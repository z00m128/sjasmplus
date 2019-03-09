    MACRO MYMACRO1 addr, string, term
        ld de,addr
    ENDM

    MACRO MYMACRO2 addr, string
        ld de,addr
    ENDM

    MACRO MYMACRO3 _addr, _string, _term
        ld de,_addr
    ENDM

    MACRO MYMACRO4 addr?, string?, term?
        ld de,addr?
    ENDM

    ORG 0x1234
    ; this will fail with "Label not found: test_result_1", because "string" sub-part is substitued with "1"
    MYMACRO1 test_result_string, 1, 0   ; this is feature, not bug (see "macro_test.asm")

    ; this will not fail (seems like BUG in sjasmplus multi-depth substitution algorithm)
    MYMACRO2 test_result_string, 1

    ; this will not fail, seems again like bug? or weird internal rule, how the '_' does
    ; work as sub-part delimiter exactly.
    MYMACRO3 test_result_string, 1, 0

    ; this should work, and was suggested as fix to the Issue#35 reporter
    MYMACRO4 test_result_string, 1, 0

test_result_string: defb 0
