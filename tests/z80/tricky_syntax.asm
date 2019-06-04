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
