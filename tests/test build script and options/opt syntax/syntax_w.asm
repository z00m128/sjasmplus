; SYNTAX option "w":
;   w      Warnings options: report warnings as errors

; verify regular syntax works as expected with default options
    ld      a,0x1234            ; warning about lost bytes
    OPT push --syntax=w ; test the syntax option "w"
    ld      a,0x1234            ; error about lost bytes
    OPT pop             ; test push+pop of new option
    ld      a,0x1234            ; warning about lost bytes
    ASSERT _WARNINGS == 2 && _ERRORS == 1
