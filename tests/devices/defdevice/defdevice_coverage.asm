    ; correct syntax
    DEFDEVICE LikeZx48, $4000, 4, 0, 1, 2, 3
    DEFDEVICE LikeZxNext, $2000, 96

    ; correct syntax, but not defined in first pass - gets silently ignored
    IF 1 < __PASS__
        DEFDEVICE tooLateId, $4000, 4
    ENDIF

    ; invalid syntax, missing arguments
    DEFDEVICE
    DEFDEVICE invalidId
    DEFDEVICE invalidId,
    DEFDEVICE invalidId, $10000
    DEFDEVICE invalidId, $10000,

    ; invalid arguments
    DEFDEVICE invalidId, $10001, 256
    DEFDEVICE invalidId, 255, 256
    DEFDEVICE invalidId, $10000, 0
    DEFDEVICE invalidPage, $4000, 4, 1, 4, 2, 3

    ; re-definition of already defined ID
    DEFDEVICE LIKEZX48, $4000, 8, 2, 3, 4, 5

    ; try to switch to mis-defined devices (errors expected)
    DEVICE tooLateId
    DEVICE invalidId

    ; try to switch to valid user defined devices
    DEVICE LIKEZX48
    DEVICE LIKEZXNEXT

    ; MMU when it runs out of pages
    DEVICE LIKEZX48
    MMU 0 3, 2
    MMU 0 n, 3, $3FFF
    DB $01
    ; error about no more pages to map
    ;(even when there is no byte emit... because address wrap-around happens any way for listing at least)

    ; older SLOT/PAGE
    SLOT 4
    PAGE 4

    DEVICE LIKEZX48, $8765  ; ramtop warning

    ; non-divisible slot size are technically possible, but they may cause few glitches here and there
    DEFDEVICE weirdSlotSz, $E000, 4

    DEVICE weirdslotsz
    ORG $0000 : ASSERT 0 == $$
    ORG $E000 : ASSERT 1 == $$
    SLOT 0 : PAGE 2 : ORG $0000 : ASSERT 2 == $$
    SLOT 1 : PAGE 1 : ORG $E000 : ASSERT 1 == $$
    SLOT 2
    MMU $E000, 3, $FFFE
    ASSERT 3 == $$
    nop
    ld a,1
long_ptr_label:
    ; due to weird slot size, this doesn't report 64ki boundary crossing and works a bit like --longptr mode
    ASSERT $10001 == $ && 3 == $$
    ; but trying to set such ORG directly will end with truncated ORG back to slot 0
    ORG $10001
truncated_label:
    ASSERT 2 == $$
