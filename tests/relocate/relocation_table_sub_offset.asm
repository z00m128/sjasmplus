    org $3000
    relocate_start

    ld      hl,test
    ld      de,test2
    ret

test    db  0
test2   db  0
        dw  relocate_count
        dw  relocate_size

    relocate_table $1000    ; test optional argument
    relocate_table          ; regular table with original offsets
    relocate_table -$1000

    relocate_end

    ; test syntax error check
    relocate_table @@
    relocate_table ,
    relocate_table $1000,
    relocate_table $1000, 123

    ASSERT 4 == __ERRORS__
    ASSERT 0 == __WARNINGS__
