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

; Issue #275 -> refactoring implementation to allow flow changes till next to last pass
    IF 2 <= __PASS__
100:
    ENDIF
    jp  100_b
    jp  100_f
    IF 2 <= __PASS__
100:
    ENDIF
; check warnings about value change in last pass
    IF 3 <= __PASS__
    rst 0
    ENDIF
    IF 2 <= __PASS__
101:
    ENDIF
    jp  101_b
    jp  101_f
    IF 2 <= __PASS__
101:
    ENDIF
; check error about flow change in penultimate <-> last pass
    IF 2 == __PASS__
    rst 0       ; neutralize address change from previous block
    ENDIF
102:
    IF 3 <= __PASS__
103:
    ENDIF
    jp  102_b
    jp  102_f
    IF 3 <= __PASS__
103:
    ENDIF
102:
