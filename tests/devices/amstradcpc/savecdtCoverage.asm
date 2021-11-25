; test-coverage cases not covered by regular tests

    DEVICE ZXSPECTRUM48                     ; errors about wrong device
    SAVECDT EMPTY "BadDevice.cdt"
    SAVECDT FULL "BadDevice.cdt"
    SAVECDT BASIC "BadDevice.cdt"
    SAVECDT CODE "BadDevice.cdt"
    SAVECDT HEADLESS "BadDevice.cdt"
    SAVECDT INVALID "BadDevice.cdt"

    DEVICE NONE
    SAVECDT EMPTY "NoDevice.cdt"            ; error about none device

    DEVICE AMSTRADCPC464
    SAVECDT INVALID "BadDevice.cdt"         ; invalid sub-command
    ; empty filename
    SAVECDT EMPTY
    SAVECDT EMPTY ""
    SAVECDT FULL

    ;TODO add further ones with invalid syntax
