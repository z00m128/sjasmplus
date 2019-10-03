    OUTPUT "op_C0_FF.bin" : OPT --syntax=a

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
    bit     0,h     ; BITS 0xCB prefix + 0x44
    call    z,$4241
    call    $4241
    adc     a,$43
    rst     0x08
    ret     nc
    pop     de
    jp      nc,$4241
    ;; D3 = *nothing*
    call    nc,$4241
    push    de
    sub     $43
    rst     $10
    ret     c
    ;; D9 = reti
    jp      c,$4241
    ;; DB = *nothing*
    call    c,$4241
    ;; DD = *nothing*
    sbc     a,$43
    rst     #18
    ;; E0 = ldh (a8),a
    pop     hl
    ;; E2 = ld (c),a
    ;; E3 = *nothing*
    ;; E4 = *nothing*
    push    hl
    and     $43
    rst     32
    ;; E8 = add sp,r8
    jp      (hl)
    ;; EA = ld (a16),a
    ;; EB = *nothing*
    ;; EC = *nothing*
    ;; ED = *nothing*
    xor     $43
    rst     28h
    ;; F0 = ldh a,(a8)
    pop     af
    ;; F2 = ld a,(c)
    di
    ;; F4 = *nothing*
    push    af
    or      $43
    rst     #30
    ;; F8 = ld hl,sp+r8
    ld      sp,hl
    ;; FA = ld a,(a16)
    ei
    ;; FC = *nothing*
    ;; FD = *nothing*
    cp      $43
    rst     $38

    ; illegal on LR35902
    out     ($43),a
    exx
    in      a,($43)
    inc     ix  ; IX 0xDD prefix + 0x44
    ret     po
    jp      po,$4241
    ex      (sp),hl
    call    po,$4241
    ret     pe
    jp      pe,$4241
    ex      de,hl
    call    pe,$4241
    neg         ; EXTD 0xED prefix + 0x44
    ret     p
    jp      p,$4241
    call    p,$4241
    ret     m
    jp      m,$4241
    call    m,$4241
    dec     iy  ; IY 0xFD prefix + 0x44

    ; different opcode on LR35902
