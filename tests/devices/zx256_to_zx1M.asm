    ;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;; ZXSPECTRUM256 ;;;;;;
    DEVICE ZXSPECTRUM256

    SLOT 0
pageNum = 0
    DUP 16
        PAGE pageNum : ASSERT {0} == 0 : ORG 0x0000 : DW pageNum+'0' + ((pageNum+'0')<<8)
pageNum = pageNum+1
    EDUP
    PAGE 16         ; error - non-existing page
    ASSERT {0} == "??"  ; page 15 should be still there

    SLOT 0 : PAGE 10 : ASSERT {0x0000} == "::" : PAGE 7 : ASSERT {0x0000} == "77"
    SLOT 1 : PAGE 4 : ASSERT {0x4000} == "44" : PAGE 15 : ASSERT {0x4000} == "??"
    SLOT 2 : PAGE 6 : ASSERT {0x8000} == "66" : PAGE 7 : ASSERT {0x8000} == "77"
    SLOT 3 : PAGE 14 : ASSERT {0xC000} == ">>" : PAGE 15 : ASSERT {0xC000} == "??"

    SLOT 4      ; error

    ; pages: 7:15:7:15
    ORG 0xC000-2
    DB  "AABB"
    ASSERT {0x4000-2} == "AA"   ; should be visible also at these addresses
    ASSERT {0x4000} == "BB"

    ORG 0xFFFE
    DB  "CCDD"  ; "DD" goes beyond 0x10000 -> lost (error reported)
    ASSERT {0} == "77"          ; still page 7 there
    ASSERT {0xFFFE} == "CC"

    SAVESNA "toCheck_IsZXSpectrumDevice_method", -1     ;; will error out

    ;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;; ZXSPECTRUM512 ;;;;;;
    DEVICE ZXSPECTRUM512

    SLOT 0
pageNum = 0
    DUP 32
        PAGE pageNum : ASSERT {0} == 0 : ORG 0x0000 : DW pageNum+'0' + ((pageNum+'0')<<8)
pageNum = pageNum+1
    EDUP
    PAGE 32         ; error - non-existing page
    ASSERT {0} == "OO"  ; page 31 should be still there

    SLOT 0 : PAGE 10 : ASSERT {0x0000} == "::" : PAGE 7 : ASSERT {0x0000} == "77"
    SLOT 1 : PAGE 4 : ASSERT {0x4000} == "44" : PAGE 31 : ASSERT {0x4000} == "OO"
    SLOT 2 : PAGE 6 : ASSERT {0x8000} == "66" : PAGE 7 : ASSERT {0x8000} == "77"
    SLOT 3 : PAGE 14 : ASSERT {0xC000} == ">>" : PAGE 31 : ASSERT {0xC000} == "OO"

    SLOT 4      ; error

    ; pages: 7:31:7:31
    ORG 0xC000-2
    DB  "AABB"
    ASSERT {0x4000-2} == "AA"   ; should be visible also at these addresses
    ASSERT {0x4000} == "BB"

    ORG 0xFFFE
    DB  "CCDD"  ; "DD" goes beyond 0x10000 -> lost (error reported)
    ASSERT {0} == "77"          ; still page 7 there
    ASSERT {0xFFFE} == "CC"

    SAVESNA "toCheck_IsZXSpectrumDevice_method", -1     ;; will error out

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;; ZXSPECTRUM1024 ;;;;;;
    DEVICE ZXSPECTRUM1024

    SLOT 0
pageNum = 0
    DUP 64
        PAGE pageNum : ASSERT {0} == 0 : ORG 0x0000 : DW pageNum+'0' + ((pageNum+'0')<<8)
pageNum = pageNum+1
    EDUP
    PAGE 64         ; error - non-existing page
    ASSERT {0} == $6F6F ; page 63 should be still there

    SLOT 0 : PAGE 10 : ASSERT {0x0000} == "::" : PAGE 7 : ASSERT {0x0000} == "77"
    SLOT 1 : PAGE 4 : ASSERT {0x4000} == "44" : PAGE 63 : ASSERT {0x4000} == $6F6F
    SLOT 2 : PAGE 6 : ASSERT {0x8000} == "66" : PAGE 7 : ASSERT {0x8000} == "77"
    SLOT 3 : PAGE 14 : ASSERT {0xC000} == ">>" : PAGE 63 : ASSERT {0xC000} == $6F6F

    SLOT 4      ; error

    ; pages: 7:63:7:63
    ORG 0xC000-2
    DB  "AABB"
    ASSERT {0x4000-2} == "AA"   ; should be visible also at these addresses
    ASSERT {0x4000} == "BB"

    ORG 0xFFFE
    DB  "CCDD"  ; "DD" goes beyond 0x10000 -> lost (error reported)
    ASSERT {0} == "77"          ; still page 7 there
    ASSERT {0xFFFE} == "CC"

    SAVESNA "toCheck_IsZXSpectrumDevice_method", -1     ;; will error out

    ;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;; non ZX device ;;;;;;
    DEVICE ZXSPECTRUMNEXT
    SAVESNA "toCheck_IsZXSpectrumDevice_method", 0      ;; will error out

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;; non-existent device ;;;;;;
    DEVICE COMMODORE08
    SAVESNA "toCheck_IsZXSpectrumDevice_method", 0      ;; will error out
