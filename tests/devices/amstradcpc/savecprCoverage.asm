; test-coverage cases not covered by regular tests

    DEVICE AMSTRADCPC6128
    SAVECPR "BadDevice.cpr", 2        ; error about wrong device

    DEVICE NONE
    SAVECPR "NoDevice.cpr", 1         ; error about none device

    DEVICE AMSTRADCPCPLUS
    SAVECPR "file.cpr", -1            ; negative number of pages
    SAVECPR "file.cpr", &             ; invalid (parse) page value
    SAVECPR "file.cpr", 33            ; page value out of bound
    SAVECPR ".", 19                   ; fail to open file for write
    SAVECPR "file.cpr",               ; missing page value suggested by comma
    SAVECPR "", 1                     ; empty filename
