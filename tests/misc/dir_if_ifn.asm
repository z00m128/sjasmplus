    OUTPUT "dir_if_ifn.bin"     ; final output should be 10x 'v'

    ;; Check IF functionality in normal code
    IF 5 < 3 && 2 < 10
        false
    ENDIF

    IF 3 < 5 && 2 < 10
        halt    ; true
    ENDIF

    IF 3 < 5
        IF 5 < 3
            nested false
        ENDIF
        IF 2 < 10
            halt; nested true
        ENDIF
    ENDIF

    IF 5 < 3    ; top level is false
        IF 5 < 3
            nested false
        ENDIF
        IF 2 < 10
            almost halt; nested true in false
        ENDIF
    ENDIF

    ; ELSE variants
    IF 3 < 5
        IF 5 < 3
            nested false
        ELSE
            halt; nested true
        ENDIF
    ELSE        ; top level is false
        IF 5 < 3
            nested false
        ELSE
            almost halt; nested true in false
        ENDIF
    ENDIF

    ; check the new multi-ELSE warning
    IF 3 < 2
        false
    ELSE
        halt    ; true
    ELSE        ; + warning
        false again
    ELSE        ; + warning
        halt    ; true
    ENDIF

    ;; Check IFN functionality in normal code
    IFN 5 < 3 && 2 < 10
        halt    ; true
    ENDIF

    IFN 3 < 5 && 2 < 10
        false
    ENDIF

    IFN 3 < 5   ; top level is false
        IFN 5 < 3
            almost halt; nested true in false
        ENDIF
        IFN 2 < 10
            nested false
        ENDIF
    ENDIF

    IFN 5 < 3   ; true
        IFN 5 < 3
            halt; nested true
        ENDIF
        IFN 2 < 10
            nested false
        ENDIF
    ENDIF

    ; ELSE variants
    IFN 3 < 5   ; top level is false
        IFN 5 < 3
            almost halt; nested true in false
        ELSE
            nested false
        ENDIF
    ELSE        ; true
        IFN 5 < 3
            halt; nested true
        ELSE
            nested false
        ENDIF
    ENDIF

    ; check the new multi-ELSE warning
    IFN 3 < 2
        halt    ; true
    ELSE
        false
    ELSE        ; + warning
        halt    ; true
    ELSE        ; + warning
        false again
    ENDIF
