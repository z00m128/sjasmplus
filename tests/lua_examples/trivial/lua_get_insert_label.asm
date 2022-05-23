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
