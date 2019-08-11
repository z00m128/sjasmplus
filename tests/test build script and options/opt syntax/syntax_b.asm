; Thorough tests for memory accessing instructions with --syntax=b
    ; default bracket syntax (relaxed one)
    OPT reset --zxnext --syntax=a
    ; 3x OK: val, mem, mem
    ld  a,0 : ld  a,(1) : ld  a,[2]
    ; 2x OK: val, val, ---
    ld  b,3 : ld  b,(4) : ld  b,[5]
    ; 2x OK: val, val, ---
    bit 3,a : bit (3),a : bit [3],a
    ; 2x OK: val, val, ---
    add a,6 : add a,(7) : add a,[8]
    adc a,6 : adc a,(7) : adc a,[8]
    sub a,6 : sub a,(7) : sub a,[8]     ; this syntax works because --syntax=A was used
    sbc a,6 : sbc a,(7) : sbc a,[8]
    and a,6 : and a,(7) : and a,[8]
    xor a,6 : xor a,(7) : xor a,[8]
    or  a,6 : or  a,(7) : or  a,[8]
    cp  a,6 : cp  a,(7) : cp  a,[8]
    ; 2x OK: val, val, ---
    im  1   : im  (1)   : im  [1]
    ; 2x OK: val, val, ---
    ld (hl),9  : ld (hl),(10) : ld (hl),[11]
    ; 2x OK: val, val, ---
    ld (ix),12 : ld (ix),(13) : ld (ix),[14]
    ; 2x OK: val, val, ---
    ld  ixl,15 : ld  ixl,(16) : ld  ixl,[17]
    ; 2x OK: val, val, ---
    ldd (hl),18 : ldd (hl),(19) : ldd (hl),[20]  ; Fake instructions
    ; 2x OK: val, val, ---
    ldd (ix),21 : ldd (ix),(22) : ldd (ix),[23]  ; Fake instructions
    ; 2x OK: val, val, ---
    ldi (hl),24 : ldi (hl),(25) : ldi (hl),[26]  ; Fake instructions
    ; 2x OK: val, val, ---
    ldi (ix),27 : ldi (ix),(28) : ldi (ix),[29]  ; Fake instructions
    ; 2x OK: val, val, ---
    nextreg 30,31 : nextreg (32),(33) : nextreg [34],[35]
    ; 2x OK: val, val, ---
    out (c),0 : out (c),(0) : out (c),[0]
    ; 2x OK: val, val, ---
    res 7,a : res (7),a : res [7],a
    ; 2x OK: val, val, ---
    rst 16 : rst (16) : rst [16]
    ; 2x OK: val, val, ---
    set 6,a : set (6),a : set [6],a
    ; 2x OK: val, val, ---
    test 36 : test (37) : test [38]

    ;; 16 bit immediates (none of them on regular Z80, always ambiguous val+mem combination)
    ; 2x OK: val, val, ---
    add hl,100 : add hl,(101) : add hl,[102]
    add bc,103 : add bc,(104) : add bc,[105]
    add de,106 : add de,(107) : add de,[108]
    push 109 : push (110) : push [111]
    
    OPT --syntax=b
    ; 3x OK: val, mem, mem
    ld  a,0 : ld  a,(1) : ld  a,[2]
    ; 1x OK: val, ---, ---
    ld  b,3 : ld  b,(4) : ld  b,[5]
    ; 1x OK: val, ---, ---
    bit 3,a : bit (3),a : bit [3],a
    ; 1x OK: val, ---, ---
    add a,6 : add a,(7) : add a,[8]
    adc a,6 : adc a,(7) : adc a,[8]
    sub a,6 : sub a,(7) : sub a,[8]     ; this syntax works because --syntax=A was used
    sbc a,6 : sbc a,(7) : sbc a,[8]
    and a,6 : and a,(7) : and a,[8]
    xor a,6 : xor a,(7) : xor a,[8]
    or  a,6 : or  a,(7) : or  a,[8]
    cp  a,6 : cp  a,(7) : cp  a,[8]
    ; 1x OK: val, ---, ---
    im  1   : im  (1)   : im  [1]
    ; 1x OK: val, ---, ---
    ld (hl),9  : ld (hl),(10) : ld (hl),[11]
    ; 1x OK: val, ---, ---
    ld (ix),12 : ld (ix),(13) : ld (ix),[14]
    ; 1x OK: val, ---, ---
    ld  ixl,15 : ld  ixl,(16) : ld  ixl,[17]
    ; 1x OK: val, ---, ---
    ldd (hl),18 : ldd (hl),(19) : ldd (hl),[20]  ; Fake instructions
    ; 1x OK: val, ---, ---
    ldd (ix),21 : ldd (ix),(22) : ldd (ix),[23]  ; Fake instructions
    ; 1x OK: val, ---, ---
    ldi (hl),24 : ldi (hl),(25) : ldi (hl),[26]  ; Fake instructions
    ; 1x OK: val, ---, ---
    ldi (ix),27 : ldi (ix),(28) : ldi (ix),[29]  ; Fake instructions
    ; 1x OK: val, ---, ---
    nextreg 30,31 : nextreg (32),(33) : nextreg [34],[35]
    ; 1x OK: val, ---, ---
    out (c),0 : out (c),(0) : out (c),[0]
    ; 1x OK: val, ---, ---
    res 7,a : res (7),a : res [7],a
    ; 1x OK: val, ---, ---
    rst 16 : rst (16) : rst [16]
    ; 1x OK: val, ---, ---
    set 6,a : set (6),a : set [6],a
    ; 1x OK: val, ---, ---
    test 36 : test (37) : test [38]

    ; 1x OK: val, ---, ---
    add hl,100 : add hl,(101) : add hl,[102]
    add bc,103 : add bc,(104) : add bc,[105]
    add de,106 : add de,(107) : add de,[108]
    push 109 : push (110) : push [111]

someLabel:
    ld  b,(someLabel)       ; just make super sure it does catch the original real world annoyance

    ;; Docs example from command line options section
        OPT reset --syntax=abfw
label:  dw 15
        ld b,(label)
        sub a,b
