# Snake Game Implementation in ARMv8 Assembly

This project implements the classic Snake game entirely in ARMv8 (AArch64) assembly language for Linux systems with a comprehensive multi-level gameplay system. The implementation demonstrates low-level system programming concepts including direct system call usage, terminal I/O control, memory management without standard library functions, real-time user input handling, and multi-level game state management.

The game runs natively on 64-bit ARM processors and showcases fundamental computer architecture principles through practical application development with three distinct gameplay modes.

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

## Build System

### Compilation Process
```bash
# Standard build (ARM64 systems only)
make

# GCC-based build (recommended for ARM64)
make gcc

# Cross-compile and run with QEMU (x86_64 systems)
make qemu-run

# Debug build with symbols
make debug
```

### Build Targets
- `all`: Standard assembly and linking (ARM64 only)
- `gcc`: GCC-based compilation for enhanced compatibility (ARM64 only)
- `qemu-run`: Cross-compile and run with QEMU emulation (x86_64 systems)
- `clean`: Remove build artifacts
- `run`: Build and execute in single command (ARM64 only)
- `install`: System-wide installation to `/usr/local/bin`

### Architecture Verification
```bash
make check-arch     # Check current architecture and build recommendations
```

### Cross-Platform Support
For x86_64 systems (Intel/AMD processors), the game can be run using QEMU emulation:

**Prerequisites:**
```bash
sudo apt update
sudo apt install -y qemu-user qemu-user-static
sudo apt install -y gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu
```

**Quick Start on x86_64:**
```bash
make qemu-run       # Automatically cross-compiles and runs with QEMU
```

## Usage Instructions

### Running the Game

**On ARM64 systems:**
```bash
make run            # Build and run natively
# or
./snake            # Run directly if already built
```

**On x86_64 systems:**
```bash
make qemu-run      # Cross-compile and run with QEMU
```

### Controls

**Level Selection:**
- **↑/W**: Navigate up in level menu
- **↓/S**: Navigate down in level menu
- **ENTER**: Confirm level selection and start game

**In-Game:**
- **W/↑**: Move up
- **A/←**: Move left  
- **S/↓**: Move down
- **D/→**: Move right
- **SPACE**: Pause/Unpause game
- **Q**: Quit game

### Game Levels

**Level 1 - Normal Mode:**
- Classic Snake gameplay with wall collisions
- Standard game speed with progressive acceleration
- Snake dies when hitting screen boundaries

**Level 2 - No Walls Mode:**
- Snake wraps around screen edges instead of dying
- Boundary collisions transport snake to opposite side
- Same speed progression as Normal Mode

**Level 3 - Super Fast Mode:**
- High-speed challenge with accelerated timing
- Faster base speed and quicker acceleration
- Standard wall collision rules apply

### Game Rules
- Snake moves continuously in current direction
- Eating food increases score and snake length
- Direction changes are queued and processed at next game tick
- Level-specific collision behavior (walls vs. wrapping)
- High scores are automatically saved per level to `file.txt`
- "NEW RECORD" message displays for level-specific record-breaking scores

## Performance Characteristics

### Timing Analysis
- **Frame Rate**: 5 FPS (200ms per frame) for Levels 1-2, 16+ FPS (60ms per frame) for Level 3
- **Input Latency**: <50ms typical response time across all levels
- **Memory Usage**: 6KB static allocation with level-specific data structures
- **CPU Usage**: Minimal (single-threaded, event-driven)

### Scalability Considerations
- Grid size configurable via constants (`GRID_WIDTH`, `GRID_HEIGHT`)
- Maximum snake length: 600 segments
- Game speed adjustable per level via timing constants
- Level system expandable with additional game modes

## Testing and Verification

### Functional Testing
The implementation has been validated on:
- Raspberry Pi 4 (Cortex-A72)
- AWS Graviton2 instances
- Apple Silicon under Linux virtualization

### Edge Case Handling
- Rapid direction changes (input queuing)
- Food spawning collision avoidance
- Terminal resize graceful degradation
- Signal handling for clean shutdown

## Educational Value

This project demonstrates several key computer systems concepts:

1. **Assembly Language Programming**: Register management, instruction encoding, calling conventions
2. **Operating System Interface**: System calls, kernel interaction, resource management  
3. **I/O Programming**: Terminal control, non-blocking input, escape sequence processing
4. **Real-time Systems**: Timing constraints, input responsiveness, frame rate consistency
5. **Memory Management**: Static allocation, data structure design, address calculation

## Features

### Multi-Level High Score System
The game includes a comprehensive persistent high score system:
- Separate high scores tracked for each of the three game levels
- Scores are automatically saved to `file.txt` in structured format when new records are achieved
- File format: `LEVEL1:score\nLEVEL2:score\nLEVEL3:score\n`
- File is created automatically if it doesn't exist
- Only actual record-breaking scores for the current level trigger saves and "NEW RECORD" messages
- Level-specific score validation and persistence
- Uses ARM64-optimized file I/O with proper error handling

## Potential Enhancements

Future development could incorporate:
- Additional game levels with unique mechanics (speed challenges, obstacle courses, etc.)
- Network multiplayer via socket system calls
- Audio feedback using ALSA or OSS interfaces
- Graphics acceleration through framebuffer access
- Performance profiling and optimization
- Advanced statistics tracking (time played per level, level completion rates)

## References

- ARM Limited. *ARM Architecture Reference Manual ARMv8*
- Torvalds, L. *Linux System Call Interface*
- Free Software Foundation. *GNU Assembler Manual*
- Stevens, W.R. *Advanced Programming in the UNIX Environment*

## License

This educational project is distributed under the MIT License for academic and learning purposes.