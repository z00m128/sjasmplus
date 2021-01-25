; this test is based on Omega (CZ demo scener) issue report, when local label defined
; after structure instance did use as "main" label the last inner-field of structure
; instead of the main structure name. (ie. ".data" after "test: sss" got expanded as
; "test.there.data" instead of expected "test.data")
; - the initial test got extended also with macro emit and structure with local name
; - and SLD file, as it took some effort to get at least somewhat meaningful output

    DEVICE ZXSPECTRUM48

    STRUCT nestS
nested1:    byte
nested2:    word
    ENDS

    STRUCT sss
what:   db 0
where:  dw 0
how:    nestS {$12, $3456}
there:  db 0
    ENDS

    ORG $ABCD
test: sss $23,.data,{,.data},$45
.t2:  sss $56,.t2,{,.t2},$78
.data db $EF

    ORG $9876
    MACRO defineStruct naam?
naam?   sss $23,.data,{,.data},$45
.naam?  sss $56,.naam?,{,.naam?},$78
.data   db $DC
    ENDM

    defineStruct fromM
