;;; the example is modified to show bugs in sjasmplus v1.10.4 and to produce binary data for automatic testing
    DEFARRAY myarray 5*13,"B,C\"\\",'X''Y',67,40+28,'e'-32,'F',<'G','H!!!>'>
    ; And the produced data should be ASCII string "AB,C"\X'YCDEFGH!>"

    OUTPUT 'po_defarray_B.bin'

CNT=0
    DUP 8
    ;; DISPLAY myarray[CNT]  (do not clutter stdout, instead produce BIN)
    db  myarray[CNT]
CNT=CNT+1
    EDUP
