; issue in v1.15.1 reported on pk-ru forum:
; sometimes the internal function "cmphstr" is used to detect keywords over raw line data
; which didn't undergo yet proper substitution and contain block/EOL comment, then it was
; possible to miss the keyword if the comment char was right after it without whitespace

    DEFINE/*c*/xyz
    IFDEF/*c*/xyz
        DB/*c*/1
    ELSE
        ASSERT/*c*/0
    ENDIF
    UNDEFINE/*c*/xyz

    ; comment block focused
    IF/*c*/1
        ; nested IF/IFN/IFNUSED
        DB/*c*/2
        IFN/*c*/0
            DB/*c*/3
        ELSE/*c*/
            ASSERT/*c*/0
        ENDIF/*c*/
        ; "//" EOL comment focused
        IF/*c*/1
            DB/*c*/4
        ELSE//c
            ASSERT/*c*/0
        ENDIF//c
        ; ";" EOL comment focused
        IFNUSED/*c*/someLabel
            DB/*c*/5
        ELSE;c
            ASSERT/*c*/0
        ENDIF;c
    ELSE; comment - causing issue in v1.15.1
        ; nested + skipped IF/IFN/IFNUSED
        ASSERT/*c*/0
        IFN/*c*/0
            DB/*c*/-1
        ELSE/*c*/
            ASSERT/*c*/0
        ENDIF/*c*/
        ; "//" EOL comment focused
        IF/*c*/1
            DB/*c*/-2
        ELSE//c
            ASSERT/*c*/0
        ENDIF//c
        ; ";" EOL comment focused
        IFNUSED/*c*/someLabel
            DB/*c*/-3
        ELSE;c
            ASSERT/*c*/0
        ENDIF;c
    ENDIF; comment - causing issue in v1.15.1

    DUP/*c*/1
        DB 6
    EDUP//c

    STRUCT/*c*/ TestStruct
s_a     BYTE/*c*/-7
    ENDS//c

    TestStruct/*c*/{7}

;; LEVEL 2 - add empty defines into sensitive lines to verify they get skipped

    DEFINE _EMPTINESS_

    ; DEFINE, IFDEF and UNDEFINE can't provide substitution, so they can't attend LEVEL 2

    ; comment block focused
    IF/**/_EMPTINESS_/**/1
        ; nested IF/IFN/IFNUSED
        DB/**/_EMPTINESS_/**/10
        IFN/**/_EMPTINESS_/**/0
            DB/**/_EMPTINESS_/**/11
        ELSE/**/_EMPTINESS_/**/
            ASSERT/**/_EMPTINESS_/**/0
        ENDIF/**/_EMPTINESS_/**/
        ; "//" EOL comment focused
        IF/**/_EMPTINESS_/**/1
            DB/**/_EMPTINESS_/**/12
        ELSE/**/_EMPTINESS_//c
            ASSERT/**/_EMPTINESS_/**/0
        ENDIF/**/_EMPTINESS_//c
        ; ";" EOL comment focused
        IFNUSED/**/_EMPTINESS_/**/someLabel
            DB/**/_EMPTINESS_/**/13
        ELSE/**/_EMPTINESS_;c
            ASSERT/**/_EMPTINESS_/**/0
        ENDIF/**/_EMPTINESS_;c
    ELSE; comment - causing issue in v1.15.1
        ; nested + skipped IF/IFN/IFNUSED
        ASSERT/**/_EMPTINESS_/**/0
        IFN/**/_EMPTINESS_/**/0
            DB/**/_EMPTINESS_/**/-11
        ELSE/**/_EMPTINESS_/**/
            ASSERT/**/_EMPTINESS_/**/0
        ENDIF/**/_EMPTINESS_/**/
        ; "//" EOL comment focused
        IF/**/_EMPTINESS_/**/1
            DB/**/_EMPTINESS_/**/-12
        ELSE/**/_EMPTINESS_//c
            ASSERT/**/_EMPTINESS_/**/0
        ENDIF/**/_EMPTINESS_//c
        ; ";" EOL comment focused
        IFNUSED/**/_EMPTINESS_/**/someLabel
            DB/**/_EMPTINESS_/**/-13
        ELSE/**/_EMPTINESS_;c
            ASSERT/**/_EMPTINESS_/**/0
        ENDIF/**/_EMPTINESS_;c
    ENDIF; comment - causing issue in v1.15.1

    DUP/**/_EMPTINESS_/**/1
        DB 14
    EDUP/**/_EMPTINESS_//c

    STRUCT/**/_EMPTINESS_/**/ TestStruct_L2
s_a     BYTE/**/_EMPTINESS_/**/-14
    ENDS/**/_EMPTINESS_//c

    TestStruct_L2/**/_EMPTINESS_/**/{15}
