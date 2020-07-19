
; first relocation block
    RELOCATE_START

    ORG $1000

    ASSERT 2 * relocate_count == relocate_size
    ASSERT 4 == relocate_count
    dw      relocate_count
    dw      relocate_size

reloc1:
    ld      hl,reloc1           ; to be relocated
    ld      de,reloc2           ; to be relocated
    ld      bc,reloc2-reloc1
    ld      sp,absolute1

    RELOCATE_END

; no relocation area
    ORG $17DC
absolute1:
    ld      hl,reloc1
    ld      de,reloc2
    ld      bc,reloc2-reloc1
    ld      sp,absolute1

; second relocation block
    RELOCATE_START

    ORG $2000

    ld      hl,reloc1           ; to be relocated
    ld      de,reloc2           ; to be relocated
    ld      bc,reloc2-reloc1
    ld      sp,absolute1
reloc2:

    RELOCATE_TABLE

    RELOCATE_END

    ASSERT 0 == __ERRORS__
    ASSERT 0 == __WARNINGS__
