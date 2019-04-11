    OUTPUT "checking_macro_args_within_lua.bin"

    ; define Lua functions rather only in PASS1, the Lua context is global across whole
    ; assembling and across all passes, so just single pure function definition is enough.
    LUA PASS1
        function getMacroArgument(argname)
            _pl(" DEFINE _LUA_GET_MACRO_ARGUMENT "..argname)
            local result = sj.get_define("_LUA_GET_MACRO_ARGUMENT")
            _pl(" UNDEFINE _LUA_GET_MACRO_ARGUMENT")
            return result
        end
    ENDLUA

    ; macro using short Lua script, which does call the function above to figure out
    ; the value of someArg0 within the Lua
    MACRO someMacro someArg0
        LUA ALLPASS
            _pc(" db "..getMacroArgument("someArg0"))
        ENDLUA
    ENDM

    ; spawn the macro (should end as `db "ARG0_content"` final machine code.
    someMacro "ARG0_content"
