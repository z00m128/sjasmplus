    OUTPUT "op_C0_FF.bin"
    ;; solid formatting, just to get C0..FF sequence (interleaved by $44 where needed)
    ret     nz
    pop     bc
    jp      nz,$4444
    jp      $4444
    call    nz,$4444
    push    bc
    add     a,$44
    rst     00h
    ret     z
    ret
    jp      z,$4444
    bit     0,h     ; BITS 0xCB prefix + 0x44
    call    z,$4444
    call    $4444
    adc     a,$44
    rst     0x08
    ret     nc
    pop     de
    jp      nc,$4444
    out     ($44),a
    call    nc,$4444
    push    de
    sub     $44
    rst     $10
    ret     c
    exx
    jp      c,$4444
    in      a,($44)
    call    c,$4444
    ld      b,ixh   ; IX 0xDD prefix + 0x44
    sbc     a,$44
    rst     #18
    ret     po
    pop     hl
    jp      po,$4444
    ex      (sp),hl
    call    po,$4444
    push    hl
    and     $44
    rst     32
    ret     pe
    jp      (hl)
    jp      pe,$4444
    ex      de,hl
    call    pe,$4444
    neg             ; EXTD 0xED prefix + 0x44
    xor     $44
    rst     28h
    ret     p
    pop     af
    jp      p,$4444
    di
    call    p,$4444
    push    af
    or      $44
    rst     #30
    ret     m
    ld      sp,hl
    jp      m,$4444
    ei
    call    m,$4444
    ld      b,iyh   ; IY 0xFD prefix + 0x44
    cp      $44
    rst     $38

    ;; separator
    ds      $20, $44

    ;; parser exercises (mostly conditional jumps/calls/rets)
    ret     NZ
    jp      NZ , $4444
    call    NZ , $4444
    ret     Z
    jp      Z , $4444
    call    Z , $4444
    ret     NC
    jp      NC , $4444
    call    NC , $4444
    ret     C
    jp      C , $4444
    call    C , $4444
    ret     PO
    jp      PO , $4444
    call    PO , $4444
    ret     PE
    jp      [HL]
    jp      PE , $4444
    call    PE , $4444
    ret     P
    jp      P , $4444
    call    P , $4444
    ret     M
    jp      M , $4444
    call    M , $4444

    RET     NZ
    JP      NZ,$4444
    JP      $4444
    CALL    NZ,$4444
    RET     Z
    JP      Z,$4444
    CALL    Z,$4444
    CALL    $4444
    RET     NC
    JP      NC,$4444
    CALL    NC,$4444
    RET     C
    JP      C,$4444
    CALL    C,$4444
    RET     PO
    JP      PO,$4444
    CALL    PO,$4444
    RET     PE
    JP      HL
    JP      PE,$4444
    CALL    PE,$4444
    RET     NS
    JP      NS,$4444
    CALL    NS,$4444
    RET     S
    JP      S,$4444
    CALL    S,$4444

    RET     nz
    JP      nz	,	$4444
    CALL    nz	,	$4444
    RET     z
    JP      z	,	$4444
    CALL    z	,	$4444
    RET     nc
    JP      nc	,	$4444
    CALL    nc	,	$4444
    RET     c
    JP      c	,	$4444
    CALL    c	,	$4444
    RET     po
    JP      po	,	$4444
    CALL    po	,	$4444
    RET     pe
    JP      pe	,	$4444
    CALL    pe	,	$4444
    RET     ns
    JP      ns	,	$4444
    CALL    ns	,	$4444
    RET     s
    JP      s	,	$4444
    CALL    s	,	$4444

    JP      nz,$4444, z,$4444, m,$4444, ns,$4444, po,$4444
    CALL    $4444, $4444, nz,$4444, z,$4444, p,$4444, pe,$4444
