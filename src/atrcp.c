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
 * Copy files in and out of ATR images.
 */
#define _GNU_SOURCE
#include "atr.h"
#include "compat.h"
#include "convert.h"
#include "flist.h"
#include "lssfs.h"
#include "msg.h"
#include "spartafs.h"
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

//---------------------------------------------------------------------
// Parse ATR path: "image.atr:path/to/file.ext"
// Returns 1 if it's an ATR path, 0 otherwise
// Sets *atr_file and *atr_path on success
static int parse_atr_path(const char *arg, char **atr_file, char **atr_path)
{
    const char *colon = strchr(arg, ':');
    if( !colon )
        return 0;

    size_t atr_len = colon - arg;
    *atr_file = check_malloc(atr_len + 1);
    memcpy(*atr_file, arg, atr_len);
    (*atr_file)[atr_len] = '\0';

    if( colon[1] == '\0' )
    {
        // Empty path, use filename from source
        *atr_path = NULL;
    }
    else
    {
        *atr_path = strdup(colon + 1);
        if( !*atr_path )
            memory_error();
    }

    return 1;
}

//---------------------------------------------------------------------
// Find a file in SpartaDOS filesystem by path
// Returns file data and size, or NULL if not found
static struct
{
    uint8_t *data;
    unsigned size;
    int found;
} find_result;

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

static void find_file_in_dir(struct atr_image *atr, unsigned map, const char *search_path,
                             const char *current_path)
{
    if( find_result.found )
        return;

    uint8_t *data = check_malloc(65536);
    unsigned len = read_file_data(atr, map, 65536, data);
    if( !len )
    {
        free(data);
        return;
    }

    // Split search_path into current component and rest
    const char *next_slash = strchr(search_path, '/');
    size_t component_len = next_slash ? (next_slash - search_path) : strlen(search_path);
    char search_component[32];
    if( component_len >= sizeof(search_component) )
        component_len = sizeof(search_component) - 1;
    memcpy(search_component, search_path, component_len);
    search_component[component_len] = '\0';

    // Convert to uppercase for comparison
    for( size_t i = 0; i < component_len; i++ )
    {
        if( search_component[i] >= 'a' && search_component[i] <= 'z' )
            search_component[i] = search_component[i] - 'a' + 'A';
    }

    // Traverse directory
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

        // Convert filename to uppercase for comparison
        char fname_upper[32];
        strcpy(fname_upper, fname);
        for( size_t j = 0; fname_upper[j]; j++ )
        {
            if( fname_upper[j] >= 'a' && fname_upper[j] <= 'z' )
                fname_upper[j] = fname_upper[j] - 'a' + 'A';
        }

        // Check if this matches our search component
        if( strcmp(fname_upper, search_component) == 0 )
        {
            if( is_dir )
            {
                // Recurse into subdirectory
                if( next_slash )
                {
                    char *new_path;
                    int ret = asprintf(&new_path, "%s/%s", current_path, fname);
                    if( ret >= 0 )
                    {
                        find_file_in_dir(atr, fmap, next_slash + 1, new_path);
                        free(new_path);
                    }
                }
            }
            else
            {
                // Found the file!
                if( !next_slash ) // Must be at end of path
                {
                    find_result.size = fsize;
                    find_result.data = check_malloc(fsize);
                    unsigned r = read_file_data(atr, fmap, fsize, find_result.data);
                    if( r != fsize )
                        show_msg("short file read: expected %u, got %u", fsize, r);
                    find_result.found = 1;
                }
            }
            break;
        }
    }

    free(data);
}

