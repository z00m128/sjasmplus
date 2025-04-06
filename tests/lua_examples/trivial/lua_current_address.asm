; check write-ability of sj.current_address (works like more limited ORG)
    DEVICE NONE
    LUA ALLPASS
        assert(0 == sj.current_address) -- check read of the value
        sj.current_address = 0x1234     -- check write of the value
        assert(0x1234 == sj.current_address)
        sj.current_address = 0x82345    -- truncated with warning
        assert(0x2345 == sj.current_address)
        sj.current_address = -1         -- truncated with warning
        assert(0xFFFF == sj.current_address)
    ENDLUA
    DEVICE ZXSPECTRUM128
    LUA ALLPASS
        _pl("top: di")
        sj.current_address = 0x4567
        assert(0x4567 == sj.current_address)
        _pl("main: di")
    ENDLUA
    ASSERT($FFFF == top)
    ASSERT($4567 == main)
