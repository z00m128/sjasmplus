mac1    MACRO
.mac1_start:
            ld      b,b
            DUP 3
2:
                ld      b,(hl)
                IF alternate
                    IF !alternate
                        fialovy fail
                        LUA PASS3
                            nonsense anyway --never assembled
                        ENDLUA
                        IF 0 : fail : ELSE : fail : ENDIF
                    ELSE
                        ld      b,a
                        IF 0 : fail : ELSE : inc sp : ENDIF
                    ENDIF
                ENDIF
alternate = !alternate
            EDUP
            ld      b,c
.mac1_end:
        ENDM

mac2    MACRO
.mac2_start:
            ld      c,b
            LUA ALLPASS
                luaLabelId = 0
            ENDLUA
            DUP 3
                MMU 4, $$+4
1:
                mac1
                jr      nz,2B
                jr      z,1B
                LUA ALLPASS
                    _pc("ld c,a")
                    _pl(".luaLab"..luaLabelId.." ld c,(hl)")
                    luaLabelId = luaLabelId + 1
                    if 3 == luaLabelId then
                        _pc("mac1")
                    ; end
                ENDLUA
            EDUP
            ld      c,c
.mac2_end:
        ENDM

mac3    MACRO
.mac3_start:
        .2  ld      d,b         ; emit 2x
.mac2_emit:
            mac2
            ld      d,c
.mac3_end:
        ENDM

    DEVICE ZXSPECTRUMNEXT
        MMU 0 7, 10                         ; map pages 10..17 to each slot
        ORG $8000
main:
.start:
            ld      e,b
alternate = 1
.mac3_emit1:
            mac3
            ld      e,c
.mac3_emit2:
            mac3
            ld      e,d
.end:

        DUP 3
1:          ld      h,b
            ld      h,d
        EDUP
        ld      h,a

    CSPECTMAP "sld_complex.sym"
    DEVICE NONE    ; does damage CSPECTMAP export!! the source must end with NEXT device
    DEVICE ZXSPECTRUMNEXT   ; fix CSPECTMAP to follow Next memory paging
