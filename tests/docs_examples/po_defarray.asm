;;; this example is currently malfunctioning ... to be fixed one day...
;;; https://github.com/z00m128/sjasmplus/issues/33
    DEFARRAY myarray 10*20,"A",20,</D,40>,50,70

CNT=0
    DUP 6
    DISPLAY myarray[CNT]
CNT=CNT+1
    EDUP

;;; testable variant (producing some code)

    OUTPUT 'po_defarray.bin'

    DEFARRAY arr2 1, 2, 3
CNT=0
    DUP 3
    ld  a, arr2[CNT]
CNT=CNT+1
    EDUP
