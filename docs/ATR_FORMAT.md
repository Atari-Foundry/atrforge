# ATR Format Specification

The ATR (Atari Disk Image) format is the standard way to store Atari 8-bit disk images. It's been around since the 1980s, which makes it older than some of the people using it. But it works, and that's what matters.

## Overview

An ATR file is a binary representation of an Atari disk. It contains all the sectors from the original disk, plus a header that describes the disk's characteristics. It's like a photograph of a disk, but in binary form.

## File Structure

An ATR file consists of:
1. **Header** (16 bytes) - Describes the disk format
2. **Sector Data** - The actual disk sectors

That's it. Simple and straightforward. No fancy compression, no metadata beyond what's needed. Just the essentials.

## Header Format

The ATR header is exactly 16 bytes. Here's what each byte does:

| Offset | Size | Description |
|--------|------|-------------|
| 0 | 1 | Magic number: `0x96` |
| 1 | 1 | Magic number: `0x02` |
| 2-3 | 2 | Image size in paragraphs (16-byte units), little-endian |
| 4-5 | 2 | Sector size in bytes, little-endian (128 or 256) |
| 6 | 1 | High byte of image size (for images > 16MB) |
| 7-15 | 9 | Reserved (should be zero) |

### Magic Numbers

The first two bytes are `0x96` and `0x02`. This identifies the file as an ATR image. If these aren't present, it's not an ATR file (or it's corrupted).

### Image Size

The image size is stored in paragraphs (16-byte units). The size is stored in bytes 2-3 (low 16 bits) and byte 6 (high 8 bits), giving a maximum size of 2^24 bytes (16MB).

**Calculation:**
```
size_bytes = (header[2] | (header[3] << 8)) | (header[6] << 16)
```

Actually, it's a bit more complex. The size is stored as:
- Bytes 2-3: Low 16 bits (in paragraphs)
- Byte 6: High 8 bits

The actual size in bytes is calculated from the sector count and sector size.

### Sector Size

The sector size is stored in bytes 4-5 as a little-endian 16-bit value. Valid values are:
- `128` (0x0080) - Single density
- `256` (0x0100) - Double density

That's it. No other sizes are supported. We're not that flexible.

## Sector Layout

### First Three Sectors

The first three sectors are always 128 bytes, regardless of the sector size specified in the header. This is a quirk of the ATR format (and the Atari disk format it represents).

**Why?** The Atari disk controller reads the first three sectors as 128-byte sectors during boot. After that, it switches to the configured sector size. It's a historical artifact, but it's part of the format.

### Remaining Sectors

After the first three sectors, sectors use the size specified in the header (128 or 256 bytes).

### Sector Padding

Some ATR files store the first three sectors as 128 bytes even when the sector size is 256. The padding is calculated as:

```
padding = (sector_size - 128) * 3
```

So for 256-byte sectors, the first three sectors take up 384 bytes in the file (128 bytes each, but stored with 256-byte spacing).

## Image Size Calculation

The total image size in the file is:

```
if (sector_size == 256 && sector_count > 3):
    file_size = 128 * 3 + sector_size * (sector_count - 3)
else:
    file_size = sector_size * sector_count
```

The header stores the size in paragraphs (16-byte units), but the actual file size is calculated from the sector layout.

## Maximum Size Limits

- **Maximum sector count:** 65535 sectors
- **Maximum sector size:** 256 bytes
- **Maximum image size:** 65535 × 256 = 16,777,216 bytes (16MB)

That's the theoretical maximum. In practice, most images are much smaller.

## Standard Disk Sizes

Common ATR disk sizes:

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
| 65535 | 256 | 16M | Maximum |

## Reading an ATR File

To read an ATR file:

1. **Read the header** (16 bytes)
2. **Verify magic numbers** (`0x96`, `0x02`)
3. **Extract sector size** (bytes 4-5)
4. **Calculate sector count** from image size
5. **Read sectors** according to the layout

The first three sectors are always 128 bytes. After that, use the sector size from the header.

## Writing an ATR File

To write an ATR file:

1. **Calculate image size** from sector count and sector size
2. **Write header** with magic numbers, size, and sector size
3. **Write first three sectors** as 128 bytes each
4. **Write remaining sectors** using the specified sector size

Make sure to handle the padding correctly for 256-byte sectors.

## Format Variations

### Old Format (No Header)

Some very old ATR files don't have a header. They're just raw sector data. atrforge tools can detect and handle these by:
1. Checking if the file starts with the magic numbers
2. If not, assuming it's a headerless image
3. Calculating size from file size and assuming 128-byte sectors

### Size Calculation Issues

Some ATR files have incorrect size information in the header. The tools handle this by:
1. Reading the header
2. Calculating expected size
3. If the file size doesn't match, using the actual file size
4. Warning the user about the discrepancy

## Compatibility Notes

- **Emulators:** Most Atari emulators support the ATR format
- **Tools:** Most Atari disk tools can read/write ATR files
- **Size limits:** Some older tools may have lower size limits
- **Sector size:** Not all tools support both 128 and 256-byte sectors

## Technical Details

### Byte Order

All multi-byte values in the ATR header are little-endian. This means the least significant byte comes first. It's the standard for x86 systems, so it's probably what you're used to.

### Reserved Bytes

Bytes 7-15 in the header are reserved and should be zero. Some tools use them for extensions, but the standard says they should be zero. Stick to the standard if you want maximum compatibility.

### Sector Numbering

Sectors are numbered starting from 1 (not 0). This is how the Atari disk controller sees them. The first sector is sector 1, not sector 0. Keep this in mind when working with sector numbers.

## See Also

- [DOS Formats](DOS_FORMATS.md) - Information on filesystem formats stored in ATR images
- [atrforge](ATRFORGE.md) - How to create ATR images
- [convertatr](CONVERTATR.md) - How to convert between ATR formats

---

*For the complete tool list, see the [main documentation index](README.md).*
