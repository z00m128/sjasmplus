    ;; few more test cases not covered by regular tests,
    ;; but were discovered by code coverage as code not executed in tests

    ; some tests need more strict syntax rules to hit specific code paths
    OPT reset --syntax=ab

    xor     [1234   ; "Operand expected" error when parsing of no-memory argument fails

    call            ; "Operand expected" error

    ld      a,high af           ; tricky way to write "ld a,a" :) ("high af" covered)

    in      low af,(c)          ; tricky way to write "in f,(c)" ("low af" covered)

    ; nonexistent register pairs (with possible match) in `GetRegister` function
    pop az : pop ha : pop xa : pop ya : pop YA

    ; invalid registers in common ALU instructions
    xor af : xor sp : xor i : xor r : xor f

    adc     hl      ; "Comma expected" error
    adc     hl,ix   ; invalid instr.
    adc     b ,, c  ; multiarg

    add     hl              ; "Comma expected" error
    ex      hl              ; "Comma expected" error
    ex      (sp)            ; "Comma expected" error

    and     b ,, c          ; multiarg
    bit     5,c ,, 3,(ix+4) ; multiarg
    cp      b ,, c          ; multiarg
    inc     b ,, c          ; multiarg
    in      a,(1) ,, d,(c)  ; multiarg
    djnz    $ ,, $          ; multiarg
    jr      $ ,, $          ; multiarg
    ldd     a,(hl) ,, b,(hl); multiarg
    ldi     a,(hl) ,, b,(hl); multiarg
    ldd     ,,              ; freaking multiarg syntax allows for this!
    ldi     ,,              ; freaking multiarg syntax allows for this!

    djnz                    ; "Operand expected" error
    djnz    $+2-128-1       ; just outside of range
    djnz    $+2+127+1       ; just outside of range

    dec     r               ; illegal dec/inc instruction
    inc     r
    dec     af
    inc     af

    jr      p,$             ; illegal JR conditions
    jr      ns,$
    jr      m,$
    jr      s,$
    jr      po,$
    jr      pe,$

    ; illegal instructions (exercising all code paths)
    ld      (1234),af
    ld      (1234),r
    ld      (af),a
    ldd     a,(af)
    ldi     a,(af)
    ldd     b,c
    ldi     b,c
    ldd     (hl),i
    ldi     (hl),i
    ldd     (ix),i
    ldi     (iy),i
    ldi     b,(af)
    ldi     bc,a
    ldi     de,a
    ldi     hl,a

    ; normal instructions, different syntax (not used yet by any test)
    exa     : ex af,af'     ; "ex af,af'" shortcut
    exd     : ex de,hl      ; "ex de,hl" shortcut
    inf     : in f,(c)      ; "in f,(c)" shortcut

    OPT reset --syntax=abF  ; no fakes allowed
    ldd                     ; regular ldd
    ldi                     ; regular ldi
    ldd     a,(hl)          ; regular ldd with "unexpected ...." error when fakes are OFF
    ldi     a,(hl)          ; regular ldi with "unexpected ...." error when fakes are OFF

    ;; part 2 (new commit)
    ; illegal instructions (exercising all code paths)
    in      hl,(c)
    out     (c),hl
    bit     -1,a
    bit     8,b
    res     -1,a
    res     8,b
    set     -1,a
    set     8,b
    rl      sp
    rlc     sp
    rr      sp
    rrc     sp
    sla     sp
    sli     sp
    sra     sp
    srl     sp

    ; multiarg
    or      b ,, c ,, 123
    xor     b ,, c ,, 123
    out     (c),b ,, (254),a
    res     5,c ,, 3,(ix+4),d
    set     5,c ,, 3,(ix+4),d
    rl      a ,, b
    rlc     a ,, b
    rr      a ,, b
    rrc     a ,, b
    rst     $08 ,, $38
    sbc     a ,, b
    sla     a ,, b
    sli     a ,, b
    sra     a ,, b
    srl     a ,, b

    ; no fakes allowed
    rl      bc
    rr      bc
    sla     hl
    sla     bc
    sli     bc
    sra     bc
    srl     bc

    ; "Comma expected" error
    sbc     hl
    sub     hl

    ; reverse pop code path exercise
    OPT reset --syntax=ab --reversepop
    pop     af,,bc,,de,,hl,,ix,,iy      ;; regular + multiarg
    pop     sp          ; illegal

    ;; part 3 (new commit, focusing on branching in the code, exercising more combinations and code paths)
    ; these tests (whole this file) are unfortunately very implementation based, in case of major refactorings they may
    ; quickly lose their functionality (the machine code produced should be the same, but code coverage may regress).

    ; illegal instructions (exercising all code paths)
    sbc     hl,af
    sub     hl,af

    ;; no fakes allowed
    OPT reset --syntax=abF
    sub     hl,bc

    ;; branches extra coverage - not going to comment on each one, as these exercise very specific code paths
    ;; of current implementation (based on v1.13.3) and there's nothing special about them in general way

    ret     np
    ret     px
    ld      a,ixn
    ld      a,ixhn
    ld      a,ixln
    ld      a,iyn
    ld      a,iyhn
    ld      a,iyln
    ld      a,IXN
    ld      a,IXHN
    ld      a,IXLN
    ld      a,IYN
    ld      a,IYHN
    ld      a,IYLN
    ex      af,bc
    jp      [hl
    jp      [123]
    ld      a
    ld      hl,bc
    ld      hl,de
    ld      (ix),bc
    ld      (ix),de
    ld      (ix),hl
    ld      (hl),bc
    ld      (hl),de
    ld      (hl),hl
    ld      bc,(hl)
    ld      bc,(ix)
    ld      1,bc
    ld      (bc
    ld      (bc)
    ld      (bc),b

    OPT reset --syntax=ab
    ld      (ix+127),bc
    ld      (ix+127),de
    ld      (ix+127),hl
    ld      bc,(ix+127)

    OPT reset --syntax=abf
    ldd     a
    ldd     a,
    ldd     a,(hl)
    ldd     b
    ldd     b,
    ldd     b,(hl)
    ldd     (hl)
    ldd     (hl),
    ldd     (hl),a
    ldd     (iy)
    ldd     (iy),
    ldd     (iy),a
    ldd     (de)
    ldd     (de),
    ldd     (de),a
    ldd     (de),b

    ldi     a
    ldi     a,
    ldi     a,(hl)
    ldi     b
    ldi     bc
    ldi     b,
    ldi     b,(hl)
    ldi     (hl)
    ldi     (hl),
    ldi     (hl),a
    ldi     (iy)
    ldi     (iy),
    ldi     (iy),a
    ldi     (de)
    ldi     (de),
    ldi     (de),a
    ldi     (de),b
    ldi     hl,(hl)

    ;; part 4 (more of the branching stuff, handpicked from local detailed coverage report)
    ld      a,[ix]
    ex      (bc),hl
    ex      (sp
    in      b
    in      (c)
    jr      $+2-129
    jr      $+2+128
    xor     hl,0
    adc     de,hl

    OPT reset --syntax=abF
    ld      de,(ix)

    OPT reset --syntax=a
    bit     -1,a
    call    nz
    ex      (sp),de
    im      3
    in      b,(254)
    jp      nz
    jr      nz
    ld      a,(bc
    ld      a,(de
    ld      a,[1234
    ld      (ix),ix
    ld      sp,(iy+13)
    ld      de,[1234
    ld      ix,[1234
    ldd     a,[de
    ldd     a,[hl
    ldd     a,[ix+3
    ldd     [hl
    ldd     [sp],a
    ldi     a,[de
    ldi     a,[hl
    ldi     a,[ix+3
    ldi     [hl
    ldi     [sp],a
    ldi     l,[hl
    ldi     l,[ix+3
    out     (c)
    out     (c),1
    out     (254),h
    push    e
    sub     de,de
