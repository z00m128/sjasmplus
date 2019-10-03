    ; all of these should fail on LR35902

    add     ix,bc       ; #DD09

    add     ix,de       ; #DD19

    ld      ix,#100     ; #DD210001
    ld      (#100),ix   ; #DD220001
    inc     ix          ; #DD23
    inc     ixh         ; #DD24
    dec     ixh         ; #DD25
    ld      ixh,0       ; #DD2600
    add     ix,ix       ; #DD29
    ld      ix,(#100)   ; #DD2A0001
    dec     ix          ; #DD2B
    inc     ixl         ; #DD2C
    dec     ixl         ; #DD2D
    ld      ixl,0       ; #DD2E00

    inc     (ix+17)     ; #DD3411
    dec     (ix+17)     ; #DD3511
    ld      (ix+17),0   ; #DD361100
    add     ix,sp       ; #DD39

    ld      b,ixh       ; #DD44
    ld      b,ixl       ; #DD45
    ld      b,(ix+17)   ; #DD4611
    ld      c,ixh       ; #DD4C
    ld      c,ixl       ; #DD4D
    ld      c,(ix+17)   ; #DD4E11

    ld      d,ixh       ; #DD54
    ld      d,ixl       ; #DD55
    ld      d,(ix+17)   ; #DD5611
    ld      e,ixh       ; #DD5C
    ld      e,ixl       ; #DD5D
    ld      e,(ix+17)   ; #DD5E11

    ld      ixh,b       ; #DD60
    ld      ixh,c       ; #DD61
    ld      ixh,d       ; #DD62
    ld      ixh,e       ; #DD63
    ld      ixh,ixh     ; #DD64
    ld      ixh,ixl     ; #DD65
    ld      h,(ix+17)   ; #DD6611
    ld      ixh,a       ; #DD67
    ld      ixl,b       ; #DD68
    ld      ixl,c       ; #DD69
    ld      ixl,d       ; #DD6A
    ld      ixl,e       ; #DD6B
    ld      ixl,ixh     ; #DD6C
    ld      ixl,ixl     ; #DD6D
    ld      l,(ix+17)   ; #DD6E11
    ld      ixl,a       ; #DD6F

    ld      (ix+17),b   ; #DD7011
    ld      (ix+17),c   ; #DD7111
    ld      (ix+17),d   ; #DD7211
    ld      (ix+17),e   ; #DD7311
    ld      (ix+17),h   ; #DD7411
    ld      (ix+17),l   ; #DD7511
    ld      (ix+17),a   ; #DD7711
    ld      a,ixh       ; #DD7C
    ld      a,ixl       ; #DD7D
    ld      a,(ix+17)   ; #DD7E11

    add     a,ixh       ; #DD84
    add     a,ixl       ; #DD85
    add     a,(ix+17)   ; #DD8611
    adc     a,ixh       ; #DD8C
    adc     a,ixl       ; #DD8D
    adc     a,(ix+17)   ; #DD8E11

    sub     ixh         ; #DD94
    sub     ixl         ; #DD95
    sub     (ix+17)     ; #DD9611
    sbc     a,ixh       ; #DD9C
    sbc     a,ixl       ; #DD9D
    sbc     a,(ix+17)   ; #DD9E11

    and     ixh         ; #DDA4
    and     ixl         ; #DDA5
    and     (ix+17)     ; #DDA611
    xor     ixh         ; #DDAC
    xor     ixl         ; #DDAD
    xor     (ix+17)     ; #DDAE11

    or      ixh         ; #DDB4
    or      ixl         ; #DDB5
    or      (ix+17)     ; #DDB611
    cp      ixh         ; #DDBC
    cp      ixl         ; #DDBD
    cp      (ix+17)     ; #DDBE11

    pop     ix          ; #DDE1
    ex      (sp),ix     ; #DDE3
    push    ix          ; #DDE5
    jp      (ix)        ; #DDE9

    ld      sp,ix       ; #DDF9
