#!/bin/bash

# Snake Game Build Verification Script
# This script checks if the system is compatible and provides build guidance

echo "=== Snake Game Build Check ==="
echo

# Check architecture
ARCH=$(uname -m)
echo "Current architecture: $ARCH"

if [ "$ARCH" = "aarch64" ]; then
    echo "✓ ARM64 architecture detected - compatible!"
    
    # Check for required tools
    echo
    echo "Checking build tools..."
    
    if command -v as &> /dev/null; then
        echo "✓ GNU Assembler (as) found"
        AS_VERSION=$(as --version | head -n 1)
        echo "  $AS_VERSION"
    else
        echo "✗ GNU Assembler (as) not found"
        echo "  Install with: sudo apt install binutils (Debian/Ubuntu)"
        echo "               sudo pacman -S binutils (Arch Linux)"
        BUILD_READY=false
    fi
    
    if command -v ld &> /dev/null; then
        echo "✓ GNU Linker (ld) found"
        LD_VERSION=$(ld --version | head -n 1)
        echo "  $LD_VERSION"
    else
        echo "✗ GNU Linker (ld) not found"
        echo "  Install with: sudo apt install binutils (Debian/Ubuntu)"
        echo "               sudo pacman -S binutils (Arch Linux)"
        BUILD_READY=false
    fi
    
    if command -v gcc &> /dev/null; then
        echo "✓ GCC found (recommended for building)"
        GCC_VERSION=$(gcc --version | head -n 1)
        echo "  $GCC_VERSION"
    else
        echo "! GCC not found (optional but recommended)"
        echo "  Install with: sudo apt install gcc (Debian/Ubuntu)"
        echo "               sudo pacman -S gcc (Arch Linux)"
    fi
    
    echo
    echo "=== Build Instructions ==="
    echo "1. Standard build:  make"
    echo "2. GCC build:       make gcc"
    echo "3. Run game:        make run"
    echo "4. Clean:           make clean"
    echo
    echo "Ready to build!"
    
elif [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "i386" ] || [ "$ARCH" = "i686" ]; then
    echo "✗ x86/x64 architecture detected - NOT compatible"
    echo
    echo "This Snake game is written specifically for ARM64 (AArch64) processors."
    echo "It will NOT run on x86/x64 systems."
    echo
    echo "Compatible systems:"
    echo "  - Raspberry Pi 3/4 running 64-bit Linux"
    echo "  - Apple Silicon Macs running Linux (via UTM/Parallels/native boot)"
    echo "  - AWS Graviton instances"
    echo "  - Any other ARM64 Linux system"
    echo
    echo "To test this game, you need to:"
    echo "1. Transfer files to an ARM64 Linux system"
    echo "2. Run this script on that system"
    echo "3. Build and run the game there"
    
else
    echo "? Unknown architecture: $ARCH"
    echo
    echo "This game requires ARM64 (AArch64) architecture."
    echo "If you're on an ARM64 system, the build tools might still work."
    echo "Try running 'make' to see if the build succeeds."
fi

echo
echo "=== System Information ==="
echo "OS: $(uname -s)"
echo "Kernel: $(uname -r)"
echo "Architecture: $ARCH"

if [ -f /proc/version ]; then
    echo "Distribution: $(cat /proc/version)"
fi

echo
echo "For questions or issues, check the README.md file."