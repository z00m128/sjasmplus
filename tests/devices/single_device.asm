    ; when only single DEVICE directive is used in whole source, the DEVICE becomes "global"

    ; do device-only things before declaring actual DEVICE
    ORG 0x8000
binStart:
    BLOCK   8, 8        ; 8x value 8
binEnd:
    SAVEBIN "single_device.bin", 0x8000, binEnd-binStart

    ; set ZX48 as global device
    DEVICE ZXSPECTRUM48
