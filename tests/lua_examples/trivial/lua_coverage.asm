; various error states, etc... (not a good fit elsewhere)
    ENDLUA

    LUA neverpass
    ENDLUA

    INCLUDELUA neverfile.lua
    INCLUDELUA lua_coverage.asm     ; file exists, but errors out

    LUA pass3
        % $ & ?
    ENDLUA

    LUA pass3   ; lua errors in calling known functions
        sj.get_define("define", 2)  -- not an error after lua5.4 upgrade, extra arguments are silent
    ENDLUA

    LUA pass3
        sj.insert_define("define", 2, 3)  -- not an error after lua5.4 upgrade, extra arguments are silent
    ENDLUA

    LUA         ; check read-only property of the directly mapped values
        sj.current_address = 1
    ENDLUA
    LUA
        sj.error_count = 2
    ENDLUA
    LUA
        sj.warning_count = 3
    ENDLUA


    LUA pass3
        someErrorInLua(1, 2, 3)
