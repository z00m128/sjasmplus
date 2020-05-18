    DEVICE ZXSPECTRUM48
    BPLIST "dir_setbp.exp" zesarux  ; valid breakpoints file

    SETBP 0x1234
    setbp 0xBCDE
    ORG $2345
    SETBP       ; default = "$"

    BPLIST "dir_setbp.exp" unreal

    ; value truncating warnings
    .SETBP 0x10000
    .setbp -1

    ; syntax error test
    SETBP &
