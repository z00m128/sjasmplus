    OUTPUT "ifused_in_module.bin"
    MACRO CHECK_USAGE checkString?
        db  '/ Check ', checkString?, ", USED labels:\n"
        IFUSED @M1.LABEL1
            db    "| M1.LABEL1\n"
        ENDIF
        IFUSED @M1.LABEL2
            db    "| M1.LABEL2\n"
        ENDIF
        IFUSED @M1.LABEL3
            db    "| M1.LABEL3\n"
        ENDIF
        db  "> UNUSED labels:\n"
        IFNUSED @M1.LABEL1
            db    "| M1.LABEL1\n"
        ENDIF
        IFNUSED @M1.LABEL2
            db    "| M1.LABEL2\n"
        ENDIF
        IFNUSED @M1.LABEL3
            db    "| M1.LABEL3\n"
        ENDIF
        db  '\ Check ', checkString?, " END\n"
    ENDM

    MODULE M1
LABEL1      ;; define the three labels which will be tested by IFUSED
LABEL2
LABEL3

.useL1=LABEL1
    ENDMODULE
.useL2=M1.LABEL2

    CHECK_USAGE '[main body]'

    MODULE M2
        CHECK_USAGE '[M2 body]'
    ENDMODULE