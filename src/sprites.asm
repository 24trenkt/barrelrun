; CS240: World 6: Game Draft
; @file graphics.asm
; @author Tommy Trenk
; @date April 18, 2026
; Loads multiple sprites, representing the player and various
; obstacles into OAM, and contains function to update sprites

include "src/utils.inc"
include "src/wram.inc"
include "src/joypad.inc"

def PLAYER_SPRITE_L       equ _OAMRAM
def PLAYER_SPRITE_R       equ _OAMRAM + sizeof_OAM_ATTRS
def PLAYER_L_START_X      equ 80
def PLAYER_R_START_X      equ 88
def PLAYER_START_Y        equ 136
def PLAYER_L_TILEID       equ 0
def PLAYER_R_TILEID       equ 2

def BARREL_1_L            equ _OAMRAM + sizeof_OAM_ATTRS * 2
def BARREL_1_R            equ _OAMRAM + sizeof_OAM_ATTRS * 3
def BARREL_2_L            equ _OAMRAM + sizeof_OAM_ATTRS * 4
def BARREL_2_R            equ _OAMRAM + sizeof_OAM_ATTRS * 5
def BARREL_1_START_Y      equ 0
def BARREL_2_START_Y      equ 60
def BARREL_L_TILEID       equ 12
def BARREL_R_TILEID       equ 14

def ROCK_L                equ _OAMRAM + sizeof_OAM_ATTRS * 6
def ROCK_R                equ _OAMRAM + sizeof_OAM_ATTRS * 7
def ROCK_START_X          equ 0
def ROCK_START_Y          equ 0
def ROCK_L_TILEID         equ 16
def ROCK_R_TILEID         equ 18

def LEFT_LANE_L           equ 64
def LEFT_LANE_R           equ 72
def MIDDLE_LANE_L         equ 80
def MIDDLE_LANE_R         equ 88
def RIGHT_LANE_L          equ 96
def RIGHT_LANE_R          equ 104

def VERTICAL_COLLISION_Y  equ PLAYER_START_Y - 8
def ANIMATE_LENGTH        equ 4

def AMMO_COUNTER_TILE     equ $9C05
def NUM_TO_TILE           equ 200

def MOD_8                 equ %00000111
def OFF_SCREEN            equ 160
def L_R_CONVERT           equ 2
def TILE_WIDTH            equ 8

def ANIMATE1              equ 0
def ANIMATE2              equ 4
def ANIMATE3              equ 8


def OAMA_NO_FLAGS         equ 0

section "player", rom0
ANIMATE:
    db ANIMATE1, ANIMATE2, ANIMATE3, ANIMATE2


macro AnimatePlayer
    ; update the timer
    ld a, [PLAYER_TIMER]
    inc a
    ld [PLAYER_TIMER], a

    ; compute %8
    and MOD_8
    jr nz, .walkdone\@

    ld a, [PLAYER_FRAME]
    ld hl, ANIMATE
    ld d, 0
    ld e, a
    add hl, de
    ld a, [hl]

    ld [PLAYER_SPRITE_L + OAMA_TILEID], a
    add a, L_R_CONVERT
    ld [PLAYER_SPRITE_R + OAMA_TILEID], a

    ; increment PLAYER_FRAME
    ld a, [PLAYER_FRAME]
    inc a
    ld [PLAYER_FRAME], a

    ; reset if PLAYER_FRAME == 4
    cp ANIMATE_LENGTH
    jr nz, .walkdone\@
        xor a
        ld [PLAYER_FRAME], a
    .walkdone\@
endm

; Initializes the player sprite
init_player:
    copy [PLAYER_SPRITE_L + OAMA_X], MIDDLE_LANE_L
    copy [PLAYER_SPRITE_L + OAMA_Y], PLAYER_START_Y
    copy [PLAYER_SPRITE_L + OAMA_TILEID], PLAYER_L_TILEID
    copy [PLAYER_SPRITE_L + OAMA_FLAGS], OAMA_NO_FLAGS

    copy [PLAYER_SPRITE_R + OAMA_X], MIDDLE_LANE_R
    copy [PLAYER_SPRITE_R + OAMA_Y], PLAYER_START_Y
    copy [PLAYER_SPRITE_R + OAMA_TILEID], PLAYER_R_TILEID
    copy [PLAYER_SPRITE_R + OAMA_FLAGS], OAMA_NO_FLAGS

    copy [PLAYER_TIMER], 0
    copy [PLAYER_FRAME], 0
    ret

; Creates two barrel obstacles
init_barrels:
    copy [BARREL_1_L + OAMA_X], MIDDLE_LANE_L
    copy [BARREL_1_L + OAMA_Y], BARREL_1_START_Y
    copy [BARREL_1_L + OAMA_TILEID], BARREL_L_TILEID
    copy [BARREL_1_L + OAMA_FLAGS], OAMA_NO_FLAGS

    copy [BARREL_1_R + OAMA_X], MIDDLE_LANE_R
    copy [BARREL_1_R + OAMA_Y], BARREL_1_START_Y
    copy [BARREL_1_R + OAMA_TILEID], BARREL_R_TILEID
    copy [BARREL_1_R + OAMA_FLAGS], OAMA_NO_FLAGS

    copy [BARREL_2_L + OAMA_X], RIGHT_LANE_L
    copy [BARREL_2_L + OAMA_Y], BARREL_2_START_Y
    copy [BARREL_2_L + OAMA_TILEID], BARREL_L_TILEID
    copy [BARREL_2_L + OAMA_FLAGS], OAMA_NO_FLAGS

    copy [BARREL_2_R + OAMA_X], RIGHT_LANE_R
    copy [BARREL_2_R + OAMA_Y], BARREL_2_START_Y
    copy [BARREL_2_R + OAMA_TILEID], BARREL_R_TILEID
    copy [BARREL_2_R + OAMA_FLAGS], OAMA_NO_FLAGS

    ret

