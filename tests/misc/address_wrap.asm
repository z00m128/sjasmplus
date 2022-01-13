    ; default without device will go outside into 0x10000+ address realm (with warnings)
    DEVICE NONE
    ORG $FFFF
ta1 scf
tb1 jr tb1
tc1 jr tc1
    call tc1

    ORG $FFFF
ta2 ld a,'7'    ; will reset warning-displayed flag => warnings again
tb2 jr tb2
tc2 jr tc2
    call tc2

    ; default with device will produce error (and leak into 0x10000+ address realm)
    DEVICE ZXSPECTRUM48
    ORG $FFFF
ta3 scf
tb3 jr tb3      ; machine code is written only to OUTPUT, not to device-memory (SAVEBIN)
tc3 jr tc3
    call tc3

    ORG $FFFF
ta4 ld a,'8'
tb4 jr tb4
tc4 jr tc4
    call tc4

    ; produce the same machine code at $8000 (recommended way how to FFFF->0000 wrap)
    DEVICE NONE
    ORG $8000
binStart5
    DISP $FFFF
ta5 scf
tb5 jr tb5          ; the "tb5" label will equal 0x10000 since v1.15.0 (was 0x0000 before)
tc5 jr tc5
    call tc5

    ORG $FFFF       ; displacedorg-ok ; while already inside DISP<->ENT block, use ORG for further changes
ta6 ld a,'8'
tb6 jr tb6
tc6 jr tc6
    call tc6
    ENT
binEnd6

    ; machine code at $8000 and also into device memory (SAVEBIN/SAVETAP ready)
    DEVICE ZXSPECTRUM48
binStart7
    DISP $FFFF
ta7 scf
tb7 jr tb7
tc7 jr tc7
    call tc7

    ORG $FFFF       ; displacedorg-ok
ta8 ld a,'8'
tb8 jr tb8
tc8 jr tc8
    call tc8
    ENT
binEnd8
