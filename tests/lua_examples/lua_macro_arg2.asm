    ; test the new way of lua `_c`/`sj.calc` function to do the define/macro_arg
    ; substitution before the expression is evaluated, so using macro arguments
    ; inside lua script should be now trivial, no more workaround through DEFINE.

    ; this example has been reworked to conform to updated lua5.4 and only official
    ; documented Lua bindings, the `sj.insert_label` has no more the optional arguments
    ; that said, you can use instead the regular asm syntax and `_pl` binding to create
    ; any kind of special flavour of label (DEFL, EQU, global, local, ...)

    ; The extra options of `sj.insert_label` were promised to stay in v1.x
    ; in the original test code, unless there is serious reason. Upgrade
    ; to lua 5.4 is actually *that* serious reason, sorry.


    MACRO testM arg1?
        LUA ALLPASS
            x = _c("arg1?")     -- get value of evaluated macro argument
                -- if you want the macro argument without evaluation
                -- check "lua_macro_arg.asm" test for DEFINE workaround
            _pl("!x = "..x)         -- DEFL type label "x" set to value x
            _pc("dw arg1?, x, "..x) -- check all three sources of input value
                -- _pc does it's own substitution, the label "x" should be set and lua "x"
            -- test _c a bit more for handling weird things...
            e1 = _c("/* ehm")
            e2 = _c("define arg1? xx")  -- will emit error "Label not found: define" = OK
            e3 = _c("$FF&".._c("arg1?"))
            _pc("db /* e1, e2, e3 */ "..e1..","..e2..","..e3)
        ENDLUA
.localMacroLabel:   ; check which root the macro local label gets (should be per emit)
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
