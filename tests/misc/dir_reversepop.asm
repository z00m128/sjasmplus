    OUTPUT  "dir_reversepop.bin"
    nop
    push    hl, bc  ; should compile as `push hl` `push bc`
    pop     hl, bc  ; should compile as `pop bc` `pop hl` with --reversepop option
