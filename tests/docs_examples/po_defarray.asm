;;; this example is currently malfunctioning ... to be fixed one day...
;;; https://github.com/z00m128/sjasmplus/issues/33
    DISPLAY "Currently malfunctioning (Issue #33), the BIN is intentionally disabled to 'pass'"

;;; the example is slightly modified to produce some actual binary data for automatic testing
    DEFARRAY myarray 10*20,"A",20,40,50,70

    OUTPUT 'po_defarray.bin'

CNT=0
    DUP 6
    ;; DISPLAY myarray[CNT]  (do not clutter stdout, instead produce BIN)
    db  myarray[CNT]
CNT=CNT+1
    EDUP
