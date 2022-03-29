; this is trivial "does it even do something" check of SAVECPCSNA with a CPC6128 device
; there's nothing to verify after the test except sjasmplus did not error out

    DEVICE AMSTRADCPC6128
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
    
.mmr_paging:
    ; flip slot 3 in and out
    nop
	nop
	ld c,$C1
	out (c),c
	nop
	nop
	ld c,$C0
	out (c),c
    jr      .borderMess

    SLOT 3 : PAGE 3
    ORG $C000
    .db $03, $03

    SLOT 3 : PAGE 7
    ORG $C000
    .db $07, $07

    SAVECPCSNA "cpc6128_savesna.sna", start
