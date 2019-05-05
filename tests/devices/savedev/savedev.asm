; test only valid variants in this test, the invalid/error states are in savedevB.asm
; (because existence of LST file would kill the result of binary compares from .cli run)
; (and .cli is used to make the test work with gzipped binaries)
; The test binaries do contain also ordinary ZX128 default RAM area values (CLS, sysvar,
; stack), so any changes to the device in future will make binaries obsolete = update it.
    DEVICE ZXSPECTRUM128
    MMU 0 3, 0      ; map pages 0,1,2,3, write tags into them
    ORG $0000 : DB "00" : ORG $4000 : DB "11" : ORG $8000 : DB "22" : ORG $C000 : DB "33"
    MMU 0 3, 4      ; map pages 0,1,2,3, write tags into them
    ORG $0000 : DB "44" : ORG $4000 : DB "55" : ORG $8000 : DB "66" : ORG $C000 : DB "77"
    ; save 128kiB binary blob of whole device memory
    SAVEDEV "savedev1.bin", 0, 0x0000, 0x20000
    SAVEDEV "savedev2.bin", 1, 0x0000, 0x20000-0xBFFE   ; save second blob from "11".."66"
    SAVEDEV "savedev3.bin", 0, 0x4000, 0x20000-0xBFFE   ; third blob from "11".."66"
                        ; ^^^ by using start offset instead of page
