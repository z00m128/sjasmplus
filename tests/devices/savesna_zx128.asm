; this is trivial "does it even do something" check of SAVESNA with ZX128 device
; there's nothing to verify after the test except sjasmplus did not error out
; (ot checking the snapshot as binary file, but I don't want to add 128kiB of sh*t just
; for this one, maybe later, using gunzip to keep the repository size as low as possible)

    DEVICE ZXSPECTRUM128
    PAGE    5   ; btw this is VRAM page (and slot 3 is default)
    ORG     0xC000
    ; so this code will be visible on screen
    ; and it will cause page 5 to be stored in snapshot twice, is this even legal? :D
start:
    ld      bc,0x07FE
.borderMess:
    inc     a
    and     b
    out     (c),a
    jp      .borderMess

    SAVESNA "savesna_zx128.sna", start
