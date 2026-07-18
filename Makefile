# builds snake.asm through the course pipeline: m4, then gcc.
# native targets expect an arm64 linux box; qemu-run cross-builds
# and runs under qemu on x86_64.

TARGET = snake
SOURCE = snake.asm

all: $(TARGET)

$(TARGET).s: $(SOURCE)
	m4 $(SOURCE) > $(TARGET).s

$(TARGET): $(TARGET).s
	gcc -static $(TARGET).s -o $(TARGET)

run: $(TARGET)
	./$(TARGET)

cross: $(TARGET).s
	aarch64-linux-gnu-gcc -static $(TARGET).s -o $(TARGET)

qemu-run: cross
	qemu-aarch64 ./$(TARGET)

clean:
	rm -f $(TARGET) $(TARGET).s $(TARGET).o

.PHONY: all run cross qemu-run clean
