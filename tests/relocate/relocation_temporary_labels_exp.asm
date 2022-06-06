; since v1.19.0 it is possible to use temporary labels also in expressions,
; but it was not test-covered for relocation use cases, adding the test (and fix) now

; first section is not part of relocation table
    ORG $1000
2:

    ld      hl,2_B
    ld      hl,2_F
    ld      hl,3_F              ; not in relocation table, even with relocatable label

2:

; second section does test relocation

    RELOCATE_START

    ASSERT 2 * relocate_count == relocate_size
    ASSERT 8 == relocate_count
    dw      relocate_count
    dw      relocate_size

3:                              ; usage of this label should trigger relocation

    ORG $2000
    ; no relocation cases
    ld      hl,2_B
    ld      hl,2_F
    ld      hl,norel 3_B
    ld      hl,norel 3_F
    ld      hl,norel 3_B + 0x1234
    ld      hl,norel 3_F + 0x1234
    ld      hl,0x1234 + norel 3_B
    ld      hl,0x1234 + norel 3_F
    ld      hl,3_F - 3_B
    jp      norel 3_B
    jp      norel 3_F

    ORG $3000
    ; relocation cases
    ld      hl,3_B
    ld      hl,3_F
    ld      hl,3_B + 0x1234
    ld      hl,3_F + 0x1234
    ld      hl,0x1234 + 3_B
    ld      hl,0x1234 + 3_F
    jp      3_B
    jp      3_F

    ORG $4000
    ; unstable expressions
    ld      hl,low 3_B
    ld      hl,low 3_F
    ld      hl,high 3_B
    ld      hl,high 3_F
    ld      hl,3*3_F - 3_B

3:                              ; usage of this label should trigger relocation

    ; the relocation table must be after all temporary labels, as those don't manage
    ; to settle down within 3 passes if there's dynamic-size table ahead, and "forward"
    ; labels are referenced
    RELOCATE_TABLE              ; should emit the 16 addresses of opcode data

    RELOCATE_END

2:
