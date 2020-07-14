    ORG $1000

    RELOCATE_START

    dw      relocate_count
    dw      relocate_size

table:
    dw      label1          ; to be relocated
    dw      label2          ; to be relocated
    dw      $1111, label1, $2222, label2    ; single line having multiple values
    ; warn about unstable expression
    db      high label1
    db      high label1     ; ok ; supressed warning
    ; correct + no relocation data
    dw      label2-label1
    db      label2-label1

label1:
    ld      hl,0+table
    ld      (hl),low table  ; warn about unstable
    ld      (hl),low table  ; ok ; suppressed warning
label2:
    ld      de,table+4
    ld      (label1+1),de

    RELOCATE_END

    RELOCATE_TABLE
