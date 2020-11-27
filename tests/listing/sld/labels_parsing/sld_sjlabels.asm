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

    STRUCT S_TEST, 10
byte    BYTE    0x12
word    WORD    0x3456
    ENDS

data:
.s1     S_TEST
.s2     S_TEST { 0x78, 0x9ABC }
s3      S_TEST { 0xDE, 0xF023 }

    ld  ix,data.s2
    ld  a,(ix+S_TEST.word)
    ld  (s3.word),a
    ld  de,S_TEST
    add ix,de

    ; same stuff, but in module m2 (!)
    MODULE m2
    STRUCT S_TEST, 10
byte    BYTE    0x12
word    WORD    0x3456
    ENDS

data:
.s1     S_TEST
.s2     S_TEST { 0x78, 0x9ABC }
s3      S_TEST { 0xDE, 0xF023 }

    ld  ix,data.s2
    ld  a,(ix+S_TEST.word)
    ld  (s3.word),a
    ld  de,S_TEST
    add ix,de
    ENDMODULE
