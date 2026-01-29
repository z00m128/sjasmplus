    ; test RAMTOP -1 for ZX device feature (no memory init, just zeroing)

    ORG $8000 : jr $

    DEVICE ZXSPECTRUM128, -1

    SAVESNA "skip_zx_ram_init.bin", $8000
