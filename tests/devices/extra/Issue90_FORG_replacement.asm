    MACRO FORG addr?
         ; add padding + display warning
         IF $ > addr?
           ; no padding
           DISPLAY /L, "Warning! PADORG failed! ", $, " is more than ", addr?
         ELSE
           ; add padding
           BLOCK addr?-$
         ENDIF
         ORG addr?      ; fileorg-ok suppress built-in warning
    ENDM

        OUTPUT  "Issue90_FORG_replacement.bin"
        SIZE    $140
        DEVICE  ZXSPECTRUM48
;--------------------------------
        ORG	$0000

        JP  START
;--------------------------------

        FORG 0x0066

        JP  START
;--------------------------------
        FORG 0x0100

START:	DI
        LD  a, 0x10
        LD  (0x4010), a

        LD  a, (0x4010)
        OUT (54H), a

        HALT
;--------------------------------

        FORG 0x40   ; verify the warning message works
