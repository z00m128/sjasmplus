    DB  __COUNTER__

TestLabel__COUNTER__:
    ; ^^ does NOT work, because "_" at beginning of __COUNTER__
    ; prevents sub-word substitution = TODO for sjasmplus v2.x

    LUA ALLPASS     ; as usually, lua for the rescue
        sj.insert_label("lua_label_" .. sj.get_define("__COUNTER__"), sj.current_address)
        sj.add_byte(sj.get_define("__COUNTER__"))
        sj.insert_label("lua_label_" .. sj.get_define("__COUNTER__"), sj.current_address)
        sj.add_byte(sj.get_define("__COUNTER__"))
        sj.insert_label("lua_label_" .. sj.get_define("__COUNTER__"), sj.current_address)
        sj.add_byte(sj.get_define("__COUNTER__"))
    ENDLUA

    DB  __COUNTER__
