; warnings about emitting bytes with wrong LUA block modifier (should be "allpass")
; this test does test only the suppression mechanics
; In this special case of lua-byte-emit warning, the user can put the suppression mark
; both at the beginning and at the end of the lua->endlua block, so testing both here:

;; verify the warnings still work (just quick test)
    lua pass1
        sj.add_byte(1)
    endlua

    lua pass2
        sj.add_byte(2)
    endlua

    lua pass3
        sj.add_byte(3)
    endlua

    lua
        sj.add_byte(4)
    endlua

;; test suppression at beginning of block

    lua pass1   ; luamc-ok - warning should be suppressed (even here at beginning of block)
        sj.warning("but lua warning should work", 11)
        sj.add_byte(11)
    endlua

    lua pass2   ; luamc-ok - warning should be suppressed (even here at beginning of block)
        sj.warning("but lua warning should work", 12)
        sj.add_byte(12)
    endlua

    lua pass3   ; luamc-ok - warning should be suppressed (even here at beginning of block)
        sj.warning("but lua warning should work", 13)
        sj.add_byte(13)
    endlua

    lua         ; luamc-ok - warning should be suppressed (even here at beginning of block)
        sj.warning("but lua warning should work", 14)
        sj.add_byte(14)
    endlua

;; test suppression at end of block

    lua pass1
        sj.warning("but lua warning should work", 21)
        sj.add_byte(21)
    endlua      ; luamc-ok

    lua pass2
        sj.warning("but lua warning should work", 22)
        sj.add_byte(22)
    endlua      ; luamc-ok

    lua pass3
        sj.warning("but lua warning should work", 23)
        sj.add_byte(23)
    endlua      ; luamc-ok

    lua
        sj.warning("but lua warning should work", 24)
        sj.add_byte(24)
    endlua      ; luamc-ok
