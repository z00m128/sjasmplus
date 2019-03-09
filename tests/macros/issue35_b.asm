    MACRO MYMACRO1 addr, string, term
        ld de,addr
    ENDM

    ; this will exercise the max-depth limit = 20 in substitution
    MYMACRO1 test_result_string, string, 0  ; "string = string" causes infinite recursion
