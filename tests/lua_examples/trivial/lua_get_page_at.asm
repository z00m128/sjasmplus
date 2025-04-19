; since v1.21.1 sj.get_page_at is available
    DEVICE none

    lua
        -- check warning about device mode needed
        assert(-1 == sj.get_page_at())
    endlua

    DEVICE zxspectrum128

    lua
        assert(-1 == sj.get_page_at(-1))
        assert(-1 == sj.get_page_at(0x10000))
        assert(7 == sj.get_page_at(0))
        assert(5 == sj.get_page_at(0x4000))
        assert(2 == sj.get_page_at(0x8000))
        assert(0 == sj.get_page_at(0xC000))
        -- test current address as default argument
        assert(7 == sj.get_page_at())
        sj.current_address = 0x8000
        assert(2 == sj.get_page_at())
    endlua
