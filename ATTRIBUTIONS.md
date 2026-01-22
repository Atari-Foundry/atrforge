# Attributions

This project is based on the original mkatr tools by Daniel Serpell, with significant
enhancements, security improvements, and new features added by Rick Collette and
AtariFoundry.com. The project has been rebranded as **atrforge**.

## Original Author

**Daniel Serpell** - Original author of the mkatr and lsatr tools (now rebranded as atrforge)
- Original implementation of ATR image creation and extraction
- Support for multiple DOS formats (SpartaDOS, Atari DOS, MyDOS, LiteDOS, etc.)
- Original filesystem implementations

## Enhancements and Contributions

**Rick Collette & AtariFoundry.com (2026)** - Security improvements, new features, and enhancements
- Security fixes:
  - Path traversal prevention
  - Input validation and sanitization
  - Integer overflow protection
  - Sector number validation
  - Memory safety improvements
- New features:
  - ATR file modification capabilities (`modatr`)
  - ATR conversion tool (`convertatr`)
  - Enhanced CLI options (quiet mode, force overwrite, verify)
  - Comprehensive documentation (SECURITY.md, CHANGELOG.md)
- Code quality improvements:
  - Error handling enhancements
  - Code consistency improvements
  - Documentation updates

## License

This program is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software Foundation,
either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this
program. If not, see <http://www.gnu.org/licenses/>.

## Files Modified/Created by Rick Collette & AtariFoundry.com

### New Files Created
- `src/modatr.h` - ATR modification interface
- `src/modatr.c` - ATR modification implementation
- `src/convertatr.h` - ATR conversion interface
- `src/convertatr.c` - ATR conversion implementation
- `src/convertatr_main.c` - convertatr main program
- `SECURITY.md` - Security documentation
- `CHANGELOG.md` - Change log
- `ATTRIBUTIONS.md` - This file

### Files Significantly Modified
- `src/compat.c` - Added path sanitization function
- `src/compat.h` - Added path sanitization declaration
- `src/lssfs.c` - Added path sanitization, asprintf checks, sector validation
- `src/lsdos.c` - Added path sanitization, asprintf checks, sector validation
- `src/lsextra.c` - Added path sanitization, asprintf checks, string safety
- `src/flist.c` - Added string safety improvements
- `src/spartafs.c` - Added sector validation
- `src/atr.c` - Added sector validation, overflow protection
- `src/mkatr.c` - Added overflow protection, modification support, error handling
- `src/lsatr.c` - Added CLI enhancements (quiet, force, verify)
- `src/msg.c` - Added quiet mode support
- `src/msg.h` - Added quiet mode declaration
- `src/lssfs.h` - Updated function signatures
- `src/lsdos.h` - Updated function signatures
- `src/lsextra.h` - Updated function signatures
- `src/lshowfen.h` - Updated function signatures
- `README.md` - Updated with new features and security information
