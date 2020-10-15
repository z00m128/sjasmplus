; (this is example how sjasmplus can be exploited as byte-processor over file content)
;
; script to convert 1bpp font (like original ZX ROM font, .ch8 files or .udg files)
; to assembly source form using `DG` directive, so you can see/modify the pixels
; in your text editor while editing code, if you prefer this style of workflow
; (over including the binary form by `INCBIN`).
;
; usage: sjasmplus chargfx2asm.script.asm -DFIN="input.ch8" -DFOUT="result.asm"
;
; The example "ZX Courier.ch8" file is font by DamienG: https://damieng.com/zx-origins
; Check Damien's amazing site for font's license details and other fonts.

    ; default example file names in case they are not provided on command line
    IFNDEF FIN : DEFINE FIN "ZX Courier.ch8" : ENDIF
    IFNDEF FOUT : DEFINE FOUT "ZX Courier.ch8.i.asm" : ENDIF

    DEVICE ZXSPECTRUM48 : ORG 0 : INCBIN FIN
udgEnd:
udgB=0
        OUTPUT FOUT
            DUP udgEnd
                IFN udgB%8 : DB "\n" : ENDIF
                DB "\tDG  "
mask=0x80
                DUP 8
                    IF mask & {b udgB} : DB '#' : ELSE : DB '-' : ENDIF
mask=mask>>1
                EDUP
                DB "\n"
udgB=udgB+1
            EDUP
        OUTEND
