; Based on documentation example (definitions same as tests/docs_examples/c_structures.asm)
; But this test does focus on stressing initializers syntax

        STRUCT  SCOLOR
RED     BYTE 4
GREEN   BYTE 5
BLUE    BYTE 6
        ENDS

        STRUCT SDOT
X       BYTE
Y       BYTE
C       SCOLOR 0,1,0 ; use new default values
        ENDS

        DEVICE  ZXSPECTRUM48
        ORG     0x8000

COLOR   SCOLOR                  ; set by default to { 4, 5, 6 }

COLORTABLE      ; without labels per item
        SCOLOR  0,0,0           ; { 0, 0, 0 }
        SCOLOR  1,2,3           ; { 1, 2, 3 }
        SCOLOR  ,2              ; { 4, 2, 6 }

DOT1    SDOT    0,0, 0,0,0      ; X:0, Y:0, C = { 0, 0, 0 }
        SDOT    {1,2, {3,4,5}}  ; X:1, Y:2, C = { 3, 4, 5 }
        SDOT    {6,7 {,,8}}     ; X:6, Y:7, C = { 0, 1, 8 } (overriden defaults + 8)
        ;syntax fail: SDOT    {6, {,,8}}, but "{6,,{,,8}}" works

;        SAVEBIN "c_structures.bin", COLOR, $-COLOR
        DISPLAY "FIXME: The binary result is disabled for now, work-in-progress"
        ; FIXME: this whole test is unfinished
; TODO:
;  - add bigger "stress-test" (than align.asm is)
;   -- more complex structures, all possible data fields
;   -- exercise incomplete initializers a bit more (and {})
;   -- ... ?? ...
