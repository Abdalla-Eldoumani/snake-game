// Snake Game in ARMv8 (AArch64) Assembly for Linux
// Target: 64-bit ARM processors

.text
.global _start

// System call numbers for ARMv8 Linux
.equ SYS_READ, 63
.equ SYS_WRITE, 64
.equ SYS_EXIT, 93
.equ SYS_NANOSLEEP, 101
.equ SYS_IOCTL, 29
.equ SYS_GETRANDOM, 278
.equ SYS_FCNTL, 25
.equ SYS_CLOCK_GETTIME, 113
.equ SYS_OPENAT, 56
.equ SYS_CLOSE, 57
.equ AT_FDCWD, -100
.equ CLOCK_MONOTONIC, 1

// File open flags  
.equ O_RDONLY, 0
.equ O_WRONLY, 1
.equ O_CREAT, 64
.equ O_TRUNC, 512

// Standard file descriptors
.equ STDIN_FILENO, 0
.equ STDOUT_FILENO, 1
.equ STDERR_FILENO, 2

// Terminal control constants
.equ TCGETS, 0x5401
.equ TCSETS, 0x5402
.equ ICANON, 0x0002
.equ ECHO, 0x0008
.equ F_GETFL, 3
.equ F_SETFL, 4
.equ O_NONBLOCK, 0x800

// Game constants
.equ GRID_WIDTH, 30
.equ GRID_HEIGHT, 20
.equ MAX_SNAKE_LENGTH, 600
.equ INITIAL_SNAKE_LENGTH, 3

// Level constants
.equ LEVEL_NORMAL, 1
.equ LEVEL_NO_WALLS, 2
.equ LEVEL_SUPER_FAST, 3

// Direction constants
.equ DIR_UP, 0
.equ DIR_RIGHT, 1
.equ DIR_DOWN, 2
.equ DIR_LEFT, 3

// Cell types
.equ CELL_EMPTY, 0
.equ CELL_SNAKE, 1
.equ CELL_FOOD, 2
.equ CELL_WALL, 3

// Food types
.equ FOOD_NORMAL, 0
.equ FOOD_GOLDEN, 1

_start:
    // Set up stack frame
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Save original terminal settings
    bl      save_terminal_settings
    cmp     x0, #0
    b.ne    exit_error
    
    // Set raw mode
    bl      set_raw_mode
    cmp     x0, #0
    b.ne    restore_and_exit
    
    // Set non-blocking input
    bl      set_nonblocking_input
    cmp     x0, #0
    b.ne    restore_and_exit
    
    // Show welcome screen and get level selection
    bl      show_welcome_screen
    bl      get_level_selection
    
    // Initialize game with selected level
    bl      init_game
    
    // Clear screen and hide cursor
    bl      clear_screen
    bl      hide_cursor
    
    // Main game loop
game_loop:
    // Handle input
    bl      handle_input
    
    // Check if quit was pressed
    adr     x0, quit_flag
    ldr     w1, [x0]
    cmp     w1, #1
    b.eq    game_over
    
    // Check if game is paused
    adr     x0, game_paused
    ldr     w1, [x0]
    cmp     w1, #1
    b.eq    pause_loop
    
    // Move snake
    bl      move_snake
    
    // Check collisions
    bl      check_collisions
    cmp     x0, #0
    b.ne    game_over
    
    // Check food consumption
    bl      check_food_collision
    
    // Draw game
    bl      draw_game
    
    // Sleep
    bl      game_sleep
    
    // Continue loop
    b       game_loop

pause_loop:
    // Display pause message
    bl      draw_game
    bl      display_pause_message
    
    // Sleep briefly and continue checking input
    bl      game_sleep
    b       game_loop

game_over:
    // Show cursor and display game over
    bl      show_cursor
    bl      display_game_over
    
restore_and_exit:
    // Restore terminal settings
    bl      restore_terminal_settings
    
    // Normal exit
    mov     x0, #0
    b       exit_program
    
exit_error:
    mov     x0, #1
    
exit_program:
    mov     x8, #SYS_EXIT
    svc     #0

// Show welcome screen
show_welcome_screen:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Clear screen
    bl      clear_screen
    
    // Display welcome title
    mov     x0, #STDOUT_FILENO
    adr     x1, welcome_title
    mov     x2, welcome_title_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    // Display level selection text
    mov     x0, #STDOUT_FILENO
    adr     x1, level_select_text
    mov     x2, level_select_text_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    ldp     x29, x30, [sp], #16
    ret

// Get level selection from user
get_level_selection:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Initialize selected level to 1
    adr     x0, current_level
    mov     w1, #LEVEL_NORMAL
    str     w1, [x0]
    
level_selection_loop:
    // Clear any remaining input
    bl      clear_input_buffer
    
    // Display level options with current selection indicator
    bl      display_level_options
    
    // Get user input
    bl      get_level_input
    
    // Check if selection is confirmed (ENTER pressed)
    adr     x0, quit_flag
    ldr     w1, [x0]
    cmp     w1, #2  // Use 2 as confirmation flag
    b.eq    level_selection_done
    
    b       level_selection_loop

level_selection_done:
    // Reset quit flag for game
    adr     x0, quit_flag
    mov     w1, #0
    str     w1, [x0]
    
    ldp     x29, x30, [sp], #16
    ret

// Display level options with selection indicator
display_level_options:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Get current level
    adr     x0, current_level
    ldr     w19, [x0]
    
    // Display Level 1
    cmp     w19, #LEVEL_NORMAL
    b.ne    display_level_1_normal
    
    // Show indicator for Level 1
    mov     x0, #STDOUT_FILENO
    adr     x1, level_indicator
    mov     x2, level_indicator_len
    mov     x8, #SYS_WRITE
    svc     #0
    b       display_level_1_text

display_level_1_normal:
    mov     x0, #STDOUT_FILENO
    adr     x1, clear_line
    mov     x2, #3  // Just 3 spaces
    mov     x8, #SYS_WRITE
    svc     #0

display_level_1_text:
    mov     x0, #STDOUT_FILENO
    adr     x1, level_1_text
    mov     x2, level_1_text_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    // Display Level 2
    cmp     w19, #LEVEL_NO_WALLS
    b.ne    display_level_2_normal
    
    mov     x0, #STDOUT_FILENO
    adr     x1, level_indicator
    mov     x2, level_indicator_len
    mov     x8, #SYS_WRITE
    svc     #0
    b       display_level_2_text

display_level_2_normal:
    mov     x0, #STDOUT_FILENO
    adr     x1, clear_line
    mov     x2, #3
    mov     x8, #SYS_WRITE
    svc     #0

display_level_2_text:
    mov     x0, #STDOUT_FILENO
    adr     x1, level_2_text
    mov     x2, level_2_text_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    // Display Level 3
    cmp     w19, #LEVEL_SUPER_FAST
    b.ne    display_level_3_normal
    
    mov     x0, #STDOUT_FILENO
    adr     x1, level_indicator
    mov     x2, level_indicator_len
    mov     x8, #SYS_WRITE
    svc     #0
    b       display_level_3_text

