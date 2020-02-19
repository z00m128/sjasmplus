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

    MACRO alignHl alignValue?
        ASSERT 2 <= (alignValue?)
        ASSERT 0 == ((alignValue?) & ((alignValue?)-1)) ; make sure it's power of two
        push    af
        IF (alignValue?) == 256
            xor     a
            cp      l           ; Fc=1 when 0 < L
            ld      l,a         ; L = 0
            adc     a,h
            ld      h,a
                ; 20T 5B
        ELSE : IF (alignValue?) == 2
            inc     hl
            res     0,l
                ; 14T 3B
        ELSE : IF (alignValue?) < 256
            ld      a,(alignValue?)-1
            IFNDEF SJ_LIBRARY_USE_Z80N
                add     a,l
                rra             ; preserve carry flag for increment of H
                and     -((alignValue?)>>1)     ; clear bottom bits, Fc=0
                rla             ; restore add-carry and fix position of L bits
                ld      l,a
                adc     a,h     ; A = L + H + add-carry
                sub     l       ; A = H + add-carry (new H)
                ld      h,a
                    ; 42T 11B
            ELSE
                add     hl,a    ; add align-1 to HL
                cpl             ; bits to keep in L (and clear bottom bits)
                and     l
                ld      l,a
                    ; 27T 7B
            ENDIF
        ELSE : ASSERT 256 < (alignValue?)
            xor     a
            cp      l
            ld      l,a
            adc     a,h     ; if 0 < L, then ++H here in every case
            add     a,((alignValue?)-1)>>8
            and     -((alignValue?)>>8)
            ld      h,a
                ; 34T 9B
        ENDIF : ENDIF : ENDIF
        pop     af
    ENDM

    OPT pop
