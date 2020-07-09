    ; test new RAMTOP feature against the "global device" feature

    ORG $8000 : jr $

    DEVICE ZXSPECTRUM48, $7FFF

    SAVESNA "ramtop_global.bin", $8000
