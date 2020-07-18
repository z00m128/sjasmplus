    OPT --zxnext --syntax=abfw : ORG $1234

    RELOCATE_START

    ASSERT 2 * relocate_count == relocate_size
    ASSERT 12 == relocate_count
    dw      relocate_count
    dw      relocate_size

reloc1:
    ; generate two relocation records:
    ld      hl,reloc1,,bc,reloc2-reloc1,,de,reloc1+5,,sp,absolute1
    jp      reloc1,,reloc2-reloc1,,reloc1+5,,absolute1
    call    reloc1,,reloc2-reloc1,,reloc1+5,,absolute1
    add     hl,reloc1,,bc,reloc2-reloc1,,de,reloc1+5,,hl,absolute1  ; Z80N extras
    ld      hl,(reloc1),,bc,(reloc2-reloc1),,de,(reloc1+5),,sp,(absolute1)
    ld      (reloc1),hl,,(reloc2-reloc1),bc,,(reloc1+5),de,,(absolute1),sp

reloc2:

    RELOCATE_END

absolute1:

    RELOCATE_TABLE
    ; 39 12 ($1239) 3F 12 ($123F)   ; ld r16,imm16
    ; 45 12 ($1245) 4B 12 ($124B)   ; jp
    ; 51 12 ($1251) 57 12 ($1257)   ; call
    ; 5E 12 ($125E) 66 12 ($1266)   ; add r16,imm16
    ; 6D 12 ($126D) 75 12 ($1275)   ; ld r16,(mem16)
    ; 7C 12 ($127C) 84 12 ($1284)   ; ld (mem16),r16

    ASSERT 0 == __ERRORS__
    ASSERT 0 == __WARNINGS__
