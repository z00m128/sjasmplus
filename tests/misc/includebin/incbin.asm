    ;; the included incbin/incbin.bin is fake file (doesn't have correct checksums/etc)
    ; its payload is actually ASCII text, readable by text editor
    OUTPUT "incbin.bin"

    ; create copy of original 256B data by using 3 parts
    INCBIN "incbin/incbin.bin",,128
    INCBIN "incbin/incbin.bin",128,64
    INCBIN "incbin/incbin.bin",192
    ; just read whole 256B data in one go
    INCBIN "incbin/incbin.bin"
    ; another composed 256B copy (having extra spaces everywhere to exercise parser)
    INCBIN "incbin/incbin.bin"  ,  ,  128
    INCBIN "incbin/incbin.bin"  ,  128  ,  64
    INCBIN "incbin/incbin.bin"  ,  192
    ; = 3x256 = 768B output so far

    ; Exercise the new negative offset/length functionality
    INCBIN "incbin/incbin.bin", -256, -64   ; first 192B
    INCBIN "incbin/incbin.bin", -64         ; remaining 64B
    ; = 4x256 = 1024B output so far
    OUTEND

    ; Exercise (some) error/warning states of INCBIN
    INCBIN "incbin/incbin.bin",,0           ; warning length=0
    ;INCBIN "incbin/incbin.bin",,65537       ; warning max 64kiB - too short file to test this
    // rest of errors are FATAL type, PITA to test

    INCBIN "incbin/incbin.bin",
    INCBIN "incbin/incbin.bin",,
    INCBIN "incbin/incbin.bin",+
    INCBIN "incbin/incbin.bin",0,
    INCBIN "incbin/incbin.bin",0,+
