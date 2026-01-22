# DOS Formats Support

The Atari 8-bit world had many different DOS formats. Some were official, some were third-party, and some were... creative. atrforge tools support reading from many of them, and creating images in SpartaDOS/BW-DOS format. Let's talk about what works and what doesn't.

## Creation Support

### SpartaDOS / BW-DOS

**Full read/write support.** This is what `atrforge` creates, and it's what most of the tools work with.

**Features:**
- Up to 16MB images
- Subdirectories
- File attributes (protected, hidden, archived)
- Long filenames (up to 11 characters, 8.3 format)
- Efficient filesystem structure

**Why this format?** It's widely supported, efficient, and has all the features you need. It's the format of choice for most modern Atari software.

## Read-Only Support

These formats can be read and extracted, but not created or modified by atrforge tools:

### Atari DOS 1.0

The original Atari DOS. Single density only (90k disks).

**Limitations:**
- Single density only
- No subdirectories
- Simple file structure
- 64 files maximum per disk

**When you'll see it:** Old software, original Atari disks from the early 1980s.

### Atari DOS 2.0

The improved Atari DOS. Supports both single and double density.

**Features:**
- Single and double density
- Better file management
- Still no subdirectories
- 64 files maximum per disk

**When you'll see it:** Most commercial Atari software from the mid-1980s.

### Atari DOS 2.5

Enhanced density support. The last official Atari DOS.

**Features:**
- Single, double, and enhanced density (130k)
- Improved file handling
- Still no subdirectories
- 64 files maximum per disk

**When you'll see it:** Later Atari software, enhanced density disks.

### MyDOS

A popular third-party DOS that supports large disks.

**Features:**
- Up to 16MB images
- Subdirectories
- Better file management than Atari DOS
- More files per disk

**When you'll see it:** Power users, large disk images, modern Atari software.

### LiteDOS 2.x / LiteDOS-SE

Lightweight DOS variants. Simple but functional.

**Features:**
- Basic file management
- Subdirectory support (in some versions)
- Smaller footprint than full DOS

**When you'll see it:** Minimal setups, boot disks, specialized applications.

## Special Formats

These aren't really DOS formats, but they're stored in ATR files:

### BAS2BOOT Images

A bootable image format that contains a BASIC program.

**What it is:** An ATR image with a BASIC program that boots automatically.

**What atrforge does:** Extracts the BASIC file from the image.

**When you'll see it:** Bootable BASIC programs, educational software.

### Howfen DOS Images

A specialized boot image format.

**What it is:** A bootable image with a specific structure.

**What atrforge does:** Extracts the raw BOOT image.

**When you'll see it:** Specialized boot disks, custom boot loaders.

### K-file Boot Images

Boot images that contain XEX files.

**What it is:** A bootable image with an XEX file inside.

**What atrforge does:** Extracts the XEX file.

**When you'll see it:** Game boot disks, executable boot images.

## Format Detection

When you use `lsatr` on an ATR image, it tries to detect the format automatically:

1. **SpartaDOS/BW-DOS** - Checks for SpartaDOS filesystem structure
2. **Howfen DOS** - Checks for Howfen DOS signature
3. **Atari DOS** - Checks VTOC and directory structure
4. **MyDOS** - Checks MyDOS signature and structure
5. **LiteDOS** - Checks LiteDOS signature
6. **Special formats** - Checks for BAS2BOOT, K-file, etc.

It tries each format in order until it finds one that works. If none work, it reports that the format isn't supported.

## Compatibility Notes

### What Works

- **Reading:** All listed formats can be read and files extracted
- **Creating:** Only SpartaDOS/BW-DOS images can be created
- **Modifying:** Only SpartaDOS/BW-DOS images can be modified (with `-a` or `atrcp`)

### What Doesn't Work

- **Creating other formats:** You can't create Atari DOS, MyDOS, or other format images
- **Converting formats:** You can't convert between DOS formats (only ATR format conversion)
- **Some features:** Not all features work with all formats (attributes, subdirectories, etc.)

### Limitations by Format

| Format | Read | Write | Subdirs | Attributes | Max Size |
|--------|------|-------|---------|------------|----------|
| SpartaDOS/BW-DOS | ✓ | ✓ | ✓ | ✓ | 16MB |
| Atari DOS 1 | ✓ | ✗ | ✗ | ✗ | 90k |
| Atari DOS 2.0 | ✓ | ✗ | ✗ | ✗ | 180k |
| Atari DOS 2.5 | ✓ | ✗ | ✗ | ✗ | 130k |
| MyDOS | ✓ | ✗ | ✓ | ✗ | 16MB |
| LiteDOS | ✓ | ✗ | Partial | ✗ | Varies |

## Why Only SpartaDOS/BW-DOS for Creation?

Good question. Here's why:

1. **It's the most capable** - Supports everything you need
2. **It's widely compatible** - Works with most Atari systems and emulators
3. **It's what we know** - The tools were designed around this format
4. **It's efficient** - Good filesystem structure and performance

If you need other formats, you can:
- Create in SpartaDOS/BW-DOS, then convert on the Atari
- Use other tools that support those formats
- Extract from existing images and work with the files

## Tips for Working with Different Formats

1. **Check format first** - Use `lsatr` to see what format an image uses
2. **Extract and recreate** - If you need to modify a non-SpartaDOS image, extract files and create a new SpartaDOS image
3. **Preserve originals** - Keep original images when extracting, in case you need the original format
4. **Check compatibility** - Make sure your target system supports the format you're creating

## See Also

- [atrforge](ATRFORGE.md) - Creating SpartaDOS/BW-DOS images
- [lsatr](LSATR.md) - Reading and extracting from various formats
- [ATR Format](ATR_FORMAT.md) - Technical details about ATR file format

---

*For the complete tool list, see the [main documentation index](README.md).*
