    EXPORT                      ; syntax error
    EXPORT  !                   ; syntax error 2
    EXPORT  nonExistentLabel    ; label not found error
    EXPORT  fwdRefNormal
    EXPORT  .fwdRefLocal        ; this is error, the main label here is undefined ("_")
    EXPORT  fwdRefNormal.fwdRefLocal
    EXPORT  @fwdRefNormal.fwdRefLocal   ; "@" is not supported in EXPORT ???!?!
    EXPORT  fwdRefEqu
    EXPORT  fwdRefDefl
    ORG     0x1234
fwdRefNormal:   nop
.fwdRefLocal:   ldir
fwdRefEqu:      EQU     0x2345
fwdRefDefl:     DEFL    0x3456
LabelNormal:    nop
.LabelLocal:    ldir
LabelEqu:       EQU     0x2345+1
LabelDefl:      DEFL    0x3456+1
    .EXPORT LabelNormal
    .EXPORT .LabelLocal         ; this is error, it will try to find LabelDefl.LabelLocal
    .EXPORT LabelNormal.LabelLocal
    .EXPORT @LabelNormal.LabelLocal
    export  LabelEqu
    .export LabelDefl
    EXPORT  LabelNormal         ; double export is not problem of sjasmplus, but coder

    ; check if the exports are always global
    EXPORT  aha.hehe.hihi
    MODULE  aha
    EXPORT  aha.hehe.hoho
hehe
.hihi
.hoho
    ENDMODULE