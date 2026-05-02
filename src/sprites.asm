; CS240: World 8: Full Game
; @file sprites.asm
; @author Tommy Trenk
; @date May 1, 2026
; Loads multiple sprites, representing the player and various
; obstacles into OAM, and contains function to update sprites

include "src/utils.inc"
include "src/wram.inc"
include "src/joypad.inc"
include "src/graphics.inc"

def PLAYER_START_Y        equ 136
def PLAYER_L_TILEID       equ 0
def PLAYER_R_TILEID       equ 2
def PLAYER_L_WIN_1        equ 20
def PLAYER_R_WIN_1        equ 22
def PLAYER_L_WIN_2        equ 24
def PLAYER_R_WIN_2        equ 26

; Barrel Row 0
def BARREL_00_L           equ _OAMRAM + sizeof_OAM_ATTRS * 2
def BARREL_00_R           equ _OAMRAM + sizeof_OAM_ATTRS * 3
def BARREL_01_L           equ _OAMRAM + sizeof_OAM_ATTRS * 4
def BARREL_01_R           equ _OAMRAM + sizeof_OAM_ATTRS * 5
def BARREL_02_L           equ _OAMRAM + sizeof_OAM_ATTRS * 6
def BARREL_02_R           equ _OAMRAM + sizeof_OAM_ATTRS * 7
def ROW_0_START           equ 2

; Barrel Row 1
def BARREL_10_L           equ _OAMRAM + sizeof_OAM_ATTRS * 8
def BARREL_10_R           equ _OAMRAM + sizeof_OAM_ATTRS * 9
def BARREL_11_L           equ _OAMRAM + sizeof_OAM_ATTRS * 10
def BARREL_11_R           equ _OAMRAM + sizeof_OAM_ATTRS * 11
def BARREL_12_L           equ _OAMRAM + sizeof_OAM_ATTRS * 12
def BARREL_12_R           equ _OAMRAM + sizeof_OAM_ATTRS * 13
def ROW_1_START           equ 8

; Barrel Row 2
def BARREL_20_L           equ _OAMRAM + sizeof_OAM_ATTRS * 14
def BARREL_20_R           equ _OAMRAM + sizeof_OAM_ATTRS * 15
def BARREL_21_L           equ _OAMRAM + sizeof_OAM_ATTRS * 16
def BARREL_21_R           equ _OAMRAM + sizeof_OAM_ATTRS * 17
def BARREL_22_L           equ _OAMRAM + sizeof_OAM_ATTRS * 18
def BARREL_22_R           equ _OAMRAM + sizeof_OAM_ATTRS * 19
def ROW_2_START           equ 14

; Barrel Row 3
def BARREL_30_L           equ _OAMRAM + sizeof_OAM_ATTRS * 20
def BARREL_30_R           equ _OAMRAM + sizeof_OAM_ATTRS * 21
def BARREL_31_L           equ _OAMRAM + sizeof_OAM_ATTRS * 22
def BARREL_31_R           equ _OAMRAM + sizeof_OAM_ATTRS * 23
def BARREL_32_L           equ _OAMRAM + sizeof_OAM_ATTRS * 24
def BARREL_32_R           equ _OAMRAM + sizeof_OAM_ATTRS * 25
def ROW_3_START           equ 20

def BARREL_L_TILEID       equ 12
def BARREL_R_TILEID       equ 14
def BARREL_X_OFFSCREEN    equ 0

def LEVEL_ZERO_SPACING    equ 60
def LEVEL_ONE_SPACING     equ 45
def LEVEL_TWO_SPACING     equ 30
def LEVEL_THREE_SPACING   equ 20

def ROCK_L                equ _OAMRAM + sizeof_OAM_ATTRS * 26
def ROCK_R                equ _OAMRAM + sizeof_OAM_ATTRS * 27
def ROCK_START_X          equ 140
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
def COLLIDE_UPPER         equ 144
def ANIMATE_LENGTH        equ 4

