    OUTPUT "op_00_3F.bin"

    nop
    ld      bc,$4241
    ld      (bc),a
    inc     bc
    inc     b
    dec     b
    ld      b,$43
    rlca
    ;; 08 = ld (a16),sp
    add     hl,bc
    ld      a,(bc)
    dec     bc
    inc     c
    dec     c
    ld      c,$43
    rrca
    ;; 10 = stop
    ld      de,$4241
    ld      (de),a
    inc     de
    inc     d
    dec     d
    ld      d,$43
    rla
    jr      $+2+$44
    add     hl,de
    ld      a,(de)
    dec     de
    inc     e
    dec     e
    ld      e,$43
    rra
    jr      nz,$+2+$44
    ld      hl,$4241
    ;; 22 = ld (hl+),a
    inc     hl
    inc     h
    dec     h
    ld      h,$43
    daa
    jr      z,$+2+$44
    add     hl,hl
    ;; 2A = ld a,(hl+)
    dec     hl
    inc     l
    dec     l
    ld      l,$43
    cpl
    jr      nc,$+2+$44
    ld      sp,$4241
    ;; 32 = ld (hl-),a
    inc     sp
    inc     (hl)
    dec     (hl)
    ld      (hl),$43
    scf
    jr      c,$+2+$44
    add     hl,sp
    ;; 3A = ld a,(hl-)
    dec     sp
    inc     a
    dec     a
    ld      a,$43
    ccf

    ; illegal on LR35902
    ex      af,af'
    djnz    $
    ld      ($4241),hl
    ld      hl,($4241)

    ; different opcode on LR35902
    ld      ($4241),a       ; EA
    ld      a,($4241)       ; FA