static int extract_from_atr(const char *atr_file, const char *atr_path, const char *output_file,
                             int to_utf8, int sevenbit)
{
    struct atr_image *atr = load_atr_image(atr_file);
    if( !atr )
        return 1;

    // Check if it's a SpartaDOS filesystem
    const uint8_t *boot = atr_data(atr, 1);
    if( !boot || boot[7] != 0x80 )
    {
        show_error("%s: only SpartaDOS/BW-DOS images are supported for file extraction",
                   atr_file);
        atr_free(atr);
        return 1;
    }

    // Find root directory (sector 361 for SpartaDOS)
    unsigned root_map = read16(boot + 0x0A);

    // Initialize find result
    find_result.data = NULL;
    find_result.size = 0;
    find_result.found = 0;

    // Find the file
    find_file_in_dir(atr, root_map, atr_path, "");

    if( !find_result.found )
    {
        show_error("%s: file '%s' not found in ATR image", atr_file, atr_path);
        atr_free(atr);
        return 1;
    }

    // Convert if requested
    uint8_t *output_data = find_result.data;
    size_t output_size = find_result.size;
    if( to_utf8 )
    {
        uint8_t *converted = NULL;
        size_t converted_size = 0;
        if( convert_buffer_atascii_to_utf8(find_result.data, find_result.size,
                                             &converted, &converted_size, sevenbit) != 0 )
        {
            show_error("conversion failed");
            free(find_result.data);
            atr_free(atr);
            return 1;
        }
        free(find_result.data);
        output_data = converted;
        output_size = converted_size;
    }

    // Write to output file
    int fd = creat(output_file, 0666);
    if( fd == -1 )
    {
        show_error("can't create output file '%s': %s", output_file, strerror(errno));
        free(output_data);
        atr_free(atr);
        return 1;
    }

    if( output_size != write(fd, output_data, output_size) )
    {
        show_error("can't write output file '%s': %s", output_file, strerror(errno));
        close(fd);
        free(output_data);
        atr_free(atr);
        return 1;
    }

    close(fd);
    free(output_data);
    atr_free(atr);

    show_msg("extracted '%s' from '%s' to '%s'", atr_path, atr_file, output_file);
    return 0;
}

//---------------------------------------------------------------------
// Read all files from ATR and extract to temp directory, then add to file_list
static void extract_all_to_temp(struct atr_image *atr, unsigned map, const char *temp_dir,
                                const char *dir_path)
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

        char *host_path;
        int ret = asprintf(&host_path, "%s/%s", temp_dir, full_path);
        if( ret < 0 )
        {
            show_error("memory error");
            free(full_path);
            continue;
        }

        if( is_dir )
        {
            // Create directory
            compat_mkdir(host_path);
            // Recurse into subdirectory
            extract_all_to_temp(atr, fmap, temp_dir, full_path);
            free(host_path);
            free(full_path);
        }
        else
        {
            // Read file data and write to temp directory
            uint8_t *fdata = check_malloc(fsize);
            unsigned r = read_file_data(atr, fmap, fsize, fdata);
            if( r != fsize )
                show_msg("%s: short file read", full_path);

            // Create parent directory if needed
            char *parent_dir = strdup(host_path);
            char *last_slash = strrchr(parent_dir, '/');
            if( last_slash )
            {
                *last_slash = '\0';
                compat_mkdir(parent_dir);
            }
            free(parent_dir);

            // Write file
            FILE *tmp = fopen(host_path, "wb");
            if( tmp )
            {
                fwrite(fdata, 1, fsize, tmp);
                fclose(tmp);
            }
            else
            {
                show_msg("warning: can't create temp file for %s", host_path);
            }

            free(fdata);
            free(host_path);
            free(full_path);
        }
    }

    free(data);
}

