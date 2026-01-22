# Attributions

This project stands on the shoulders of some seriously impressive work. Let's give credit where credit is due, because without the foundation, we'd just be standing here with a pile of bits and no idea what to do with them.

## The Original Architect: Daniel Serpell

**Daniel Serpell** - The brilliant mind behind the original mkatr and lsatr tools. This is the person who looked at Atari disk images and said "I can make tools for that" - and then actually did it. And did it well.

### What This Amazing Human Built

Daniel created the entire foundation that atrforge is built on. We're talking about:

- **The core ATR image creation and extraction engine** - The thing that actually makes disk images work. This isn't trivial. Disk formats are weird, and getting them right takes serious skill.

- **Multi-format DOS support** - The ability to read from SpartaDOS, Atari DOS, MyDOS, LiteDOS, and more. Each of these formats is different, with its own quirks and peculiarities. Supporting them all? That's the work of someone who really knows their stuff.

- **The filesystem implementations** - Understanding how these old filesystems work, parsing their structures, extracting files correctly. This is the kind of work that makes you appreciate how clever people can be.

- **The entire tool architecture** - A clean, well-designed codebase that's actually maintainable. In 2026, we're still building on code that was written years ago, and it's still solid. That's quality engineering.

Seriously, without Daniel's work, atrforge wouldn't exist. We'd be starting from scratch, and that would be... well, let's just say we're glad we didn't have to do that. The original mkatr tools were already excellent - we just added some modern touches and security improvements.

**Thank you, Daniel, for building something awesome that we could build upon.**

## What We Added (2026)

**Rick Collette & AtariFoundry.com** - We came along and said "this is great, but what if we made it even better?" So we did some things:

### Security Improvements

Because security matters, even for 8-bit disk images:
- Path traversal prevention (because `../` shouldn't escape directories)
- Input validation and sanitization (trust but verify, you know?)
- Integer overflow protection (math is hard, but we try)
- Sector number validation (boundaries are important)
- Memory safety improvements (because crashes are no fun)

### New Features

Because more features are more betterer:
- **ATR file modification** - Add files to existing images without recreating everything
- **ATR conversion tool** - Resize and convert between formats
- **Enhanced CLI options** - Quiet mode, force overwrite, verification
- **UTF8/ATASCII conversion** - Because modern editors are picky
- **Comprehensive documentation** - Because good tools deserve good docs

### Code Quality

Because clean code is happy code:
- Better error handling (errors happen, but we handle them gracefully)
- Improved consistency (because consistency is the hobgoblin of... actually, it's just good practice)
- Documentation updates (we wrote a lot of words about this stuff)

## The Bottom Line

Daniel Serpell built something excellent. We took that excellent foundation and added modern security practices, new features, and a whole lot of documentation. The result is atrforge - a toolkit that honors the original work while bringing it into the modern era.

We're proud to build on such a solid foundation. Thanks for making our job easier, Daniel!

## License

This program is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software Foundation,
either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this
program. If not, see <http://www.gnu.org/licenses/>.

## Technical Details (For the Curious)

### Files Created by Rick Collette & AtariFoundry.com

- `src/modatr.h` / `src/modatr.c` - ATR modification interface and implementation
- `src/convertatr.h` / `src/convertatr.c` / `src/convertatr_main.c` - ATR conversion tool
- `src/atrcp.c` - File copy tool for ATR images
- `src/convert.c` / `src/convert.h` - UTF8/ATASCII conversion library
- `SECURITY.md` - Security documentation
- `CHANGELOG.md` - Change log
- `ATTRIBUTIONS.md` - This file (hi!)
- All the documentation in `docs/` - Because documentation is important

### Files Enhanced by Rick Collette & AtariFoundry.com

We improved many of Daniel's original files with security fixes, validation, and new features:
- `src/compat.c` / `src/compat.h` - Path sanitization
- `src/lssfs.c` / `src/lsdos.c` / `src/lsextra.c` - Security and validation improvements
- `src/spartafs.c` / `src/atr.c` / `src/mkatr.c` - Safety and error handling enhancements
- `src/lsatr.c` - New CLI options
- `src/flist.c` - String safety improvements
- Various header files - Updated function signatures
- `README.md` - Enhanced with new information

The original code structure and design philosophy remain intact - we just made it safer and added some modern conveniences.

---

*Building on excellence since 2026.*
