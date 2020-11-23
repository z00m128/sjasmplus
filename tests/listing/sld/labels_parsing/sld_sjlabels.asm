    DEVICE ZXSPECTRUMNEXT

    MACRO testMacro arg1?
        IF 0 == arg1? : testMacro 1 : ENDIF
.macro_local.1:
        ret
    ENDM

    ORG $8000
.no_main_local.1e: EQU 123
.no_main_local.1:   ; has no main label, will become "_.no_main_local"
        xor a
        jr nz,.no_main_local.1
        jr z,main.1.local.1
main.1e: EQU 234
main.1:
        halt
        testMacro 0
.local.1e: EQU 345
.local.1:
        xor a
        jr nz,.local.1
        jr nz,_.no_main_local.1

    MODULE module@1
        RELOCATE_START
.no_main_local.2e: EQU 456
.no_main_local.2:
        xor a
        jr nz,.no_main_local.2
        jr z,main.2.local.2
main.2e: EQU 567
main.2:
        RELOCATE_END
        halt
        testMacro 0
.local.2e: EQU 678
.local.2:
        xor a
@main.1.local.2e: EQU 789   ; fake global label looking like another local
@main.1.local.2:    ; fake global label looking like another local
        jr nz,main.2.local.2
        jr nz,_.no_main_local.2
    ENDMODULE

    DW _.no_main_local.1e, module@1.main.2.local.2e
