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

    ; newly added devices, exercise also the new mem-page limits, etc..
    DEVICE ZXSPECTRUM2048
    PAGE 127    ; good
    PAGE 128    ; error
    SAVESNA "zx2048.sna", $8000
    SAVEDEV "m2048_end.bin", 127, 0, 0x4000 ; good
    SAVEDEV "m2048_end.bin", 127, 0, 0x4001 ; error

    DEVICE ZXSPECTRUM4096
    PAGE 255    ; good
    PAGE 256    ; error
    SAVESNA "zx4096.sna", $8000
    SAVEDEV "m4096_end.bin", 255, 0, 0x4000 ; good
    SAVEDEV "m4096_end.bin", 255, 0, 0x4001 ; error

    DEVICE ZXSPECTRUM8192
    PAGE 511    ; good
    PAGE 512    ; error
    SAVESNA "zx8192.sna", $8000
    SAVEDEV "m8192_end.bin", 511, 0, 0x4000 ; good
    SAVEDEV "m8192_end.bin", 511, 0, 0x4001 ; error

    ; check suppression of "only 128k" warning
    DEVICE ZXSPECTRUM256
    SAVESNA "zx256.sna", $8000  ; suppress sna128-ok

    ; check 48k snapshot warning about screen overwritten
    DEVICE ZXSPECTRUM48         ; default stack is already tainted by previous SAVESNA!
    SAVESNA "zx48.sna", $8000   ; emit warning
    SAVESNA "zx48.sna", $8000   ; suppress sna48-ok

    ; check fail-to-open file is non-fatal
    SAVESNA "", $8000 ; sna48-ok
