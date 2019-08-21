    IF & : IFN &    ; syntax errors
    IF 0 < fwdLabel : ENDIF
    IFN 0 < fwdLabel : ENDIF
fwdLabel:
    IF 0 < fwdLabel : ENDIF     ; should be OK here
    IFN 0 < fwdLabel : ENDIF    ; should be OK here

    ELSE
    ENDIF

    ; create "AHOY!" in "coverage1.bin" by using all output modes
    OUTPUT "coverage1.bin",T    : DB "xx"
    OUTPUT "coverage1.bin",A    : DB "xY"
    OUTPUT "coverage1.bin",R
    DB "y" : FPOS 2 : DB  "O" : FPOS -2 : DB  "H" : FPOS +2 : DB  "!" : FPOS &
    OUTPUT "coverage1.bin", R   ; try with space after comma (new bugfix)
    DB "A"
    ; syntax errors (should not fallback to "truncate", would destroy current output)
    OUTPUT "coverage1.bin",
    OUTPUT "coverage1.bin",     ; with spaces after comma
    OUTPUT "coverage1.bin",&
    OUTEND

    DEFINE 1nvalidId value
    UNDEFINE 1nvalidId

    DEFINE validDefine 1nvalidId
    UNDEFINE validDefine
    UNDEFINE validDefine        ; warning not found (second undefine)

    UNDEFINE fwdLabel           ; labels can't be removed any more (since v1.14.0)
        ; not that it worked correctly before?? (removed because IMO broken beyond repair + undocumented!)
        ; makes little sense in 3-pass, fix the source to not rely on such weird feature

    ; bomb everything with "UNDEFINE *"
    IFDEF _SJASMPLUS    ; still defined
        DB 1
    ENDIF
    UNDEFINE *
    IFNDEF _SJASMPLUS   ; and it's gone
        DB 2
    ENDIF

    ENDS
    ASSERT 1            ; valid
    ASSERT &            ; syntax err

    DISPLAY "DISPLAY", /L, " ", /T, "has silently skipped options /L and /T. ", 15, " ", /D, 15
    DISPLAY "

    SHELLEXEC "echo Ahoy!"
    SHELLEXEC '"echo"', "from SHELLEXEC"
    SHELLEXEC "bash", "my_invalid_filename"
