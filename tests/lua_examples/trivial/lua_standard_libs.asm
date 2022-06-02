;
; check if standard Lua libraries are loaded
; see Lua 5.4 manual for full details: https://www.lua.org/manual/5.4/manual.html#6
;
    LUA
        -- base lib
        assert(true)
        assert(2 == tonumber("10", 2))
        assert(43794 == tonumber("ab12", 16))
        assert("1234" == tostring(1234))
        assert("Lua 5.4" == _VERSION)
        assert("nil" == type(nil))
        -- string manipulation
        assert(0x42 == string.byte("ABC", 2))
        assert("ABC" == string.char(0x41, 0x42, 0x43))
        assert("ab12" == string.format('%x', 43794))
        -- math
        assert(math.abs(300 * 0.07 - 21.0) ~= 0)        -- trollface
        assert(math.abs(300 * 0.07 - 21.0) < 1e-14)     -- lua doesn't have epsilon-equal out of box :/
        assert(128 == 2^7)  -- math.pow is replaced by "^" operator in recent Lua versions
        assert("integer" == math.type(1234))
        assert("float" == math.type(1234.0))
        -- and others... see the documentation
    ENDLUA

;
; Third-party embedded library(ies) from old sjasmplus versions (if they ever did work?)
;

; hex: hex.to_hex(i), hex.to_dec(h)
; - removed, this should be easy to replace with standard lib, write your own wrappers if needed
    LUA
        assert(43794 == tonumber("ab12", 16))
        assert(43794 == tonumber("0xab12"))
        assert("ab12" == string.format('%x', 43794))
        assert("0xab12" == string.format('0x%x', 43794))
    ENDLUA

; bitwise operators: bit.bxor(a, b) (bnot,band,bor,bxor,brshift,blshift,bxor2,blogic_rshift,tobits,tonumb)
; - removed, these are part of Lua now (since Lua 5.3)
    LUA
        assert(-1 == ~0)
        assert(0xA0C0 == 0xABCD & 0xF0F0)
        assert(0xABCD == 0xA0C1 | 0xAB0C)
        assert(0xA0CC == 0xABCD ~ 0x0B01)
        assert(0xAB00 == 0xAB << 8)
        assert(0xAB == 0xAB00 >> 8)
    ENDLUA

; lpack.c: string.pack, string.unpack
; - removed, part of standard Lua string lib
    LUA
        assert("ABCD" == string.pack("bbbb", 0x41, 0x42, 0x43, 0x44))
        assert(0x4241, 0x4142, 5 == string.unpack("<H>H", "ABAB"))
    ENDLUA
