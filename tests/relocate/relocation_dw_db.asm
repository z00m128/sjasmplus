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
    db      high label1     ; relunstable-ok ; supressed warning
    ; correct + no relocation data
    dw      label2-label1
    db      label2-label1

label1:
    ld      hl,0+table
    ld      (hl),low table  ; warn about unstable
    ld      (hl),low table  ; relunstable-ok ; suppressed warning
label2:
    ld      de,table+4
    ld      (label1+1),de

    ; these should warn about unstable result, but only once
    db      12, low label1, 23, high label1, 34, label1, 56

    RELOCATE_END

    RELOCATE_TABLE
