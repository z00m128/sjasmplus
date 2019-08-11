    LUA pass1
        lua_pass = 1
    ENDLUA

    LUA pass3   ; wrong arguments
        sj.exit(27, 2)
    ENDLUA

    LUA allpass
        if (3 == lua_pass) then sj.exit(13); end
        ;-- exit precisely in third pass, to exercise certain code path in sjasm.cpp
        lua_pass = lua_pass + 1
    ENDLUA
