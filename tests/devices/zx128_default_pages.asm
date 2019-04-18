    DEVICE ZXSPECTRUM128
    ; expected default is SLOT 3, ORG 0, pages: 0, 5, 2, 7
    DB "00" : ORG 0x4000 : DB "55" : ORG 0x8000 : DB "22" : ORG 0xC000 : DB "77"
    ASSERT {0x0000} == "00" : ASSERT {0x4000} == "55" : ASSERT {0x8000} == "22" : ASSERT {0xC000} == "77"
    ; test default slot == 3 (does test also default mapping - difficult to test only slot :/ )
    PAGE 0 : ASSERT {0xC000} == "00" : PAGE 5 : ASSERT {0xC000} == "55" : PAGE 2 : ASSERT {0xC000} == "22" : PAGE 7 : ASSERT {0xC000} == "77"
    ; test other pages = done
    SLOT 0
    PAGE 1 : ASSERT {0} == 0 : ORG 0 : DB "11"
    PAGE 3 : ASSERT {0} == 0 : ORG 0 : DB "33"
    PAGE 4 : ASSERT {0} == 0 : ORG 0 : DB "44"
    PAGE 6 : ASSERT {0} == 0 : ORG 0 : DB "66"

    PAGE 0 : ASSERT {0} == "00" : PAGE 1 : ASSERT {0} == "11"
    PAGE 2 : ASSERT {0} == "22" : PAGE 3 : ASSERT {0} == "33"
    PAGE 4 : ASSERT {0} == "44" : PAGE 5 : ASSERT {0} == "55"
    PAGE 6 : ASSERT {0} == "66" : PAGE 7 : ASSERT {0} == "77"
