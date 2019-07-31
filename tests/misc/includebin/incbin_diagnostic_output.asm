    ; test diagnostic output with --msg=all
    OUTPUT "incbin_diagnostic_output.sym"
    INCBIN "incbin_diagnostic_output.asm", 4, 7
    INCBIN "incbin_diagnostic_output.asm", -10, 7
    INCBIN "incbin_diagnostic_output.asm", -10, -3  ; should include the same data
    OUTEND
; last 10 bytes of this file: 0123456789