; end of line can be now escaped with backslash (to concatenate multiple lines into one)
; but the implementation is fairly limited:
; - the total line length is still 2k chars max
; - line numbers reported for errors are pointing to last line of full line
; - listing file shows only concatenated line with last line number
; - eol-comments can't be split (they end with EOL even when backslash is there)
; - not even trying what will happen to SLD spans when colons and \ are intermixed

BUILD_ENTRANCE          EQU     0x01
BUILD_RESIDENTIAL_AREA  EQU     0x02
BUILD_WAREHOUSE         EQU     0x04
BUILD_SHOPPING_AREA     EQU     0x08

    ld (ix + 123), BUILD_ENTRANCE | BUILD_RESIDENTIAL_AREA \
        | BUILD_WAREHOUSE \
        | BUILD_SHOPPING_AREA \
        ; multi-line finishing here

    ASSERT 0, "line numbers for single line should work"

    ld (ix + 123), BUILD_ENTRANCE | BUILD_RESIDENTIAL_AREA \
        | MISSING_LABEL \
        | BUILD_SHOPPING_AREA \
        ; multi-line with error, reported error line is *here* (last line of multi-line)

    ; eol comment can't be split \
    this is new line

    /* inside block comment it's ignored \
    but that doesn't change anything about it, as the block continues */

    invalid : nop \
        ; comment for nop, "invalid" report it's own correct line number

    nop : invalid \
        ; comment for invalid, error reports *this* line

    ; let's try macro definitions, because why the heck not
    MACRO my_ml_ma
        pop \
            de \
        : push \
            hl
    ENDM

    my_ml_ma

    DEFINE ML_DEF U REALLY \
        PUSHING IT, \
        AREN'T YA?

    ML_DEF
