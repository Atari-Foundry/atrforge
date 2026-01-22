# UTF8 / ATASCII Conversion

Modern text editors use UTF8. Atari computers use ATASCII. They're not the same thing. This is why we have conversion tools. Because sometimes you want to edit Atari text files in a modern editor without everything breaking.

## Overview

ATASCII (ATARI ASCII) is the character encoding used by Atari 8-bit computers. It's similar to ASCII, but with some differences:
- Uses the high bit for graphics characters
- Line endings are character 155 (not newline)
- Some characters are different from standard ASCII

UTF8 is what modern editors use. It's Unicode encoded in a way that's compatible with ASCII for the basic characters, but can represent any Unicode character.

**The problem:** Edit an ATASCII file in a UTF8 editor, and things break. Edit a UTF8 file on an Atari, and things break.

**The solution:** Convert between them. That's what the conversion tools do.

## Why Conversion is Needed

### The ATASCII Character Set

ATASCII uses:
- **Standard ASCII** for most characters (0-127)
- **High-bit graphics** for special characters (128-255)
- **Character 155** for line endings (instead of newline, 0x0a)

### The UTF8 Character Set

UTF8 uses:
- **Standard ASCII** for basic characters (0-127)
- **Multi-byte sequences** for extended characters
- **Newline (0x0a)** for line endings

### The Conflicts

1. **Line endings** - ATASCII uses 155, UTF8 uses 0x0a
2. **High-bit characters** - ATASCII high-bit chars don't map directly to UTF8
3. **Extended characters** - Different encoding schemes

## How Conversion Works

### ATASCII to UTF8

When converting from ATASCII to UTF8:
1. **Line endings:** Character 155 → 0x0a (newline)
2. **Standard ASCII:** Characters 0-127 → Same in UTF8
3. **High-bit characters:** Encoded as UTF8 sequences (0xee 0x80|(c>>6) 0x80|(c&0x3f))

The high-bit characters are encoded as 3-byte UTF8 sequences that represent the ATASCII character value.

### UTF8 to ATASCII

When converting from UTF8 to ATASCII:
1. **Line endings:** 0x0a (newline) → Character 155
2. **Standard ASCII:** Characters 0-127 → Same in ATASCII
3. **UTF8 sequences:** Decoded back to ATASCII high-bit characters

UTF8 multi-byte sequences that represent ATASCII characters are decoded back to single-byte ATASCII values.

### 7-bit Mode

7-bit mode strips the high bit from characters during ATASCII→UTF8 conversion:
- Characters 128-255 → Characters 0-127 (high bit removed)
- Useful when you want pure 7-bit ASCII
- Only affects ATASCII→UTF8 conversion

## Conversion in Tools

### atrforge

Convert files from UTF8 to ATASCII when creating an image:

```bash
atrforge --to-atascii disk.atr source.bas
```

This converts `source.bas` from UTF8 to ATASCII before adding it to the disk.

### atrcp

Convert files in either direction:

**Extract and convert to UTF8:**
```bash
atrcp --to-utf8 disk.atr:SOURCE.BAS source.bas
```

**Add and convert to ATASCII:**
```bash
atrcp --to-atascii source.bas disk.atr:SOURCE.BAS
```

**7-bit mode:**
```bash
atrcp --7bit --to-utf8 disk.atr:FILE.TXT file.txt
```

### convertatr

Convert all files in an image during resize/conversion:

**Convert all files to UTF8:**
```bash
convertatr --convert-utf8 --resize 1440 disk.atr disk_utf8.atr
```

**Convert all files to ATASCII:**
```bash
convertatr --convert-atascii --sector-size 256 disk.atr disk_atascii.atr
```

## Conversion Examples

### Editing a BASIC File

1. **Extract with UTF8 conversion:**
   ```bash
   atrcp --to-utf8 disk.atr:PROGRAM.BAS program.bas
   ```

2. **Edit in your favorite editor:**
   ```bash
   vim program.bas  # or nano, emacs, VS Code, etc.
   ```

3. **Add back with ATASCII conversion:**
   ```bash
   atrcp --to-atascii program.bas disk.atr:PROGRAM.BAS
   ```

Now you can edit Atari BASIC files in modern editors without breaking them.

### Batch Conversion

Convert all files in an image to UTF8:

```bash
convertatr --convert-utf8 --resize 1440 disk.atr disk_utf8.atr
```

This creates a new image with all files converted to UTF8. Useful if you want to edit multiple files.

### 7-bit ASCII Extraction

Extract a file as 7-bit ASCII:

```bash
atrcp --7bit --to-utf8 disk.atr:FILE.TXT file.txt
```

This strips the high bit, giving you pure 7-bit ASCII. Useful for compatibility with systems that don't handle high-bit characters well.

## Character Mapping

### Standard ASCII (0-127)

These characters are the same in both ATASCII and UTF8:
- Letters (A-Z, a-z)
- Numbers (0-9)
- Basic punctuation
- Control characters (with some exceptions)

### Line Endings

- **ATASCII:** Character 155 (0x9B)
- **UTF8:** Newline (0x0A)

Conversion handles this automatically.

### High-bit Characters (128-255)

ATASCII high-bit characters are encoded as UTF8 sequences:
- **ATASCII byte:** Single byte (128-255)
- **UTF8 encoding:** 3-byte sequence (0xee 0x80|(c>>6) 0x80|(c&0x3f))

When converting back, these sequences are decoded to the original ATASCII byte.

## Best Practices

1. **Convert when extracting** - Use `--to-utf8` when extracting files you want to edit
2. **Convert when adding** - Use `--to-atascii` when adding edited files back
3. **Keep originals** - Backup original files before converting
4. **Test after conversion** - Verify converted files work on the Atari
5. **Use 7-bit mode carefully** - Only use `--7bit` if you need pure 7-bit ASCII

## Limitations

1. **Round-trip conversion** - Converting ATASCII→UTF8→ATASCII should preserve data, but test to be sure
2. **Non-ATASCII UTF8** - UTF8 characters that aren't ATASCII may not convert correctly
3. **Binary files** - Don't convert binary files (they'll break)
4. **File conversion is all-or-nothing** - In `convertatr`, all files are converted or none

## Tips and Tricks

1. **Edit workflow** - Extract with `--to-utf8`, edit, add with `--to-atascii`
2. **Batch operations** - Use `convertatr` for converting entire images
3. **7-bit for compatibility** - Use `--7bit` if you need maximum compatibility
4. **Test first** - Always test converted files before using them
5. **Keep backups** - Original files are your safety net

## Common Mistakes

- **Converting binary files** - Don't convert `.com`, `.xex`, or other binary files
- **Forgetting conversion** - Remember to convert when extracting/adding edited files
- **Wrong direction** - Make sure you're converting in the right direction
- **Expecting perfect round-trip** - Some edge cases may not convert perfectly
- **Using 7-bit unnecessarily** - Only use `--7bit` if you actually need it

## See Also

- [atrforge](ATRFORGE.md) - Creating images with UTF8→ATASCII conversion
- [atrcp](ATRCP.md) - Copying files with conversion
- [convertatr](CONVERTATR.md) - Converting entire images
- [Examples](EXAMPLES.md) - Conversion workflow examples

---

*For the complete tool list, see the [main documentation index](README.md).*
