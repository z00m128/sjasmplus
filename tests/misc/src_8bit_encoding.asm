; test to check if source file is treated as 8-bit byte array, assembling texts inside DB statements 1:1 into machine code
; this should produce 256 bytes going from 0 to 255
; the source file encoding is "custom", do not edit with text editor, but use hex-editor instead

    OUTPUT "src_8bit_encoding.bin"

  IF 1      ; switch to 0 to generate the 0-255 example bin by simple DUP 256
    ; $00..$3F
    DB  "\0	\n\r !\"#$%&'()*+,-./0123456789:;<=>?"
    ASSERT $40 == $
    ; $40..$7F
    DB  "@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
    ASSERT $80 == $
    ; $80..$BF
    DB  "€‚ƒ„…†‡ˆ‰Š‹Œ‘’“”•–—˜™š›œŸ ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿"
    ASSERT $C0 == $
    ; $C0..$FF
    DB  "ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏĞÑÒÓÔÕÖ×ØÙÚÛÜİŞßàáâãäåæçèéêëìíîïğñòóôõö÷øùúûüışÿ"
    ASSERT $100 == $
  ELSE
    ; produce the same 0..255 by script
val = 0
    DUP 256
        DB val
val = val + 1
    EDUP
  ENDIF

    OUTEND
