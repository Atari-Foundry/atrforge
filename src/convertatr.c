/*
 *  Copyright (C) 2026 Rick Collette & AtariFoundry.com
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program.  If not, see <http://www.gnu.org/licenses/>
 */
/*
 * Convert ATR images.
 */
#include "convertatr.h"
#include "atr.h"
#include "convert.h"
#include "flist.h"
#include "msg.h"
#include "spartafs.h"
#include <errno.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <dirent.h>

// Helper function to write ATR header
static void write_atr_header(FILE *f, unsigned size, unsigned sec_size)
{
    putc(0x96, f);
    putc(0x02, f);
    putc(size >> 4, f);
    putc(size >> 12, f);
    putc(sec_size, f);
    putc(sec_size >> 8, f);
    putc(size >> 20, f);
    for( int i = 0; i < 9; i++ )
        putc(0, f);
}

// Helper functions for filesystem operations
static uint16_t read16(const uint8_t *p)
{
    return p[0] | (p[1] << 8);
}

static unsigned read24(const uint8_t *p)
{
    return p[0] | (p[1] << 8) | (p[2] << 16);
}

static unsigned read_file_data(struct atr_image *atr, unsigned map, unsigned size, uint8_t *data)
{
    const uint8_t *m = atr_data(atr, map);
    if( !m )
        return 0;

    unsigned pos = 0;
    unsigned visited_count = 0;
    const unsigned max_visited = atr->sec_count;

    while( m && pos < size && visited_count < max_visited )
    {
        visited_count++;
        for( unsigned s = 4; s < atr->sec_size && pos < size; s += 2 )
        {
            unsigned sec = read16(m + s);
            if( sec && sec >= 2 && sec <= atr->sec_count )
            {
                const uint8_t *sec_data = atr_data(atr, sec);
                if( sec_data )
                {
                    unsigned rem = size - pos;
                    if( rem > atr->sec_size )
                        rem = atr->sec_size;
                    memcpy(data + pos, sec_data, rem);
                    pos += rem;
                }
            }
        }
        unsigned next_map = read16(m);
        if( next_map == 0 || next_map < 2 || next_map > atr->sec_count )
            break;
        m = atr_data(atr, next_map);
    }

    return pos;
}

static unsigned get_name(char *name, const uint8_t *data, int max, int lower_case)
{
    unsigned l = 0;
    int dot = 0;
    for( int i = 0; i < max; i++ )
    {
        uint8_t c = data[i];
        if( c >= 'A' && c <= 'Z' && lower_case )
            c = c - 'A' + 'a';
        if( c < ' ' || c == '/' || c == '.' || c == '?' || c == '\\' || c == 96 || c > 'z' )
            c = '_';
        else if( c == ' ' )
            continue;
        if( i > 7 && !dot )
        {
            dot = 1;
            name[l++] = '.';
        }
        name[l++] = c;
    }
    name[l] = 0;
    return l;
}

