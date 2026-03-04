; strings can be concatenated by two-dot operator (like in Lua)
    DEFINE KEYWORD_BIN 'b'.."in"

    ; filename concatenated from multiple parts:
    INCBIN "two_dot_strings" .. '.' .. "asm" : ALIGN $2000
    OUTPUT "two_dot_strings" .. '.' .. KEYWORD_BIN

    ; for DB comma can be used in this trivial case, but operator should work too:
    DB  "string" .. ' ' .. "concatenation", 0, '"' .. KEYWORD_BIN .. '"'
    DB "ABC"C .. "Z"Z           ; suffix strings support
    DP "Pascal" .. "Str"        ; verify pascal string length

    ; not sure about this one, if it should be even supported
    ld  hl,"h" .. "l"

    BLOCK 8, "B" .. "lock"Z

    DISPLAY "DISPLAY" .. '..' .. "concatenate"

    STRUCT STRUCT_TEXT
txt     TEXT 8, { "T" .. "ext"Z }
    ENDS
txt1    STRUCT_TEXT
txt2    STRUCT_TEXT { {"some" .. "text"} }

    ; syntax variations (condensed whitespace)
    DB  "string"..' '.."concatenation", 0, '"'.. KEYWORD_BIN ..'"'
    DB "ABC"C.."Z"Z
    ld  hl,"h".."l"
    BLOCK 8, "B".."lock"Z

    ; errors: missing string literal to concatenate
    DB "string" ..
    DB "string" ..    ; space only
    DB "string" .. 0xEE

    DB "empty second arg with C" .. ""C     ; error can't patch empty string

    END
    ; why ".." support in general way, including DB (although file names are crucial):
    ; - in the future there is possibility of adding "strlen" operator using Lua syntax:
    LUA PASS3
        print (#"hello")          -- 5
        print (#"he" .. "llo")    -- 2llo
        print (#("he" .. "llo"))  -- 5
    ENDLUA
