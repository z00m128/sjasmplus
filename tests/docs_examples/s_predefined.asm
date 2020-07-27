    DB __COUNTER__   ; DB 0
    LUA ALLPASS
        sj.insert_label("label_" .. sj.get_define("__COUNTER__"), sj.current_address)
                -- creates "label_1" at "$" (0x0001)
        sj.insert_label("label_" .. sj.get_define("__COUNTER__"), _c("$+10"))
                -- creates "label_2" at "$+10" (0x000B)
    ENDLUA
label__COUNTER__: ; does *NOT* substitute in current sjasmplus, sorry
    DB __COUNTER__   ; DB 3

    ; also macro arguments substitution can be used
    MACRO createLabelWithSuffix label?, suffix?
label?_suffix? ; define global label
    ENDM
    createLabelWithSuffix label, __COUNTER__    ; label_4
    createLabelWithSuffix label, __COUNTER__    ; label_5
