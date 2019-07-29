nn: nop
    ld      a,'warn'
    some_error line
; invalid msg option in "--msg" will keep the test-runner "--msg=lstlab" in place,
; so the accompanying "msglst" file looks like "lstlab" with extra options error ahead
