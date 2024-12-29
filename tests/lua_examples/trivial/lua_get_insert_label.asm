  ; missing arguments errors (stops scripts)
  LUA
    sj.get_label()
  ENDLUA
  LUA
     -- sj.insert_label() -- disabled, the error message is platform+compiler dependent, linux reports #2 arg, macos+bsd #1 arg
  ENDLUA
  LUA
    sj.insert_label("no_address")
  ENDLUA

foo   EQU   0x1234
bay   EQU   bar + 0x1111

  LUA PASS1
    -- regular get_label
    assert(0x1234 == sj.get_label("foo"))

    -- regular insert_label
    assert(0 == sj.get_label("bar"))
    assert(true == sj.insert_label("bar",0x2345))
    assert(0x2345 == sj.get_label("bar"))
    assert(false == sj.insert_label("bar",0x3456))  -- can't modify regular label
    assert(0x2345 == sj.get_label("bar"))

    assert(0x1111 == sj.get_label("bay"))   -- not modified by inserting "bar" yet
    assert(0 == sj.get_label("baz"))        -- not defined yet (not modified by inserting "bar")

    -- invalid args (avoid hard crash)
    assert(-1 == sj.get_label("1_invalid_name"))
    assert(-1 == sj.get_label(nil))
    assert(-1 == sj.get_label(""))
    assert(-1 == sj.get_label(" "))
    assert(-1 == sj.get_label("@"))

    assert(false == sj.insert_label(nil, 0x2345))
    assert(false == sj.insert_label("", 0x2345))
    assert(false == sj.insert_label(" ", 0x2345))
    assert(false == sj.insert_label("@", 0x2345))
    assert(false == sj.insert_label(".", 0x2345))
    assert(false == sj.insert_label("1_invalid_name", 0x2345))
  ENDLUA

  LUA PASS3
    -- regular get_label
    assert(0x1234 == sj.get_label("foo"))

    -- regular insert_label
    assert(0x2345 == sj.get_label("bar"))
    assert(true == sj.insert_label("bar",0x2346)) -- can modify if defining it first time this pass, but will emit warning
    assert(0x2346 == sj.get_label("bar"))
    assert(false == sj.insert_label("bar",0x3456)) -- can't modify regular label
    assert(0x2346 == sj.get_label("bar"))

    assert(0x2345+0x1111 == sj.get_label("bay")) -- defined with older value 0x2345
    assert(0x2345+0x1111 == sj.get_label("baz")) -- defined with older value 0x2345

    -- invalid args (avoid hard crash) - also produce regular errors in PASS3
    assert(-1 == sj.get_label("1_invalid_name"))
    assert(-1 == sj.get_label(nil))
    assert(-1 == sj.get_label(""))
    assert(-1 == sj.get_label(" "))
    assert(-1 == sj.get_label("@"))

    assert(false == sj.insert_label(nil, 0x2345))
    assert(false == sj.insert_label("", 0x2345))
    assert(false == sj.insert_label(" ", 0x2345))
    assert(false == sj.insert_label("@", 0x2345))
    assert(false == sj.insert_label(".", 0x2345))
    assert(false == sj.insert_label("1_invalid_name", 0x2345))
  ENDLUA

baz   EQU   bar + 0x1111

; insert_label should apply current namespace (not just validate against it)

  MODULE plop
    LUA ALLPASS
      assert(sj.insert_label(".local",0x3401))          -- plop._.local
      assert(false == sj.insert_label(".local",0x33))
      assert(sj.insert_label("bar",0x3402))             -- plop.bar
      assert(false == sj.insert_label("bar",0x33))
      assert(sj.insert_label(".local",0x3403))          -- plop.bar.local
      assert(false == sj.insert_label(".local",0x33))
      assert(sj.insert_label("!foo",0x3404))            -- plop.foo (not set as namespace)
      assert(false == sj.insert_label(".local",0x33))   -- plop.bar.local fails 2nd time
      assert(false == sj.insert_label("@foo",0x33))     -- foo fails
      assert(sj.insert_label("@bax",0x3405))            -- bax
    ENDLUA

    MODULE plip
      LUA ALLPASS
        assert(sj.insert_label(".local",0x4501))        -- plop.plip._.local
        assert(false == sj.insert_label(".local",0x33))
        assert(sj.insert_label("bar",0x4502))           -- plop.plip.bar
        assert(false == sj.insert_label("bar",0x33))
        assert(sj.insert_label(".local",0x4503))        -- plop.plip.bar.local
        assert(false == sj.insert_label(".local",0x33))
        assert(sj.insert_label("!foo",0x4504))          -- plop.plip.foo (not set as namespace)
        assert(false == sj.insert_label(".local",0x33)) -- plop.plip.bar.local fails 2nd time
        assert(false == sj.insert_label("@foo",0x33))   -- foo fails
        assert(false == sj.insert_label("@bax",0x33))   -- bax fails
      ENDLUA
    ENDMODULE

  ENDMODULE

  LUA PASS3
    assert(0x3401 == sj.get_label("plop._.local"))
    assert(0x3402 == sj.get_label("plop.bar"))
    assert(0x3403 == sj.get_label("plop.bar.local"))
    assert(0x3404 == sj.get_label("plop.foo"))
    assert(0x3405 == sj.get_label("bax"))
    assert(0x4501 == sj.get_label("plop.plip._.local"))
    assert(0x4502 == sj.get_label("plop.plip.bar"))
    assert(0x4503 == sj.get_label("plop.plip.bar.local"))
    assert(0x4504 == sj.get_label("plop.plip.foo"))
    assert(0x1234 == sj.get_label("foo"))
  ENDLUA
