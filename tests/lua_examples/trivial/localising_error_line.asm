    LUA PASS3
        f1()
    ENDLUA
    LUA PASS3
        f2()
    ENDLUA
    LUA PASS1
        -- few extra lines to make the assert line number 15
        -- and one useless local var
        --
        local x = 1

        function f1()
            sj.error("f1 asm:14 invoked from asm:2")       -- reports invokation, but at least correctly placed (asm:2) OK
            assert(false, "f1 assert fail -> asm:15 invoked from asm:2")   -- FAIL asm:9
        end

        -- one error invoked during pass1

        sj.error("asm:20 pass1")    -- OK
    ENDLUA

    INCLUDELUA "./localising_error_line.lua"
    INCLUDELUA "localising_error_line.lua"
