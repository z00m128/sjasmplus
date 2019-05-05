    OUTPUT "new_apostrophe.bin"

    ; test new \0 escape for double quotes
    db  "\0"

    ; test new stricter rules for not-escaping apostrophe strings
    db  '\E', '\\'          ; test (4 bytes)
    db  "\\E", "\\\\"       ; expected (emulating expected result in quotes)
    db  '''''', '\', 0, ''  ; test (4 bytes) + warning
    db  "''", "\\", 0       ; expected (emulating expected result in quotes)

    ; more tricky ones (putting stress also on line parsers and buffer readers)
    db  '/**/''/**/''\n\\''\"'''
    db  "/**/'/**/'\\n\\\\'\\\"'"    ; expected

    db  "\"" : db 0
    db  '\' : db 1
    db  '\\' : db 2
    db  '' : db 3           ; warning empty string + error no arguments
    db  '''' : db 4

    dw  'ABCD', 'ABCDEFGHXX'; regular value check warnings + string literal overflow
    dw  "ABCD", "ABCDEFGHXX"; regular value check warnings + string literal overflow

    ;; exercise remaining escape sequences inside apostrophes (shouldn't be escaped)
    db  '\A', '\B', '\D', '\E'      ; verify nothing leaks into comments
    db  '\F', '\N', '\R', '\T'      ; verify nothing leaks into comments
    db  '\\', '\"', '\?', '"\'      ; verify nothing leaks into comments
    db  '\0', '\'''                 ; verify nothing leaks into comments
    db  "\n"

    ;; Example about string literals from documentation
    BYTE "stringconstant\n" ; escape sequence assembles to newline
    BYTE 'stringconstant\n' ; \n assembles literally as two bytes: '\', 'n'
    LD HL,'hl'  ; hl = 0x686C = 'l', 'h'
    LD HL,"hl"  ; hl = 0x686C = 'l', 'h'
    LD A,"7"    ; not recommended (but works)
    LD A,'8'    ; recommended
    LD A,'\E'   ; warning + truncating value to 'E' (0x45)
    LD A,'"'    ; A = 0x22
    LD A,"'"    ; A = 0x27
    LD A,''''   ; A = 0x27 ; since v1.11
