        device zxspectrum128

        org #8000

        MACRO WAVEOUT reg, data
        LD A,reg
        OUT (7EH),A
        LD A,data
        OUT (7FH),A
        ENDM

        WAVEOUT 2,17