display_level_3_normal:
    mov     x0, #STDOUT_FILENO
    adr     x1, clear_line
    mov     x2, #3
    mov     x8, #SYS_WRITE
    svc     #0

display_level_3_text:
    mov     x0, #STDOUT_FILENO
    adr     x1, level_3_text
    mov     x2, level_3_text_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    // Display prompt
    mov     x0, #STDOUT_FILENO
    adr     x1, level_select_prompt
    mov     x2, level_select_prompt_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    ldp     x29, x30, [sp], #16
    ret

// Get level selection input
get_level_input:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
wait_for_input:
    // Try to read input
    mov     x0, #STDIN_FILENO
    adr     x1, input_buffer
    mov     x2, #1
    mov     x8, #SYS_READ
    svc     #0
    
    // Check if we got input
    cmp     x0, #1
    b.ne    wait_for_input
    
    // Get the character
    adr     x0, input_buffer
    ldrb    w0, [x0]
    
    // Check for confirmation (ENTER)
    cmp     w0, #10
    b.eq    confirm_selection
    cmp     w0, #13
    b.eq    confirm_selection
    
    // Check for up/down movement
    cmp     w0, #'w'
    b.eq    move_selection_up
    cmp     w0, #'W'
    b.eq    move_selection_up
    cmp     w0, #'s'
    b.eq    move_selection_down
    cmp     w0, #'S'
    b.eq    move_selection_down
    
    // Check for escape sequence (arrow keys)
    cmp     w0, #0x1b
    b.eq    handle_level_arrow_keys
    
    b       get_level_input_done
    
confirm_selection:
    adr     x0, quit_flag
    mov     w1, #2  // Use 2 as confirmation flag
    str     w1, [x0]
    b       get_level_input_done

move_selection_up:
    adr     x0, current_level
    ldr     w1, [x0]
    cmp     w1, #LEVEL_NORMAL
    b.eq    wrap_to_level_3
    sub     w1, w1, #1
    str     w1, [x0]
    b       get_level_input_done

wrap_to_level_3:
    mov     w1, #LEVEL_SUPER_FAST
    str     w1, [x0]
    b       get_level_input_done

move_selection_down:
    adr     x0, current_level
    ldr     w1, [x0]
    cmp     w1, #LEVEL_SUPER_FAST
    b.eq    wrap_to_level_1
    add     w1, w1, #1
    str     w1, [x0]
    b       get_level_input_done

wrap_to_level_1:
    mov     w1, #LEVEL_NORMAL
    str     w1, [x0]
    b       get_level_input_done

