# Snake Game in ARMv8 (AArch64) Assembly for Linux
# Target: 64-bit ARM processors

.text
.global _start

# System call numbers for ARMv8 Linux
.equ SYS_READ, 63
.equ SYS_WRITE, 64
.equ SYS_EXIT, 93
.equ SYS_NANOSLEEP, 101
.equ SYS_IOCTL, 29
.equ SYS_GETRANDOM, 278
.equ SYS_FCNTL, 25

# Standard file descriptors
.equ STDIN_FILENO, 0
.equ STDOUT_FILENO, 1
.equ STDERR_FILENO, 2

# Terminal control constants
.equ TCGETS, 0x5401
.equ TCSETS, 0x5402
.equ ICANON, 0x0002
.equ ECHO, 0x0008
.equ F_GETFL, 3
.equ F_SETFL, 4
.equ O_NONBLOCK, 0x800

# Game constants
.equ GRID_WIDTH, 30
.equ GRID_HEIGHT, 20
.equ MAX_SNAKE_LENGTH, 600
.equ INITIAL_SNAKE_LENGTH, 3

# Direction constants
.equ DIR_UP, 0
.equ DIR_RIGHT, 1
.equ DIR_DOWN, 2
.equ DIR_LEFT, 3

# Cell types
.equ CELL_EMPTY, 0
.equ CELL_SNAKE, 1
.equ CELL_FOOD, 2
.equ CELL_WALL, 3

_start:
    # Set up stack frame
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    # Save original terminal settings
    bl      save_terminal_settings
    cmp     x0, #0
    b.ne    exit_error
    
    # Set raw mode
    bl      set_raw_mode
    cmp     x0, #0
    b.ne    restore_and_exit
    
    # Set non-blocking input
    bl      set_nonblocking_input
    cmp     x0, #0
    b.ne    restore_and_exit
    
    # Initialize game
    bl      init_game
    
    # Clear screen and hide cursor
    bl      clear_screen
    bl      hide_cursor
    
    # Main game loop
game_loop:
    # Handle input
    bl      handle_input
    
    # Check if quit was pressed
    adr     x0, quit_flag
    ldr     w1, [x0]
    cmp     w1, #1
    b.eq    game_over
    
    # Move snake
    bl      move_snake
    
    # Check collisions
    bl      check_collisions
    cmp     x0, #0
    b.ne    game_over
    
    # Check food consumption
    bl      check_food_collision
    
    # Draw game
    bl      draw_game
    
    # Sleep
    bl      game_sleep
    
    # Continue loop
    b       game_loop

game_over:
    # Show cursor and display game over
    bl      show_cursor
    bl      display_game_over
    
restore_and_exit:
    # Restore terminal settings
    bl      restore_terminal_settings
    
    # Normal exit
    mov     x0, #0
    b       exit_program
    
exit_error:
    mov     x0, #1
    
exit_program:
    mov     x8, #SYS_EXIT
    svc     #0

# Save original terminal settings
save_terminal_settings:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    mov     x0, #STDIN_FILENO
    mov     x1, #TCGETS
    adr     x2, termios_orig
    mov     x8, #SYS_IOCTL
    svc     #0
    
    ldp     x29, x30, [sp], #16
    ret