; initialize the rock projectile for the player
init_rock:
    copy [ROCK_L + OAMA_X], ROCK_START_X
    copy [ROCK_L + OAMA_Y], ROCK_START_Y
    copy [ROCK_L + OAMA_TILEID], ROCK_L_TILEID
    copy [ROCK_L + OAMA_FLAGS], OAMA_NO_FLAGS

    copy [ROCK_R + OAMA_X], ROCK_START_X + TILE_WIDTH
    copy [ROCK_R + OAMA_Y], ROCK_START_Y
    copy [ROCK_R + OAMA_TILEID], ROCK_R_TILEID
    copy [ROCK_R + OAMA_FLAGS], OAMA_NO_FLAGS

    ld a, 3
    ld [AMMO_LEFT], a
    xor a
    ld [ROCK_TIMER], a

ret

; Moves the player to different lanes, including logic to
; avoid leaving the 3 lane track
move_player:
    TestPadInput PAD_PRSS, PADF_LEFT
    jr nz, .left_checked
        ld a, [PLAYER_SPRITE_L + OAMA_X]
        cp a, LEFT_LANE_L
        jr z, .left_checked
            sub a, 16
            ld [PLAYER_SPRITE_L + OAMA_X], a
            add a, 8
            ld [PLAYER_SPRITE_R + OAMA_X], a
    .left_checked

    TestPadInput PAD_PRSS, PADF_RIGHT
    jr nz, .right_checked
        ld a, [PLAYER_SPRITE_L + OAMA_X]
        cp a, RIGHT_LANE_L
        jr z, .right_checked
            add a, 16
            ld [PLAYER_SPRITE_L + OAMA_X], a
            add a, 8
            ld [PLAYER_SPRITE_R + OAMA_X], a
    .right_checked

    AnimatePlayer
    ret

; Moves the rock, and checks to throw a new one
throw_rock:
    ld a, [ROCK_TIMER]
    or a
    jr z, .check_for_new
        ld a, [ROCK_L + OAMA_Y]
        dec a
        ld [ROCK_L + OAMA_Y], a
        ld [ROCK_R + OAMA_Y], a

        ld a, [ROCK_TIMER]
        dec a
        ld [ROCK_TIMER], a
        or a
        jr nz, .done
            ld [ROCK_L + OAMA_Y], a
            ld [ROCK_R + OAMA_Y], a

    ; If there is no rock on screen, check to see if A is pressed to throw another
    .check_for_new
    ld a, [AMMO_LEFT]
    or a
    jr z, .done
    TestPadInput PAD_PRSS, PADF_A
        jr nz, .done
        ld a, 16
        ld [ROCK_TIMER], a
        ld a, [AMMO_LEFT]
        dec a
        ld [AMMO_LEFT], a
        ld hl, AMMO_COUNTER_TILE
        add a, NUM_TO_TILE
        ld [hl], a

        ld a, [PLAYER_SPRITE_L + OAMA_X]
        ld [ROCK_L + OAMA_X], a
        ld a, [PLAYER_SPRITE_L + OAMA_Y]
        ld [ROCK_L + OAMA_Y], a

        ld a, [PLAYER_SPRITE_R + OAMA_X]
        ld [ROCK_R + OAMA_X], a
        ld a, [PLAYER_SPRITE_R + OAMA_Y]
        ld [ROCK_R + OAMA_Y], a

    .done
        ret

; Moves barrels down the screen, then moves them back to the top
move_barrels:

    ; Moves the first barrel, checking for collisions.
    ld a, [BARREL_1_L + OAMA_Y]
    cp a, OFF_SCREEN
    jr nz, .first_on_screen
        ld a, 0
        ld [BARREL_1_L + OAMA_Y], a
        ld [BARREL_1_R + OAMA_Y], a
    .first_on_screen
        inc a
        ld [BARREL_1_L + OAMA_Y], a
        ld [BARREL_1_R + OAMA_Y], a
        cp a, VERTICAL_COLLISION_Y
        jr nz, .no_collision_1 
            ld a, [BARREL_1_L + OAMA_X]
            ld b, a
            ld a, [PLAYER_SPRITE_L + OAMA_X]
            cp a, b
            jr nz, .no_collision_1
                ret

    ; Moves the second barrel, checking for collisions.
    .no_collision_1
        ld a, [BARREL_2_L + OAMA_Y]
        cp a, OFF_SCREEN
        jr nz, .second_on_screen
            ld a, 0
            ld [BARREL_2_L + OAMA_Y], a
            ld [BARREL_2_R + OAMA_Y], a
        .second_on_screen
            inc a
            ld [BARREL_2_L + OAMA_Y], a
            ld [BARREL_2_R + OAMA_Y], a
            cp a, VERTICAL_COLLISION_Y
            jr nz, .no_collision_2
                ld a, [BARREL_2_L + OAMA_X]
                ld b, a
                ld a, [PLAYER_SPRITE_L + OAMA_X]
                cp a, b
                jr nz, .no_collision_2
                    ret

    .no_collision_2
        ret

export init_player, init_barrels, init_rock, move_player, move_barrels, throw_rock