    ; the __FILE__ and __LINE__ values are raw without quotes, so they are currently
    ; difficult to use with sjasmplus, the Lua script can manipulate them well
    ; but sjasmplus itself would need maybe some string operators... or even more?
    OUTPUT "predefined_base_file.bin"

    DB 0, 1, 2, 3, 255, 254, 253, 252, 10, 10, 10   ; make sure git doesn't treat this as text file
    DB "Main file before INCLUDE:\n"
    LUA ALLPASS
        _pc("DB \"base: " .. sj.get_define("__BASE_FILE__") .. "\\n\"")
        _pc("DB \"file: " .. sj.get_define("__FILE__") .. "\\n\"")
        _pc("DB \"ENDLUA line: " .. sj.get_define("__LINE__") .. "\\n\"")
    ENDLUA

    INCLUDE "predefined_base_file.i.asm"

    DB "Main file after INCLUDE:\n"
    LUA ALLPASS
        _pc("DB \"base: " .. sj.get_define("__BASE_FILE__") .. "\\n\"")
        _pc("DB \"file: " .. sj.get_define("__FILE__") .. "\\n\"")
        _pc("DB \"ENDLUA line: " .. sj.get_define("__LINE__") .. "\\n\"")
    ENDLUA
