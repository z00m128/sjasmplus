; SYNTAX option "abfl@":
;  @ is error "unrecognized" (but outside of list file!)
;  b and l are "unimplemented yet" (comments below are for future implementation)
    ld      bc,hl       ; warning
    ld      bc,hl       ; warning removed by using "fake" in this comment
    sub     a,b         ; sub b
    sub     a,,b        ; sub a : sub b
    ld      b,h,,c,l    ; ld b,h : ld c,l (same as first fake)
    ld      b,h, c,l    ; error
hl:                     ; warning
    ld      a,(hl)      ; memory reference
    ld      a,[hl]      ; error
