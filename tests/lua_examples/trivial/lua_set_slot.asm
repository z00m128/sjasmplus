    DEVICE none

    lua
        -- warning because no device is set
        assert(not sj.set_slot(1))
    endlua

    DEVICE zxspectrum128

    ORG 0xC000
    ASSERT 0 == $$  ; slot 3 should be at default page 0
    ORG 0x8000
    ASSERT 2 == $$  ; slot 2 should be at default page 2

    lua
        assert(not sj.set_slot(4))
    endlua

    lua
        assert(not sj.set_slot(-1))
    endlua

    lua allpass
        assert(sj.set_slot(2))
    endlua

    PAGE 6
    ASSERT 6 == $$  ; slot 2 should be active by lua script => page 6 there

    ; test the address-based slot selecting
    lua allpass
        assert(sj.set_slot(0xC000))
    endlua

    PAGE 5
    ORG 0xC000
    ASSERT 5 == $$  ; slot 3 should be active by lua script => page 5 there

    lua pass3 ; wrong arguments
        sj.set_slot(1, 2)   -- not reported since Lua5.4 and LuaBridge 2.6 integration :(
        sj.set_slot()
    endlua
