
    DEVICE ZXSPECTRUMNEXT
; 18 FE
    ;; OPEN <filename>[,<startAddress>,<stackAddress>[,<entryBank 0..111>]]
    SAVENEX     OPEN    "savenexBmpLoRes.nex", $6000+128*47, $F000
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

    ; errors - missing file
    SAVENEX     SCREEN  BMP "missing file . bmp"

    ; correct one
    SAVENEX     SCREEN  BMP "savenexBmpLoRes/savenexBmpLoRes.bmp"

    ; revisit screen errors - here no screen should work because bank was written already
    SAVENEX     SCREEN  BMP "savenexBmpLoRes/savenexBmpLoRes.bmp"

    SAVENEX     CLOSE
