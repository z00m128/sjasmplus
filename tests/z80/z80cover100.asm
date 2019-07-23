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
