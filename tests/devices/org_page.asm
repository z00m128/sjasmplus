    DEVICE ZXSPECTRUM128
    ; taint page 0 and page 1
    SLOT 3 : PAGE 0 : ORG 0xC000 : DB "00" : PAGE 1 : ORG 0xC000 : DB "11"
    ASSERT {0xC000} == "11"
    ; test second argument of ORG
    ORG 0x4000, 0       ; should do also PAGE 0 in current slot (not related to 0x4000)
        ; since v1.15.2 this should emit warning about address outside current slot
    DB "55"
    ASSERT {0xC000} == "00" : ASSERT {0x4000} == "55"
    ; verify warning precision on all ends
    SLOT 2
    ORG 0x7FFF, 7   ; should warn
    ORG 0xC000, 7   ; should warn
    ORG 0x8000, 6   ; should be ok
    ORG 0xBFFF, 6   ; should be ok
    ORG 0x7FFF, 5   ; ok ; should be suppressed
    ORG 0xC000, 5   ; ok ; should be suppressed

    ; try the warning with 8kiB slots
    DEVICE ZXSPECTRUMNEXT
    SLOT 4
    ORG 0x7FFF, 7   ; should warn
    ORG 0xA000, 7   ; should warn
    ORG 0x8000, 6   ; should be ok
    ORG 0x9FFF, 6   ; should be ok
    ORG 0x7FFF, 5   ; ok ; should be suppressed
    ORG 0xA000, 5   ; ok ; should be suppressed
