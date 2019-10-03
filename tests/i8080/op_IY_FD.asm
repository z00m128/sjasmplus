    ; all of these should fail on i8080

    add     iy,bc       ; #FD09

    add     iy,de       ; #FD19

    ld      iy,#100     ; #FD210001
    ld      (#100),iy   ; #FD220001
    inc     iy          ; #FD23
    inc     iyh         ; #FD24
    dec     iyh         ; #FD25
    ld      iyh,0       ; #FD2600
    add     iy,iy       ; #FD29
    ld      iy,(#100)   ; #FD2A0001
    dec     iy          ; #FD2B
    inc     iyl         ; #FD2C
    dec     iyl         ; #FD2D
    ld      iyl,0       ; #FD2E00

    inc     (iy+17)     ; #FD3411
    dec     (iy+17)     ; #FD3511
    ld      (iy+17),0   ; #FD361100
    add     iy,sp       ; #FD39

    ld      b,iyh       ; #FD44
    ld      b,iyl       ; #FD45
    ld      b,(iy+17)   ; #FD4611
    ld      c,iyh       ; #FD4C
    ld      c,iyl       ; #FD4D
    ld      c,(iy+17)   ; #FD4E11

    ld      d,iyh       ; #FD54
    ld      d,iyl       ; #FD55
    ld      d,(iy+17)   ; #FD5611
    ld      e,iyh       ; #FD5C
    ld      e,iyl       ; #FD5D
    ld      e,(iy+17)   ; #FD5E11

    ld      iyh,b       ; #FD60
    ld      iyh,c       ; #FD61
    ld      iyh,d       ; #FD62
    ld      iyh,e       ; #FD63
    ld      iyh,iyh     ; #FD64
    ld      iyh,iyl     ; #FD65
    ld      h,(iy+17)   ; #FD6611
    ld      iyh,a       ; #FD67
    ld      iyl,b       ; #FD68
    ld      iyl,c       ; #FD69
    ld      iyl,d       ; #FD6A
    ld      iyl,e       ; #FD6B
    ld      iyl,iyh     ; #FD6C
    ld      iyl,iyl     ; #FD6D
    ld      l,(iy+17)   ; #FD6E11
    ld      iyl,a       ; #FD6F

    ld      (iy+17),b   ; #FD7011
    ld      (iy+17),c   ; #FD7111
    ld      (iy+17),d   ; #FD7211
    ld      (iy+17),e   ; #FD7311
    ld      (iy+17),h   ; #FD7411
    ld      (iy+17),l   ; #FD7511
    ld      (iy+17),a   ; #FD7711
    ld      a,iyh       ; #FD7C
    ld      a,iyl       ; #FD7D
    ld      a,(iy+17)   ; #FD7E11

    add     a,iyh       ; #FD84
    add     a,iyl       ; #FD85
    add     a,(iy+17)   ; #FD8611
    adc     a,iyh       ; #FD8C
    adc     a,iyl       ; #FD8D
    adc     a,(iy+17)   ; #FD8E11

    sub     iyh         ; #FD94
    sub     iyl         ; #FD95
    sub     (iy+17)     ; #FD9611
    sbc     a,iyh       ; #FD9C
    sbc     a,iyl       ; #FD9D
    sbc     a,(iy+17)   ; #FD9E11

    and     iyh         ; #FDA4
    and     iyl         ; #FDA5
    and     (iy+17)     ; #FDA611
    xor     iyh         ; #FDAC
    xor     iyl         ; #FDAD
    xor     (iy+17)     ; #FDAE11

    or      iyh         ; #FDB4
    or      iyl         ; #FDB5
    or      (iy+17)     ; #FDB611
    cp      iyh         ; #FDBC
    cp      iyl         ; #FDBD
    cp      (iy+17)     ; #FDBE11

    pop     iy          ; #FDE1
    ex      (sp),iy     ; #FDE3
    push    iy          ; #FDE5
    jp      (iy)        ; #FDE9

    ld      sp,iy       ; #FDF9
