    DEVICE none
    BLOCK   -8000,11
    DISP    0x1234
    BLOCK   -8000,12
    ENDT
    SAVEBIN "sjio_coverage4.bin", 1, 2  ; no device error

    DEVICE zxspectrum48
    BLOCK   -8000,13
    ORG     0xFFFC
    DB      "AHOY"
    SAVEBIN "sjio_coverage4.bin", 0xFFFC        ; no length argument
    SAVEBIN "sjio_coverage4.tap", 0xFFFC, 1000  ; length beyond end of RAM
