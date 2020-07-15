    ORG $1000

    RELOCATE_START

    ASSERT 2 * relocate_count == relocate_size
    ASSERT 38 == relocate_count
    dw      relocate_count
    dw      relocate_size

jr_jp_call:                     ; usage of this label should trigger relocation
    ; relative jumps don't need relocation
    jr      1 + jr_jp_call + 1
    jr      nz,1 + jr_jp_call + 1
    jr      z,1 + jr_jp_call + 1
    jr      nc,1 + jr_jp_call + 1
    jr      c,1 + jr_jp_call + 1
    djnz    1 + jr_jp_call + 1
    ; absolute jumps need relocation
    jp      nz,1 + jr_jp_call + 1
    jp      1 + jr_jp_call + 1
    jp      z,1 + jr_jp_call + 1
    jp      nc,1 + jr_jp_call + 1
    jp      c,1 + jr_jp_call + 1
    jp      po,1 + jr_jp_call + 1
    jp      pe,1 + jr_jp_call + 1
    jp      p,1 + jr_jp_call + 1
    jp      m,1 + jr_jp_call + 1
    ; calls need relocation
    call    nz,1 + jr_jp_call + 1
    call    z,1 + jr_jp_call + 1
    call    1 + jr_jp_call + 1
    call    nc,1 + jr_jp_call + 1
    call    c,1 + jr_jp_call + 1
    call    po,1 + jr_jp_call + 1
    call    pe,1 + jr_jp_call + 1
    call    p,1 + jr_jp_call + 1
    call    m,1 + jr_jp_call + 1

ld_a:
    ld      a,high ld_a     ; warning
    ld      a,(ld_a)
    ld      (ld_a),a
ld_r8:                      ; warning all
    ld      b,high ld_r8
    ld      c,high ld_r8
    ld      d,high ld_r8
    ld      e,high ld_r8
    ld      h,high ld_r8
    ld      l,high ld_r8
    ld      ixh,high ld_r8
    ld      ixl,high ld_r8
    ld      iyh,high ld_r8
    ld      iyl,high ld_r8
ld_r16:
    ld      bc,ld_r16
    ld      de,ld_r16
    ld      hl,ld_r16
    ld      ix,ld_r16
    ld      iy,ld_r16
    ld      sp,ld_r16
    ld      bc,(ld_r16)
    ld      de,(ld_r16)
    ld      hl,(ld_r16)
    ld      ix,(ld_r16)
    ld      iy,(ld_r16)
    ld      sp,(ld_r16)
    ld      (ld_r16),bc
    ld      (ld_r16),de
    ld      (ld_r16),hl
    ld      (ld_r16),ix
    ld      (ld_r16),iy
    ld      (ld_r16),sp
ld_extras:                  ; warning all
    ld      (hl),high ld_extras
    ld      (ix+high ld_extras),123
    ld      (ix+123),high ld_extras
    ld      (iy+high ld_extras),123
    ld      (iy+123),high ld_extras
ld_ixy_r8:                  ; warning all
    ld      b,(ix+high ld_ixy_r8)
    ld      c,(ix+high ld_ixy_r8)
    ld      d,(ix+high ld_ixy_r8)
    ld      e,(ix+high ld_ixy_r8)
    ld      h,(ix+high ld_ixy_r8)
    ld      l,(ix+high ld_ixy_r8)
    ld      a,(ix+high ld_ixy_r8)

    ld      b,(iy+high ld_ixy_r8)
    ld      c,(iy+high ld_ixy_r8)
    ld      d,(iy+high ld_ixy_r8)
    ld      e,(iy+high ld_ixy_r8)
    ld      h,(iy+high ld_ixy_r8)
    ld      l,(iy+high ld_ixy_r8)
    ld      a,(iy+high ld_ixy_r8)

    ld      (ix+high ld_ixy_r8),b
    ld      (ix+high ld_ixy_r8),c
    ld      (ix+high ld_ixy_r8),d
    ld      (ix+high ld_ixy_r8),e
    ld      (ix+high ld_ixy_r8),h
    ld      (ix+high ld_ixy_r8),l
    ld      (ix+high ld_ixy_r8),a

    ld      (iy+high ld_ixy_r8),b
    ld      (iy+high ld_ixy_r8),c
    ld      (iy+high ld_ixy_r8),d
    ld      (iy+high ld_ixy_r8),e
    ld      (iy+high ld_ixy_r8),h
    ld      (iy+high ld_ixy_r8),l
    ld      (iy+high ld_ixy_r8),a

alu_imm8:                   ; warning all
    add     a,high alu_imm8
    adc     a,high alu_imm8
    sub     high alu_imm8
    sbc     a,high alu_imm8
    and     high alu_imm8
    xor     high alu_imm8
    or      high alu_imm8
    cp      high alu_imm8

imm8_extras:                ; warning all
    out     (high imm8_extras),a
    in      a,(high imm8_extras)

alu_ixy:                    ; warning all
    add     a,(ix+high alu_ixy)
    adc     a,(ix+high alu_ixy)
    sub     (ix+high alu_ixy)
    sbc     a,(ix+high alu_ixy)
    and     (ix+high alu_ixy)
    xor     (ix+high alu_ixy)
    or      (ix+high alu_ixy)
    cp      (ix+high alu_ixy)
    add     a,(iy+high alu_ixy)
    adc     a,(iy+high alu_ixy)
    sub     (iy+high alu_ixy)
    sbc     a,(iy+high alu_ixy)
    and     (iy+high alu_ixy)
    xor     (iy+high alu_ixy)
    or      (iy+high alu_ixy)
    cp      (iy+high alu_ixy)

ixy_extras:                 ; warning all
    inc     (ix+high ixy_extras)
    dec     (ix+high ixy_extras)
    inc     (iy+high ixy_extras)
    dec     (iy+high ixy_extras)

bit_imm8:                   ; warning all
    bit     bit_imm8&7,b
    bit     bit_imm8&7,c
    bit     bit_imm8&7,d
    bit     bit_imm8&7,e
    bit     bit_imm8&7,h
    bit     bit_imm8&7,l
    bit     bit_imm8&7,(hl)
    bit     bit_imm8&7,a
    res     bit_imm8&7,b
    res     bit_imm8&7,c
    res     bit_imm8&7,d
    res     bit_imm8&7,e
    res     bit_imm8&7,h
    res     bit_imm8&7,l
    res     bit_imm8&7,(hl)
    res     bit_imm8&7,a
    set     bit_imm8&7,b
    set     bit_imm8&7,c
    set     bit_imm8&7,d
    set     bit_imm8&7,e
    set     bit_imm8&7,h
    set     bit_imm8&7,l
    set     bit_imm8&7,(hl)
    set     bit_imm8&7,a

