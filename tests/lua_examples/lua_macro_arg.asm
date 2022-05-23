    ; OBSOLETE, define/macro_arg substitution is added to `_c`/`sj.calc` in v1.14.4
    ; check new test lua_macro_arg2.asm

    ; this test shows possible workaround for:
    ; 1) extracting macro arg through regular DEFINE (to not tamper with current
    ;   "big" label from outside the macro, otherwise one can also set global label)
    ; 2) how to store intermediate values into global labels from inside Lua script
    ;   with _pl creating full asm line with non-main DEFL type of label, so it can
    ;   be redefined over and over with new values (the sj.insert_label does produce
    ;   only regular labels, which can't change value multiple times.
    ; Also macro arguments are substituted inside Lua `_pl()` and `_pc()` (parse line,
    ;   parse code), and inside `_c` (calculate expression)

    MACRO testM arg1?
        ; convert macro-define "arg1?" to global define (makes it visible to Lua)
        DEFINE __testM_arg1_tmp arg1?
        LUA ALLPASS
            x = sj.get_define("__testM_arg1_tmp")
            _pl("!x = "..x)         -- DEFL type label "x" set to value x
            _pc("ld de,arg1?")      -- _pc does the substitution
            sj.add_word(x)          -- parsed value from lua variable
            sj.add_word(_c("x"))    -- _c will at least recognize the inserted label
            z = _c("arg1?")         -- now substitution in `_c` WORKS in v1.14.4

        ENDLUA
.localMacroLabel:
        UNDEFINE __testM_arg1_tmp     ; release the global define
    ENDM

x   = 88
BigLabel1:
    testM 0x1234
.local1:
    DW  x                       ; check that symbol "x" was set by _pl("!x = "..x)
    jr      BigLabel1.local1    ; check "big" label was not modified by _pl("!x = "..x)
x   = 77
BigLabel2:
    testM 0x3456
.local2:
    DW  x
    jr      BigLabel2.local2    ; same checks as above, but second value
