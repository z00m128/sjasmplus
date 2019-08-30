    ; setup Lua "inc_text" functionality
    INCLUDELUA "lua_inctext.lua"

        OUTPUT "lua_inctext.bin"

        ORG     0x8000
        ld      hl,Text1    ; using labels defined from the text file (included below)
        ld      de,Text2
        ld      ix,Text3
        call    Final
        jp      $

        LUA ALLPASS
            -- inc_text(file_name, ">>", 13) -- default values of parameters
            inc_text("lua_inctext/test.txt")            -- test defaults
            inc_text("lua_inctext/test2.txt", "!!", 10) -- test non-default parameters
            inc_text("missing file")                    -- test error handling
        ENDLUA

        OUTEND