//---------------------------------------------------------------------
// Recursively add all files from a directory to file_list
// Adds directories first, then files, to ensure proper hierarchy
static void add_dir_to_flist(file_list *flist, const char *dir_path)
{
    DIR *dir = opendir(dir_path);
    if( !dir )
        return;

    // Collect all entries first
    struct dirent **entries = NULL;
    int count = 0;
    struct dirent *entry;
    while( (entry = readdir(dir)) != NULL )
    {
        if( entry->d_name[0] == '.' && (entry->d_name[1] == '\0' ||
                                         (entry->d_name[1] == '.' && entry->d_name[2] == '\0')) )
            continue; // Skip . and ..

        // Allocate space for entry pointer
        entries = check_realloc(entries, (count + 1) * sizeof(struct dirent *));
        // Allocate space for the dirent structure
        entries[count] = check_malloc(entry->d_reclen);
        memcpy(entries[count], entry, entry->d_reclen);
        count++;
    }
    closedir(dir);

    // First pass: add directories
    for( int i = 0; i < count; i++ )
    {
        entry = entries[i];
        char *full_path;
        int ret = asprintf(&full_path, "%s/%s", dir_path, entry->d_name);
        if( ret < 0 )
        {
            show_error("memory error");
            continue;
        }

        struct stat st;
        if( stat(full_path, &st) == 0 && S_ISDIR(st.st_mode) )
        {
            // Add directory first
            flist_add_file(flist, full_path, 0, 0);
            // Then recurse into it
            add_dir_to_flist(flist, full_path);
        }

        free(full_path);
    }

    // Second pass: add files
    for( int i = 0; i < count; i++ )
    {
        entry = entries[i];
        char *full_path;
        int ret = asprintf(&full_path, "%s/%s", dir_path, entry->d_name);
        if( ret < 0 )
        {
            show_error("memory error");
            continue;
        }

        struct stat st;
        if( stat(full_path, &st) == 0 && S_ISREG(st.st_mode) )
        {
            // Add file to list
            flist_add_file(flist, full_path, 0, 0);
        }

        free(full_path);
    }

    // Free entries
    for( int i = 0; i < count; i++ )
        free(entries[i]);
    free(entries);
}

