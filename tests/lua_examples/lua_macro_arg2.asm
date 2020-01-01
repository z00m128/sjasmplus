    ; test the new way of lua `_c`/`sj.calc` function to do the define/macro_arg
    ; substitution before the expression is evaluated, so using macro arguments
    ; inside lua script should be now trivial, no more workaround through DEFINE.

    ; this still shows extra options of `sj.insert_label`, which are not shown in
    ; official documentation. I'm not sure if these will stay for v2.x, so I'm
    ; not adding them to docs, but you can learn about any hidden optional arguments
    ; in sjasm/lua_sjasm.cpp file, tracking down the particular lua stub, and checking
    ; how many arguments and types are parsed, and how they are used in the call
    ; of internal sjasm function.
    ; These are to stay in v1.x forever like this, unless there will be really serious
    ; reason to modify them. For v2.x the main goal is to mostly keep them and make
    ; them official, but som pruning/reorganization may happen, plus newer Lua version..

    MACRO testM arg1?
        LUA ALLPASS
            x = _c("arg1?")     -- get value of evaluated macro argument
                -- if you want the macro argument without evaluation
                -- check "lua_macro_arg.asm" test for DEFINE workaround
            sj.insert_label("x", x, false, true)   -- isUndefined=false, isDefl=true
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
    DW  x                       ; check that symbol "x" was set by sj.insert_label
    jr      BigLabel1.local1    ; check "big" label was not modified by sj.insert_label
x   = 77
BigLabel2:
    testM 0x3456
.local2:
    DW  x
    jr      BigLabel2.local2    ; same checks as above, but second value
