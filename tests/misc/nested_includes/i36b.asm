INC_DEPTH=0

    INCLUDE "i36b_II.i.asm"

    db  "0123456789ABCDEF", 0xFF

    END


Test to check listing file format, focused on line numbering and include-nesting counter.

This is similar to "i36" tests, but the include file is using many more colons to pack
multiple instructions/expressions on single line, to make sure the listing file does not
miss some expression in such case.