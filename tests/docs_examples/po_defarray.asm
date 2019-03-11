;;; the example is slightly modified to produce some actual binary data for automatic testing
    DEFARRAY myarray 5*13,"B",67,40+28,'e'-32,'F'
    ; And the produced data should be ASCII string "ABCDEF"

    OUTPUT 'po_defarray.bin'

CNT=0
    DUP 6
    ;; DISPLAY myarray[CNT]  (do not clutter stdout, instead produce BIN)
    db  myarray[CNT]
CNT=CNT+1
    EDUP
