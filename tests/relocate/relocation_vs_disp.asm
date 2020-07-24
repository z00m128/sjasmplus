    ORG $1000

    RELOCATE_START

    dw      relocate_count
    dw      relocate_size

label1:
    call    label1

    DISP    $2000
    jp      label1      ; should relocate but at the $100x address ($1008)

    RELOCATE_END        ; error (inner-DISP is still open)

    DISP    $3000       ; DISP inside DISP, will get ignored
    ENT                 ; end the inner-DISP
    RELOCATE_END        ; end first relocation block

    DISP    $3000       ; outer-DISP
    nop
label2:
    call    label2
    RELOCATE_START
    call    label3      ; should relocate at $300x address ($3005)
    ENT                 ; error - trying to end outer-DISP inside relocation
    RELOCATE_END        ; end relocation block
    ENT                 ; end outer-block

    RELOCATE_START
    call    label2
label3:
    call    label3      ; classic relocation
    RELOCATE_END

    RELOCATE_TABLE

    ASSERT 2*relocate_count == relocate_size
    ASSERT 4 == relocate_count
    ASSERT 2 == __ERRORS__
    ASSERT 1 == __WARNINGS__
