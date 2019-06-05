    ; test various tricky cases of syntax
    adc     a , (   ( 3 ) + ( 4 )   )
    ld      a , (   ( 3 ) + ( 4 )   )
    ld      a ,     ( 3 ) + ( 4 )
    ld      a ,     ( 3 ) | ( 4 )
    ld      a ,       ( 3 | 4 )
    ld      a,((3|4))
    ld      a,(+(3|4))
    ld      a,+((3|4))

    ; test all IXY variants recognized by parser
    ld      a,hx, a,xh, a,ixh, a,HX, a,XH, a,IXH, a,high ix, a,high IX, a,HIGH ix, a,HIGH IX
    ld      a,lx, a,xl, a,ixl, a,LX, a,XL, a,IXL, a,low  ix, a,low  IX, a,LOW  ix, a,LOW  IX
    ld      a,hy, a,yh, a,iyh, a,HY, a,YH, a,IYH, a,high iy, a,high IY, a,HIGH iy, a,HIGH IY
    ld      a,ly, a,yl, a,iyl, a,LY, a,YL, a,IYL, a,low  iy, a,low  IY, a,LOW  iy, a,LOW  IY
    push    ix, IX
    push    iy, IY

    jp      (hl), hl, (ix), ix, (iy), iy        ; valid
    ; invalid
    jp      ((hl))
    jp      ((ix))
    jp      ((iy))

    ; ld r16,nnnn vs ld r16,(nnnn) heuristics in default syntax mode
    ld      bc, $1230 + 4  , bc, ($1230) + (4)  , bc,+($1230 + 4)
    ld      bc,($1230 + 4) , bc,(($1230) + (4)) , bc, [$1230 + 4] , bc,[($1230  +  4)]

    ld      de, $1230 + 4  , de, ($1230) + (4)  , de,+($1230 + 4)
    ld      de,($1230 + 4) , de,(($1230) + (4)) , de, [$1230 + 4] , de,[($1230  +  4)]

    ld      hl, $1230 + 4  , hl, ($1230) + (4)  , hl,+($1230 + 4)
    ld      hl,($1230 + 4) , hl,(($1230) + (4)) , hl, [$1230 + 4] , hl,[($1230  +  4)]

    ld      ix, $1230 + 4  , ix, ($1230) + (4)  , ix,+($1230 + 4)
    ld      ix,($1230 + 4) , ix,(($1230) + (4)) , ix, [$1230 + 4] , ix,[($1230  +  4)]

    ld      iy, $1230 + 4  , iy, ($1230) + (4)  , iy,+($1230 + 4)
    ld      iy,($1230 + 4) , iy,(($1230) + (4)) , iy, [$1230 + 4] , iy,[($1230  +  4)]

    ld      sp, $1230 + 4  , sp, ($1230) + (4)  , sp,+($1230 + 4)
    ld      sp,($1230 + 4) , sp,(($1230) + (4)) , sp, [$1230 + 4] , sp,[($1230  +  4)]

    ld      bc,(hl), de,(hl)                    ; valid fake instructions
    ld      hl,(ix+1), hl,(ix-128), hl,(ix+126)
    ld      hl,(iy+1), hl,(iy-128), hl,(iy+126)
    ; invalid
    ld      hl,(hl)
    ld      sp,(hl)
    ld      ix,(hl)
    ld      iy,(hl)
    ld      hl,(ix+127)
    ld      hl,(ix-129)
    ld      hl,(iy+127)
    ld      hl,(iy-129)

    ex      de,hl
    ex      hl,de
    ex      af
    ex      af,af
    ex      af,af'
