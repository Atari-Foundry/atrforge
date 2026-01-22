# lsatr - List and Extract ATR Contents

`lsatr` is the nosy neighbor of the atrforge toolkit. It peeks inside ATR images, lists their contents, and extracts files. Think of it as `ls` and `tar` combined, but specifically designed for 8-bit disk images. It's actually pretty useful.

## Overview

lsatr can read and extract files from a wide variety of Atari DOS formats. It's like a universal disk image reader, except it doesn't actually read the disk - it reads the image file. You know, the modern way.

**What it does:**
- Lists files in ATR images
- Extracts files from ATR images
- Supports multiple DOS formats (see below)
- Shows file sizes, dates, and attributes
- Verifies ATR image integrity

**What it doesn't do:**
- Create new images (that's `atrforge`'s job)
- Modify images (use `atrforge -a` or `atrcp` for that)
- Make your coffee (still working on it)

## Command Syntax

```bash
lsatr [options] <atr_image_file>
```

Simple enough: give it options and an ATR file, and it does its thing.

## Options

### `-a` - Atari Format Listing

Shows the listing in native Atari format instead of the default UNIX-style format. This means:
- Filename separated by spaces to the extension (like "MY FILE COM" instead of "MYFILE.COM")
- Size, date, and time (if available)
- Each subdirectory in a separate listing

```bash
lsatr -a disk.atr
```

The standard format shows size, date, time (if available), and the full path at the end. Use `-a` if you want that nostalgic Atari feel.

### `-l` - Lowercase Filenames

Converts all filenames to lowercase when listing or extracting. Because sometimes you want consistency, and Atari filenames are traditionally uppercase.

```bash
lsatr -l disk.atr
```

This affects both listing and extraction. Useful if you're working on a case-sensitive filesystem and want everything lowercase.

### `-x` - Extract to Current Directory

Extracts all files to the current directory. Simple and straightforward.

```bash
lsatr -x disk.atr
```

Files are extracted with their directory structure preserved (relative to the current directory). If a file already exists, it won't be overwritten unless you use `-f`.

### `-X <path>` - Extract to Specific Directory

Extracts all files to the specified directory. If the directory doesn't exist, it will be created. How convenient!

```bash
lsatr -X output/ disk.atr
```

This is the preferred way to extract files if you want them in a specific location. The directory is created automatically, so you don't need to create it first.

### `-f` - Force Overwrite

Allows overwriting existing files during extraction. By default, lsatr won't overwrite existing files (because we're not monsters). Use this flag if you want to overwrite them anyway.

```bash
lsatr -f -X output/ disk.atr
```

**Warning:** This will overwrite files without asking. Make sure you know what you're doing.

### `-q` - Quiet Mode

Suppresses informational messages. Only shows errors and the actual output (file listings or extraction progress).

```bash
lsatr -q disk.atr
```

Useful in scripts or when you just want the facts without the commentary.

### `--verify` - Verify Image Integrity

Verifies that the ATR image is valid and can be loaded correctly. This checks:
- Valid ATR header
- Reasonable sector count and size
- Image structure integrity

```bash
lsatr --verify disk.atr
```

This is a read-only operation - it doesn't extract or list files, just verifies the image is okay. Useful for checking if an image is corrupted before trying to use it.

### `-h` - Help

Shows a brief help message. You're reading the extended version.

### `-v` - Version

Shows version information. Because version numbers are important.

## Supported DOS Formats

lsatr supports reading from a wide variety of Atari DOS formats. Here's the list:

### Creation Support (SpartaDOS/BW-DOS)

- **SpartaDOS** - Full read/write support (this is what `atrforge` creates)
- **BW-DOS** - Full read/write support (compatible with SpartaDOS)

### Read-Only Support

