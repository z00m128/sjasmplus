testCond    MACRO arg1?, arg2?, arg3?
                IF arg1?
                    DB  arg2?
                    IF !arg1?
                        never happens
                    ENDIF
                ELSE
                    DB  arg3?
                    IF $8004 <= $
                        DB  "..."
                    ELSE
                        jr  nc,.localLabelInCondition + '!'
                    ENDIF
.localLabelInCondition
                ENDIF
            ENDM

        DEVICE ZXSPECTRUM48 : ORG $8000
        OUTPUT "conditions_in_macro.bin"
        testCond 1, 'A', 'B'    ; A
        testCond 0, 'A', 'B'    ; B0!
        DB " "                  ; " "
        testCond 0, 'C', 'D'    ; D...
        OUTEND
