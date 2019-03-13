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
    ; 2x "012345678\n" + "012\n"
    db      48-7+"\A", 49-8+"\B", 50-127+"\D", 51-27+"\E", 52-12+"\F"
    db      53-10+"\N", 54-13+"\R", 55-9+"\T", 56-11+"\V", "\n"
    db      "\A"+48-7, "\B"+49-8, "\D"+50-127, "\E"+51-27, "\F"+52-12
    db      "\N"+53-10, "\R"+54-13, "\T"+55-9, "\V"+56-11, "\n"
    db      '0'+0,1+'0','0'+2,10

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
    DC      10, "a"-32, "BC", "DEF" ; last char of each substring |128
    DZ      10, "abc", "def"    ; extra 0 after last byte

    ; block/ds directive
    BLOCK   5, "\n"
    DS      16, '*'

    ; 7x warning, testing 8/16b checks
    DB      266, 256, -257, -502
    DW      -65537, 65536, "DCBA"   ; last one should produce bytes 'A', 'B'
    ; 5x 8b warnings for whole expressions (checks before "add" in ABYTE directive)
    ABYTE '!' 128+128, 191+'A', 'A'+191, 191+"A", "A"+191

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

    ;; exercising DW a bit more
    DW      'AA',    'BB'     ,       'CC'
    DW                              ; error: Expression expected
    DW      +                       ; error: Syntax error
    ; 128 values = OK
    DW      1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
    ; 129 values = error too many
    DW      -1, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16

    ;; exercising DD a bit more
    DD      'AAAA',    'BBBB'     ,       'CCCC'
    DD                              ; error: Expression expected
    DD      +                       ; error: Syntax error
    ; 128 values = OK
    DD      -1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
    ; 129 values = error too many
    DD      -1, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16

    ;; exercising D24 a bit more
    D24     'AAA',    'BBB'     ,       'CCC'
    D24    'AAAA',   'BBBB'     ,      'CCCC'       ; 3x int24 warning
    D24                             ; error: Expression expected
    D24     +                       ; error: Syntax error
    ; 128 values = OK
    D24     -1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
    ; 129 values = error too many
    D24     -1, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
