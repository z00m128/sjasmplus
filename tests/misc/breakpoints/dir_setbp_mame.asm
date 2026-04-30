    DEVICE ZXSPECTRUM48
    BPLIST "dir_setbp_mame.exp" mame ; valid breakpoints file for MAME

    SETBREAKPOINT 0x1234
    setbreakpoint 0xBCDE
    ORG $2345
    SETBREAKPOINT       ; default = "$"

    ; value truncating warnings
    .SETBREAKPOINT 0x10000
    .setbreakpoint -1

    ; conditional breakpoints for MAME added since v1.23.1
    SETBREAKPOINT 0x4000, "hl=1234"
    SETBREAKPOINT 0x5000, 'a==5'
    SETBREAKPOINT 0x6000, "bc<0x8000"
