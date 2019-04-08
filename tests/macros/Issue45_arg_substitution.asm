    OUTPUT "Issue45_arg_substitution.bin"

    MACRO def name, val
        DEFINE name val
    ENDM

    def TESTD, 12345

    IFDEF TESTD
        DB      'OK'
    ELSE
        'TESTD not defined'
    ENDIF
