    ORG $1234
    ; by default listing is ON (full listing)
        IF 1
            ; 1. active branch
        ELSE
            ; 1. ~LISTED~
        ENDIF
    OPT push listact    ; remember current state, switch listing to active-only
        IF 1
            ; 2. active branch (only)
        ELSE
            !!!ERROR!!! ; 2. ~SKIPPED~
        ENDIF
    OPT listall         ; switch listing back to ALL lines
        IF 1
            ; 3. active branch
        ELSE
            ; 3. ~LISTED~
        ENDIF
    OPT pop             ; restoring original state
        IF 1
            ; 4. active branch
        ELSE
            ; 4. ~LISTED~
        ENDIF
    OPT listact         ; switch listing to active-only
        IF 1
            ; 5. active branch (only)
        ELSE
            !!!ERROR!!! ; 5. ~SKIPPED~
        ENDIF
    OPT reset           ; reset to default state
        IF 1
            ; 6. active branch
        ELSE
            ; 6. ~LISTED~
        ENDIF

    ; nested listing adjusting by suggested push+pop technique
    OPT push listact    ; switch active listing twice
    OPT push listact
        IF 1
            ; 7. active branch (only)
        ELSE
            !!!ERROR!!! ; 7. ~SKIPPED~
        ENDIF
    OPT push listoff    ; switch listing completely off temporarily
        IF 1
            ; 8. !!! HIDDEN !!!
        ELSE
            !!!ERROR!!! ; 8. ~SKIPPED~
        ENDIF
    OPT pop             ; restored to active listing
        IF 1
            ; 9. active branch (only)
        ELSE
            !!!ERROR!!! ; 9. ~SKIPPED~
        ENDIF
    OPT pop
        IF 1
            ; A. active branch (only)
        ELSE
            !!!ERROR!!! ; A. ~SKIPPED~
        ENDIF
    OPT pop             ; restored to full listing
        IF 1
            ; B. active branch
        ELSE
            ; B. ~LISTED~
        ENDIF
