# atrcp - Copy Files to and from ATR Images

`atrcp` is the file courier of the atrforge toolkit. It copies individual files between ATR images and your host filesystem. Think of it as `cp`, but for files inside disk images. It's actually quite handy when you just need to update one file without recreating the entire disk.

## Overview

atrcp is the newest addition to the toolkit (well, relatively speaking). It's designed for quick file operations - when you just need to copy one file in or out of an ATR image without the overhead of extracting everything or recreating the image.

**What it does:**
- Extracts individual files from ATR images
- Adds individual files to ATR images
- Converts between UTF8 and ATASCII on the fly
- Creates automatic backups when modifying ATR files

**What it doesn't do:**
- List directory contents (that's `lsatr`'s job)
- Create new images (that's `atrforge`'s job)
- Convert entire images (that's `convertatr`'s job)
- Make your files faster (we're not that good)

## Command Syntax

```bash
atrcp [options] <source> <destination>
```

The source and destination can be either regular files or files inside ATR images (using the special `image.atr:path` syntax).

## ATR Path Format

Files inside ATR images are specified using a colon separator:

```
image.atr:path/to/file.ext
```

The format is: `image_file:path_inside_image`

Examples:
- `disk.atr:MYFILE.COM` - File in root directory
- `disk.atr:GAMES/GAME1.COM` - File in subdirectory
- `disk.atr:` - Just the image (for adding files, uses source filename)

If you omit the path after the colon when adding a file, it uses the source filename. Convenient!

## Options

### `--to-utf8` - Convert ATASCII to UTF8

Converts the file from ATASCII to UTF8 when extracting from an ATR. This is useful if you want to edit the file in a modern UTF8 editor.

```bash
atrcp --to-utf8 disk.atr:SOURCE.BAS source.bas
```

The conversion happens during extraction, so you get a UTF8 file ready for editing.

### `--to-atascii` - Convert UTF8 to ATASCII

Converts the file from UTF8 to ATASCII when adding to an ATR. This is useful if you've edited a file in UTF8 and need it back in ATASCII format.

```bash
atrcp --to-atascii source.bas disk.atr:SOURCE.BAS
```

The conversion happens during the add operation, so your UTF8 file becomes ATASCII in the image.

### `--7bit` - 7-bit Mode

Uses 7-bit mode for ATASCII→UTF8 conversion. This strips the high bit from characters, effectively converting to 7-bit ASCII.

```bash
atrcp --7bit --to-utf8 disk.atr:FILE.TXT file.txt
```

Useful when you want pure 7-bit ASCII without the high-bit characters that ATASCII uses.

**Note:** This only affects ATASCII→UTF8 conversion. It doesn't do anything for UTF8→ATASCII.

### `-h` - Help

Shows a brief help message. You're reading the extended version.

### `-v` - Version

Shows version information. Version numbers matter.

## Usage Patterns

### Extract from ATR

Extract a file from an ATR image to the host filesystem:

```bash
atrcp disk.atr:MYFILE.COM myfile.com
```

Or to the current directory using the same name:

```bash
atrcp disk.atr:MYFILE.COM .
```

### Add to ATR

Add a file from the host filesystem to an ATR image:

```bash
atrcp myfile.com disk.atr:MYFILE.COM
```

Or let it use the source filename:

```bash
atrcp myfile.com disk.atr:
```

This adds `myfile.com` to the root of the disk with the same name.

### Add to Subdirectory

Add a file to a subdirectory in the ATR:

```bash
atrcp myfile.com disk.atr:GAMES/MYFILE.COM
```

The directory is created automatically if it doesn't exist. How helpful!

## Examples

### Basic Extract

Extract a file from an ATR:

```bash
atrcp disk.atr:PROGRAM.COM program.com
```

### Basic Add

Add a file to an ATR:

```bash
atrcp program.com disk.atr:PROGRAM.COM
```

### Extract with UTF8 Conversion

Extract and convert to UTF8:

```bash
atrcp --to-utf8 disk.atr:SOURCE.BAS source.bas
```

### Add with ATASCII Conversion

Add and convert to ATASCII:

```bash
atrcp --to-atascii source.bas disk.atr:SOURCE.BAS
```

### Extract with 7-bit Mode

Extract and convert to UTF8 using 7-bit mode:

```bash
atrcp --7bit --to-utf8 disk.atr:FILE.TXT file.txt
```

### Add to Subdirectory

Add a file to a subdirectory:

```bash
atrcp game.com disk.atr:GAMES/GAME.COM
```

### Use Source Filename

Add a file using its original name:

```bash
atrcp myfile.com disk.atr:
```

This adds `myfile.com` to the root directory of the disk.

### Update Existing File

Update an existing file in the ATR:

```bash
atrcp updated.com disk.atr:OLD.COM
```

This replaces `OLD.COM` with the contents of `updated.com`. A backup is created automatically (see below).

## Automatic Backups

When atrcp modifies an ATR image (by adding or updating files), it automatically creates a backup of the original image. The backup has a `.bak` extension:

- Original: `disk.atr`
- Backup: `disk.atr.bak`

This way, if something goes wrong, you can restore the original. We're looking out for you.

**Note:** The backup is created before any modifications, so your original is safe.

## UTF8/ATASCII Conversion

atrcp can convert files between UTF8 and ATASCII during copy operations. This is useful when:

- You want to edit files in a modern UTF8 editor
- You've edited files in UTF8 and need them back in ATASCII
- You're working with text files that need conversion

See [UTF8 Conversion](UTF8_CONVERSION.md) for more details on how the conversion works.

## Tips and Tricks

1. **Use `:` for same-name adds** - When adding a file, you can use `disk.atr:` to use the source filename automatically.

2. **Backups are automatic** - Don't worry about backing up - atrcp does it for you.

3. **Directories are created automatically** - If you specify a path that doesn't exist, it's created for you.

4. **Conversion is on-the-fly** - UTF8/ATASCII conversion happens during the copy, so you don't need a separate step.

5. **7-bit mode for compatibility** - Use `--7bit` if you need pure 7-bit ASCII without high-bit characters.

## Common Mistakes

- **Wrong path format** - Remember the colon: `image.atr:path`, not `image.atr/path`.

- **Forgetting the path** - When adding, you need to specify where the file goes. Use `:` if you want the same name.

- **Using both convert options** - You can't convert to UTF8 and ATASCII at the same time. Pick one direction.

- **Expecting `--7bit` to work both ways** - `--7bit` only affects ATASCII→UTF8 conversion, not the reverse.

## Limitations

1. **SpartaDOS/BW-DOS only** - atrcp only works with SpartaDOS/BW-DOS format images (the format that `atrforge` creates).

2. **Single file operations** - You can only copy one file at a time. For multiple files, use `atrforge -a` or extract everything with `lsatr`.

3. **No directory copying** - You can't copy entire directories at once. Copy files individually or use other tools.

4. **File conversion is per-file** - Each file conversion is independent. You can't convert some files and not others in one operation.

## See Also

- [Examples](EXAMPLES.md) - More usage examples
- [UTF8 Conversion](UTF8_CONVERSION.md) - Details on UTF8/ATASCII conversion
- [atrforge](ATRFORGE.md) - For creating images and adding multiple files
- [lsatr](LSATR.md) - For listing and extracting multiple files

---

*For the complete tool list, see the [main documentation index](README.md).*
