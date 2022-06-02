  MACRO test FOO, BAR
    LUA ALLPASS
      assert("arg1" == sj.get_define("FOO", true))
      assert("abcd" == sj.get_define("FOO", false))
      assert("abcd" == sj.get_define("FOO"))

      assert("arg2" == sj.get_define("BAR", true))
      assert(nil == sj.get_define("BAR", false))
      assert(nil == sj.get_define("BAR"))

      assert("efgh" == sj.get_define("BAZ", true))
      assert("efgh" == sj.get_define("BAZ", false))
      assert("efgh" == sj.get_define("BAZ"))

      assert(nil == sj.get_define("FUZ", true))
      assert(nil == sj.get_define("FUZ", false))
      assert(nil == sj.get_define("FUZ"))
    ENDLUA
  ENDM

  DEFINE FOO abcd
  DEFINE BAZ efgh

  test arg1, arg2

  LUA ALLPASS
    assert("abcd" == sj.get_define("FOO", true))
    assert("abcd" == sj.get_define("FOO", false))
    assert("abcd" == sj.get_define("FOO"))

    assert(nil == sj.get_define("BAR", true))
    assert(nil == sj.get_define("BAR", false))
    assert(nil == sj.get_define("BAR"))

    assert("efgh" == sj.get_define("BAZ", true))
    assert("efgh" == sj.get_define("BAZ", false))
    assert("efgh" == sj.get_define("BAZ"))

    assert(nil == sj.get_define("FUZ", true))
    assert(nil == sj.get_define("FUZ", false))
    assert(nil == sj.get_define("FUZ"))
  ENDLUA