def AMMO_COUNTER_TILE     equ $9C05
def MOD_32                equ %00011111
def OFF_SCREEN            equ 160
def L_R_CONVERT           equ 2
def TILE_WIDTH            equ 8

def ANIMATE1              equ 0
def ANIMATE2              equ 4
def ANIMATE3              equ 8

def SPRITES_PER_ROW       equ 6
def BIT_1                 equ 1
def BIT_2                 equ 2
def BIT_3                 equ 3

def SOUND_VAR_1           equ $0C
def SOUND_VAR_2           equ $FE
def SOUND_VAR_3           equ $8B
def SOUND_VAR_4           equ $C0

def BIT_CONSTANT          equ %00001110
def SIXTEEN               equ 16
def EIGHT                 equ 8

def ROCK_TIME             equ 20



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

macro MakeSpacing
    ld a, \1
    ld b, a
    sla a
    sla a
    cp a, OFF_SCREEN
    jr c, .spacing\@
        inc a
        ld [RESET_Y], a 

    .spacing\@
    xor a
    ld [ROW_0_Y], a
    add a, b

    ld [ROW_1_Y], a
    add a, b

    ld [ROW_2_Y], a
    add a, b

    ld [ROW_3_Y], a
    add a, b
endm

macro InitBarrel
        copy [\1 + OAMA_X], 0
        copy [\1 + OAMA_Y], \3
        copy [\1 + OAMA_TILEID], BARREL_L_TILEID
        copy [\1 + OAMA_FLAGS], OAMA_NO_FLAGS

        copy [\2 + OAMA_X], 0
        copy [\2 + OAMA_Y], \3
        copy [\2 + OAMA_TILEID], BARREL_R_TILEID
        copy [\2 + OAMA_FLAGS], OAMA_NO_FLAGS
endm

macro ResetBarrel
    copy [\1 + OAMA_Y], \3
    copy [\2 + OAMA_Y], \3
endm

macro PlaceBarrel
    bit \3, b
    jr z, .offscreen\@
        ld [hl], \1
        add hl, de
        ld [hl], \2
        add hl, de
        jr .done\@
    .offscreen\@
        ld [hl], 0
        add hl, de
        ld [hl], 0
        add hl, de
    .done\@
endm

macro MoveRow
    ld c, SPRITES_PER_ROW
    ld a, [hl]
    inc a
    ld [\1], a
    push hl
    ld hl, RESET_Y
    cp a, [hl]
    pop hl
    jp nz, .move_loop\@
        ld a, [BARRELS_LEFT]
        dec a
        ld [BARRELS_LEFT], a
        push hl
        inc hl
        GetRandom
        PlaceBarrel LEFT_LANE_L, LEFT_LANE_R, BIT_1
        PlaceBarrel MIDDLE_LANE_L, MIDDLE_LANE_R, BIT_2
        PlaceBarrel RIGHT_LANE_L, RIGHT_LANE_R, BIT_3
        xor a
        ld [\1], a
        pop hl
    .move_loop\@
        ld [hl], a
        add hl, de
        dec c
        jr nz, .move_loop\@  
    .done\@
endm

macro CheckCollision
ld a, [PLAYER_SPRITE_L + OAMA_X]
ld b, a
ld a, [\1 + OAMA_X]
cp a, b
jr z, .collision\@

ld a, [\2 + OAMA_X]
cp a, b
jr z, .collision\@

ld a, [\3 + OAMA_X]
cp a, b
jr z, .collision\@
jr .no_collision\@

.collision\@
    scf
    jr .done\@

.no_collision\@
    scf
    ccf
    jr .done\@

.done\@
endm

