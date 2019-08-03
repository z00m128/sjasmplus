    DEVICE ZXSPECTRUM48
    LUA
        sj.get_word(0)
        sj.get_word(0xFFFF)
        sj.get_byte(0x2000)
        sj.get_byte(0x20000)
    ENDLUA

    EMPTYTAP "sjio_coverage2_ignore.tap"
    TAPOUT "sjio_coverage2_ignore.tap"
        DS  0x8000,1
        DS  0x8000,2
    TAPEND

    MACRO   MacroWithoutENDM
