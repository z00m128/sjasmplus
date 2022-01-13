    DB 1:DB 2       ; legal syntax
DB 3:DB 4           ; error without --dirbol ("DB" becomes label)
    DW 5 DW 6       ; error, no colon
DW 7 DW 8           ; error without --dirbol and no colon ("DW" becomes label)

    OPT --dirbol
    DB 1:DB 2       ; legal syntax
DB 3:DB 4           ; legal syntax with --dirbol
    DW 5 DW 6       ; error, no colon after DW 5
DW 7 DW 8           ; error, no colon after DW 7 (but DW 7 works with --dirbol)
