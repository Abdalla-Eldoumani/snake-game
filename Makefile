# Makefile for Snake Game (ARMv8 Assembly)
# Target: 64-bit ARM processors (Raspberry Pi 3/4, Apple Silicon under Linux)

TARGET = snake
SOURCE = snake.s

# Default target
all: $(TARGET)

# Build the executable
$(TARGET): $(SOURCE)
	@echo "Assembling and linking $(TARGET)..."
	as -o $(TARGET).o $(SOURCE)
	ld -o $(TARGET) $(TARGET).o
	@echo "Build complete! Run with: ./$(TARGET)"

# Alternative build using gcc (recommended for better compatibility)
gcc: $(SOURCE)
	@echo "Building with GCC..."
	gcc -nostdlib -static $(SOURCE) -o $(TARGET)
	@echo "Build complete! Run with: ./$(TARGET)"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -f $(TARGET) $(TARGET).o
	@echo "Clean complete."

# Install (copy to /usr/local/bin)
install: $(TARGET)
	@echo "Installing $(TARGET) to /usr/local/bin..."
	sudo cp $(TARGET) /usr/local/bin/
	@echo "Installation complete."

# Uninstall
uninstall:
	@echo "Removing $(TARGET) from /usr/local/bin..."
	sudo rm -f /usr/local/bin/$(TARGET)
	@echo "Uninstallation complete."

# Run the game
run: $(TARGET)
	./$(TARGET)

# Debug build with symbols
debug: $(SOURCE)
	@echo "Building debug version..."
	as -g -o $(TARGET).o $(SOURCE)
	ld -o $(TARGET) $(TARGET).o
	@echo "Debug build complete."

# Check if we're on ARM64
check-arch:
	@echo "Current architecture: $$(uname -m)"
	@if [ "$$(uname -m)" = "aarch64" ]; then \
		echo "✓ ARM64 architecture detected - ready to build!"; \
	else \
		echo "⚠ Warning: Not on ARM64 architecture. This game requires ARMv8 (AArch64)."; \
		echo "  Supported platforms: Raspberry Pi 3/4, Apple Silicon under Linux"; \
	fi

# Help
help:
	@echo "Snake Game Build System"
	@echo "======================"
	@echo ""
	@echo "Available targets:"
	@echo "  all        - Build the game (default)"
	@echo "  gcc        - Build using GCC (recommended)"
	@echo "  clean      - Remove build artifacts"
	@echo "  run        - Build and run the game"
	@echo "  install    - Install to /usr/local/bin"
	@echo "  uninstall  - Remove from /usr/local/bin"
	@echo "  debug      - Build with debug symbols"
	@echo "  check-arch - Check if running on ARM64"
	@echo "  help       - Show this help message"
	@echo ""
	@echo "Requirements:"
	@echo "  - ARMv8 (AArch64) Linux system"
	@echo "  - GNU Assembler (as) and Linker (ld)"
	@echo "  - Terminal with ANSI escape sequence support"

.PHONY: all gcc clean install uninstall run debug check-arch help