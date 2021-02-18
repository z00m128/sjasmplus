    DEVICE ZXSPECTRUMNEXT
    ORG $7E00
start:  ei : jr $           ; app code entry point, BC = NEX file handle
    ; Layer2 screen (top 1/3 defined, bottom of it will be used also as "visible" stack)
    ORG $C000 : DUP 64*32 : DB $90,$91,$92,$93,$94,$95,$96,$97 : EDUP

    ; write everything into NEX file
    SAVENEX OPEN "example.nex", start, $FFFE, 9  ; stack will go into Layer2
    SAVENEX CORE 2, 0, 0        ; Next core 2.0.0 required as minimum
    SAVENEX CFG 4, 1, 0, 1      ; green border, file handle in BC, reset NextRegs, 2MB required
    SAVENEX BAR 1, $E0, 50, 25  ; do load bar, red colour, start/load delays 50/25 frames
    SAVENEX SCREEN L2 0, 0      ; store the data from C000 (page 0, offset 0), no palette
    SAVENEX BANK 5, 100, 101    ; store the 16ki banks 5 (contains the code at 0x7E00), 100, 101
    SAVENEX CLOSE               ; (banks 100 and 101 are added just as example)
