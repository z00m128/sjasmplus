; empty SYNTAX options should keep defaults
    ld      bc,hl       ; fake enabled, no warning
    sub     a,b         ; sub a : sub b
    ld      b,h, c,l    ; ld b,h : ld c,l (same as first fake)
hl:                     ; no warning/error for using register name as label
    ld      a,(hl)      ; memory reference
    ld      a,[hl]      ; memory reference
