    ;; based on real bug (already fixed in previous commit)
    OUTPUT macro_args2.bin

    ;; defines to require multi define-substitution
    DEFINE _zzzzz _zzzz
    DEFINE _zzzz _zzz
    DEFINE _zzz _zz
    DEFINE _zz _z
    DEFINE _z hl

    MACRO ccc cond?, val1?, val2?
        IF cond?
            ld  _zzzzz,val1? | #2000
        ELSE
            ld  _zzzzz,val2? | #2000
        ENDIF
    ENDM

    ;; the angle-brackets should be used as delimiters only at begin/end positions of argument
COND_VAL=6
    DUP     4
    ccc     COND_VAL < 8, #44 << 4, #5500 >> 4  ; these <> are regular less-than and shifts
COND_VAL=COND_VAL+1
    EDUP
