/*
 *  Copyright (C) 2023 Daniel Serpell
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
 * Common compatibility functions.
 */
#include "compat.h"
#include <limits.h>
#include <string.h>
#include <sys/stat.h>

int compat_mkdir(const char *path)
{
#if( defined(_WIN32) || defined(__WIN32__) )
    return mkdir(path);
#else
    return mkdir(path, 0777);
#endif
}

int is_separator(char c)
{
#if( defined(_WIN32) || defined(__WIN32__) )
    return c == '/' || c == '\\' || c == ':';
#else
    return c == '/';
#endif
}

int sanitize_path(const char *path, char *output, size_t output_size)
{
    if( !path || !output || output_size == 0 )
        return 0;

    // Reject absolute paths
    if( is_separator(path[0]) )
        return 0;

    size_t len = strlen(path);
    if( len >= output_size )
        return 0;

    // Copy path and process components
    const char *in = path;
    size_t out_pos = 0;

    // Track depth to prevent ".." from escaping
    int depth = 0;

    while( *in && out_pos < output_size - 1 )
    {
        // Skip leading separators
        while( is_separator(*in) )
            in++;

        if( !*in )
            break;

        // Find end of component
        const char *comp_start = in;
        const char *comp_end = in;
        while( *comp_end && !is_separator(*comp_end) )
            comp_end++;

        size_t comp_len = comp_end - comp_start;

        // Check for dangerous components
        if( comp_len == 0 )
        {
            in = comp_end;
            continue;
        }

        // Check for ".." component
        if( comp_len == 2 && comp_start[0] == '.' && comp_start[1] == '.' )
        {
            // Go up one level
            if( depth > 0 )
            {
                depth--;
                // Remove last component from output
                while( out_pos > 0 && !is_separator(output[out_pos - 1]) )
                    out_pos--;
                if( out_pos > 0 )
                    out_pos--; // Remove separator
            }
            // If depth is 0, ".." would escape, reject
            else
                return 0;
        }
        // Check for "." component (ignore it)
        else if( comp_len == 1 && comp_start[0] == '.' )
        {
            // Ignore current directory component
        }
        // Check for component containing path separators (shouldn't happen, but be safe)
        else
        {
            // Check if component contains any separators (shouldn't, but validate)
            int has_sep = 0;
            for( size_t i = 0; i < comp_len; i++ )
            {
                if( is_separator(comp_start[i]) )
                {
                    has_sep = 1;
                    break;
                }
            }
            if( has_sep )
                return 0;

            // Add separator if not first component
            if( out_pos > 0 && output[out_pos - 1] != '/' )
            {
                output[out_pos++] = '/';
            }

            // Copy component
            if( out_pos + comp_len >= output_size - 1 )
                return 0;
            memcpy(output + out_pos, comp_start, comp_len);
            out_pos += comp_len;
            depth++;
        }

        in = comp_end;
    }

    output[out_pos] = '\0';
    return 1;
}
