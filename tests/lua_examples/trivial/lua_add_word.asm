    lua allpass
        sj.set_device()
        _pc("ORG $8000")
        sj.add_word(0x0100)
        _pc("ORG $FFFF")
        sj.add_word(0xD0BA) -- warning about exceeding memory limit
        _pc("ORG $C000")
        sj.add_word(0x0302)

        sj.set_device("ZXSPECTRUM48", 0x5FFF)
        _pc("ORG $8000")
        sj.add_word(0x0100)
        _pc("ORG $FFFF")
        sj.add_word(0xD0BA) -- error about exceeding device memory limit
        _pc("ORG $C000")
        sj.add_word(0x0302)
    endlua
