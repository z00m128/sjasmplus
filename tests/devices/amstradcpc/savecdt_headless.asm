    DEVICE AMSTRADCPC464

    ORG $7FFF
    DB '1'      ; mark page 1 at end
    DB '2'      ; mark page 2 at beginning

    ORG 0x10000-4
endStart:
    DB '!end'           ; mark end of RAM at $FFFF (to check saving of last byte)
.sz EQU $-endStart
    ASSERT $10000 == endStart + endStart.sz

    MMU $4000, 0, $7FFF ; map page 0 to slot 1
    MMU $8000, 3, $7FFF ; map page 3 to slot 2
dataStart:
    DB '0'      ; mark page 0 at end
    DB '3'      ; mark page 3 at beginning
dataLength equ $-dataStart

    ; create empty CDT file
    SAVECDT EMPTY "savecdt_headless.cdt"

    ; first block: default sync, default format (amstrad), pages 0+3
    SAVECDT HEADLESS "savecdt_headless.cdt",dataStart,dataLength

    ; second block: sync $AA, default format, pages 1+2
    MMU $4000 $8000, 1      ; map pages 1,2 to slots 1,2
    SAVECDT HEADLESS "savecdt_headless.cdt",dataStart,dataLength,$AA

    ; third block: sync $BB, spectrum format, pages 0+2
    MMU $4000, 0            ; map page 0 to slot 1
    SAVECDT HEADLESS "savecdt_headless.cdt",dataStart,dataLength,$BB,1

    ; fourth block: sync $CC, amstrad format, pages 0+3
    MMU $8000, 3            ; map page 3 to slot 2
    SAVECDT HEADLESS "savecdt_headless.cdt",dataStart,dataLength,$CC,0

    ; fifth block: sync $DD, amstrad format, end of RAM
    SAVECDT HEADLESS "savecdt_headless.cdt",endStart,endStart.sz,$DD,0
