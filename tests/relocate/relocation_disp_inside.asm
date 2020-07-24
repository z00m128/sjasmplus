    ; init ZX48 device, put machine code at $8000
    DEVICE ZXSPECTRUM48 : ORG $8000

    RELOCATE_START

    dw      relocate_count
    dw      relocate_size

vram_routine_bytes:                 ; relocatable label
    ; like use case: "helper routine to be displaced at runtime to ULA VRAM"
    DISP    vram_routine_bytes      ; error, no DISP for relocatable labels
    DISP    $4000
vram_routine:                       ; absolute label (and "$" should be absolute here too)
    ld      hl,$-$300               ; should not relocate
    ld      de,$+$800               ; should not relocate
    ld      ix,vram_routine_bytes   ; should give relocate data for the physical location ($8000+ address)
    jp      nz,vram_routine         ; should not relocate
    jp      absolute1               ; should not relocate

    RELOCATE_END    ; error - can't finish relocate block with DISP block open

    ENT             ; end displacement routine
vram_routine_bytes.size EQU $ - vram_routine_bytes  ; should be length

    ; use case: "dislocating the subroutine to target memory at runtime"
    ld      hl,vram_routine_bytes   ; should relocate
    ld      de,vram_routine         ; should not relocate
    ld      bc,vram_routine_bytes.size  ; absolute size (not relocate)
    ldir
    call    vram_routine            ; should not relocate
    jp      absolute1               ; should not relocate

    RELOCATE_END

absolute1:
    jp      absolute1               ; should not relocate

    ENT                             ; error ENT without DISP

    RELOCATE_TABLE
        ; 0C 80 15 80 ($800C, $8015)

    ; verify the actual machine code was placed at $8000 in virtual device memory
    SAVEBIN "relocation_disp_inside.bin", $8000, $ - $8000

    ASSERT 2 == relocate_count
    ASSERT 2*relocate_count == relocate_size
    ASSERT 3 == __ERRORS__
    ASSERT 0 == __WARNINGS__
