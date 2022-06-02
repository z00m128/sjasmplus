    LUA pass1
        lua_pass = 1
    ENDLUA

    LUA pass3   ; wrong arguments
        -- sj.exit(27, 2) -- not reported since Lua5.4 and LuaBridge 2.6 integration :(
    ENDLUA

    LUA allpass
        if (3 == lua_pass) then sj.exit(13); end
        ;-- exit precisely in third pass, to exercise certain code path in sjasm.cpp
        lua_pass = lua_pass + 1
    ENDLUA

    ; errorcode argument is optional, missing argument or nil will do `sj.exit(1)` (v1.20.0+)
