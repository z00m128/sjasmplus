    DEVICE ZXSPECTRUM48
    ORG $FF00
    DB "getIntArguments"
    ALIGN 256, $A5

    SAVEHOB "savehob.explicit.hob", "test.C", $FF00, $100
    SAVEHOB "savehob.default.hob", "test.C", $FF00  ; length is optional, defaults to "remainder of RAM"
    SAVEHOB "savehob.zero.hob", "test.C", $FF00, 0  ; non-positive length is offset "from end of RAM" (0 = end of RAM)
    SAVEHOB "savehob.forward.hob", "test.C", startAddress, byteCount
startAddress EQU $FF00
byteCount EQU $100