    org $3000
    relocate_start

test1   equ     $           ; should have isRelocatable flag
test2   equ     $ + 23      ; should have isRelocatable flag
test3   equ     $ - test1   ; size of code = no relocation

        dw      relocate_count
        dw      relocate_size

        ld      hl,test1    ; to be relocated
        ld      de,test2    ; to be relocated
        ld      bc,test3    ; no relocation
        ld      sp,noRel1   ; no relocation

    relocate_table

    relocate_end

noRel1  equ     $
    ; no relocation outside of the block
        ld      hl,test1
        ld      de,test2
        ld      bc,test3
        ld      sp,noRel1   ; no relocation

    ASSERT 2 == relocate_count
    ASSERT 0 == __ERRORS__
    ASSERT 0 == __WARNINGS__
