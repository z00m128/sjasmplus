    DEVICE none

    lua
        -- warning because no device is set
        assert(not sj.set_slot(1))
    endlua

    DEVICE zxspectrum128

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

    lua pass3 ; wrong arguments
        sj.set_slot(1, 2)
    endlua
