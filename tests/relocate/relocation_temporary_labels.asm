    ORG $1000

; first section is not part of relocation table
1:

    jr      1B                  ; opcode should be in relocation table
    jr      nz,1B
    jr      z,1B
    jr      nc,1B
    jr      c,1B

    jp      nz,1B
    jp      1B                  ; opcode should be in relocation table
    jp      z,1B
    jp      nc,1B
    jp      c,1B
    jp      po,1B
    jp      pe,1B
    jp      p,1B
    jp      m,1B

    call    nz,1B
    call    z,1B
    call    1B
    call    nc,1B
    call    c,1B
    call    po,1B
    call    pe,1B
    call    p,1B
    call    m,1B

    jr      1F                  ; opcode should be in relocation table
    jr      nz,1F
    jr      z,1F
    jr      nc,1F
    jr      c,1F

    jp      nz,1F
    jp      1F                  ; opcode should be in relocation table
    jp      z,1F
    jp      nc,1F
    jp      c,1F
    jp      po,1F
    jp      pe,1F
    jp      p,1F
    jp      m,1F

    call    nz,1F
    call    z,1F
    call    1F
    call    nc,1F
    call    c,1F
    call    po,1F
    call    pe,1F
    call    p,1F
    call    m,1F

1:

; second section does test relocation
    RELOCATE_START

    ASSERT 2 * relocate_count == relocate_size
    ASSERT 36 == relocate_count
    dw      relocate_count
    dw      relocate_size

1:                              ; usage of this label should trigger relocation
    ; relative jumps don't need relocation
    jr      1B
    jr      nz,1B
    jr      z,1B
    jr      nc,1B
    jr      c,1B
    ; absolute jumps need relocation
    jp      nz,1B
    jp      1B
    jp      z,1B
    jp      nc,1B
    jp      c,1B
    jp      po,1B
    jp      pe,1B
    jp      p,1B
    jp      m,1B
    ; calls need relocation
    call    nz,1B
    call    z,1B
    call    1B
    call    nc,1B
    call    c,1B
    call    po,1B
    call    pe,1B
    call    p,1B
    call    m,1B
    ; again the same set, but this time using forward temporary label
    jr      1F
    jr      nz,1F
    jr      z,1F
    jr      nc,1F
    jr      c,1F

    jp      nz,1F
    jp      1F
    jp      z,1F
    jp      nc,1F
    jp      c,1F
    jp      po,1F
    jp      pe,1F
    jp      p,1F
    jp      m,1F

    call    nz,1F
    call    z,1F
    call    1F
    call    nc,1F
    call    c,1F
    call    po,1F
    call    pe,1F
    call    p,1F
    call    m,1F
1:                              ; usage of this label should trigger relocation

    ; the relocation table must be after all temporary labels, as those don't manage
    ; to settle down within 3 passes if there's dynamic-size table ahead, and "forward"
    ; labels are referenced
    RELOCATE_TABLE              ; should emit the 36 addresses of opcode data

    RELOCATE_END
