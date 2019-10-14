    DEVICE ZXSPECTRUMNEXT
    ORG $E000,32
    DISP $8000,1        ; fake page "1" for everything here
DispLabel:              ; sh*t, labels emit no warning about different mapping.
            MMU 4, 1
            nop         ; no warning, mapping is identical
            MMU 4, 4    ; emit warning
DispLabel2:
            nop         ; warning about DISP page being different from current mapping
            nop         ; no warning (warning is emitted only once per whole assembling
    ENT
    DISP $8010
DispLabel3:             ; should derive page number from current mapping
            nop
    ENT
NormalLabel:
            ret
    ASSERT 32 == $$NormalLabel
    ASSERT 1 == $$DispLabel
    ASSERT 1 == $$DispLabel2
    ASSERT 4 == $$DispLabel3

    ; just in the valid range values
    DISP $8000,0
    DISP $8000,223

    ; syntax errors of DISP parser (first in DEVICE mode)
    DISP $8000,         ; syntax error
    DISP $8000,(        ; syntax error
    DISP $8000,512      ; error outside of valid pages
    DISP $8000,-1       ; error outside of valid pages

    DEVICE NONE
    ORG $8000
    DISP $C000,         ; error, only in device mode
    DISP $C000,-1       ; error, only in device mode

    DEVICE ZXSPECTRUMNEXT
    CSPECTMAP "sld_disp.sym"
