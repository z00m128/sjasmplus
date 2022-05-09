;;;;;;; warning emitting test (for all affected instructions) ;;;;;;;;;;
    OPT reset       ; default syntax
    ; round parentheses memory access to low address 0..255 emits warning
    ld  a,(1)
    ld  hl,(2)
    ld  bc,(3)
    ld  de,(4)
    ld  sp,(5)
    ld  ix,(6)
    ld  iy,(7)
    ; addresses 256+ are of course OK by default
    ld  a,(0x101)
    ld  hl,(0x102)
    ld  bc,(0x103)
    ld  de,(0x104)
    ld  sp,(0x105)
    ld  ix,(0x106)
    ld  iy,(0x107)
    ; square brackets are without warning
    ld  a,[1]
    ld  hl,[2]
    ld  bc,[3]
    ld  de,[4]
    ld  sp,[5]
    ld  ix,[6]
    ld  iy,[7]
    ; immediates are also ok
    ld  a,1
    ld  hl,2
    ld  bc,3
    ld  de,4
    ld  sp,5
    ld  ix,6
    ld  iy,7

    OPT reset --syntax=b    ; syntax "b" (round parentheses mark memory access only)
                            ; should behave identically to default ("b" doesn't affect these)
    ; round parentheses memory access to low address 0..255 emits warning
    ld  a,(1)
    ld  hl,(2)
    ld  bc,(3)
    ld  de,(4)
    ld  sp,(5)
    ld  ix,(6)
    ld  iy,(7)
    ; addresses 256+ are of course OK by default
    ld  a,(0x101)
    ld  hl,(0x102)
    ld  bc,(0x103)
    ld  de,(0x104)
    ld  sp,(0x105)
    ld  ix,(0x106)
    ld  iy,(0x107)
    ; square brackets are without warning
    ld  a,[1]
    ld  hl,[2]
    ld  bc,[3]
    ld  de,[4]
    ld  sp,[5]
    ld  ix,[6]
    ld  iy,[7]
    ; immediates are also ok
    ld  a,1
    ld  hl,2
    ld  bc,3
    ld  de,4
    ld  sp,5
    ld  ix,6
    ld  iy,7

    OPT reset --syntax=B    ; syntax "B" (square brackets only for memory access)
                            ; should turn round parentheses into immediates = no warning
    ; immediates in round parentheses
    ld  a,(1)
    ld  hl,(2)
    ld  bc,(3)
    ld  de,(4)
    ld  sp,(5)
    ld  ix,(6)
    ld  iy,(7)
    ; still immediates
    ld  a,(0x101)           ; correct warning about truncating value
    ld  hl,(0x102)
    ld  bc,(0x103)
    ld  de,(0x104)
    ld  sp,(0x105)
    ld  ix,(0x106)
    ld  iy,(0x107)
    ; square brackets are without warning
    ld  a,[1]
    ld  hl,[2]
    ld  bc,[3]
    ld  de,[4]
    ld  sp,[5]
    ld  ix,[6]
    ld  iy,[7]
    ; immediates are also ok
    ld  a,1
    ld  hl,2
    ld  bc,3
    ld  de,4
    ld  sp,5
    ld  ix,6
    ld  iy,7


;;;;;;; warning suppression mechanisms ;;;;;;;;;;
    OPT reset --syntax=abfw
    ; warning not suppressed or wrongly suppressed -> emit warning
    ld  a,(1)
    ld  a,(1)   ;
    ld  a,(1)   ;	
    ld  a,(1)   ;rdlow
    ld  a,(1)   ;rdlow-
    ld  a,(1)   ;rdlow-o
    ld  a,(1)   ;rdlow-Ok
    ld  a,(1)   ;rdlow-0k
    ld  a,(1)   ;RDLOW-OK (big capitals don't work!)
    ld  a,(1)   ;rdlow-oK
    ld  a,(1)   ;RDLOW-ok
    ld  a,(1)   ;Rdlow-ok
    ld  a,(1)   ;rdlow-OK
    ld  a,(1)   ;Rdlow-Ok

    ; warning suppressed correctly
    ld  a,(1)   ;rdlow-ok
    ld  a,(1)   ;;;;;;;;;;;rdlow-ok
    ld  a,(1)   //rdlow-ok
    ld  a,(1)   /////rdlow-ok

    ; with whitespace and letters ahead of suppressing text
    ld  a,(1)   ;  blabla  rdlow-ok
    ld  a,(1)   ;;;;;;;;;;;  blabla  rdlow-ok
    ld  a,(1)   //  blabla  rdlow-ok
    ld  a,(1)   /////  blabla  rdlow-ok

    ; following include TABs (mixed with spaces)! (make sure they stay there)
    ld  a,(1)   ;	  	rdlow-ok
    ld  a,(1)   ;;;;;;;;;;;	  	rdlow-ok
    ld  a,(1)   //	  	rdlow-ok
    ld  a,(1)   /////	  	rdlow-ok

    ld  a,(1)   ;rdlow-ok.
    ld  a,(1)   ;rdlow-ok?
    ld  a,(1)   ;rdlow-ok!
    ld  a,(1)   ;rdlow-ok+
    ld  a,(1)   ;rdlow-ok blabla


;;;;;;; test suppression for fake instructions ;;;;;;;;;;
    OPT reset --syntax=abf
    ldi a,(hl)  ; warning
    ldi a,(hl)  ; this is "fake" instruction (warning suppressed by "fake")
    ldi a,(hl)  ; iz fakeish instruztione (substring can be anywhere)
    ; the "ok" way is removed since v1.19.0, use "fake"

;;;;;;; docs-grade example ;;;;;;;;;;

    ld      a,(16|4)    ;warning when accidentally using parentheses around 0..255 value

    ld      a,(200)     ; rdlow-ok Intentionally accessing ROM data at address 200
        ; the "rdlow-ok" in the end-of-line-comment does suppress the warning
