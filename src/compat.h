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
#pragma once

#include <stddef.h>

// Checks if given character is a PATH separator
int is_separator(char c);

// Wrapper for mkdir
int compat_mkdir(const char *path);

// Sanitize path to prevent directory traversal attacks
// Returns 1 if path is safe, 0 if path contains dangerous components
// Safe path is written to output buffer (must be at least PATH_MAX or strlen(path)+1 bytes)
int sanitize_path(const char *path, char *output, size_t output_size);
