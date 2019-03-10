    DEVICE ZXSPECTRUM48
    org     $8000
    ; 17 bytes block of "default" memory values
    db      "ABCDEFGHIJKLMNOPZ"

    ALIGN   0       ; error
    ALIGN   1,-1    ; error
    ALIGN   1,256   ; error
    ALIGN   3       ; error
    ALIGN   5,10    ; error
    ALIGN   $10000  ; error

    ; re-run over the initial values again with different ALIGN directives
    org     $8000
    db      'a'     ; [8000] = 'a'
    ALIGN   1       ; effective nothing should happen here
    ALIGN   1, '!'  ; and neighter here
    ALIGN   2       ; this should advance to $8002 + preserve memory
    ALIGN   4, 'b'  ; [8002] = [8003] = 'b'
    ALIGN   7, '!'  ; error
    ALIGN   8       ; advance to 8008, preserve memory
    ALIGN   16, 'c' ; [8008..800F] = 'c'
    ALIGN           ; should not make any difference (already at MOD 4 address)

    ; the final result should be "aBbbEFGHccccccccZ"

    SAVEBIN "dir_align.bin", $8000, 17  ; modified area is saved into BIN file
