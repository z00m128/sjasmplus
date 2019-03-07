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

    IFN 31=_ERRORS
        UNEXPECTED ERROR!
    ENDIF

    ;;; if expected amount of error happened, the output should be 0B long