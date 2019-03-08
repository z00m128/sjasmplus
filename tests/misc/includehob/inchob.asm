    ;; the included inchob/inchob.$c is fake file (doesn't have correct checksums/etc)
    ; its payload is actually ASCII text, readable by text editor
    OUTPUT "inchob.bin"

    ; create copy of original 256B data by using 3 parts
    INCHOB "inchob/inchob.$c",,128
    INCHOB "inchob/inchob.$c",128,64
    INCHOB "inchob/inchob.$c",192
    ; just read whole 256B data in one go
    INCHOB "inchob/inchob.$c"
    ; another composed 256B copy (having extra spaces everywhere to exercise parser)
    INCHOB "inchob/inchob.$c"  ,  ,  128
    INCHOB "inchob/inchob.$c"  ,  128  ,  64
    INCHOB "inchob/inchob.$c"  ,  192
    ; = 3x256 = 768B output

    OUTEND
