    OUTPUT "colon_vs_label_issue.bin"
    MACRO worksOK:ld b,c:ld b,d:ld b,e:ld a,(bc):ENDM
    worksOK     ; "ABC\n" output
    MACRO failed:scf:scf:scf:ld a,(bc):ENDM
    failed      ; "777\n" output
    ; did fail in v1.11, the SCF (or any single word instruction) needs
    ; extra space ahead to not eat the colon after as sort of "label" colon
