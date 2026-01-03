    MODULE Whatever

MethodA:
    STRUCT .Data        ; local to MethodA
X1l  BYTE
X2l  BYTE
    ENDS
Md  .Data { 12, 34 }    ; <- WORKS in v1.21.0

    STRUCT Data         ; inside module (standalone)
X1m  BYTE
X2m  BYTE
    ENDS

    STRUCT @Data        ; global (no module prefix)
X1g  BYTE
X2g  BYTE
    ENDS

Md2 MethodA.Data { 12, 34 }     ; <- FAILS in v1.21.0
; ^ error: Unrecognized instruction: MethodA.Data { 12, 34 }
Md3 Data { 12, 34 }
Md4 @Data { 12, 34 }

MethodB:
    STRUCT .Data        ; local to MethodB
BX1l  BYTE
BX2l  BYTE
    ENDS
    STRUCT .Data        ; local to MethodB ; <- should fail, duplicity
xBX1l  BYTE
xBX2l  BYTE
    ENDS
Mdb .Data { 23, 45 }    ; <- WORKS in v1.21.0

    ; test self-reference check
MethodC:
    STRUCT .Data
.CC1    BYTE    $67
.self1: .Data
.self2: MethodC.Data
.self3: Whatever.MethodC.Data
    ENDS

Mdc1    .Data
Mdc2    MethodC.Data
Mdc3    Whatever.MethodC.Data

        ld a,(Mdc1.CC1)
        ld a,(Mdc2.CC1)
.lMdc3: ld a,(Mdc3.CC1)
        ld a,(Whatever.Mdc1.CC1)
        ld a,(Whatever.Mdc2.CC1)
        ld a,(Whatever.Mdc3.CC1)

    ENDMODULE

MahInstanceGlob    Data { 12, 34 }
MahInstanceMod     Whatever.Data { 12, 34 }
MahInstanceLoc     Whatever.MethodA.Data { 12, 34 } ; <- FAILS in v1.21.0
; ^ error: Unrecognized instruction: Whatever.MethodA.Data { 12, 34 }
        ld a,(MahInstanceGlob.X1g)
        ld a,(MahInstanceMod.X1m)
        ld a,(MahInstanceLoc.X1l)
        ld a,(Whatever.Md4.X1g)
        ld a,(Whatever.Md3.X1m)
        ld a,(Whatever.Md2.X1l)
        ld a,(Whatever.Mdc1.CC1)
        ld a,(Whatever.Mdc2.CC1)
        ld a,(Whatever.Mdc3.CC1)

%as     Whatever.MethodC.Data   ; invalid labelname error reporting check

    DEVICE ZXSPECTRUMNEXT       ; setup global device for SLD file test

























    ; reserving 100+ lines
