; CS240: World 6: Game Draft
; @file graphics.asm
; @author Tommy Trenk
; @date April 8, 2026
; Contains function calls to initilize data, and executes
; the main game loop, moving the background, player, and obstacles
include "src/hardware.inc"
include "src/graphics.inc"
include "src/joypad.inc"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section "header", rom0[$0100]
entrypoint:
    di
    jr main
    ds ($0150 - @), 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section "main", rom0[$0150]
main:
    ; Initialize the background and window, turning both on
    DisableLCD
    call init_graphics
    EnableLCDWinOn

    ; Reads from input until START is pressed, then initialies 
    ; sprites and disables the window
    .start_screen
        UpdateJoypad
        call check_start
        jr nz, .start_screen
    DisableLCD
    call init_player
    call init_barrels
    EnableLCDWinOff

    ; The main game loop
    .loop
        halt
        ld a, [rSCY]
        dec a
        ld [rSCY], a
        UpdateJoypad
        call move_player
        call move_barrels
        jr .loop