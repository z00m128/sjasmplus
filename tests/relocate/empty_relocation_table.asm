    call    label_out_relocate  ; outside of relocation area

    ORG $1000
    RELOCATE_START
    dw      relocate_count      ; should be zero
    dw      relocate_size       ; should be zero
    nop
    call    label_out_relocate  ; should be absolute call (not in relocate data)
equ_label   equ     $1001
    ld      hl,equ_label        ; should be absolute (equ) value (not in relocate data)
unused_label:                   ; should not produce any relocation data, just defines "relocatable" label
    RELOCATE_TABLE              ; should emit no relocation data
    RELOCATE_END
    ; outside of relocation area
label_out_relocate:
    ret
