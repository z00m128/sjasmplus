; test warnings about DISP and ORG inside DISP block

    ORG     $8000
    DISP    $C000

l1:     scf
        DISP    $1234, 4    ; warning about being ignored, because DISP inside DISP
l2:     nop
        ASSERT $C001 == l2  ; not $1234

        ORG     $E002       ; warning: only virtual address being modified inside DISP
l3:     ccf
        ORG     $F003       ; ok ; warning suppressed
l4:     rra

    ENT
    cpl

    DISP    $CCCC           ; leave DISP open to test next pass behaviour (should auto-end)
