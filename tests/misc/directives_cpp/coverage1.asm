    IF & : IFN &    ; syntax errors
    IF 0 < fwdLabel : ENDIF
    IFN 0 < fwdLabel : ENDIF
fwdLabel:

    ELSE
    ENDIF

    ; create "AHOY!" in "coverage1.bin" by using all output modes
    OUTPUT "coverage1.bin",T    : DB "xx"
    OUTPUT "coverage1.bin",A    : DB "xY"
    OUTPUT "coverage1.bin",R
    DB "y" : FPOS 2 : DB  "O" : FPOS -2 : DB  "H" : FPOS +2 : DB  "!"
    OUTPUT "coverage1.bin", R   ; try with space after comma (new bugfix)
    DB "A"
    ; syntax errors (should not fallback to "truncate", would destroy current output)
    OUTPUT "coverage1.bin",
    OUTPUT "coverage1.bin",     ; with spaces after comma
    OUTPUT "coverage1.bin",&
    OUTEND
