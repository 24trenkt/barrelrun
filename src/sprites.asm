; CS240: World 6: Game Draft
; @file graphics.asm
; @author Tommy Trenk
; @date April 8, 2026
; Loads multiple sprites, representing the player and various
; obstacles into OAM, and contains function to update sprites

include "src/utils.inc"
include "src/wram.inc"
include "src/joypad.inc"

; if only used in this file, then it makes sense 
; to put player constants here. If used elsewhere (very possible)
; then put in player.inc file

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

def LEFT_LANE_L           equ 64
def LEFT_LANE_R           equ 72
def MIDDLE_LANE_L         equ 80
def MIDDLE_LANE_R         equ 88
def RIGHT_LANE_L          equ 96
def RIGHT_LANE_R          equ 104

def VERTICAL_COLLISION_Y equ PLAYER_START_Y - 8

def OAMA_NO_FLAGS         equ 0

section "player", rom0

macro AnimatePlayer
    ; update the timer
    ld a, [PLAYER_TIMER]
    inc a

    ; compute %32
    and %00011111
    ld [PLAYER_TIMER], a

    ; based on timer, change the tiles that represent the player
    cp 0
    jr z, .walk0\@
    cp 8
    jr z, .walk1\@
    cp 16
    jr z, .walk2\@
    cp 24
    jr z, .walk1\@
    jr .walkdone\@

    .walk0\@
        copy [PLAYER_SPRITE_L + OAMA_TILEID], PLAYER_L_TILEID
        copy [PLAYER_SPRITE_R + OAMA_TILEID], PLAYER_R_TILEID
        jr .walkdone\@
    .walk1\@
        copy [PLAYER_SPRITE_L + OAMA_TILEID], PLAYER_L_TILEID + 4
        copy [PLAYER_SPRITE_R + OAMA_TILEID], PLAYER_R_TILEID + 4
        jr .walkdone\@
    .walk2\@
        copy [PLAYER_SPRITE_L + OAMA_TILEID], PLAYER_L_TILEID + 8
        copy [PLAYER_SPRITE_R + OAMA_TILEID], PLAYER_R_TILEID + 8
        jr .walkdone\@
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

; Moves barrels down the screen, then moves them back to the top
move_barrels:
    ld a, [BARREL_1_L + OAMA_Y]
    cp a, 160
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

    .no_collision_1
        ld a, [BARREL_2_L + OAMA_Y]
        cp a, 160
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

export init_player, init_barrels, move_player, move_barrels