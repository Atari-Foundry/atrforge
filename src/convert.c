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
 * UTF8 ↔ ATASCII conversion functions.
 */
#include "convert.h"
#include "msg.h"
#include <stdlib.h>
#include <string.h>

//---------------------------------------------------------------------
// Convert UTF8 stream to ATASCII stream
static int convert_utf8_to_atascii_stream(FILE *input, FILE *output)
{
    int character;
    int err = 0;

    while( (character = fgetc(input)) != EOF )
    {
        if( character == 0x0a )
        {
            fputc(155, output);
        }
        else if( character < 128 )
        {
            fputc(character, output);
        }
        else
        {
            // Handle UTF8 multi-byte sequence
            int chrarr[8];
            chrarr[0] = character << 1;

            int cnt = 0;
            while( chrarr[0] & 0x80 )
            {
                if( (chrarr[++cnt] = fgetc(input)) == EOF )
                {
                    show_error("unexpected EOF while reading UTF8 sequence");
                    err = 1;
                    break;
                }
                chrarr[0] <<= 1;
            }
            if( err )
                break;

            character &= (1 << (6 - cnt)) - 1;
            int c2;
            for( c2 = 1; c2 <= cnt; c2++ )
            {
                character <<= 6;
                character |= chrarr[c2] & 0x3f;
            }
            if( (character & 0xfc80) == 0xe080 )
            {
                fputc(character & 0xff, output);
            }
        }
    }

    return err;
}

//---------------------------------------------------------------------
// Convert ATASCII stream to UTF8 stream
static int convert_atascii_to_utf8_stream(FILE *input, FILE *output, int sevenbit)
{
    int character;

    while( (character = fgetc(input)) != EOF )
    {
        if( character == 155 )
        {
            fputc(0x0a, output);
        }
        else if( character < 128 || sevenbit )
        {
            fputc(character & 0x7f, output);
        }
        else
        {
            // Encode as UTF8 sequence: 0xee 0x80|(c>>6) 0x80|(c&0x3f)
            fputc(0xee, output);
            fputc(0x80 | (character >> 6), output);
            fputc(0x80 | (character & 0x3f), output);
        }
    }

    return 0;
}

//---------------------------------------------------------------------
int convert_utf8_to_atascii_file(const char *input_file, const char *output_file)
{
    FILE *input = fopen(input_file, "rb");
    if( !input )
    {
        show_error("can't open input file '%s'", input_file);
        return 1;
    }

    FILE *output = fopen(output_file, "wb");
    if( !output )
    {
        show_error("can't create output file '%s'", output_file);
        fclose(input);
        return 1;
    }

    int err = convert_utf8_to_atascii_stream(input, output);

    fclose(input);
    fclose(output);

    return err;
}

//---------------------------------------------------------------------
int convert_atascii_to_utf8_file(const char *input_file, const char *output_file, int sevenbit)
{
    FILE *input = fopen(input_file, "rb");
    if( !input )
    {
        show_error("can't open input file '%s'", input_file);
        return 1;
    }

    FILE *output = fopen(output_file, "wb");
    if( !output )
    {
        show_error("can't create output file '%s'", output_file);
        fclose(input);
        return 1;
    }

    int err = convert_atascii_to_utf8_stream(input, output, sevenbit);

    fclose(input);
    fclose(output);

    return err;
}

//---------------------------------------------------------------------
// Buffer-based UTF8 to ATASCII conversion
int convert_buffer_utf8_to_atascii(const uint8_t *input, size_t input_size, 
                                    uint8_t **output, size_t *output_size)
{
    // Allocate output buffer (worst case: same size as input)
    *output = check_malloc(input_size);
    size_t out_pos = 0;
    size_t in_pos = 0;

    while( in_pos < input_size )
    {
        int character = input[in_pos++];

        if( character == 0x0a )
        {
            if( out_pos >= input_size )
            {
                // Need to reallocate
                *output = check_realloc(*output, input_size * 2);
                input_size *= 2;
            }
            (*output)[out_pos++] = 155;
        }
        else if( character < 128 )
        {
            if( out_pos >= input_size )
            {
                *output = check_realloc(*output, input_size * 2);
                input_size *= 2;
            }
            (*output)[out_pos++] = character;
        }
        else
        {
            // Handle UTF8 multi-byte sequence
            int chrarr[8];
            chrarr[0] = character << 1;

            int cnt = 0;
            while( chrarr[0] & 0x80 && in_pos < input_size )
            {
                chrarr[++cnt] = input[in_pos++];
                chrarr[0] <<= 1;
            }
            if( in_pos >= input_size && (chrarr[0] & 0x80) )
            {
                show_error("unexpected EOF while reading UTF8 sequence");
                free(*output);
                *output = NULL;
                return 1;
            }

            character &= (1 << (6 - cnt)) - 1;
            int c2;
            for( c2 = 1; c2 <= cnt; c2++ )
            {
                character <<= 6;
                character |= chrarr[c2] & 0x3f;
            }
            if( (character & 0xfc80) == 0xe080 )
            {
                if( out_pos >= input_size )
                {
                    *output = check_realloc(*output, input_size * 2);
                    input_size *= 2;
                }
                (*output)[out_pos++] = character & 0xff;
            }
        }
    }

    *output_size = out_pos;
    return 0;
}

//---------------------------------------------------------------------
// Buffer-based ATASCII to UTF8 conversion
int convert_buffer_atascii_to_utf8(const uint8_t *input, size_t input_size, 
                                    uint8_t **output, size_t *output_size,
                                    int sevenbit)
{
    // Allocate output buffer (worst case: 3x input size for UTF8 encoding)
    size_t alloc_size = input_size * 3;
    *output = check_malloc(alloc_size);
    size_t out_pos = 0;
    size_t in_pos = 0;

    while( in_pos < input_size )
    {
        int character = input[in_pos++];

        if( character == 155 )
        {
            if( out_pos >= alloc_size )
            {
                alloc_size *= 2;
                *output = check_realloc(*output, alloc_size);
            }
            (*output)[out_pos++] = 0x0a;
        }
        else if( character < 128 || sevenbit )
        {
            if( out_pos >= alloc_size )
            {
                alloc_size *= 2;
                *output = check_realloc(*output, alloc_size);
            }
            (*output)[out_pos++] = character & 0x7f;
        }
        else
        {
            // Encode as UTF8 sequence: 0xee 0x80|(c>>6) 0x80|(c&0x3f)
            if( out_pos + 3 > alloc_size )
            {
                alloc_size *= 2;
                *output = check_realloc(*output, alloc_size);
            }
            (*output)[out_pos++] = 0xee;
            (*output)[out_pos++] = 0x80 | (character >> 6);
            (*output)[out_pos++] = 0x80 | (character & 0x3f);
        }
    }

    *output_size = out_pos;
    return 0;
}
