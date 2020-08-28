; regular correct nested DUP (just to be sure it still works)
    DUP     2
        DUP     2
            daa
        EDUP
    EDUP

; first variant of problem -> correct amount of EDUPs
; but nested <count> expression syntax error happens, making nested DUP suddenly missing
    DUP     2
        nop
    DUP
        nop
    EDUP
    EDUP

; second variant of problem -> EDUP missing for real, completely    
    DUP     3
        DUP     4
            nop
    EDUP
    ; the line 11 will be reported, even if it looks like it has EDUP, but that one is
    ; consumed by nested DUP at line 12
