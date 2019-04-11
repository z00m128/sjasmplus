    OUTPUT "issue46_LuaInsideMacro.bin"
    MACRO luatest
        LUA
            _pc("ld b,c")   -- 'A'
            _pc("ld b,d")   -- 'B'
            _pc("ld b,e")   -- 'C'
        ENDLUA
    ENDM

    luatest
