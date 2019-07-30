    lua pass1
        pass = 0
    endlua

    lua allpass
        pass = pass + 1
        sj.parse_code("DISPLAY \"lua pass: \", /D, "..pass)
        if sj.file_exists("lua_file_exists.asm") then
            sj.parse_line(" DISPLAY \"lua_file_exists.asm does exist.\"")
        ; end
        if not sj.file_exists("bogus.file") then
            sj.error("bogus.file does not exist.")  -- show this one as error for fun
        ; end
    endlua
