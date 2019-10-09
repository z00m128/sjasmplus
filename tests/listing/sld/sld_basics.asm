    IFDEF recursively_included
    ; this part is included from this same file at the end of regular part
        DEVICE ZXSPECTRUMNEXT
                    ORG $F000           ; these should be page 63 set by non-included code
IncludedLabel:          rst $00
.localLabel1:           rst $08
Including2ndFile:   INCLUDE "sld_basics.i.asm"      ; and try here also regular non-recursive include
    ; following part is the "regular" one, which will include the part above
    ELSE

    DEVICE ZXSPECTRUMNEXT
    CSPECTMAP "sld_basics.sym"
        MODULE next
                    ORG $DFFF, 63       ; page 63 into E000..FFFF region (slot 7 active)
.localLabel1:           nop             ; but these are still in page 0 in C000..DFFF
.localLabel2:           daa             ; these should be in page 63
.localEqu1          EQU $CCCC

testMacro       MACRO
                    ; macro definition should not affect anything here
.localFromMacro:
                ENDM

.localEqu2          EQU $EEEE
.localVar           = $1111             ; DEFL/= symbol-variables are excluded from SLD
                        testMacro       ; shouldn't emit machine code either
.localLabel3            ret             ; this one should
.someDbBytes            DZ      "Hello 1337!"
        ENDMODULE

    DEVICE NONE
        MODULE no_device
                    ORG $E100
DeviceNoneLabel:        scf             ; both should produce page -1
.localEqu2          EQU $EEEF
.localVar           = $1112             ; DEFL/= symbol-variables are excluded from SLD
                        testMacro       ; shouldn't emit machine code either
.someDbBytes            DZ      "Hello 1337!"
        ENDMODULE

    DEVICE ZXSPECTRUM48                 ; just to test device data

    DEVICE ZXSPECTRUM128
        MODULE zx128
                    ORG $BFFF,4         ; page 4 into C000..FFFF region (slot 3 active)
DeviceZx128Label1:      cpl             ; for 8000..BFFF the default page is 2
DeviceZx128Label2:      rrca            ; for C000..FFFF the page is 4
Zx128Equ            EQU $CCCC
.localEqu2          EQU $EEF0
.localVar           = $1113             ; DEFL/= symbol-variables are excluded from SLD
                        testMacro       ; shouldn't emit machine code either
.someDbBytes            DZ      "Hello 1337!"
        ENDMODULE

        DEFINE  recursively_included
        INCLUDE "sld_basics.asm"
    ENDIF
