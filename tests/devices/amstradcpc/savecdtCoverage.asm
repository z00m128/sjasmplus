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
    SAVECDT BASIC "some.cdt","",0,1,
    SAVECDT BASIC "some.cdt","",0,&
    SAVECDT BASIC "some.cdt","b1",-1,1 ; invalid start address
    SAVECDT BASIC "some.cdt","b2",0x1234,0 ; invalid length
    SAVECDT BASIC "some.cdt","b3",0xFFFF,2 ; invalid start+length
    SAVECDT BASIC "some.cdt","b4",0,0x10000 ; invalid length (64ki block is not possible)

    ; CODE syntax errors
    SAVECDT CODE "some.cdt"
    SAVECDT CODE "some.cdt",
    SAVECDT CODE "some.cdt",""
    SAVECDT CODE "some.cdt","",
    SAVECDT CODE "some.cdt","",0
    SAVECDT CODE "some.cdt","",0,
    SAVECDT CODE "some.cdt","",0,&
    SAVECDT CODE "some.cdt","",0,1,
    SAVECDT CODE "some.cdt","",0,1,&
    SAVECDT CODE "some.cdt","",0,1,0,
    SAVECDT CODE "some.cdt","c1",-1,1 ; invalid start address
    SAVECDT CODE "some.cdt","c2",0x1234,0 ; invalid length
    SAVECDT CODE "some.cdt","c3",0xFFFF,2 ; invalid start+length
    SAVECDT CODE "some.cdt","c4",0,0x10000 ; invalid length (64ki block is not possible)

    ; HEADLESS syntax errors, invalid values
    SAVECDT HEADLESS "some.cdt"
    SAVECDT HEADLESS "some.cdt",
    SAVECDT HEADLESS "some.cdt",0
    SAVECDT HEADLESS "some.cdt",0,
    SAVECDT HEADLESS "some.cdt",0,&
    SAVECDT HEADLESS "some.cdt",0,1,
    SAVECDT HEADLESS "some.cdt",0,1,&
    SAVECDT HEADLESS "some.cdt",0,1,0,
    SAVECDT HEADLESS "some.cdt",0,1,0,2
    SAVECDT HEADLESS "some.cdt",0,1,0,0,
    SAVECDT HEADLESS "some.cdt",-1,1 ; invalid start address
    SAVECDT HEADLESS "some.cdt",0x1234,0 ; invalid length
    SAVECDT HEADLESS "some.cdt",0xFFFF,2 ; invalid start+length
    SAVECDT HEADLESS "some.cdt",0,0x10000 ; invalid length (64ki block is not possible)

    ; FULL syntax errors
    SAVECDT FULL "some.cdt",
    SAVECDT FULL "some.cdt",0,
    SAVECDT FULL "some.cdt",0, 0,0, 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,
    ; not testing dangling comma after each optional value... it works, really...