static int add_to_atr(const char *input_file, const char *atr_file, const char *atr_path,
                       int to_atascii)
{
    // Load existing ATR
    struct atr_image *atr = load_atr_image(atr_file);
    if( !atr )
        return 1;

    // Check if it's a SpartaDOS filesystem
    const uint8_t *boot = atr_data(atr, 1);
    if( !boot || boot[7] != 0x80 )
    {
        show_error("%s: only SpartaDOS/BW-DOS images can be modified", atr_file);
        atr_free(atr);
        return 1;
    }

    // Create backup
    char *backup_file = check_malloc(strlen(atr_file) + 10);
    strcpy(backup_file, atr_file);
    strcat(backup_file, ".bak");

    FILE *src = fopen(atr_file, "rb");
    if( !src )
    {
        show_error("can't open '%s' for reading: %s", atr_file, strerror(errno));
        free(backup_file);
        atr_free(atr);
        return 1;
    }

    FILE *dst = fopen(backup_file, "wb");
    if( !dst )
    {
        show_error("can't create backup '%s': %s", backup_file, strerror(errno));
        fclose(src);
        free(backup_file);
        atr_free(atr);
        return 1;
    }

    uint8_t buffer[4096];
    size_t n;
    while( (n = fread(buffer, 1, sizeof(buffer), src)) > 0 )
    {
        if( fwrite(buffer, 1, n, dst) != n )
        {
            show_error("error writing backup file");
            fclose(src);
            fclose(dst);
            unlink(backup_file);
            free(backup_file);
            atr_free(atr);
            return 1;
        }
    }
    fclose(src);
    fclose(dst);

    show_msg("Backup created: %s", backup_file);
    free(backup_file);

    // Create temporary directory for extracted files
    char *temp_dir;
    int ret = asprintf(&temp_dir, "/tmp/atrcp_%d_%p", getpid(), (void *)atr);
    if( ret < 0 )
    {
        show_error("memory error");
        atr_free(atr);
        return 1;
    }

    if( compat_mkdir(temp_dir) )
    {
        show_error("can't create temp directory '%s': %s", temp_dir, strerror(errno));
        free(temp_dir);
        atr_free(atr);
        return 1;
    }

    // Save ATR parameters before freeing
    unsigned old_sec_size = atr->sec_size;
    unsigned old_sec_count = atr->sec_count;

    // Extract all files to temp directory
    unsigned root_map = read16(boot + 0x0A);
    extract_all_to_temp(atr, root_map, temp_dir, "");

    atr_free(atr); // No longer need the ATR in memory

    // Read all existing files into file_list
    file_list flist;
    darray_init(flist, 1);
    flist_add_main_dir(&flist);

    // Add all files from temp directory to file_list
    add_dir_to_flist(&flist, temp_dir);

    // Handle the new file - convert if needed
    const char *file_to_add = input_file;
    char *temp_converted_file = NULL;
    if( to_atascii )
    {
        // Read input file and convert
        FILE *in = fopen(input_file, "rb");
        if( !in )
        {
            show_error("can't open input file '%s': %s", input_file, strerror(errno));
            darray_delete(flist);
            return 1;
        }

        // Get file size
        fseek(in, 0, SEEK_END);
        long file_size = ftell(in);
        fseek(in, 0, SEEK_SET);

        uint8_t *input_data = check_malloc(file_size);
        if( fread(input_data, 1, file_size, in) != file_size )
        {
            show_error("error reading input file");
            fclose(in);
            free(input_data);
            darray_delete(flist);
            return 1;
        }
        fclose(in);

        // Convert
        uint8_t *converted = NULL;
        size_t converted_size = 0;
        if( convert_buffer_utf8_to_atascii(input_data, file_size, &converted, &converted_size) != 0 )
        {
            show_error("conversion failed");
            free(input_data);
            darray_delete(flist);
            return 1;
        }
        free(input_data);

        // Write to temp file
        int ret = asprintf(&temp_converted_file, "/tmp/atrcp_conv_%d_%p", getpid(), (void *)&flist);
        if( ret < 0 )
        {
            show_error("memory error");
            free(converted);
            darray_delete(flist);
            return 1;
        }

        FILE *out = fopen(temp_converted_file, "wb");
        if( !out )
        {
            show_error("can't create temp file '%s': %s", temp_converted_file, strerror(errno));
            free(converted);
            free(temp_converted_file);
            darray_delete(flist);
            return 1;
        }

        if( fwrite(converted, 1, converted_size, out) != converted_size )
        {
            show_error("error writing temp file");
            fclose(out);
            free(converted);
            free(temp_converted_file);
            darray_delete(flist);
            return 1;
        }
        fclose(out);
        free(converted);

        file_to_add = temp_converted_file;
    }

    // Add the new file
    flist_add_file(&flist, file_to_add, 0, 0);

    // Cleanup temp directory (files have been read into memory)
    // Note: We could clean up here, but it's safer to leave it for debugging
    // In production, we'd want to recursively remove the temp directory

    // Rebuild filesystem
    unsigned boot_addr = 0x07; // Standard boot address
    struct sfs *sfs = build_spartafs(old_sec_size, old_sec_count, boot_addr, &flist);
    if( !sfs )
    {
        show_error("can't rebuild filesystem");
        darray_delete(flist);
        atr_free(atr);
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

    FILE *out = fopen(atr_file, "wb");
    if( !out )
    {
        show_error("can't open '%s' for writing: %s", atr_file, strerror(errno));
        sfs_free(sfs);
        darray_delete(flist);
        atr_free(atr);
        return 1;
    }

    // Write ATR header
    putc(0x96, out);
    putc(0x02, out);
    putc(size >> 4, out);
    putc(size >> 12, out);
    putc(ssec, out);
    putc(ssec >> 8, out);
    putc(size >> 20, out);
    for( int i = 0; i < 9; i++ )
        putc(0, out);

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
            atr_free(atr);
            return 1;
        }
    }

    fclose(out);
    sfs_free(sfs);
    darray_delete(flist);
    if( temp_converted_file )
    {
        unlink(temp_converted_file);
        free(temp_converted_file);
    }

    show_msg("added '%s' to '%s'", input_file, atr_file);
    return 0;
}

