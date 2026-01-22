Atari ATR disk image tools
--------------------------

Tools to create, list, extract, modify, and convert Atari `ATR` disk images.

atrforge: Create ATR images from list of files
---------------------------------------------

This program creates Atari `ATR` disk images from a list of files given
in the command line, in the SpartaDOS / BW-DOS disk format.

Usage:

    atrforge [options] output [+attributes] filenames

Options:

- `-a`  Add files to an existing ATR image (instead of creating a new one).
        The existing image must be a SpartaDOS/BW-DOS format image.

- `-b`  Selects the next file in the command line as the _boot_ file,
        the file will be loaded when the computer boots, and must be
        in the standard Atari binary file format.
        The bootloader for 128 bytes per sector needs 613 bytes, from $700 to
        $965, and the bootloader for 256 bytes per sector needs 848 bytes, from
        $700 to $A50, both can be relocated with the `-B` option.

- `-x`  Output image with exact sector count for all available content.
        This will use non-standard sector counts, and return images with
        128 bytes per sector if the image is smaller than about 8MB.

- `-s`  Specify the minimum size of the output image, in bytes. The image
        will be of this size or larger instead of the smaller possible.
        This allows creating images with available free space.
        Using this option with the `-x` option allows generating images of
        specific sizes (up to the sector size).

- `-B`  Specify the page (high part of address) of the start of the bootloader.
        Use this option to load games or other software with a low loading
        address that conflicts with the standard address of the bootloader.  A
        safe value is from page 6 instead of the default page 7, but page 4 or
        5 is also possible.

- `-h`  Shows a brief help.

- `-v`  Shows version information.

Also, in front of each file name you can optionally add a list of attributes to
be set for that file:

- `+p`  Marks this file as protected (read-only).

- `+h`  Hide file from directory. This only works in SpartaDOS-X.

- `+a`  Marks the file as "archived". This only works in SpartaDOS-X.

To place files inside a sub-directory, simply add the directory *before*
all the files inside that directory.

The resulting image will be the smaller size that fits all the given files (or
the minimum specified with `-s`), from the following list (except when the `-x`
option is used):

| Sector Count | Sector Size | Total Size | Name                     |
|         ---: |        ---: |       ---: | :---                     |
|       720    |       128   |      90k   | SD                       |
|      1040    |       128   |     130k   | ED                       |
|       720    |       256   |     180k   | DD                       |
|      1440    |       256   |     360k   | DSDD                     |
|      2048    |       256   |     512k   | hard disk                |
|      4096    |       256   |       1M   | hard disk                |
|      8192    |       256   |       2M   | hard disk                |
|     16384    |       256   |       4M   | hard disk                |
|     32768    |       256   |       8M   | hard disk                |
|     65535    |       256   |      16M   | biggest possible image   |

lsatr: List and extract contents of ATR images
----------------------------------------------

This program list or extracts the contents of an Atari `ATR` disk image.

The supported formats are:

- Atari DOS 1, single density.
- Atari DOS 2.0, single and double density.
- Atari DOS 2.5, enhanced density.
- MyDOS, up to 16MB images.
- SpartaDOS and BW-DOS, up to 16MB images.
- LiteDOS 2.x and LiteDOS-SE.
- BAS2BOOT images, extracts the BAS file inside.
- Howfen DOS images, extracting the raw BOOT images.
- K-file boot images, extracts the XEX file inside.


Usage:

    lsatr [options] filenames.atr

Options:

- `-a`  Shows the listing in the same format of native Atari tools,
        this is the file name separated by spaces to the file extension,
        followed by the size, date and time (if available), and each
        sub-directory in a separate listing.
        Standard listing format shows the size, the date, time (if available)
        and the full path at the end.

- `-l`  Show or extract all filenames in lowercase.

- `-x`  Extract all files in the current directory.

- `-X`  Extract all files in the directory given as argument to the option. If
        the directory does not exists, it will be created first.

- `-h`  Shows a brief help.

- `-v`  Shows version information.

Usage Examples
--------------

To create an image named `disk1.atr` with all the files in the "atari"
directory:

    atrforge disk1.atr atari/*

To create a bootable BW-DOS image with a hidden and protected DOS file inside
a subdirectory and a protected `startup.bat` file outside:

    atrforge bwdos.atr dos/ -b +ph dos/xbw130.dos +p startup.bat

To create an image with only one file that will be loaded at boot:

    atrforge game.atr -b mygame.com

To list the files inside an image:

    lsatr bwdos.atr

To extract all files from the image to a folder `out`:

    lsatr -X out/ bwdos.atr

convertatr: Convert and resize ATR images
------------------------------------------

This program converts ATR images between different formats and sizes.

Usage:

    convertatr [options] <input.atr> <output.atr>

Options:

- `--resize N`      Resize the image to N sectors (can only increase size).
- `--sector-size N` Convert to N-byte sectors (128 or 256).
- `-h`              Show help.
- `-v`              Show version information.

Examples:

To resize an ATR image to 1440 sectors:

    convertatr --resize 1440 disk1.atr disk1_large.atr

To convert from 128-byte to 256-byte sectors:

    convertatr --sector-size 256 disk128.atr disk256.atr

Compilation
-----------

Compile with `make` and copy the resulting `atrforge`, `lsatr`, and `convertatr`
programs to your bin folder.

Build Requirements
------------------

- A C compiler (GCC or Clang recommended)
- Standard C library
- Make utility

Security Considerations
----------------------

When extracting files from ATR images, the tools implement path sanitization to
prevent directory traversal attacks. All file paths are validated before extraction
to ensure they don't contain dangerous components like `..` or absolute paths.

However, users should still exercise caution when:
- Extracting files from untrusted ATR images
- Using the `-X` option with user-provided directory paths
- Processing ATR images from unknown sources

For more details, see `SECURITY.md`.

Known Limitations
-----------------

- Maximum ATR image size is 16MB (65535 sectors of 256 bytes)
- Some DOS formats may have limited support for certain features
- File attributes (hidden, protected, archived) are only fully supported in
  SpartaDOS-X format
- Boot file relocation (`-B` option) should be used with caution and proper
  understanding of the target system's memory layout

Version Information
-------------------

**atrforge** has been rebranded from the original mkatr tools. The version
numbering has been reset to start at 1.0.0 and will increment from there. The
patch level (third number) is automatically incremented on each build, so each
rebuild will result in a new version number (e.g., 1.0.0 → 1.0.1 → 1.0.2).
