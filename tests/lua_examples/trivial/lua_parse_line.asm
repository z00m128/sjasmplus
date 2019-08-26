
    org     0x1234          ; eol comment belong to ORG
    lua allpass ; machine code needs to be emitted in *every* pass (and the same one)
        sj.parse_line("allpass_1: rrca")    -- try without EOL comment first
        sj.parse_line("allpass_2: rra      ; with eol comment") -- *with*
        sj.parse_line("allpass_3: cpl")     -- *without*
        _pl("allpass_4: inc bc")
        _pl("allpass_5: inc de      ; with eol comment 2")
        _pl("allpass_6: inc hl")
    endlua
    lua         ; [pass default] == pass3 - this is not good for ASM parsing lines!
        sj.parse_line("pass_default: rlca      ; this will cause problems")
        _pl("pass_default_2: rla      ; same with _pl alias")
    endlua
    lua pass1   ; pass1 this is also insufficient to generate valid machine code
        sj.parse_line("pass1: daa      ; will define label, but machine code will be missing")
        _pl("pass1_2: scf      ; same with _pl alias")
    endlua
