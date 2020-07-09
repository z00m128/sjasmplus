    OUTPUT "inc_3let_extension.bin"
    INCTRD "inc_3let_extension/test.trd", "data.bin"            ; file not found
    INCTRD "inc_3let_extension/test.trd", "data.bi"             ; full 288 bytes
    INCTRD "inc_3let_extension/test.trd", "data.bi", 8, 7       ; just "address" chars
    INCTRD "inc_3let_extension/test.trd", "data.bi", 287, 1     ; just last "a" byte
    INCTRD "inc_3let_extension/test.trd", "data.bi", 287, 2     ; err: length after offset OOB
    INCTRD "inc_3let_extension/test.trd", "data.bi", 286        ; just last "ta" bytes
    INCTRD "inc_3let_extension/test.trd", "data.bi", 288        ; err: offset after the file
    INCTRD "inc_3let_extension/test.trd", "data.bi", , 4        ; add first 4 "Data" bytes
    OUTEND
