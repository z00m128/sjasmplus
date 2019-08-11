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
            ldir
            ldir
            ORG     0       ; does reset the DISP part only, not real address
            ORG     0xFFFF
            ldir            ; (again) warning about memory limit
            ldir            ; no warning (not doubling)
            ENDT

        ; physical under DISP
            ORG     0xFFFF
            DISP    0x2000
            ldir
            ldir
            ORG     0x3000  ; does NOT reset physical one, only DISP one
            ldir
            ldir
            ENDT
        ; here the physical gets warned second time because of DISP end
        ; it's sort of bug, or unplanned feature, but actually makes sense

        ; physical AND disp together
            ORG     0xFFFF
            DISP    0xFFFF
            ldir            ; will get TWO warnings (DISP + ORG)
            ldir
            ENDT
        ; again physical gets last warning here again due to DISP end

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Block-emit code coverage
            ORG     0xFFF0
            block   100,0xAA
            nop             ; classic
            ORG     0
            ORG     0xFFF0
            block   100,0xBB
            nop             ; again

        ; DISP-only
            ORG     0x1000
            DISP    0xFFF0
            block   100,0xCC
            nop
            ORG     0       ; does reset the DISP part only, not real address
            ORG     0xFFF0
            block   100,0xDD
            nop
            ENDT

        ; physical under DISP
            ORG     0xFFF0
            DISP    0x2000
            block   100,0xEE
            nop
            ORG     0x3000  ; does NOT reset physical one, only DISP one
            block   100,0xFF
            nop
            ENDT
        ; here the physical gets warned second time because of DISP end
        ; it's sort of bug, or unplanned feature, but actually makes sense

        ; physical AND disp together
            ORG     0xFFF0
            DISP    0xFFF0
            block   100,0x77
            nop
            ENDT
        ; again physical gets last warning here again due to DISP end
