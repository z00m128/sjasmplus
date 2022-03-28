        DEVICE ZXSPECTRUM48
        ORG $6000

array:
        DB      1       ; maybe "b()" name? not sure about it (can be overridden by LOAD any way)
        DW      4       ; dimension of array?
        DW 0 : D24 1    ; b(1) = 1
        DW 0 : D24 3    ; b(2) = 3
        DW 0 : D24 5    ; b(3) = 5
        DW 0 : D24 1234 ; b(4) = 1234
.sz     EQU     $-array

        SAVE3DOS "save3dos_1.bin", array, array.sz, 1

    ; not even trying to fake string array, just checking the header for particular w2 + w3 and type=2
        SAVE3DOS "save3dos_1.raw", array, array.sz, 2, 0x3456, 0xABCD
