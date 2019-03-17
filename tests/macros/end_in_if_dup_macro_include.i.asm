    MACRO test_end x?
        DUP 3
            IF  0 < x?
                END
            ENDIF
            halt
        EDUP
    ENDM
