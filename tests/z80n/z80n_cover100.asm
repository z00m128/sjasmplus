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

    ;; part 3 (new commit, focusing on branching in the code, exercising more combinations and code paths)
    ; these tests (whole this file) are unfortunately very implementation based, in case of major refactorings they may
    ; quickly lose their functionality (the machine code produced should be the same, but code coverage may regress).

    add     hl,1234
    add     hl,a
    push    1234

    ;; part 4 (more of the branching stuff, handpicked from local detailed coverage report)

    OPT reset --syntax=ab --zxnext
    add     de,b
    bsra    de
    bsra    de,a
    brlc    de
    brlc    de,
    brlc    de,a

    OPT reset --syntax=abF --zxnext
    mul
    mul     d
    mul     d,c

    ; code coverage for clrbrk/setbrk argument parsing errors:
    OPT reset --syntax=abF --zxnext=cspect
    clrbrk
    clrbrk  $EE
    clrbrk  $EE,
    clrbrk  $EE, $EEEE
    clrbrk  $EE, $EEEE,
    setbrk
    setbrk  $EE
    setbrk  $EE,
    setbrk  $EE, $EEEE
    setbrk  $EE, $EEEE,
