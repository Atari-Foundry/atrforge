# Installation Guide

So you want to install atrforge? Good choice. It's actually pretty straightforward, which is refreshing in a world where "just run make" often means "spend three hours debugging dependency hell."

## System Requirements

atrforge is written in C and should compile on any system with a reasonable C compiler. We've tested it on:

- Linux (various distributions)
- macOS
- Other Unix-like systems

**Required:**
- A C compiler (GCC or Clang recommended)
- Make utility
- Standard C library

That's it. No fancy dependencies, no package managers required (though you can use them if you want). We keep it simple.

## Building from Source

### Step 1: Get the Source

If you're reading this, you probably already have the source. If not, clone the repository or download the source code.

### Step 2: Build It

Navigate to the `atrforge` directory and run:

```bash
make
```

That's it. Really. If it doesn't work, see the Troubleshooting section below. But it should work. We tested it and everything.

The build process will:
1. Create `obj/` directory for object files
2. Create `bin/` directory for the final binaries
3. Compile all source files
4. Link everything together
5. Place the executables in `bin/`

### Step 3: Use It

The binaries are now in the `bin/` directory:

- `bin/atrforge`
- `bin/lsatr`
- `bin/convertatr`
- `bin/atrcp`

You can run them directly, or copy them to somewhere in your PATH (like `/usr/local/bin` or `~/bin`).

## Installation Options

### Option 1: Use from Build Directory

Just run the binaries from `bin/`:

```bash
./bin/atrforge disk.atr file.com
```

Simple, but you'll need to specify the path each time.

### Option 2: Copy to System Path

Copy the binaries to a directory in your PATH:

```bash
sudo cp bin/* /usr/local/bin/
```

Or for your user directory:

```bash
mkdir -p ~/bin
cp bin/* ~/bin/
export PATH="$HOME/bin:$PATH"  # Add to your ~/.bashrc or ~/.zshrc
```

### Option 3: Create Symlinks

Create symlinks instead of copying:

```bash
sudo ln -s $(pwd)/bin/atrforge /usr/local/bin/atrforge
sudo ln -s $(pwd)/bin/lsatr /usr/local/bin/lsatr
sudo ln -s $(pwd)/bin/convertatr /usr/local/bin/convertatr
sudo ln -s $(pwd)/bin/atrcp /usr/local/bin/atrcp
```

This way, when you rebuild, the symlinks automatically point to the new binaries.

## Build Options

The Makefile uses standard CFLAGS. You can override them if you want:

```bash
make CFLAGS="-O3 -march=native"
```

Or add debug symbols:

```bash
make CFLAGS="-g -O0"
```

We're not going to judge your optimization choices.

## Version Information

atrforge uses semantic versioning. The version is stored in the `VERSION` file and is automatically incremented on each build (the patch level, anyway). To see the version:

```bash
atrforge -v
```

Or check the `VERSION` file:

```bash
cat VERSION
```

## Cleaning Up

To remove build artifacts:

```bash
make clean
```

This removes the `obj/` and `bin/` directories and all compiled files. It's like it never happened.

For a more thorough cleanup:

```bash
make distclean
```

This does everything `clean` does, plus removes the version stamp file.

## Troubleshooting

### "make: command not found"

You need to install `make`. On most systems:
- Linux: `sudo apt install build-essential` (Debian/Ubuntu) or `sudo yum groupinstall "Development Tools"` (RHEL/CentOS)
- macOS: Install Xcode Command Line Tools: `xcode-select --install`

### "gcc: command not found"

You need a C compiler. See above for installation instructions.

### "Permission denied"

If you're trying to install to a system directory, you'll need `sudo`. Or install to your user directory instead.

### Build Errors

If you get compilation errors:
1. Make sure you have a recent C compiler
2. Check that all source files are present
3. Try `make clean` and rebuild
4. Check the error message - it usually tells you what's wrong

### Version Increment Issues

The build system automatically increments the patch version on each build. If this causes issues (it shouldn't), you can manually edit the `VERSION` file. It's just a text file with a version number like `1.0.13`.

## What Gets Built

The build process creates:

- **Object files** in `obj/` - Intermediate compilation results
- **Binaries** in `bin/` - The actual programs you'll use
- **Version header** in `src/version.h` - Generated from `VERSION` file

The source code stays untouched (unless you edit it, which is encouraged).

## Next Steps

Now that you have atrforge installed:

1. Try creating a disk image: `atrforge test.atr somefile.com`
2. List its contents: `lsatr test.atr`
3. Read the [Examples](EXAMPLES.md) for more ideas
4. Check out the [Tool Documentation](README.md#tool-documentation) for detailed usage

Welcome to the club. You're now ready to create, manipulate, and extract Atari disk images like a pro (or at least like someone who read the documentation).

---

*For more information, see the [main documentation index](README.md).*
