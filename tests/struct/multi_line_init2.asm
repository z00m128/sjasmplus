; variation on more complex internal states of sjasmplus (reading multi-line from macro definition/etc)

    OUTPUT "multi_line_init2.bin"

    DB  "1) single-line classic initializers test:\n"

    STRUCT S_sub1
b1      byte    $11
t1      text    5, { "txt", '_' }
w1      word    $3322
    ENDS

    STRUCT S_main
b2      byte    $44
s1      S_sub1
    ENDS

    ; 2x S_main instance by using dot-repeater -> no label assigned to these
dotRep  .2  S_main { 'a', { 'b', { "cdefg" }, "\nh" } }

    ; 2x S_main instance by using DUP+EDUP
dupRep:
        DUP 2
            S_main { 'i', { 'j', { "klmno" }, "\np" } }
        EDUP

    ; emit structure inside macro
macDef  MACRO   b1?, t1?
.macSub     S_main { '<', { b1?, { t1? }, "\n>" } }
        ENDM

    ; emit 2x structure inside macro with dot repeater (structs have own macro-specific label)
        .2  macDef 'B', < 'C', 'D', "EF" >

        DUP 2
            macDef 'b', < 'c', 'd', "ef" >
        EDUP

    DB  "\n2) same code, but multi-line variants:\n"
    DB  "(dot-repeater variants are NOT supported)\n"

    ; 2x S_main instance by using DUP+EDUP
mlDupRep:
        DUP 2
            S_main {
                'i',
                {
                    'j',
                    { "klmno" },
                    "\np"
                }
            }
        EDUP

    ; emit structure inside macro
macDef2  MACRO   b1?, t1?
.macSub     S_main {
    '<',
    {
        b1?,
        { t1? },
        "\n>"
    }
}
        ENDM

    ; emit 2x structure inside macro with dot repeater (structs have own macro-specific label)
        .2  macDef2 'B', < 'C', 'D', "EF" >

        DUP 2
            macDef2 'b', < 'c', 'd', "ef" >
        EDUP

    ; 2x S_main instance by using dot-repeater -> this one is *NOT* supported
    ; it should NOT read more lines outside of the macro scope, and report missing "}"
mlDotRep  .2  S_main {
        ld  b,c : ld a,(bc) ; this should be processed as instructions => 41 0A ("A\n")

    ; try dot-repeater inside macro definition as ultimate complexity thing
    ; (ignoring IF type of complexity and recursion, because I want to finish it today)
    ; this is still *NOT* supported and the second instance will miss the "}"
macDef3  MACRO   b1?, t1?
        .2 S_main {
    '{',
    {
        b1?,
        { t1? },
        "\n}"
    }
}
        ENDM

    ; this should fail due to dot-repeater used for multi-line initializer
        macDef3 '1', "2345"
        ld  b,d : ld a,(bc) ; this should be processed as instructions => 42 0A ("B\n")

    OUTEND
