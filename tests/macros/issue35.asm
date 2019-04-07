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

    ; this will fail with "Label not found: test_result_1", because "string" sub-part is substitued with "1"
    MYMACRO2 test_result_string, 1

    ; this will not fail, since v1.11.2 the sjasmplus substitution rules were modified.
    ; The macro arguments and define's names starting with underscore will prevent the in-middle substition
    ; so the `_string` macro argument can substitute only whole `_string` term, but not at the end of `test_result_string`
    MYMACRO3 test_result_string, 1, 0

    ; this should work, and was suggested as fix to the Issue#35 reporter
    MYMACRO4 test_result_string, 1, 0

test_result_string: defb 0