ixy_bits:                   ; warning all
    ; IX (long list it is...)
    rlc     (ix+high ixy_bits),b
    rlc     (ix+high ixy_bits),c
    rlc     (ix+high ixy_bits),d
    rlc     (ix+high ixy_bits),e
    rlc     (ix+high ixy_bits),h
    rlc     (ix+high ixy_bits),l
    rlc     (ix+high ixy_bits)
    rlc     (ix+high ixy_bits),a
    rrc     (ix+high ixy_bits),b
    rrc     (ix+high ixy_bits),c
    rrc     (ix+high ixy_bits),d
    rrc     (ix+high ixy_bits),e
    rrc     (ix+high ixy_bits),h
    rrc     (ix+high ixy_bits),l
    rrc     (ix+high ixy_bits)
    rrc     (ix+high ixy_bits),a
    rl      (ix+high ixy_bits),b
    rl      (ix+high ixy_bits),c
    rl      (ix+high ixy_bits),d
    rl      (ix+high ixy_bits),e
    rl      (ix+high ixy_bits),h
    rl      (ix+high ixy_bits),l
    rl      (ix+high ixy_bits)
    rl      (ix+high ixy_bits),a
    rr      (ix+high ixy_bits),b
    rr      (ix+high ixy_bits),c
    rr      (ix+high ixy_bits),d
    rr      (ix+high ixy_bits),e
    rr      (ix+high ixy_bits),h
    rr      (ix+high ixy_bits),l
    rr      (ix+high ixy_bits)
    rr      (ix+high ixy_bits),a
    sla     (ix+high ixy_bits),b
    sla     (ix+high ixy_bits),c
    sla     (ix+high ixy_bits),d
    sla     (ix+high ixy_bits),e
    sla     (ix+high ixy_bits),h
    sla     (ix+high ixy_bits),l
    sla     (ix+high ixy_bits)
    sla     (ix+high ixy_bits),a
    sra     (ix+high ixy_bits),b
    sra     (ix+high ixy_bits),c
    sra     (ix+high ixy_bits),d
    sra     (ix+high ixy_bits),e
    sra     (ix+high ixy_bits),h
    sra     (ix+high ixy_bits),l
    sra     (ix+high ixy_bits)
    sra     (ix+high ixy_bits),a
    sli     (ix+high ixy_bits),b
    sli     (ix+high ixy_bits),c
    sli     (ix+high ixy_bits),d
    sli     (ix+high ixy_bits),e
    sli     (ix+high ixy_bits),h
    sli     (ix+high ixy_bits),l
    sli     (ix+high ixy_bits)
    sli     (ix+high ixy_bits),a
    srl     (ix+high ixy_bits),b
    srl     (ix+high ixy_bits),c
    srl     (ix+high ixy_bits),d
    srl     (ix+high ixy_bits),e
    srl     (ix+high ixy_bits),h
    srl     (ix+high ixy_bits),l
    srl     (ix+high ixy_bits)
    srl     (ix+high ixy_bits),a

    bit     ixy_bits&7,(ix)
    res     ixy_bits&7,(ix),b
    res     ixy_bits&7,(ix),c
    res     ixy_bits&7,(ix),d
    res     ixy_bits&7,(ix),e
    res     ixy_bits&7,(ix),h
    res     ixy_bits&7,(ix),l
    res     ixy_bits&7,(ix)
    res     ixy_bits&7,(ix),a
    set     ixy_bits&7,(ix),b
    set     ixy_bits&7,(ix),c
    set     ixy_bits&7,(ix),d
    set     ixy_bits&7,(ix),e
    set     ixy_bits&7,(ix),h
    set     ixy_bits&7,(ix),l
    set     ixy_bits&7,(ix)
    set     ixy_bits&7,(ix),a

    bit     0,(ix+high ixy_bits)
    bit     1,(ix+high ixy_bits)
    bit     2,(ix+high ixy_bits)
    bit     3,(ix+high ixy_bits)
    bit     4,(ix+high ixy_bits)
    bit     5,(ix+high ixy_bits)
    bit     6,(ix+high ixy_bits)
    bit     7,(ix+high ixy_bits)
    res     0,(ix+high ixy_bits)
    res     1,(ix+high ixy_bits)
    res     2,(ix+high ixy_bits)
    res     3,(ix+high ixy_bits)
    res     4,(ix+high ixy_bits)
    res     5,(ix+high ixy_bits)
    res     6,(ix+high ixy_bits)
    res     7,(ix+high ixy_bits)
    set     0,(ix+high ixy_bits)
    set     1,(ix+high ixy_bits)
    set     2,(ix+high ixy_bits)
    set     3,(ix+high ixy_bits)
    set     4,(ix+high ixy_bits)
    set     5,(ix+high ixy_bits)
    set     6,(ix+high ixy_bits)
    set     7,(ix+high ixy_bits)

    res     0,(ix+high ixy_bits),b
    res     1,(ix+high ixy_bits),b
    res     2,(ix+high ixy_bits),b
    res     3,(ix+high ixy_bits),b
    res     4,(ix+high ixy_bits),b
    res     5,(ix+high ixy_bits),b
    res     6,(ix+high ixy_bits),b
    res     7,(ix+high ixy_bits),b
    set     0,(ix+high ixy_bits),b
    set     1,(ix+high ixy_bits),b
    set     2,(ix+high ixy_bits),b
    set     3,(ix+high ixy_bits),b
    set     4,(ix+high ixy_bits),b
    set     5,(ix+high ixy_bits),b
    set     6,(ix+high ixy_bits),b
    set     7,(ix+high ixy_bits),b

    res     0,(ix+high ixy_bits),c
    res     1,(ix+high ixy_bits),c
    res     2,(ix+high ixy_bits),c
    res     3,(ix+high ixy_bits),c
    res     4,(ix+high ixy_bits),c
    res     5,(ix+high ixy_bits),c
    res     6,(ix+high ixy_bits),c
    res     7,(ix+high ixy_bits),c
    set     0,(ix+high ixy_bits),c
    set     1,(ix+high ixy_bits),c
    set     2,(ix+high ixy_bits),c
    set     3,(ix+high ixy_bits),c
    set     4,(ix+high ixy_bits),c
    set     5,(ix+high ixy_bits),c
    set     6,(ix+high ixy_bits),c
    set     7,(ix+high ixy_bits),c

    res     0,(ix+high ixy_bits),d
    res     1,(ix+high ixy_bits),d
    res     2,(ix+high ixy_bits),d
    res     3,(ix+high ixy_bits),d
    res     4,(ix+high ixy_bits),d
    res     5,(ix+high ixy_bits),d
    res     6,(ix+high ixy_bits),d
    res     7,(ix+high ixy_bits),d
    set     0,(ix+high ixy_bits),d
    set     1,(ix+high ixy_bits),d
    set     2,(ix+high ixy_bits),d
    set     3,(ix+high ixy_bits),d
    set     4,(ix+high ixy_bits),d
    set     5,(ix+high ixy_bits),d
    set     6,(ix+high ixy_bits),d
    set     7,(ix+high ixy_bits),d

    res     0,(ix+high ixy_bits),e
    res     1,(ix+high ixy_bits),e
    res     2,(ix+high ixy_bits),e
    res     3,(ix+high ixy_bits),e
    res     4,(ix+high ixy_bits),e
    res     5,(ix+high ixy_bits),e
    res     6,(ix+high ixy_bits),e
    res     7,(ix+high ixy_bits),e
    set     0,(ix+high ixy_bits),e
    set     1,(ix+high ixy_bits),e
    set     2,(ix+high ixy_bits),e
    set     3,(ix+high ixy_bits),e
    set     4,(ix+high ixy_bits),e
    set     5,(ix+high ixy_bits),e
    set     6,(ix+high ixy_bits),e
    set     7,(ix+high ixy_bits),e

    res     0,(ix+high ixy_bits),h
    res     1,(ix+high ixy_bits),h
    res     2,(ix+high ixy_bits),h
    res     3,(ix+high ixy_bits),h
    res     4,(ix+high ixy_bits),h
    res     5,(ix+high ixy_bits),h
    res     6,(ix+high ixy_bits),h
    res     7,(ix+high ixy_bits),h
    set     0,(ix+high ixy_bits),h
    set     1,(ix+high ixy_bits),h
    set     2,(ix+high ixy_bits),h
    set     3,(ix+high ixy_bits),h
    set     4,(ix+high ixy_bits),h
    set     5,(ix+high ixy_bits),h
    set     6,(ix+high ixy_bits),h
    set     7,(ix+high ixy_bits),h

    res     0,(ix+high ixy_bits),l
    res     1,(ix+high ixy_bits),l
    res     2,(ix+high ixy_bits),l
    res     3,(ix+high ixy_bits),l
    res     4,(ix+high ixy_bits),l
    res     5,(ix+high ixy_bits),l
    res     6,(ix+high ixy_bits),l
    res     7,(ix+high ixy_bits),l
    set     0,(ix+high ixy_bits),l
    set     1,(ix+high ixy_bits),l
    set     2,(ix+high ixy_bits),l
    set     3,(ix+high ixy_bits),l
    set     4,(ix+high ixy_bits),l
    set     5,(ix+high ixy_bits),l
    set     6,(ix+high ixy_bits),l
    set     7,(ix+high ixy_bits),l

    res     0,(ix+high ixy_bits),a
    res     1,(ix+high ixy_bits),a
    res     2,(ix+high ixy_bits),a
    res     3,(ix+high ixy_bits),a
    res     4,(ix+high ixy_bits),a
    res     5,(ix+high ixy_bits),a
    res     6,(ix+high ixy_bits),a
    res     7,(ix+high ixy_bits),a
    set     0,(ix+high ixy_bits),a
    set     1,(ix+high ixy_bits),a
    set     2,(ix+high ixy_bits),a
    set     3,(ix+high ixy_bits),a
    set     4,(ix+high ixy_bits),a
    set     5,(ix+high ixy_bits),a
    set     6,(ix+high ixy_bits),a
    set     7,(ix+high ixy_bits),a

    ; IY (long list it is...)
    rlc     (iy+high ixy_bits),b
    rlc     (iy+high ixy_bits),c
    rlc     (iy+high ixy_bits),d
    rlc     (iy+high ixy_bits),e
    rlc     (iy+high ixy_bits),h
    rlc     (iy+high ixy_bits),l
    rlc     (iy+high ixy_bits)
    rlc     (iy+high ixy_bits),a
    rrc     (iy+high ixy_bits),b
    rrc     (iy+high ixy_bits),c
    rrc     (iy+high ixy_bits),d
    rrc     (iy+high ixy_bits),e
    rrc     (iy+high ixy_bits),h
    rrc     (iy+high ixy_bits),l
    rrc     (iy+high ixy_bits)
    rrc     (iy+high ixy_bits),a
    rl      (iy+high ixy_bits),b
    rl      (iy+high ixy_bits),c
    rl      (iy+high ixy_bits),d
    rl      (iy+high ixy_bits),e
    rl      (iy+high ixy_bits),h
    rl      (iy+high ixy_bits),l
    rl      (iy+high ixy_bits)
    rl      (iy+high ixy_bits),a
    rr      (iy+high ixy_bits),b
    rr      (iy+high ixy_bits),c
    rr      (iy+high ixy_bits),d
    rr      (iy+high ixy_bits),e
    rr      (iy+high ixy_bits),h
    rr      (iy+high ixy_bits),l
    rr      (iy+high ixy_bits)
    rr      (iy+high ixy_bits),a
    sla     (iy+high ixy_bits),b
    sla     (iy+high ixy_bits),c
    sla     (iy+high ixy_bits),d
    sla     (iy+high ixy_bits),e
    sla     (iy+high ixy_bits),h
    sla     (iy+high ixy_bits),l
    sla     (iy+high ixy_bits)
    sla     (iy+high ixy_bits),a
    sra     (iy+high ixy_bits),b
    sra     (iy+high ixy_bits),c
    sra     (iy+high ixy_bits),d
    sra     (iy+high ixy_bits),e
    sra     (iy+high ixy_bits),h
    sra     (iy+high ixy_bits),l
    sra     (iy+high ixy_bits)
    sra     (iy+high ixy_bits),a
    sli     (iy+high ixy_bits),b
    sli     (iy+high ixy_bits),c
    sli     (iy+high ixy_bits),d
    sli     (iy+high ixy_bits),e
    sli     (iy+high ixy_bits),h
    sli     (iy+high ixy_bits),l
    sli     (iy+high ixy_bits)
    sli     (iy+high ixy_bits),a
    srl     (iy+high ixy_bits),b
    srl     (iy+high ixy_bits),c
    srl     (iy+high ixy_bits),d
    srl     (iy+high ixy_bits),e
    srl     (iy+high ixy_bits),h
    srl     (iy+high ixy_bits),l
    srl     (iy+high ixy_bits)
    srl     (iy+high ixy_bits),a

    bit     ixy_bits&7,(iy)
    res     ixy_bits&7,(iy),b
    res     ixy_bits&7,(iy),c
    res     ixy_bits&7,(iy),d
    res     ixy_bits&7,(iy),e
    res     ixy_bits&7,(iy),h
    res     ixy_bits&7,(iy),l
    res     ixy_bits&7,(iy)
    res     ixy_bits&7,(iy),a
    set     ixy_bits&7,(iy),b
    set     ixy_bits&7,(iy),c
    set     ixy_bits&7,(iy),d
    set     ixy_bits&7,(iy),e
    set     ixy_bits&7,(iy),h
    set     ixy_bits&7,(iy),l
    set     ixy_bits&7,(iy)
    set     ixy_bits&7,(iy),a

    bit     0,(iy+high ixy_bits)
    bit     1,(iy+high ixy_bits)
    bit     2,(iy+high ixy_bits)
    bit     3,(iy+high ixy_bits)
    bit     4,(iy+high ixy_bits)
    bit     5,(iy+high ixy_bits)
    bit     6,(iy+high ixy_bits)
    bit     7,(iy+high ixy_bits)
    res     0,(iy+high ixy_bits)
    res     1,(iy+high ixy_bits)
    res     2,(iy+high ixy_bits)
    res     3,(iy+high ixy_bits)
    res     4,(iy+high ixy_bits)
    res     5,(iy+high ixy_bits)
    res     6,(iy+high ixy_bits)
    res     7,(iy+high ixy_bits)
    set     0,(iy+high ixy_bits)
    set     1,(iy+high ixy_bits)
    set     2,(iy+high ixy_bits)
    set     3,(iy+high ixy_bits)
    set     4,(iy+high ixy_bits)
    set     5,(iy+high ixy_bits)
    set     6,(iy+high ixy_bits)
    set     7,(iy+high ixy_bits)

    res     0,(iy+high ixy_bits),b
    res     1,(iy+high ixy_bits),b
    res     2,(iy+high ixy_bits),b
    res     3,(iy+high ixy_bits),b
    res     4,(iy+high ixy_bits),b
    res     5,(iy+high ixy_bits),b
    res     6,(iy+high ixy_bits),b
    res     7,(iy+high ixy_bits),b
    set     0,(iy+high ixy_bits),b
    set     1,(iy+high ixy_bits),b
    set     2,(iy+high ixy_bits),b
    set     3,(iy+high ixy_bits),b
    set     4,(iy+high ixy_bits),b
    set     5,(iy+high ixy_bits),b
    set     6,(iy+high ixy_bits),b
    set     7,(iy+high ixy_bits),b

    res     0,(iy+high ixy_bits),c
    res     1,(iy+high ixy_bits),c
    res     2,(iy+high ixy_bits),c
    res     3,(iy+high ixy_bits),c
    res     4,(iy+high ixy_bits),c
    res     5,(iy+high ixy_bits),c
    res     6,(iy+high ixy_bits),c
    res     7,(iy+high ixy_bits),c
    set     0,(iy+high ixy_bits),c
    set     1,(iy+high ixy_bits),c
    set     2,(iy+high ixy_bits),c
    set     3,(iy+high ixy_bits),c
    set     4,(iy+high ixy_bits),c
    set     5,(iy+high ixy_bits),c
    set     6,(iy+high ixy_bits),c
    set     7,(iy+high ixy_bits),c

    res     0,(iy+high ixy_bits),d
    res     1,(iy+high ixy_bits),d
    res     2,(iy+high ixy_bits),d
    res     3,(iy+high ixy_bits),d
    res     4,(iy+high ixy_bits),d
    res     5,(iy+high ixy_bits),d
    res     6,(iy+high ixy_bits),d
    res     7,(iy+high ixy_bits),d
    set     0,(iy+high ixy_bits),d
    set     1,(iy+high ixy_bits),d
    set     2,(iy+high ixy_bits),d
    set     3,(iy+high ixy_bits),d
    set     4,(iy+high ixy_bits),d
    set     5,(iy+high ixy_bits),d
    set     6,(iy+high ixy_bits),d
    set     7,(iy+high ixy_bits),d

    res     0,(iy+high ixy_bits),e
    res     1,(iy+high ixy_bits),e
    res     2,(iy+high ixy_bits),e
    res     3,(iy+high ixy_bits),e
    res     4,(iy+high ixy_bits),e
    res     5,(iy+high ixy_bits),e
    res     6,(iy+high ixy_bits),e
    res     7,(iy+high ixy_bits),e
    set     0,(iy+high ixy_bits),e
    set     1,(iy+high ixy_bits),e
    set     2,(iy+high ixy_bits),e
    set     3,(iy+high ixy_bits),e
    set     4,(iy+high ixy_bits),e
    set     5,(iy+high ixy_bits),e
    set     6,(iy+high ixy_bits),e
    set     7,(iy+high ixy_bits),e

    res     0,(iy+high ixy_bits),h
    res     1,(iy+high ixy_bits),h
    res     2,(iy+high ixy_bits),h
    res     3,(iy+high ixy_bits),h
    res     4,(iy+high ixy_bits),h
    res     5,(iy+high ixy_bits),h
    res     6,(iy+high ixy_bits),h
    res     7,(iy+high ixy_bits),h
    set     0,(iy+high ixy_bits),h
    set     1,(iy+high ixy_bits),h
    set     2,(iy+high ixy_bits),h
    set     3,(iy+high ixy_bits),h
    set     4,(iy+high ixy_bits),h
    set     5,(iy+high ixy_bits),h
    set     6,(iy+high ixy_bits),h
    set     7,(iy+high ixy_bits),h

    res     0,(iy+high ixy_bits),l
    res     1,(iy+high ixy_bits),l
    res     2,(iy+high ixy_bits),l
    res     3,(iy+high ixy_bits),l
    res     4,(iy+high ixy_bits),l
    res     5,(iy+high ixy_bits),l
    res     6,(iy+high ixy_bits),l
    res     7,(iy+high ixy_bits),l
    set     0,(iy+high ixy_bits),l
    set     1,(iy+high ixy_bits),l
    set     2,(iy+high ixy_bits),l
    set     3,(iy+high ixy_bits),l
    set     4,(iy+high ixy_bits),l
    set     5,(iy+high ixy_bits),l
    set     6,(iy+high ixy_bits),l
    set     7,(iy+high ixy_bits),l

    res     0,(iy+high ixy_bits),a
    res     1,(iy+high ixy_bits),a
    res     2,(iy+high ixy_bits),a
    res     3,(iy+high ixy_bits),a
    res     4,(iy+high ixy_bits),a
    res     5,(iy+high ixy_bits),a
    res     6,(iy+high ixy_bits),a
    res     7,(iy+high ixy_bits),a
    set     0,(iy+high ixy_bits),a
    set     1,(iy+high ixy_bits),a
    set     2,(iy+high ixy_bits),a
    set     3,(iy+high ixy_bits),a
    set     4,(iy+high ixy_bits),a
    set     5,(iy+high ixy_bits),a
    set     6,(iy+high ixy_bits),a
    set     7,(iy+high ixy_bits),a

    RELOCATE_END

    RELOCATE_TABLE

