; make some instructions to accept single-comma multi-arg even when --syntax=a mode is specified
; instructions supporting relaxed multi-arg: dec, inc, pop, push

; errors of double-comma used without --syntax=a mode

    dec bc,,de
    inc bc,,de
    push hl,,de
    pop hl,,de
    OPT --reversepop
    pop hl,,de

; enabled --syntax=a mode, and check mixed commas for relaxed instructions

    OPT reset --syntax=a
    dec bc,de,,hl,sp,,ix,iy,,b,c,d,e,,h,l,(hl),a
    inc bc,de,,hl,sp,,ix,iy,,b,c,d,e,,h,l,(hl),a
    push bc,de,,hl,af,,ix,iy
    pop bc,de,,hl,af,,ix,iy
    OPT --reversepop
    pop bc,de,,hl,af,,ix,iy
