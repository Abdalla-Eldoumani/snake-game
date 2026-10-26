# Snake Game - ARM64 Assembly

Snake for the terminal, written in ARMv8 (AArch64) assembly with no libc:
raw Linux syscalls, raw terminal mode, real-time input, ANSI rendering.
Six game modes, combo scoring, power-ups, lives, and per-mode high scores.

```
    ███████ ███    ██  █████  ██   ██ ███████
    ██      ████   ██ ██   ██ ██  ██  ██
    ███████ ██ ██  ██ ███████ █████   █████
         ██ ██  ██ ██ ██   ██ ██  ██  ██
    ███████ ██   ████ ██   ██ ██   ██ ███████
```

## Run it

**ARM64 Linux** (Raspberry Pi, Apple Silicon VM, any aarch64 box):

```bash
make run
```

**x86_64 via QEMU** (setup details in QEMU_SETUP_GUIDE.md):

```bash
sudo apt install m4 qemu-user gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu
make qemu-run
```

**Browser**: the exact same program runs in the
[AArch64 Playground](https://aarch64-playground.com/playground?example=snake) --
its emulator implements the terminal syscalls this game stands on and
hands it the terminal pane. Same keys, same game, no install.

A prebuilt static binary ships with each release:
`qemu-aarch64 ./snake-linux-arm64` (or run it directly on arm64).

## Controls

| where | keys |
|---|---|
| menu | W/S or arrows to select, ENTER to start, Q to quit |
| game | WASD or arrows to steer, SPACE to pause, Q to end the run |
| game over | R to restart, Q for the menu |

## Modes

- **CLASSIC** - walls end a life
- **ENDLESS** - edges wrap around
- **SPEED** - fast from the first frame, faster as you grow
- **MAZE** - six obstacles, plus a new wall every 5 foods
- **HYPER** - starts calm, accelerates with every bite
- **MINES** - wrapping field where a new mine lands every 5 seconds

## Scoring

- Food `*` = 1 point; golden food = 5 points, 20% chance, gone after 7 s
- **Combo streaks**: eat again within 3 s to multiply points, x2 up to x5;
  the multiplier rides in the header and dies with you
- Power-ups (10% after eating): blue `~` slow motion, purple `-` shrink
- Three lives; a death resets the snake, the score survives
- The game over screen tallies the run: food eaten, time alive, longest
  length, deepest combo

High scores persist per mode in `file.txt`, written and re-read with raw
`openat`/`read`/`write`/`close` syscalls; older four-line files load fine.

## Under the hood

- Kernel interface only: `read`, `write`, `ioctl` (termios raw mode),
  `fcntl` (non-blocking stdin), `nanosleep` (frame pacing),
  `clock_gettime`, `getrandom`, `openat`/`close`, `exit`
- Static memory throughout: a 30x20 grid, a circular buffer for the
  snake body, no allocator
- The source is `snake.asm`: m4 register aliases and symbol constants,
  expanded by `m4 snake.asm > snake.s` before assembly

## Build targets

```bash
make            # m4 + as + ld (native arm64)
make gcc        # gcc -nostdlib -static instead of as/ld
make qemu-run   # cross-build and run under qemu-aarch64
make clean      # remove snake, snake.s, snake.o
```

## Files

```
snake.asm            the game
Makefile             build targets above
file.txt             high scores, one LEVELn: line per mode
QEMU_SETUP_GUIDE.md  x86_64 setup
```

## License

MIT
