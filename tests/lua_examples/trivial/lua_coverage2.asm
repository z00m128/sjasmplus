; force non-empty internal sline/sline2 arrays during `_c()` evaluation
    DEFINE  qwe xyz
    DEFINE  xyz abc
    DEFINE  abc @
    LUA ALLPASS
        sj.add_byte(_c("1+2"))
    ENDLUA qwe  ; both sline or sline2 will contain "@" from substitution
