    DEVICE ZXSPECTRUM128
    ; taint page 0 and page 1
    SLOT 3 : PAGE 0 : ORG 0xC000 : DB "00" : PAGE 1 : ORG 0xC000 : DB "11"
    ASSERT {0xC000} == "11"
    ; test second argument of ORG
    ORG 0x4000, 0       ; should do also PAGE 0 in current slot (not related to 0x4000)
    DB "55"
    ASSERT {0xC000} == "00" : ASSERT {0x4000} == "55"
