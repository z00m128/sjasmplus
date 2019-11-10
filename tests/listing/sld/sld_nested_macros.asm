mac1    MACRO
.mac1_start:
            ld      b,b
            ld      b,c
.mac1_end:
        ENDM

mac2    MACRO
.mac2_start:
            ld      c,b
.mac1_emit:
            mac1
            ld      c,c
.mac2_end:
        ENDM

mac3    MACRO
.mac3_start:
            ld      d,b
.mac2_emit:
            mac2
            ld      d,c
.mac3_end:
        ENDM

    DEVICE ZXSPECTRUMNEXT
        MMU 0 7, 10                         ; map pages 10..17 to each slot
        ORG $8000
        OUTPUT "sld_nested_macros.bin"
main:
.start:
            ld      e,b
.mac3_emit1:
            mac3
            ld      e,c
.mac3_emit2:
            mac3
            ld      e,d
.end:

    CSPECTMAP "sld_nested_macros.sym"
