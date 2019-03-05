    -- LUA includes are included only in PASS1, so they can't basically emit code directly
    -- but they can for example define functions, which will be used to emit code in asm.
    function inc_ld_local(reg, val)
        instruction = 'LD '..reg..','..val..' ; function only in local include'
        -- will emit 1, 2 and 3 instructions per "pass", to make assembling fail.
        for i=1,pass do _pc(instruction) end
    end

    function inc_ld_system(reg, val)
        instruction = 'LD '..reg..','..val..' ; overloaded funcion (local variant)'
        _pc(instruction)
    end
