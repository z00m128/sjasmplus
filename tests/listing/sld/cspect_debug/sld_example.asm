; a bit "like real" example with actual ZX Next binary to verify some debugger the SLD parsing
; to launch the final NEX file in CSpect with map file:
;  CSpect.exe [your other preferred options] -map=sld_example.sym sld_example.nex
    DEVICE ZXSPECTRUMNEXT
    SLDOPT COMMENT WPMEM

WAIT_DELAY EQU 21
CSPECT_EASY EQU $A8     ; use $00 to confuse CSpect disassembly window in single-stepping

    MACRO docolor col8b?
        nextreg $4A,col8b?  ; transparency fallback register
        ld b,WAIT_DELAY
        djnz $
    ENDM

    INCLUDE "sld_example/include.i.asm"

    ORG 35000
start:
    di
    nextreg $07,0       ; 3.5MHz
    nextreg $68,$80     ; switch ULA off
.loop:
    someMacro1
    someMacro2
    nextreg $56,20
    call mmu6p20
    docolor $00         ; black
    nextreg $57,32
    jr .loop

    SAVENEX OPEN "sld_example.nex", start, 40000 : SAVENEX AUTO : SAVENEX CLOSE
    CSPECTMAP "sld_example.sym"
