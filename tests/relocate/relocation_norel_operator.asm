    ORG $1000

    RELOCATE_START

norel:  jp norel        ; "norel" as label itself (should relocate)
    jp norel norel      ; should not relocate

label1:
    call    label1                      ; should relocate
    call    nc,norel   label1           ; should not relocate
    call    nz,norel(label1)            ; should not relocate
    call    c,norel label1 + label1     ; should relocate because only first "label1" is norel
    call    z,norel(label1 + label1)    ; should not relocate

    ld      a,high norel label1         ; no warning about unstable expression
    ld      a,norel high label1         ; error about missing label "high" (norel must be followed by label expression)
    ld      a,norel  (high label1)      ; (or parentheses will make high operator legal)

    jp      $                           ; should relocate
    jp      norel $                     ; should not relocate

    RELOCATE_END

    RELOCATE_TABLE

    ASSERT 2*relocate_count == relocate_size
    ASSERT 4 == relocate_count
    ASSERT 2 == __ERRORS__
    ASSERT 0 == __WARNINGS__
