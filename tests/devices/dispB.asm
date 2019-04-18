; same test as disp.asm, but with 1B opcode instructions
    DEVICE ZXSPECTRUM128
    SLOT 0 : PAGE 0 : SLOT 1 : PAGE 1 :  SLOT 2 : PAGE 2 : SLOT 3 : PAGE 3
    ORG     0x4000-2
orgLabel:
    DISP    0xC000-1
dispLabel:
    ld b,c : ld b,d : ld b,e : ld b,h
    ENT
    ORG     0x8000-2
orgLabel2:
    DISP    0xC000-3
dispLabel2:
    ld b,c : ld b,d : ld b,e : ld b,h
    ENT
    ; verification of results
    DW      {0x4000-2}, {0x4000}, {0x8000-2}, {0x8000}, {0xC000-2}, {0xC000}
