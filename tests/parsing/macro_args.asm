    ;; defines to require multi define-substitution
    DEFINE _zzzzz _zzzz
    DEFINE _zzzz _zzz
    DEFINE _zzz _zz
    DEFINE _zz _z
    DEFINE _z hl

    MACRO ccc varX?, varY?, varZ?
        DUP (varX?) & 0x03
        ld  a,varX?
        EDUP
        call .varY?_varZ?
.varY?_varZ?:
    ENDM

    MACRO xxx
        DUP 2
1:
        ld _zzzzz,0x1234
        jr  1B
        EDUP
.labTest:
        ccc 2, yyy, _zzzzz
    ENDM

    MACRO macDB a1?, a2?, a3?, a4?, a5?, a6?
        db a1?, a2?, a3?, a4?, a5?, a6?
    ENDM

    xxx

    DUP 2
    ret
    ld  _zzzzz,0x56AB
    xxx     ; emit macro
    ccc 'd''d' | 0x2, first, second
    EDUP

    ; expected end result of following macDB usage
    db      1 + 14, "a\A\"", 'x''y', 4, 5, ">!!x", '''\', "\\"
    ; test:
    macDB   1 + 14, "a\A\"", 'x''y', <4, 5, "!>!!!x">, '''\', "\\"

    // warning on empty argument
    ccc  13, , second
    // too few/many argument errors
    ccc  5, 6
    ccc  7, 8, 9, 10