//---------------------------------------------------------------------
static void show_usage(void)
{
    printf("Usage: %s [options] <source> <destination>\n"
           "\n"
           "Copy files between ATR images and the host filesystem.\n"
           "\n"
           "Extract from ATR:\n"
           "  %s image.atr:path/to/file.ext output.ext\n"
           "  %s image.atr:file.ext .\n"
           "\n"
           "Add to ATR:\n"
           "  %s input.ext image.atr:path/to/file.ext\n"
           "  %s input.ext image.atr:\n"
           "\n"
           "Options:\n"
           "  --to-utf8\tConvert ATASCII to UTF8 when extracting from ATR.\n"
           "  --to-atascii\tConvert UTF8 to ATASCII when adding to ATR.\n"
           "  --7bit\tUse 7-bit mode for ATASCII→UTF8 conversion (strip high bit).\n"
           "  -h\t\tShow this help.\n"
           "  -v\t\tShow version information.\n",
           prog_name, prog_name, prog_name, prog_name, prog_name);
    exit(EXIT_SUCCESS);
}

//---------------------------------------------------------------------
int main(int argc, char **argv)
{
    prog_name = argv[0];

    if( argc < 2 )
        show_usage();

    int to_utf8 = 0;
    int to_atascii = 0;
    int sevenbit = 0;
    const char *source = NULL;
    const char *dest = NULL;

    for( int i = 1; i < argc; i++ )
    {
        if( !strcmp(argv[i], "-h") || !strcmp(argv[i], "--help") )
            show_usage();
        else if( !strcmp(argv[i], "-v") )
        {
            show_version();
            return 0;
        }
        else if( !strcmp(argv[i], "--to-utf8") )
            to_utf8 = 1;
        else if( !strcmp(argv[i], "--to-atascii") )
            to_atascii = 1;
        else if( !strcmp(argv[i], "--7bit") )
            sevenbit = 1;
        else if( !source )
            source = argv[i];
        else if( !dest )
            dest = argv[i];
        else
            show_opt_error("too many arguments");
    }

    if( !source || !dest )
        show_opt_error("expected source and destination arguments");

    if( to_utf8 && to_atascii )
        show_opt_error("cannot specify both --to-utf8 and --to-atascii");

    // Parse source and destination to determine operation
    char *src_atr_file = NULL, *src_atr_path = NULL;
    char *dst_atr_file = NULL, *dst_atr_path = NULL;

    int src_is_atr = parse_atr_path(source, &src_atr_file, &src_atr_path);
    int dst_is_atr = parse_atr_path(dest, &dst_atr_file, &dst_atr_path);

    int ret = 1;

    if( src_is_atr && !dst_is_atr )
    {
        // Extract from ATR
        if( !src_atr_path )
            show_opt_error("source ATR path cannot be empty");
        if( to_atascii )
            show_opt_error("--to-atascii can only be used when adding files to ATR");
        ret = extract_from_atr(src_atr_file, src_atr_path, dest, to_utf8, sevenbit);
    }
    else if( !src_is_atr && dst_is_atr )
    {
        // Add to ATR
        if( to_utf8 )
            show_opt_error("--to-utf8 can only be used when extracting files from ATR");
        ret = add_to_atr(source, dst_atr_file, dst_atr_path, to_atascii);
    }
    else
    {
        show_opt_error("exactly one of source or destination must be an ATR path (contain ':')");
    }

    if( src_atr_file )
        free(src_atr_file);
    if( src_atr_path )
        free(src_atr_path);
    if( dst_atr_file )
        free(dst_atr_file);
    if( dst_atr_path )
        free(dst_atr_path);

    return ret;
}
