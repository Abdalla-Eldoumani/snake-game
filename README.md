# Snake Game - ARM64 Assembly

Snake game written in ARM64 assembly for Linux. Has 4 game modes, power-ups, lives, and saves high scores.

```
    ███████ ███    ██  █████  ██   ██ ███████
    ██      ████   ██ ██   ██ ██  ██  ██
    ███████ ██ ██  ██ ███████ █████   █████
         ██ ██  ██ ██ ██   ██ ██  ██  ██
    ███████ ██   ████ ██   ██ ██   ██ ███████

           ~ Classic Arcade Game ~
```

## Technical Specifications

### Target Architecture
- **ISA**: ARMv8-A (AArch64)
- **ABI**: AAPCS64 (ARM Architecture Procedure Call Standard)
- **Operating System**: Linux (kernel 4.1+)
- **Word Size**: 64-bit

### Hardware Requirements
- ARM64 processor (Cortex-A53, Cortex-A72, Apple Silicon, etc.)
- Minimum 32MB RAM
- Terminal supporting ANSI escape sequences

### Software Dependencies
- GNU Binutils (assembler `as`, linker `ld`)
- Optional: GCC for alternative linking
- Make utility for build automation

## Architecture and Implementation

### System Call Interface
The program interfaces directly with the Linux kernel through the ARMv8 system call convention:
- System call number in register `x8`
- Arguments in registers `x0-x5`
- Invocation via `svc #0` instruction
- Return value in `x0`

**Primary System Calls Used:**
- `read(63)`: Non-blocking keyboard input
- `write(64)`: Terminal output operations
- `ioctl(29)`: Terminal mode configuration
- `nanosleep(101)`: Game timing control
- `getrandom(278)`: Cryptographically secure random number generation
- `fcntl(25)`: File descriptor flag manipulation
- `openat(56)`: File access for high score persistence
- `close(57)`: File descriptor cleanup

### Memory Management
The program employs static memory allocation exclusively, with no dynamic memory allocation or standard library dependencies.

**Memory Layout:**
```
.text    : Executable code (~2KB)
.data    : Game state and constants (~6KB)
.bss     : Uninitialized data buffers
```

**Key Data Structures:**
- `game_grid`: 2D array representing the 30×20 play field
- `snake_body`: Circular buffer storing coordinate pairs for snake segments
- `termios_orig/raw`: Terminal configuration structures

### Game Engine Architecture

#### Core Game Loop
```
1. Level Selection → 2. Input Processing → 3. Game Logic → 4. Collision Detection → 5. Rendering → 6. Timing
```

#### Multi-Level System
- Interactive welcome screen with level selection interface
- Arrow key navigation (↑/↓ or W/S keys) for level selection
- Visual selection indicators with real-time menu updates
- Three distinct gameplay modes with unique mechanics

#### Input Handling System
- Non-blocking input via modified file descriptor flags
- Support for both WASD keys and arrow key sequences
- Escape sequence parsing for arrow keys (`\x1b[A`, `\x1b[B`, etc.)
- Direction change validation preventing 180-degree turns
- Menu navigation support for level selection

#### Collision Detection
- Level-aware boundary collision with configurable behavior
- Self-collision: Grid-based lookup for occupied cells
- Wall wrapping mechanics for specific game modes
- Optimized with early termination on first collision detected

#### Rendering Pipeline
- ANSI escape sequence generation for cursor positioning
- Color-coded cell rendering (green snake, red food, white borders)
- Selective screen updates to reduce flicker
- Score display with integer-to-ASCII conversion
- Level indicator display showing current game mode

### Terminal Control Implementation
The program implements raw terminal mode to capture individual keystrokes:

1. **Save original terminal settings** via `ioctl(TCGETS)`
2. **Configure raw mode** by clearing `ICANON` and `ECHO` flags
3. **Set immediate input** with `VMIN=1, VTIME=0`
4. **Restore settings on exit** for proper cleanup

This approach bypasses line buffering and provides real-time input response essential for interactive gameplay.

## Run It

**On x86_64:**
```bash
sudo apt install qemu-user qemu-user-static gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu
aarch64-linux-gnu-as -o snake.o snake.s
aarch64-linux-gnu-ld -o snake snake.o
qemu-aarch64 ./snake
```

**On ARM64 (Raspberry Pi, etc):**
```bash
make run
```

## Controls

**Menu:** Arrow keys or W/S to move, ENTER to select, Q to quit

**Game:** Arrow keys or WASD to move, SPACE to pause, Q to quit

**Game Over:** R to restart, Q for menu

## Game Modes

- **CLASSIC** - Hit a wall, lose a life
- **ENDLESS** - Walls wrap around
- **SPEED** - Everything moves faster
- **MAZE** - Obstacles on the field

## Power-ups

10% chance to spawn after eating food:
- Blue `~` = Slow motion (shows countdown)
- Purple `-` = Shrinks your snake

## Lives

You get 3 lives. Screen flashes red when you die. Score keeps going until all lives gone.

## High Scores

Saved to `file.txt`, one score per level. Shows on the menu.

## Files

```
snake.s              - The source code of the game
Makefile             - Build commands
file.txt             - High scores
QEMU_SETUP_GUIDE.md  - Setup help for x86_64
```

## Build Commands

```bash
make              # Build (ARM64 only)
make run          # Build and run (ARM64 only)
make qemu-run     # Build and run with QEMU (x86_64)
make clean        # Delete build files
```

## References

- ARM Limited. *ARM Architecture Reference Manual ARMv8*
- Torvalds, L. *Linux System Call Interface*
- Free Software Foundation. *GNU Assembler Manual*
- Stevens, W.R. *Advanced Programming in the UNIX Environment*

## License

MIT