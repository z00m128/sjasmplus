    DEVICE ZXSPECTRUM48
    ORG $8000

    ; generally speaking, the `{<adr>}` operator is cancelling relocation
    ; of <adr> expression and operates in absolute way with the assembling-time
    ; address and memory content - seems this way it yields most logical outcomes

    RELOCATE_START
label1: DW  0x1234
label2: DW  label1              ; should be relocated

        IF 0x1234 == {label1}   ; should be true
            ld  hl,label2       ; should be relocated
        ENDIF
        IF label1 == {label2}   ; should be true (relocation unstability doesn't matter)
            ld  de,label1       ; should be relocated
        ENDIF

        ld  hl,{label1}         ; regular 0x1234 value (reads the correct one always)

    ; ! this lost "needs relocation" property by indirection: be careful when using {adr}
        ld  de,{label2}

    ; this should always evaluate to true (not affected by relocation juggling)
        DB  0x1234 == {label1}

        DW  {label1} + label1           ; should be relocated (0x1234 + label1)
        DB  low ({label1} + label1)     ; should warn (byte(0x1234 + label1) is affected)

    ; byte-reading variants use the same technique
        DB  0x34 == {b label1}          ; should be true
        DW  {b label1} + label1         ; should be relocated
        DB  low ({b label1} + label1)   ; should warn

    RELOCATE_END

    RELOCATE_TABLE
