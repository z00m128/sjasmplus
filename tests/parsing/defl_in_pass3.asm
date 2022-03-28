    ; this is UGLY example, doing machine code generation in last pass, which is sort of "wrong"
    ; but for convenience sometimes the DEFL labels in last pass are handy, for example for DISPLAY or data checks
    IF 3 == __PASS__
p3_defl = 'A'
p3_defl = p3_defl + 1
p3_defl2 DEFL 'a'
p3_defl2 DEFL p3_defl2 + 1
        DB p3_defl, p3_defl2    ; expected 'B','b'
p3_equ  EQU 123     ; error
p3_label:           ; error
.p3_local:          ; error
3       jr  3B      ; error
    ENDIF
