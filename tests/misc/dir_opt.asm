; requires --dirbol on command line (for testing purposes of last OPT pop restoring it)
OPT pop                     ; warn about no previous syntax in stack
    ld      hl,bc,de,bc
    mirror  a               ; error (Z80N instruction)

    ; try all possible options
OPT push reset --nofakes --syntax=a --zxnext=cspect --reversepop --dirbol
    ld      hl,bc,,de,bc    ; error because --nofakes (!)
    sub     a,b,,c
    mirror  a : break       ; next enabled, including CSpect emulator extras
    pop     hl,,bc          ; pop bc : pop hl (--reversepop)
    pop     bc  ; validation
OPT push reset --syntax=aBfl    ; this one can be at beggining of line (--dirbol)
OPT = 1 : nop : OPT --dirbol  ; first is label, instruction, adding --dirbol back (no push/reset)
    ld      hl,bc,,de,bc    ; 2x warning about fAkEs (suppression is case sensitive)
    ld      hl,bc           ; fake with suppressed warning
    mirror  a               ; error (Z80N instruction)
    pop     hl,,bc          ; pop hl : pop bc
    pop     hl  ; validation
OPT pop : OPT pop           ; pop syntax two times (and verify --dirbol works)
    ld      hl,bc,de,bc
OPT pop : OPT reset         ; warn about no previous syntax in stack, then reset (but no options)
OPT = 2 : nop               ; this one is no more dirbol, but just a label

    OPT --nologo 1 2 3 4 5 6 7 8 9 A B C D E F G ; invalid option(s) and many of them

    OPT unknown             ; error about invalid command
    OPT reset push          ; warn about pushing default syntax

    ; verify if -Wfake/Wno-fake works similarly to --syntax=f
    ld      bc,hl           ; no warning in default syntax
    OPT push -Wfake
    ld      bc,hl           ; warning
    ld      bc,hl           ; warning suppressed by fake-ok
    OPT push -Wno-fake
    ld      bc,hl           ; no warning
    OPT pop
    ld      bc,hl           ; warning from previous state
    OPT pop
    ld      bc,hl           ; no warning in default
