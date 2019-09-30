;; test to exercise instructions which are not Z80-identical into greater depth
;; focus is mostly on IDA syntax variants, the goal is to have it thoroughly tested
    OPT --syntax=abf    ; but this is expected "default" mode of syntax for new sources

;; example macro to get "halt" which emits automatically halt+nop like rgbasm does
halt    MACRO
            @halt
            nop
        ENDM
    halt    ; = halt+nop
    @halt   ; = halt (only)

    ; "variables" crossing into the $FF00 area, so some of them can be accessed with LDH
        STRUCT struct1
a           BYTE    1
b           BYTE    2
        ENDS

        ORG     $FF00-4
varSX       struct1
var1        db      0x34
var2        dw      0x5678
var3        db      0xAB
var4        dw      0xCDEF
varS        struct1

        ORG     $8000
            ld      a,[var1]        ; like LD a,(a16) on Z80
            ld      a,[var3]
            ldh     a,[low var3]
            ldh     a,[var3]
            ldh     a,[var1]        ; should warn about truncating value (bug in source)
            ld      [var1],a        ; like LD (a16),a on Z80
            ld      [var3],a
            ldh     [low var3],a
            ldh     [var3],a
            ldh     [var1],a        ; should warn about truncating value (bug in source)
            ; repeat the same exercise, but with parentheses
            ld      a,(var1)
            ld      a,(var3)
            ldh     a,(low var3)
            ldh     a,(var3)
            ldh     a,(var1)
            ld      (var1),a
            ld      (var3),a
            ldh     (low var3),a
            ldh     (var3),a
            ldh     (var1),a
            ; the uselessly more explicit syntax (but should work)
            ld      a,[$ff00 + low var3]
            ld      [$ff00 + low var3],a
            ; these should warn, this is not correct way of writing it (bug in source)
            ld      a,[$ff00 + var3]
            ld      [$ff00 + var3],a
            ; accessing the structure members
            ldh     a,[varS.a]
            ldh     [varS.b],a
            ldh     a,[varSX.a]     ; warning, outside of $FFxx area
            ldh     [varSX.b],a     ; warning, outside of $FFxx area
            ld      a,[varS.a]      ; regular LD is optimized if possible
            ld      [varS.b],a      ; regular LD is optimized if possible
            ld      a,[varSX.a]
            ld      [varSX.b],a

            ; whitespace parsing in "(c)" operand (not much else to test)
            ld      a , ( c )
            ld      ( c ) , a
            ; illegal register combinations, all should produce some error (mostly "illegal instruction")
            ld      a , ( b )
            ld      ( b ) , a
            ld      b , ( c )       ; error, illegal instruction; --syntax=b reports "ld b,(mem)"
            ld      ( c ) , b
            ld      hl,(c)
            ld      (c),hl

            ld      a,(123)         ; check if low-memory warning is off in LR35902 mode (good idea?? not sure)

            ldi     a,(hl+)         ; error, mixed invalid syntax
            ldi     a , ( hl )
            ld      a , [ hl+ ]
            ld      a , [ hl + ]    ; error, the "hl+" must be together
            ld      a,(hl+0)        ; error, there's no such thing

            ldd     a,(hl-)         ; error, mixed invalid syntax
            ldd     a , ( hl )
            ld      a , [ hl- ]
            ld      a , [ hl - ]    ; error, the "hl-" must be together
            ld      a,(hl-0)        ; error, there's no such thing

            ldi     (hl+),a         ; error, mixed invalid syntax
            ldi     ( hl ) , a
            ld      [ hl+ ] , a
            ld      [ hl + ] , a    ; error, the "hl+" must be together
            ld      (hl+0),a        ; error, there's no such thing

            ldd     (hl-),a         ; error, mixed invalid syntax
            ldd     ( hl ) , a
            ld      [ hl- ] , a
            ld      [ hl - ] , a    ; error, the "hl-" must be together
            ld      (hl-0),a        ; error, there's no such thing

            ; wrong registers => errors
            ldi     a,(de)
            ldd     a,(de)
            ld      a,(de+)
            ld      a,(de-)
            ldi     l,(hl)
            ldd     l,(hl)
            ld      l,(hl+)
            ld      l,(hl-)
            ldi     (de),a
            ldd     (de),a
            ld      (de+),a
            ld      (de-),a
            ldi     (hl),l
            ldd     (hl),l
            ld      (hl+),l
            ld      (hl-),l
            ldi     (hl),1
            ldd     (hl),2
            ld      (hl+),3
            ld      (hl-),4

            ld      hl,sp               ; implicit +0
            ld      hl , sp + 0
            ld      hl , sp - 0
            ld      hl , sp + 1
            ld      hl , sp - 1
            ld      hl , sp + +1
            ld      hl , sp + -1
            ld      hl , sp + +1
            ld      hl , sp (+1)        ; error, there must be + or - right after "sp"
            ld      hl , sp + struct1   ; hl = sp + sizeof(struct1)
            ld      hl , sp + 127
            ld      hl , sp + 128       ; error, value is beyond range
            ld      hl , sp - 128
            ld      hl , sp - 129       ; error, value is beyond range
            ld      hl , de + 1         ; invalid
            ld      de , sp + 1         ; invalid

            ld      ( var2 + 4 ) , sp
            ld      ( var2 + 4 ) , hl   ; invalid

            ; illegal "add sp,r8" variants
            add     sp
            add     sp ,
            add     sp , hl
            add     sp , +128
            add     sp , -129
            ; legit "add sp,r8"
            add     sp , 0
            add     sp , +127
            add     sp , -128
            add     sp , struct1        ; sp += sizeof(struct1)

            ; some more malformed lines (intermezzo ... getting back to opcodes already above)
            ld      (hl+)
            ld      [hl+]
            ld      (hl+),
            ld      [hl+],
            ld      [hl+),a
            ld      (hl+],a
            ldi     (hl)
            ldi     [hl]
            ldd     (hl)
            ldd     [hl]
            ldi     (hl),
            ldi     [hl],
            ldd     (hl),
            ldd     [hl],
            ldh     a
            ldh     a,
            ldh     (var3)
            ldh     (var3),
            ldh     [var3]
            ldh     [var3],
            ldh     [var3),a
            ldh     (var3],a
            ld      hl,s

            ; illegal syntax of swap
            swap
            swap    (var3)
            swap    var3
            swap    de
            swap    [de]
            swap    (a)
            swap    a,b
            ; legit ones
            swap    a
            swap    a,,b        ; multi-arg

            ; illegal syntax of stop
            stop    a
            stop    [0]
            stop    (hl)
            stop    0,,1        ; no multi-arg for STOP implemented
            ; legit ones
            stop                ; implicit 0
            stop    0
            stop    0xE0

            ; more multi-args exercised (only in "--syntax=a" mode)
            ldi     a,[hl],,a,(hl),,[hl],a,,(hl),a
            ldd     a,[hl],,a,(hl),,[hl],a,,(hl),a
            ld      a,[hl+],,a,(hl+),,[hl+],a,,(hl+),a
            ld      a,[hl-],,a,(hl-),,[hl-],a,,(hl-),a
            ldh     a,[varS.a],,[varS.b],a,,a,(varS.a),,(varS.b),a
            add     sp,3,,sp,4
            ld      hl,sp,,hl,sp+5,,hl,sp+6

            ;;;; more extra tests after pushing the commit (as always)

            ; LDH automagic in LD - range checks
            ld      a,(0xFEFF+0)        ; outside
            ld      a,(0xFEFF+1)        ; LDH
            ld      a,(0xFEFF+256)      ; LDH
            ld      a,(0xFEFF+257)      ; outside + warning
            ld      (0xFEFF+0),a        ; outside
            ld      (0xFEFF+1),a        ; LDH
            ld      (0xFEFF+256),a      ; LDH
            ld      (0xFEFF+257),a      ; outside + warning

    END     ; scratcharea
