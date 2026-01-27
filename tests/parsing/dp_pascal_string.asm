; Test for Issue #241: declaration of Pascal Strings (`DP`)
    ORG $8000
    OPT reset --syntax=abf

    DP "Hello"                          ; Equivalent to: DB 5,"Hello"
    DP "Foo", "Bar"                     ; Equivalent to: DB 6,"Foo","Bar"
    DP "abc", 13, "efg", 0              ; Equivalent to: DB 8,"abc\refg\0"

    ; check multiple directives on same line split by colon (each has own length)
    dp "abc",0,"efg",0:dp "second string with own length byte"

    ; no need to test 256+ lengths because sjasmplus DB-like parser has limit of 128 bytes per line
    ; so any longer pascal string must be defined by DB over multiple lines

    ; test zero size string (but why? just `DB 0` to avoid warnings/errors)
    dp ""

    ; check alias
    DEFP "Ahoy!"
    defp "Ahoy!"

    ; check syntax error
    DP
    DP  &
    DP  "Ahoy!",&
