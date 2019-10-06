    OUTPUT "op_40_7F.bin"

    ;;; generate all 40..7F instructions (all common `ld xx,yy` variants + halt)
    DEFARRAY registers b, c, d, e, h, l, (hl), a
R1=0
    DUP 8
R2=0
        DUP 8
            IF R1==6 && R2==6
                halt
            ELSE
                ld  registers[R1],registers[R2]
            ENDIF
R2=R2+1
        EDUP
R1=R1+1
    EDUP
