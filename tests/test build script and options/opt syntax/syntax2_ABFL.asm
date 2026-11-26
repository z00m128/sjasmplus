; SYNTAX option "aBFL":     (used to be "ABFL", but "A" was removed)
;  L is "unimplemented yet" (comments below are for future implementation)
    ld      bc,hl       ; error
    ld      bc,hl       ; still error even with "fake" in this comment
    sub     a,b         ; sub b
    sub     a,,b        ; sub a : sub b
    sub     a``b        ; error
    ld      b,h,,c,l    ; ld b,h : ld c,l
    ld      b,h``c,l    ; error
    ld      b,h, c,l    ; error
hl:                     ; error
    ld      a,(hl)      ; expression error  ; with "L" unimplemented this actually works as LD a,8
    ld      a,[hl]      ; memory reference

    ; B mode requires square brackets for I/O addresses too
    in      a,[c] ,, b,[C] ,, a,[254] ,, f,[c] ,, [C]
    out     [c],b ,, [C],0 ,, [254],a
    out     [c],(0)      ; value expression, not an address
    out     [c],[0]      ; error: value operand can't access memory

    ; round parentheses and bare port addresses are errors
    in      a,(c)
    in      a,(254)
    out     (c),0
    out     (c),b
    out     (254),a

    in      a,254       ; or without parentheses at all (new syntax variant)
    out     254,a
    in      a,[c)       ; mismatched brackets
    out     [254),a

    jp      (c)         ; next only - here label not found
    jp      [c]         ; next only
    OPT --zxnext
    jp      [c]
    jp      (c)         ; square brackets required to be Z80N `jp (c)`, this is `jp nnnn` then
