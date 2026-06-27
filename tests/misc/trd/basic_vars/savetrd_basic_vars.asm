    ; test SAVETRD with "BASIC", using the extra optional argument for size w/o BASIC variables
    device zxspectrum128
    ORG #4000
    DB 1,2,3,4      ; fake "BASIC" program

    EMPTYTRD "savetrd_basic_vars.trd","bas_vars"    ; create empty TRD image

    SAVETRD "savetrd_basic_vars.trd","0.B",#4000,21             ; valid, no autoline, no size w/o vars
    SAVETRD "savetrd_basic_vars.trd","1.B",#4000,21,34          ; valid, autoline 34, no size w/o vars
    SAVETRD "savetrd_basic_vars.trd","2.B",#4000,21,35,10       ; valid, autoline 34, size w/o vars 10

    ; parsing or logical errors
    SAVETRD "savetrd_basic_vars.trd","e0.B",#4000,21,36,21+1    ; size w/o vars too big
    SAVETRD "savetrd_basic_vars.trd","e1.B",#4000,21,37,        ; missing size w/o vars
    SAVETRD "savetrd_basic_vars.trd","e2.B",#4000,21,           ; missing autoline
    SAVETRD "savetrd_basic_vars.trd","e3.B",#4000,21,38,10,     ; extra comma
    SAVETRD "savetrd_basic_vars.trd","e4.C",#4000,21,39,10      ; not a BASIC file
    SAVETRD "savetrd_basic_vars.trd","e5.B",#4000,21,-2,10      ; negative autoline = error

    ; valid since v1.24.0:
    SAVETRD "savetrd_basic_vars.trd","3.B",#4000,21,-1,10       ; valid, no autoline, size w/o vars 10
        ; useful when user wants to add own autostart tag and fill up remaining bytes of sector
        ; with custom easter egg message: https://github.com/z00m128/sjasmplus/issues/286
        ; so the size w/o vars will be what catalogue will show and full size will be written as raw data to sector
