    ;; invalid numeric literals errors

    ;; missing digits
    DD      #
    ;DD $   => is actual valid syntax for current address pointer
    DD      0x
    DD      %

    ;; hard 32b overflow
    DD      0xFFFFFFFF                          ; OK
    DD      0x100000000                         ; overflow error
    DD      %11111111111111111111111111111111   ; OK
    DD      %100000000000000000000000000000000  ; overflow error
    DD      37777777777o                        ; OK
    DD      40000000000o                        ; overflow error
    DD      4294967295                          ; OK
    DD      4294967296                          ; overflow error

    ;; digit out of base
    DD      12A0
    DD      12A0d
    DD      0FFGFh
    DD      0xFFGF
    DD      $FFGF
    DD      #FFGF
    DD      1002001b
    DD      01002001b
    DD      %1002001
    DD      %01002001
    DD      12834q
    DD      12834o

    ;; since v1.20.0 the parser does recognise decimal part of the constant and throws it away with warning
    ;; this is crude work-around to help migrate Lua 5.1 scripts, as those now format values like 2^7 as "128.0"
    OPT -Wdecimalz
    DB      12.0
    DB      $AB.0
    DB      %101.0
    DB      0q77.0
    DB      12.03
    DB      $AB.0E
    DB      %101.01
    DB      0q77.01
    LUA ALLPASS     ; warning vs integer variant
        _pc("db " .. 2^7 .. " , " .. (1<<7))    -- "1<<7" is integer variant of "2^7"
        _pc("db " .. 2^7.00001 .. " , " .. math.floor(2^7.00001))
        _pc("db " .. 35/7 .. " , " .. 35//7)    -- "35//7" is integer variant of "35/7"
        _pc("db " .. 36/7 .. " , " .. 36//7)    -- "36//7" is integer variant of "36/7"
    ENDLUA
    DB      12.0'0
    DB      12.0'1
    ; errors when decimal part has invalid digit
    DB      12.A
    DB      $AB.G
    DB      %101.2
    DB      0q77.8
