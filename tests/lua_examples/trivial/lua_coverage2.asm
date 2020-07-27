; force non-empty internal sline/sline2 arrays during `_c()` evaluation
    DEFINE  qwe xyz
    DEFINE  xyz abc
    DEFINE  abc
    LUA ALLPASS
        sj.add_byte(_c("1+2"))
    ENDLUA qwe  ; either sline or sline2 should be non-empty from substitution
    LUA ALLPASS
        sj.add_byte(_c("2+3"))
    ENDLUA xyz  ; either sline or sline2 should be non-empty from substitution
    ; the above trick didn't help, so one more try
    LUA ALLPASS
        _pc("nop qwe")
        sj.add_byte(_c("3+4"))
    ENDLUA
    LUA ALLPASS
        _pc("nop xyz")
        sj.add_byte(_c("5+6"))
    ENDLUA
