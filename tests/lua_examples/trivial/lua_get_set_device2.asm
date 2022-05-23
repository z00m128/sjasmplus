; test the global-device detection when device is set from lua
    PAGE 2      ; should not cause any error, because global device is ZXSPECTRUM48
    LUA ALLPASS
        sj.set_device("ZXSPECTRUM48",0x7FFF)
    ENDLUA
