# Advanced Topics

You've mastered the basics. Now let's get fancy. This section covers advanced techniques, edge cases, and things you probably don't need but might find interesting. Or useful. Or both.

## Custom Disk Sizes

### Exact Sector Count Mode

The `-x` option creates images with exact sector counts, using non-standard sizes:

```bash
atrforge -x custom.atr file1.com file2.bas
```

This creates an image with exactly the number of sectors needed, which might not be a standard size. Useful when:
- You need a specific size
- You want to minimize disk space
- Standard sizes don't fit your needs

**Note:** These non-standard sizes may not work with all emulators or systems. Test first.

### Minimum Size with Exact Mode

Combine `-s` and `-x` for specific sizes:

```bash
atrforge -s 360000 -x disk.atr files...
```

This creates an image of at least the specified size, using exact sector counts. The size is in bytes, but the actual image will be rounded to sector boundaries.

## Bootloader Relocation Strategies

### When to Relocate

Relocate the bootloader when:
- Your program loads at $600-$700
- You get memory conflicts
- Boot process fails
- You know the load address conflicts

### Relocation Options

**Page 6 ($600):** Usually safe, recommended first try
```bash
atrforge -B 6 -b disk.atr program.com
```

**Page 5 ($500):** Possible, but riskier
```bash
atrforge -B 5 -b disk.atr program.com
```

**Page 4 ($400):** Possible, but even riskier
```bash
atrforge -B 4 -b disk.atr program.com
```

### Testing Relocation

Always test relocated bootloaders:
1. Create image with relocation
2. Test in emulator first
3. Verify program loads correctly
4. Check for memory conflicts
5. Test on real hardware if possible

## Filesystem Optimization

### Directory Structure

Organize files efficiently:
- Group related files in directories
- Keep directory depth reasonable (2-3 levels max)
- Use descriptive directory names
- Avoid too many small directories

### File Placement

- Put frequently accessed files in root
- Put related files together
- Consider access patterns
- Balance organization with efficiency

### Attribute Usage

Use attributes strategically:
- Protect system files (`+p`)
- Hide temporary files (`+h`)
- Mark archived files (`+a`)
- Don't overuse attributes

## Batch Operations

### Processing Multiple Images

Extract from multiple images:

```bash
for img in *.atr; do
    dir="${img%.atr}"
    mkdir -p "$dir"
    lsatr -X "$dir/" "$img"
done
```

Convert multiple images:

```bash
for img in *.atr; do
    convertatr --sector-size 256 "$img" "converted/${img}"
done
```

### Creating Multiple Disks

Create disks for multiple programs:

```bash
for prog in *.com; do
    atrforge -b "${prog%.com}.atr" "$prog"
done
```

### Batch File Updates

Update files in multiple images:

```bash
for img in *.atr; do
    atrcp newfile.com "$img:NEWFILE.COM"
done
```

## Scripting Examples

### Automated Disk Creation

Create a script for standard disk creation:

```bash
#!/bin/bash
# create_disk.sh - Create a standard disk image

DISK_NAME="$1"
shift
FILES="$@"

atrforge "$DISK_NAME" \
    system/ +p system/config.sys \
    "$FILES"
```

Usage:
```bash
./create_disk.sh mydisk.atr file1.com file2.bas
```

### Disk Maintenance Script

Script to verify and report on multiple images:

```bash
#!/bin/bash
# check_disks.sh - Verify multiple disk images

for img in *.atr; do
    echo "Checking $img..."
    if lsatr --verify "$img" > /dev/null 2>&1; then
        echo "  OK"
    else
        echo "  FAILED"
    fi
done
```

### Backup Script

Backup script for disk images:

```bash
#!/bin/bash
# backup_disks.sh - Backup disk images with timestamps

BACKUP_DIR="backups/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

for img in *.atr; do
    cp "$img" "$BACKUP_DIR/${img%.atr}_$(date +%H%M%S).atr"
done
```

## Integration with Other Tools

### Using with Emulators

Most Atari emulators support ATR images directly:
- Altirra
- Atari800
- Atari++

