            DEVICE NONE         ; set "none" explicitly, to avoid "global device" feature
            CSPECTMAP           ; error about non-device mode
            DEVICE ZXSPECTRUMNEXT : SLOT 6
            CSPECTMAP "cspectmap.sym"   ; default-name variant is tested only manually
;             CSPECTMAP ; default-name is source name with ".map" appended (tested manually)
            LABELSLIST "cspectmap.lbl"

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

.local.local:       ; TODO this will be incorrectly marked as local at second dot
    ; but it will stay so, because A) not simple to fix B) works often better for UX

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

    ; exporting of struct-emit labels should contain the correct physical address too
s1          Struct { 0x1234 }