;===================================================================================
; here comes the copy of all the instructions, but outside of relocation block
; but using the labels which are affected by relocation (this should still *NOT*
; add to the relocation table, as instructions are outside of relocation block)
; and thus this should also *NOT* warn about unstable relocation.
;===================================================================================

    ; relative jumps will be too far plus they don't need extra test
    ; absolute jumps need relocation
    jp      nz,1 + jr_jp_call + 1
    jp      1 + jr_jp_call + 1
    jp      z,1 + jr_jp_call + 1
    jp      nc,1 + jr_jp_call + 1
    jp      c,1 + jr_jp_call + 1
    jp      po,1 + jr_jp_call + 1
    jp      pe,1 + jr_jp_call + 1
    jp      p,1 + jr_jp_call + 1
    jp      m,1 + jr_jp_call + 1
    ; calls need relocation
    call    nz,1 + jr_jp_call + 1
    call    z,1 + jr_jp_call + 1
    call    1 + jr_jp_call + 1
    call    nc,1 + jr_jp_call + 1
    call    c,1 + jr_jp_call + 1
    call    po,1 + jr_jp_call + 1
    call    pe,1 + jr_jp_call + 1
    call    p,1 + jr_jp_call + 1
    call    m,1 + jr_jp_call + 1

;ld_a:
    ld      a,high ld_a     ; warning
    ld      a,(ld_a)
    ld      (ld_a),a
