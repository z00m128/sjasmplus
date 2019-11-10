mac3    MACRO
.mac3Start:
            jr  nc,$
.mac3End:
        ENDM

    ;; include macro definitions from other file
    INCLUDE     "sld_macro_file.i.asm"

mac4    MACRO
.mac4Start:
            jr  z,$
.mac4End:
        ENDM

    ORG         $A000

    ;; emit macro in "none" device
    DEVICE NONE
NoneEmit1:      mac1
NoneEmit2:      mac1
NoneEmitM3:     mac3
NoneEmitM4:     mac4

    ;; emit macro in ZXN device
    DEVICE ZXSPECTRUMNEXT   : MMU 0 7, 32
NextEmit1:      mac1
NextEmit2:      mac1
NextEmitM3:     mac3
NextEmitM4:     mac4

    CSPECTMAP "sld_macro_file.sym"
