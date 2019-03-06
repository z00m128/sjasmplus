    OUTPUT "op_80_BF.bin"

    ;;; generate all 80..BF instructions
    LUA ALLPASS
        instructions = { 'add', 'adc', 'sub', 'sbc', 'and', 'xor', 'or', 'cp' }
        registers = { 'b', 'c', 'd', 'e', 'h', 'l', '(hl)', 'a' }
        for ii = 1, #instructions do
            for rr = 1, #registers do
                instruction = instructions[ii]..' '..registers[rr]
                _pc(instruction)
            end
        end
    ENDLUA
