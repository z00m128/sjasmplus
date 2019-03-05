    MACRO filler x1, x2, y1, y2
        IF (y1 < 0)
            ld  hl,y1*2
            add hl,sp
            ld  sp,hl
        ENDIF
        IF (0 <= y1)
            ld  hl,y1*2
            add hl,sp
            ld  sp,hl
        ENDIF

        ld  hl,y1*2
        add hl,sp
        ld  sp,hl
        dup (y2 - y1)
            ld  de,x1
            pop hl
            add hl,de

            dup (x2 - x1)
                ld  (hl),a
                inc l
            edup

            ld  (hl),a
        edup
    ENDM

    output "if_in_macro.bin"

    filler 17, 20, 37, 40

    IF ($ < 0x40)
        ds  0x40 - $, 201
    ENDIF

    ret

    ; verify that IF works inside macro even if there's nothing after the macro.
    filler 117, 120, 137, 140