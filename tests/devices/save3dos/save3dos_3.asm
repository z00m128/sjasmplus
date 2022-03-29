        DEVICE ZXSPECTRUM48
        ORG $8765
code:
        DB      "Code"
.sz     EQU     $-code

    ; the default type is CODE block, taking two arguments: address, size
        SAVE3DOS "save3dos_3.bin", code, code.sz
        SAVE3DOS "save3dos_3.raw", code, code.sz, 3, $ABCD  ; w2 = non-default load address
