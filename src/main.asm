; CS240: World 6: Game Draft
; @file graphics.asm
; @author Tommy Trenk
; @date April 8, 2026
; Contains function calls to initilize data, and executes
; the main game loop, moving the background, player, and obstacles
include "src/hardware.inc"
include "src/graphics.inc"
include "src/joypad.inc"
include "src/utils.inc"
include "src/wram.inc"

def WINDOW_X            equ 120
def WINDOW_Y            equ 136

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
    .begin
    DisableLCD
    ld a, 0
    ld [rWX], a
    ld a, 0
    ld [rWY], a
    call init_graphics
    EnableLCD

    ; Reads from input until START is pressed, then initialies 
    ; sprites and disables the window
    .start_screen
        UpdateJoypad
        call check_start
        jr nz, .start_screen
    DisableLCD
    call init_player
    ; copy [SPACING], 50
    call init_barrels
    call init_rock
    EnableLCD
    ld a, WINDOW_X
    ld [rWX], a
    ld a, WINDOW_Y
    ld [rWY], a

    ; The main game loop
    .loop
        halt
        ld a, [rSCY]
        dec a
        ld [rSCY], a
        UpdateJoypad
        call move_player
        call throw_rock
        call move_barrels
        jp z, .begin

        ldh a, [rLY]
        cp 144
        jr nc, .still_in_vblank ; rLY still in 144-153

        .overrun
            ; ld a, %00000000
            ; ld [rBGP], a
            ; jr .loop
            jp .begin

        .still_in_vblank
            ld a, %11100100
            ld [rBGP], a 
        jr .loop