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
    ; = 3x256 = 768B output

    ; Exercise (some) error/warning states of INCBIN (others are type FATAL, PITA to test)
    INCBIN "incbin/incbin.bin",-1
    INCBIN "incbin/incbin.bin",,-1
    INCBIN "incbin/incbin.bin",,0
    INCBIN "incbin/incbin.bin",256
    INCBIN "incbin/incbin.bin",123,0

    OUTEND
