    OPT --zxnext
    ORG $1000

    RELOCATE_START

    ASSERT 2 * relocate_count == relocate_size
    ASSERT 3 == relocate_count
    dw      relocate_count
    dw      relocate_size

add_r16_imm16:
    add     hl,add_r16_imm16
    add     de,add_r16_imm16
    add     bc,add_r16_imm16

push_imm16:
    push    push_imm16          ; not suitable for relocation because big-endian encoding
    ; try multi arg variation, it will report two errors for two expressions
    push    0x1234, push_imm16, 0x2345, push_imm16

imm8_warnings:                  ; warning all
    nextreg high imm8_warnings,a
    nextreg high imm8_warnings,$34
    nextreg $12,high imm8_warnings
    test    high imm8_warnings

    RELOCATE_END

    RELOCATE_TABLE

;===================================================================================
; here comes the copy of all the instructions, but outside of relocation block
; but using the labels which are affected by relocation (this should still *NOT*
; add to the relocation table, as instructions are outside of relocation block)
; and thus this should also *NOT* warn about unstable relocation.
;===================================================================================

;add_r16_imm16:
    add     hl,add_r16_imm16
    add     de,add_r16_imm16
    add     bc,add_r16_imm16

;push_imm16:
    push    push_imm16          ; not suitable for relocation because big-endian encoding
    ; multi arg variation
    push    0x1234, push_imm16, 0x2345, push_imm16

;imm8_warnings:
    nextreg high imm8_warnings,a
    nextreg high imm8_warnings,$34
    nextreg $12,high imm8_warnings
    test    high imm8_warnings

    RELOCATE_TABLE

    ASSERT 3 == __ERRORS__
    ASSERT 4 == __WARNINGS__
