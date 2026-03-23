; Add a file header comment to all code files except hardware.inc
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
    ; perform any initialization before starting the game loop

    ; make your game loop here. You may modify this however you'd like
    ; however, you should only call halt once
    .loop
        halt
        jr .loop

