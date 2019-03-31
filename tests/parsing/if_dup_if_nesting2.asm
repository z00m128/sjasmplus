    OUTPUT if_dup_if_nesting2.bin
    IF  1
        ld b,c  ; 'A'
        DUP 2
            IF 1
                ld b,d  ; 'B'
            ELSE
                ny!
            ENDIF
            DUP 2
                IF 1
                    ld b,e  ; 'C'
                ELSE
                    ny!
                ENDIF
            EDUP
        EDUP
    ELSE
        ny!
    ENDIF
