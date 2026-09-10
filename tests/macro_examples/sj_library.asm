    OPT push reset --syntax=abfw

    MACRO negR16toR16 fromR16?, toR16?
        ; 6B 24T, uses A
        xor     a
        sub     low fromR16?
        ld      low toR16?,a    ; low = 0 - low
        sbc     a,a
        sub     high fromR16?
        ld      high toR16?,a   ; high = 0 - high - borrow
    ENDM

    MACRO negR16 r16?
        ; 6B 24T, uses A
        negR16toR16 r16?, r16?
    ENDM

    MACRO negDEtoHL
        ; 6B 29T, but preserves A, HL = -DE
        ld  hl,0
        or  a
        sbc hl,de
    ENDM

    MACRO alignHl alignValue?
        ASSERT 2 <= (alignValue?)
        ASSERT 0 == ((alignValue?) & ((alignValue?)-1)) ; make sure it's power of two
        IF (alignValue?) == 2
            inc     hl
            res     0,l
                ; 3B 14T
        ELSEIF (alignValue?) < 256
            dec     hl
            ld      a,(alignValue?)-1
            or      l
            ld      l,a
            inc     hl
                ; 6B 27T, uses A
        ELSEIF (alignValue?) == 256
            dec     hl
            inc     h
            ld      l,0
                ; 4B 17T
        ELSEIF (alignValue?) == 512
            dec     hl
            set     0,h
            inc     h
            ld      l,0
                ; 6B 25T
        ELSE : ASSERT 256 < (alignValue?)
            dec     hl
            ld      a,high((alignValue?)-1)
            or      h
            inc     a
            ld      h,a
            ld      l,0
                ; 8B 32T, uses A
        ENDIF
    ENDM

    OPT pop