;ld_r8:                      ; warning all
    ld      b,high ld_r8
    ld      c,high ld_r8
    ld      d,high ld_r8
    ld      e,high ld_r8
    ld      h,high ld_r8
    ld      l,high ld_r8
    ld      ixh,high ld_r8
    ld      ixl,high ld_r8
    ld      iyh,high ld_r8
    ld      iyl,high ld_r8
;ld_r16:
    ld      bc,ld_r16
    ld      de,ld_r16
    ld      hl,ld_r16
    ld      ix,ld_r16
    ld      iy,ld_r16
    ld      sp,ld_r16
    ld      bc,(ld_r16)
    ld      de,(ld_r16)
    ld      hl,(ld_r16)
    ld      ix,(ld_r16)
    ld      iy,(ld_r16)
    ld      sp,(ld_r16)
    ld      (ld_r16),bc
    ld      (ld_r16),de
    ld      (ld_r16),hl
    ld      (ld_r16),ix
    ld      (ld_r16),iy
    ld      (ld_r16),sp
;ld_extras:                  ; warning all
    ld      (hl),high ld_extras
    ld      (ix+high ld_extras),123
    ld      (ix+123),high ld_extras
    ld      (iy+high ld_extras),123
    ld      (iy+123),high ld_extras
;ld_ixy_r8:                  ; warning all
    ld      b,(ix+high ld_ixy_r8)
    ld      c,(ix+high ld_ixy_r8)
    ld      d,(ix+high ld_ixy_r8)
    ld      e,(ix+high ld_ixy_r8)
    ld      h,(ix+high ld_ixy_r8)
    ld      l,(ix+high ld_ixy_r8)
    ld      a,(ix+high ld_ixy_r8)

    ld      b,(iy+high ld_ixy_r8)
    ld      c,(iy+high ld_ixy_r8)
    ld      d,(iy+high ld_ixy_r8)
    ld      e,(iy+high ld_ixy_r8)
    ld      h,(iy+high ld_ixy_r8)
    ld      l,(iy+high ld_ixy_r8)
    ld      a,(iy+high ld_ixy_r8)

    ld      (ix+high ld_ixy_r8),b
    ld      (ix+high ld_ixy_r8),c
    ld      (ix+high ld_ixy_r8),d
    ld      (ix+high ld_ixy_r8),e
    ld      (ix+high ld_ixy_r8),h
    ld      (ix+high ld_ixy_r8),l
    ld      (ix+high ld_ixy_r8),a

    ld      (iy+high ld_ixy_r8),b
    ld      (iy+high ld_ixy_r8),c
    ld      (iy+high ld_ixy_r8),d
    ld      (iy+high ld_ixy_r8),e
    ld      (iy+high ld_ixy_r8),h
    ld      (iy+high ld_ixy_r8),l
    ld      (iy+high ld_ixy_r8),a