Just point the emulator at your ATR file. It's that simple.

### Using with Disk Utilities

You can use atrforge images with other Atari disk utilities:
- Extract files, modify on Atari, recreate image
- Use Atari tools for filesystem operations
- Combine atrforge creation with Atari-side modification

### Using with Version Control

ATR images are binary, but you can:
- Extract files and version control those
- Keep ATR images as release artifacts
- Use scripts to recreate images from version-controlled files

## Advanced Conversion Techniques

### Multi-Step Conversions

Convert in multiple steps:

```bash
# Step 1: Resize
convertatr --resize 1440 small.atr medium.atr

# Step 2: Convert sector size
convertatr --sector-size 256 medium.atr large.atr

# Step 3: Convert files
convertatr --convert-utf8 --resize 2048 large.atr final.atr
```

### Selective File Conversion

Convert specific files only:

```bash
# Extract files
lsatr -X temp/ image.atr

# Convert specific files
atrcp --to-utf8 temp/file1.bas file1_utf8.bas
atrcp --to-utf8 temp/file2.bas file2_utf8.bas

# Recreate image
atrforge --to-atascii newimage.atr file1_utf8.bas file2_utf8.bas temp/file3.com
```

## Performance Optimization

### Large Image Handling

For very large images (approaching 16MB):
- Process in smaller chunks if possible
- Close other applications
- Ensure adequate system memory
- Consider splitting across multiple images

### Batch Processing

For processing many images:
- Process sequentially (not parallel)
- Clean up temporary files
- Monitor disk space
- Use scripts for automation

## Edge Cases and Workarounds

### Non-Standard Formats

If you encounter non-standard ATR formats:
- Try `lsatr --verify` first
- Extract files and recreate if needed
- Check if format is actually supported
- Report unsupported formats

### Corrupted Images

For corrupted images:
- Try `lsatr --verify` to assess damage
- Attempt extraction (may get some files)
- Use `convertatr` to rebuild structure
- Extract and recreate if possible

### Very Large Files

For files approaching disk size limits:
- Check actual file sizes
- Use largest available disk size
- Consider file compression (if supported)
- Split files if necessary

## Advanced Attribute Usage

### Attribute Combinations

Strategic attribute combinations:
- System files: `+ph` (protected + hidden)
- Backups: `+pa` (protected + archived)
- Temporary: `+h` (hidden only)
- Important: `+p` (protected only)

### Attribute Management

Manage attributes programmatically:
- Extract files, modify attributes on Atari, recreate
- Use scripts to set attributes consistently
- Document attribute usage

## Custom Workflows

### Development Workflow

For development work:
1. Create development disk with tools
2. Extract source files for editing
3. Edit in modern editors (with UTF8 conversion)
4. Add files back to disk
5. Test in emulator
6. Repeat

### Archival Workflow

For archiving old disks:
1. Verify images: `lsatr --verify`
2. Extract all files: `lsatr -X archive/`
3. Document contents
4. Create organized structure
5. Backup everything

### Distribution Workflow

For creating distribution disks:
1. Organize files into directories
2. Set appropriate attributes
3. Create bootable image if needed
4. Test thoroughly
5. Create final image
6. Verify before distribution

## Tips for Power Users

1. **Automate repetitive tasks** - Write scripts for common operations
2. **Test everything** - Especially boot files and conversions
3. **Keep backups** - Multiple backups, different locations
4. **Document your process** - Write down what works
5. **Version control** - Use git or similar for file management
6. **Verify images** - Always verify before using
7. **Know your limits** - 16MB max, understand constraints
8. **Test in emulators** - Before using on real hardware
9. **Keep it organized** - Good structure saves time later
10. **Read the docs** - Even power users need reference

## See Also

- [Examples](EXAMPLES.md) - More examples that might be useful
- [Troubleshooting](TROUBLESHOOTING.md) - When things go wrong
- Tool-specific documentation for detailed options
- [ATR Format](ATR_FORMAT.md) - Technical details

---

*For the complete tool list, see the [main documentation index](README.md).*
