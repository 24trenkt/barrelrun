; CS240: World 8: Full Game
; @file main.asm
; @author Tommy Trenk
; @date May 1, 2026
; Contains function calls to initilize data, and executes
; the main game loop, moving the background, player, and obstacles
include "src/hardware.inc"
include "src/graphics.inc"
include "src/joypad.inc"
include "src/utils.inc"
include "src/wram.inc"

def WINDOW_X            equ 120
def WINDOW_Y            equ 136
def WIN_X_START         equ 7
def SPACING_START       equ 50
def LEVEL_COUNT_START   equ 200
def LEVEL_INDEX         equ $9CCC
def SPACING_DECREASE    equ 10
def ONE_SEC             equ 60
def MOVE_UP_FRAMES      equ 164
def EIGHT               equ 8


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
    ld a, WIN_X_START
    ld [rWX], a
    ld a, 0
    ld [rWY], a
    copy [SPACING], SPACING_START
    copy [LVL_COUNTER], LEVEL_COUNT_START
    call init_graphics
    EnableLCD LCDCF_WINON

    ; Reads from input until START is pressed, then initialies 
    ; sprites and disables the window
    .start_screen
        UpdateJoypad
        call check_start
        jr nz, .start_screen
    DisableLCD
    call init_player
    call init_barrels
    call init_rock
    EnableAmmoCounter
    EnableLCD LCDCF_WINON
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
        jr z, .game_over
        ld a, [BARRELS_LEFT]
        or a
        jr z, .next_level
        jr .loop

.next_level
    DisableLCD
    ld a, WIN_X_START
    ld [rWX], a
    ld a, 0
    ld [rWY], a
    call init_graphics
    ld hl, LEVEL_INDEX
    ld a, [LVL_COUNTER]
    inc a
    ld [LVL_COUNTER], a
    ld [hl], a
    ld a, [SPACING]
    sub a, SPACING_DECREASE
    ld [SPACING], a
    cp a, SPACING_DECREASE
    jr z, .win
    EnableLCD LCDCF_WINON
    jp .start_screen

.game_over
    ld c, ONE_SEC
    .game_over_loop
    halt
    ld a, [PLAYER_TIMER]
    inc a
    ld [PLAYER_TIMER], a

    ; compute %8
    and MOD_16
    jr nz, .pal1
        ; Use tile 1
        copy [PLAYER_SPRITE_L + OAMA_FLAGS], OAMF_PAL1
        copy [PLAYER_SPRITE_R + OAMA_FLAGS], OAMF_PAL1
    .pal1
    cp a, MOD_8
    jr nz, .done
        ; use tile 2
        copy [PLAYER_SPRITE_L + OAMA_FLAGS], OAMF_PAL0
        copy [PLAYER_SPRITE_R + OAMA_FLAGS], OAMF_PAL0
    .done
        dec c
        jr nz, .game_over_loop
    jp .begin

.win
    ld c, MOVE_UP_FRAMES
    ld a, PLAYER_L_START_X
    ld [PLAYER_SPRITE_L + OAMA_X], a
    add a, EIGHT
    ld [PLAYER_SPRITE_R + OAMA_X], a
    EnableLCD LCDCF_WINOFF
    .win_loop
        halt
        push bc
        call move_player
        ld a, [PLAYER_SPRITE_L + OAMA_Y]
        dec a
        ld [PLAYER_SPRITE_L + OAMA_Y], a
        ld [PLAYER_SPRITE_R + OAMA_Y], a
        pop bc
        dec c
        jr nz, .win_loop
        .second_loop
        halt
        call animate_win
        jr nz, .second_loop
        jp .begin