    DEVICE AMSTRADCPC464

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

    ; swap to the 6128
    DEVICE AMSTRADCPC6128

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

    ; swap to the plus
    DEVICE AMSTRADCPCPLUS

    SLOT 0
    PAGE 0 : ASSERT {0} == 0 : ORG 0x0000 : DB "00"
    PAGE 1 : ASSERT {0} == 0 : ORG 0x0000 : DB "11"
    PAGE 2 : ASSERT {0} == 0 : ORG 0x0000 : DB "22"
    PAGE 3 : ASSERT {0} == 0 : ORG 0x0000 : DB "33"
    PAGE 4 : ASSERT {0} == 0 : ORG 0x0000 : DB "44"
    PAGE 5 : ASSERT {0} == 0 : ORG 0x0000 : DB "55"
    PAGE 6 : ASSERT {0} == 0 : ORG 0x0000 : DB "66"
    PAGE 7 : ASSERT {0} == 0 : ORG 0x0000 : DB "77"
    PAGE 8 : ASSERT {0} == 0 : ORG 0x0000 : DB "88"
    PAGE 9 : ASSERT {0} == 0 : ORG 0x0000 : DB "99"
    PAGE 10 : ASSERT {0} == 0 : ORG 0x0000 : DB "AA"
    PAGE 11 : ASSERT {0} == 0 : ORG 0x0000 : DB "BB"
    PAGE 12 : ASSERT {0} == 0 : ORG 0x0000 : DB "CC"
    PAGE 13 : ASSERT {0} == 0 : ORG 0x0000 : DB "DD"
    PAGE 14 : ASSERT {0} == 0 : ORG 0x0000 : DB "EE"
    PAGE 15 : ASSERT {0} == 0 : ORG 0x0000 : DB "FF"
    PAGE 16 : ASSERT {0} == 0 : ORG 0x0000 : DB "GG"
    PAGE 17 : ASSERT {0} == 0 : ORG 0x0000 : DB "HH"
    PAGE 18 : ASSERT {0} == 0 : ORG 0x0000 : DB "II"
    PAGE 19 : ASSERT {0} == 0 : ORG 0x0000 : DB "JJ"
    PAGE 20 : ASSERT {0} == 0 : ORG 0x0000 : DB "KK"
    PAGE 21 : ASSERT {0} == 0 : ORG 0x0000 : DB "LL"
    PAGE 22 : ASSERT {0} == 0 : ORG 0x0000 : DB "MM"
    PAGE 23 : ASSERT {0} == 0 : ORG 0x0000 : DB "NN"
    PAGE 24 : ASSERT {0} == 0 : ORG 0x0000 : DB "OO"
    PAGE 25 : ASSERT {0} == 0 : ORG 0x0000 : DB "PP"
    PAGE 26 : ASSERT {0} == 0 : ORG 0x0000 : DB "QQ"
    PAGE 27 : ASSERT {0} == 0 : ORG 0x0000 : DB "RR"
    PAGE 28 : ASSERT {0} == 0 : ORG 0x0000 : DB "SS"
    PAGE 29 : ASSERT {0} == 0 : ORG 0x0000 : DB "TT"
    PAGE 30 : ASSERT {0} == 0 : ORG 0x0000 : DB "UU"
    PAGE 31 : ASSERT {0} == 0 : ORG 0x0000 : DB "VV"

    PAGE 32      ; error - non-existing page (page 31 should be still visible in slot 0)
    ASSERT {0} == "VV"

    SLOT 1 : PAGE 4 : ASSERT {0x4000} == "44" : PAGE 5 : ASSERT {0x4000} == "55"
    SLOT 2 : PAGE 6 : ASSERT {0x8000} == "66" : PAGE 7 : ASSERT {0x8000} == "77"
    SLOT 3 : PAGE 8 : ASSERT {0xC000} == "88" : PAGE 9 : ASSERT {0xC000} == "99"
    SLOT 1 : PAGE 10 : ASSERT {0x4000} == "AA" : PAGE 11 : ASSERT {0x4000} == "BB"
    SLOT 2 : PAGE 12 : ASSERT {0x8000} == "CC" : PAGE 13 : ASSERT {0x8000} == "DD"
    SLOT 3 : PAGE 14 : ASSERT {0xC000} == "EE" : PAGE 15 : ASSERT {0xC000} == "FF"
    SLOT 1 : PAGE 16 : ASSERT {0x4000} == "GG" : PAGE 17 : ASSERT {0x4000} == "HH"
    SLOT 2 : PAGE 18 : ASSERT {0x8000} == "II" : PAGE 19 : ASSERT {0x8000} == "JJ"
    SLOT 1 : PAGE 20 : ASSERT {0x4000} == "KK" : PAGE 21 : ASSERT {0x4000} == "LL"
    SLOT 2 : PAGE 22 : ASSERT {0x8000} == "MM" : PAGE 23 : ASSERT {0x8000} == "NN"
    SLOT 3 : PAGE 24 : ASSERT {0xC000} == "OO" : PAGE 25 : ASSERT {0xC000} == "PP"
    SLOT 1 : PAGE 26 : ASSERT {0x4000} == "QQ" : PAGE 27 : ASSERT {0x4000} == "RR"
    SLOT 2 : PAGE 28 : ASSERT {0x8000} == "SS" : PAGE 29 : ASSERT {0x8000} == "TT"
    SLOT 3 : PAGE 30 : ASSERT {0xC000} == "UU" : PAGE 31 : ASSERT {0xC000} == "VV"
    SLOT 2 : PAGE 30 : ASSERT {0x8000} == "UU" : PAGE 31 : ASSERT {0x8000} == "VV"
    SLOT 3 : PAGE 26 : ASSERT {0xC000} == "QQ" : PAGE 27 : ASSERT {0xC000} == "RR"

    SLOT 4      ; error

    ; pages: 31:27:31:27
    ORG 0xC000-2
    DB  "AABB"
    ASSERT {0x4000-2} == "AA"   ; should be visible also at these addresses
    ASSERT {0x4000} == "BB"

    ORG 0xFFFE
    DB  "CCDD"  ; "DD" goes beyond 0x10000 -> lost (error reported)
    ASSERT {0} == "VV"          ; still page 31 there