# Set terminal to raw mode
set_raw_mode:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    # Copy original settings to raw settings
    adr     x0, termios_orig
    adr     x1, termios_raw
    mov     x2, #60
    bl      memcpy
    
    # Modify c_lflag: disable ICANON and ECHO
    adr     x0, termios_raw
    ldr     w1, [x0, #12]
    mov     w2, #ICANON
    orr     w2, w2, #ECHO
    bic     w1, w1, w2
    str     w1, [x0, #12]
    
    # Set VMIN=1, VTIME=0
    mov     w1, #1
    strb    w1, [x0, #17]
    mov     w1, #0
    strb    w1, [x0, #18]
    
    # Apply settings
    mov     x0, #STDIN_FILENO
    mov     x1, #TCSETS
    adr     x2, termios_raw
    mov     x8, #SYS_IOCTL
    svc     #0
    
    ldp     x29, x30, [sp], #16
    ret

# Set non-blocking input
set_nonblocking_input:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    # Get current flags
    mov     x0, #STDIN_FILENO
    mov     x1, #F_GETFL
    mov     x8, #SYS_FCNTL
    svc     #0
    
    # Add O_NONBLOCK flag
    orr     x2, x0, #O_NONBLOCK
    mov     x0, #STDIN_FILENO
    mov     x1, #F_SETFL
    mov     x8, #SYS_FCNTL
    svc     #0
    
    ldp     x29, x30, [sp], #16
    ret

# Restore terminal settings
restore_terminal_settings:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    mov     x0, #STDIN_FILENO
    mov     x1, #TCSETS
    adr     x2, termios_orig
    mov     x8, #SYS_IOCTL
    svc     #0
    
    ldp     x29, x30, [sp], #16
    ret

# Memory copy function
memcpy:
    cbz     x2, memcpy_done
memcpy_loop:
    ldrb    w3, [x0], #1
    strb    w3, [x1], #1
    subs    x2, x2, #1
    b.ne    memcpy_loop
memcpy_done:
    ret

# Initialize game state
init_game:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    # Initialize grid (all empty)
    adr     x0, game_grid
    mov     x1, #CELL_EMPTY
    mov     x2, #(GRID_WIDTH * GRID_HEIGHT)
    bl      memset
    
    # Initialize snake at center
    adr     x0, snake_length
    mov     w1, #INITIAL_SNAKE_LENGTH
    str     w1, [x0]
    
    adr     x0, snake_head_index
    mov     w1, #0
    str     w1, [x0]
    
    adr     x0, snake_direction
    mov     w1, #DIR_RIGHT
    str     w1, [x0]
    
    # Place initial snake segments
    mov     x0, #(GRID_WIDTH / 2)
    mov     x1, #(GRID_HEIGHT / 2)
    
    # Head
    adr     x2, snake_body
    str     w0, [x2]
    str     w1, [x2, #4]
    
    # Body segments
    sub     w0, w0, #1
    str     w0, [x2, #8]
    str     w1, [x2, #12]
    
    sub     w0, w0, #1
    str     w0, [x2, #16]
    str     w1, [x2, #20]
    
    # Initialize score
    adr     x0, score
    mov     w1, #0
    str     w1, [x0]
    
    # Place first food
    bl      place_food
    
    # Initialize grid with snake and food
    bl      update_grid
    
    # Initialize quit flag
    adr     x0, quit_flag
    mov     w1, #0
    str     w1, [x0]
    
    ldp     x29, x30, [sp], #16
    ret

# Memory set function
memset:
    cbz     x2, memset_done
memset_loop:
    strb    w1, [x0], #1
    subs    x2, x2, #1
    b.ne    memset_loop
memset_done:
    ret


# Handle keyboard input
handle_input:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    # Try to read input
    mov     x0, #STDIN_FILENO
    adr     x1, input_buffer
    mov     x2, #1
    mov     x8, #SYS_READ
    svc     #0
    
    # Check if we got input
    cmp     x0, #1
    b.ne    handle_input_done
    
    # Get the character
    adr     x0, input_buffer
    ldrb    w0, [x0]
    
    # Check for quit
    cmp     w0, #'q'
    b.eq    set_quit_flag
    cmp     w0, #'Q'
    b.eq    set_quit_flag
    
    # Check for direction keys
    cmp     w0, #'w'
    b.eq    set_direction_up
    cmp     w0, #'W'
    b.eq    set_direction_up
    cmp     w0, #'s'
    b.eq    set_direction_down
    cmp     w0, #'S'
    b.eq    set_direction_down
    cmp     w0, #'a'
    b.eq    set_direction_left
    cmp     w0, #'A'
    b.eq    set_direction_left
    cmp     w0, #'d'
    b.eq    set_direction_right
    cmp     w0, #'D'
    b.eq    set_direction_right
    
    # Check for escape sequence (arrow keys)
    cmp     w0, #0x1b
    b.eq    handle_arrow_keys
    
    b       handle_input_done
    
set_quit_flag:
    adr     x0, quit_flag
    mov     w1, #1
    str     w1, [x0]
    b       handle_input_done

set_direction_up:
    adr     x0, snake_direction
    ldr     w1, [x0]
    cmp     w1, #DIR_DOWN
    b.eq    handle_input_done
    mov     w1, #DIR_UP
    str     w1, [x0]
    b       handle_input_done

set_direction_down:
    adr     x0, snake_direction
    ldr     w1, [x0]
    cmp     w1, #DIR_UP
    b.eq    handle_input_done
    mov     w1, #DIR_DOWN
    str     w1, [x0]
    b       handle_input_done

set_direction_left:
    adr     x0, snake_direction
    ldr     w1, [x0]
    cmp     w1, #DIR_RIGHT
    b.eq    handle_input_done
    mov     w1, #DIR_LEFT
    str     w1, [x0]
    b       handle_input_done

set_direction_right:
    adr     x0, snake_direction
    ldr     w1, [x0]
    cmp     w1, #DIR_LEFT
    b.eq    handle_input_done
    mov     w1, #DIR_RIGHT
    str     w1, [x0]
    b       handle_input_done

handle_arrow_keys:
    # Read next two characters of escape sequence
    mov     x0, #STDIN_FILENO
    adr     x1, input_buffer
    mov     x2, #2
    mov     x8, #SYS_READ
    svc     #0
    
    cmp     x0, #2
    b.ne    handle_input_done
    
    adr     x0, input_buffer
    ldrb    w1, [x0]
    cmp     w1, #'['
    b.ne    handle_input_done
    
    ldrb    w1, [x0, #1]
    cmp     w1, #'A'
    b.eq    set_direction_up
    cmp     w1, #'B'
    b.eq    set_direction_down
    cmp     w1, #'C'
    b.eq    set_direction_right
    cmp     w1, #'D'
    b.eq    set_direction_left

handle_input_done:
    ldp     x29, x30, [sp], #16
    ret

# Move snake
move_snake:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    # Get current head position
    adr     x0, snake_head_index
    ldr     w0, [x0]
    adr     x1, snake_body
    mov     w2, #8
    mul     w0, w0, w2
    add     x1, x1, x0
    
    ldr     w2, [x1]
    ldr     w3, [x1, #4]
    
    # Calculate new head position based on direction
    adr     x0, snake_direction
    ldr     w0, [x0]
    
    cmp     w0, #DIR_UP
    b.eq    move_up
    cmp     w0, #DIR_DOWN
    b.eq    move_down
    cmp     w0, #DIR_LEFT
    b.eq    move_left
    cmp     w0, #DIR_RIGHT
    b.eq    move_right
    b       move_snake_done

move_up:
    sub     w3, w3, #1
    b       update_head

move_down:
    add     w3, w3, #1
    b       update_head

move_left:
    sub     w2, w2, #1
    b       update_head

move_right:
    add     w2, w2, #1

update_head:
    # Calculate new head index (circular buffer)
    adr     x0, snake_head_index
    ldr     w1, [x0]
    add     w4, w1, #1
    cmp     w4, #MAX_SNAKE_LENGTH
    csel    w4, wzr, w4, eq
    str     w4, [x0]
    
    # Store new head position
    adr     x0, snake_body
    mov     w5, #8
    mul     x6, x4, x5
    add     x0, x0, x6
    str     w2, [x0]
    str     w3, [x0, #4]
    
move_snake_done:
    ldp     x29, x30, [sp], #16
    ret

# Check collisions with walls and self
check_collisions:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    # Get head position
    adr     x0, snake_head_index
    ldr     w0, [x0]
    adr     x1, snake_body
    mov     w2, #8
    mul     w0, w0, w2
    add     x1, x1, x0
    
    ldr     w2, [x1]
    ldr     w3, [x1, #4]
    
    # Check wall collisions
    cmp     w2, #0
    b.lt    collision_detected
    cmp     w2, #(GRID_WIDTH - 1)
    b.gt    collision_detected
    cmp     w3, #0
    b.lt    collision_detected
    cmp     w3, #(GRID_HEIGHT - 1)
    b.gt    collision_detected
    
    # Check self collision
    mov     w4, #GRID_WIDTH
    mul     w3, w3, w4
    add     w2, w2, w3
    
    adr     x0, game_grid
    ldrb    w1, [x0, x2]
    cmp     w1, #CELL_SNAKE
    b.eq    collision_detected
    
    # No collision
    mov     x0, #0
    ldp     x29, x30, [sp], #16
    ret

collision_detected:
    mov     x0, #1
    ldp     x29, x30, [sp], #16
    ret

# Check food collision and handle growth
check_food_collision:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    # Get head position
    adr     x0, snake_head_index
    ldr     w0, [x0]
    adr     x1, snake_body
    mov     w2, #8
    mul     w0, w0, w2
    add     x1, x1, x0
    
    ldr     w2, [x1]
    ldr     w3, [x1, #4]
    
    # Check if head is on food
    adr     x0, food_position
    ldr     w4, [x0]
    ldr     w5, [x0, #4]
    
    cmp     w2, w4
    b.ne    no_food_collision
    cmp     w3, w5
    b.ne    no_food_collision
    
    # Food eaten - grow snake and increase score
    adr     x0, snake_length
    ldr     w1, [x0]
    add     w1, w1, #1
    str     w1, [x0]
    
    adr     x0, score
    ldr     w1, [x0]
    add     w1, w1, #10
    str     w1, [x0]
    
    # Place new food
    bl      place_food
    
no_food_collision:
    # Update grid with new snake position
    bl      update_grid
    
    ldp     x29, x30, [sp], #16
    ret

# Place food randomly on grid
place_food:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
place_food_loop:
    # Get random numbers for x and y
    adr     x0, random_buffer
    mov     x1, #2
    mov     x2, #0
    mov     x8, #SYS_GETRANDOM
    svc     #0
    
    # Convert to grid coordinates
    adr     x0, random_buffer
    ldrb    w1, [x0]
    mov     w2, #GRID_WIDTH
    udiv    w3, w1, w2
    mul     w3, w3, w2
    sub     w1, w1, w3
    
    ldrb    w4, [x0, #1]
    mov     w2, #GRID_HEIGHT
    udiv    w5, w4, w2
    mul     w5, w5, w2
    sub     w4, w4, w5
    
    # Check if position is empty
    mov     w2, #GRID_WIDTH
    mul     w4, w4, w2
    add     w1, w1, w4
    
    adr     x0, game_grid
    ldrb    w2, [x0, x1]
    cmp     w2, #CELL_EMPTY
    b.ne    place_food_loop
    
    # Place food
    mov     w2, #CELL_FOOD
    strb    w2, [x0, x1]
    
    # Store food position
    mov     w2, #GRID_WIDTH
    udiv    w4, w1, w2
    mul     w5, w4, w2
    sub     w3, w1, w5
    
    adr     x0, food_position
    str     w3, [x0]
    str     w4, [x0, #4]
    
    ldp     x29, x30, [sp], #16
    ret

# Update grid with current snake position
update_grid:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    # Clear entire grid first
    adr     x0, game_grid
    mov     x1, #CELL_EMPTY
    mov     x2, #(GRID_WIDTH * GRID_HEIGHT)
    bl      memset
    
    # Place all snake segments
    adr     x19, snake_length
    ldr     w19, [x19]
    adr     x20, snake_head_index
    ldr     w20, [x20]
    adr     x21, snake_body
    
    mov     w22, #0
    
place_snake_segments:
    cmp     w22, w19
    b.ge    snake_placed
    
    # Calculate segment index (head - counter, with wraparound)
    sub     w23, w20, w22
    cmp     w23, #0
    b.ge    index_positive
    add     w23, w23, #MAX_SNAKE_LENGTH
    
index_positive:
    # Get segment position
    mov     w24, #8
    mul     w23, w23, w24
    add     x23, x21, x23
    
    ldr     w24, [x23]
    ldr     w25, [x23, #4]
    
    # Calculate grid position
    mov     w26, #GRID_WIDTH
    mul     w25, w25, w26
    add     w24, w24, w25
    
    # Place snake segment on grid
    adr     x26, game_grid
    mov     w27, #CELL_SNAKE
    strb    w27, [x26, x24]
    
    add     w22, w22, #1
    b       place_snake_segments
    
snake_placed:
    # Place food
    adr     x0, food_position
    ldr     w1, [x0]
    ldr     w2, [x0, #4]
    
    mov     w3, #GRID_WIDTH
    mul     w2, w2, w3
    add     w1, w1, w2
    
    adr     x0, game_grid
    mov     w3, #CELL_FOOD
    strb    w3, [x0, x1]
    
    ldp     x29, x30, [sp], #16
    ret

# Clear screen
clear_screen:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    mov     x0, #STDOUT_FILENO
    adr     x1, clear_screen_seq
    mov     x2, clear_screen_seq_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    ldp     x29, x30, [sp], #16
    ret

# Hide cursor
hide_cursor:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    mov     x0, #STDOUT_FILENO
    adr     x1, hide_cursor_seq
    mov     x2, hide_cursor_seq_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    ldp     x29, x30, [sp], #16
    ret

# Show cursor
show_cursor:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    mov     x0, #STDOUT_FILENO
    adr     x1, show_cursor_seq
    mov     x2, show_cursor_seq_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    ldp     x29, x30, [sp], #16
    ret

# Draw the game
draw_game:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    # Move cursor to top
    mov     x0, #STDOUT_FILENO
    adr     x1, move_cursor_home
    mov     x2, move_cursor_home_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    # Draw title and score
    bl      draw_header
    
    # Draw top border
    bl      draw_horizontal_border
    
    # Draw game grid
    mov     w19, #0
    
draw_grid_loop:
    cmp     w19, #GRID_HEIGHT
    b.ge    draw_grid_done
    
    # Draw left border
    mov     x0, #STDOUT_FILENO
    adr     x1, vertical_border
    mov     x2, #1
    mov     x8, #SYS_WRITE
    svc     #0
    
    # Draw row
    mov     w20, #0
    
draw_row_loop:
    cmp     w20, #GRID_WIDTH
    b.ge    draw_row_done
    
    # Get cell value
    mov     w0, #GRID_WIDTH
    mul     w1, w19, w0
    add     w1, w1, w20
    
    adr     x0, game_grid
    ldrb    w2, [x0, x1]
    
    # Draw cell based on type
    cmp     w2, #CELL_SNAKE
    b.eq    draw_snake_cell
    cmp     w2, #CELL_FOOD
    b.eq    draw_food_cell
    
    # Empty cell
    mov     x0, #STDOUT_FILENO
    adr     x1, empty_cell
    mov     x2, #1
    mov     x8, #SYS_WRITE
    svc     #0
    b       draw_cell_done

draw_snake_cell:
    mov     x0, #STDOUT_FILENO
    adr     x1, snake_cell
    mov     x2, snake_cell_len
    mov     x8, #SYS_WRITE
    svc     #0
    b       draw_cell_done

draw_food_cell:
    mov     x0, #STDOUT_FILENO
    adr     x1, food_cell
    mov     x2, food_cell_len
    mov     x8, #SYS_WRITE
    svc     #0

draw_cell_done:
    add     w20, w20, #1
    b       draw_row_loop

draw_row_done:
    # Draw right border and newline
    mov     x0, #STDOUT_FILENO
    adr     x1, vertical_border_newline
    mov     x2, #2
    mov     x8, #SYS_WRITE
    svc     #0
    
    add     w19, w19, #1
    b       draw_grid_loop

draw_grid_done:
    # Draw bottom border
    bl      draw_horizontal_border
    
    # Draw controls
    mov     x0, #STDOUT_FILENO
    adr     x1, controls_text
    mov     x2, controls_text_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    ldp     x29, x30, [sp], #16
    ret

# Draw header with score
draw_header:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    # Draw title
    mov     x0, #STDOUT_FILENO
    adr     x1, game_title
    mov     x2, game_title_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    # Draw score
    mov     x0, #STDOUT_FILENO
    adr     x1, score_text
    mov     x2, score_text_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    # Convert score to string and display
    adr     x0, score
    ldr     w0, [x0]
    adr     x1, score_buffer
    bl      int_to_string
    
    mov     x2, x0          # Save string length
    mov     x0, #STDOUT_FILENO
    adr     x1, score_buffer
    mov     x8, #SYS_WRITE
    svc     #0
    
    # Newline
    mov     x0, #STDOUT_FILENO
    adr     x1, newline
    mov     x2, #1
    mov     x8, #SYS_WRITE
    svc     #0
    
    ldp     x29, x30, [sp], #16
    ret

# Draw horizontal border
draw_horizontal_border:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    # Corner
    mov     x0, #STDOUT_FILENO
    adr     x1, corner_char
    mov     x2, #1
    mov     x8, #SYS_WRITE
    svc     #0
    
    # Horizontal line
    mov     w19, #0
border_loop:
    cmp     w19, #GRID_WIDTH
    b.ge    border_done
    
    mov     x0, #STDOUT_FILENO
    adr     x1, horizontal_border
    mov     x2, #1
    mov     x8, #SYS_WRITE
    svc     #0
    
    add     w19, w19, #1
    b       border_loop

border_done:
    # Corner and newline
    mov     x0, #STDOUT_FILENO
    adr     x1, corner_newline
    mov     x2, #2
    mov     x8, #SYS_WRITE
    svc     #0
    
    ldp     x29, x30, [sp], #16
    ret

# Convert integer to string
int_to_string:
    # x0 = number, x1 = buffer, returns length in x0
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    mov     x2, x1
    cbz     x0, zero_case
    
    # Handle negative numbers
    mov     x3, #0
    cmp     x0, #0
    b.ge    positive_number
    
    mov     w4, #'-'
    strb    w4, [x1], #1
    neg     x0, x0
    add     x3, x3, #1

positive_number:
    mov     x4, x1
    
convert_loop:
    mov     x5, #10
    udiv    x6, x0, x5
    mul     x7, x6, x5
    sub     x5, x0, x7
    add     w5, w5, #'0'
    strb    w5, [x1], #1
    add     x3, x3, #1
    mov     x0, x6
    cbnz    x0, convert_loop
    
    # Reverse the digits
    sub     x1, x1, #1
reverse_loop:
    cmp     x4, x1
    b.ge    reverse_done
    
    ldrb    w5, [x4]
    ldrb    w6, [x1]
    strb    w6, [x4], #1
    strb    w5, [x1], #-1
    b       reverse_loop

reverse_done:
    mov     x0, x3
    ldp     x29, x30, [sp], #16
    ret

zero_case:
    mov     w4, #'0'
    strb    w4, [x1]
    mov     x0, #1
    ldp     x29, x30, [sp], #16
    ret

# Display game over message
display_game_over:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    mov     x0, #STDOUT_FILENO
    adr     x1, game_over_text
    mov     x2, game_over_text_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    # Display final score
    mov     x0, #STDOUT_FILENO
    adr     x1, final_score_text
    mov     x2, final_score_text_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    adr     x0, score
    ldr     w0, [x0]
    adr     x1, score_buffer
    bl      int_to_string
    
    mov     x2, x0          # Save string length
    mov     x0, #STDOUT_FILENO
    adr     x1, score_buffer
    mov     x8, #SYS_WRITE
    svc     #0
    
    mov     x0, #STDOUT_FILENO
    adr     x1, newline
    mov     x2, #1
    mov     x8, #SYS_WRITE
    svc     #0
    
    ldp     x29, x30, [sp], #16
    ret

# Game sleep function
game_sleep:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    adr     x0, sleep_time
    mov     x1, #0
    mov     x8, #SYS_NANOSLEEP
    svc     #0
    
    ldp     x29, x30, [sp], #16
    ret

.data
.align 3

# Terminal settings
termios_orig:   .space 60
termios_raw:    .space 60

# Game state
game_grid:      .space (GRID_WIDTH * GRID_HEIGHT)
snake_body:     .space (MAX_SNAKE_LENGTH * 8)
snake_length:   .word INITIAL_SNAKE_LENGTH
snake_head_index: .word 0
snake_direction: .word DIR_RIGHT
food_position:  .space 8
score:          .word 0
quit_flag:      .word 0

# Input/output buffers
input_buffer:   .space 4
random_buffer:  .space 2
score_buffer:   .space 12

# Sleep timing
sleep_time:
    .quad 0
    .quad 200000000

# ANSI escape sequences
clear_screen_seq: .ascii "\x1b[2J"
clear_screen_seq_len = . - clear_screen_seq

hide_cursor_seq: .ascii "\x1b[?25l"
hide_cursor_seq_len = . - hide_cursor_seq

show_cursor_seq: .ascii "\x1b[?25h"
show_cursor_seq_len = . - show_cursor_seq

move_cursor_home: .ascii "\x1b[1;1H"
move_cursor_home_len = . - move_cursor_home

# Game display characters
snake_cell: .ascii "\x1b[42m \x1b[0m"
snake_cell_len = . - snake_cell

food_cell: .ascii "\x1b[41m*\x1b[0m"
food_cell_len = . - food_cell

empty_cell: .ascii " "
vertical_border: .ascii "|"
horizontal_border: .ascii "-"
corner_char: .ascii "+"
vertical_border_newline: .ascii "|\n"
corner_newline: .ascii "+\n"
newline: .ascii "\n"

# Game text
game_title: .ascii "=== SNAKE GAME ===\n"
game_title_len = . - game_title

score_text: .ascii "Score: "
score_text_len = . - score_text

controls_text: .ascii "Controls: WASD or Arrow Keys to move, Q to quit\n"
controls_text_len = . - controls_text

game_over_text: .ascii "\n=== GAME OVER ===\n"
game_over_text_len = . - game_over_text

final_score_text: .ascii "Final Score: "
final_score_text_len = . - final_score_text
