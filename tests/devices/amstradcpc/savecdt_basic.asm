    DEVICE AMSTRADCPC464

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

    ; first block: pages 0+3
    SAVECDT BASIC "savecdt_basic.cdt","basic1",dataStart,dataStart.sz

    ; second block: pages 1+2
    MMU $4000 $8000, 1  ; map pages 1,2 to slots 1,2
    SAVECDT BASIC "savecdt_basic.cdt","basic2",dataStart,dataStart.sz

    ; third block, saving last bytes of address space
    SAVECDT BASIC "savecdt_basic.cdt","basic3",endStart,endStart.sz
