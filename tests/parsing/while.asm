    ; docs example:
ptr = $4000
    WHILE ptr < $4020
        DB low ptr
ptr = ptr + 1
    EDUP

    ; other tests
    DEVICE ZXSPECTRUMNEXT : ORG $8000
searchMem:
    DB  0, 0, 0, 0
needle:
    DB  1
    DB  0, 0, 0, 0
searchMemEnd:

ptr = searchMem
    WHILE (ptr < searchMemEnd) && ({b ptr} == 0)    ; search for "1" in memory
        ; ^ keep in mind {b ..} reads as zero until last pass
ptr = ptr + 1
    ENDW
    ASSERT needle == ptr

    WHILE needle <= ptr + 3     ; nested whiles
        WHILE needle <= ptr + 1
ptr = ptr - 1
        ENDW
ptr = ptr - 1
    ENDW
    ASSERT needle == ptr + 4

    ; syntax errors/warnings
    WHILE
    ENDW

    WHILE @
        nop
    ENDW

    WHILE fwdLabel < $8000
        ASSERT 0
    ENDW

fwdLabel:

    ; test the infinite-loop guardian (default 100k)
cnt = 0
    OPT push listmc
    WHILE cnt <= 100000
cnt = cnt + 1
    ENDW
    OPT pop

    ; test custom-explicit infinite-loop guardian
cnt = 0
    WHILE cnt < 2, 2   ; looping twice with guardian "2" => without error
cnt = cnt + 1
    ENDW

cnt = 0
    WHILE cnt < 4, 2   ; looping trice with guardian "2" => error
cnt = cnt + 1
    ENDW

cnt = 0
    WHILE cnt < 2, @   ; syntax error in guardian-couner value
cnt = cnt + 1
    ENDW
