# Running ARM64 Snake Game on x86_64 Systems

This Snake game is written in ARMv8 (AArch64) assembly language, which means it's designed to run on ARM64 processors. If you're using a typical Windows/Linux system with an Intel or AMD processor (x86_64), you'll need to use QEMU emulation to run the game.

## Prerequisites

- WSL (Windows Subsystem for Linux) or any Linux distribution
- Terminal with sudo access

## Setup Instructions

### 1. Check Your Architecture

First, verify that you need emulation:

```bash
uname -m
```

If this shows `x86_64` or `amd64`, continue with this guide. If it shows `aarch64` or `arm64`, you can compile and run the game directly without QEMU.

### 2. Install QEMU and ARM64 Tools

Open your terminal and run:

```bash
# Update package list
sudo apt update

# Install QEMU ARM64 emulator
sudo apt install -y qemu-user qemu-user-static

# Install ARM64 cross-compilation tools
sudo apt install -y gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu
```

### 3. Build the Game

Navigate to the directory containing `snake.s` and run:

```bash
# Assemble the ARM64 code
aarch64-linux-gnu-as -o snake.o snake.s

# Link the object file
aarch64-linux-gnu-ld -o snake snake.o
```

Alternatively, if a Makefile is present:

```bash
# Use the cross-compiler with make
make CC=aarch64-linux-gnu-gcc AS=aarch64-linux-gnu-as LD=aarch64-linux-gnu-ld
```

### 4. Run the Game

Execute the game through QEMU:

```bash
qemu-aarch64 ./snake
```

## Game Controls

- **W/↑**: Move up
- **A/←**: Move left
- **S/↓**: Move down
- **D/→**: Move right
- **SPACE**: Pause/Unpause game
- **Q**: Quit game

## Troubleshooting

### Terminal Display Issues
If the game display appears corrupted, ensure your terminal supports ANSI escape sequences. Most modern terminals (Windows Terminal, Ubuntu Terminal) support this by default.

### Performance
The game runs through emulation, so there might be a slight performance overhead compared to native execution. However, for a Snake game, this should be negligible.

## Notes

- QEMU transparently translates ARM64 instructions to x86_64, allowing the ARM binary to run on your Intel/AMD processor
- The first run might be slightly slower as QEMU initializes
- All game features including colors, controls, and scoring work normally under emulation

That's it! Hope you enjoy :-)