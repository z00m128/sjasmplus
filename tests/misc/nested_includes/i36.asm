INC_DEPTH=0

    INCLUDE "i36_II.i.asm"
    END


Test to check listing file format, focused on line numbering and include-nesting counter.

This one should produce only single digit line numbers in listing.
There are two more tests: `inc_I.asm` and `inc_II.asm` exercising two and three digits
line counters.