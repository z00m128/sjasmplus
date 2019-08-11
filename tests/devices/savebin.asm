    DEVICE NONE
    SAVEBIN "fname",0,1     ; error because no device...

    DEVICE ZXSPECTRUM48
    ; syntax errors
    SAVEBIN "fname"
    SAVEBIN "fname",
    SAVEBIN "fname",&
    SAVEBIN "fname",-1
    SAVEBIN "fname",0x10000
    SAVEBIN "fname",,
    SAVEBIN "fname",0xC000,
    SAVEBIN "fname",0xC000,&
    SAVEBIN "fname",0xC000,-1
