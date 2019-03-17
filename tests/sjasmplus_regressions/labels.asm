        device zxspectrum128

        org #8000
        jr label
.label  nop
label   ret

        module mod
label   dw label
.label  dw @label
        dw .label
        endmod
