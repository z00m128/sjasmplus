  DEFINE FOO abcd

  IFDEF BAR : ASSERT 0 : ENDIF

  LUA ALLPASS
    assert("abcd" == sj.get_define("FOO"))

    assert(nil == sj.get_define("BAR"))
    assert(true == sj.insert_define("BAR","hello"))
    assert("hello" == sj.get_define("BAR"))
    assert(false == sj.insert_define("BAR","world"))
    assert("world" == sj.get_define("BAR"))

    assert(true == sj.insert_define("ZAR"))
    assert("" == sj.get_define("ZAR"))

    -- invalid args tests (avoiding hard crash)
    assert(false == sj.insert_define(nil))
    assert(nil == sj.get_define(nil))

    assert(false == sj.insert_define(""))
    assert(nil == sj.get_define(""))

    assert(false == sj.insert_define("@"))
    assert(nil == sj.get_define("@"))

    -- check "id" validation (only enough to avoid invalid state in insert, not validating get_define)
    assert(false == sj.insert_define(" "))
    assert(nil == sj.get_define(" "))

    assert(true == sj.insert_define(" FAR ", " ! "))
    assert(" ! " == sj.get_define("FAR"))
    assert(nil == sj.get_define(" FAR "))
  ENDLUA

  IFNDEF BAR : ASSERT 0 : ENDIF
