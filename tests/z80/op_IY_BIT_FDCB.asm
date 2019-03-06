    OUTPUT "op_IY_BIT_FDCB.bin"

    ;;; generate shift instructions: #FDCBFF00 .. #FDCBFF3F ("iy-1" = FF index byte)
    LUA ALLPASS
        instructions = { 'rlc', 'rrc', 'rl', 'rr', 'sla', 'sra', 'sli', 'srl' }
        registers = { '(iy-1),b', '(iy-1),c', '(iy-1),d', '(iy-1),e', '(iy-1),h', '(iy-1),l', '(iy-1)', '(iy-1),a' }
        for ii = 1, #instructions do
            for rr = 1, #registers do
                instruction = instructions[ii]..' '..registers[rr]
                _pc(instruction)
            end
        end
    ENDLUA

    ;;; generate `bit` instructions: #FDCBFF46 .. #FDCBFF7E (two: {#x6, #xE})
    LUA ALLPASS
        for bb = 0, 7 do
            instruction = 'bit '..bb..',(iy-1)'
            _pc(instruction)
        end
    ENDLUA

    ;;; generate `res` + `set` instructions: #FDCB1180 .. #FDCB11FF ("iy+17" = 11 index byte)
    LUA ALLPASS
        instructions = { 'res', 'set' }
        registers = { '(iy+17),b', '(iy+17),c', '(iy+17),d', '(iy+17),e', '(iy+17),h', '(iy+17),l', '(iy+17)', '(iy+17),a' }
        for ii = 1, #instructions do
            for bb = 0, 7 do
                for rr = 1, #registers do
                    instruction = instructions[ii]..' '..bb..','..registers[rr]
                    _pc(instruction)
                end
            end
        end
    ENDLUA
