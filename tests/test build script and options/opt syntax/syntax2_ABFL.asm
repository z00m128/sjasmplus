; SYNTAX option "ABFL":
;  L is "unimplemented yet" (comments below are for future implementation)
    ld      bc,hl       ; error
    ld      bc,hl       ; still error even with "fake" in this comment
    sub     a,b         ; sub b
    sub     a``b        ; sub a : sub b
    sub     a,,b        ; error
    ld      b,h``c,l    ; ld b,h : ld c,l
    ld      b,h,,c,l    ; error
    ld      b,h, c,l    ; error
hl:                     ; error
    ld      a,(hl)      ; expression error  ; with "L" unimplemented this actually works as LD a,8
    ld      a,[hl]      ; memory reference

    ; some specifics of B mode - I/O instructions still work only with round parentheses
    jp      (c)
    jp      [c]
    jp      (C)
    jp      [C]
    OPT --zxnext
    jp      (c)
    jp      [c]
    jp      (C)
    jp      [C]

    in      a,(c)
    in      a,(254)
    out     (c),0
    out     (c),b
    out     (254),a

    in      a,254       ; or without parentheses at all (new syntax variant)
    out     254,a

    ; but square brackets will not work (errors)
    in      a,[c]
    in      a,[254]
    out     [c],b
    out     [254],a
