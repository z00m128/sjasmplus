    org     0x1234          ; eol comment belong to ORG
    lua allpass ; machine code needs to be emitted in *every* pass (and the same one)
        sj.parse_code("")    -- try without EOL comment first
        sj.parse_code(nil)    -- try without EOL comment first
        sj.parse_code("rrca")    -- try without EOL comment first
        sj.parse_code("rra      ; with eol comment") -- *with*
        sj.parse_code("cpl")     -- *without*
        _pc("inc bc")
        _pc("inc de      ; with eol comment 2")
        _pc("inc hl")
        -- errors
        sj.parse_code("label:")
        _pc("label:")
        sj.parse_code("unknown")
        _pc("unknown")
    endlua
    lua         ; [pass default] == pass3 - this is not good for ASM parsing lines!
        sj.parse_code("")    -- try without EOL comment first
        sj.parse_code(nil)    -- try without EOL comment first
        sj.parse_code("rrca")    -- try without EOL comment first
        sj.parse_code("rra      ; with eol comment") -- *with*
        sj.parse_code("cpl")     -- *without*
        _pc("inc bc")
        _pc("inc de      ; with eol comment 2")
        _pc("inc hl")
        -- errors
        sj.parse_code("label:")
        _pc("label:")
        sj.parse_code("unknown")
        _pc("unknown")
    endlua
    lua pass1   ; pass1 this is also insufficient to generate valid machine code
        sj.parse_code("")    -- try without EOL comment first
        sj.parse_code(nil)    -- try without EOL comment first
        sj.parse_code("rrca")    -- try without EOL comment first
        sj.parse_code("rra      ; with eol comment") -- *with*
        sj.parse_code("cpl")     -- *without*
        _pc("inc bc")
        _pc("inc de      ; with eol comment 2")
        _pc("inc hl")
        -- errors (but silent, because they are PASS3 type)
        sj.parse_code("label:")
        _pc("label:")
        sj.parse_code("unknown")
        _pc("unknown")
    endlua
