# File Attributes

Atari disk files can have attributes that control how they behave. Some make files read-only, some hide them from directory listings, and some mark them as archived. It's like file permissions, but simpler (and older).

## Overview

File attributes are flags that modify how files behave on the Atari. They're stored in the filesystem and affect how the file is displayed, accessed, and modified.

**Supported attributes:**
- **Protected** (`+p`) - Makes files read-only
- **Hidden** (`+h`) - Hides files from directory listings
- **Archived** (`+a`) - Marks files as backed up

**Important:** Attributes are primarily a SpartaDOS-X feature. They may not work (or work differently) in other DOS formats.

## Protected Files (`+p`)

Protected files are read-only. The Atari won't let you delete or modify them without first removing the protection.

### Setting Protection

When creating an image with `atrforge`:

```bash
atrforge disk.atr +p important.com
```

This marks `important.com` as protected.

### What It Does

- **Prevents deletion** - The file can't be deleted (without removing protection first)
- **Prevents modification** - The file can't be modified
- **Still readable** - The file can still be read and executed

### Use Cases

- System files that shouldn't be modified
- Important data files
- Configuration files
- Files you want to prevent accidental changes

### Removing Protection

On the Atari, you can remove protection using DOS commands. atrforge tools don't currently support removing protection (you'd need to recreate the image or use Atari tools).

## Hidden Files (`+h`)

Hidden files don't appear in normal directory listings. They're still there, they're just not shown. It's like the Unix `.` prefix, but built into the filesystem.

### Setting Hidden Attribute

When creating an image with `atrforge`:

```bash
atrforge disk.atr +h secret.com
```

This marks `secret.com` as hidden.

### What It Does

- **Hides from listings** - File doesn't appear in normal `DIR` commands
- **Still accessible** - File can still be accessed if you know the name
- **SpartaDOS-X only** - Only works in SpartaDOS-X, not in other DOS formats

### Use Cases

- System files you don't want cluttering directory listings
- Files you want to keep private (though not really secure)
- Temporary files
- Backup files

### Viewing Hidden Files

On SpartaDOS-X, you can view hidden files using special commands or options. Normal directory listings won't show them.

## Archived Files (`+a`)

Archived files are marked as having been backed up. It's a flag that says "this file has been archived." It doesn't actually do anything to the file, it's just a marker.

### Setting Archived Attribute

When creating an image with `atrforge`:

```bash
atrforge disk.atr +a backup.com
```

This marks `backup.com` as archived.

### What It Does

- **Marks as backed up** - Indicates the file has been archived
- **No functional effect** - Doesn't change file behavior
- **SpartaDOS-X only** - Only meaningful in SpartaDOS-X

### Use Cases

- Files that have been backed up
- Marking files for backup systems
- Tracking which files need archiving

## Combining Attributes

You can combine multiple attributes on a single file:

```bash
atrforge disk.atr +ph system.com
```

This makes `system.com` both protected and hidden.

### Common Combinations

- **`+ph`** - Protected and hidden (system files)
- **`+pa`** - Protected and archived (backed up system files)
- **`+ha`** - Hidden and archived (backed up hidden files)
- **`+pha`** - All three (the ultimate system file)

## Setting Attributes with atrforge

### Single File

```bash
atrforge disk.atr +p file1.com +h file2.com +a file3.com
```

Each attribute prefix applies only to the file immediately following it.

### Multiple Files

```bash
atrforge disk.atr \
    +p important1.com \
    +p important2.com \
    +h secret1.com \
    +h secret2.com
```

You need to specify the attribute for each file individually.

### In Directories

```bash
atrforge disk.atr \
    system/ +p system/config.sys \
    games/ game1.com game2.com
```

Attributes work the same way in subdirectories.

## Viewing Attributes

### With lsatr

When listing files with `lsatr`, attributes may be shown depending on the DOS format and listing mode. SpartaDOS-X format images will show attribute information.

### On the Atari

On SpartaDOS-X, you can view file attributes using the `DIR` command with appropriate options. The attributes are displayed as flags (P for protected, H for hidden, A for archived).

## Attribute Compatibility

### SpartaDOS-X / BW-DOS

**Full support.** All attributes work as expected.

### Other DOS Formats

**Limited or no support.** Attributes may not be stored or may not function:
- **Atari DOS** - No attribute support
- **MyDOS** - Limited attribute support
- **LiteDOS** - Varies by version

If you set attributes on files in a SpartaDOS image, they'll work. If you try to read attributes from other formats, you may not see them.

## Tips and Tricks

1. **Use protection for system files** - Protect important files from accidental modification
2. **Hide temporary files** - Use hidden attribute for files you don't want in listings
3. **Combine attributes** - Use multiple attributes for maximum control
4. **Check DOS compatibility** - Make sure your target DOS supports the attributes you're using
5. **Attributes are per-file** - Each file needs its own attribute prefix

## Common Mistakes

- **Forgetting the `+`** - It's `+p`, not `-p` or `--protected`. The `+` is important.
- **Wrong order** - Attributes must come before the filename, not after.
- **Expecting universal support** - Attributes are primarily a SpartaDOS-X feature.
- **Thinking hidden = secure** - Hidden files aren't really secure, they're just not shown in listings.

## See Also

- [atrforge](ATRFORGE.md) - How to set attributes when creating images
- [DOS Formats](DOS_FORMATS.md) - Which formats support attributes
- [Examples](EXAMPLES.md) - Examples of using attributes

---

*For the complete tool list, see the [main documentation index](README.md).*