// Extract all files from ATR to file_list, converting if requested
static void extract_files_to_flist(struct atr_image *atr, unsigned map, file_list *flist,
                                    const char *dir_path, int convert_utf8, int convert_atascii)
{
    uint8_t *data = check_malloc(65536);
    unsigned len = read_file_data(atr, map, 65536, data);
    if( !len )
    {
        free(data);
        return;
    }

    for( unsigned i = 23; i < len; i += 23 )
    {
        unsigned flags = data[i];
        if( !flags )
            break;
        if( 0 == (flags & 0x08) )
            continue; // unused
        if( 0x10 == (flags & 0x10) )
            continue; // erased

        int is_dir = flags & 0x20;
        unsigned fmap = read16(data + i + 1);
        unsigned fsize = read24(data + i + 3);

        char fname[32];
        if( !get_name(fname, data + i + 6, 11, 0) || !*fname )
            continue;

        char *full_path;
        if( *dir_path )
        {
            int ret = asprintf(&full_path, "%s/%s", dir_path, fname);
            if( ret < 0 )
            {
                show_error("memory error allocating path name");
                continue;
            }
        }
        else
        {
            full_path = strdup(fname);
            if( !full_path )
                memory_error();
        }

        if( is_dir )
        {
            // Add directory to file_list
            flist_add_file(flist, full_path, 0, 0);
            // Recurse into subdirectory
            extract_files_to_flist(atr, fmap, flist, full_path, convert_utf8, convert_atascii);
            free(full_path);
        }
        else
        {
            // Read file data
            uint8_t *fdata = check_malloc(fsize);
            unsigned r = read_file_data(atr, fmap, fsize, fdata);
            if( r != fsize )
                show_msg("%s: short file read", full_path);

            // Convert if requested
            uint8_t *converted_data = fdata;
            size_t converted_size = fsize;
            if( convert_utf8 )
            {
                uint8_t *output = NULL;
                size_t output_size = 0;
                if( convert_buffer_utf8_to_atascii(fdata, fsize, &output, &output_size) == 0 )
                {
                    free(fdata);
                    converted_data = output;
                    converted_size = output_size;
                }
                else
                {
                    show_msg("warning: conversion failed for %s, using original", full_path);
                }
            }
            else if( convert_atascii )
            {
                uint8_t *output = NULL;
                size_t output_size = 0;
                if( convert_buffer_atascii_to_utf8(fdata, fsize, &output, &output_size, 0) == 0 )
                {
                    free(fdata);
                    converted_data = output;
                    converted_size = output_size;
                }
                else
                {
                    show_msg("warning: conversion failed for %s, using original", full_path);
                }
            }

            // Create temporary file with converted data
            char *temp_file;
            int ret = asprintf(&temp_file, "/tmp/convertatr_%d_%p_%s", getpid(), (void *)atr, fname);
            if( ret < 0 )
            {
                show_error("memory error");
                free(converted_data);
                free(full_path);
                continue;
            }

            FILE *tmp = fopen(temp_file, "wb");
            if( tmp )
            {
                fwrite(converted_data, 1, converted_size, tmp);
                fclose(tmp);
                // Add to file_list using temp file
                flist_add_file(flist, temp_file, 0, 0);
                free(temp_file);
            }
            else
            {
                show_msg("warning: can't create temp file for %s", full_path);
                free(temp_file);
            }

            free(converted_data);
            free(full_path);
        }
    }

    free(data);
}

// Convert ATR with file conversion
static int convertatr_with_conversion(const char *input_file, const char *output_file,
                                       unsigned new_sectors, unsigned new_sector_size,
                                       int convert_utf8, int convert_atascii)
{
    struct atr_image *atr = load_atr_image(input_file);
    if( !atr )
        return 1;

    // Check if it's a SpartaDOS filesystem
    const uint8_t *boot = atr_data(atr, 1);
    if( !boot || boot[7] != 0x80 )
    {
        // Not a SpartaDOS filesystem, do normal conversion without file conversion
        atr_free(atr);
        if( new_sectors > 0 )
            return convertatr_resize(input_file, output_file, new_sectors, 0, 0);
        else
            return convertatr_sector_size(input_file, output_file, new_sector_size, 0, 0);
    }

    // Save original parameters before freeing atr
    unsigned old_sec_size = atr->sec_size;
    unsigned old_sec_count = atr->sec_count;

    // Extract root directory
    unsigned root_map = read16(boot + 0x0A);

    // Extract all files to file_list
    file_list flist;
    darray_init(flist, 1);
    flist_add_main_dir(&flist);
    extract_files_to_flist(atr, root_map, &flist, "", convert_utf8, convert_atascii);

    atr_free(atr);

    // Determine new sector parameters
    unsigned boot_addr = 0x07;
    unsigned target_sec_size = new_sector_size ? new_sector_size : old_sec_size;
    unsigned target_sec_count = new_sectors ? new_sectors : old_sec_count;

    // Build new filesystem
    struct sfs *sfs = build_spartafs(target_sec_size, target_sec_count, boot_addr, &flist);
    if( !sfs )
    {
        show_error("can't rebuild filesystem");
        darray_delete(flist);
        return 1;
    }

    // Write new ATR
    int nsec = sfs_get_num_sectors(sfs);
    int ssec = sfs_get_sector_size(sfs);
    const uint8_t *sfs_data = sfs_get_data(sfs);

    // Calculate image size
    int size;
    if( nsec > 3 )
    {
        size = ssec * (nsec - 3) + 128 * 3;
    }
    else
    {
        size = 128 * nsec;
    }

    FILE *out = fopen(output_file, "wb");
    if( !out )
    {
        show_error("can't open '%s' for writing: %s", output_file, strerror(errno));
        sfs_free(sfs);
        darray_delete(flist);
        return 1;
    }

    // Write ATR header
    write_atr_header(out, size, ssec);

    // Write sectors
    for( int i = 0; i < nsec; i++ )
    {
        size_t write_size = (i < 3) ? 128 : ssec;
        if( fwrite(sfs_data + ssec * i, write_size, 1, out) != 1 )
        {
            show_error("can't write sector %d: %s", i + 1, strerror(errno));
            fclose(out);
            sfs_free(sfs);
            darray_delete(flist);
            return 1;
        }
    }

    fclose(out);
    sfs_free(sfs);
    darray_delete(flist);

    return 0;
}

