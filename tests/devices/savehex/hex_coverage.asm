    DEVICE ZXSPECTRUM128
    HEXOUT "hex_coverage.bin"
    ORG $FFFE           ; go beyond 16ki space - .hex output ignores and emits bytes
Code:                   ; continuing in record starting with 0xFFFE address -> broken
    ld  b,c
Start:
    ld  b,d
Data:
    dz  "C"             ; regular device error message
End:
    HEXEND Start

    DEVICE NONE
    HEXOUT "hex_coverage.tap"
    ORG $FFFE           ; go beyond 16ki space - .hex output ignores and emits bytes
Code2:                  ; continuing in record starting with 0xFFFE address -> broken
    ld  b,c
Start2:
    ld  b,d
Data2:
    dz  "C"             ; regular warning message

    ; --longptr will cause this to go through silently, putting first bytes over 0x10000
    ; into the record block at address 0xFFFE and next record has wrap-around 16b address
    ; so this is basically broken (and not guarded by Intel hex functionality, up to the user)
End2:
    HEXEND Start2
