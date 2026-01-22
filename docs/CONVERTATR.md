# convertatr - Convert and Resize ATR Images

`convertatr` is the shape-shifter of the atrforge toolkit. It converts ATR images between different formats and sizes. Need a bigger disk? Different sector size? This is your tool. It's like a disk image transformer, but without the explosions.

## Overview

convertatr converts ATR images between different sector sizes and resizes them to different sector counts. It's the tool you use when you need to change an image's format without recreating it from scratch.

**What it does:**
- Resizes images to different sector counts
- Converts between 128-byte and 256-byte sector sizes
- Converts files between UTF8 and ATASCII during resize
- Preserves all data (when possible)

**What it doesn't do:**
- Create new images from files (that's `atrforge`'s job)
- Extract files (that's `lsatr`'s job)
- Make your disk faster (we're not magicians)

## Command Syntax

```bash
convertatr [options] <input.atr> <output.atr>
```

Give it an input file and an output file, tell it what to do, and it does it. Simple.

## Options

### `--resize <N>` - Resize to N Sectors

Resizes the image to N sectors. You can only increase the size (because you can't make data appear out of nowhere).

```bash
convertatr --resize 1440 disk1.atr disk1_large.atr
```

The sector count must be between 1 and 65535. The image will be resized, and the extra space will be available for new files (if the filesystem supports it).

**Note:** This only changes the image size. It doesn't automatically expand the filesystem. You'll need to use filesystem-specific tools on the Atari to actually use the extra space.

### `--sector-size <N>` - Convert Sector Size

Converts the image to use N-byte sectors. Valid values are 128 or 256. That's it. No other sizes. We're not that flexible.

```bash
convertatr --sector-size 256 disk128.atr disk256.atr
```

This converts between 128-byte and 256-byte sector formats. The conversion preserves all data, but the sector layout changes, so the image structure is rebuilt.

### `--convert-utf8` - Convert Files to UTF8

Converts all files in the ATR from ATASCII to UTF8 during the resize/conversion operation. This is useful if you want to edit files in a modern UTF8 editor.

```bash
convertatr --convert-utf8 --resize 1440 disk.atr disk_utf8.atr
```

See [UTF8 Conversion](UTF8_CONVERSION.md) for more details on this process.

### `--convert-atascii` - Convert Files to ATASCII

Converts all files in the ATR from UTF8 to ATASCII during the resize/conversion operation. This is useful if you've edited files in UTF8 and need them back in ATASCII format.

```bash
convertatr --convert-atascii --sector-size 256 disk.atr disk_atascii.atr
```

**Note:** You can't use both `--convert-utf8` and `--convert-atascii` at the same time. Pick one direction.

### `-h` - Help

Shows a brief help message. You're reading the extended version.

### `-v` - Version

Shows version information. Version numbers are important.

## Requirements

You must specify either `--resize` or `--sector-size` (or both, but not at the same time - see below). The tool needs to know what conversion you want to perform.

## Combining Options

You can combine `--resize` and `--sector-size` to do both operations at once:

```bash
convertatr --resize 1440 --sector-size 256 disk.atr newdisk.atr
```

This resizes to 1440 sectors AND converts to 256-byte sectors. Efficient!

However, you cannot combine `--convert-utf8` and `--convert-atascii`. That would be like trying to go north and south at the same time. Pick a direction.

## Examples

### Resize Image

Resize an image to 1440 sectors (360k):

```bash
convertatr --resize 1440 disk1.atr disk1_large.atr
```

### Convert Sector Size

Convert from 128-byte to 256-byte sectors:

```bash
convertatr --sector-size 256 disk128.atr disk256.atr
```

### Convert from 256-byte to 128-byte Sectors

Convert from 256-byte to 128-byte sectors:

```bash
convertatr --sector-size 128 disk256.atr disk128.atr
```

### Resize and Convert Sector Size

Do both at once:

```bash
convertatr --resize 1440 --sector-size 256 disk.atr newdisk.atr
```

### Convert Files to UTF8 During Resize

Resize and convert all files to UTF8:

```bash
convertatr --convert-utf8 --resize 2048 disk.atr disk_utf8.atr
```

### Convert Files to ATASCII During Conversion

Convert sector size and convert all files to ATASCII:

```bash
convertatr --convert-atascii --sector-size 256 disk.atr disk_atascii.atr
```

## How It Works

### Resizing

When you resize an image:
1. The image file is expanded (or the size is changed)
2. The filesystem structure is preserved
3. Extra space becomes available (if the filesystem supports it)

**Important:** Resizing only changes the image file size. The filesystem itself may need to be expanded on the Atari to actually use the extra space. This depends on the DOS format.

### Sector Size Conversion

When converting sector sizes:
1. The image is read with the old sector size
2. Data is reorganized for the new sector size
3. The filesystem structure is rebuilt if necessary
4. A new image is written with the new sector size

This is a more complex operation because the entire disk structure changes. All data is preserved, but the layout is different.

### File Conversion

When converting files (UTF8 ↔ ATASCII):
1. Files are read from the source image
2. Each file is converted according to the specified direction
3. Files are written to the destination image

This happens during the resize/conversion operation, so it's all done in one pass.

## Limitations

1. **Resize only increases size** - You can't shrink an image (well, you can, but data might be lost, so we don't let you).

2. **Filesystem compatibility** - Some DOS formats may not support the new size or sector format. Check compatibility before converting.

3. **File conversion is all-or-nothing** - You can't convert some files and not others. It's all files or nothing.

4. **Sector count limits** - Maximum sector count is 65535. That's the ATR format limit, not ours.

## Tips and Tricks

1. **Backup first** - Always backup your images before converting. Just in case.

2. **Test after conversion** - Verify the converted image works before deleting the original.

3. **Check filesystem support** - Make sure your DOS format supports the new size/sector format.

4. **Use file conversion carefully** - Converting all files to UTF8/ATASCII affects every file. Make sure that's what you want.

5. **Combine operations** - You can resize and convert sector size in one operation. Efficient!

## Common Mistakes

- **Forgetting to specify resize or sector-size** - You must specify at least one. The tool needs to know what to do.

- **Trying to use both convert options** - You can't convert to UTF8 and ATASCII at the same time. Pick one.

- **Expecting automatic filesystem expansion** - Resizing the image doesn't automatically expand the filesystem. You may need to do that on the Atari.

- **Converting incompatible formats** - Not all DOS formats support all sector sizes. Check compatibility first.

## See Also

- [Examples](EXAMPLES.md) - More usage examples
- [UTF8 Conversion](UTF8_CONVERSION.md) - Details on UTF8/ATASCII conversion
- [ATR Format](ATR_FORMAT.md) - Technical details about ATR format
- [DOS Formats](DOS_FORMATS.md) - Information on DOS format compatibility

---

*For the complete tool list, see the [main documentation index](README.md).*
