    DEVICE ZXSPECTRUM48

    SLOT 0
    PAGE 0 : ORG 0x0000 : DB "00"
    PAGE 1 : ORG 0x0000 : DB "11"
    PAGE 2 : ORG 0x0000 : DB "22"
    PAGE 3 : ORG 0x0000 : DB "33"

    PAGE 4      ; error - non-existing page (page 3 should be still visible in slot 0)
    ASSERT {0} == "33"

    SLOT 1 : PAGE 0 : ASSERT {0x4000} == "00" : PAGE 1 : ASSERT {0x4000} == "11"
    SLOT 2 : PAGE 2 : ASSERT {0x8000} == "22" : PAGE 3 : ASSERT {0x8000} == "33"
    SLOT 3 : PAGE 0 : ASSERT {0xC000} == "00" : PAGE 1 : ASSERT {0xC000} == "11"

    SLOT 4      ; error

    ; pages: 3:1:3:1
    ORG 0xC000-2
    DB  "AABB"
    ASSERT {0x4000-2} == "AA"   ; should be visible also at these addresses
    ASSERT {0x4000} == "BB"

    ORG 0xFFFE
    DB  "CCDD"  ; "DD" goes beyond 0x10000 -> lost (error reported)
    ASSERT {0} == "33"          ; still page 3 there

    ; now try the 128 classic (should be not affected by the 48 device above)
    DEVICE ZXSPECTRUM128

    SLOT 0
    PAGE 0 : ASSERT {0} == 0 : ORG 0x0000 : DB "00"
    PAGE 1 : ASSERT {0} == 0 : ORG 0x0000 : DB "11"
    PAGE 2 : ASSERT {0} == 0 : ORG 0x0000 : DB "22"
    PAGE 3 : ASSERT {0} == 0 : ORG 0x0000 : DB "33"
    PAGE 4 : ASSERT {0} == 0 : ORG 0x0000 : DB "44"
    PAGE 5 : ASSERT {0} == 0 : ORG 0x0000 : DB "55"
    PAGE 6 : ASSERT {0} == 0 : ORG 0x0000 : DB "66"
    PAGE 7 : ASSERT {0} == 0 : ORG 0x0000 : DB "77"

    PAGE 8      ; error - non-existing page (page 7 should be still visible in slot 0)
    ASSERT {0} == "77"

    SLOT 1 : PAGE 4 : ASSERT {0x4000} == "44" : PAGE 5 : ASSERT {0x4000} == "55"
    SLOT 2 : PAGE 6 : ASSERT {0x8000} == "66" : PAGE 7 : ASSERT {0x8000} == "77"
    SLOT 3 : PAGE 4 : ASSERT {0xC000} == "44" : PAGE 5 : ASSERT {0xC000} == "55"

    SLOT 4      ; error

    ; pages: 7:5:7:5
    ORG 0xC000-2
    DB  "AABB"
    ASSERT {0x4000-2} == "AA"   ; should be visible also at these addresses
    ASSERT {0x4000} == "BB"

    ORG 0xFFFE
    DB  "CCDD"  ; "DD" goes beyond 0x10000 -> lost (error reported)
    ASSERT {0} == "77"          ; still page 7 there

    ; some more error states
    ORG & : PAGE & : ORG 0x1234, & : DISP & : SLOT & ; syntax errors
    ENT

    DEVICE none
    PAGE 1 : SLOT 1
