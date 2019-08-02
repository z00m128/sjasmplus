    DEVICE ZXSPECTRUMNEXT
    ; check default page mapping 14, 15, 10, 11, 4, 5, 0, 1 (and ORG 0) - write markers
                 DB  "EE" : ORG 0x2000 : DB "FF" : ORG 0x4000 : DB  "AA" : ORG 0x6000 : DB  "BB"
    ORG 0x8000 : DB  "44" : ORG 0xA000 : DB "55" : ORG 0xC000 : DB  "00" : ORG 0xE000 : DB  "11"
    ; verify defaut is slot 7
    PAGE 2 : ASSERT {0xE000} == 0 : ORG 0xE000 : DB "22"
    PAGE 3 : ASSERT {0xE000} == 0 : ORG 0xE000 : DB "33"
    ; verify there are 8 slots and 224 pages
    SLOT 8      ; error
    PAGE 224    ; error
    ; do few more verifications with other slots, reading previously modified pages
    SLOT 1 : PAGE 0 : ASSERT {0x2000} == "00" : SLOT 2 : PAGE 1 : ASSERT {0x4000} == "11"
    SLOT 1 : PAGE 2 : ASSERT {0x2000} == "22" : SLOT 2 : PAGE 3 : ASSERT {0x4000} == "33"
    SLOT 1 : PAGE 4 : ASSERT {0x2000} == "44" : SLOT 2 : PAGE 5 : ASSERT {0x4000} == "55"
    SLOT 1 : PAGE 10 : ASSERT {0x2000} == "AA" : SLOT 2 : PAGE 11 : ASSERT {0x4000} == "BB"
    SLOT 1 : PAGE 14 : ASSERT {0x2000} == "EE" : SLOT 2 : PAGE 15 : ASSERT {0x4000} == "FF"

    ; check the Z80N instructions are enabled by the device selection
    nextreg $07,2

    PAGE -1     ; error
