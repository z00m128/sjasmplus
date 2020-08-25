    OUTPUT "dir_elseif.bin"

    ;; no nested blocks, just regular IF/ELSEIF/ELSEIF/ELSE/ENDIF chain

    IF 1
        ld  b,c ;   'A'
    ELSEIF 1
        false   ; false because other block was active (true)
    ELSEIF 1
        false   ; false because other block was active (true)
    ELSE
        false   ; false because other block was active (true)
    ENDIF

    IF 0
        false
    ELSEIF 1
        ld  b,d ;   'B'
    ELSEIF 1
        false   ; false because other block was active (true)
    ELSE
        false
    ENDIF

    IF 0
        false
    ELSEIF 0
        false
    ELSEIF 1
        ld  b,e ;   'C'
    ELSE
        false
    ENDIF

    IF 0
        false
    ELSEIF 0
        false
    ELSEIF 0
        false
    ELSE
        ld  b,h ;   'D'
    ENDIF

    ;; nested blocks

    ; first block active ('a')
    IF 1
        ld  h,c ;   'a'
        IF 1
            ld  b,c ;   'A'
        ELSEIF 1
            false   ; false because other block was active (true)
        ELSEIF 1
            false   ; false because other block was active (true)
        ELSE
            false   ; false because other block was active (true)
        ENDIF

        IF 0
            false
        ELSEIF 1
            ld  b,d ;   'B'
        ELSEIF 1
            false   ; false because other block was active (true)
        ELSE
            false
        ENDIF

        IF 0
            false
        ELSEIF 0
            false
        ELSEIF 1
            ld  b,e ;   'C'
        ELSE
            false
        ENDIF

        IF 0
            false
        ELSEIF 0
            false
        ELSEIF 0
            false
        ELSE
            ld  b,h ;   'D'
        ENDIF
    ELSEIF 1
        false   ; false because other block was active (true)
        IF 1
            false
        ELSEIF 1
            false
        ELSEIF 1
            false
        ELSE
            false
        ENDIF
    ELSEIF 1
        false   ; false because other block was active (true)
        IF 1
            false
        ELSEIF 1
            false
        ELSEIF 1
            false
        ELSE
            false
        ENDIF
    ELSE
        false   ; false because other block was active (true)
        IF 1
            false
        ELSEIF 1
            false
        ELSEIF 1
            false
        ELSE
            false
        ENDIF
    ENDIF

    ; second block active ('b')
    IF 0
        false
        IF 1
            false
        ELSEIF 1
            false
        ELSEIF 1
            false
        ELSE
            false
        ENDIF
    ELSEIF 1
        ld  h,d ;   'b'
        IF 1
            ld  b,c ;   'A'
        ELSEIF 1
            false   ; false because other block was active (true)
        ELSEIF 1
            false   ; false because other block was active (true)
        ELSE
            false   ; false because other block was active (true)
        ENDIF

        IF 0
            false
        ELSEIF 1
            ld  b,d ;   'B'
        ELSEIF 1
            false   ; false because other block was active (true)
        ELSE
            false
        ENDIF

        IF 0
            false
        ELSEIF 0
            false
        ELSEIF 1
            ld  b,e ;   'C'
        ELSE
            false
        ENDIF

        IF 0
            false
        ELSEIF 0
            false
        ELSEIF 0
            false
        ELSE
            ld  b,h ;   'D'
        ENDIF
    ELSEIF 1
        false   ; false because other block was active (true)
        IF 1
            false
        ELSEIF 1
            false
        ELSEIF 1
            false
        ELSE
            false
        ENDIF
    ELSE
        false   ; false because other block was active (true)
        IF 1
            false
        ELSEIF 1
            false
        ELSEIF 1
            false
        ELSE
            false
        ENDIF
    ENDIF

    ; third block active ('c')
    IF 0
        false
        IF 1
            false
        ELSEIF 1
            false
        ELSEIF 1
            false
        ELSE
            false
        ENDIF
    ELSEIF 0
        false
        IF 1
            false
        ELSEIF 1
            false
        ELSEIF 1
            false
        ELSE
            false
        ENDIF
    ELSEIF 1
        ld  h,e ;   'c'
        IF 1
            ld  b,c ;   'A'
        ELSEIF 1
            false   ; false because other block was active (true)
        ELSEIF 1
            false   ; false because other block was active (true)
        ELSE
            false   ; false because other block was active (true)
        ENDIF

        IF 0
            false
        ELSEIF 1
            ld  b,d ;   'B'
        ELSEIF 1
            false   ; false because other block was active (true)
        ELSE
            false
        ENDIF

        IF 0
            false
        ELSEIF 0
            false
        ELSEIF 1
            ld  b,e ;   'C'
        ELSE
            false
        ENDIF

        IF 0
            false
        ELSEIF 0
            false
        ELSEIF 0
            false
        ELSE
            ld  b,h ;   'D'
        ENDIF
    ELSE
        false   ; false because other block was active (true)
        IF 1
            false
        ELSEIF 1
            false
        ELSEIF 1
            false
        ELSE
            false
        ENDIF
    ENDIF

    ; fourth block active ('d')
    IF 0
        false
        IF 1
            false
        ELSEIF 1
            false
        ELSEIF 1
            false
        ELSE
            false
        ENDIF
    ELSEIF 0
        false
        IF 1
            false
        ELSEIF 1
            false
        ELSEIF 1
            false
        ELSE
            false
        ENDIF
    ELSEIF 0
        false
        IF 1
            false
        ELSEIF 1
            false
        ELSEIF 1
            false
        ELSE
            false
        ENDIF
    ELSE
        ld  h,h ;   'd'
        IF 1
            ld  b,c ;   'A'
        ELSEIF 1
            false   ; false because other block was active (true)
        ELSEIF 1
            false   ; false because other block was active (true)
        ELSE
            false   ; false because other block was active (true)
        ENDIF

        IF 0
            false
        ELSEIF 1
            ld  b,d ;   'B'
        ELSEIF 1
            false   ; false because other block was active (true)
        ELSE
            false
        ENDIF

        IF 0
            false
        ELSEIF 0
            false
        ELSEIF 1
            ld  b,e ;   'C'
        ELSE
            false
        ENDIF

        IF 0
            false
        ELSEIF 0
            false
        ELSEIF 0
            false
        ELSE
            ld  b,h ;   'D'
        ENDIF
    ENDIF

    ASSERT 24 == $  ; expected output: "ABCDaABCDbABCDcABCDdABCD"

    ;; verify that ELSEIF expression is not evaluated when active block already happened
    IF 1
    ELSEIF @    ; would emit syntax error if evaluated
    ELSE
    ENDIF

    IF 0
    ELSEIF 1
    ELSEIF @    ; would emit syntax error if evaluated
    ELSE
    ENDIF
