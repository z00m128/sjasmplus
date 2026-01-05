    OUTPUT "org_warning.bin"
    ORG     1000    ; no warning, no byte in the open output file yet, free to set first address
    ld      b,c
    ORG     3000    ; warning: ORG not emitting padding bytes
    ld      b,d
    ORG     2000    ; warning: ORG not emitting padding bytes (erasing in this case)
    ld      b,e
    ORG     2001    ; no warning, address does match $
    ld      b,h
    ORG     4000    ; fileorg-ok ; warning suppressed
    ld      b,l
    OUTEND

    ORG     5000    ; no warning, output file is closed here
    ld      hl,"!!"

    OUTPUT "org_warning.bin",a      ; append to first file, but ORG warnings are reset
    ORG     6000    ; no warning, first byte after re-opening the file
    ld      b,(hl)
    ORG     7000    ; warning
    ld      b,a
    OUTEND
