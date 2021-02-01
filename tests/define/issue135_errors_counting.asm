    ; check warnings counting
    IF label : ENDIF    ; emit forward-reference warning
    ; turn warnings into errors and check errors counting
    OPT --syntax=w
    IF label : ENDIF    ; emit forward-reference error
label:
    ASSERT 1 == __WARNINGS__ && 1 == __ERRORS__

; extra note: when I initially tried to add also pass3 error/warning (to make sure
; they are not affected by changing code), it did fix the bug, so the test does only
; pass1 warning/errors, don't extend it
