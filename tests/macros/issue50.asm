    MACRO m1
        ; commentA
        nop ; comment1
        ; commentB
        nop ; comment2
        nop ; comment3
    ENDM

    MACRO m2
        nop     ; with its own comment m2.nop
    ENDM

    MACRO m3    ; without comment on code line
        nop
    ENDM

    m1

    scf     ; main line m2_1 with comment
    m2

    daa     ; main line m2_2 with comment
    m2      ; macro emit m2_2 with comment

    ccf
    m2      ; macro emit m2_3 with comment

    scf     ; main line m3_1 with comment
    m3

    daa     ; main line m3_2 with comment
    m3      ; macro emit m3_2 with comment

    ccf
    m3      ; macro emit m3_3 with comment
