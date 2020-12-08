    ORG $1000

    RELOCATE_START
label1:     DB  0x12
        ALIGN   16      ; relalign-ok ; suppressed warning
        ALIGN   32      ; warn about relocation mode
            ld  hl,label1
    RELOCATE_END

    RELOCATE_TABLE
