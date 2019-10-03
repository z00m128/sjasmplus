    ; all of these should fail on i8080

    ;;; generate shift instructions: #DDCBFF00 .. #DDCBFF3F ("ix-1" = FF index byte)
    DEFARRAY instructions rlc, rrc, rl, rr, sla, sra, sli, srl
    DEFARRAY registers <(ix-1),b>, <(ix-1),c>, <(ix-1),d>, <(ix-1),e>, <(ix-1),h>, <(ix-1),l>, <(ix-1)>, <(ix-1),a>

INS_I=0
    DUP 8
REG_I=0
        DUP 8
            instructions[INS_I] registers[REG_I]
REG_I=REG_I+1
        EDUP
INS_I=INS_I+1
    EDUP

    ;;; generate `bit` instructions: #DDCBFF46 .. #DDCBFF7E (two: {#x6, #xE})
REG_BIT=0
    DUP 8
        bit REG_BIT,(ix-1)
REG_BIT=REG_BIT+1
    EDUP

    ;;; generate `res` + `set` instructions: #DDCB1180 .. #DDCB11FF ("ix+17" = 11 index byte)
    DEFARRAY instructions2 res, set
    DEFARRAY registers2 <(ix+17),b>, <(ix+17),c>, <(ix+17),d>, <(ix+17),e>, <(ix+17),h>, <(ix+17),l>, <(ix+17)>, <(ix+17),a>

INS_I=0
    DUP 2
REG_BIT=0
        DUP 8
REG_I=0
            DUP 8
                instructions2[INS_I] REG_BIT,registers2[REG_I]
REG_I=REG_I+1
            EDUP
REG_BIT=REG_BIT+1
        EDUP
INS_I=INS_I+1
    EDUP
