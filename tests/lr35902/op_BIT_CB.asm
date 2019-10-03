    OUTPUT "op_BIT_CB.bin"      ; all of these should pass except "sli" (= swap)

    ;;; generate shift instructions: #CB00 .. #CB3F
    DEFARRAY instructions rlc, rrc, rl, rr, sla, sra, sli, srl
    DEFARRAY registers b, c, d, e, h, l, (hl), a

INS_I=0
    DUP 8
REG_I=0
        DUP 8
            instructions[INS_I] registers[REG_I]
REG_I=REG_I+1
        EDUP
INS_I=INS_I+1
    EDUP

    ;;; generate bit-manipulation instructions: #CB40 .. #CBFF
    DEFARRAY instructions2 bit, res, set
INS_I=0
    DUP 3
REG_BIT=0
        DUP 8
REG_I=0
            DUP 8
                instructions2[INS_I] REG_BIT,registers[REG_I]
REG_I=REG_I+1
            EDUP
REG_BIT=REG_BIT+1
        EDUP
INS_I=INS_I+1
    EDUP