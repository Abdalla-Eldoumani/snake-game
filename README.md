# snake

Turn-based snake for the terminal, written in ARMv8 (AArch64) assembly in
the style taught in CPSC 355 at the University of Calgary: m4 register
aliases, AAPCS64 frame-pointer prologues, libc for console I/O, and raw
Linux syscalls for the score file.

The game is turn-based on purpose. Instead of racing a clock, you type a
line of moves and watch them play out frame by frame. That trade makes the
game run anywhere a terminal runs, including the console of the
[AArch64 Playground](https://aarch64-playground.vercel.app), which has no
raw terminal mode.

```
 score 20 | len 5 | lives 3 | classic | moves 18
 +--------------------+
 |                    |
 |          *         |
 |                    |
 |    @               |
 |    o               |
 |    oo              |
 |                    |
 +--------------------+
```

## play it in the browser

Open the [playground](https://aarch64-playground.vercel.app/playground),
paste `snake.asm` into the editor, assemble, and run. When the program
pauses for input, type a line of moves into the console and press run to
continue. No install, no toolchain.

## build it on linux

On an arm64 machine (Raspberry Pi, Apple Silicon VM, a university ARM
server):

```bash
m4 snake.asm > snake.s
gcc -static snake.s -o snake
./snake
```

On x86_64, cross-build and run under QEMU:

```bash
sudo apt install m4 gcc-aarch64-linux-gnu qemu-user
m4 snake.asm > snake.s
aarch64-linux-gnu-gcc -static snake.s -o snake
qemu-aarch64 ./snake
```

`make` wraps the native build, `make qemu-run` the QEMU one. A prebuilt
static binary is attached to each release, so you can also skip the
toolchain entirely and just `qemu-aarch64 ./snake`.

## how to play

Pick a mode from the menu (1-4). Each turn, type moves and press enter:

| input   | effect                                    |
|---------|-------------------------------------------|
| `w a s d` | one step up / left / down / right       |
| `dddww` | a whole route, one frame per step          |
| `5d`    | repeat a move: five steps right            |
| enter   | a blank line steps ahead once              |
| `q`     | end the game                               |

The snake cannot reverse into its own neck, and moves after a death in
the same line are dropped.

**Modes.** classic ends a life on the walls, endless wraps around the
edges, sprint moves two cells per step, maze adds eight obstacles.

**Food.** `*` is worth 10, the golden `$` is worth 50, and the rare `~`
shrink pickup trims three segments off your tail.

**Lives.** You get three. A collision resets the snake to the center but
keeps your score.

**High scores.** The best score per mode is kept in `scores.txt` next to
the binary, written with raw `openat`/`write`/`close` syscalls.

**Seed.** The same run plays out the same way every time. Pass a number
argument (`./snake 1234`, or the args field in the playground) for a
different food layout.

## files

```
snake.asm   the game, one m4-preprocessed assembly file
Makefile    m4 + gcc pipeline (native, cross, qemu)
```

`m4 snake.asm > snake.s` produces the plain GAS file the assembler
consumes; `snake.s` is generated output and stays out of version control.

## license

MIT
