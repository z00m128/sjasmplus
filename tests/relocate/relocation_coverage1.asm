    ORG $1000

    RELOCATE_START

    RELOCATE_START      ; error 2x start

    dw      relocate_count
    dw      relocate_size

label1:
    call    label1
    ld      a,high label1   ; warning about unstable expression
label2:
    ld      a,high(4*label2) - high(2*label1)   ; warning about unstable expression
    ld      a,high(8*label2) - high(8*label1)   ; this one is stable (no warning)

    ld      a,high label2   ; ok ; warning supressed

    RELOCATE_END

    RELOCATE_TABLE

    RELOCATE_END        ; error about missing START
    RELOCATE_START      ; error about missing END
