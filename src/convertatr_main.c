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
 * Convert ATR images - main program.
 */
#include "convertatr.h"
#include "msg.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void show_usage(void)
{
    printf("Usage: %s [options] <input.atr> <output.atr>\n"
           "Options:\n"
           "\t--resize N\tResize image to N sectors.\n"
           "\t--sector-size N\tConvert to N-byte sectors (128 or 256).\n"
           "\t--convert-utf8\tConvert files from UTF8 to ATASCII when processing ATR.\n"
           "\t--convert-atascii\tConvert files from ATASCII to UTF8 when processing ATR.\n"
           "\t-h\t\tShow this help.\n"
           "\t-v\t\tShow version information.\n",
           prog_name);
    exit(EXIT_SUCCESS);
}

int main(int argc, char **argv)
{
    const char *input_file = 0;
    const char *output_file = 0;
    unsigned resize_sectors = 0;
    unsigned new_sector_size = 0;
    int convert_utf8 = 0;
    int convert_atascii = 0;

    prog_name = argv[0];

    for( int i = 1; i < argc; i++ )
    {
        if( !strcmp(argv[i], "-h") || !strcmp(argv[i], "--help") )
            show_usage();
        else if( !strcmp(argv[i], "-v") )
            show_version();
        else if( !strcmp(argv[i], "--resize") )
        {
            if( i + 1 >= argc )
                show_opt_error("option '--resize' needs an argument");
            i++;
            resize_sectors = strtoul(argv[i], 0, 0);
            if( resize_sectors == 0 || resize_sectors > 65535 )
                show_error("invalid sector count for resize");
        }
        else if( !strcmp(argv[i], "--sector-size") )
        {
            if( i + 1 >= argc )
                show_opt_error("option '--sector-size' needs an argument");
            i++;
            new_sector_size = strtoul(argv[i], 0, 0);
            if( new_sector_size != 128 && new_sector_size != 256 )
                show_error("sector size must be 128 or 256");
        }
        else if( !strcmp(argv[i], "--convert-utf8") )
            convert_utf8 = 1;
        else if( !strcmp(argv[i], "--convert-atascii") )
            convert_atascii = 1;
        else if( !input_file )
            input_file = argv[i];
        else if( !output_file )
            output_file = argv[i];
        else
            show_opt_error("too many arguments");
    }

    if( !input_file || !output_file )
        show_opt_error("input and output files required");

    if( !resize_sectors && !new_sector_size )
        show_opt_error("must specify either --resize or --sector-size");

    if( resize_sectors && new_sector_size )
        show_opt_error("cannot specify both --resize and --sector-size");

    if( convert_utf8 && convert_atascii )
        show_opt_error("cannot specify both --convert-utf8 and --convert-atascii");

    if( resize_sectors )
        return convertatr_resize(input_file, output_file, resize_sectors, convert_utf8, convert_atascii);
    else
        return convertatr_sector_size(input_file, output_file, new_sector_size, convert_utf8, convert_atascii);
}
