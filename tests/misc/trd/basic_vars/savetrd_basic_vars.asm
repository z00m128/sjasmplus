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
