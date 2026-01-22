# atrforge - Create ATR Disk Images

`atrforge` is the tool that started it all. It creates Atari ATR disk images from files you give it. Think of it as a disk image factory that takes your files and packages them into a nice, tidy ATR image that your Atari (or emulator) can actually use.

## Overview

atrforge creates ATR disk images in SpartaDOS/BW-DOS format. You provide a list of files, and it figures out the best disk size to fit them all. It's smarter than it looks.

**What it does:**
- Creates new ATR images from files
- Adds files to existing ATR images
- Creates bootable disk images
- Handles directory structures
- Sets file attributes (protected, hidden, archived)
- Converts UTF8 files to ATASCII on the fly

**What it doesn't do:**
- Read existing disk images (that's `lsatr`'s job)
- Convert between formats (that's `convertatr`'s job)
- Make coffee (we're working on it)

## Command Syntax

```bash
atrforge [options] <output_atr> [+attributes] <file_1> [... <file_n>]
```

The basic pattern is: options, output file, then your files. Simple enough, right?

## Options

### `-a` - Add to Existing Image

Adds files to an existing ATR image instead of creating a new one. The existing image must be in SpartaDOS/BW-DOS format (because that's what we create, and we're not mind readers).

```bash
atrforge -a existing.atr newfile.com
```

**Note:** This creates a backup of the original file (with `.bak` extension) before modifying it. Because we're nice like that.

### `-b` - Boot File

Marks the next file as the boot file. This file will be loaded when the Atari boots from the disk. The file must be in standard Atari binary format (`.com`, `.xex`, etc.).

```bash
atrforge -b game.atr mygame.com
```

**Bootloader requirements:**
- 128-byte sectors: Bootloader needs 613 bytes, from $700 to $965
- 256-byte sectors: Bootloader needs 848 bytes, from $700 to $A50

Both can be relocated with the `-B` option if you need to avoid memory conflicts.

### `-x` - Exact Sector Count

Creates an image with the exact sector count needed for all content. This uses non-standard sector counts and will use 128-byte sectors if the image is smaller than about 8MB.

```bash
atrforge -x custom.atr file1.com file2.bas
```

Useful when you need a specific size or want to minimize disk space usage. Most of the time, you don't need this.

### `-s <size>` - Minimum Size

Specifies the minimum size of the output image in bytes. The image will be at least this size (or larger, depending on the standard sizes).

```bash
atrforge -s 360000 disk.atr file.com
```

This is handy when you want extra free space on the disk. Combine with `-x` to create images of specific sizes (up to the sector size limit).

### `-B <page>` - Relocate Bootloader

Relocates the bootloader to a different page address. The page is the high byte of the address (so page 7 = $0700, page 6 = $0600, etc.).

```bash
atrforge -B 6 -b game.atr mygame.com
```

**Why would you need this?** Some games or programs load at low addresses that conflict with the standard bootloader location (page 7, $700). Relocating to page 6, 5, or even 4 can solve this. Just make sure you know what you're doing - wrong addresses can cause your boot file to not work.

**Safe values:** Page 6 is usually safe. Pages 4-5 are possible but riskier.

### `--to-atascii` - Convert UTF8 to ATASCII

Converts files from UTF8 to ATASCII when adding them to the ATR. This is useful when you've edited files in a modern UTF8 editor and need them in ATASCII format for the Atari.

```bash
atrforge --to-atascii disk.atr source.bas
```

See [UTF8 Conversion](UTF8_CONVERSION.md) for more details on this process.

### `-h` - Help

Shows a brief help message. You're reading the extended version right now.

### `-v` - Version

Shows version information. Because sometimes you need to know what version you're running.

## File Attributes

You can set attributes on individual files by prefixing the filename with attribute flags:

### `+p` - Protected (Read-Only)

Marks the file as protected (read-only). The Atari won't let you delete or modify it.

```bash
atrforge disk.atr +p important.com
```

### `+h` - Hidden

Hides the file from directory listings. This only works in SpartaDOS-X, so don't expect it to work everywhere.

```bash
atrforge disk.atr +h secret.com
```

### `+a` - Archived

Marks the file as archived. This is a SpartaDOS-X feature that indicates the file has been backed up.

```bash
atrforge disk.atr +a backup.com
```

### Combining Attributes

You can combine attributes:

```bash
atrforge disk.atr +ph hidden_protected.com
```

This makes the file both hidden and protected. Because sometimes you really don't want people messing with your files.

## Directory Structure

To place files in subdirectories, simply list the directory before the files that go in it:

```bash
atrforge disk.atr games/ game1.com game2.com utils/ util1.com
```

This creates:
- `games/game1.com`
- `games/game2.com`
- `utils/util1.com`

Directories are created automatically. You don't need to create them first. We're helpful like that.

## Disk Size Formats

atrforge automatically chooses the smallest standard disk size that fits all your files. The available sizes are:

| Sector Count | Sector Size | Total Size | Name |
|-------------|-------------|------------|------|
| 720 | 128 | 90k | SD (Single Density) |
| 1040 | 128 | 130k | ED (Enhanced Density) |
| 720 | 256 | 180k | DD (Double Density) |
| 1440 | 256 | 360k | DSDD (Double-Sided Double Density) |
| 2048 | 256 | 512k | Hard disk |
| 4096 | 256 | 1M | Hard disk |
| 8192 | 256 | 2M | Hard disk |
| 16384 | 256 | 4M | Hard disk |
| 32768 | 256 | 8M | Hard disk |
| 65535 | 256 | 16M | Biggest possible image |

If you use the `-x` option, it will use non-standard sizes and 128-byte sectors for smaller images.

## Examples

### Basic Image Creation

Create a simple disk image with a few files:

```bash
atrforge mydisk.atr file1.com file2.bas file3.txt
```

### Bootable Disk

Create a bootable disk with a game:

```bash
atrforge -b game.atr mygame.com
```

### Bootable Disk with DOS

Create a bootable disk with DOS and a startup file:

```bash
atrforge bwdos.atr dos/ -b +ph dos/xbw130.dos +p startup.bat
```

This creates:
- A bootable disk (`-b`)
- DOS file is hidden and protected (`+ph`)
- Startup file is protected (`+p`)
- DOS is in a subdirectory (`dos/`)

### Adding Files to Existing Image

Add more files to an existing disk:

```bash
atrforge -a existing.atr newfile1.com newfile2.bas
```

### Directory Structure

Create a disk with organized directories:

```bash
atrforge organized.atr \
    games/ game1.com game2.com \
    utils/ util1.com util2.com \
    docs/ readme.txt manual.txt
```

### Protected System Files

Create a disk with protected system files:

```bash
atrforge system.atr +p config.sys +p autoexec.bat normal.com
```

### UTF8 Conversion

Convert UTF8 files to ATASCII when creating the disk:

```bash
atrforge --to-atascii disk.atr edited.bas converted.txt
```

### Custom Size with Extra Space

Create a disk with a minimum size for future files:

```bash
atrforge -s 360000 disk.atr current_files.com
```

This creates at least a 360k disk, even if the files would fit in a smaller one.

## Tips and Tricks

1. **Order matters for boot files**: The `-b` option applies to the *next* file, so put it right before the boot file.

2. **Attributes apply to one file**: Each `+attribute` prefix only affects the file immediately following it.

3. **Directories are implicit**: Just list the directory name, then the files. No need to create directories first.

4. **Backups are automatic**: When using `-a`, a `.bak` file is created automatically. Don't worry, we've got your back.

5. **Size calculation is smart**: atrforge picks the smallest size that fits. If you need more space, use `-s`.

## Common Mistakes

- **Forgetting `-b` before the boot file**: The boot file won't be bootable if you forget the flag.
- **Wrong file format for boot**: Boot files must be in Atari binary format. Text files won't work.
- **Using `-a` on non-SpartaDOS images**: Only works with SpartaDOS/BW-DOS format images.
- **Attribute syntax**: It's `+p`, not `-p` or `--protected`. The `+` is important.

## See Also

- [Examples](EXAMPLES.md) - More usage examples
- [Boot Files](BOOT_FILES.md) - Detailed boot file information
- [File Attributes](FILE_ATTRIBUTES.md) - More on file attributes
- [UTF8 Conversion](UTF8_CONVERSION.md) - UTF8/ATASCII conversion details
- [ATR Format](ATR_FORMAT.md) - Technical details about ATR format

---

*For the complete tool list, see the [main documentation index](README.md).*
