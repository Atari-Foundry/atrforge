# Usage Examples

Here are some real-world examples of using atrforge tools. These are actual scenarios you might encounter, with actual commands you can use. No theory, just practice.

## Basic Image Creation

### Simple Disk Image

Create a basic disk image with a few files:

```bash
atrforge mydisk.atr file1.com file2.bas file3.txt
```

That's it. Three files, one disk. Simple.

### Organized Disk Image

Create a disk with organized directories:

```bash
atrforge organized.atr \
    games/ game1.com game2.com \
    utils/ util1.com util2.com \
    docs/ readme.txt manual.txt
```

This creates:
- `games/game1.com` and `games/game2.com`
- `utils/util1.com` and `utils/util2.com`
- `docs/readme.txt` and `docs/manual.txt`

Organization is good. Your future self will thank you.

## Bootable Disks

### Simple Bootable Game

Create a bootable game disk:

```bash
atrforge -b game.atr mygame.com
```

Boot the Atari with this disk, and the game runs automatically. No typing required.

### Bootable Disk with DOS

Create a bootable disk with DOS and startup file:

```bash
atrforge bwdos.atr \
    dos/ -b +ph dos/xbw130.dos \
    +p startup.bat \
    config.sys
```

This creates:
- Bootable disk (DOS boots automatically)
- DOS file is hidden and protected
- Startup file is protected
- Config file is regular

### Bootable Disk with Relocated Bootloader

If your game loads at a low address that conflicts with the bootloader:

```bash
atrforge -B 6 -b game.atr mygame.com
```

This moves the bootloader to page 6, leaving page 7 free for your game.

## File Attributes

### Protected System Files

Create a disk with protected system files:

```bash
atrforge system.atr \
    +p config.sys \
    +p autoexec.bat \
    normal.com
```

System files are protected, regular files are not.

### Hidden Files

Create a disk with hidden files:

```bash
atrforge disk.atr \
    +h secret.com \
    visible.com
```

`secret.com` is hidden, `visible.com` is not. On SpartaDOS-X, hidden files won't show in normal directory listings.

### Combined Attributes

Create a disk with files that have multiple attributes:

```bash
atrforge disk.atr \
    +ph system.com \
    +pa backup.com \
    normal.com
```

- `system.com` is protected and hidden
- `backup.com` is protected and archived
- `normal.com` has no special attributes

## Adding Files to Existing Images

### Add Single File

Add a file to an existing disk:

```bash
atrforge -a existing.atr newfile.com
```

The original disk is backed up automatically (as `existing.atr.bak`).

### Add Multiple Files

Add several files at once:

```bash
atrforge -a existing.atr file1.com file2.bas file3.txt
```

All files are added in one operation.

### Add Files to Subdirectory

Add files to a subdirectory:

```bash
atrforge -a existing.atr games/ newgame1.com newgame2.com
```

The `games/` directory is created if it doesn't exist.

## Listing and Extracting

### List Files

See what's in a disk image:

```bash
lsatr disk.atr
```

Simple listing of all files.

### Atari-Style Listing

List files in native Atari format:

```bash
lsatr -a disk.atr
```

For that authentic Atari directory listing feel.

### Extract All Files

Extract everything to a directory:

```bash
lsatr -X extracted/ disk.atr
```

All files are extracted, preserving directory structure.

### Extract with Lowercase Names

Extract files with lowercase filenames:

```bash
lsatr -l -X output/ disk.atr
```

Useful if you're working on a case-sensitive filesystem.

### Verify Image

Check if an image is valid:

```bash
lsatr --verify disk.atr
```

Quick check to see if the image is okay.

## Converting Images

### Resize Image

Make a disk bigger:

```bash
convertatr --resize 1440 disk1.atr disk1_large.atr
```

Resizes to 1440 sectors (360k).

### Convert Sector Size

Convert from 128-byte to 256-byte sectors:

```bash
convertatr --sector-size 256 disk128.atr disk256.atr
```

Changes the sector size while preserving data.

### Resize and Convert

Do both at once:

```bash
convertatr --resize 1440 --sector-size 256 disk.atr newdisk.atr
```

Efficient! Two operations in one command.

## Copying Files

### Extract Single File

Extract one file from a disk:

```bash
atrcp disk.atr:MYFILE.COM myfile.com
```

Just that one file, nothing else.

### Add Single File

Add one file to a disk:

```bash
atrcp myfile.com disk.atr:MYFILE.COM
```

Updates the disk, creates a backup automatically.

### Add File with Same Name

Add a file using its original name:

```bash
atrcp myfile.com disk.atr:
```

The `:` with no path uses the source filename.

### Add File to Subdirectory

Add a file to a subdirectory:

```bash
atrcp game.com disk.atr:GAMES/GAME.COM
```

Directory is created automatically if needed.

## UTF8/ATASCII Conversion

