<!--
  Copyright (C) 2026 Rick Collette & AtariFoundry.com

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License along
  with this program.  If not, see <http://www.gnu.org/licenses/>
-->

# Changelog

All notable changes to the atrforge tools will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### New Features

- **UTF8/ATASCII Conversion Support** (2026-01-21): Added comprehensive UTF8 ↔ ATASCII conversion
  functionality across all tools, allowing seamless editing of ATASCII files in modern UTF8 editors:
  - New shared conversion library (`src/convert.c`, `src/convert.h`) based on example implementation
  - **convertatr**: Added `--convert-utf8` and `--convert-atascii` options to convert files during
    ATR resize/sector conversion operations
  - **atrcp**: Added `--to-utf8`, `--to-atascii`, and `--7bit` options:
    - `--to-utf8`: Convert ATASCII to UTF8 when extracting files from ATR
    - `--to-atascii`: Convert UTF8 to ATASCII when adding files to ATR
    - `--7bit`: Use 7-bit mode (strip high bit) for ATASCII→UTF8 conversion
  - **atrforge**: Added `--to-atascii` option to convert files from UTF8 to ATASCII when creating
    or adding to ATR images
  - Conversion handles newline conversion (0x0a ↔ 155) and UTF8 multi-byte sequences
  - Files affected: `src/convert.c`, `src/convert.h`, `src/convertatr.c`, `src/convertatr_main.c`,
    `src/atrcp.c`, `src/mkatr.c`, `src/flist.c`, `src/flist.h`, `Makefile`

- **ATR File Copy Tool** (2026-01-21): New `atrcp` program for copying files between ATR images
  and the host filesystem:
  - Extract files from ATR images: `atrcp image.atr:path/to/file.ext output.ext`
  - Add files to ATR images: `atrcp input.ext image.atr:path/to/file.ext`
  - Supports SpartaDOS/BW-DOS filesystem format
  - Creates automatic backups when modifying ATR files
  - Files affected: `src/atrcp.c`, `Makefile`

- **ATR File Modification** (2026-01-21): Added ability to add files to existing ATR images
  using the `-a` option in `atrforge`. This creates a backup of the original file
  before modification.
  - Files affected: `src/mkatr.c`, `src/modatr.c`, `src/modatr.h`
  - Note: Full in-place modification (delete/rename) requires additional
    implementation

- **ATR Conversion Tool** (2026-01-21): New `convertatr` program for converting and resizing
  ATR images:
  - Resize images to different sector counts
  - Convert between 128-byte and 256-byte sector sizes
  - Files affected: `src/convertatr.c`, `src/convertatr.h`, `src/convertatr_main.c`

### New Features (from previous release)

- **Enhanced CLI Options** (2026-01-21): Added new command-line options to `lsatr`:
  - `-q` (quiet mode): Suppress informational messages
  - `-f` (force overwrite): Allow overwriting existing files during extraction
  - `--verify`: Verify ATR image integrity (checks if image loads correctly and has valid structure)
  - Files affected: `src/lsatr.c`, `src/msg.c`, `src/msg.h`, `src/lssfs.c`, `src/lsdos.c`, `src/lsextra.c`, `src/lshowfen.c`

### Security Fixes

- **Path Traversal Prevention** (2026-01-21): Added comprehensive path sanitization to prevent
  directory traversal attacks when extracting files from ATR images. All file
  paths are now validated to remove `..` components and reject absolute paths.
  - Implemented `sanitize_path()` function in `compat.c`
  - Applied path sanitization in `lssfs.c`, `lsdos.c`, and `lsextra.c`
  - Files affected: `src/compat.c`, `src/compat.h`, `src/lssfs.c`, `src/lsdos.c`, `src/lsextra.c`

- **Unchecked asprintf Return Values** (2026-01-21): Added error checking for all `asprintf()`
  calls to handle memory allocation failures properly.
  - Files affected: `src/lssfs.c`, `src/lsdos.c`, `src/lsextra.c`

- **Unsafe String Operations** (2026-01-21): Replaced unsafe `strcpy()` and `strcat()` calls
  with bounds-checked alternatives (`strncpy()`, `snprintf()`).
  - Files affected: `src/lsextra.c`, `src/flist.c`

- **Sector Number Validation** (2026-01-21): Added comprehensive sector number validation in
  all sector access functions to prevent out-of-bounds access.
  - Added validation in `file_msize()` and `read_file()` in `lssfs.c`
  - Added validation in `read_file()` in `lsdos.c`
  - Added validation in `sfs_ptr()`, `sfs_free_sec()`, and `sfs_used()` in `spartafs.c`
  - Added loop detection to prevent infinite loops in sector chains
  - Files affected: `src/lssfs.c`, `src/lsdos.c`, `src/spartafs.c`

- **Integer Overflow Protection** (2026-01-21): Added overflow checks in size calculations to
  prevent buffer overflows and integer wraparound.
  - Added checks in `image_size()` and `write_atr()` in `mkatr.c`
  - Added checks in `load_atr_image()` in `atr.c`
  - Files affected: `src/mkatr.c`, `src/atr.c`

### Code Quality Improvements

- **Build System Organization** (2026-01-21): Improved build system organization:
  - All compiled binaries now placed in `bin/` directory instead of root directory
  - Updated `make clean` to remove both `obj/` and `bin/` directories
  - Better separation of build artifacts and final binaries
  - Files affected: `Makefile`

- **Error Message Consistency** (2026-01-21): Standardized all error messages to use "can't"
  instead of "can´t" throughout the codebase.
  - Files affected: `src/atr.c`, `src/mkatr.c`, `src/lsdos.c`, `src/lssfs.c`, `src/lsextra.c`, `src/lshowfen.c`

- **Error Handling** (2026-01-21): Improved error handling by:
  - Checking `fwrite()` return values in `mkatr.c`
  - Adding better error context to error messages
  - Ensuring proper cleanup in error paths

- **Memory Safety** (2026-01-21): Improved memory management by:
  - Ensuring proper cleanup in all error paths
  - Validating memory allocation results
  - Preventing memory leaks in error conditions

### Documentation

- **README Updates** (2026-01-21): Enhanced README.md with:
  - Security considerations section
  - Build requirements
  - Known limitations
  - Installation instructions

- **Security Documentation** (2026-01-21): Created `SECURITY.md` with:
  - Security features overview
  - Security recommendations for users and developers
  - Security issue reporting guidelines

- **Changelog** (2026-01-21): Created `CHANGELOG.md` to track all changes, improvements, and
  security fixes.

## [1.4~beta] - Previous Release

### Features

- Support for creating ATR images with SpartaDOS/BW-DOS filesystem
- Support for listing and extracting from multiple DOS formats:
  - Atari DOS 1, 2.0, 2.5
  - MyDOS
  - SpartaDOS and BW-DOS
  - LiteDOS 2.x and LiteDOS-SE
  - BAS2BOOT images
  - Howfen DOS images
  - K-file boot images

- Boot file support with configurable bootloader address
- File attribute support (protected, hidden, archived)
- Directory structure support
- Multiple disk size formats (90k to 16MB)

### Known Issues (Fixed in Unreleased)

- Path traversal vulnerability in file extraction
- Unchecked memory allocation return values
- Unsafe string operations
- Missing sector number validation
- Integer overflow vulnerabilities
- Inconsistent error message formatting

---

## Version History

- **1.4~beta**: Initial public release with core functionality
- **Unreleased**: Security fixes and code quality improvements
