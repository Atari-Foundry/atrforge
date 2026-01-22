# Troubleshooting

Things go wrong. It happens. This guide will help you figure out what went wrong and how to fix it. Most problems have simple solutions. Some don't. We'll cover both.

## Common Error Messages

### "can't open file"

**What it means:** The tool can't open the specified file.

**Possible causes:**
- File doesn't exist
- Wrong path
- Permission issues
- File is locked by another process

**Solutions:**
- Check the file path (typos are common)
- Verify the file exists: `ls -l filename`
- Check file permissions: `chmod` if needed
- Make sure no other program has the file open

### "not an ATR image"

**What it means:** The file isn't a valid ATR image.

**Possible causes:**
- File is corrupted
- File is in a different format
- File is empty or incomplete

**Solutions:**
- Verify the file is actually an ATR image
- Check file size (ATR files should be at least a few KB)
- Try downloading/copying the file again
- Check if it's a different disk image format

### "invalid ATR image size"

**What it means:** The ATR header has invalid size information.

**Possible causes:**
- Corrupted header
- Non-standard ATR file
- File was truncated

**Solutions:**
- Try `lsatr --verify` to check the image
- The tools may auto-correct some size issues
- If it's a known good image, it might be a tool bug (report it)

### "can't write to output file"

**What it means:** Can't write the output file.

**Possible causes:**
- Disk full
- Permission denied
- File is read-only
- Path doesn't exist

**Solutions:**
- Check disk space: `df -h`
- Check write permissions
- Make sure the directory exists
- Check if file is read-only: `chmod` if needed

### "option needs an argument"

**What it means:** You used an option that requires an argument but didn't provide one.

**Possible causes:**
- Missing argument after option
- Wrong option syntax

**Solutions:**
- Check the option syntax in the documentation
- Make sure arguments come immediately after options that need them
- Example: `-X output/` not `-Xoutput/` (space matters)

## Image Format Issues

### Image Won't Load

**Symptoms:**
- Image doesn't work in emulator
- Image doesn't boot
- Error messages when trying to use image

**Possible causes:**
- Wrong DOS format for target system
- Corrupted image
- Incompatible sector size
- Boot file issues

**Solutions:**
- Verify image: `lsatr --verify image.atr`
- Check DOS format compatibility
- Try recreating the image
- Check boot file format and requirements

### Image Too Large

**Symptoms:**
- Error about image size
- Image creation fails
- "image size calculation overflow"

**Possible causes:**
- Files too large for available disk sizes
- Maximum size exceeded (16MB limit)

**Solutions:**
- Check total file sizes
- Use `-x` for exact sizing if needed
- Split files across multiple disks
- Maximum ATR size is 16MB (65535 sectors × 256 bytes)

### Image Too Small

**Symptoms:**
- Files don't fit
- "not enough space" errors

**Possible causes:**
- Files are larger than selected disk size
- Disk size calculation was wrong

**Solutions:**
- Use a larger disk size (atrforge picks automatically)
- Use `-s` to specify minimum size
- Remove some files
- Check actual file sizes

## File Size Problems

### Files Don't Fit

**Symptoms:**
- Error when adding files
- Files missing from image

**Possible causes:**
- Files too large for disk
- Not enough free space

**Solutions:**
- Check file sizes before creating image
- Use larger disk size
- Remove unnecessary files
- Split across multiple disks

### Unexpected File Sizes

**Symptoms:**
- Files appear larger/smaller than expected
- Size mismatches

**Possible causes:**
- Directory overhead
- Filesystem overhead
- Rounding in size calculations

**Solutions:**
- Some overhead is normal
- Check actual disk usage, not just file sizes
- Use `lsatr` to see actual file sizes in image

## Boot File Problems

### Boot File Doesn't Load

**Symptoms:**
- Disk doesn't boot
- Boot process fails
- System hangs on boot

**Possible causes:**
- File not in binary format
- Bootloader conflict
- Memory conflicts
- Corrupted boot file

**Solutions:**
- Verify file is in Atari binary format (`.com`, `.xex`)
- Try relocating bootloader: `atrforge -B 6 -b disk.atr file.com`
- Check file isn't corrupted
- Test file separately (not as boot file)

### Bootloader Conflicts

**Symptoms:**
- Boot process starts but fails
- Memory errors
- Program doesn't load correctly

**Possible causes:**
- Program loads at same address as bootloader
- Memory layout conflicts

**Solutions:**
- Relocate bootloader: `atrforge -B 6 -b disk.atr file.com`
- Check program's load address
- Try different bootloader pages (6, 5, or 4)

## Conversion Issues

