    ORG     $1000
    ; regular temporary label syntax
1
    jp  1B
    jp  1F
1
    ; new underscore suffix syntax
    jp  1_B
    jp  1_F
1
    ; old syntax in regular instructions is ignored ("1B" becomes binary value)
    ld  hl,1B
    ; new underscore suffix syntax enables temporary labels also in regular instructions
    ld  hl,1_B
    ld  hl,1_F
1
    ; check new underscore suffix in expressions
    ld  hl,((1_F+(1_B<<1))-1_F)>>1
1
    ; check usage across macro instances
    MACRO node num?, ofs?
        ld hl,1_B+ofs?
        ld (hl),num?
        ld hl,1_F+ofs?
1
    ENDM

    node 'A',1
    node 'B',2

    ld  hl,1_B!AD    ; this should fail
