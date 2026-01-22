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
 * Modify existing ATR images.
 */
#pragma once
#include "atr.h"
#include "flist.h"

// Add files to an existing ATR image
// Returns 0 on success, 1 on error
int modatr_add_files(const char *atr_file, file_list *flist);

// Delete a file from an existing ATR image
// Returns 0 on success, 1 on error
int modatr_delete_file(const char *atr_file, const char *file_path);

// Rename a file in an existing ATR image
// Returns 0 on success, 1 on error
int modatr_rename_file(const char *atr_file, const char *old_path, const char *new_path);
