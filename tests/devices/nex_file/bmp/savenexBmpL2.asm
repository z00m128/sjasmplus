
    DEVICE ZXSPECTRUMNEXT

    ; empty infinite loop as code
    ORG $C000
    di
    jr  $

    ;; OPEN <filename>[,<startAddress>,<stackAddress>[,<entryBank 0..111>]]
    SAVENEX     OPEN    "savenexBmpL2.nex", $C000, $F000
    ;; CORE <major 0..15>,<minor 0..15>,<subminor 0..255>
    SAVENEX     CORE    2,0,0
    ;; CFG <border 0..7>[,<fileHandle 0/1/$4000+>[,<PreserveNextRegs 0/1>[,<2MbRamReq 0/1>]]]
    SAVENEX     CFG     0, 0, 0, 0
    ;; BAR <loadBar 0/1>,<barColour 0..255>[,<startDelay 0..255>[,<bankDelay 0..255>]]
    SAVENEX     BAR     0,  0

    ;; SAVENEX SCREEN BMP <filename>[,<savePalette 0/1>]
    ; errors - [un]expected arguments
    SAVENEX     SCREEN  BMP
    SAVENEX     SCREEN  BMP , 0
    SAVENEX     SCREEN  BMP 9 ,

    ; errors - missing file / invalid files
    SAVENEX     SCREEN  BMP "missing file . bmp"
    SAVENEX     SCREEN  BMP "savenexBmpL2/savenexBmpL2_16color.bmp", 0
    SAVENEX     SCREEN  BMP "savenexBmpL2/savenexBmpL2_256x8.bmp", 0    ;.. shouldn't warn about colors because savePalette = 0
    SAVENEX     SCREEN  BMP "savenexBmpL2/savenexBmpL2_256x8.bmp", 1    ; ok - to suppres "only 10 color" warning

    ; correct one (with two warnings
    SAVENEX     SCREEN  BMP "savenexBmpL2/savenexBmpL2.bmp", 2  ; will warn: savePalette=2, and "only 10 color"

    SAVENEX     BANK    0

    ; revisit screen errors - here no screen should work because bank was written already
    SAVENEX     SCREEN  BMP "savenexBmpL2/savenexBmpL2.bmp"

    SAVENEX     CLOSE
