; Based on documentation example (definitions same as tests/docs_examples/c_structures.asm)
; But this test does focus on stressing initializers syntax

        STRUCT  SCOLOR
RED     BYTE 4
GREEN   BYTE 5
BLUE    BYTE 6
        ENDS

        STRUCT SDOT
X       BYTE    8
Y       BYTE    9
C       SCOLOR  10,11,12 ; use new default values
        ENDS

        OUTPUT initializer_syntax.bin

COLOR   SCOLOR                  ; set by default to { 4, 5, 6 }

COLORTABLE      ; without labels per item
        SCOLOR  0,0,0           ; { 0, 0, 0 }
        SCOLOR  ,,3             ; { 4, 5, 3 }
        SCOLOR  ,2              ; { 4, 2, 6 }

DOT1    SDOT                    ; X:8, Y:9, C = { 10, 11, 12 }
        SDOT    {1,2, {3,4,5}}  ; X:1, Y:2, C = { 3, 4, 5 }

        ; X:6, Y:7, C = { 10, 11, 8 }
        SDOT    {6,7 {,,8}}
        SDOT    6,7,,,8
        SDOT    6,7 {,,8}
        SDOT    {6,7 ,,,8}

        ; X:6, Y:9, C = { 10, 11, 8 }
        SDOT    {6{,,8}}
        SDOT    {6,{,,8}}
        SDOT    {6, {,,8}}
        SDOT    {6,,{,,8}}
        SDOT    {  6  ,  ,  {  ,  ,  8  }  }

        ; X:8, Y:7, C = { 10, 8, 12 }
        SDOT    {,7{,8}}
        SDOT    {,7,{,8}}
        SDOT    {,7,{,8,}}
        SDOT    { , 7 , { , 8 } }
        SDOT    { , 7 , { , 8, } }
        SDOT    ,7{,8}
        SDOT    ,7,,8
        SDOT    ,7,,8,
        SDOT    {,7,,8}

        SDOT    {1,2,3}         ; X:1, Y:2, C = { 3, 11, 12 }
        SDOT    ,{1,2,3}        ; X:8, Y:9, C = { 1, 2, 3 }

        ; few errors
        SDOT    {,7{,8}}}
        SDOT    {,7{,8}}{
        SDOT    {{,7{,8}}
        SDOT    {{,7{,8}}}
        SDOT    ,7,,8,,

        STRUCT SERR
C       SCOLOR {31,32,33
        ENDS
