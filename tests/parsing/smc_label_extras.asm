;  The syntax `<label>+<single_digit>[:]` is meant to be used as self-modify-code marker only,
; so the plus and single digit should cover cases (+1..+3).
;  The syntax is intentionally limited to not clash with regular
; syntax (expressions "eating" `and/or/xor` instruction, etc.)

x       equ     1
    org #8000
lA:     and 1
    ; valid extra syntax (colon is optional)
lB+1    and 2
lC+1:   and 3
lD+0    and 4   ; pointless, but valid
lE+9    and 5
    ; valid extra syntax, empty remainder of line
lO+2
lP+3:
    ; syntax errors (single digit only)
lF+10   and 6
lG+#1   and 7
    ; syntax errors (no expressions, no evaluation)
lH+(1)  and 8
lI+x    and 9
lJ+1+2  and 10
lK+1-3  and 11
    ; syntax errors (no minus either)
lL-1    and 12
lM-1:   and 13

123+1   jr  123B
124+1:  jr  124B

lN+1    MACRO
            nop
        ENDM
        lN

        STRUCT S_TEST
Byte        BYTE    0x12
Smc+1       BYTE    0x34    ; error, can't have SMC
        ENDS

NormalStruct    S_TEST
SmcStruct+1     S_TEST      ; error, can't have SMC

    ASSERT #8000+0 == lA
    ASSERT #8002+1 == lB
    ASSERT #8004+1 == lC
    ASSERT #8006+0 == lD
    ASSERT #8008+9 == lE
    ASSERT #800A   == lF
    ASSERT #800A+2 == lO
    ASSERT #800A+3 == lP
