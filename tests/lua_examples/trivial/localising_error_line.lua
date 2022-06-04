    -- few extra lines to make the assert line number 20
    --
    --
    --
    --
    --
    --
    --
    --
    --
    --
    --
    --
    -- and one useless local var
    --
    local x = 2

    function f2()
        sj.error("f2 lua:19 invoked from asm:5")       -- OK + "emitted from here" points to LUAEND (FAIL?)
        assert(false, "f2 assert fail -> lua:20 invoked from asm:5")   -- FAIL to asm:20
    end

    -- one error invoked while including

    sj.error("lua:25 pass1 emit from asm:23/24")    -- OK + "emitted from here" OK
