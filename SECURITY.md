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

# Security Best Practices for atrforge Tools

## Overview

The atrforge tools (`atrforge` and `lsatr`) have been designed with security in mind,
but users should be aware of potential security considerations when working with
ATR disk images, especially from untrusted sources.

## Security Features

### Path Sanitization

The tools implement comprehensive path sanitization when extracting files from
ATR images:

- **Directory Traversal Prevention**: All `..` components in paths are removed
  or rejected to prevent escaping the extraction directory
- **Absolute Path Rejection**: Absolute paths (starting with `/` or `\`) are
  rejected when extracting files
- **Path Component Validation**: All path components are validated to ensure
  they don't contain path separators or other dangerous characters

### Input Validation

- **Sector Number Validation**: All sector numbers read from disk images are
  validated against the image's sector count before access
- **Integer Overflow Protection**: Size calculations include overflow checks to
  prevent buffer overflows
- **Memory Allocation Checks**: All memory allocation failures are properly
  handled

### Error Handling

- **Safe String Operations**: Unsafe string functions (`strcpy`, `strcat`) have
  been replaced with bounds-checked alternatives
- **Format String Safety**: All format strings in error messages are controlled
  by the application, not user input

## Security Recommendations

### For Users

1. **Untrusted ATR Images**: Be cautious when extracting files from ATR images
   obtained from untrusted sources. While path sanitization prevents directory
   traversal, malicious images could still contain:
   - Very long filenames that might cause issues
   - Files with unusual attributes
   - Corrupted filesystem structures

2. **Extraction Directory**: When using `lsatr -X`, ensure the extraction
   directory is:
   - In a location you control
   - Not a system directory
   - Has appropriate permissions

3. **File Permissions**: Extracted files are created with mode 0666 (read/write
   for all). Review and adjust permissions as needed after extraction.

4. **Large Images**: Very large ATR images (approaching the 16MB limit) may
   consume significant memory. Ensure your system has adequate resources.

### For Developers

1. **Memory Safety**: Always validate:
   - Sector numbers before array access
   - Size calculations for overflow
   - Buffer bounds before memory operations

2. **Path Handling**: Never trust paths from disk images. Always:
   - Sanitize paths before file operations
   - Validate against the extraction directory
   - Reject absolute paths

3. **Error Handling**: Ensure all error paths:
   - Free allocated memory
   - Close file descriptors
   - Provide clear error messages

## Reporting Security Issues

If you discover a security vulnerability in the atrforge tools, please:

1. **Do not** open a public issue
2. Contact the maintainers privately
3. Provide detailed information about the vulnerability
4. Allow time for a fix before public disclosure

## Security History

See `CHANGELOG.md` for a complete history of security fixes and improvements.
