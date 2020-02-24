; test only valid variants in this test, the invalid/error states are in ramtop.asm
; (because existence of LST file would kill the result of binary compares from .cli run)
; (and .cli is used to make the test work with gzipped binaries)
    DEVICE ZXSPECTRUM128, $5D00
    SAVEDEV "rt5D00.bin", 5, 0, $4000

    ; try one with stack data crossing page boundary
    DEVICE ZXSPECTRUM512, $8000
    SAVEDEV "rt8000.bin", 2, 0, 4*$4000

    ; try RAMTOP at the very end of memory
    DEVICE ZXSPECTRUM256, $FFFF
    SAVEDEV "rtFFFF.bin", 0, 0, $4000
