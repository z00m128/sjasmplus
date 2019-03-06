    OUTPUT "op_BIT_CB.bin"

    ;;; generate shift instructions: #CB00 .. #CB3F
    LUA ALLPASS
        instructions = { 'rlc', 'rrc', 'rl', 'rr', 'sla', 'sra', 'sli', 'srl' }
        registers = { 'b', 'c', 'd', 'e', 'h', 'l', '(hl)', 'a' }
        for ii = 1, #instructions do
            for rr = 1, #registers do
                instruction = instructions[ii]..' '..registers[rr]
                _pc(instruction)
            end
        end
    ENDLUA

    ;;; generate bit-manipulation instructions: #CB40 .. #CBFF
    LUA ALLPASS
        instructions = { 'bit', 'res', 'set' }
        registers = { 'b', 'c', 'd', 'e', 'h', 'l', '(hl)', 'a' }
        for ii = 1, #instructions do
            for bb = 0, 7 do
                for rr = 1, #registers do
                    instruction = instructions[ii]..' '..bb..','..registers[rr]
                    _pc(instruction)
                end
            end
        end
    ENDLUA
