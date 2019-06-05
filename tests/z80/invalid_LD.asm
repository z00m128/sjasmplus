    DEFARRAY reg8 a, b, c, d, e, h, l, (hl), ixh, ixl, iyh, iyl
    DEFARRAY reg16 af, bc, de, hl, ix, iy, sp

    ; IXY 8 bit invalid combinations
    ld  h,ixh
    ld  l,ixh
    ld  h,ixl
    ld  l,ixl

    ld  h,iyh
    ld  l,iyh
    ld  h,iyl
    ld  l,iyl

    ld  ixh,h
    ld  ixh,l
    ld  ixl,h
    ld  ixl,l

    ld  iyh,h
    ld  iyh,l
    ld  iyl,h
    ld  iyl,l

    ; I and R register can be paired only against register A
R1=1        ; skip A
    DUP 11
        ld  reg8[R1],r
        ld  reg8[R1],i
        ld  r,reg8[R1]
        ld  i,reg8[R1]
R1=R1+1
    EDUP

    ; ld r16,SP , AF,r16, r16,AF doesn't exist
R1=0
    DUP 7
        ld  reg16[R1],sp
        ld  af,reg16[R1]
        ld  reg16[R1],af
R1=R1+1
    EDUP

    ; ld r8,r16 / ld r16,r8     ; includes four valid fakes: ld bc|de,(hl) and (hl),bc|de
R1=0
    DUP 12
R2=0
        DUP 7
            ld  reg8[R1],reg16[R2]
            ld  reg16[R2],reg8[R1]
R2=R2+1
        EDUP
R1=R1+1
    EDUP

    ; special cases for MEM_HL "register"
R1=7        ; skip A, .., L (start with "(hl)")
    DUP 5
        ld  reg8[R1],(hl)
        ld  (hl),reg8[R1]
R1=R1+1
    EDUP

    ; some cases manually picked
    ld      sp,bc
    ld      sp,de
    ld      hl,sp
    ld      sp,(hl)
    ld      hl,(hl)
    ld      sp,(ix+1)
    ld      sp,(sp)
    ld      hl,(sp)
