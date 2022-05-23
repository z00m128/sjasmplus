; force non-empty internal sline/sline2 arrays during `_c()` evaluation
    DEFINE  qwe xyz
    DEFINE  xyz abc
    DEFINE  abc @
    LUA ALLPASS
        sj.add_byte(_c("1+2"))
    ENDLUA qwe  ; both sline or sline2 will contain "@" from substitution

    LUA PASS3
        assert(false == zx.trdimage_create())
        assert(false == zx.trdimage_add_file("1.trd",nil,0x1234,1))
        assert(false == zx.save_snapshot_sna(nil,0x8000))
        zx.save_snapshot_sna("1.sna")   -- bad argument #2, exits this script
    ENDLUA