macro RockCollision
    ld a, [ROCK_L + OAMA_Y]
    sub a, 16
    ld b, a
    ld a, [ROW_0_Y]
    cp a, b
    jr nz, .check_1\@
        ld hl, BARREL_00_L
        inc hl
        CheckRow
        jp .done\@ 

    .check_1\@
    ld a, [ROW_1_Y]
    cp a, b
    jr nz, .check_2\@
        ld hl, BARREL_10_L
        inc hl
        CheckRow
        jr .done\@

    .check_2\@
    ld a, [ROW_2_Y]
    cp a, b
    jr nz, .check_3\@
        ld hl, BARREL_20_L
        inc hl
        CheckRow
        jr .done\@

    .check_3\@
    ld a, [ROW_3_Y]
    cp a, b
    jr nz, .done\@
        ld hl, BARREL_30_L
        inc hl
        CheckRow
        jr .done\@

    .done\@
endm

macro CheckRow
    ld de, sizeof_OAM_ATTRS
    ld a, [ROCK_L + OAMA_X]
    ld b, a
    ld c, 3
    .loop\@
        ld a, [hl]
        cp a, b
        jr z, .collide\@ 
        add hl, de
        add hl, de
        dec c
        jr nz, .loop\@
    jr .done\@

    .collide\@
        xor a
        ld [hl], a
        add hl, de
        ld [hl], a
        copy [rNR41], SOUND_VAR_1
        copy [rNR42], SOUND_VAR_2
        copy [rNR43], SOUND_VAR_3
        copy [rNR44], SOUND_VAR_4
    .done\@
endm

macro GetRandom
    .random\@
    ld a, [rDIV]
    and a, BIT_CONSTANT
    cp a, BIT_CONSTANT
    jr z, .random\@
    cp a, 0
    jr z, .random\@
    ld b, a
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
    MakeSpacing [SPACING]
    copy [BARRELS_LEFT], MOD_32

    GetRandom
    InitBarrel BARREL_00_L, BARREL_00_R, [ROW_0_Y]
    InitBarrel BARREL_01_L, BARREL_01_R, [ROW_0_Y]
    InitBarrel BARREL_02_L, BARREL_02_R, [ROW_0_Y]

    GetRandom
    InitBarrel BARREL_10_L, BARREL_10_R, [ROW_1_Y]
    InitBarrel BARREL_11_L, BARREL_11_R, [ROW_1_Y]
    InitBarrel BARREL_12_L, BARREL_12_R, [ROW_1_Y]

    GetRandom
    InitBarrel BARREL_20_L, BARREL_20_R, [ROW_2_Y]
    InitBarrel BARREL_21_L, BARREL_21_R, [ROW_2_Y]
    InitBarrel BARREL_22_L, BARREL_22_R, [ROW_2_Y]

    GetRandom
    InitBarrel BARREL_30_L, BARREL_30_R, [ROW_3_Y]
    InitBarrel BARREL_31_L, BARREL_31_R, [ROW_3_Y]
    InitBarrel BARREL_32_L, BARREL_32_R, [ROW_3_Y]

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

    ld a, BIT_3
    ld [AMMO_LEFT], a
    ld hl, AMMO_COUNTER_TILE
    add a, NUM_TO_TILE
    ld [hl], a
    xor a
    ld [ROCK_TIMER], a

ret

; Moves the player to different lanes, including logic to
; avoid leaving the 3 lane track
move_player:
    TestPadInput PAD_PRSS, PADF_LEFT
    jr nz, .left_checked
        ld a, [PLAYER_SPRITE_L + OAMA_X]
        ld [rDIV], a
        cp a, LEFT_LANE_L
        jr z, .left_checked
            sub a, SIXTEEN
            ld [PLAYER_SPRITE_L + OAMA_X], a
            add a, EIGHT
            ld [PLAYER_SPRITE_R + OAMA_X], a
    .left_checked

    TestPadInput PAD_PRSS, PADF_RIGHT
    jr nz, .right_checked
        ld a, [PLAYER_SPRITE_L + OAMA_X]
        ld [rDIV], a
        cp a, RIGHT_LANE_L
        jr z, .right_checked
            add a, SIXTEEN
            ld [PLAYER_SPRITE_L + OAMA_X], a
            add a, EIGHT
            ld [PLAYER_SPRITE_R + OAMA_X], a
    .right_checked

    AnimatePlayer
    ret

