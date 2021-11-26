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

    ; BASIC syntax errors
    SAVECDT BASIC "some.cdt"
    SAVECDT BASIC "some.cdt",
    SAVECDT BASIC "some.cdt",""
    SAVECDT BASIC "some.cdt","",
    SAVECDT BASIC "some.cdt","",0
    SAVECDT BASIC "some.cdt","",0,
    SAVECDT BASIC "some.cdt","",0,0,
    SAVECDT BASIC "some.cdt","",0,&

    ; CODE syntax errors
    SAVECDT CODE "some.cdt"
    SAVECDT CODE "some.cdt",
    SAVECDT CODE "some.cdt",""
    SAVECDT CODE "some.cdt","",
    SAVECDT CODE "some.cdt","",0
    SAVECDT CODE "some.cdt","",0,
    SAVECDT CODE "some.cdt","",0,&
    SAVECDT CODE "some.cdt","",0,0,
    SAVECDT CODE "some.cdt","",0,0,&
    SAVECDT CODE "some.cdt","",0,0,0,

    ; HEADLESS syntax errors, invalid values
    SAVECDT HEADLESS "some.cdt"
    SAVECDT HEADLESS "some.cdt",
    SAVECDT HEADLESS "some.cdt",0
    SAVECDT HEADLESS "some.cdt",0,
    SAVECDT HEADLESS "some.cdt",0,&
    SAVECDT HEADLESS "some.cdt",0,0,
    SAVECDT HEADLESS "some.cdt",0,0,&
    SAVECDT HEADLESS "some.cdt",0,0,0,
    SAVECDT HEADLESS "some.cdt",0,0,0,2
    SAVECDT HEADLESS "some.cdt",0,0,0,0,

    ; FULL syntax errors
    SAVECDT FULL "some.cdt",
    ;TODO more of it...
