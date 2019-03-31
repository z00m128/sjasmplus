    OUTPUT if_dup_if_nesting.bin
    IF  1
        DUP 2
            IF 1
                ld b,c
            ENDIF
        EDUP
    ENDIF
