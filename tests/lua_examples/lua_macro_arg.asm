    ;TODO some "get_macro_define" is missing to easily extract macro args in Lua
    ; this test shows possible workaround for:
    ; 1) extracting macro arg through regular DEFINE (to not tamper with current
    ;   "big" label from outside the macro, otherwise one can also set global label)
    ; 2) how to store intermediate values into global labels from inside Lua script
    ;   with sj.insert_label, and it's extra undocumented optional arguments to keep
    ;   that global symbol of "DEFL" type (like "=" in asm source), so it can be
    ;   redefined over and over with new values
    ; Also macro arguments are substituted inside Lua `_pl()` and `_pc()` (parse line,
    ;   parse code), but not inside `_c` (calculate expression)

    MACRO testM arg1?
        ; convert macro-define "arg1?" to global define (makes it visible to Lua)
        DEFINE __testM_arg1_tmp arg1?
        LUA ALLPASS
            x = sj.get_define("__testM_arg1_tmp")
            sj.insert_label("x", x, false, true)   -- isUndefined=false, isDefl=true
            _pc("ld de,arg1?")      -- _pc does the substitution
            sj.add_word(x)          -- parsed value from lua variable
            sj.add_word(_c("x"))    -- _c will at least recognize the inserted label
            z = _c("arg1?")         -- does NOT work. Should it?
        ENDLUA
.localMacroLabel:
        UNDEFINE __testM_arg1_tmp     ; release the global define
    ENDM

x   = 88
BigLabel1:
    testM 0x1234
.local1:
    DW  x                       ; check that symbol "x" was set by sj.insert_label
    jr      BigLabel1.local1    ; check "big" label was not modified by sj.insert_label
x   = 77
BigLabel2:
    testM 0x3456
.local2:
    DW  x
    jr      BigLabel2.local2    ; same checks as above, but second value
