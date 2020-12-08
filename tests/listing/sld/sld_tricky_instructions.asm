    DEVICE ZXSPECTRUMNEXT
    ORG $8000
; multi-argument instructions
    push af,hl,de   ; 3x push instruction
    ld  a,1,b,2,hl,$1234,de,$5678    ; 4x ld instruction

; all fake instructions
nn EQU $56
mm EQU $78
    rl bc           ; rl c : rl b
    rl de           ; rl e : rl d
    rl hl           ; rl l : rl h
    rr bc           ; rr b : rr c
    rr de           ; rr d : rr e
    rr hl           ; rr h : rr l
    sla bc          ; sla c : rl b
    sla de          ; sla e : rl d
    sla hl          ; add hl,hl
    sll bc          ; sli c : rl b
    sll de          ; sli e : rl d
    sll hl          ; sli l : rl h
    sli bc          ; sli c : rl b
    sli de          ; sli e : rl d
    sli hl          ; sli l : rl h
    sra bc          ; sra b : rr c
    sra de          ; sra d : rr e
    sra hl          ; sra h : rr l
    srl bc          ; srl b : rr c
    srl de          ; srl d : rr e
    srl hl          ; srl h : rr l

    ld bc,bc        ; ld b,b : ld c,c
    ld bc,de        ; ld b,d : ld c,e
    ld bc,hl        ; ld b,h : ld c,l
    ld bc,ix        ; ld b,xh : ld c,xl
    ld bc,iy        ; ld b,yh : ld c,yl
    ld bc,(hl)      ; ld c,(hl) : inc hl : ld b,(hl) : dec hl
    ld bc,(ix+nn)   ; ld c,(ix+nn) : ld b,(ix+nn+1)
    ld bc,(iy+nn)   ; ld c,(iy+nn) : ld b,(iy+nn+1)

    ld de,bc        ; ld d,b : ld e,c
    ld de,de        ; ld d,d : ld e,e
    ld de,hl        ; ld d,h : ld e,l
    ld de,ix        ; ld d,xh : ld e,xl
    ld de,iy        ; ld d,yh : ld e,yl
    ld de,(hl)      ; ld e,(hl) : inc hl : ld d,(hl) : dec hl
    ld de,(ix+nn)   ; ld e,(ix+nn) : ld d,(ix+nn+1)
    ld de,(iy+nn)   ; ld e,(iy+nn) : ld d,(iy+nn+1)

    ld hl,bc        ; ld h,b : ld l,c
    ld hl,de        ; ld h,d : ld l,e
    ld hl,hl        ; ld h,h : ld l,l
    ld hl,ix        ; push ix : pop hl
    ld hl,iy        ; push iy : pop hl
    ld hl,(ix+nn)   ; ld l,(ix+nn) : ld h,(ix+nn+1)
    ld hl,(iy+nn)   ; ld l,(iy+nn) : ld h,(iy+nn+1)

    ld ix,bc        ; ld xh,b : ld xl,c
    ld ix,de        ; ld xh,d : ld xl,e
    ld ix,hl        ; push hl : pop ix
    ld ix,ix        ; ld xh,xh : ld xl,xl
    ld ix,iy        ; push iy : pop ix

    ld iy,bc        ; ld yh,b : ld yl,c
    ld iy,de        ; ld yh,d : ld yl,e
    ld iy,hl        ; push hl : pop iy
    ld iy,ix        ; push ix : pop iy
    ld iy,iy        ; ld yh,yh : ld yl,yl

    ld (hl),bc      ; ld (hl),c : inc hl : ld (hl),b : dec hl
    ld (hl),de      ; ld (hl),e : inc hl : ld (hl),d : dec hl

    ld (ix+nn),bc   ; ld (ix+nn),c : ld (ix+nn+1),b
    ld (ix+nn),de   ; ld (ix+nn),e : ld (ix+nn+1),d
    ld (ix+nn),hl   ; ld (ix+nn),l : ld (ix+nn+1),h

    ld (iy+nn),bc   ; ld (iy+nn),c : ld (iy+nn+1),b
    ld (iy+nn),de   ; ld (iy+nn),e : ld (iy+nn+1),d
    ld (iy+nn),hl   ; ld (iy+nn),l : ld (iy+nn+1),h

    ldi bc,(hl)     ; ld c,(hl) : inc hl : ld b,(hl) : inc hl
    ldi bc,(ix+nn)  ; ld c,(ix+nn) : inc ix : ld b,(ix+nn) : inc ix
    ldi bc,(iy+nn)  ; ld c,(iy+nn) : inc iy : ld b,(iy+nn) : inc iy

    ldi de,(hl)     ; ld e,(hl) : inc hl : ld d,(hl) : inc hl
    ldi de,(ix+nn)  ; ld e,(ix+nn) : inc ix : ld d,(ix+nn) : inc ix
    ldi de,(iy+nn)  ; ld e,(iy+nn) : inc iy : ld d,(iy+nn) : inc iy

    ldi hl,(ix+nn)  ; ld l,(ix+nn) : inc ix : ld h,(ix+nn) : inc ix
    ldi hl,(iy+nn)  ; ld l,(iy+nn) : inc iy : ld h,(iy+nn) : inc iy

    ldi (hl),bc     ; ld (hl),c : inc hl : ld (hl),b : inc hl
    ldi (hl),de     ; ld (hl),e : inc hl : ld (hl),d : inc hl

    ldi (ix+nn),bc  ; ld (ix+nn),c : inc ix : ld (ix+nn),b : inc ix
    ldi (ix+nn),de  ; ld (ix+nn),e : inc ix : ld (ix+nn),d : inc ix
    ldi (ix+nn),hl  ; ld (ix+nn),l : inc ix : ld (ix+nn),h : inc ix

    ldi (iy+nn),bc  ; ld (iy+nn),c : inc iy : ld (iy+nn),b : inc iy
    ldi (iy+nn),de  ; ld (iy+nn),e : inc iy : ld (iy+nn),d : inc iy
    ldi (iy+nn),hl  ; ld (iy+nn),l : inc iy : ld (iy+nn),h : inc iy

    ldi a,(bc)      ; ld a,(bc) : inc bc
    ldi a,(de)      ; ld a,(de) : inc de
    ldi a,(hl)      ; ld a,(hl) : inc hl
    ldi b,(hl)      ; ld b,(hl) : inc hl
    ldi c,(hl)      ; ld c,(hl) : inc hl
    ldi d,(hl)      ; ld d,(hl) : inc hl
    ldi e,(hl)      ; ld e,(hl) : inc hl
    ldi h,(hl)      ; ld h,(hl) : inc hl
    ldi l,(hl)      ; ld l,(hl) : inc hl
    ldi a,(ix+nn)   ; ld a,(ix+nn) : inc ix
    ldi b,(ix+nn)   ; ld b,(ix+nn) : inc ix
    ldi c,(ix+nn)   ; ld c,(ix+nn) : inc ix
    ldi d,(ix+nn)   ; ld d,(ix+nn) : inc ix
    ldi e,(ix+nn)   ; ld e,(ix+nn) : inc ix
    ldi h,(ix+nn)   ; ld h,(ix+nn) : inc ix
    ldi l,(ix+nn)   ; ld l,(ix+nn) : inc ix
    ldi a,(iy+nn)   ; ld a,(iy+nn) : inc iy
    ldi b,(iy+nn)   ; ld b,(iy+nn) : inc iy
    ldi c,(iy+nn)   ; ld c,(iy+nn) : inc iy
    ldi d,(iy+nn)   ; ld d,(iy+nn) : inc iy
    ldi e,(iy+nn)   ; ld e,(iy+nn) : inc iy
    ldi h,(iy+nn)   ; ld h,(iy+nn) : inc iy
    ldi l,(iy+nn)   ; ld l,(iy+nn) : inc iy

    ldd a,(bc)      ; ld a,(bc) : dec bc
    ldd a,(de)      ; ld a,(de) : dec de
    ldd a,(hl)      ; ld a,(hl) : dec hl
    ldd b,(hl)      ; ld b,(hl) : dec hl
    ldd c,(hl)      ; ld c,(hl) : dec hl
    ldd d,(hl)      ; ld d,(hl) : dec hl
    ldd e,(hl)      ; ld e,(hl) : dec hl
    ldd h,(hl)      ; ld h,(hl) : dec hl
    ldd l,(hl)      ; ld l,(hl) : dec hl
    ldd a,(ix+nn)   ; ld a,(ix+nn) : dec ix
    ldd b,(ix+nn)   ; ld b,(ix+nn) : dec ix
    ldd c,(ix+nn)   ; ld c,(ix+nn) : dec ix
    ldd d,(ix+nn)   ; ld d,(ix+nn) : dec ix
    ldd e,(ix+nn)   ; ld e,(ix+nn) : dec ix
    ldd h,(ix+nn)   ; ld h,(ix+nn) : dec ix
    ldd l,(ix+nn)   ; ld l,(ix+nn) : dec ix
    ldd a,(iy+nn)   ; ld a,(iy+nn) : dec iy
    ldd b,(iy+nn)   ; ld b,(iy+nn) : dec iy
    ldd c,(iy+nn)   ; ld c,(iy+nn) : dec iy
    ldd d,(iy+nn)   ; ld d,(iy+nn) : dec iy
    ldd e,(iy+nn)   ; ld e,(iy+nn) : dec iy
    ldd h,(iy+nn)   ; ld h,(iy+nn) : dec iy
    ldd l,(iy+nn)   ; ld l,(iy+nn) : dec iy

    ldi (bc),a      ; ld (bc),a : inc bc
    ldi (de),a      ; ld (de),a : inc de
    ldi (hl),a      ; ld (hl),a : inc hl
    ldi (hl),b      ; ld (hl),b : inc hl
    ldi (hl),c      ; ld (hl),c : inc hl
    ldi (hl),d      ; ld (hl),d : inc hl
    ldi (hl),e      ; ld (hl),e : inc hl
    ldi (hl),h      ; ld (hl),h : inc hl
    ldi (hl),l      ; ld (hl),l : inc hl
    ldi (ix+nn),a   ; ld (ix+nn),a : inc ix
    ldi (ix+nn),b   ; ld (ix+nn),b : inc ix
    ldi (ix+nn),c   ; ld (ix+nn),c : inc ix
    ldi (ix+nn),d   ; ld (ix+nn),d : inc ix
    ldi (ix+nn),e   ; ld (ix+nn),e : inc ix
    ldi (ix+nn),h   ; ld (ix+nn),h : inc ix
    ldi (ix+nn),l   ; ld (ix+nn),l : inc ix
    ldi (iy+nn),a   ; ld (iy+nn),a : inc iy
    ldi (iy+nn),b   ; ld (iy+nn),b : inc iy
    ldi (iy+nn),c   ; ld (iy+nn),c : inc iy
    ldi (iy+nn),d   ; ld (iy+nn),d : inc iy
    ldi (iy+nn),e   ; ld (iy+nn),e : inc iy
    ldi (iy+nn),h   ; ld (iy+nn),h : inc iy
    ldi (iy+nn),l   ; ld (iy+nn),l : inc iy

    ldd (bc),a      ; ld (bc),a : dec bc
    ldd (de),a      ; ld (de),a : dec de
    ldd (hl),a      ; ld (hl),a : dec hl
    ldd (hl),b      ; ld (hl),b : dec hl
    ldd (hl),c      ; ld (hl),c : dec hl
    ldd (hl),d      ; ld (hl),d : dec hl
    ldd (hl),e      ; ld (hl),e : dec hl
    ldd (hl),h      ; ld (hl),h : dec hl
    ldd (hl),l      ; ld (hl),l : dec hl
    ldd (ix+nn),a   ; ld (ix+nn),a : dec ix
    ldd (ix+nn),b   ; ld (ix+nn),b : dec ix
    ldd (ix+nn),c   ; ld (ix+nn),c : dec ix
    ldd (ix+nn),d   ; ld (ix+nn),d : dec ix
    ldd (ix+nn),e   ; ld (ix+nn),e : dec ix
    ldd (ix+nn),h   ; ld (ix+nn),h : dec ix
    ldd (ix+nn),l   ; ld (ix+nn),l : dec ix
    ldd (iy+nn),a   ; ld (iy+nn),a : dec iy
    ldd (iy+nn),b   ; ld (iy+nn),b : dec iy
    ldd (iy+nn),c   ; ld (iy+nn),c : dec iy
    ldd (iy+nn),d   ; ld (iy+nn),d : dec iy
    ldd (iy+nn),e   ; ld (iy+nn),e : dec iy
    ldd (iy+nn),h   ; ld (iy+nn),h : dec iy
    ldd (iy+nn),l   ; ld (iy+nn),l : dec iy

    ldi (hl),mm     ; ld (hl),mm : inc hl
    ldi (ix+nn),mm  ; ld (ix+nn),mm : inc ix
    ldi (iy+nn),mm  ; ld (iy+nn),mm : inc iy

    ldd (hl),mm     ; ld (hl),mm : dec hl
    ldd (ix+nn),mm  ; ld (ix+nn),mm : dec ix
    ldd (iy+nn),mm  ; ld (iy+nn),mm : dec iy

    sub hl,bc       ; or a : sbc hl,bc
    sub hl,de       ; or a : sbc hl,de
    sub hl,hl       ; or a : sbc hl,hl
    sub hl,sp       ; or a : sbc hl,sp

; multi-argument fake instructions (final level)

    ; ld (hl),l : dec hl : ld (ix+nn),a : dec ix : ld (hl),mm : dec hl : ld (ix+nn),mm : dec ix
    ldd (hl),l,(ix+nn),a,(hl),mm,(ix+nn),mm

    ; ld (hl),l : inc hl : ld (ix+nn),a : inc ix : ld (hl),mm : inc hl : ld (ix+nn),mm : inc ix
    ldi (hl),l,(ix+nn),a,(hl),mm,(ix+nn),mm

    ; sla c : rl b : sla e : rl d : add hl,hl
    sla bc,de,hl

    ; hopefully that's enough to test...
