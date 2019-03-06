    OUTPUT "op_IX_BIT_DDCB.bin"

    ;;; generate shift instructions: #DDCBFF00 .. #DDCBFF3F ("ix-1" = FF index byte)
    LUA ALLPASS
        instructions = { 'rlc', 'rrc', 'rl', 'rr', 'sla', 'sra', 'sli', 'srl' }
        registers = { '(ix-1),b', '(ix-1),c', '(ix-1),d', '(ix-1),e', '(ix-1),h', '(ix-1),l', '(ix-1)', '(ix-1),a' }
        for ii = 1, #instructions do
            for rr = 1, #registers do
                instruction = instructions[ii]..' '..registers[rr]
                _pc(instruction)
            end
        end
    ENDLUA

    ;;; generate `bit` instructions: #DDCBFF46 .. #DDCBFF7E (two: {#x6, #xE})
    LUA ALLPASS
        for bb = 0, 7 do
            instruction = 'bit '..bb..',(ix-1)'
            _pc(instruction)
        end
    ENDLUA

    ;;; generate `res` + `set` instructions: #DDCB1180 .. #DDCB11FF ("ix+17" = 11 index byte)
    LUA ALLPASS
        instructions = { 'res', 'set' }
        registers = { '(ix+17),b', '(ix+17),c', '(ix+17),d', '(ix+17),e', '(ix+17),h', '(ix+17),l', '(ix+17)', '(ix+17),a' }
        for ii = 1, #instructions do
            for bb = 0, 7 do
                for rr = 1, #registers do
                    instruction = instructions[ii]..' '..bb..','..registers[rr]
                    _pc(instruction)
                end
            end
        end
    ENDLUA
