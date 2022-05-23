  LUA ALLPASS
    assert("NONE" == sj.get_device())
    assert("NONE" == sj.get_device(1))    -- extra argument doesn't matter with LuaBridge2.6

    sj.set_device("ZXSPECTRUM48")         -- zx48, default ramtop
    assert("ZXSPECTRUM48" == sj.get_device())

    sj.set_device("ZXSPECTRUM128",0xFEDC) -- zx128, specific ramtop
    assert("ZXSPECTRUM128" == sj.get_device())

    sj.set_device("ZXSPECTRUM128",0xEDCB) -- warning about different ramtop value

    sj.set_device("NONE")
    assert("NONE" == sj.get_device())
  ENDLUA

  DEVICE ZXSPECTRUM48
  ORG 0x1234 : DB 48
  DEVICE ZXSPECTRUM128, 0xEDCB
  ORG 0x1234 : DB 128

  LUA PASS3
    sj.set_device("ZXSPECTRUM48")
    assert(48 == sj.get_byte(0x1234))
    assert("ZXSPECTRUM48" == sj.get_device())

    assert(false == sj.set_device("invalid"))
    assert("NONE" == sj.get_device())   -- invalid id does cause switch to NONE

    sj.set_device("ZXSPECTRUM128",0xFEDC)
    assert(128 == sj.get_byte(0x1234))

    assert(true == sj.set_device()) -- default id is "NONE"
    assert("NONE" == sj.get_device())
  ENDLUA
