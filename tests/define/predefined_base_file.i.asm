    IF 1 == __INCLUDE_LEVEL__

        DB "Before second INCLUDE:\n"
        LUA ALLPASS
            _pc("DB \"base: " .. sj.get_define("__BASE_FILE__") .. "\\n\"")
            _pc("DB \"file: " .. sj.get_define("__FILE__") .. "\\n\"")
            _pc("DB \"ENDLUA line: " .. sj.get_define("__LINE__") .. "\\n\"")
        ENDLUA

        INCLUDE "predefined_base_file.i.asm"

        DB "After second INCLUDE:\n"
        LUA ALLPASS
            _pc("DB \"base: " .. sj.get_define("__BASE_FILE__") .. "\\n\"")
            _pc("DB \"file: " .. sj.get_define("__FILE__") .. "\\n\"")
            _pc("DB \"ENDLUA line: " .. sj.get_define("__LINE__") .. "\\n\"")
        ENDLUA

    ELSE

        DB "Inside second INCLUDE:\n"
        LUA ALLPASS
            _pc("DB \"base: " .. sj.get_define("__BASE_FILE__") .. "\\n\"")
            _pc("DB \"file: " .. sj.get_define("__FILE__") .. "\\n\"")
            _pc("DB \"ENDLUA line: " .. sj.get_define("__LINE__") .. "\\n\"")
        ENDLUA

    ENDIF
