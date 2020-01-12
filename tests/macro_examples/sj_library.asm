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

    MACRO negHLuseDE            ; 6B 38T
        ; HL = -HL, DE = HL (preserves A)
        ex  de,hl
        or  a
        sbc hl,hl               ; HL = 0
        sbc hl,de               ; HL = 0 - HL
    ENDM

    MACRO negDEuseHL            ; 6B 38T
        ; DE = -DE, HL = DE (preserves A)
        or  a
        sbc hl,hl
        sbc hl,de
        ex  de,hl
    ENDM
