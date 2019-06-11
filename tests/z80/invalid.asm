    add     ix,iy
    add     ix,hl
    add     iy,hl
    add     iy,ix
    add     de,a
    add     hl,a
    add     a,hl
    add     a,de
    ld      iyl,(ix+0)
    ld      iyl,(iy+0)
    ld      iyl,(hl)
    ld      iyl,l
    ld      iyl,h
    ld      (ix+0),iyl
    ld      (iy+0),iyl
    ld      (hl),iyl
    ld      l,iyl
    ld      h,iyl
    xor     (e 5            ; did work as `xor 5` up to 1.10.4
    xor     (ixl+0)
    ex      ix,hl
    ex      de,ix
    ex      iy,hl
    ex      de,iy
    ex      bc,hl
    ex      hl,hl
    sbc     ix,bc
    sbc     ix,de
    sbc     ix,ix
    sbc     ix,sp
    ld      (hl),(hl)
    ex      de,de
    rst     1
    rst     2
    rst     4
    rst     $40
    rst     $80
    rlc     (ix+7),i
    rrc     (ix-7),r
    nextreg $44,a
    mirror  a
    ASSERT 0=_ERRORS        ; this assert should fail

    ASSERT 44=_ERRORS       ; update this assert when editing the file, to make it pass

;;; few labels/macros errors exercises

a123456789a123456789a123456789a123456789a123456789a123456789:
B123456789a123456789a123456789a123456789a123456789a123456789a123456789a123456789:

    MACRO dupName
        ld      a,0
    ENDM

    MACRO dupName
        ld      a,0
    ENDM

    undefine nononooo
