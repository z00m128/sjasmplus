    OUTPUT "disp.bin"

    ORG $8000
phase1_start:
    PHASE $FFFF
longptr1:   DB      'A'
longptr2:   DB      'B'
longptr3:   DB      'C'
    UNPHASE
phase1_end:

normalmem:  DB      '_'

    ORG $FFFF
phase2_start:
    PHASE $FFFE
longptr4:   DB      '.D'    ; disp FFFE..FFFF, but crossing real memory $10000
longptr5:   DB      'E'     ; crossing also disp $10000
longptr6:   DB      'F'
    UNPHASE
phase2_end:

longmem:    DB      '_'

    ORG $240000
phase3_start:
    PHASE $FFFFFF
longptr7:   DB      'G'
longptr8:   DB      'H'
longptr9:   DB      'I'
    UNPHASE
phase3_end:

    ; but using the long pointers still emits the truncation warning
    ld      hl,longptr7
    dw      longptr8
    ; no warning when explicit truncation is used
    ld      hl,longptr7&$FFFF
    dw      longptr8&$FFFF

; added: in one project the usage of `DS 0` did uncover bug truncating longptr addresses back to 16b, fixed in v1.18.4

    ORG $35000
phase4_start:
    PHASE $46000
longptrA:
        DS  0,'!'
longptrB:
    UNPHASE
phase4_end:
    ASSERT longptrA == longptrB && phase4_start == phase4_end