### UTF8 Conversion Problems

**Symptoms:**
- Files don't work after conversion
- Characters are wrong
- Files are corrupted

**Possible causes:**
- Converting binary files (don't do this)
- Round-trip conversion issues
- Character encoding problems

**Solutions:**
- Only convert text files, not binary files
- Test converted files before using
- Keep backups of original files
- Use 7-bit mode if needed: `--7bit`

### Sector Size Conversion Fails

**Symptoms:**
- Conversion doesn't work
- Data loss
- Image corruption

**Possible causes:**
- Incompatible DOS format
- Corrupted source image
- Size calculation errors

**Solutions:**
- Verify source image first: `lsatr --verify source.atr`
- Check DOS format compatibility
- Backup before converting
- Try extracting files and recreating instead

## Permission Problems

### Can't Write Files

**Symptoms:**
- Permission denied errors
- Can't create output files

**Possible causes:**
- Directory permissions
- File permissions
- Read-only filesystem

**Solutions:**
- Check directory permissions: `ls -ld directory`
- Check file permissions: `ls -l file`
- Use `chmod` to fix permissions
- Make sure you have write access

### Can't Read Files

**Symptoms:**
- Permission denied when reading
- Can't open input files

**Possible causes:**
- File permissions
- Directory permissions
- File ownership

**Solutions:**
- Check file permissions: `ls -l file`
- Use `chmod` to fix if needed
- Check if you have read access
- Check file ownership

## Path Issues

### Path Not Found

**Symptoms:**
- "can't find path" errors
- Files not found

**Possible causes:**
- Wrong path
- Path doesn't exist
- Typo in path

**Solutions:**
- Double-check the path
- Use absolute paths if relative paths fail
- Check for typos
- Verify directory exists

### Path Traversal Warnings

**Symptoms:**
- Warnings about path components
- Files not extracted

**Possible causes:**
- Dangerous path components (`..`, absolute paths)
- Security feature blocking extraction

**Solutions:**
- This is a security feature (it's working as intended)
- Sanitize paths in source images
- Use safe path names
- Check [SECURITY.md](../SECURITY.md) for details

## Memory/Resource Issues

### Out of Memory

**Symptoms:**
- "out of memory" errors
- Process killed
- System slowdown

**Possible causes:**
- Very large images (approaching 16MB)
- System low on memory
- Too many files

**Solutions:**
- Close other applications
- Use smaller images
- Process images one at a time
- Increase system memory if possible

### Disk Space Issues

**Symptoms:**
- "disk full" errors
- Can't write output

**Possible causes:**
- Disk actually full
- Quota exceeded
- Temporary files

**Solutions:**
- Check disk space: `df -h`
- Free up disk space
- Clean temporary files
- Use different output location

## Build/Installation Issues

### Build Fails

**Symptoms:**
- `make` fails
- Compilation errors

**Possible causes:**
- Missing compiler
- Missing dependencies
- Source code issues

**Solutions:**
- Install C compiler (GCC or Clang)
- Install build tools (`make`)
- Check error messages for specific issues
- Try `make clean` and rebuild

### Program Not Found

**Symptoms:**
- "command not found"
- Can't run tools

**Possible causes:**
- Not in PATH
- Not installed
- Wrong location

**Solutions:**
- Add `bin/` to PATH
- Copy binaries to system path
- Use full path: `./bin/atrforge`
- Check installation completed

## Getting More Help

### Check Documentation

- Read the relevant tool documentation
- Check [Examples](EXAMPLES.md) for similar scenarios
- Review [Advanced](ADVANCED.md) topics

### Verify Your Setup

- Check tool versions: `atrforge -v`
- Verify images: `lsatr --verify image.atr`
- Test with simple examples first

### Report Issues

If you find a bug:
1. Check if it's already known
2. Gather information (error messages, commands used, file sizes)
3. Report with details
4. Include sample files if possible (small, non-sensitive)

## Prevention Tips

1. **Backup before modifying** - Tools create backups, but have your own too
2. **Verify images** - Use `--verify` before using images
3. **Test boot files** - Always test bootable disks
4. **Check file formats** - Make sure files are in correct format
5. **Start simple** - Test with simple examples before complex operations
6. **Read error messages** - They usually tell you what's wrong
7. **Check documentation** - Most questions are answered in the docs

## See Also

- [Examples](EXAMPLES.md) - Working examples that might help
- [Advanced](ADVANCED.md) - Advanced techniques that might solve issues
- Tool-specific documentation for detailed help
- [SECURITY.md](../SECURITY.md) - Security-related issues

---

*For the complete tool list, see the [main documentation index](README.md).*
