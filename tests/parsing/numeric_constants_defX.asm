    OUTPUT "numeric_constants_defX.bin"
    ;; official documentation of v1.10.4 - all possible DEFx directives and synonyms

    ; should produce ABCDEFGHIJKLM, all possible numeric literals - byte size
    BYTE    65, 66d
    DB      43h, 0C4h-080h, 0x45, $46, #47
    DEFB    1001000b, 01001001b, %1001010, %01001011
    DEFM    114q, 115o

    ;; some char/string literals - quotes parse escape sequences
    ; \n, ", \, ', ', ', ?, ?, \n
    DM      "\n", "\"", "\\", "''\'", "\??", "\N"
    ; "012345678\n"
    db      48-7+"\A", 49-8+"\B", 50-127+"\D", 51-27+"\E", 52-12+"\F"
    db      53-10+"\N", 54-13+"\R", 55-9+"\T", 56-11+"\V", "\n"

    ; WORD binary data
    WORD    0C000h, "HA"   ,   "HE"
    DW      %0000100010101110
    DEFW    1000101011101001b

    ; DWORD binary data
    DWORD   0x12345678
    DD      87654321h,$FFFFFFFF
    DEFD    #DEADF00D   ,   "\nEEB"

    ABYTE   64 1, 2, 3          ; +64
    ABYTEC  3 "ABC", 4, "EF"    ; +3, last char of each substring |128
    ABYTEZ  9 "ABC", 4, "EF"    ; +9, extra 0 after last byte
    DC      10, "123", "456"    ; last char of each substring |128
    DZ      10, "abc", "def"    ; extra 0 after last byte

    ; block/ds directive
    BLOCK   3, "\n"
    DS      16, '*'

    ; 7x warning, testing 8/16b checks
    DB      266, 256, -257, -502
    DW      -65537, 65536, "DCBA"   ; last one should produce bytes 'A', 'B'

    DC      'a', 'ab'               ; DC distincts between single (no |128) and two+ chars
    DC      "a", "ab"               ; but only in apostrophes, quotes make it "string" always

    DB                              ; expression expected error
    DB      1,                      ; expression expected error
    DC      "", ''                  ; 2x warning about empty "string" + 1x error "no arguments"

    ;; too many arguments error tests:
    ; 2x OK (max 128 bytes)
    DB      "\n123456789ABCDEF","0123456789ABCDEF","0123456789ABCDEF","0123456789ABCDEF","\n123456789ABCDEF","0123456789ABCDEF","0123456789ABCDEF","0123456789ABCDEF"
    DB      "\n123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF\n123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF"
    ; 3x error too many
    DB      "\n123456789ABCDEF","0123456789ABCDEF","0123456789ABCDEF","0123456789ABCDEF",'!',"\n123456789ABCDEF","0123456789ABCDEF","0123456789ABCDEF","0123456789ABCDEF"
    DB      "\n123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF\n123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF", 1
    DB      "\n123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF\n123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF!"

    END     ; scratch for some experiments

    ;;;FIXME work-in-progress
    db  '\E'       ; IMO '\\'' is bug, should be '\'
    db  "\E"
    db  '\\'
    db  "\\"
    db  ''''
    db  "'"
    db  '\'

	;; single apostroph, parse shouldn't escape anything except \'
    db  '\A', '\B', '\D', '\E'
    db  '\F', '\N', '\R', '\T'
    db  '\V', '\"', '\?', '\\''     ; IMO '\\'' is bug, should be '\'
                        ; also it leaks into comments, so there are two different parsers!
    db  '\'', "\n"                  ; and '\'' is bug too, apostroph in apostrophes has no valid syntax, based on docs

    END     ; following are C++ rules plus extra octal rule
    ; C++ rules
    dd  0x1234abcd, 0XE78F, 0x12'34'ab'cd
    dd  1234, 1'234
    dd  0b01010011010101, 0b0101'0011'0101
    ; octals can't reasonably abide the C++ rules (leading zero), so let's make up `0q`
    dd  0q1234, 0q12'34
