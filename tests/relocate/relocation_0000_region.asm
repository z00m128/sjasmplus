    ; the implementation is providing alternate label values being offset by -0x0201
    ; to their real value. This test does try relocation blocks near beginnging and end
    ; of memory regions to verify that there is no connection between the -0x201 offset
    ; and assembling results (there should not be).

    ORG     0
    RELOCATE_START
label1:     DW      label2
label2:     ld      hl,label1
            ld      de,(label1)
            ld      bc,label2 - label1
            call    label1
            rst     $08

    RELOCATE_TABLE      ; first copy of relocate table

    ; try ORG within the same block, try end region of memory
    ORG     $FFF8
label3:     jp      label2
            dw      label3 - label1
            dw      label3
        ; check crossing memory limit by instruction in relocation block
        ; this emits "incosistent warning" because the table was already emitted
        ; but with truncated 0x0000 value, while the new value to be inserted
        ; is 0x10000
            call    label3
    RELOCATE_END

    ; second copy of relocation table, make it fill memory up to 64kiB boundary
    ORG     $10000 - relocate_size
    RELOCATE_TABLE

    ; third copy of relocation table, make it leak 1B beyond 0x10000
    ORG     $10000 - relocate_size + 1
    RELOCATE_TABLE
