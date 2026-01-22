# Building atrforge

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Build](#quick-build)
3. [Build Options](#build-options)
4. [Platform-Specific Instructions](#platform-specific-instructions)
5. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required

- **C Compiler**: GCC 4.8+ or compatible (Clang, MSVC)
- **Make**: GNU Make 3.81+ or compatible
- **Standard C Library**: POSIX-compliant C library

### Optional

- **Git**: For version control
- **Debugger**: GDB or compatible for debugging
- **Docker**: For cross-platform builds (macOS, etc.)

## Quick Build

### Standard Build

```bash
# Clone or download source
cd atrforge

# Build all programs
make

# Executables will be in bin/
./bin/atrforge -h
./bin/lsatr -h
./bin/convertatr -h
./bin/atrcp -h
```

### Clean Build

```bash
# Remove all build artifacts
make clean

# Rebuild
make
```

## Build Options

### Make Targets

- `make` or `make all` - Build all programs (default)
- `make clean` - Remove all build artifacts
- `make distclean` - Remove all build artifacts and binaries
- `make help` - Show build system help
- `make test` - Run automated tests (if configured)
- `make release` - Build release binaries for all platforms
- `make github-release` - Build and create GitHub release (requires gh CLI)

### Compiler Options

The Makefile uses these default flags:

```makefile
CFLAGS = -O2 -Wall
LDLIBS = 
```

**Flags Explained**:
- Customize `CFLAGS` and `LDLIBS` in the Makefile or via command line

### Custom Build Options

#### Debug Build

```bash
make CFLAGS="-g -O0 -Wall"
```

#### Release Build (No Debug Symbols)

```bash
make CFLAGS="-O3 -flto -DNDEBUG"
```

#### Custom Compiler

```bash
make CC=clang
```

## Build System Details

### Directory Structure

```
atrforge/
├── obj/          # Object files (created)
├── bin/          # Executables (created)
│   ├── atrforge
│   ├── lsatr
│   ├── convertatr
│   └── atrcp
├── src/          # Source files
└── Makefile      # Build configuration
```

### Source Files

Source files are located in `src/`. The build system uses explicit source lists for each program in the Makefile.

### Dependencies

**External**:
- Standard C library (`libc`)

### Build Process

1. **Version Handling**: Reads VERSION file and generates `src/version.h`
2. **Compilation**: Each `.c` file compiled to `.o` object file in `obj/`
3. **Linking**: All object files linked into executables in `bin/`

## Platform-Specific Instructions

### Linux

**Requirements**:
- GCC or Clang
- Make
- Standard development tools

**Build**:
```bash
make
```

**Install** (optional):
```bash
sudo cp bin/* /usr/local/bin/
```

### macOS

**Requirements**:
- Xcode Command Line Tools
- Make (included with Xcode)

**Build**:
```bash
make
```

**Note**: May need to install Xcode Command Line Tools:
```bash
xcode-select --install
```

### Windows

**Option 1: MinGW/MSYS2**

```bash
# Install MSYS2, then:
pacman -S mingw-w64-x86_64-gcc make

# Build
make CC=x86_64-w64-mingw32-gcc
```

**Option 2: Visual Studio**

1. Open Developer Command Prompt
2. Navigate to source directory
3. Use NMake or convert Makefile to Visual Studio project

**Option 3: WSL (Windows Subsystem for Linux)**

Use Linux build instructions in WSL environment.

### Cross-Compilation

**Example: Build for ARM**

```bash
make CC=arm-linux-gnueabihf-gcc
```

**Example: Build for 32-bit**

```bash
make CC=gcc CFLAGS="-O3 -Wall -g -m32"
```

## Release Builds

### Build All Platforms

```bash
make release
```

This builds binaries for:
- Linux amd64 (atrforge, lsatr, convertatr, atrcp)
- Linux arm64 (atrforge, lsatr, convertatr, atrcp)
- Windows x86_64 (atrforge, lsatr, convertatr, atrcp)
- macOS x86_64 (requires Docker)
- macOS arm64 (requires Docker)

### Create GitHub Release

```bash
# Build all platforms and create GitHub release
make github-release

# Or specify version
make github-release VERSION=v1.2.3
```

**Prerequisites**:
- Docker (for macOS builds)
- GitHub CLI (`gh`) installed and authenticated
- Cross-compilation tools (or Docker)

## Troubleshooting

### Build Errors

#### "Command not found: gcc"

**Solution**: Install GCC compiler
- Linux: `sudo apt-get install gcc` (Debian/Ubuntu)
- macOS: Install Xcode Command Line Tools
- Windows: Install MinGW or use WSL

#### "fatal error: header.h: No such file or directory"

**Solution**: Check include paths in Makefile or set `INCLUDE_DIRS` variable

#### "undefined reference to function"

**Solution**: Check linker libraries in `LDLIBS` variable

### Runtime Errors

#### "can't open file"

**Solution**: Check file path and permissions

#### Segmentation Fault

**Solution**: Build with debug symbols and use debugger
```bash
make CFLAGS="-g -O0 -Wall"
gdb ./bin/atrforge
```

## Advanced Build Configuration

### Custom Makefile Variables

Edit `Makefile` or override on command line:

```bash
# Custom compiler
make CC=clang

# Custom flags
make CFLAGS="-O2 -Wall -g -DDEBUG"

# Custom build directory
make BDIR=output
```

### Separate Debug/Release Builds

```bash
# Debug build
mkdir -p build-debug
make BDIR=build-debug CFLAGS="-g -O0 -Wall"

# Release build
mkdir -p build-release
make BDIR=build-release CFLAGS="-O3 -flto -Wall -DNDEBUG"
```

### Static Linking

```bash
make LDFLAGS="-static"
```

## See Also

- [Installation Guide](INSTALLATION.md) - Installation instructions
- [Contributing Guide](CONTRIBUTING.md) - Development guidelines
- [CI/CD Documentation](CI_CD.md) - Continuous integration setup
