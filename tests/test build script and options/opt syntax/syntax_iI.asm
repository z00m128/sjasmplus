; SYNTAX option "i":
;   i      Case insensitive instructions/directives (default = same case required)

; verify regular syntax works as expected with default options
    jp  Label1 : JP  Label1     ; regular syntax - instruction
    ex  de,hl                   ; regular syntax - registers
    align 4 : ALIGN 4           ; regular syntax - directive
    Jp  Label1 : jP  Label1     ; 2x error - instruction
    ex  De,Hl                   ; illegal instruction due to registers
    Align 4 : aLiGN 4           ; 2x error - directive

    OPT --syntax=i      ; test the syntax options "i"
Label1:
    Jp  Label1 : jP  Label1     ; instructions should be case insensitive
    Align 4 : aLiGN 4           ; directives too
    ex  De,Hl                   ; registers should be also case insensitive
    ld  b,IXl,c,IXh             ; BTW this is actual way how Zilog describes half-ix regs

    OPT reset           ; reset syntax to defaults
    Jp  Label1                  ; error - instruction
    ld  b,IXl,c,IXh             ; error - register (label not found)
