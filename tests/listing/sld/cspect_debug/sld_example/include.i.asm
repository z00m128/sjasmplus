    MACRO someMacro2
.macro2:
        someMacro1
        jr .skip
        db CSPECT_EASY+2 ; WPMEM
.skip
    ENDM

    INCLUDE "../sld_example.i.asm"

    MMU 7 n, 30, $E000
mmu7p30:
    docolor %000'101'00 ; green
    someMacro1
    nextreg $56,21
    jp mmu6p21
    ALIGN $2000
mmu7p31:
    docolor %101'101'00 ; yellow
    someMacro1
    nextreg $56,22
    ret
