    invalid_instruction     ; regular file+line report
    sla d                   ; SLD
#   line    100     "/i/am/not/just/include/file"
    invalid_instruction     ; report /i/am/not/just/include/file(100)
    sla d                   ; SLD
    IFNDEF ALREADY_DEFINED_OUTSIDE_MACRO
        MACRO mac_from_include
            invalid_instruction ; report fake definition location
            sla d               ; SLD
        ENDM
        DEFINE ALREADY_DEFINED_OUTSIDE_MACRO
    ENDIF
    ; after include EOF the reporting will revert back to what it was before INCLUDE