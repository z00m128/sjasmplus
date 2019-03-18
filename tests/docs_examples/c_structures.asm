    ;; Example 1

        STRUCT  SCOLOR
RED     BYTE 4
GREEN   BYTE 5
BLUE    BYTE 6
        ENDS

    ASSERT SCOLOR.RED == 0 && SCOLOR.GREEN == 1 && SCOLOR.BLUE == 2 && SCOLOR == 3

    ;; Example 2

        STRUCT SDOT
X       BYTE
Y       BYTE
C       SCOLOR 0,1,0 ; use new default values
        ENDS

    ASSERT SDOT.X == 0 && SDOT.Y == 1 && SDOT.C == 2 && SDOT.C.RED == 2
    ASSERT SDOT.C.GREEN == 3 && SDOT.C.BLUE == 4 && SDOT == 5

    ;; Example 3

        STRUCT SPOS,4
X       WORD
Y       BYTE
        ALIGN 2
AD      WORD
        ENDS

    ASSERT SPOS.X == 4 && SPOS.Y == 6 && SPOS.AD == 8 && SPOS == 10

    ;; Example 4 (instancing)
        DEVICE  ZXSPECTRUM48
        ORG     0x8000
COLOR   SCOLOR                  ; set by default to { 4, 5, 6 }

        ld      a,(COLOR.BLUE)  ; A = 6 (loading value from memory address "0x8002")

COLORTABLE      ; without labels per item
        SCOLOR  0,0,0           ; { 0, 0, 0 }
        SCOLOR  1,2,3           ; { 1, 2, 3 }
        SCOLOR  ,2              ; { 4, 2, 6 }

DOT1    SDOT    0,0, 0,0,0      ; X:0, Y:0, C = { 0, 0, 0 }
        SDOT    {1,2, {3,4,5}}  ; X:1, Y:2, C = { 3, 4, 5 }
        SDOT    {6,7 {,,8}}     ; X:6, Y:7, C = { 0, 1, 8 } (overriden defaults + 8)

        SAVEBIN "c_structures.tap", COLOR, $-COLOR

        ORG     0x8000

POS1    SPOS    0x1234, 0x56, 0x789A
        ; 4Bx old_value (to reach offset 4), X:0x1234, Y:0x56, 1Bx old_value, AD:0x789A

        SAVEBIN "c_structures.bin", POS1, SPOS