- **Atari DOS 1** - Single density only
- **Atari DOS 2.0** - Single and double density
- **Atari DOS 2.5** - Enhanced density
- **MyDOS** - Up to 16MB images
- **LiteDOS 2.x** - LiteDOS and LiteDOS-SE
- **BAS2BOOT images** - Extracts the BAS file inside
- **Howfen DOS images** - Extracts the raw BOOT images
- **K-file boot images** - Extracts the XEX file inside

lsatr tries each format in order until it finds one that works. It's like a universal key that tries different locks until one opens.

## Listing Formats

### Standard Format

The default format shows:
- File size
- Date and time (if available)
- Full path

Example:
```
   1234 2024-01-15 10:30:00 GAMES/GAME1.COM
   5678 2024-01-15 10:31:00 GAMES/GAME2.COM
```

### Atari Format (`-a`)

The Atari format shows:
- Filename with spaces (e.g., "MY FILE COM")
- Size
- Date and time
- Separate listings for each subdirectory

Example:
```
MY FILE    COM    1234  2024-01-15 10:30:00
ANOTHER    BAS    5678  2024-01-15 10:31:00
```

## Extraction Behavior

When extracting files:

1. **Directory structure is preserved** - Subdirectories are created as needed
2. **Path sanitization** - Dangerous path components (`..`, absolute paths) are removed for security
3. **File permissions** - Extracted files are created with mode 0666 (read/write for all)
4. **Overwrite protection** - Existing files are not overwritten unless `-f` is used

## Examples

### Basic Listing

List files in an ATR image:

```bash
lsatr disk.atr
```

### Atari-Style Listing

List files in native Atari format:

```bash
lsatr -a disk.atr
```

### Extract to Current Directory

Extract all files to the current directory:

```bash
lsatr -x disk.atr
```

### Extract to Specific Directory

Extract all files to a specific directory:

```bash
lsatr -X extracted/ disk.atr
```

### Extract with Lowercase Names

Extract files with lowercase filenames:

```bash
lsatr -l -X output/ disk.atr
```

### Force Overwrite

Extract files, overwriting existing ones:

```bash
lsatr -f -X output/ disk.atr
```

### Verify Image

Check if an ATR image is valid:

```bash
lsatr --verify disk.atr
```

### Quiet Mode

List files without informational messages:

```bash
lsatr -q disk.atr
```

### Multiple Images

You can list multiple images (though extraction only works with one at a time):

```bash
lsatr disk1.atr disk2.atr disk3.atr
```

## Security Considerations

lsatr implements path sanitization to prevent directory traversal attacks:

- **Directory traversal prevention** - `..` components are removed from paths
- **Absolute path rejection** - Absolute paths are rejected
- **Path validation** - All path components are validated

However, you should still be cautious when extracting files from untrusted ATR images. See [SECURITY.md](../SECURITY.md) for more details.

## Tips and Tricks

1. **Use `-X` for extraction** - It's cleaner than `-x` and lets you specify the output directory.

2. **Combine `-l` with extraction** - If you want lowercase filenames, use `-l` with `-x` or `-X`.

3. **Verify before extracting** - Use `--verify` to check an image before extracting, especially if it's from an untrusted source.

4. **Atari format for nostalgia** - Use `-a` if you want that authentic Atari directory listing feel.

5. **Quiet mode in scripts** - Use `-q` when scripting to avoid extra output.

## Common Mistakes

- **Trying to extract multiple images** - Extraction only works with one image at a time. List multiple, extract one.

- **Forgetting the directory with `-X`** - The `-X` option requires a directory argument. Don't forget it.

- **Expecting `-a` to work with extraction** - The `-a` and `-x` options are incompatible. Pick one.

- **Not using `-f` when you need to overwrite** - By default, existing files won't be overwritten. Use `-f` if you want to force it.

## See Also

- [Examples](EXAMPLES.md) - More usage examples
- [DOS Formats](DOS_FORMATS.md) - Details on supported formats
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues and solutions
- [atrcp](ATRCP.md) - For copying individual files

---

*For the complete tool list, see the [main documentation index](README.md).*
