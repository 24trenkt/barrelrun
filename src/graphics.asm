; CS240: World 6: Game Draft
; @file graphics.asm
; @author Tommy Trenk
; @date April 8, 2026
; Initializes graphics, and contains logic for the start screen

include "src/utils.inc"
include "src/wram.inc"
include "src/graphics.inc"
include "src/joypad.inc"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section "vblank_interrupt", rom0[$0040]
    reti

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

def TILES_COUNT                     equ (384)
def BYTES_PER_TILE                  equ (16)
def TILES_BYTE_SIZE                 equ (TILES_COUNT * BYTES_PER_TILE)

def TILEMAPS_COUNT                  equ (2)
def BYTES_PER_TILEMAP               equ (1024)
def TILEMAPS_BYTE_SIZE              equ (TILEMAPS_COUNT * BYTES_PER_TILEMAP)

def GRAPHICS_DATA_SIZE              equ (TILES_BYTE_SIZE + TILEMAPS_BYTE_SIZE)
def GRAPHICS_DATA_ADDRESS_END       equ ($8000)
def GRAPHICS_DATA_ADDRESS_START     equ (GRAPHICS_DATA_ADDRESS_END - GRAPHICS_DATA_SIZE)

def PAL_1                           equ %11100100
def PAL_2                           equ %00011011
def BGX_START                       equ 48
def NOT_ZERO                        equ 1

; load the graphics data from ROM to VRAM
macro LoadGraphicsDataIntoVRAM
    ld de, GRAPHICS_DATA_ADDRESS_START
    ld hl, _VRAM8000
    .load_tile\@
        ld a, [de]
        inc de
        ld [hli], a
        ld a, d
        cp a, high(GRAPHICS_DATA_ADDRESS_END)
        jr nz, .load_tile\@
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section "graphics", rom0

init_graphics:
; init the palettes
    ld a, PAL_1
    ld [rBGP], a
    ld [rOBP0], a
    ld a, PAL_2
    ld [rOBP1], a

    ; init graphics data
    InitOAM
    LoadGraphicsDataIntoVRAM

    ; enable the vblank interrupt
    ld a, IEF_VBLANK
    ld [rIE], a
    ei

    ; set the background position
    xor a
    ld [rSCY], a
    ld a, BGX_START
    ld [rSCX], a

    ret

; checks if START is pressed, setting the z flag if so
check_start:
TestPadInput PAD_PRSS, PADF_START
    jr nz, .start_checked
        xor a
        jr .done
    .start_checked
    ld a, NOT_ZERO
    .done
    ret

export init_graphics, check_start

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section "graphics_data", rom0[GRAPHICS_DATA_ADDRESS_START]
incbin "assets/brtilesetfinal.chr"
incbin "assets/brbackground.tlm"
incbin "assets/brnewwindow.tlm"