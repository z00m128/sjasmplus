    DEVICE NOSLOT64K
    ; check default page mapping 0 (and ORG 0) - write marker
    DB  "00"
    ; verify defaut is slot 0 (the only slot)
    PAGE 2 : ASSERT {0x0000} == 0 : ORG 0x0000 : DB "22"
    PAGE 3 : ASSERT {0x0000} == 0 : ORG 0x0000 : DB "33"
    ; verify there is single slot and 32 pages
    SLOT 1      ; error
    PAGE 32     ; error
    ; do few more verifications, reading previously modified pages
    SLOT 0 : PAGE 0 : ASSERT {0x0000} == "00"
    SLOT 0 : PAGE 2 : ASSERT {0x0000} == "22"
    SLOT 0 : PAGE 3 : ASSERT {0x0000} == "33"

    PAGE -1     ; error

    ; try wrap-around MMU mapping, filling 80kiB
    MMU 0 n, 4, $E000
    ASSERT 4 == $$
    BLOCK 80*1024, $44
    ASSERT 6 == $$
