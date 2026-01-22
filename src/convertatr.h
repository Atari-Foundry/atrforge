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
#pragma once
#include "atr.h"

// Resize an ATR image to a new sector count
// convert_utf8: if non-zero, convert files from UTF8 to ATASCII
// convert_atascii: if non-zero, convert files from ATASCII to UTF8
// Returns 0 on success, 1 on error
int convertatr_resize(const char *input_file, const char *output_file, unsigned new_sectors,
                      int convert_utf8, int convert_atascii);

// Convert sector size (128 to 256 or vice versa)
// convert_utf8: if non-zero, convert files from UTF8 to ATASCII
// convert_atascii: if non-zero, convert files from ATASCII to UTF8
// Returns 0 on success, 1 on error
int convertatr_sector_size(const char *input_file, const char *output_file, unsigned new_sector_size,
                            int convert_utf8, int convert_atascii);
