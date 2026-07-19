# Running the ARM64 Snake Game on x86_64

The game is an AArch64 binary. On an Intel/AMD machine, QEMU user-mode
emulation runs it transparently; check with `uname -m` first --
`aarch64` means you can skip this guide and just `make run`.

## Setup and run

```bash
sudo apt update
sudo apt install -y m4 qemu-user qemu-user-static gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu
make qemu-run
```

`make qemu-run` expands the m4 macros, cross-assembles, links, and
launches under `qemu-aarch64`. The manual equivalent:

```bash
m4 snake.asm > snake.s
aarch64-linux-gnu-as -o snake.o snake.s
aarch64-linux-gnu-ld -o snake snake.o
qemu-aarch64 ./snake
```

Everything -- colors, timing, input, scoring -- behaves the same under
emulation.

## Fixes

- `command not found: qemu-aarch64` -- `sudo apt install qemu-user qemu-user-static`
- `command not found: aarch64-linux-gnu-as` -- `sudo apt install binutils-aarch64-linux-gnu`
- Terminal left in a broken state after a crash -- run `reset`
- High scores all 0 -- run the game from the directory that holds `file.txt`
- On WSL, `C:\Users\You\snake-game` lives at `/mnt/c/Users/You/snake-game`

## Verify a build

```bash
file snake        # ELF 64-bit ... ARM aarch64
qemu-aarch64 --version
```
