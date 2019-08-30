        ADD A,E
        JR NC,1F
        INC D
1       LD E,A
2       LD B,4
        LD A,(DE)
        OUT (152),A
        DJNZ 2B

        MACRO zing
            DUP 2
                JR 1F
1               DJNZ    1B
            EDUP
        ENDM

        .4 zing
