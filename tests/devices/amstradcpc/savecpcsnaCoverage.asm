; test-coverage cases not covered by regular tests

    DEVICE ZXSPECTRUM48
    SAVECPCSNA "BadDevice.sna", $1234       ; error about wrong device

    DEVICE NONE
    SAVECPCSNA "NoDevice.sna", $1234        ; error about none device

    DEVICE AMSTRADCPC464
    SAVECPCSNA "file.sna", -1               ; negative start value
    SAVECPCSNA "file.sna", &                ; invalid (parse) start value
    SAVECPCSNA "file.sna"                   ; no start address defined
