    function inc_ld_system(reg, val)
        instruction = 'LD '..reg..',('..val..') ; overloaded funcion (system-valid variant)'
        _pc(instruction)
    end
