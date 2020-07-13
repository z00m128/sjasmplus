    ORG $1000
    RELOCATE_START

    ASSERT 2 * relocate_count == relocate_size
    ASSERT 3 == relocate_count
    RELOCATE_TABLE              ; should emit the three addresses of opcode data:
        ; $100B, $100E, $1012

    dw      relocate_count
    dw      relocate_size
relocatable_label:              ; usage of this label should trigger relocation
    ld      hl,relocatable_label    ; opcode should be in relocation table
    ld      hl,(relocatable_label)  ; opcode should be in relocation table
    ret
    jp      relocatable_label   ; opcode should be in relocation table
equ_label   equ     $1001
    ld      hl,equ_label        ; should be absolute (equ) value (not in relocate data)
    ld      hl,(equ_label)      ; should be absolute (equ) address (not in relocate data)
    jp      equ_label           ; jump to absolute address (not in relocate data)

    RELOCATE_END