handle_level_arrow_keys:
    // Read next two characters of escape sequence
    mov     x0, #STDIN_FILENO
    adr     x1, input_buffer
    mov     x2, #2
    mov     x8, #SYS_READ
    svc     #0
    
    cmp     x0, #2
    b.ne    get_level_input_done
    
    adr     x0, input_buffer
    ldrb    w1, [x0]
    cmp     w1, #'['
    b.ne    get_level_input_done
    
    ldrb    w1, [x0, #1]
    cmp     w1, #'A'  // Up arrow
    b.eq    move_selection_up
    cmp     w1, #'B'  // Down arrow
    b.eq    move_selection_down

get_level_input_done:
    ldp     x29, x30, [sp], #16
    ret

// Clear input buffer
clear_input_buffer:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
clear_buffer_loop:
    mov     x0, #STDIN_FILENO
    adr     x1, input_buffer
    mov     x2, #1
    mov     x8, #SYS_READ
    svc     #0
    
    cmp     x0, #1
    b.eq    clear_buffer_loop
    
    ldp     x29, x30, [sp], #16
    ret

// Save original terminal settings
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

// Set terminal to raw mode
set_raw_mode:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Copy original settings to raw settings
    adr     x0, termios_orig
    adr     x1, termios_raw
    mov     x2, #60
    bl      memcpy
    
    // Modify c_lflag: disable ICANON and ECHO
    adr     x0, termios_raw
    ldr     w1, [x0, #12]
    mov     w2, #ICANON
    orr     w2, w2, #ECHO
    bic     w1, w1, w2
    str     w1, [x0, #12]
    
    // Set VMIN=1, VTIME=0
    mov     w1, #1
    strb    w1, [x0, #17]
    mov     w1, #0
    strb    w1, [x0, #18]
    
    // Apply settings
    mov     x0, #STDIN_FILENO
    mov     x1, #TCSETS
    adr     x2, termios_raw
    mov     x8, #SYS_IOCTL
    svc     #0
    
    ldp     x29, x30, [sp], #16
    ret

// Set non-blocking input
set_nonblocking_input:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Get current flags
    mov     x0, #STDIN_FILENO
    mov     x1, #F_GETFL
    mov     x8, #SYS_FCNTL
    svc     #0
    
    // Add O_NONBLOCK flag
    orr     x2, x0, #O_NONBLOCK
    mov     x0, #STDIN_FILENO
    mov     x1, #F_SETFL
    mov     x8, #SYS_FCNTL
    svc     #0
    
    ldp     x29, x30, [sp], #16
    ret

// Restore terminal settings
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

// Memory copy function
memcpy:
    cbz     x2, memcpy_done
memcpy_loop:
    ldrb    w3, [x0], #1
    strb    w3, [x1], #1
    subs    x2, x2, #1
    b.ne    memcpy_loop
memcpy_done:
    ret

// Initialize game state
init_game:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Initialize grid (all empty)
    adr     x0, game_grid
    mov     x1, #CELL_EMPTY
    mov     x2, #(GRID_WIDTH * GRID_HEIGHT)
    bl      memset
    
    // Initialize snake at center
    adr     x0, snake_length
    mov     w1, #INITIAL_SNAKE_LENGTH
    str     w1, [x0]
    
    adr     x0, snake_head_index
    mov     w1, #0
    str     w1, [x0]
    
    adr     x0, snake_direction
    mov     w1, #DIR_RIGHT
    str     w1, [x0]
    
    // Place initial snake segments
    mov     x0, #(GRID_WIDTH / 2)
    mov     x1, #(GRID_HEIGHT / 2)
    
    // Head
    adr     x2, snake_body
    str     w0, [x2]
    str     w1, [x2, #4]
    
    // Body segments
    sub     w0, w0, #1
    str     w0, [x2, #8]
    str     w1, [x2, #12]
    
    sub     w0, w0, #1
    str     w0, [x2, #16]
    str     w1, [x2, #20]
    
    // Initialize score
    adr     x0, score
    mov     w1, #0
    str     w1, [x0]
    
    // Initialize food count
    adr     x0, food_count
    mov     w1, #0
    str     w1, [x0]
    
    // Initialize pause state
    adr     x0, game_paused
    mov     w1, #0
    str     w1, [x0]
    
    // Record game start time
    bl      get_current_time
    adr     x0, game_start_time
    adr     x1, current_time
    ldp     x2, x3, [x1]
    stp     x2, x3, [x0]
    
    // Initialize total paused time
    adr     x0, total_paused_time
    mov     w1, #0
    str     w1, [x0]
    
    // Load high scores
    bl      load_high_scores
    
    // Place first food
    bl      place_food
    
    // Initialize grid with snake and food
    bl      update_grid
    
    // Initialize quit flag
    adr     x0, quit_flag
    mov     w1, #0
    str     w1, [x0]
    
    ldp     x29, x30, [sp], #16
    ret

// Memory set function
memset:
    cbz     x2, memset_done
memset_loop:
    strb    w1, [x0], #1
    subs    x2, x2, #1
    b.ne    memset_loop
memset_done:
    ret


// Handle keyboard input
handle_input:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Try to read input
    mov     x0, #STDIN_FILENO
    adr     x1, input_buffer
    mov     x2, #1
    mov     x8, #SYS_READ
    svc     #0
    
    // Check if we got input
    cmp     x0, #1
    b.ne    handle_input_done
    
    // Get the character
    adr     x0, input_buffer
    ldrb    w0, [x0]
    
    // Check for quit
    cmp     w0, #'q'
    b.eq    set_quit_flag
    cmp     w0, #'Q'
    b.eq    set_quit_flag
    
    // Check for direction keys
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
    
    // Check for pause (space key)
    cmp     w0, #' '
    b.eq    toggle_pause
    
    // Check for escape sequence (arrow keys)
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
    // Read next two characters of escape sequence
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

toggle_pause:
    adr     x0, game_paused
    ldr     w1, [x0]
    
    // Check if we're currently paused (about to unpause)
    cmp     w1, #1
    b.eq    unpause_game
    
    // Currently unpaused, about to pause - record pause start time
    bl      get_current_time
    adr     x0, pause_start_time
    adr     x1, current_time
    ldp     x2, x3, [x1]
    stp     x2, x3, [x0]
    
    // Set paused state
    adr     x0, game_paused
    mov     w1, #1
    str     w1, [x0]
    b       handle_input_done
    
unpause_game:
    // Currently paused, about to unpause - calculate paused time
    bl      get_current_time
    adr     x0, current_time
    adr     x1, pause_start_time
    ldr     x2, [x0]
    ldr     x3, [x1]
    sub     x2, x2, x3
    
    // Add to total paused time
    adr     x0, total_paused_time
    ldr     w1, [x0]
    add     w1, w1, w2
    str     w1, [x0]
    
    // Set unpaused state
    adr     x0, game_paused
    mov     w1, #0
    str     w1, [x0]
    
    // Clear screen and redraw for clean resume
    bl      clear_screen
    bl      draw_game

handle_input_done:
    ldp     x29, x30, [sp], #16
    ret

// Move snake
move_snake:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Get current head position
    adr     x0, snake_head_index
    ldr     w0, [x0]
    adr     x1, snake_body
    mov     w2, #8
    mul     w0, w0, w2
    add     x1, x1, x0
    
    ldr     w2, [x1]
    ldr     w3, [x1, #4]
    
    // Calculate new head position based on direction
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
    // Calculate new head index (circular buffer)
    adr     x0, snake_head_index
    ldr     w1, [x0]
    add     w4, w1, #1
    cmp     w4, #MAX_SNAKE_LENGTH
    csel    w4, wzr, w4, eq
    str     w4, [x0]
    
    // Store new head position
    adr     x0, snake_body
    mov     w5, #8
    mul     x6, x4, x5
    add     x0, x0, x6
    str     w2, [x0]
    str     w3, [x0, #4]
    
move_snake_done:
    ldp     x29, x30, [sp], #16
    ret

// Check collisions with walls and self
check_collisions:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Get head position
    adr     x0, snake_head_index
    ldr     w0, [x0]
    adr     x1, snake_body
    mov     w2, #8
    mul     w0, w0, w2
    add     x1, x1, x0
    
    ldr     w2, [x1]
    ldr     w3, [x1, #4]
    
    // Check current level for wall collision behavior
    adr     x0, current_level
    ldr     w4, [x0]
    cmp     w4, #LEVEL_NO_WALLS
    b.eq    handle_wall_wrapping
    
    // Normal wall collision detection (Level 1 and 3)
    cmp     w2, #0
    b.lt    collision_detected
    cmp     w2, #(GRID_WIDTH - 1)
    b.gt    collision_detected
    cmp     w3, #0
    b.lt    collision_detected
    cmp     w3, #(GRID_HEIGHT - 1)
    b.gt    collision_detected
    b       check_self_collision

handle_wall_wrapping:
    // Level 2: Wrap around edges instead of collision
    // Wrap X coordinate
    cmp     w2, #0
    b.lt    wrap_x_left
    cmp     w2, #(GRID_WIDTH - 1)
    b.gt    wrap_x_right
    b       check_y_wrap

wrap_x_left:
    mov     w2, #(GRID_WIDTH - 1)
    b       update_wrapped_position

wrap_x_right:
    mov     w2, #0
    b       update_wrapped_position

check_y_wrap:
    // Wrap Y coordinate
    cmp     w3, #0
    b.lt    wrap_y_top
    cmp     w3, #(GRID_HEIGHT - 1)
    b.gt    wrap_y_bottom
    b       check_self_collision

wrap_y_top:
    mov     w3, #(GRID_HEIGHT - 1)
    b       update_wrapped_position

wrap_y_bottom:
    mov     w3, #0

update_wrapped_position:
    // Update the head position with wrapped coordinates
    adr     x0, snake_head_index
    ldr     w0, [x0]
    adr     x1, snake_body
    mov     w4, #8
    mul     w0, w0, w4
    add     x1, x1, x0
    str     w2, [x1]
    str     w3, [x1, #4]

check_self_collision:
    
    // Check self collision
    mov     w4, #GRID_WIDTH
    mul     w3, w3, w4
    add     w2, w2, w3
    
    adr     x0, game_grid
    ldrb    w1, [x0, x2]
    cmp     w1, #CELL_SNAKE
    b.eq    collision_detected
    
    // No collision
    mov     x0, #0
    ldp     x29, x30, [sp], #16
    ret

collision_detected:
    mov     x0, #1
    ldp     x29, x30, [sp], #16
    ret

// Check food collision and handle growth
check_food_collision:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Get head position
    adr     x0, snake_head_index
    ldr     w0, [x0]
    adr     x1, snake_body
    mov     w2, #8
    mul     w0, w0, w2
    add     x1, x1, x0
    
    ldr     w2, [x1]
    ldr     w3, [x1, #4]
    
    // Check if head is on food
    adr     x0, food_position
    ldr     w4, [x0]
    ldr     w5, [x0, #4]
    
    cmp     w2, w4
    b.ne    no_food_collision
    cmp     w3, w5
    b.ne    no_food_collision
    
    // Food eaten - grow snake and increase score
    adr     x0, snake_length
    ldr     w1, [x0]
    add     w1, w1, #1
    str     w1, [x0]
    
    // Check food type for score bonus and sound
    adr     x0, food_type
    ldr     w2, [x0]
    cmp     w2, #FOOD_GOLDEN
    b.eq    golden_food_eaten
    
    // Normal food eaten
    bl      play_food_sound
    mov     w2, #1
    b       add_score
    
golden_food_eaten:
    bl      play_golden_food_sound
    mov     w2, #5
    
add_score:
    adr     x0, score
    ldr     w1, [x0]
    add     w1, w1, w2
    str     w1, [x0]
    
    adr     x0, food_count
    ldr     w1, [x0]
    add     w1, w1, #1
    str     w1, [x0]
    
    // Place new food
    bl      place_food
    
no_food_collision:
    // Update grid with new snake position
    bl      update_grid
    
    ldp     x29, x30, [sp], #16
    ret

// Place food randomly on grid
place_food:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Determine food type (20% chance for golden food)
    adr     x0, random_buffer
    mov     x1, #1
    mov     x2, #0
    mov     x8, #SYS_GETRANDOM
    svc     #0
    
    adr     x0, random_buffer
    ldrb    w1, [x0]
    mov     w2, #5
    udiv    w3, w1, w2
    mul     w3, w3, w2
    sub     w1, w1, w3
    
    // If w1 == 0 (20% chance), make it golden food
    adr     x0, food_type
    cmp     w1, #0
    mov     w2, #FOOD_GOLDEN
    mov     w3, #FOOD_NORMAL
    csel    w1, w2, w3, eq
    str     w1, [x0]
    
place_food_loop:
    // Get random numbers for x and y
    adr     x0, random_buffer
    mov     x1, #2
    mov     x2, #0
    mov     x8, #SYS_GETRANDOM
    svc     #0
    
    // Convert to grid coordinates
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
    
    // Check if position is empty
    mov     w2, #GRID_WIDTH
    mul     w4, w4, w2
    add     w1, w1, w4
    
    adr     x0, game_grid
    ldrb    w2, [x0, x1]
    cmp     w2, #CELL_EMPTY
    b.ne    place_food_loop
    
    // Place food
    mov     w2, #CELL_FOOD
    strb    w2, [x0, x1]
    
    // Store food position
    mov     w2, #GRID_WIDTH
    udiv    w4, w1, w2
    mul     w5, w4, w2
    sub     w3, w1, w5
    
    adr     x0, food_position
    str     w3, [x0]
    str     w4, [x0, #4]
    
    ldp     x29, x30, [sp], #16
    ret

// Update grid with current snake position
update_grid:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Clear entire grid first
    adr     x0, game_grid
    mov     x1, #CELL_EMPTY
    mov     x2, #(GRID_WIDTH * GRID_HEIGHT)
    bl      memset
    
    // Place all snake segments
    adr     x19, snake_length
    ldr     w19, [x19]
    adr     x20, snake_head_index
    ldr     w20, [x20]
    adr     x21, snake_body
    
    mov     w22, #0
    
place_snake_segments:
    cmp     w22, w19
    b.ge    snake_placed
    
    // Calculate segment index (head - counter, with wraparound)
    sub     w23, w20, w22
    cmp     w23, #0
    b.ge    index_positive
    add     w23, w23, #MAX_SNAKE_LENGTH
    
index_positive:
    // Get segment position
    mov     w24, #8
    mul     w23, w23, w24
    add     x23, x21, x23
    
    ldr     w24, [x23]
    ldr     w25, [x23, #4]
    
    // Calculate grid position
    mov     w26, #GRID_WIDTH
    mul     w25, w25, w26
    add     w24, w24, w25
    
    // Place snake segment on grid
    adr     x26, game_grid
    mov     w27, #CELL_SNAKE
    strb    w27, [x26, x24]
    
    add     w22, w22, #1
    b       place_snake_segments
    
snake_placed:
    // Place food
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

// Clear screen
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

// Hide cursor
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

// Show cursor
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

// Draw the game
draw_game:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Move cursor to top
    mov     x0, #STDOUT_FILENO
    adr     x1, move_cursor_home
    mov     x2, move_cursor_home_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    // Draw title and score
    bl      draw_header
    
    // Draw top border
    bl      draw_horizontal_border
    
    // Draw game grid
    mov     w19, #0
    
draw_grid_loop:
    cmp     w19, #GRID_HEIGHT
    b.ge    draw_grid_done
    
    // Draw left border
    mov     x0, #STDOUT_FILENO
    adr     x1, vertical_border
    mov     x2, #1
    mov     x8, #SYS_WRITE
    svc     #0
    
    // Draw row
    mov     w20, #0
    
draw_row_loop:
    cmp     w20, #GRID_WIDTH
    b.ge    draw_row_done
    
    // Get cell value
    mov     w0, #GRID_WIDTH
    mul     w1, w19, w0
    add     w1, w1, w20
    
    adr     x0, game_grid
    ldrb    w2, [x0, x1]
    
    // Draw cell based on type
    cmp     w2, #CELL_SNAKE
    b.eq    draw_snake_cell
    cmp     w2, #CELL_FOOD
    b.eq    draw_food_cell
    
    // Empty cell
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
    // Check food type
    adr     x0, food_type
    ldr     w3, [x0]
    cmp     w3, #FOOD_GOLDEN
    b.eq    draw_golden_food
    
    // Draw normal food
    mov     x0, #STDOUT_FILENO
    adr     x1, food_cell
    mov     x2, food_cell_len
    mov     x8, #SYS_WRITE
    svc     #0
    b       draw_cell_done

draw_golden_food:
    // Draw golden food
    mov     x0, #STDOUT_FILENO
    adr     x1, golden_food_cell
    mov     x2, golden_food_cell_len
    mov     x8, #SYS_WRITE
    svc     #0

draw_cell_done:
    add     w20, w20, #1
    b       draw_row_loop

draw_row_done:
    // Draw right border and newline
    mov     x0, #STDOUT_FILENO
    adr     x1, vertical_border_newline
    mov     x2, #2
    mov     x8, #SYS_WRITE
    svc     #0
    
    add     w19, w19, #1
    b       draw_grid_loop

draw_grid_done:
    // Draw bottom border
    bl      draw_horizontal_border
    
    // Draw controls
    mov     x0, #STDOUT_FILENO
    adr     x1, controls_text
    mov     x2, controls_text_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    ldp     x29, x30, [sp], #16
    ret

// Draw header with score
draw_header:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Draw title
    mov     x0, #STDOUT_FILENO
    adr     x1, game_title
    mov     x2, game_title_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    // Draw score
    mov     x0, #STDOUT_FILENO
    adr     x1, score_text
    mov     x2, score_text_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    // Convert score to string and display
    adr     x0, score
    ldr     w0, [x0]
    adr     x1, score_buffer
    bl      int_to_string
    
    mov     x2, x0
    mov     x0, #STDOUT_FILENO
    adr     x1, score_buffer
    mov     x8, #SYS_WRITE
    svc     #0
    
    // Display current level
    mov     x0, #STDOUT_FILENO
    adr     x1, level_display_text
    mov     x2, level_display_text_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    adr     x0, current_level
    ldr     w0, [x0]
    adr     x1, speed_buffer
    bl      int_to_string
    
    mov     x2, x0
    mov     x0, #STDOUT_FILENO
    adr     x1, speed_buffer
    mov     x8, #SYS_WRITE
    svc     #0
    
    // Display speed level  
    mov     x0, #STDOUT_FILENO
    adr     x1, speed_text
    mov     x2, speed_text_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    bl      calculate_speed_level
    adr     x1, speed_buffer
    bl      int_to_string
    
    mov     x2, x0
    mov     x0, #STDOUT_FILENO
    adr     x1, speed_buffer
    mov     x8, #SYS_WRITE
    svc     #0
    
    // Display time played
    mov     x0, #STDOUT_FILENO
    adr     x1, time_text
    mov     x2, time_text_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    bl      calculate_elapsed_time
    adr     x0, elapsed_seconds
    ldr     w0, [x0]
    adr     x1, time_buffer
    bl      int_to_string
    
    mov     x2, x0
    mov     x0, #STDOUT_FILENO
    adr     x1, time_buffer
    mov     x8, #SYS_WRITE
    svc     #0
    
    // Time unit
    mov     x0, #STDOUT_FILENO
    adr     x1, seconds_text
    mov     x2, seconds_text_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    // Newline
    mov     x0, #STDOUT_FILENO
    adr     x1, newline
    mov     x2, #1
    mov     x8, #SYS_WRITE
    svc     #0
    
    ldp     x29, x30, [sp], #16
    ret

// Draw horizontal border
draw_horizontal_border:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Corner
    mov     x0, #STDOUT_FILENO
    adr     x1, corner_char
    mov     x2, #1
    mov     x8, #SYS_WRITE
    svc     #0
    
    // Horizontal line
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
    // Corner and newline
    mov     x0, #STDOUT_FILENO
    adr     x1, corner_newline
    mov     x2, #2
    mov     x8, #SYS_WRITE
    svc     #0
    
    ldp     x29, x30, [sp], #16
    ret

// Convert integer to string
int_to_string:
    // x0 = number, x1 = buffer, returns length in x0
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    mov     x2, x1
    cbz     x0, zero_case
    
    // Handle negative numbers
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
    
    // Reverse the digits
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

// Display game over message
display_game_over:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Play game over sound
    bl      play_game_over_sound
    
    mov     x0, #STDOUT_FILENO
    adr     x1, game_over_text
    mov     x2, game_over_text_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    // Display final score
    mov     x0, #STDOUT_FILENO
    adr     x1, final_score_text
    mov     x2, final_score_text_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    adr     x0, score
    ldr     w0, [x0]
    adr     x1, score_buffer
    bl      int_to_string
    
    mov     x2, x0
    mov     x0, #STDOUT_FILENO
    adr     x1, score_buffer
    mov     x8, #SYS_WRITE
    svc     #0
    
    // Display newline
    mov     x0, #STDOUT_FILENO
    adr     x1, newline
    mov     x2, #1
    mov     x8, #SYS_WRITE
    svc     #0
    
    // Display food count
    mov     x0, #STDOUT_FILENO
    adr     x1, food_count_text
    mov     x2, food_count_text_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    adr     x0, food_count
    ldr     w0, [x0]
    adr     x1, food_buffer
    bl      int_to_string
    
    mov     x2, x0
    mov     x0, #STDOUT_FILENO
    adr     x1, food_buffer
    mov     x8, #SYS_WRITE
    svc     #0
    
    mov     x0, #STDOUT_FILENO
    adr     x1, newline
    mov     x2, #1
    mov     x8, #SYS_WRITE
    svc     #0
    
    // Check for new records and save high scores
    bl      check_and_update_records
    
    ldp     x29, x30, [sp], #16
    ret

// Display pause message
display_pause_message:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Move cursor to bottom of screen
    mov     x0, #STDOUT_FILENO
    adr     x1, pause_text
    mov     x2, pause_text_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    ldp     x29, x30, [sp], #16
    ret

// Get current time
get_current_time:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    mov     x0, #CLOCK_MONOTONIC
    adr     x1, current_time
    mov     x8, #SYS_CLOCK_GETTIME
    svc     #0
    
    ldp     x29, x30, [sp], #16
    ret

// Calculate elapsed time in seconds
calculate_elapsed_time:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    bl      get_current_time
    
    // Load current time and start time
    adr     x0, current_time
    adr     x1, game_start_time
    ldr     x2, [x0]
    ldr     x3, [x1]
    
    sub     x2, x2, x3
    
    // Subtract total paused time to get actual playing time
    adr     x0, total_paused_time
    ldr     w4, [x0]
    sub     x2, x2, x4
    
    // Store playing seconds (not total elapsed)
    adr     x0, elapsed_seconds
    str     w2, [x0]
    
    ldp     x29, x30, [sp], #16
    ret

// Calculate current speed level (1-10)
calculate_speed_level:
    adr     x0, snake_length
    ldr     w0, [x0]
    
    // Speed level = min(10, 1 + (length-3)/3)
    sub     w0, w0, #INITIAL_SNAKE_LENGTH
    mov     w1, #3
    udiv    w0, w0, w1
    add     w0, w0, #1
    
    mov     w1, #10
    cmp     w0, w1
    csel    w0, w1, w0, gt
    
    ret

// Load high scores from file
load_high_scores:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Try to open file for reading using openat
    mov     x0, #AT_FDCWD
    adr     x1, high_score_file
    mov     x2, #O_RDONLY
    mov     x3, #0
    mov     x8, #SYS_OPENAT
    svc     #0
    
    // If file doesn't exist (negative fd), set file_exists flag to false
    cmp     x0, #0
    b.lt    set_no_file_flag
    
    // Read high score data as text (up to 32 bytes)
    mov     x19, x0
    adr     x1, high_score_buffer
    mov     x2, #32
    mov     x8, #SYS_READ
    svc     #0
    
    // Store bytes read
    mov     x20, x0
    
    // Close file
    mov     x0, x19
    mov     x8, #SYS_CLOSE
    svc     #0
    
    // Check if we read some data
    cmp     x20, #0
    b.le    set_no_file_flag
    
    // Debug: show what we read from file
    mov     x0, #STDOUT_FILENO
    adr     x1, debug_loaded_text
    mov     x2, debug_loaded_text_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    // Show the raw buffer content
    mov     x0, #STDOUT_FILENO
    adr     x1, high_score_buffer
    mov     x2, #10
    mov     x8, #SYS_WRITE
    svc     #0
    
    mov     x0, #STDOUT_FILENO
    adr     x1, newline
    mov     x2, #1
    mov     x8, #SYS_WRITE
    svc     #0
    
    // Parse the text to extract high score
    adr     x0, high_score_buffer
    bl      parse_score_from_text
    
    // Debug: show parsed high score
    mov     x0, #STDOUT_FILENO
    adr     x1, debug_parsed_text
    mov     x2, debug_parsed_text_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    adr     x0, high_score
    ldr     w0, [x0]
    adr     x1, speed_buffer
    bl      int_to_string
    mov     x0, #STDOUT_FILENO
    adr     x1, speed_buffer
    mov     x2, #10
    mov     x8, #SYS_WRITE
    svc     #0
    
    mov     x0, #STDOUT_FILENO
    adr     x1, newline
    mov     x2, #1
    mov     x8, #SYS_WRITE
    svc     #0
    
    // Set file exists flag to true
    adr     x0, file_exists
    mov     w1, #1
    str     w1, [x0]
    b       load_high_scores_done


set_no_file_flag:
    // Mark that no high score file exists yet
    adr     x0, file_exists
    str     wzr, [x0]
    
    // Initialize high score to 0
    adr     x0, high_score
    str     wzr, [x0]

load_high_scores_done:
    ldp     x29, x30, [sp], #16
    ret

// Save high scores to file
save_high_scores:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Debug: Show what score we're saving (commented out)
    // mov     x0, #STDOUT_FILENO
    // adr     x1, debug_score_text
    // mov     x2, debug_score_text_len
    // mov     x8, #SYS_WRITE
    // svc     #0
    
    // Convert high score to text first
    adr     x0, high_score
    ldr     w0, [x0]
    adr     x1, high_score_buffer
    bl      int_to_string
    
    // Display the score we're saving (commented out)
    // mov     x0, #STDOUT_FILENO
    // adr     x1, high_score_buffer
    // mov     x2, #10
    // mov     x8, #SYS_WRITE
    // svc     #0
    
    // Add newline
    adr     x0, high_score_buffer
    mov     x1, x0
find_end:
    ldrb    w2, [x1]
    cbz     w2, add_newline
    add     x1, x1, #1
    b       find_end
add_newline:
    mov     w2, #10
    strb    w2, [x1]
    add     x1, x1, #1
    strb    wzr, [x1]
    
    // Calculate string length
    sub     x20, x1, x0
    
    // Debug: show what filename we're trying to create (commented out)
    // mov     x0, #STDOUT_FILENO
    // adr     x1, debug_filename_text
    // mov     x2, debug_filename_text_len
    // mov     x8, #SYS_WRITE
    // svc     #0

    // Show the actual filename string
    // mov     x0, #STDOUT_FILENO
    // adr     x1, high_score_file
    // mov     x2, #8
    // mov     x8, #SYS_WRITE
    // svc     #0
    
    // Print newline
    // mov     x0, #STDOUT_FILENO
    // adr     x1, newline
    // mov     x2, #1
    // mov     x8, #SYS_WRITE
    // svc     #0
    
    // Try multiple file creation approaches
    // Use openat system call
    // openat(dirfd, pathname, flags, mode)
    mov     x0, #AT_FDCWD
    adr     x1, high_score_file
    mov     x2, #577
    mov     x3, #420
    mov     x8, #SYS_OPENAT
    svc     #0
    
file_open_success:
    
    // Debug: show file descriptor result
    mov     x19, x0
    // mov     x0, #STDOUT_FILENO
    // adr     x1, debug_fd_text
    // mov     x2, debug_fd_text_len
    // mov     x8, #SYS_WRITE
    // svc     #0
    
    // Convert fd to string and display
    // mov     w0, w19
    // adr     x1, score_buffer
    // bl      int_to_string
    // mov     x0, #STDOUT_FILENO
    // adr     x1, score_buffer
    // mov     x2, #10
    // mov     x8, #SYS_WRITE
    // svc     #0
    
    // Print newline
    // mov     x0, #STDOUT_FILENO
    // adr     x1, newline
    // mov     x2, #1
    // mov     x8, #SYS_WRITE
    // svc     #0
    
    // Check for errors
    mov     x0, x19
    cmp     x0, #0
    b.lt    save_high_scores_error
    
    // Write high score data as text
    mov     x0, x19
    adr     x1, high_score_buffer
    mov     x2, x20
    mov     x8, #SYS_WRITE
    svc     #0
    
    // Close file
    mov     x0, x19
    mov     x8, #SYS_CLOSE
    svc     #0
    
    // Check write result
    cmp     x0, #0
    b.lt    save_high_scores_error
    
    // Success message (commented out for clean gameplay)
    // mov     x0, #STDOUT_FILENO
    // adr     x1, save_success_text
    // mov     x2, save_success_text_len
    // mov     x8, #SYS_WRITE
    // svc     #0
    
    b       save_high_scores_done

save_high_scores_error:
    // Try alternative path in /tmp directory
    adr     x0, high_score_file_tmp
    mov     x1, #O_WRONLY
    orr     x1, x1, #O_CREAT
    orr     x1, x1, #O_TRUNC
    mov     x2, #420
    mov     x8, #SYS_OPENAT
    svc     #0
    
    // Check if /tmp path worked
    cmp     x0, #0
    b.lt    save_high_scores_final_error
    
    // Write to /tmp file
    mov     x19, x0
    adr     x1, high_score_buffer
    mov     x2, x20
    mov     x8, #SYS_WRITE
    svc     #0
    
    // Close /tmp file
    mov     x0, x19
    mov     x8, #SYS_CLOSE
    svc     #0
    
    // Success with alternative path
    mov     x0, #STDOUT_FILENO
    adr     x1, save_tmp_success_text
    mov     x2, save_tmp_success_text_len
    mov     x8, #SYS_WRITE
    svc     #0
    b       save_high_scores_done

save_high_scores_final_error:
    // Final error message
    mov     x0, #STDOUT_FILENO
    adr     x1, save_error_text
    mov     x2, save_error_text_len
    mov     x8, #SYS_WRITE
    svc     #0

save_high_scores_done:
    ldp     x29, x30, [sp], #16
    ret

// Check for new records and update high scores
check_and_update_records:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Only check SCORE record (ignore food count and time for NEW RECORD message)
    adr     x0, score
    adr     x1, high_score  
    ldr     w2, [x0]
    ldr     w3, [x1]
    cmp     w2, w3
    b.le    check_records_done
    
    // NEW HIGH SCORE! 
    str     w2, [x1]
    bl      save_high_scores
    
    // Only show message if file existed (had previous score to beat)
    adr     x0, file_exists
    ldr     w0, [x0]
    cmp     w0, #1
    b.ne    check_records_done
    
    // Show NEW RECORD message  
    mov     x0, #STDOUT_FILENO
    adr     x1, new_record_text
    mov     x2, new_record_text_len
    mov     x8, #SYS_WRITE
    svc     #0
    
    bl      play_new_record_sound

check_records_done:
    ldp     x29, x30, [sp], #16
    ret

// Sound effects functions
play_food_sound:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Try terminal bell first
    mov     x0, #STDOUT_FILENO
    adr     x1, bell_sound
    mov     x2, #1
    mov     x8, #SYS_WRITE
    svc     #0
    
    ldp     x29, x30, [sp], #16
    ret

// // Next function
//     mov     x0, #STDOUT_FILENO
//     adr     x1, score_buffer
//     mov     x2, #10
//     mov     x8, #SYS_WRITE
//     svc     #0
    
//     mov     x0, #STDOUT_FILENO
//     adr     x1, debug_vs_high
//     mov     x2, debug_vs_high_len
//     mov     x8, #SYS_WRITE
//     svc     #0
    
//     mov     w0, w23
//     adr     x1, food_buffer
//     bl      int_to_string
//     mov     x0, #STDOUT_FILENO
//     adr     x1, food_buffer
//     mov     x2, #10
//     mov     x8, #SYS_WRITE
//     svc     #0
    
//     mov     x0, #STDOUT_FILENO
//     adr     x1, newline
//     mov     x2, #1
//     mov     x8, #SYS_WRITE
//     svc     #0
    
//     // Restore values and do comparison
//     cmp     w22, w23
//     b.le    check_food_record
    
//     // New high score
//     str     w22, [x21]
//     mov     w19, #1
    
// check_food_record:
//     // Check food count record
//     adr     x0, food_count
//     adr     x1, high_food_count
//     ldr     w2, [x0]
//     ldr     w3, [x1]
//     cmp     w2, w3
//     b.le    check_time_record
    
//     // New high food count
//     str     w2, [x1]
//     mov     w19, #1
    
// check_time_record:
//     // Check time record
//     bl      calculate_elapsed_time
//     adr     x0, elapsed_seconds
//     adr     x1, longest_time
//     ldr     w2, [x0]
//     ldr     w3, [x1]
//     cmp     w2, w3
//     b.le    save_records
    
//     // New time record
//     str     w2, [x1]
//     mov     w19, #1
    
// save_records:
//     // Debug: show what w19 is
//     mov     x0, #STDOUT_FILENO
//     adr     x1, debug_w19_text
//     mov     x2, debug_w19_text_len
//     mov     x8, #SYS_WRITE
//     svc     #0
    
//     mov     w0, w19
//     adr     x1, time_buffer
//     bl      int_to_string
//     mov     x0, #STDOUT_FILENO
//     adr     x1, time_buffer
//     mov     x2, #10
//     mov     x8, #SYS_WRITE
//     svc     #0
    
//     mov     x0, #STDOUT_FILENO
//     adr     x1, newline
//     mov     x2, #1
//     mov     x8, #SYS_WRITE
//     svc     #0
    
//     // If any new record, save and maybe display message
//     cmp     w19, #1
//     b.ne    check_records_done
    
//     // We have a new record - save it
//     mov     x0, #STDOUT_FILENO
//     adr     x1, debug_saving_text
//     mov     x2, debug_saving_text_len
//     mov     x8, #SYS_WRITE
//     svc     #0
    
//     bl      save_high_scores
    
//     // Only display "NEW RECORD" if file existed before (had previous scores to beat)
//     adr     x0, file_exists
//     ldr     w0, [x0]
//     cmp     w0, #1
//     b.ne    check_records_done
    
//     // Display NEW RECORD message
//     mov     x0, #STDOUT_FILENO
//     adr     x1, new_record_text
//     mov     x2, new_record_text_len
//     mov     x8, #SYS_WRITE
//     svc     #0
    
//     bl      play_new_record_sound
    
//     // Try terminal bell first
//     mov     x0, #STDOUT_FILENO
//     adr     x1, bell_sound
//     mov     x2, #1
//     mov     x8, #SYS_WRITE
//     svc     #0
    
//     // Force flush output
//     mov     x0, #STDOUT_FILENO
//     mov     x1, #0
//     mov     x8, #74
//     svc     #0
    
//     ldp     x29, x30, [sp], #16
//     ret

play_golden_food_sound:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Play two bells for golden food
    bl      play_food_sound
    bl      play_food_sound
    
    ldp     x29, x30, [sp], #16
    ret

play_new_record_sound:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Play three bells for new record
    bl      play_food_sound
    bl      play_food_sound  
    bl      play_food_sound
    
    ldp     x29, x30, [sp], #16
    ret

play_game_over_sound:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Play game over sound
    bl      play_food_sound
    
    ldp     x29, x30, [sp], #16
    ret

// Game sleep function with progressive speed
game_sleep:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Check current level for speed adjustment
    adr     x0, current_level
    ldr     w0, [x0]
    cmp     w0, #LEVEL_SUPER_FAST
    b.eq    super_fast_speed
    
    // Normal speed calculation for Level 1 and 2
    // Base speed: 200ms, reduce by 5ms per segment, minimum 80ms
    adr     x0, snake_length
    ldr     w1, [x0]
    
    // Calculate: max(80ms, 200ms - (length-3)*5ms)
    sub     w1, w1, #INITIAL_SNAKE_LENGTH
    mov     w2, #5
    mul     w1, w1, w2
    
    mov     w3, #200
    subs    w3, w3, w1
    mov     w4, #80
    cmp     w3, w4
    csel    w3, w4, w3, lt
    b       apply_sleep_time

super_fast_speed:
    // Level 3: Super fast - much shorter sleep times
    // Base speed: 60ms, reduce by 2ms per segment, minimum 30ms
    adr     x0, snake_length
    ldr     w1, [x0]
    
    sub     w1, w1, #INITIAL_SNAKE_LENGTH
    mov     w2, #2
    mul     w1, w1, w2
    
    mov     w3, #60
    subs    w3, w3, w1
    mov     w4, #30
    cmp     w3, w4
    csel    w3, w4, w3, lt

apply_sleep_time:
    
    // Convert milliseconds to nanoseconds
    movz    w4, #0x86A0, lsl #0
    movk    w4, #0xF, lsl #16
    mul     w3, w3, w4
    
    // Store in sleep_time structure
    adr     x0, sleep_time
    str     xzr, [x0]
    str     w3, [x0, #8]
    
    mov     x1, #0
    mov     x8, #SYS_NANOSLEEP
    svc     #0
    
    ldp     x29, x30, [sp], #16
    ret

// Parse score from text buffer
// Input: x0 = buffer address
// Output: Stores parsed score in high_score
parse_score_from_text:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    mov     x1, x0
    mov     w2, #0
    mov     w3, #10
    
parse_loop:
    ldrb    w4, [x1], #1
    
    // Check for end of string or newline
    cbz     w4, parse_done
    cmp     w4, #10
    b.eq    parse_done
    cmp     w4, #32
    b.eq    parse_done
    
    // Check if character is digit (0-9)
    sub     w4, w4, #48
    cmp     w4, #0
    b.lt    parse_loop
    cmp     w4, #9
    b.gt    parse_loop
    
    // Add digit to accumulator
    mul     w2, w2, w3
    add     w2, w2, w4
    b       parse_loop
    
parse_done:
    // Store result in high_score
    adr     x0, high_score
    str     w2, [x0]
    
    ldp     x29, x30, [sp], #16
    ret

.data
.align 3

// Terminal settings
termios_orig:   .space 60
termios_raw:    .space 60

// Game state
game_grid:      .space (GRID_WIDTH * GRID_HEIGHT)
snake_body:     .space (MAX_SNAKE_LENGTH * 8)
snake_length:   .word INITIAL_SNAKE_LENGTH
snake_head_index: .word 0
snake_direction: .word DIR_RIGHT
food_position:  .space 8
food_type:      .word 0
score:          .word 0
food_count:     .word 0
game_paused:    .word 0
quit_flag:      .word 0
current_level:  .word LEVEL_NORMAL

// Game statistics
game_start_time: .space 16
current_time:   .space 16
pause_start_time: .space 16
total_paused_time: .word 0
elapsed_seconds: .word 0

// High score data
high_score:     .word 0
high_food_count: .word 0
longest_time:   .word 0
file_exists:    .word 0

// Input/output buffers
input_buffer:   .space 4
random_buffer:  .space 2
score_buffer:   .space 12
food_buffer:    .space 12
time_buffer:    .space 12
speed_buffer:   .space 12
high_score_buffer: .space 32

// High score file
high_score_file: .asciz "file.txt"
high_score_file_tmp: .asciz "/tmp/snake_high_score.txt"

// Sleep timing
sleep_time:
    .quad 0
    .quad 200000000

// ANSI escape sequences
clear_screen_seq: .ascii "\x1b[2J"
clear_screen_seq_len = . - clear_screen_seq

hide_cursor_seq: .ascii "\x1b[?25l"
hide_cursor_seq_len = . - hide_cursor_seq

show_cursor_seq: .ascii "\x1b[?25h"
show_cursor_seq_len = . - show_cursor_seq

move_cursor_home: .ascii "\x1b[1;1H"
move_cursor_home_len = . - move_cursor_home

// Game display characters
snake_cell: .ascii "\x1b[42m \x1b[0m"
snake_cell_len = . - snake_cell

food_cell: .ascii "\x1b[41m*\x1b[0m"
food_cell_len = . - food_cell

golden_food_cell: .ascii "\x1b[43m*\x1b[0m"
golden_food_cell_len = . - golden_food_cell

empty_cell: .ascii " "
vertical_border: .ascii "|"
horizontal_border: .ascii "-"
corner_char: .ascii "+"
vertical_border_newline: .ascii "|\n"
corner_newline: .ascii "+\n"
newline: .ascii "\n"

// Game text
game_title: .ascii "=== SNAKE GAME ===\n"
game_title_len = . - game_title

score_text: .ascii "Score: "
score_text_len = . - score_text

controls_text: .ascii "Controls: WASD/Arrow Keys to move, SPACE to pause, Q to quit\n"
controls_text_len = . - controls_text

game_over_text: .ascii "\n=== GAME OVER ===\n"
game_over_text_len = . - game_over_text

final_score_text: .ascii "Final Score: "
final_score_text_len = . - final_score_text

food_count_text: .ascii "Food Eaten: "
food_count_text_len = . - food_count_text

pause_text: .ascii "\n=== PAUSED - Press SPACE to continue ===\n"
pause_text_len = . - pause_text

level_display_text: .ascii " | Level: "
level_display_text_len = . - level_display_text

speed_text: .ascii " | Speed Level: "
speed_text_len = . - speed_text

time_text: .ascii " | Time: "
time_text_len = . - time_text

seconds_text: .ascii "s"
seconds_text_len = . - seconds_text

new_record_text: .ascii "\n*** NEW RECORD! ***\n"
new_record_text_len = . - new_record_text

welcome_title: .ascii "\n\n=== WELCOME TO SNAKE GAME ===\n\n"
welcome_title_len = . - welcome_title

level_select_text: .ascii "SELECT LEVEL:\n\n"
level_select_text_len = . - level_select_text

level_1_text: .ascii "  1. Normal Mode (Classic Snake)\n"
level_1_text_len = . - level_1_text

level_2_text: .ascii "  2. No Walls Mode (Snake wraps around edges)\n"
level_2_text_len = . - level_2_text

level_3_text: .ascii "  3. Super Fast Mode (High speed challenge)\n\n"
level_3_text_len = . - level_3_text

level_select_prompt: .ascii "Use UP/DOWN arrow keys or W/S to select, ENTER to confirm\n"
level_select_prompt_len = . - level_select_prompt

level_indicator: .ascii ">>>"
level_indicator_len = . - level_indicator

clear_line: .ascii "\x1b[2K\r"
clear_line_len = . - clear_line

save_success_text: .ascii "(High score saved to file.txt)\n"
save_success_text_len = . - save_success_text

save_error_text: .ascii "(Error: Could not save high score to file.txt - check permissions)\n"
save_error_text_len = . - save_error_text

save_tmp_success_text: .ascii "(High score saved to /tmp/snake_high_score.txt)\n"
save_tmp_success_text_len = . - save_tmp_success_text

debug_score_text: .ascii "Saving score: "
debug_score_text_len = . - debug_score_text

debug_fd_text: .ascii "File descriptor: "
debug_fd_text_len = . - debug_fd_text

debug_filename_text: .ascii "Trying to create file: "
debug_filename_text_len = . - debug_filename_text

debug_current_score: .ascii "Current: "
debug_current_score_len = . - debug_current_score

debug_vs_high: .ascii " vs High: "
debug_vs_high_len = . - debug_vs_high

debug_w19_text: .ascii "Record flag (w19): "
debug_w19_text_len = . - debug_w19_text

debug_saving_text: .ascii "Actually saving new record!\n"
debug_saving_text_len = . - debug_saving_text

debug_loaded_text: .ascii "Loaded from file: '"
debug_loaded_text_len = . - debug_loaded_text

debug_parsed_text: .ascii "Parsed high score: "
debug_parsed_text_len = . - debug_parsed_text

bell_sound: .ascii "\x07"

// Alternative visual feedback when audio doesn't work
flash_text: .ascii "\x1b[5m*BEEP*\x1b[25m"
flash_text_len = . - flash_text
