; warnings about emitting bytes with wrong LUA block modifier (should be "allpass")

; no warnings variants (correct ones)

    lua allpass
        sj.add_byte(0)
    endlua

    lua allpass
        sj.add_word(0)
    endlua

    lua allpass
        _pc("nop")
    endlua

    lua allpass
        _pl("pl_allpass: nop")
    endlua

; PASS1

    lua pass1
        sj.add_byte(0)
    endlua

    lua pass1
        sj.add_word(0)
    endlua

    lua pass1
        _pc("nop")
    endlua

    lua pass1
        _pl("pl_pass1: nop")
    endlua

; PASS2

    lua pass2
        sj.add_byte(0)
    endlua

    lua pass2
        sj.add_word(0)
    endlua

    lua pass2
        _pc("nop")
    endlua

    lua pass2
        _pl("pl_pass2: nop")
    endlua

; PASS3

    lua pass3
        sj.add_byte(0)
    endlua

    lua pass3
        sj.add_word(0)
    endlua

    lua pass3
        _pc("nop")
    endlua

    lua pass3
        _pl("pl_pass3: nop")
    endlua

; default (PASS3)

    lua
        sj.add_byte(0)
    endlua

    lua
        sj.add_word(0)
    endlua

    lua
        _pc("nop")
    endlua

    lua
        _pl("pl_default: nop")
    endlua
