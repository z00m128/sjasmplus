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
