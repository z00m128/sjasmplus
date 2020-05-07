        ; common case, reset, second one
            ORG     0xFFFF
            ldir            ; warning about memory limit
            ldir            ; no warning (not doubling)
            ORG     0       ; reset warnings state
            ORG     0xFFFF
            ldir            ; (again) warning about memory limit
            ldir            ; no warning (not doubling)

        ; DISP-only
            ORG     0x1000
            DISP    0xFFFF
            ldir            ; warning about DISP memory limit
            ldir
            ORG     0       ; ok ; does reset the DISP part only, not real address
            ORG     0xFFFF  ; ok
            ldir            ; (again) warning about DISP memory limit
            ldir            ; no warning (not doubling)
            ENDT

        ; physical under DISP
            ORG     0xFFFF
            DISP    0x2000
            ldir            ; warning about memory limit
            ldir
            ORG     0x3000  ; ok ; does NOT reset physical one, only DISP one
            ldir
            ldir
            ENDT

        ; physical AND disp together
            ORG     0xFFFF
            DISP    0xFFFF
            ldir            ; will get TWO warnings (DISP + ORG)
            ldir
            ENDT

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Block-emit code coverage
            ORG     0xFFF0
            block   100,0xAA    ; warning about memory limit
            ORG     0
            ORG     0xFFF0
            block   100,0xBB    ; again

        ; DISP-only
            ORG     0x1000
            DISP    0xFFF0
            block   100,0xCC    ; warning about DISP memory limit
            ORG     0       ; ok ; does reset the DISP part only, not real address
            ORG     0xFFF0  ; ok
            block   100,0xDD    ; again
            ENDT

        ; physical under DISP
            ORG     0xFFF0
            DISP    0x2000
            block   100,0xEE    ; warning about memory limit
            ORG     0x3000  ; ok ; does NOT reset physical one, only DISP one
            block   100,0xFF
            ENDT

        ; physical AND disp together
            ORG     0xFFF0
            DISP    0xFFF0
            block   100,0x77    ; will get TWO warnings (DISP + ORG)
            ENDT
