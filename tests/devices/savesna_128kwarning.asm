; check if warning about only-128k save to snapshot is emitted

    ; no warning for regular zx48 and zx128
    DEVICE ZXSPECTRUM48
    SAVESNA "zx48.sna", $8000
    DEVICE ZXSPECTRUM128
    SAVESNA "zx128.sna", $8000

    ; the larger ZX-like devices should emit warning when SAVESNA is used
    DEVICE ZXSPECTRUM256
    SAVESNA "zx256.sna", $8000
    DEVICE ZXSPECTRUM512
    SAVESNA "zx512.sna", $8000
    DEVICE ZXSPECTRUM1024
    SAVESNA "zx1024.sna", $8000
    ; not implemented yet (2MiB and 4MiB spectrum-like devices) - errors
    ; (probably going to be added soon, so I'm leaving it here in the test)
    DEVICE ZXSPECTRUM2048
    SAVESNA "zx2048.sna", $8000
    DEVICE ZXSPECTRUM4096
    SAVESNA "zx4096.sna", $8000
