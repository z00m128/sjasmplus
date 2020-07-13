    org #1000
    relocate_start
        ld hl,test
        ld de,test2
        ret
test	db 0
test2	db 0
        dw relocate_count
        dw relocate_size
    relocate_table
    relocate_end
