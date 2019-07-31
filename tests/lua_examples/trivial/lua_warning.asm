    lua
        _pc("OPT reset")
        sj.warning("[pass default] warning emitted from lua")
        _pc("OPT --syntax=w")   ; -- treat warnings as errors
        sj.warning("[pass default] second warning emitted from lua")
    endlua

    lua pass1
        _pc("OPT reset")
        sj.warning("[pass 1] warning emitted from lua")
        _pc("OPT --syntax=w")   ; -- treat warnings as errors
        sj.warning("[pass 1] second warning emitted from lua")
    endlua

    lua pass2
        _pc("OPT reset")
        sj.warning("[pass 2] warning emitted from lua")
        _pc("OPT --syntax=w")   ; -- treat warnings as errors
        sj.warning("[pass 2] second warning emitted from lua")
    endlua

    lua pass3
        _pc("OPT reset")
        sj.warning("[pass 3] warning emitted from lua")
        _pc("OPT --syntax=w")   ; -- treat warnings as errors
        sj.warning("[pass 3] second warning emitted from lua")
    endlua

    lua allpass
        _pc("OPT reset")
        sj.warning("[pass all] warning emitted from lua")
        _pc("OPT --syntax=w")   ; -- treat warnings as errors
        sj.warning("[pass all] second warning emitted from lua")
    endlua
