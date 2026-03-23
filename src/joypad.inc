; 
; CS 240: Storing Joypad state, including pressed/released/etc
;
; @file joypad.inc
; @author Darren Strash and CS 240
; @brief constants and macros for joypad

if !def(JOYPAD_INC)
def JOYPAD_INC equ 1

include "src/wram.inc"

def NONE_HELD equ $FF

; initialize stored joypad buttons to so that
; none of them are initially detected as held
macro InitJoypad
    ld a, NONE_HELD
    ld [PAD_CURR], a
    ld [PAD_PREV], a
    ld [PAD_RLSE], a
    ld [PAD_PRSS], a
endm

macro UpdateJoypad
    ; store the previous input into the struct and (c)
    ld a, [PAD_CURR]
    ld [PAD_PREV], a
    ld c, a

    ; read the dpad
    ld a, P1F_GET_DPAD
    ldh [rP1], a
    ldh a, [rP1]
    ldh a, [rP1]

    ; put the dpad input into (b)'s high nibble
    swap a
    and a, $F0
    ld b, a

    ; read the buttons
    ld a, P1F_GET_BTN
    ldh [rP1], a
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]

    ; merge the buttons' input into (b)'s low nibble
    and a, $0F
    or a, b
    ld b, a

    ; store the current input
    ld [PAD_CURR], a

    ; disable input polling
    ld a, P1F_GET_NONE
    ldh [rP1], a

    ; compute and store pressed buttons
    ld a, c
    cpl
    or a, b
    ld [PAD_PRSS], a

    ; compute and store released buttons
    ld a, b
    cpl
    or a, c
    ld [PAD_RLSE], a
endm

endc