; Moves the rock, and checks to throw a new one
throw_rock:
    ld a, [ROCK_TIMER]
    or a
    jp z, .check_for_new
        RockCollision
        ld a, [ROCK_L + OAMA_Y]
        dec a
        ld [ROCK_L + OAMA_Y], a
        ld [ROCK_R + OAMA_Y], a
        RockCollision
        ld a, [ROCK_TIMER]
        dec a
        ld [ROCK_TIMER], a
        or a
        jp nz, .done
            ld [ROCK_L + OAMA_X], a
            ld [ROCK_R + OAMA_X], a

    ; If there is no rock on screen, check to see if A is pressed to throw another
    .check_for_new
    ld a, [AMMO_LEFT]
    or a
    jr z, .done
    TestPadInput PAD_PRSS, PADF_A
        jr nz, .done
        ld a, ROCK_TIME
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
    ld hl, _OAMRAM
    ; ld de, OAMA_Y
    ; add hl, de
    ld de, sizeof_OAM_ATTRS
    add hl, de
    add hl, de

    MoveRow ROW_0_Y
    ld a, [ROW_0_Y]
    cp a, COLLIDE_UPPER
    jr nc, .no_collision_0
        cp a, VERTICAL_COLLISION_Y
            jr c, .no_collision_0
            CheckCollision BARREL_00_L, BARREL_01_L, BARREL_02_L
            jr nc, .no_collision_0
                xor a
                ret
    .no_collision_0
    MoveRow ROW_1_Y
    ld a, [ROW_1_Y]
    cp a, COLLIDE_UPPER
    jr nc, .no_collision_1
    cp a, VERTICAL_COLLISION_Y
    jr c, .no_collision_1
        CheckCollision BARREL_10_L, BARREL_11_L, BARREL_12_L
        jr nc, .no_collision_1
            xor a
            ret
    .no_collision_1
    MoveRow ROW_2_Y
    ld a, [ROW_2_Y]
    cp a, COLLIDE_UPPER
    jr nc, .no_collision_2
    cp a, VERTICAL_COLLISION_Y
    jr c, .no_collision_2
        CheckCollision BARREL_20_L, BARREL_21_L, BARREL_22_L
        jr nc, .no_collision_2
            xor a
            ret
    .no_collision_2
    MoveRow ROW_3_Y
    ld a, [ROW_3_Y]
    cp a, COLLIDE_UPPER
    jr nc, .no_collision_3
    cp a, VERTICAL_COLLISION_Y
    jr c, .no_collision_3
        CheckCollision BARREL_30_L, BARREL_31_L, BARREL_32_L
        jr nc, .no_collision_3
            xor a
            ret
    .no_collision_3
        xor a
        inc a
        ret

animate_win:
    ; update the timer
    ld a, [PLAYER_TIMER]
    inc a
    ld [PLAYER_TIMER], a

    ; compute %8
    and MOD_32
    jr nz, .walk1
        ; Use tile 1
        copy [PLAYER_SPRITE_L + OAMA_TILEID], PLAYER_L_WIN_1
        copy [PLAYER_SPRITE_R + OAMA_TILEID], PLAYER_R_WIN_1
    .walk1
    cp a, SIXTEEN
    jr nz, .check_start
        ; use tile 2
        copy [PLAYER_SPRITE_L + OAMA_TILEID], PLAYER_L_WIN_2
        copy [PLAYER_SPRITE_R + OAMA_TILEID], PLAYER_R_WIN_2
    .check_start
        UpdateJoypad
        TestPadInput PAD_PRSS, PADF_START
        jr nz, .start_checked
            xor a
        jr .done
        .start_checked
            ld a, 1
        .done
        ret 

export init_player, init_barrels, init_rock, move_player, move_barrels, throw_rock, animate_win