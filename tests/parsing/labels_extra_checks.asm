            ORG     0x1000

nop:        nop
            ld      hl,nop
            ld      hl,@nop
            ld      hl,?nop
            ld      hl,+nop

not:        cpl
            ld      hl,not      ; error, collides with "not" operator
            ld      hl,@not
            ld      hl,?not
            ld      hl,+not     ; error, collides with "not" operator

; all of the following should be valid
symbol_22
symbol_23   DEFL    23
symbol_24   =       24
symbol_25   EQU     25

; make pass2 differ from pass1
            IFUSED symbol_22
404         nop                 ; no error since v1.21.1, temporary labels can change flow until last pass
symbol_22                       ; also duplicate label in pass2 error
                                ; ^^^ seems to be bugged currently, only warnings happens
            ENDIF
            jr      symbol_22

; local numeric labels are more limited
22
23          DEFL    23
24          =       24
25          EQU     25
            jr      22B

errSymbol1  DEFL    !
errSymbol2  =       !
errSymbol3  EQU     !

    STRUCT TEST_STRUCT
X       BYTE    1
Y       WORD    0x0302
        ALIGN
        ALIGN
    ENDS

    STRUCT TEST_STRUCT_2
.X:     BYTE    8
3       BYTE    -8
        BLOCK   !
        BLOCK   1,!
        BYTE    0xFF
        D24     !
        BYTE    0xFF
        DWORD   !
    ENDS

    MODULE Module1

        STRUCT TEST_STRUCT
Z           BYTE    0xFF
            ALIGN
            ALIGN
        ENDS

instanceModule  TEST_STRUCT 

instanceGlobal  @TEST_STRUCT 

            TEST_STRUCT 

            @TEST_STRUCT 

        STRUCT TEST_STRUCT_2
.Z:         BYTE    4
5           BYTE    -4
            BLOCK   !
            BLOCK   1,!
            BYTE    0xFF
            D24     !
            BYTE    0xFF
            DWORD   !
        ENDS
instanceMod2    TEST_STRUCT_2
instanceglob2   @TEST_STRUCT_2
                TEST_STRUCT_2
                @TEST_STRUCT_2

        STRUCT TEST_STRUCT_3
.S2Mod:     TEST_STRUCT_2

    ; empty line above is intentional to exercise certain code path in parser.cpp
.Empty      ; skipBlank(..) exercise
.S2Glob:    @TEST_STRUCT_2
.Self:      TEST_STRUCT_3
        ENDS

    ENDMODULE
