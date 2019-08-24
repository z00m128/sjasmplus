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

    lua pass3 ; wrong arguments
        sj.warning("[nope!]", 2)
    endlua

    lua pass3
        sj.add_word(sj.error_count)     -- ; should be 0x0008
        sj.add_byte(sj.warning_count)   -- ; should be 0x07
    endlua
