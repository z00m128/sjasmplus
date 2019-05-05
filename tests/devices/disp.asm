    DEVICE ZXSPECTRUM128
    SLOT 0 : PAGE 0 : SLOT 1 : PAGE 1 :  SLOT 2 : PAGE 2 : SLOT 3 : PAGE 3
    ORG     0x4000-2
orgLabel:
    DISP    0xC000-1
dispLabel:
    set     5,(ix+0x41)     ; 4B opcode across both ORG and DISP boundaries
    ENT
    ORG     0x8000-2
orgLabel2:
    DISP    0xC000-3
dispLabel2:
    set     5,(ix+0x41)
    ENT
    ; verification of results
    DW      {0x4000-2}, {0x4000}, {0x8000-2}, {0x8000}, {0xC000-2}, {0xC000}
