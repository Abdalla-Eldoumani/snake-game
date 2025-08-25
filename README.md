# Snake Game Implementation in ARMv8 Assembly

This project implements the classic Snake game entirely in ARMv8 (AArch64) assembly language for Linux systems. The implementation demonstrates low-level system programming concepts including direct system call usage, terminal I/O control, memory management without standard library functions, and real-time user input handling.

The game runs natively on 64-bit ARM processors and showcases fundamental computer architecture principles through practical application development.

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
1. Input Processing → 2. Game Logic → 3. Collision Detection → 4. Rendering → 5. Timing
```

#### Input Handling System
- Non-blocking input via modified file descriptor flags
- Support for both WASD keys and arrow key sequences
- Escape sequence parsing for arrow keys (`\x1b[A`, `\x1b[B`, etc.)
- Direction change validation preventing 180-degree turns

#### Collision Detection
- Boundary collision: Coordinate validation against grid dimensions
- Self-collision: Grid-based lookup for occupied cells
- Optimized with early termination on first collision detected

#### Rendering Pipeline
- ANSI escape sequence generation for cursor positioning
- Color-coded cell rendering (green snake, red food, white borders)
- Selective screen updates to reduce flicker
- Score display with integer-to-ASCII conversion

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
# Standard build
make

# GCC-based build (recommended)
make gcc

# Debug build with symbols
make debug
```

### Build Targets
- `all`: Standard assembly and linking
- `gcc`: GCC-based compilation for enhanced compatibility
- `clean`: Remove build artifacts
- `run`: Build and execute in single command
- `install`: System-wide installation to `/usr/local/bin`

### Architecture Verification
```bash
./build-check.sh    # Verify ARM64 compatibility and dependencies
```

## Usage Instructions

### Running the Game
```bash
./snake
```

### Controls
- **W/↑**: Move up
- **A/←**: Move left  
- **S/↓**: Move down
- **D/→**: Move right
- **Q**: Quit game

### Game Rules
- Snake moves continuously in current direction
- Eating food increases score and snake length
- Game terminates on wall collision or self-intersection
- Direction changes are queued and processed at next game tick

## Performance Characteristics

### Timing Analysis
- **Frame Rate**: 5 FPS (200ms per frame)
- **Input Latency**: <50ms typical response time
- **Memory Usage**: 6KB static allocation
- **CPU Usage**: Minimal (single-threaded, event-driven)

### Scalability Considerations
- Grid size configurable via constants (`GRID_WIDTH`, `GRID_HEIGHT`)
- Maximum snake length: 600 segments
- Game speed adjustable via `sleep_time` modification

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

## Potential Enhancements

Future development could incorporate:
- High score persistence using file I/O system calls
- Network multiplayer via socket system calls
- Audio feedback using ALSA or OSS interfaces
- Graphics acceleration through framebuffer access
- Performance profiling and optimization

## References

- ARM Limited. *ARM Architecture Reference Manual ARMv8*
- Torvalds, L. *Linux System Call Interface*
- Free Software Foundation. *GNU Assembler Manual*
- Stevens, W.R. *Advanced Programming in the UNIX Environment*

## License

This educational project is distributed under the MIT License for academic and learning purposes.