;alu_imm8:                   ; warning all
    add     a,high alu_imm8
    adc     a,high alu_imm8
    sub     high alu_imm8
    sbc     a,high alu_imm8
    and     high alu_imm8
    xor     high alu_imm8
    or      high alu_imm8
    cp      high alu_imm8

;imm8_extras:                ; warning all
    out     (high imm8_extras),a
    in      a,(high imm8_extras)

;alu_ixy:                    ; warning all
    add     a,(ix+high alu_ixy)
    adc     a,(ix+high alu_ixy)
    sub     (ix+high alu_ixy)
    sbc     a,(ix+high alu_ixy)
    and     (ix+high alu_ixy)
    xor     (ix+high alu_ixy)
    or      (ix+high alu_ixy)
    cp      (ix+high alu_ixy)
    add     a,(iy+high alu_ixy)
    adc     a,(iy+high alu_ixy)
    sub     (iy+high alu_ixy)
    sbc     a,(iy+high alu_ixy)
    and     (iy+high alu_ixy)
    xor     (iy+high alu_ixy)
    or      (iy+high alu_ixy)
    cp      (iy+high alu_ixy)

;ixy_extras:                 ; warning all
    inc     (ix+high ixy_extras)
    dec     (ix+high ixy_extras)
    inc     (iy+high ixy_extras)
    dec     (iy+high ixy_extras)

;bit_imm8:                   ; warning all
    bit     bit_imm8&7,b
    bit     bit_imm8&7,c
    bit     bit_imm8&7,d
    bit     bit_imm8&7,e
    bit     bit_imm8&7,h
    bit     bit_imm8&7,l
    bit     bit_imm8&7,(hl)
    bit     bit_imm8&7,a
    res     bit_imm8&7,b
    res     bit_imm8&7,c
    res     bit_imm8&7,d
    res     bit_imm8&7,e
    res     bit_imm8&7,h
    res     bit_imm8&7,l
    res     bit_imm8&7,(hl)
    res     bit_imm8&7,a
    set     bit_imm8&7,b
    set     bit_imm8&7,c
    set     bit_imm8&7,d
    set     bit_imm8&7,e
    set     bit_imm8&7,h
    set     bit_imm8&7,l
    set     bit_imm8&7,(hl)
    set     bit_imm8&7,a

