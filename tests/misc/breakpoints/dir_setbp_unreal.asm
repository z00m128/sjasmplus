    DEVICE ZXSPECTRUM48
    BPLIST "dir_setbp_unreal.exp" ; valid breakpoints file, default type is unreal
    BPLIST "dir_setbp_unreal.exp" unreal ; error double open, but reads type explicitly (for coverage)

    SETBREAKPOINT 0x1234
    setbreakpoint 0xBCDE
    ORG $2345
    SETBREAKPOINT       ; default = "$"

    ; value truncating warnings
    .SETBREAKPOINT 0x10000
    .setbreakpoint -1
