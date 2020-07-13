    ORG $1000

    RELOCATE_START

    dw      relocate_count
    dw      relocate_size

label1:
    call    label1

    DISP    $2000       ; error about DISP inside relocation block
    jp      label1

    RELOCATE_END

    DISP    $3000
    nop
label2:
    call    label2
    RELOCATE_START      ; error about relocation block under DISP
    call    label2
    RELOCATE_END        ; error about END without START
    ENT

    RELOCATE_START
    call    label2
label3:
    call    label3
    RELOCATE_END

    RELOCATE_TABLE
