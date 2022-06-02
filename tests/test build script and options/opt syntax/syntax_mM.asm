; SYNTAX options "M":
;   m - removed in v1.20.0, use `-Wno-rdlow` instead
;   M      Alias "m" and "M" for "(hl)" to cover 8080-like syntax: ADD A,M

; verify regular syntax works as expected with default options
    add     a,m                 ; label not found
    add     a,(hl)              ; regular add instruction
    OPT push --syntax=M     ; test the syntax options "M"
    add     a,m                 ; (hl) used
    add     a,M                 ; (hl) used
    add     a,(hl)              ; regular add instruction
    OPT pop                 ; test push+pop of new options
    add     a,M                 ; label not found
    add     a,(hl)              ; regular add instruction
    ASSERT _WARNINGS == 0 && _ERRORS == 2
