    ; all of these should fail on i8080

    ;;; generate shift instructions: #FDCBFF00 .. #FDCBFF3F ("iy-1" = FF index byte)
    DEFARRAY instructions rlc, rrc, rl, rr, sla, sra, sli, srl
    DEFARRAY registers <(iy-1),b>, <(iy-1),c>, <(iy-1),d>, <(iy-1),e>, <(iy-1),h>, <(iy-1),l>, <(iy-1)>, <(iy-1),a>

INS_I=0
    DUP 8
REG_I=0
        DUP 8
            instructions[INS_I] registers[REG_I]
REG_I=REG_I+1
        EDUP
INS_I=INS_I+1
    EDUP

    ;;; generate `bit` instructions: #FDCBFF46 .. #FDCBFF7E (two: {#x6, #xE})
REG_BIT=0
    DUP 8
        bit REG_BIT,(iy-1)
REG_BIT=REG_BIT+1
    EDUP

    ;;; generate `res` + `set` instructions: #FDCB1180 .. #FDCB11FF ("iy+17" = 11 index byte)
    DEFARRAY instructions2 res, set
    DEFARRAY registers2 <(iy+17),b>, <(iy+17),c>, <(iy+17),d>, <(iy+17),e>, <(iy+17),h>, <(iy+17),l>, <(iy+17)>, <(iy+17),a>

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
