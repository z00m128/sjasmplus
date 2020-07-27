    ORG $1000
    RELOCATE_START
    ASSERT 2 * relocate_count == relocate_size
    ASSERT 1 == relocate_count
    dw      relocate_count
    dw      relocate_size

reloc1:

equRel      EQU     reloc1 + $0203
equNoRel    EQU     reloc2 - reloc1
equAbs      EQU     absolute1
equNoRel2   EQU     reloc1 * 3  ; can't be easily relocated by "+offset" - silent drop of flag

    ld      hl,equRel           ; to be relocated
    ld      de,equNoRel         ; not affected by relocation
    ld      bc,equAbs           ; not affected by relocation
    ld      hl,equRel*2         ; affected but not relocated (invalid difference) (warning)
    ld      de,equRel*2         ; ok ; suppressed warning
    ld      bc,equNoRel2        ; not affected by relocation

reloc2:
    RELOCATE_END

; no relocation area (no warnings, no relocation data)
    ORG $17DC
absolute1:
    ld      hl,equRel
    ld      de,equNoRel
    ld      bc,equAbs
    ld      hl,equRel*2
    ld      bc,equNoRel2

    RELOCATE_TABLE

    ASSERT 0 == __ERRORS__
    ASSERT 1 == __WARNINGS__
