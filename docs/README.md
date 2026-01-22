# atrforge Documentation

Welcome to the comprehensive documentation for **atrforge** - your friendly neighborhood Atari ATR disk image toolkit. Yes, we know it's 2026 and you're still using 8-bit disk images. We're not judging. In fact, we think it's pretty cool.

## What is atrforge?

atrforge is a collection of command-line tools for creating, manipulating, extracting, and converting Atari ATR disk images. Whether you're preserving vintage software, developing new Atari 8-bit programs, or just curious about how these old disk formats work, atrforge has you covered.

The toolkit consists of four main tools:

- **`atrforge`** - Create ATR images from files (the star of the show)
- **`lsatr`** - List and extract contents from ATR images (the nosy neighbor)
- **`convertatr`** - Convert and resize ATR images (the shape-shifter)
- **`atrcp`** - Copy files in and out of ATR images (the file courier)

## Quick Start

If you're the impatient type (we get it), here's the 30-second version:

```bash
# Create a disk image
atrforge mydisk.atr file1.com file2.bas

# See what's inside
lsatr mydisk.atr

# Extract everything
lsatr -X output/ mydisk.atr
```

That's it. You're now an atrforge user. Congratulations! For the full story, keep reading.

## Documentation Index

### Getting Started

- **[Installation Guide](INSTALLATION.md)** - How to build and install atrforge (it's easier than you think)
- **[Examples](EXAMPLES.md)** - Real-world usage examples that actually make sense

### Tool Documentation

- **[atrforge](ATRFORGE.md)** - Creating ATR images from scratch (or adding to existing ones)
- **[lsatr](LSATR.md)** - Listing and extracting files from ATR images
- **[convertatr](CONVERTATR.md)** - Converting and resizing ATR images
- **[atrcp](ATRCP.md)** - Copying individual files to and from ATR images

### Technical Reference

- **[ATR Format](ATR_FORMAT.md)** - The gory details of the ATR file format
- **[DOS Formats](DOS_FORMATS.md)** - Supported filesystems and what they can do
- **[File Attributes](FILE_ATTRIBUTES.md)** - Making files hidden, protected, or archived
- **[Boot Files](BOOT_FILES.md)** - Creating bootable disk images (the fun stuff)
- **[UTF8 Conversion](UTF8_CONVERSION.md)** - Converting between UTF8 and ATASCII (because modern editors are picky)

### Advanced Topics

- **[Advanced Usage](ADVANCED.md)** - For when you want to get fancy
- **[Troubleshooting](TROUBLESHOOTING.md)** - When things go wrong (and how to fix them)

### Project Information

- **[Changelog](CHANGELOG.md)** - History of changes, features, and fixes
- **[Attributions](ATTRIBUTIONS.md)** - Credits and acknowledgments

## Tool Summary

### atrforge

Creates ATR disk images in SpartaDOS/BW-DOS format. You give it files, it gives you a disk image. Simple as that.

**Best for:** Creating new disk images, making bootable disks, organizing files into disk images

### lsatr

Lists and extracts files from ATR images. It's like `ls` and `tar` had a baby, but for 8-bit disk images.

**Best for:** Inspecting disk contents, extracting files, verifying disk images

### convertatr

Converts between different ATR formats and sizes. Need a bigger disk? Different sector size? This is your tool.

**Best for:** Resizing disks, converting sector sizes, batch conversions

### atrcp

Copies individual files between ATR images and your host filesystem. Think `cp`, but for files inside disk images.

**Best for:** Quick file operations, updating single files, UTF8/ATASCII conversion on the fly

## Getting Help

Each tool has built-in help. Just run it with `-h`:

```bash
atrforge -h
lsatr -h
convertatr -h
atrcp -h
```

For version information, use `-v`:

```bash
atrforge -v
```

## What's Next?

- New to atrforge? Start with the [Installation Guide](INSTALLATION.md) and then check out [Examples](EXAMPLES.md)
- Want to create a disk image? Read [atrforge documentation](ATRFORGE.md)
- Need to extract files? See [lsatr documentation](LSATR.md)
- Working with boot files? Check out [Boot Files](BOOT_FILES.md)
- Having problems? Try [Troubleshooting](TROUBLESHOOTING.md)

## License

atrforge is free software released under the GNU General Public License (GPL). See the main `LICENSE` file in the project root for details.

## Contributing

Found a bug? Have a suggestion? Want to contribute? Check out the main project repository. We're always happy to see improvements (especially if they come with documentation).

---

*Last updated: 2026. Because we keep track of these things.*
