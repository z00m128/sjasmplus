    ; init ZX48 device, put machine code at $8000
    DEVICE ZXSPECTRUM48 : ORG $8000
    ; but make relocation block base address $0000 with DISP
    DISP $0000

    RELOCATE_START

    dw      relocate_count
    dw      relocate_size

label1:
    call    label1              ; relocate
    call    absolute1           ; no relocation
label2:
    ld      hl,label2-label1    ; no relocation

    ENT                         ; error, can't finish DISP which did start outside

    RELOCATE_END

absolute1:
    ENT

    RELOCATE_TABLE
    ; 05 00

    ; verify the actual machine code was placed at $8000 in virtual device memory
    SAVEBIN "relocation_disp_outside.bin", $8000, $ - $8000
