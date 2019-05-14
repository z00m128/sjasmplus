; SYNTAX option "ABFL":
;  B and L are "unimplemented yet" (comments below are for future implementation)
    ld      bc,hl       ; error
    ld      bc,hl       ; still error even with "fake" in this comment
    sub     a,b         ; sub b
    sub     a``b        ; sub a : sub b
    sub     a,,b        ; error
    ld      b,h``c,l    ; ld b,h : ld c,l
    ld      b,h,,c,l    ; error
    ld      b,h, c,l    ; error
hl:                     ; error
    ld      a,(hl)      ; expression error
    ld      a,[hl]      ; memory reference
