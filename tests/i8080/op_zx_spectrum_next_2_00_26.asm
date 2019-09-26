    ; all of these should fail on i8080

    swapnib                         ; #ED23
    mirror                          ; #ED24
    test    $03                     ; #ED2703
    bsla    de,b                    ; #ED28
    bsra    de,b                    ; #ED29
    bsrl    de,b                    ; #ED2A
    bsrf    de,b                    ; #ED2B
    brlc    de,b                    ; #ED2C
    mul     d,e                     ; #ED30
    add     hl,a                    ; #ED31
    add     de,a                    ; #ED32
    add     bc,a                    ; #ED33
    add     hl,$102                 ; #ED340201
    add     de,$102                 ; #ED350201
    add     bc,$102                 ; #ED360201
    push    $102                    ; #ED8A0102
    outinb                          ; #ED90
    nextreg $04,$05                 ; #ED910405
    nextreg $03,a                   ; #ED9203
    pixeldn                         ; #ED93
    pixelad                         ; #ED94
    setae                           ; #ED95
    jp      (c)                     ; #ED98
    ldix                            ; #EDA4
    ldws                            ; #EDA5
    lddx                            ; #EDAC
    ldirx                           ; #EDB4
    ldpirx                          ; #EDB7
    lddrx                           ; #EDBC
