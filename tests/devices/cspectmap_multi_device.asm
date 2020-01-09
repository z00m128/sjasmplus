    ;; ZX Spectrum Next device first, also here the CSpect map file is defined
        DEVICE ZXSPECTRUMNEXT : SLOT 6
        CSPECTMAP "cspectmap_multi_device.sym"
        LABELSLIST "cspectmap_multi_device.lbl"

            ; create test labels in various areas of memory (and by various means)
EquLabel    EQU     $1234

DeflLabel   DEFL    $12+1

            STRUCT Struct
Field1      BLOCK   5
Field2      DW      $5678
            ENDS

            ORG $C000, $00
Page00:     daa
.local:
            ORG $C001, $01
Page01:     scf
.local:
            ORG $C00A, $0A
Page0A:     ccf
.local:     rlca
.codeEqu    EQU $+1             ; is like simple EQU => "wrong" physical address

            ORG $DFFE, $0B      ; also raise difficulty by adding extra dots in labels
Page0B.A:   cpl
.local.b:
            ORG $C0DF, $DF
PageDF.A.B: rra
.local.c..d:

            ORG $C030, $30
    MODULE Module
Page30:     rla
.local:
    ENDMODULE

            ORG $C031, $31
    MODULE Module_two_
Page31..A.: rrca
.local..c.:
    ENDMODULE

    ;; now ZX128 device, with different mem-page size (0x4000 vs Next 0x2000)
    ; the most correct outcome would be probably to not export labels from the ZX128
    ; part of test at all, because they belong to different device, but at this moment
    ; the goal of this test and bug-fix is to at least make sure the Next labels are
    ; correctly exported with page size 0x2000 (v1.14.3 does export them wrongly)
        DEVICE ZXSPECTRUM128

        MMU 2, 6
        ORG $8000
SomeZx128Label:
        nop