// Resize an ATR image to a new sector count
int convertatr_resize(const char *input_file, const char *output_file, unsigned new_sectors,
                      int convert_utf8, int convert_atascii)
{
    // If conversion is requested, use the conversion path
    if( convert_utf8 || convert_atascii )
        return convertatr_with_conversion(input_file, output_file, new_sectors, 0, convert_utf8, convert_atascii);

    struct atr_image *atr = load_atr_image(input_file);
    if( !atr )
        return 1;

    if( new_sectors < atr->sec_count )
    {
        show_error("Cannot shrink ATR image (would lose data)");
        atr_free(atr);
        return 1;
    }

    if( new_sectors > 65535 )
    {
        show_error("Maximum sector count is 65535");
        atr_free(atr);
        return 1;
    }

    // Calculate new size
    unsigned pad_size = (atr->sec_size == 256) ? 3 * 128 : 0;
    unsigned new_size = (new_sectors > 3 && atr->sec_size == 256)
                            ? new_sectors * atr->sec_size - pad_size
                            : new_sectors * atr->sec_size;

    FILE *out = fopen(output_file, "wb");
    if( !out )
    {
        show_error("can't create output file '%s': %s", output_file, strerror(errno));
        atr_free(atr);
        return 1;
    }

    // Write header
    write_atr_header(out, new_size, atr->sec_size);

    // Copy existing sectors
    for( unsigned i = 0; i < atr->sec_count; i++ )
    {
        size_t write_size = (i < 3 && atr->sec_size == 256) ? 128 : atr->sec_size;
        const uint8_t *data = atr_data(atr, i + 1);
        if( !data || fwrite(data, write_size, 1, out) != 1 )
        {
            show_error("error writing sector %u", i + 1);
            fclose(out);
            atr_free(atr);
            return 1;
        }
    }

    // Write empty sectors for expansion
    uint8_t *empty = calloc(1, atr->sec_size);
    if( !empty )
    {
        show_error("memory error");
        fclose(out);
        atr_free(atr);
        return 1;
    }

    for( unsigned i = atr->sec_count; i < new_sectors; i++ )
    {
        size_t write_size = (i < 3 && atr->sec_size == 256) ? 128 : atr->sec_size;
        if( fwrite(empty, write_size, 1, out) != 1 )
        {
            show_error("error writing empty sector %u", i + 1);
            free(empty);
            fclose(out);
            atr_free(atr);
            return 1;
        }
    }

    free(empty);
    fclose(out);
    atr_free(atr);

    show_msg("Resized %s to %u sectors, saved as %s", input_file, new_sectors, output_file);
    return 0;
}

