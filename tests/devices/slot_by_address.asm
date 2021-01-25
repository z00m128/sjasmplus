    DEVICE NONE         ; set "none" explicitly, to avoid "global device" feature
    SLOT $4000          ;; warning about non-device mode
    MMU $4000, 1        ;; warning about non-device mode
    DEVICE ZXSPECTRUM128

    ; mark banks content with values for checking results
    MMU 0, 0, 0 : DW '00'
    MMU 0, 1, 0 : DW '11'
    MMU 0, 2, 0 : DW '22'
    MMU 0, 3, 0 : DW '33'
    MMU 0, 4, 0 : DW '44'
    MMU 0, 5, 0 : DW '55'
    MMU 0, 6, 0 : DW '66'
    MMU 0, 7, 0 : DW '77'
    ; remap ZX128 to banks 0:1:2:3
    MMU 0 3, 0
    ASSERT '00' == {$0000} && '11' == {$4000} && '22' == {$8000} && '33' == {$C000}

    ; test SLOT with valid values
    SLOT $0000 : PAGE 4
    SLOT $4000 : PAGE 5
    SLOT $8000 : PAGE 6
    SLOT $C000 : PAGE 7
    ASSERT '44' == {$0000} && '55' == {$4000} && '66' == {$8000} && '77' == {$C000}

    ; test MMU with valid values
    MMU $0000 w, 1
    MMU $4000 w, 2
    MMU $8000 w, 3
    MMU $C000 w, 4
    ASSERT '11' == {$0000} && '22' == {$4000} && '33' == {$8000} && '44' == {$C000}

    MMU $0000 $C000, 2
    ASSERT '22' == {$0000} && '33' == {$4000} && '44' == {$8000} && '55' == {$C000}

    ; test with invalid value (address of start of slot must be exact)
    SLOT $1000
    SLOT 4
    MMU $1000, 0
    MMU 4, 0
