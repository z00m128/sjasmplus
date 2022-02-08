    OUTPUT "issue172_dup_zero.bin"
    DUP 1
        DB 'A'
    EDUP
    DUP 0
        DB 'B'
    EDUP
    DUP 2
        DB 'C'
    EDUP

    ; check also error message for negative count
    DUP -1
