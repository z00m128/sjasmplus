    ;; few more test cases not covered by regular tests,
    ;; but were discovered by code coverage as code not executed in tests

    ; some tests need more strict syntax rules to hit specific code paths
    OPT reset --syntax=ab --zxnext

    add     hl,[1234        ; "Operand expected" error

    brlc    hl,b            ; "only DE,B arguments" error
    bsla    hl,b
    bsra    hl,b
    bsrl    hl,b
    bsrf    hl,b
    nextreg a,$1            ; "first operand should be register number" error

    OPT reset --syntax=ab   ; disable Z80N extensions for "Z80N disabled" error
    brlc    de,b
    bsla    de,b
    bsra    de,b
    bsrl    de,b
    bsrf    de,b
    lddrx
    lddx
    ldirx
    ldix
    ldpirx
    ldws
    mul     de
    nextreg $1,$2
    nextreg $3,a
    outinb
    pixelad
    pixelad hl
    pixeldn
    pixeldn hl
    setae
    setae   a
    swapnib
    swapnib a
    test    1
