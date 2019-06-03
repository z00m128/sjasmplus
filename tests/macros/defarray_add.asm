; this test does not only test newly added "DEFARRAY+", but also tests syntax error reports
    DEFARRAY    myarray 'A', 'B', 'C'
    DEFARRAY+   myarray 'D', 'E', 'F'

    OUTPUT 'defarray_add.bin'           ; emit all six items into file to check content
CNT=0
    DUP 6
    db  myarray[CNT]
CNT=CNT+1
    EDUP

    ; error tests (also for regular DEFARRAY, as it was not tested much before)
    DEFARRAY
    DEFARRAY+
    DEFARRAY    myarray 'X', 'Y', 'Z'   ; duplicate definition
    DEFARRAY+   noneId 'D', 'E', 'F'    ; undefined id
    DEFARRAY    noneId                  ; empty values
    DEFARRAY+   myarray                 ; empty values
    db          myarray[3]
    db          myarray[-1]
    db          noneId[0]
    DEFARRAY    myarray+48              ; enforce white space between ID and first value
    DEFARRAY+   myarray+49              ; enforce white space between ID and first value
