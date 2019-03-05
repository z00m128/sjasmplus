    function inc_ld_system(reg, val)
        instruction = 'LDINVALID '..reg..','..val..' ; overloaded funcion (system-invalid variant)'
        _pc(instruction)
    end
