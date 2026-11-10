; Test for Issue #241: declaration of Pascal Strings (`DP`)
    ORG $8000
    OPT reset --syntax=abf

    DP "Hello"                          ; Equivalent to: DB 5,"Hello"
    DP "Foo", "Bar"                     ; Equivalent to: DB 6,"Foo","Bar"
    DP "abc", 13, "efg", 0              ; Equivalent to: DB 8,"abc\refg\0"

    ; check multiple directives on same line split by colon (each has own length)
    dp "abc",0,"efg",0:dp "second string with own length byte"

    ; max length 255 is OK (DB-like parser accepts up to 256 bytes per directive)
    DP "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDE"
    ; 256 bytes is too long for pascal string (length byte would overflow) => error
    DP "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF"

    ; test zero size string (valid pascal string, only emptystr warning, no error)
    dp ""

    ; check alias
    DEFP "Ahoy!"
    defp "Ahoy!"

    ; check syntax error
    DP
    DP  &
    DP  "Ahoy!",&
