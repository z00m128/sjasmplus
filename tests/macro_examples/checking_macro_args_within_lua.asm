    OUTPUT "checking_macro_args_within_lua.bin"

    ; this was originally showing hack-ish solution how to get macro argument value

    ; since v1.20.0 the sj.get_define is extended to search optionally also in macro
    ; arguments, rendering the original example pointless, this is now as simple as this:

    MACRO someMacro someArg0
        LUA ALLPASS
            _pc("db "..sj.get_define("someArg0", true)) -- "true" to enable search in macro arguments
        ENDLUA
    ENDM

    ; spawn the macro (should end as `db "ARG0_content"` final machine code.
    someMacro "ARG0_content"

;;-------------------------------------------------------------------------------
    ; second example, with usage of LUA inside DUP-EDUP block (based on Issue #27)
    LUA PASS1
        AY8910_CLOCK_FREQUENCY=1000000
        function getAyMidiFrequency(midiNumber)
            return math.floor((AY8910_CLOCK_FREQUENCY/16.0)/(2^((midiNumber-69)/12.0)*440)+0.5)
        end
    ENDLUA

midi_number=21
    dup 108-21+1
    LUA ALLPASS
        _pc('dw ' .. getAyMidiFrequency(sj.get_label("midi_number")))
    ENDLUA
midi_number=midi_number+1
    edup