// Convert sector size (128 to 256 or vice versa)
int convertatr_sector_size(const char *input_file, const char *output_file, unsigned new_sector_size,
                            int convert_utf8, int convert_atascii)
{
    if( new_sector_size != 128 && new_sector_size != 256 )
    {
        show_error("Invalid sector size. Must be 128 or 256");
        return 1;
    }

    // If conversion is requested, use the conversion path
    if( convert_utf8 || convert_atascii )
        return convertatr_with_conversion(input_file, output_file, 0, new_sector_size, convert_utf8, convert_atascii);

    struct atr_image *atr = load_atr_image(input_file);
    if( !atr )
        return 1;

    if( atr->sec_size == new_sector_size )
    {
        show_msg("Image already has sector size %u", new_sector_size);
        atr_free(atr);
        return 0;
    }

    // Calculate new sector count
    unsigned old_size = (atr->sec_count > 3 && atr->sec_size == 256)
                            ? atr->sec_count * 256 - 3 * 128
                            : atr->sec_count * atr->sec_size;

    unsigned new_sectors;
    unsigned new_pad = (new_sector_size == 256) ? 3 * 128 : 0;
    if( new_sector_size == 256 )
    {
        new_sectors = (old_size + new_pad + new_sector_size - 1) / new_sector_size;
    }
    else
    {
        new_sectors = (old_size + new_sector_size - 1) / new_sector_size;
    }

    if( new_sectors > 65535 )
    {
        show_error("Resulting image would exceed maximum size");
        atr_free(atr);
        return 1;
    }

    unsigned new_size = (new_sectors > 3 && new_sector_size == 256)
                            ? new_sectors * new_sector_size - new_pad
                            : new_sectors * new_sector_size;

    FILE *out = fopen(output_file, "wb");
    if( !out )
    {
        show_error("can't create output file '%s': %s", output_file, strerror(errno));
        atr_free(atr);
        return 1;
    }

    // Write header
    write_atr_header(out, new_size, new_sector_size);

    // Copy and convert sectors
    uint8_t *buffer = malloc(new_sector_size);
    if( !buffer )
    {
        show_error("memory error");
        fclose(out);
        atr_free(atr);
        return 1;
    }

    unsigned out_pos = 0;
    for( unsigned i = 0; i < atr->sec_count; i++ )
    {
        const uint8_t *src = atr_data(atr, i + 1);
        if( !src )
            break;

        size_t src_size = (i < 3 && atr->sec_size == 256) ? 128 : atr->sec_size;

        // Fill buffer with source data
        memset(buffer, 0, new_sector_size);
        size_t copy_size = (src_size < new_sector_size) ? src_size : new_sector_size;
        memcpy(buffer, src, copy_size);

        // Write sector
        size_t write_size = (out_pos < 3 && new_sector_size == 256) ? 128 : new_sector_size;
        if( fwrite(buffer, write_size, 1, out) != 1 )
        {
            show_error("error writing sector");
            free(buffer);
            fclose(out);
            atr_free(atr);
            return 1;
        }
        out_pos++;
    }

    // Fill remaining sectors if needed
    if( out_pos < new_sectors )
    {
        memset(buffer, 0, new_sector_size);
        for( unsigned i = out_pos; i < new_sectors; i++ )
        {
            size_t write_size = (i < 3 && new_sector_size == 256) ? 128 : new_sector_size;
            if( fwrite(buffer, write_size, 1, out) != 1 )
            {
                show_error("error writing empty sector");
                free(buffer);
                fclose(out);
                atr_free(atr);
                return 1;
            }
        }
    }

    unsigned old_sec_size = atr->sec_size;
    free(buffer);
    fclose(out);
    atr_free(atr);

    show_msg("Converted %s from %u-byte to %u-byte sectors, saved as %s", input_file,
             old_sec_size, new_sector_size, output_file);
    return 0;
}
