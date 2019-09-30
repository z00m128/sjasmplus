    OUTPUT "op_80_BF.bin"

    ;;; generate all 80..BF instructions
    DEFARRAY instructions add, adc, sub, sbc, and, xor, or, cp
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
