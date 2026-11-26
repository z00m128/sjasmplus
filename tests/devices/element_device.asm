    DEVICE ELEMENT
    ; 8 slots with 8kiB size, 2560 pages = 20MiB, all memory initially zeroed, initial mapping 0, 1, ...
slotNumber = 0
    DUP 8
    ORG slotNumber * $2000
    ASSERT $$ == slotNumber
slotNumber = slotNumber + 1
    EDUP
    ASSERT {b $5800} == 0 && {b $5C00} == 0 && {b $FF58} == 0

    PAGE 2559
    ORG $E000
lastPage:
    DB "ELEMENT!"
    ASSERT $$lastPage == 2559
    ASSERT {b $E000} == 'E'

    MMU $8000, 300
    ORG $8000
middlePage:
    DB $A5
    ASSERT $$middlePage == 300
    MMU $8000, 2559
    ASSERT {b $8000} == 'E'
    MMU $8000, 300
    ASSERT {b $8000} == $A5

    SAVEBIN "element_device.bin", $E000, 8
    SAVEDEV "element_device.raw", 0, 2559 * $2000, 8
    CSPECTMAP "element_device.sym"
    LABELSLIST "element_device.lbl"
    DEVICE NONE
    DEVICE ELEMENT
    ORG $E000
    ASSERT $$ == 2559 && {b $E000} == 'E'

    SLOT 8      ; error
    PAGE 2560   ; error
    PAGE -1     ; error