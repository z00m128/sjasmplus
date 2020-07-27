    ; the forward reference to reloc_label2 without knowing it's relocatable does cause
    ; "reloc_label2-reloc_label" to be reported as one more thing to relocate in pass 1
    ; thus the max_count is then 2 when pass 1 is finished = bug in early prototype
    ORG $1234

    RELOCATE_START

    ASSERT 2 * relocate_count == relocate_size
    ASSERT 1 == relocate_count
    dw      relocate_count
    dw      relocate_size

reloc_label:
    ld      hl,reloc_label              ; relocation needed
    ld      bc,reloc_label2-reloc_label ; no relocation

reloc_label2:

    RELOCATE_END

    RELOCATE_TABLE

    ASSERT 0 == __ERRORS__
    ASSERT 0 == __WARNINGS__
