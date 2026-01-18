# Running ARM64 Snake Game on x86_64 Systems

This Snake game is written in ARMv8 (AArch64) assembly language, which means it's designed to run on ARM64 processors. If you're using a typical Windows/Linux system with an Intel or AMD processor (x86_64), you'll need to use QEMU emulation to run the game.

## Quick Start

```bash
sudo apt update
sudo apt install -y qemu-user qemu-user-static gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu
```

Then build and run:

```bash
aarch64-linux-gnu-as -o snake.o snake.s
aarch64-linux-gnu-ld -o snake snake.o
qemu-aarch64 ./snake
```

Or just:

```bash
make qemu-run
```

## Check If You Need This

```bash
uname -m
```

- `x86_64` = You need QEMU (this guide)
- `aarch64` = You don't need QEMU, just run `make run`

## Controls

**Menu**
- Arrow keys or W/S = Move up/down
- ENTER = Start
- Q = Quit

**Playing**
- Arrow keys or WASD = Move
- SPACE = Pause
- Q = Quit to menu

**Game Over**
- R = Restart
- Q = Back to menu

## Game Modes

1. CLASSIC - Walls kill you
2. ENDLESS - Walls wrap around
3. SPEED - Faster gameplay
4. MAZE - Dodge obstacles

## Fixes

**"command not found: qemu-aarch64"**
```bash
sudo apt install qemu-user qemu-user-static
```

**"command not found: aarch64-linux-gnu-as"**
```bash
sudo apt install binutils-aarch64-linux-gnu
```

**Terminal broken after crash**
```bash
reset
```

**High scores all 0**

Run the game from the folder with file.txt.

## WSL Notes

Windows paths in WSL:
```
C:\Users\You\snake-game
```
becomes:
```
/mnt/c/Users/You/snake-game
```

Use Windows Terminal for best results.

## Check Your Setup

```bash
qemu-aarch64 --version
aarch64-linux-gnu-as --version
file snake  # Should say "ARM aarch64"
```

## Notes

- QEMU transparently translates ARM64 instructions to x86_64, allowing the ARM binary to run on your Intel/AMD processor
- The first run might be slightly slower as QEMU initializes
- All game features including colors, controls, and scoring work normally under emulation

That's it! Hope you enjoy :-)