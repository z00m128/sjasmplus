    MACRO valid0 ; no arg
        nop
    ENDM

    MACRO valid1 arg1?  ; 1 arg
        DB arg1?
    ENDM

    MACRO valid2 arg1?  ,  arg2?  ; 2 arg
        DB arg1?, arg2?
    ENDM

    valid0
    valid1 1
    valid2 2, 3

    ; parsing errors

    MACRO missing_name1 arg1?  ,   ; extra comma
    ENDM

    MACRO invalid_name1 |   ; invalid char
    ENDM

    MACRO invalid_name2 arg1?  ,  |  ; invalid char in second arg
    ENDM

    MACRO invalid_name3 arg1? x   ; extra x
    ENDM

    MACRO invalid_name4 arg1?, arg2? y   ; extra y
    ENDM

    MACRO duplicate_arg argx?    , argx? ; "argx?" twice
    ENDM
