    print ('"valid subdir variant" Included and executed in pass ' .. pass)
    function inc_ld(reg, val)
        instruction = 'LD '..reg..',('..val..')'
        for i=1,pass do
            print('Generating ins: ' .. instruction)
            _pc(instruction)
        end
    end
