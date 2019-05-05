    DEVICE ZXSPECTRUMNEXT : SLOT 7 : LABELSLIST "incbin80k.lbl"
    ; incbin80k.bin is from offset 2 letters 'a' to 't' with linux newlines (byte 10)
    ; for each letter, there's 80 of them + newline, repeated 51 times
    ; such one letter block = 51*81 = 4131 bytes (just over 4ki), there's 20 letters
    ; = 82620 bytes (plus 2 bytes at beginning making it "binary" file for git)

    ; try short incbin (no paging) first into page 20
    ORG 0xE000
    MMU 7 n, 20
short_start:
    INCBIN "incbin80k/incbin80k.bin",2,81
short_end:
    ASSERT $$ == 20 && $ == 0xE000 + 81
    ASSERT {0xE000} == "aa" && {0xE000+79} == "\na"

    ; try 3-page long incbin into pages 21, 22, 23
    MMU 7 n, 21
    ORG 0xE000
p3_start:
    INCBIN "incbin80k/incbin80k.bin",2,81*51*4      ; include four letters (16524 bytes)
p3_end:
    PAGE 21 : ASSERT {0xE000} == "aa" && {0xE000+79} == "\na" && {0xE000+81*51} == "bb" && {0xFFFE} == "bb"
    PAGE 22 : ASSERT {0xE000} == "bb" && {0xE000+81*102-0x2000-2} == "\nb"
    ASSERT {0xE000+81*102-0x2000} == "cc" && {0xE000+81*153-0x2000-2} == "\nc"
    ASSERT {0xE000+81*153-0x2000} == "dd" && {0xFFFE} == "dd"
    PAGE 23 : ASSERT {0xE000} == "dd" && {0xE000+81*204-0x4000-2} == "\nd"
    ASSERT {0xE000+81*204-0x4000} == 0

    ; try error by including beyond device RAM range
    MMU 7, 23       ; reset wrapping behaviour for slot 7, keep page 23
err_start:
    INCBIN "incbin80k/incbin80k.bin",2,81*51*2      ; include two letters (8+ki)
err_end:

    ; try full length 80+ki binary include
    MMU 7 n, 30     ; map pages 30, 31, 32, .., 40 (11 pages long)
    ORG 0xE000
long_start:
    INCBIN "incbin80k/incbin80k.bin",2          ; include 20 letters from offset 2
long_end:
    PAGE 30 : ASSERT {0xE000} == "aa" && {0xE000+79} == "\na" && {0xE000+81*51} == "bb" && {0xFFFE} == "bb"
    PAGE 31 : ASSERT {0xE000} == "bb" && {0xE000+81*102-0x2000-2} == "\nb"
    ASSERT {0xE000+81*102-0x2000} == "cc" && {0xE000+81*153-0x2000-2} == "\nc"
    ASSERT {0xE000+81*153-0x2000} == "dd" && {0xFFFE} == "dd"
    PAGE 32 : ASSERT {0xE000} == "dd" && {0xE000+81*204-0x4000-2} == "\nd"
    ASSERT {0xE000+81*204-0x4000} == "ee" && {0xE000+81*255-0x4000-2} == "\ne"
    PAGE 37 : ASSERT {0xE000} == "nn" && {0xE000+81*51*14-0xE000-2} == "\nn"
    ASSERT {0xE000+81*51*14-0xE000} == "oo" && {0xE000+81*51*15-0xE000-2} == "\no"
    ASSERT {0xE000+81*51*15-0xE000} == "pp" && {0xFFFE} == "pp"
    PAGE 38 : ASSERT {0xE000} == "pp" && {0xE000+81*51*16-0x10000-2} == "\np"
    ASSERT {0xE000+81*51*16-0x10000} == "qq" && {0xE000+81*51*17-0x10000-2} == "\nq"
    ASSERT {0xE000+81*51*17-0x10000} == "rr" && {0xFFFE} == "rr"
    PAGE 40 : ASSERT {0xE000} == "tt" && {0xE000+81*51*20-0x14000-2} == "\nt"
    ASSERT {0xE000+81*51*20-0x14000} == 0 && {0xFFFE} == 0

    ; incbin in no-device mode: includes whole file, addressing goes into 16+ bit realm
    DEVICE NONE
    ORG 0xE000
nodevice_start:
    INCBIN "incbin80k/incbin80k.bin",2          ; include 20 letters from offset 2
nodevice_end:                                   ; emits warning about going over 0x10000

    ; switch back to ZX Next to produce labels list
    ORG 0 : DEVICE ZXSPECTRUMNEXT   ; slot 7 is still in "wrap", but $ is beyond (error) => org 0 needed

    ; one more test of case when even wrapping MMU runs out of next pages
    MMU 7 n, 222                    ; two pages left: 222, 223, try to include 3 pages
    ORG 0xE000
noram_start:                        ; emit error of running out of free memory pages
    INCBIN "incbin80k/incbin80k.bin",2,81*51*4  ; include four letters (16524 bytes)
noram_end:
    PAGE 222 : ASSERT {0xE000} == "aa" && {0xE000+79} == "\na" && {0xE000+81*51} == "bb" && {0xFFFE} == "bb"
    PAGE 223 : ASSERT {0xE000} == "bb" && {0xE000+81*102-0x2000-2} == "\nb"
    ASSERT {0xE000+81*102-0x2000} == "cc" && {0xE000+81*153-0x2000-2} == "\nc"
    ASSERT {0xE000+81*153-0x2000} == "dd" && {0xFFFE} == "dd"

    nop                             ; check error message wording in case of further write
