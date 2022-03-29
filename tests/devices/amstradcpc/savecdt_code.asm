    DEVICE AMSTRADCPC464

    ORG $7FFF
    DB '1'              ; mark page 1 at end
    DB '2'              ; mark page 2 at beginning
    DB "[5ki:"
    OPT push listoff
    DUP 5*1024-7
      DB low(__COUNTER__)
    EDUP
    OPT pop
    DB "]"

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
    SAVECDT EMPTY "savecdt_code.cdt"

    ; first block: default start address == dataStart, pages 0+3
    SAVECDT CODE "savecdt_code.cdt","code1",dataStart,dataStart.sz

    ; second block: start address + 1, pages 1+2
    MMU $4000 $8000, 1  ; map pages 1,2 to slots 1,2
    SAVECDT CODE "savecdt_code.cdt","code2",dataStart,dataStart.sz,dataStart+1

    ; third block, saving last byte of address space
    SAVECDT CODE "savecdt_code.cdt","code3",endStart,endStart.sz

    ; fourth block, checking truncation of long name
    SAVECDT CODE "savecdt_code.cdt","long name 123456ccccccccccccccccccccc",dataStart,dataStart.sz

    ; fifth block, checking the internal implementation of splitting long chunks into 2048 byte blocks
    SAVECDT CODE "savecdt_code.cdt","code5",$8000,5*1024,$8001
