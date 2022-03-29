; this is trivial "does it even do something" check of SAVECPCSNA with a CPC464 device
; there's nothing to verify after the test except sjasmplus did not error out

    DEVICE AMSTRADCPC464
    ORG     0x1200
start:
    ld      b,$7F
    ld      c,$8D   ; disable ROMS, set mode 1
    out     (c),c

    ld      c,$10   ; PENR = BORDER
    out     (c),c

    ld      a,$FF
.borderMess:
    inc     a
    and     $1F
    cp      $1F
    jr      nz,.brd
    ld      a,$00
.brd:
    or      $40
    ld      c,a
    out     (c),a   ; INKR
    jr      .borderMess

    SAVECPCSNA "cpc464_savesna.sna", start
