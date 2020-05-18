    DEVICE ZXSPECTRUM48
    OUTPUT "outprefix.raw"
    EMPTYTAP "outprefix.tap"
    BPLIST "outprefix.exp" zesarux

    ORG $8000
start:
    SETBP
    jr      $
    DB      "AB"

    ; save it to call the code paths, but the content/existence is not verified
    SAVESNA "outprefix.sna", $8000
    SAVEDEV "outprefix.dev", 0, $8000, 4

    ; files which will be verified by test script (content wise)
    SAVETAP "outprefix.tap", CODE, "out", $8000, 4
    SAVEBIN "outprefix.bin", $8000, 4
    LABELSLIST "outprefix.lbl"
    CSPECTMAP "outprefix.sym"
