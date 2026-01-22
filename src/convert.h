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
#pragma once
#include <stdio.h>
#include <stdint.h>
#include <stddef.h>

// Convert UTF8 file to ATASCII file
// Returns 0 on success, non-zero on error
int convert_utf8_to_atascii_file(const char *input_file, const char *output_file);

// Convert ATASCII file to UTF8 file
// sevenbit: if non-zero, strip high bit (7-bit mode)
// Returns 0 on success, non-zero on error
int convert_atascii_to_utf8_file(const char *input_file, const char *output_file, 
                                  int sevenbit);

// Buffer-based conversions (for in-memory processing)
// Output buffer is allocated and must be freed by caller
// Returns 0 on success, non-zero on error
int convert_buffer_utf8_to_atascii(const uint8_t *input, size_t input_size, 
                                    uint8_t **output, size_t *output_size);

int convert_buffer_atascii_to_utf8(const uint8_t *input, size_t input_size, 
                                    uint8_t **output, size_t *output_size,
                                    int sevenbit);
