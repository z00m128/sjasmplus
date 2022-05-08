    ; this was changed from fatal error to regular error by request of Neo-spectruman
    ; although this seems not very practical, as the internal address will be derailed,
    ; probably causing extra errors later, but whatever, you should fix errors in your code
    ORG $8000

    ; test error upon "too short" due to wrong offset
    INCBIN "incbin_tooshort.asm", 4000, 1
    ASSERT $8000 == $   ; nothing was included

    ; test error upon "too short" due to wrong length
    INCBIN "incbin_tooshort.asm", -5, 10
    ASSERT $8005 == $   ; 5 bytes were included

    ; test error upon "too short" due to wrong combination of offset and length
    INCBIN "incbin_tooshort.asm", -5, -10
    ASSERT $8005 == $   ; nothing included

    ; test error upon "too short" due to wrong combination of offset and length
    INCBIN "incbin_tooshort.asm", 5, 4000
    ; N bytes will be included, up to current file length
    ASSERT $8005 + 4000 != $    ; but not 4000 for sure
