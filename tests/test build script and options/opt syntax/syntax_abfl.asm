; SYNTAX option "abfl@":
;  @ is error "unrecognized" (but outside of list file!)
;  l is "unimplemented yet" (comments below are for future implementation)
    ld      bc,hl       ; warning
    ld      bc,hl       ; warning removed by using "fake" in this comment
    sub     a,b         ; sub b
    sub     a,,b        ; sub a : sub b
    ld      b,h,,c,l    ; ld b,h : ld c,l (same as first fake)
    ld      b,h, c,l    ; error
hl:                     ; warning
    ld      a,(hl)      ; OK: memory reference
    ld      a,[hl]      ; OK: memory reference
    add     a,(5)       ; error (memory reference = illegal instruction)
    add     a,[6]       ; error (memory reference = illegal instruction)
    add     a,7         ; OK
    ld      b,(8)       ; error (memory reference = illegal instruction)
    ld      b,[9]       ; error (memory reference = illegal instruction)
    ld      b,10        ; OK

    ld      bc,hl       ;ok (warning suppressed by "ok")
