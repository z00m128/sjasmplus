    MACRO someMacro1
.macro1:
        jr .skip
        db CSPECT_EASY+1 ; WPMEM
.skip
    ENDM

    MMU 6 n, 20, $C000
mmu6p20:
    docolor %000'000'10 ; blue
    someMacro2
    nextreg $57,30
    jp mmu7p30
    ALIGN $2000
mmu6p21:
    docolor %000'101'10 ; cyan
    someMacro2
    nextreg $57,31
    jp mmu7p31
