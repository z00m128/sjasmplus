    ORG 100h ; or 0x100, or $100, or #100

    ; useful macro that padding code
    MACRO PADORG addr
         ; add padding
         IF $ < addr
         BLOCK addr-$
         ENDIF
         ORG addr
    ENDM

    MACRO PADORG2 addr
         ; add padding + display warning
         IF $ > addr
           ; no padding
           DISPLAY /L, "Warning! PADORG failed! ", $, " is more than ", addr
         ELSE
           ; add padding
           BLOCK addr-$
         ENDIF
         ORG addr
    ENDM

    ; try the macros defined in documentation
    PADORG $104
    PADORG2 $106
    PADORG2 $102
    nop
    PADORG2 $103