### Edit a BASIC File

Complete workflow for editing a BASIC file:

```bash
# 1. Extract and convert to UTF8
atrcp --to-utf8 disk.atr:PROGRAM.BAS program.bas

# 2. Edit in your favorite editor
vim program.bas

# 3. Add back and convert to ATASCII
atrcp --to-atascii program.bas disk.atr:PROGRAM.BAS
```

Now you can edit Atari BASIC files in modern editors.

### Create Image with UTF8 Conversion

Create a disk, converting files from UTF8 to ATASCII:

```bash
atrforge --to-atascii disk.atr edited.bas converted.txt
```

Files are converted during image creation.

### Convert Entire Image

Convert all files in an image to UTF8:

```bash
convertatr --convert-utf8 --resize 1440 disk.atr disk_utf8.atr
```

Creates a new image with all files converted.

### Extract with 7-bit Mode

Extract a file as 7-bit ASCII:

```bash
atrcp --7bit --to-utf8 disk.atr:FILE.TXT file.txt
```

Strips the high bit for maximum compatibility.

## Real-World Scenarios

### Creating a Game Distribution Disk

Create a professional game disk:

```bash
atrforge gamedisk.atr \
    -b game.com \
    +p readme.txt \
    +p license.txt \
    docs/ manual.txt
```

- Game boots automatically
- Documentation is protected
- Organized structure

### Archiving Old Disks

Extract files from old disks for archival:

```bash
# Extract all files
lsatr -X archive/ olddisk1.atr olddisk2.atr olddisk3.atr

# Verify images first
lsatr --verify olddisk1.atr
lsatr --verify olddisk2.atr
lsatr --verify olddisk3.atr
```

Preserve old software for posterity.

### Updating a Single File

Update one file on a disk:

```bash
# Extract the file
atrcp --to-utf8 disk.atr:CONFIG.TXT config.txt

# Edit it
vim config.txt

# Add it back
atrcp --to-atascii config.txt disk.atr:CONFIG.TXT
```

Quick update without recreating the entire disk.

### Converting Old Images

Convert old 128-byte sector images to 256-byte:

```bash
convertatr --sector-size 256 old128.atr new256.atr
```

Modernize old disk images.

### Creating a Bootable Development Disk

Create a disk for development work:

```bash
atrforge devdisk.atr \
    -b devtool.com \
    source/ file1.bas file2.bas \
    data/ data1.dat data2.dat \
    +p config.cfg
```

- Development tool boots automatically
- Source files organized
- Config file protected

## Batch Operations

### Extract Multiple Images

Extract files from multiple images:

```bash
for img in *.atr; do
    mkdir -p "extracted/${img%.atr}"
    lsatr -X "extracted/${img%.atr}/" "$img"
done
```

Extract all ATR files in the current directory.

### Convert Multiple Images

Convert all images to 256-byte sectors:

```bash
for img in *.atr; do
    convertatr --sector-size 256 "$img" "converted/${img}"
done
```

Batch conversion of multiple images.

### Create Multiple Boot Disks

Create bootable disks for multiple games:

```bash
for game in game*.com; do
    atrforge -b "${game%.com}.atr" "$game"
done
```

Create a bootable disk for each game.

## Advanced Examples

### Custom Size Disk

Create a disk with a specific minimum size:

```bash
atrforge -s 360000 disk.atr current_files.com
```

Creates at least a 360k disk, even if files would fit in smaller.

### Exact Size Disk

Create a disk with exact sector count:

```bash
atrforge -x custom.atr file1.com file2.bas
```

Uses non-standard sector count to fit exactly.

### Complex Directory Structure

Create a disk with a complex directory structure:

```bash
atrforge complex.atr \
    system/ +p system/config.sys \
    games/ action/ game1.com game2.com \
    games/ puzzle/ game3.com game4.com \
    utils/ +p utils/tool.com \
    docs/ readme.txt manual.txt
```

Multiple levels of organization.

## Tips from the Examples

1. **Use directories** - Organize files into directories for better structure
2. **Protect important files** - Use `+p` for files that shouldn't be modified
3. **Test boot files** - Always test bootable disks before distributing
4. **Backup before modifying** - Tools create backups, but it doesn't hurt to have your own
5. **Verify images** - Use `--verify` to check images before using them
6. **Convert for editing** - Use UTF8 conversion when editing text files
7. **Batch operations** - Use shell scripts for repetitive tasks

## See Also

- [atrforge](ATRFORGE.md) - Complete atrforge documentation
- [lsatr](LSATR.md) - Complete lsatr documentation
- [convertatr](CONVERTATR.md) - Complete convertatr documentation
- [atrcp](ATRCP.md) - Complete atrcp documentation
- [Advanced](ADVANCED.md) - More advanced techniques

---

*For the complete tool list, see the [main documentation index](README.md).*
