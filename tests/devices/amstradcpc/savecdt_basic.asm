    DEVICE AMSTRADCPC464

    ORG $0
basic_code:
;   10  CLS
.l10    DW .l10sz, 10 : DB $8A, $00
.l10sz  EQU $-.l10
;   20 PRINT "I like rusty spoons"
.l20    DW .l20sz, 20 : DB $BF, "\"I like rusty spoons\"", $00
.l20sz  EQU $-.l20
    .db $00
.sz equ $-basic_code+1

    ORG $7FFF
    DB '1'              ; mark page 1 at end
    DB '2'              ; mark page 2 at beginning

    ORG 0x10000-4
endStart:
    DB '!end'           ; mark end of RAM at $FFFF (to check saving of last byte)
.sz EQU $-endStart
    ASSERT $10000 == endStart + endStart.sz

    MMU $4000, 0        ; map page 0 to slot 1
    MMU $8000, 3, $7FFF ; map page 3 to slot 2
dataStart:
    DB '0'              ; mark page 0 at end
    DB '3'              ; mark page 3 at beginning
.sz EQU $-dataStart

    ; create empty CDT file
    SAVECDT EMPTY "savecdt_basic.cdt"

    ; save valid CPC BASIC example
    SAVECDT BASIC "savecdt_basic.cdt", "A", basic_code, basic_code.sz

    ; first block: pages 0+3
    SAVECDT BASIC "savecdt_basic.cdt","basic1",dataStart,dataStart.sz

    ; second block: pages 1+2
    MMU $4000 $8000, 1  ; map pages 1,2 to slots 1,2
    SAVECDT BASIC "savecdt_basic.cdt","basic2",dataStart,dataStart.sz

    ; third block, saving last bytes of address space
    SAVECDT BASIC "savecdt_basic.cdt","basic3",endStart,endStart.sz
