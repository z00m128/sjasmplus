    OUTPUT "op_00_3F.bin"

    nop
    ld      bc,$4241
    ld      (bc),a
    inc     bc
    inc     b
    dec     b
    ld      b,$43
    rlca
    add     hl,bc
    ld      a,(bc)
    dec     bc
    inc     c
    dec     c
    ld      c,$43
    rrca
    ld      de,$4241
    ld      (de),a
    inc     de
    inc     d
    dec     d
    ld      d,$43
    rla
    add     hl,de
    ld      a,(de)
    dec     de
    inc     e
    dec     e
    ld      e,$43
    rra
    ld      hl,$4241
    ld      ($4241),hl
    inc     hl
    inc     h
    dec     h
    ld      h,$43
    daa
    add     hl,hl
    ld      hl,($4241)
    dec     hl
    inc     l
    dec     l
    ld      l,$43
    cpl
    ld      sp,$4241
    ld      ($4241),a
    inc     sp
    inc     (hl)
    dec     (hl)
    ld      (hl),$43
    scf
    add     hl,sp
    ld      a,($4241)
    dec     sp
    inc     a
    dec     a
    ld      a,$43
    ccf

    ; illegal on i8080
    ex      af,af'
    djnz    $
    jr      $
    jr      nz,$
    jr      z,$
    jr      nc,$
    jr      c,$