;ixy_bits:                   ; warning all
    ; IX (long list it is...)
    rlc     (ix+high ixy_bits),b
    rlc     (ix+high ixy_bits),c
    rlc     (ix+high ixy_bits),d
    rlc     (ix+high ixy_bits),e
    rlc     (ix+high ixy_bits),h
    rlc     (ix+high ixy_bits),l
    rlc     (ix+high ixy_bits)
    rlc     (ix+high ixy_bits),a
    rrc     (ix+high ixy_bits),b
    rrc     (ix+high ixy_bits),c
    rrc     (ix+high ixy_bits),d
    rrc     (ix+high ixy_bits),e
    rrc     (ix+high ixy_bits),h
    rrc     (ix+high ixy_bits),l
    rrc     (ix+high ixy_bits)
    rrc     (ix+high ixy_bits),a
    rl      (ix+high ixy_bits),b
    rl      (ix+high ixy_bits),c
    rl      (ix+high ixy_bits),d
    rl      (ix+high ixy_bits),e
    rl      (ix+high ixy_bits),h
    rl      (ix+high ixy_bits),l
    rl      (ix+high ixy_bits)
    rl      (ix+high ixy_bits),a
    rr      (ix+high ixy_bits),b
    rr      (ix+high ixy_bits),c
    rr      (ix+high ixy_bits),d
    rr      (ix+high ixy_bits),e
    rr      (ix+high ixy_bits),h
    rr      (ix+high ixy_bits),l
    rr      (ix+high ixy_bits)
    rr      (ix+high ixy_bits),a
    sla     (ix+high ixy_bits),b
    sla     (ix+high ixy_bits),c
    sla     (ix+high ixy_bits),d
    sla     (ix+high ixy_bits),e
    sla     (ix+high ixy_bits),h
    sla     (ix+high ixy_bits),l
    sla     (ix+high ixy_bits)
    sla     (ix+high ixy_bits),a
    sra     (ix+high ixy_bits),b
    sra     (ix+high ixy_bits),c
    sra     (ix+high ixy_bits),d
    sra     (ix+high ixy_bits),e
    sra     (ix+high ixy_bits),h
    sra     (ix+high ixy_bits),l
    sra     (ix+high ixy_bits)
    sra     (ix+high ixy_bits),a
    sli     (ix+high ixy_bits),b
    sli     (ix+high ixy_bits),c
    sli     (ix+high ixy_bits),d
    sli     (ix+high ixy_bits),e
    sli     (ix+high ixy_bits),h
    sli     (ix+high ixy_bits),l
    sli     (ix+high ixy_bits)
    sli     (ix+high ixy_bits),a
    srl     (ix+high ixy_bits),b
    srl     (ix+high ixy_bits),c
    srl     (ix+high ixy_bits),d
    srl     (ix+high ixy_bits),e
    srl     (ix+high ixy_bits),h
    srl     (ix+high ixy_bits),l
    srl     (ix+high ixy_bits)
    srl     (ix+high ixy_bits),a

    bit     ixy_bits&7,(ix)
    res     ixy_bits&7,(ix),b
    res     ixy_bits&7,(ix),c
    res     ixy_bits&7,(ix),d
    res     ixy_bits&7,(ix),e
    res     ixy_bits&7,(ix),h
    res     ixy_bits&7,(ix),l
    res     ixy_bits&7,(ix)
    res     ixy_bits&7,(ix),a
    set     ixy_bits&7,(ix),b
    set     ixy_bits&7,(ix),c
    set     ixy_bits&7,(ix),d
    set     ixy_bits&7,(ix),e
    set     ixy_bits&7,(ix),h
    set     ixy_bits&7,(ix),l
    set     ixy_bits&7,(ix)
    set     ixy_bits&7,(ix),a

    bit     0,(ix+high ixy_bits)
    bit     1,(ix+high ixy_bits)
    bit     2,(ix+high ixy_bits)
    bit     3,(ix+high ixy_bits)
    bit     4,(ix+high ixy_bits)
    bit     5,(ix+high ixy_bits)
    bit     6,(ix+high ixy_bits)
    bit     7,(ix+high ixy_bits)
    res     0,(ix+high ixy_bits)
    res     1,(ix+high ixy_bits)
    res     2,(ix+high ixy_bits)
    res     3,(ix+high ixy_bits)
    res     4,(ix+high ixy_bits)
    res     5,(ix+high ixy_bits)
    res     6,(ix+high ixy_bits)
    res     7,(ix+high ixy_bits)
    set     0,(ix+high ixy_bits)
    set     1,(ix+high ixy_bits)
    set     2,(ix+high ixy_bits)
    set     3,(ix+high ixy_bits)
    set     4,(ix+high ixy_bits)
    set     5,(ix+high ixy_bits)
    set     6,(ix+high ixy_bits)
    set     7,(ix+high ixy_bits)

    res     0,(ix+high ixy_bits),b
    res     1,(ix+high ixy_bits),b
    res     2,(ix+high ixy_bits),b
    res     3,(ix+high ixy_bits),b
    res     4,(ix+high ixy_bits),b
    res     5,(ix+high ixy_bits),b
    res     6,(ix+high ixy_bits),b
    res     7,(ix+high ixy_bits),b
    set     0,(ix+high ixy_bits),b
    set     1,(ix+high ixy_bits),b
    set     2,(ix+high ixy_bits),b
    set     3,(ix+high ixy_bits),b
    set     4,(ix+high ixy_bits),b
    set     5,(ix+high ixy_bits),b
    set     6,(ix+high ixy_bits),b
    set     7,(ix+high ixy_bits),b

    res     0,(ix+high ixy_bits),c
    res     1,(ix+high ixy_bits),c
    res     2,(ix+high ixy_bits),c
    res     3,(ix+high ixy_bits),c
    res     4,(ix+high ixy_bits),c
    res     5,(ix+high ixy_bits),c
    res     6,(ix+high ixy_bits),c
    res     7,(ix+high ixy_bits),c
    set     0,(ix+high ixy_bits),c
    set     1,(ix+high ixy_bits),c
    set     2,(ix+high ixy_bits),c
    set     3,(ix+high ixy_bits),c
    set     4,(ix+high ixy_bits),c
    set     5,(ix+high ixy_bits),c
    set     6,(ix+high ixy_bits),c
    set     7,(ix+high ixy_bits),c

    res     0,(ix+high ixy_bits),d
    res     1,(ix+high ixy_bits),d
    res     2,(ix+high ixy_bits),d
    res     3,(ix+high ixy_bits),d
    res     4,(ix+high ixy_bits),d
    res     5,(ix+high ixy_bits),d
    res     6,(ix+high ixy_bits),d
    res     7,(ix+high ixy_bits),d
    set     0,(ix+high ixy_bits),d
    set     1,(ix+high ixy_bits),d
    set     2,(ix+high ixy_bits),d
    set     3,(ix+high ixy_bits),d
    set     4,(ix+high ixy_bits),d
    set     5,(ix+high ixy_bits),d
    set     6,(ix+high ixy_bits),d
    set     7,(ix+high ixy_bits),d

    res     0,(ix+high ixy_bits),e
    res     1,(ix+high ixy_bits),e
    res     2,(ix+high ixy_bits),e
    res     3,(ix+high ixy_bits),e
    res     4,(ix+high ixy_bits),e
    res     5,(ix+high ixy_bits),e
    res     6,(ix+high ixy_bits),e
    res     7,(ix+high ixy_bits),e
    set     0,(ix+high ixy_bits),e
    set     1,(ix+high ixy_bits),e
    set     2,(ix+high ixy_bits),e
    set     3,(ix+high ixy_bits),e
    set     4,(ix+high ixy_bits),e
    set     5,(ix+high ixy_bits),e
    set     6,(ix+high ixy_bits),e
    set     7,(ix+high ixy_bits),e

    res     0,(ix+high ixy_bits),h
    res     1,(ix+high ixy_bits),h
    res     2,(ix+high ixy_bits),h
    res     3,(ix+high ixy_bits),h
    res     4,(ix+high ixy_bits),h
    res     5,(ix+high ixy_bits),h
    res     6,(ix+high ixy_bits),h
    res     7,(ix+high ixy_bits),h
    set     0,(ix+high ixy_bits),h
    set     1,(ix+high ixy_bits),h
    set     2,(ix+high ixy_bits),h
    set     3,(ix+high ixy_bits),h
    set     4,(ix+high ixy_bits),h
    set     5,(ix+high ixy_bits),h
    set     6,(ix+high ixy_bits),h
    set     7,(ix+high ixy_bits),h

    res     0,(ix+high ixy_bits),l
    res     1,(ix+high ixy_bits),l
    res     2,(ix+high ixy_bits),l
    res     3,(ix+high ixy_bits),l
    res     4,(ix+high ixy_bits),l
    res     5,(ix+high ixy_bits),l
    res     6,(ix+high ixy_bits),l
    res     7,(ix+high ixy_bits),l
    set     0,(ix+high ixy_bits),l
    set     1,(ix+high ixy_bits),l
    set     2,(ix+high ixy_bits),l
    set     3,(ix+high ixy_bits),l
    set     4,(ix+high ixy_bits),l
    set     5,(ix+high ixy_bits),l
    set     6,(ix+high ixy_bits),l
    set     7,(ix+high ixy_bits),l

    res     0,(ix+high ixy_bits),a
    res     1,(ix+high ixy_bits),a
    res     2,(ix+high ixy_bits),a
    res     3,(ix+high ixy_bits),a
    res     4,(ix+high ixy_bits),a
    res     5,(ix+high ixy_bits),a
    res     6,(ix+high ixy_bits),a
    res     7,(ix+high ixy_bits),a
    set     0,(ix+high ixy_bits),a
    set     1,(ix+high ixy_bits),a
    set     2,(ix+high ixy_bits),a
    set     3,(ix+high ixy_bits),a
    set     4,(ix+high ixy_bits),a
    set     5,(ix+high ixy_bits),a
    set     6,(ix+high ixy_bits),a
    set     7,(ix+high ixy_bits),a

    ; IY (long list it is...)
    rlc     (iy+high ixy_bits),b
    rlc     (iy+high ixy_bits),c
    rlc     (iy+high ixy_bits),d
    rlc     (iy+high ixy_bits),e
    rlc     (iy+high ixy_bits),h
    rlc     (iy+high ixy_bits),l
    rlc     (iy+high ixy_bits)
    rlc     (iy+high ixy_bits),a
    rrc     (iy+high ixy_bits),b
    rrc     (iy+high ixy_bits),c
    rrc     (iy+high ixy_bits),d
    rrc     (iy+high ixy_bits),e
    rrc     (iy+high ixy_bits),h
    rrc     (iy+high ixy_bits),l
    rrc     (iy+high ixy_bits)
    rrc     (iy+high ixy_bits),a
    rl      (iy+high ixy_bits),b
    rl      (iy+high ixy_bits),c
    rl      (iy+high ixy_bits),d
    rl      (iy+high ixy_bits),e
    rl      (iy+high ixy_bits),h
    rl      (iy+high ixy_bits),l
    rl      (iy+high ixy_bits)
    rl      (iy+high ixy_bits),a
    rr      (iy+high ixy_bits),b
    rr      (iy+high ixy_bits),c
    rr      (iy+high ixy_bits),d
    rr      (iy+high ixy_bits),e
    rr      (iy+high ixy_bits),h
    rr      (iy+high ixy_bits),l
    rr      (iy+high ixy_bits)
    rr      (iy+high ixy_bits),a
    sla     (iy+high ixy_bits),b
    sla     (iy+high ixy_bits),c
    sla     (iy+high ixy_bits),d
    sla     (iy+high ixy_bits),e
    sla     (iy+high ixy_bits),h
    sla     (iy+high ixy_bits),l
    sla     (iy+high ixy_bits)
    sla     (iy+high ixy_bits),a
    sra     (iy+high ixy_bits),b
    sra     (iy+high ixy_bits),c
    sra     (iy+high ixy_bits),d
    sra     (iy+high ixy_bits),e
    sra     (iy+high ixy_bits),h
    sra     (iy+high ixy_bits),l
    sra     (iy+high ixy_bits)
    sra     (iy+high ixy_bits),a
    sli     (iy+high ixy_bits),b
    sli     (iy+high ixy_bits),c
    sli     (iy+high ixy_bits),d
    sli     (iy+high ixy_bits),e
    sli     (iy+high ixy_bits),h
    sli     (iy+high ixy_bits),l
    sli     (iy+high ixy_bits)
    sli     (iy+high ixy_bits),a
    srl     (iy+high ixy_bits),b
    srl     (iy+high ixy_bits),c
    srl     (iy+high ixy_bits),d
    srl     (iy+high ixy_bits),e
    srl     (iy+high ixy_bits),h
    srl     (iy+high ixy_bits),l
    srl     (iy+high ixy_bits)
    srl     (iy+high ixy_bits),a

    bit     ixy_bits&7,(iy)
    res     ixy_bits&7,(iy),b
    res     ixy_bits&7,(iy),c
    res     ixy_bits&7,(iy),d
    res     ixy_bits&7,(iy),e
    res     ixy_bits&7,(iy),h
    res     ixy_bits&7,(iy),l
    res     ixy_bits&7,(iy)
    res     ixy_bits&7,(iy),a
    set     ixy_bits&7,(iy),b
    set     ixy_bits&7,(iy),c
    set     ixy_bits&7,(iy),d
    set     ixy_bits&7,(iy),e
    set     ixy_bits&7,(iy),h
    set     ixy_bits&7,(iy),l
    set     ixy_bits&7,(iy)
    set     ixy_bits&7,(iy),a

    bit     0,(iy+high ixy_bits)
    bit     1,(iy+high ixy_bits)
    bit     2,(iy+high ixy_bits)
    bit     3,(iy+high ixy_bits)
    bit     4,(iy+high ixy_bits)
    bit     5,(iy+high ixy_bits)
    bit     6,(iy+high ixy_bits)
    bit     7,(iy+high ixy_bits)
    res     0,(iy+high ixy_bits)
    res     1,(iy+high ixy_bits)
    res     2,(iy+high ixy_bits)
    res     3,(iy+high ixy_bits)
    res     4,(iy+high ixy_bits)
    res     5,(iy+high ixy_bits)
    res     6,(iy+high ixy_bits)
    res     7,(iy+high ixy_bits)
    set     0,(iy+high ixy_bits)
    set     1,(iy+high ixy_bits)
    set     2,(iy+high ixy_bits)
    set     3,(iy+high ixy_bits)
    set     4,(iy+high ixy_bits)
    set     5,(iy+high ixy_bits)
    set     6,(iy+high ixy_bits)
    set     7,(iy+high ixy_bits)

    res     0,(iy+high ixy_bits),b
    res     1,(iy+high ixy_bits),b
    res     2,(iy+high ixy_bits),b
    res     3,(iy+high ixy_bits),b
    res     4,(iy+high ixy_bits),b
    res     5,(iy+high ixy_bits),b
    res     6,(iy+high ixy_bits),b
    res     7,(iy+high ixy_bits),b
    set     0,(iy+high ixy_bits),b
    set     1,(iy+high ixy_bits),b
    set     2,(iy+high ixy_bits),b
    set     3,(iy+high ixy_bits),b
    set     4,(iy+high ixy_bits),b
    set     5,(iy+high ixy_bits),b
    set     6,(iy+high ixy_bits),b
    set     7,(iy+high ixy_bits),b

    res     0,(iy+high ixy_bits),c
    res     1,(iy+high ixy_bits),c
    res     2,(iy+high ixy_bits),c
    res     3,(iy+high ixy_bits),c
    res     4,(iy+high ixy_bits),c
    res     5,(iy+high ixy_bits),c
    res     6,(iy+high ixy_bits),c
    res     7,(iy+high ixy_bits),c
    set     0,(iy+high ixy_bits),c
    set     1,(iy+high ixy_bits),c
    set     2,(iy+high ixy_bits),c
    set     3,(iy+high ixy_bits),c
    set     4,(iy+high ixy_bits),c
    set     5,(iy+high ixy_bits),c
    set     6,(iy+high ixy_bits),c
    set     7,(iy+high ixy_bits),c

    res     0,(iy+high ixy_bits),d
    res     1,(iy+high ixy_bits),d
    res     2,(iy+high ixy_bits),d
    res     3,(iy+high ixy_bits),d
    res     4,(iy+high ixy_bits),d
    res     5,(iy+high ixy_bits),d
    res     6,(iy+high ixy_bits),d
    res     7,(iy+high ixy_bits),d
    set     0,(iy+high ixy_bits),d
    set     1,(iy+high ixy_bits),d
    set     2,(iy+high ixy_bits),d
    set     3,(iy+high ixy_bits),d
    set     4,(iy+high ixy_bits),d
    set     5,(iy+high ixy_bits),d
    set     6,(iy+high ixy_bits),d
    set     7,(iy+high ixy_bits),d

    res     0,(iy+high ixy_bits),e
    res     1,(iy+high ixy_bits),e
    res     2,(iy+high ixy_bits),e
    res     3,(iy+high ixy_bits),e
    res     4,(iy+high ixy_bits),e
    res     5,(iy+high ixy_bits),e
    res     6,(iy+high ixy_bits),e
    res     7,(iy+high ixy_bits),e
    set     0,(iy+high ixy_bits),e
    set     1,(iy+high ixy_bits),e
    set     2,(iy+high ixy_bits),e
    set     3,(iy+high ixy_bits),e
    set     4,(iy+high ixy_bits),e
    set     5,(iy+high ixy_bits),e
    set     6,(iy+high ixy_bits),e
    set     7,(iy+high ixy_bits),e

    res     0,(iy+high ixy_bits),h
    res     1,(iy+high ixy_bits),h
    res     2,(iy+high ixy_bits),h
    res     3,(iy+high ixy_bits),h
    res     4,(iy+high ixy_bits),h
    res     5,(iy+high ixy_bits),h
    res     6,(iy+high ixy_bits),h
    res     7,(iy+high ixy_bits),h
    set     0,(iy+high ixy_bits),h
    set     1,(iy+high ixy_bits),h
    set     2,(iy+high ixy_bits),h
    set     3,(iy+high ixy_bits),h
    set     4,(iy+high ixy_bits),h
    set     5,(iy+high ixy_bits),h
    set     6,(iy+high ixy_bits),h
    set     7,(iy+high ixy_bits),h

    res     0,(iy+high ixy_bits),l
    res     1,(iy+high ixy_bits),l
    res     2,(iy+high ixy_bits),l
    res     3,(iy+high ixy_bits),l
    res     4,(iy+high ixy_bits),l
    res     5,(iy+high ixy_bits),l
    res     6,(iy+high ixy_bits),l
    res     7,(iy+high ixy_bits),l
    set     0,(iy+high ixy_bits),l
    set     1,(iy+high ixy_bits),l
    set     2,(iy+high ixy_bits),l
    set     3,(iy+high ixy_bits),l
    set     4,(iy+high ixy_bits),l
    set     5,(iy+high ixy_bits),l
    set     6,(iy+high ixy_bits),l
    set     7,(iy+high ixy_bits),l

    res     0,(iy+high ixy_bits),a
    res     1,(iy+high ixy_bits),a
    res     2,(iy+high ixy_bits),a
    res     3,(iy+high ixy_bits),a
    res     4,(iy+high ixy_bits),a
    res     5,(iy+high ixy_bits),a
    res     6,(iy+high ixy_bits),a
    res     7,(iy+high ixy_bits),a
    set     0,(iy+high ixy_bits),a
    set     1,(iy+high ixy_bits),a
    set     2,(iy+high ixy_bits),a
    set     3,(iy+high ixy_bits),a
    set     4,(iy+high ixy_bits),a
    set     5,(iy+high ixy_bits),a
    set     6,(iy+high ixy_bits),a
    set     7,(iy+high ixy_bits),a

    RELOCATE_TABLE

    ASSERT 0 == __ERRORS__
    ASSERT 532 == __WARNINGS__
