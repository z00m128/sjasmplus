    DEVICE ZXSPECTRUM48
    ORG 0x4443
test:   DEFW 0x4241
    OUTPUT "lua_get_word.bin"
    LUA
        _pc("dw "..sj.get_word(_c("test"))..", ".._c("test"))
        _pc("dw "..sj.get_word(0x4443)..", "..0x4443)
    ENDLUA

    LUA
        x = _c("test + ~ ")    -- invalid syntax for expression evaluation, returns 0
        _pc("db 'e'+"..x)
    ENDLUA

    LUA pass3 ; wrong arguments
        sj.get_word(0x1234, 2)
    ENDLUA
