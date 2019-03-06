    OUTPUT "op_00_3F.bin"

    nop
    ld      bc,$4444
    ld      (bc),a
    inc     bc
    inc     b
    dec     b
    ld      b,$44
    rlca
    ex      af,af'
    add     hl,bc
    ld      a,(bc)
    dec     bc
    inc     c
    dec     c
    ld      c,$44
    rrca
    djnz    $+2+$44
    ld      de,$4444
    ld      (de),a
    inc     de
    inc     d
    dec     d
    ld      d,$44
    rla
    jr      $+2+$44
    add     hl,de
    ld      a,(de)
    dec     de
    inc     e
    dec     e
    ld      e,$44
    rra
    jr      nz,$+2+$44
    ld      hl,$4444
    ld      ($4444),hl
    inc     hl
    inc     h
    dec     h
    ld      h,$44
    daa
    jr      z,$+2+$44
    add     hl,hl
    ld      hl,($4444)
    dec     hl
    inc     l
    dec     l
    ld      l,$44
    cpl
    jr      nc,$+2+$44
    ld      sp,$4444
    ld      ($4444),a
    inc     sp
    inc     (hl)
    dec     (hl)
    ld      (hl),$44
    scf
    jr      c,$+2+$44
    add     hl,sp
    ld      a,($4444)
    dec     sp
    inc     a
    dec     a
    ld      a,$44
    ccf
