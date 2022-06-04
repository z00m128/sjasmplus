    lua allpass
        sj.set_device()
        _pc("ORG $8000")
        sj.add_byte(0)
        _pc("ORG $FFFF")
        sj.add_byte(2)
        sj.add_byte(0xBA)    -- warning about exceeding memory limit
        _pc("ORG $C000")
        sj.add_byte(1)

        sj.set_device("ZXSPECTRUM48", 0x5FFF)
        _pc("ORG $8000")
        sj.add_byte(0)
        _pc("ORG $FFFF")
        sj.add_byte(2)
        sj.add_byte(0xBA)    -- error about exceeding device memory limit
        _pc("ORG $C000")
        sj.add_byte(1)
    endlua
