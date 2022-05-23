    DEVICE none

    lua
        -- v1.20.0 added visible warning message
        assert(not sj.set_page(1))
    endlua

    DEVICE zxspectrum128

    lua
        assert(not sj.set_page(233))
        assert(not sj.set_page(-1))
        assert(sj.set_page(6))
    endlua

    ASSERT(7 == $$)     ; slot 0 should be still default page 7
    ORG 0xC000
    ASSERT(6 == $$)     ; default slot 3 should be page 6 set by lua

    lua pass3 ; wrong arguments
        sj.set_page(233, 2) -- not reported since Lua5.4 and LuaBridge 2.6 integration :(
        sj.set_page()
    endlua
