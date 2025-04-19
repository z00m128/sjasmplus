; since v1.21.1 sj.pass is available
    LUA pass1
        assert(1 == sj.pass)
    ENDLUA

    LUA pass2
        assert(2 == sj.pass)
    ENDLUA

    LUA pass3
        assert(3 == sj.pass)
    ENDLUA
