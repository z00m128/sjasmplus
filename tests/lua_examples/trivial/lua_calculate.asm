    org     0x1234          ; eol comment belong to ORG
    lua allpass
        assert(0 == _c(nil))
        assert(0 == _c(""))
        assert(123 == _c("123"))
        assert(0x1234 == _c("$"))
        assert(0x1234 == _c("label"))
        assert(-1 == _c("-1"))      -- check the result is signed integer
    endlua
    lua pass1
        assert(0 == _c(nil))
        assert(0 == _c(""))
        assert(123 == _c("123"))
        assert(0x1234 == _c("$"))
        assert(0 == _c("label"))    -- label is not defined yet
    endlua
    lua pass2
        assert(0 == _c(nil))
        assert(0 == _c(""))
        assert(123 == _c("123"))
        assert(0x1234 == _c("$"))
        assert(0x1234 == _c("label"))
    endlua
    lua pass3
        assert(0 == _c(nil))
        assert(0 == _c(""))
        assert(123 == _c("123"))
        assert(0x1234 == _c("$"))
        assert(0x1234 == _c("label"))
    endlua
    lua
        assert(0 == _c(nil))
        assert(0 == _c(""))
        assert(123 == _c("123"))
        assert(0x1234 == _c("$"))
        assert(0x1234 == _c("label"))
    endlua
label:

    ; sjasmplus expression evaluator is strictly 32-bit, following are consequences

    ; Overflow error detected in evaluator (while parsing value)
    lua
        _c("0x1FFFFFFFF")
    endlua
    ; truncated result
    lua
        assert(0x34567800 == _c("0x12345678<<8"))
    endlua
