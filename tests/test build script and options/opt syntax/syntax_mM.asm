; SYNTAX options "mM":
;   m      Switch off "Accessing low memory" warning globally
;   M      Alias "m" and "M" for "(hl)" to cover 8080-like syntax: ADD A,M

; verify regular syntax works as expected with default options
    ld      a,(123)             ; warning about low memory access
    ld      a,(123)             ; ok ; warning suppressed
    add     a,m                 ; label not found
    add     a,(hl)              ; regular add instruction
    OPT push --syntax=mM    ; test the syntax options "mM"
    ld      a,(123)
    ld      a,(123)             ; ok
    add     a,m                 ; (hl) used
    add     a,M                 ; (hl) used
    add     a,(hl)              ; regular add instruction
    OPT pop                 ; test push+pop of new options
    ld      a,(123)             ; warning about low memory access
    ld      a,(123)             ; ok ; warning suppressed
    add     a,M                 ; label not found
    add     a,(hl)              ; regular add instruction
    ASSERT _WARNINGS == 2 && _ERRORS == 2
