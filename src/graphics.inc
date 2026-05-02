; CS240: World 8: Full Game
; @file graphics.inc
; @author Tommy Trenk
; @date May 1, 2026
; Contains macros and constants to initialize graphics data and
; update the screen when needed
if !def(GRAPHICS_INC)
def GRAPHICS_INC        equ 1
def NUM_TO_TILE         equ 200
def PLAYER_SPRITE_L     equ _OAMRAM
def PLAYER_SPRITE_R     equ _OAMRAM + sizeof_OAM_ATTRS
def PLAYER_L_START_X    equ 80
def PLAYER_R_START_X    equ 88
def MOD_8               equ %00000111
def MOD_16              equ %00001111

; disable the LCD
macro DisableLCD
    ; wait for the vblank
    .wait_vblank\@
        ld a, [rLY]
        cp a, SCRN_Y
        jr nz, .wait_vblank\@

    ; turn the LCD off
    xor a
    ld [rLCDC], a
endm

; clear the OAM
macro InitOAM
    ld c, OAM_COUNT
    ld hl, _OAMRAM + OAMA_Y
    ld de, sizeof_OAM_ATTRS
    .init_oam\@
        ld [hl], 0
        add hl, de
        dec c
        jr nz, .init_oam\@
endm

; Turns the lcd on with desired graphics parameters
macro EnableLCD
    ld a, LCDCF_ON | LCDCF_WIN9C00 | LCDCF_BG8800 | LCDCF_BG9800 | LCDCF_OBJ16 | LCDCF_OBJON | LCDCF_BGON | \1
    ld [rLCDC], a
endm

macro EnableAmmoCounter
    ld hl, $9C00
    ld a, 135
    ld [hli], a
    ld a, 157
    ld [hli], a
    ld [hli], a
    ld a, 169
    ld [hli], a
    ld [hl], 180
endm

endc
