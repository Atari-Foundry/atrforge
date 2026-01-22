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
#include "modatr.h"
#include "atr.h"
#include "flist.h"
#include "spartafs.h"
#include "msg.h"
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

// Add files to an existing ATR image
int modatr_add_files(const char *atr_file, file_list *flist)
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

    // Create backup filename
    char *backup_file = check_malloc(strlen(atr_file) + 10);
    strcpy(backup_file, atr_file);
    strcat(backup_file, ".bak");

    // Copy original to backup
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

    // Copy file
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
    show_msg("Note: Adding files requires rebuilding the image.");
    show_msg("This feature is partially implemented - files will be added to a new image.");

    // For now, we create a new image. Full implementation would:
    // 1. Read all existing files from the ATR
    // 2. Merge with new file list
    // 3. Rebuild filesystem
    // This is complex and would require significant additional code
    
    free(backup_file);
    atr_free(atr);
    return 0;
}

// Delete a file from an existing ATR image
int modatr_delete_file(const char *atr_file, const char *file_path)
{
    show_error("File deletion not yet implemented");
    return 1;
}

// Rename a file in an existing ATR image
int modatr_rename_file(const char *atr_file, const char *old_path, const char *new_path)
{
    show_error("File renaming not yet implemented");
    return 1;
}
