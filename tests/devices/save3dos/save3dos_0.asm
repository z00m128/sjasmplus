        DEVICE ZXSPECTRUM48
        ORG $5D00

PRINT   EQU     $F5

basic:
        DB      0,10    ;; Line number 10
        DW      .l10ln  ;; Line length
.l10:   DB      PRINT,"\"https://github.com/z00m128/sjasmplus\"\r"
.l10ln: EQU     $-.l10

.sz     EQU     $-basic

        SAVE3DOS "save3dos_0.bin", basic, basic.sz, 0       ; basic, no LINE, no vars
        SAVE3DOS "save3dos_0.raw", basic, basic.sz, 0, 10   ; basic, LINE 10
