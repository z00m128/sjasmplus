    OUTPUT "op_C0_FF.bin"
    ;; solid formatting, just to get C0..FF sequence (interleaved by $41..$43 where needed)
    ret     nz
    pop     bc
    jp      nz,$4241
    jp      $4241
    call    nz,$4241
    push    bc
    add     a,$43
    rst     00h
    ret     z
    ret
    jp      z,$4241
    call    z,$4241
    call    $4241
    adc     a,$43
    rst     0x08
    ret     nc
    pop     de
    jp      nc,$4241
    out     ($43),a
    call    nc,$4241
    push    de
    sub     $43
    rst     $10
    ret     c
    jp      c,$4241
    in      a,($43)
    call    c,$4241
    sbc     a,$43
    rst     #18
    ret     po
    pop     hl
    jp      po,$4241
    ex      (sp),hl
    call    po,$4241
    push    hl
    and     $43
    rst     32
    ret     pe
    jp      (hl)
    jp      pe,$4241
    ex      de,hl
    call    pe,$4241
    xor     $43
    rst     28h
    ret     p
    pop     af
    jp      p,$4241
    di
    call    p,$4241
    push    af
    or      $43
    rst     #30
    ret     m
    ld      sp,hl
    jp      m,$4241
    ei
    call    m,$4241
    cp      $43
    rst     $38

    ; illegal on i8080
    bit     0,h     ; BITS 0xCB prefix + 0x44
    exx
    inc     ix      ; IX 0xDD prefix + 0x44
    neg             ; EXTD 0xED prefix + 0x44
    dec     iy      ; IY 0xFD prefix + 0x44
