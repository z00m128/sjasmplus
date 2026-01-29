    DEVICE ZXSPECTRUM48
    BPLIST "dir_setbp_mame.exp" mame ; valid breakpoints file for MAME

    SETBREAKPOINT 0x1234
    setbreakpoint 0xBCDE
    ORG $2345
    SETBREAKPOINT       ; default = "$"

    ; value truncating warnings
    .SETBREAKPOINT 0x10000
    .setbreakpoint -1

    SETBP   "conditions not supported yet"
