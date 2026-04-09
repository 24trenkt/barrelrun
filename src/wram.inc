; Add a file header comment to all code files except hardware.inc
if !def(WRAM_INC)
def WRAM_INC equ 1

rsset _RAM

; WRAM variables for joypad
def PAD_CURR    rb 1
def PAD_PREV    rb 1
def PAD_PRSS    rb 1
def PAD_RLSE    rb 1

; WRAM variables for player
def PLAYER_TIMER rb 1

def WRAM_END    rb 0

def WRAM_USAGE equ (WRAM_END - _RAM)
println "WRAM usage: {d:WRAM_USAGE} bytes"
assert WRAM_USAGE <= $2000, "Too many bytes used in WRAM"

endc
