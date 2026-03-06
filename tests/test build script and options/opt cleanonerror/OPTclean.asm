; verify the OPT can be also used for --cleanonerror
; this test does also verify the diagnostic output when --msg=all
        DEVICE ZXSPECTRUM48, $FEFF
        ORG $FF00
        di
        halt
        SAVEBIN "OPTclean.bin", $FF00, 2

        OPT --cleanonerror

; final syntax error to make the build failure
        ASSERT 0, "binaries should be cleaned"
