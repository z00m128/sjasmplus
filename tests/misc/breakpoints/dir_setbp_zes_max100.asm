    DEVICE ZXSPECTRUM48
    BPLIST "somefile.exp" zesarux

    ; test the "maximum 100 breakpoints" warning for ZEsarUX type of file
    OPT listoff
val_i=0
    DUP 100
        SETBP val_i
val_i=val_i+1
    EDUP
    OPT liston

    SETBP   $EEEE   ; ok ; should do warning (can't be suppressed)
