    ORG $1000
    RELOCATE_START
    ASSERT 2 * relocate_count == relocate_size
    ASSERT 2 == relocate_count
    dw      relocate_count
    dw      relocate_size

reloc1:
    ld      hl,reloc1           ; to be relocated
    ld      de,reloc2           ; to be relocated
    ld      bc,reloc2-reloc1    ; not affected by relocation
    ld      sp,absolute1        ; not affected by relocation
    ld      hl,reloc2*2         ; affected but not relocated (invalid difference) (warning)
    ld      hl,reloc2*2         ; reldiverts-ok ; warning suppressed

reloc2:
    RELOCATE_END

; no relocation area (no warnings, no relocation data)
    ORG $17DC
absolute1:
    ld      hl,reloc1
    ld      de,reloc2
    ld      bc,reloc2-reloc1
    ld      sp,absolute1
    ld      hl,reloc2*2

    RELOCATE_TABLE

    ASSERT 0 == __ERRORS__
    ASSERT 1 == __WARNINGS__
