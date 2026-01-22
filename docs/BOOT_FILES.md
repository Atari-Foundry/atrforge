# Boot Files

Boot files are special. When you boot an Atari from a disk, the boot file is automatically loaded and executed. It's like having a program that runs itself when you turn on the computer. Pretty neat, right?

## Overview

A boot file is a program that gets loaded automatically when the Atari boots from the disk. The Atari disk controller reads the boot sectors, which contain a bootloader that then loads your program. It's a two-stage process: bootloader loads, then your program loads.

**What makes a boot file:**
- Must be in Atari binary format (`.com`, `.xex`, etc.)
- Must be marked with the `-b` flag when creating the image
- Must fit in available memory
- Must be compatible with the bootloader location

## How Boot Files Work

### The Boot Process

1. **Atari boots** - Computer starts up
2. **Disk controller reads boot sectors** - First few sectors are read
3. **Bootloader executes** - Bootloader code runs
4. **Bootloader loads your file** - Your program is loaded into memory
5. **Your program runs** - Program executes automatically

It's like a chain reaction: boot → bootloader → your program.

### Bootloader

The bootloader is a small program that lives in the boot sectors. It's responsible for loading your actual program file. The bootloader has specific memory requirements:

- **128-byte sectors:** Bootloader needs 613 bytes, from $700 to $965
- **256-byte sectors:** Bootloader needs 848 bytes, from $700 to $A50

These are the standard locations. You can relocate the bootloader if needed (see below).

## Creating Bootable Disks

### Basic Boot File

Create a bootable disk with a single file:

```bash
atrforge -b game.atr mygame.com
```

The `-b` flag marks the next file as the boot file. Simple as that.

### Boot File with Other Files

You can have other files on the disk too:

```bash
atrforge -b game.atr mygame.com data.txt readme.txt
```

The boot file is `mygame.com`, and the other files are just regular files on the disk.

### Boot File in Subdirectory

Boot files are typically in the root directory, but you can put them in subdirectories:

```bash
atrforge -b game.atr games/ -b games/mygame.com
```

Note that you need `-b` before the directory too if the boot file is in a subdirectory. Actually, wait - boot files should be in the root for maximum compatibility. Let's stick with that.

## Bootloader Relocation

Sometimes your program loads at a low address that conflicts with the bootloader. The bootloader normally lives at page 7 ($700), but you can move it.

### Standard Location

By default, the bootloader is at page 7 ($700):
- Address range: $700 to $965 (128-byte sectors) or $A50 (256-byte sectors)
- This is the standard location
- Works with most programs

### Relocating the Bootloader

Use the `-B` option to relocate the bootloader:

```bash
atrforge -B 6 -b game.atr mygame.com
```

This moves the bootloader to page 6 ($600). The `-B` option takes the page number (high byte of address).

### Safe Relocation Values

- **Page 6 ($600)** - Usually safe, recommended if page 7 conflicts
- **Page 5 ($500)** - Possible, but riskier
- **Page 4 ($400)** - Possible, but even riskier

**Why relocate?** Some programs (especially games) load at low addresses like $600 or $700. If the bootloader is there too, they conflict. Moving the bootloader solves this.

### When to Relocate

Relocate the bootloader if:
- Your program loads at $600-$700 range
- You get memory conflicts
- The boot process fails
- You know your program's load address conflicts

If your program works fine with the standard location, don't relocate. The standard location is the most compatible.

## Boot File Requirements

### File Format

Boot files must be in **Atari binary format**:
- `.com` files (COM format)
- `.xex` files (XEX format)
- Other Atari binary formats

**Text files won't work.** BASIC files won't work (unless they're in a special bootable format). The file must be a binary executable.

### File Size

Boot files can be any size that fits in memory, but:
- Must fit in available RAM
- Must not conflict with bootloader location
- Must be loadable by the bootloader

There's no hard limit, but practical limits depend on available memory and your program's requirements.

### Memory Layout

The bootloader and your program share memory space. Make sure they don't conflict:

```
Standard layout (128-byte sectors):
$700 - $965: Bootloader (613 bytes)
$966+: Your program

Standard layout (256-byte sectors):
$700 - $A50: Bootloader (848 bytes)
$A51+: Your program
```

If you relocate the bootloader, adjust these addresses accordingly.

## Examples

### Simple Bootable Game

Create a bootable game disk:

```bash
atrforge -b game.atr game.com
```

Boot the Atari with this disk, and `game.com` runs automatically.

### Bootable Disk with DOS

Create a bootable disk with DOS and a startup file:

```bash
atrforge bwdos.atr dos/ -b +ph dos/xbw130.dos +p startup.bat
```

This creates:
- Bootable disk (`-b` before DOS file)
- DOS file is hidden and protected (`+ph`)
- Startup file is protected (`+p`)
- DOS in subdirectory

### Boot File with Relocated Bootloader

Create a bootable disk with relocated bootloader:

```bash
atrforge -B 6 -b game.atr mygame.com
```

The bootloader is at page 6, leaving page 7 free for your program.

### Boot File with Multiple Files

Create a bootable disk with a boot file and other files:

```bash
atrforge -b disk.atr bootme.com file1.txt file2.txt data.dat
```

The boot file is `bootme.com`, and the other files are accessible after boot.

## Troubleshooting Boot Files

### Boot File Doesn't Load

**Possible causes:**
- File isn't in binary format (check file type)
- Bootloader conflict (try relocating with `-B`)
- File too large for available memory
- Corrupted file

**Solutions:**
- Verify file is in Atari binary format
- Try relocating bootloader: `atrforge -B 6 -b disk.atr file.com`
- Check file size and memory requirements
- Verify file isn't corrupted

### Memory Conflicts

**Symptoms:**
- Program crashes on boot
- Bootloader doesn't execute
- System hangs

**Solutions:**
- Relocate bootloader: `atrforge -B 6 -b disk.atr file.com`
- Check your program's load address
- Ensure no memory conflicts

### Bootloader Too Large

**Symptoms:**
- Boot process fails
- Error messages about bootloader

**Solutions:**
- This is rare, but if it happens, the bootloader might not fit
- Check sector size (128 vs 256 bytes)
- Verify bootloader requirements

## Tips and Tricks

1. **Test boot files** - Always test bootable disks in an emulator before using on real hardware
2. **Keep boot files simple** - Complex boot files are more likely to have issues
3. **Use standard location** - Only relocate if you have a conflict
4. **Check file format** - Make sure your file is in Atari binary format
5. **Verify memory layout** - Know where your program loads and avoid conflicts

## Common Mistakes

- **Forgetting `-b` flag** - Without `-b`, the file won't be bootable
- **Wrong file format** - Text files or BASIC files won't work as boot files
- **Memory conflicts** - Not checking if program conflicts with bootloader
- **Wrong bootloader location** - Using wrong page number with `-B`
- **Boot file in subdirectory** - Boot files should be in root for best compatibility

## See Also

- [atrforge](ATRFORGE.md) - How to create bootable images
- [Examples](EXAMPLES.md) - More boot file examples
- [Troubleshooting](TROUBLESHOOTING.md) - Common boot file problems

---

*For the complete tool list, see the [main documentation index](README.md).*
