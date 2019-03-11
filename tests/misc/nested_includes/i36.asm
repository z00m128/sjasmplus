INC_DEPTH=0

    INCLUDE "i36_II.i.asm"

    db  "0123456789ABCDEF", 0xFF

    END


Test to check listing file format, focused on line numbering and include-nesting counter.

This one should produce only single digit line numbers in listing.
There are two more tests: `i36_I.asm` and `i36_II.asm` exercising two and three digits
line counters.