    ;SAVEHEX <filename>,<address>,<size>[,<start = -1>]

    DEVICE ZXSPECTRUM128
    ORG $7FFE   ; cross slot regions from Bank 5 to Bank 2
    ; SAVEHEX HEX record will be split on boundary due to implementation
Code:
    ld  b,c
Start:
    ld  b,d
Data:
    dz  "C"
End:
    block $4000, 'E'    ; fill beyond for longer file test (with various HEX records)

    DEVICE NONE
    ; error about device mode
    SAVEHEX "savehex.bin",0,1

    DEVICE ZXSPECTRUM128
    ; check parsing/syntax errors
    SAVEHEX
    SAVEHEX "savehex.bin"
    SAVEHEX "savehex.bin",
    SAVEHEX "savehex.bin", &
    SAVEHEX "savehex.bin", Code
    SAVEHEX "savehex.bin", Code,
    SAVEHEX "savehex.bin", Code, &
    SAVEHEX "savehex.bin", Code, End-Code,
    SAVEHEX "savehex.bin", Code, End-Code, &
    SAVEHEX "savehex.bin", Code, End-Code, Start,
    ; check errors of main arguments
    SAVEHEX "", Code, End-Code
    SAVEHEX ".", Code, End-Code, Start
    SAVEHEX "savehex.bin", -1, End-Code
    SAVEHEX "savehex.bin", Code, $10001-Code
    ; check "start" validity warning
    SAVEHEX "savehex.bin", Code, End-Code, -2
    SAVEHEX "savehex.bin", Code, End-Code, $10000

    ; valid with all arguments
    SAVEHEX "savehex.bin", Code, End-Code, Start
    SAVEHEX "savehex.raw", Code, End-Code, -1
    SAVEHEX "savehex.tap", Code, End-Code

    ; implementation specific, testing different HEX record sizes and edge cases
    SAVEHEX "savehex.cdt", Code, 34
    SAVEHEX "savehex.cpr", Code, 35

    ; coverage for all remaining HEX stuff if possible
    HEXOUT "savehex.blocked"
    SAVEHEX "savehex.tap", Code, End-Code   ; can't write file while HEXOUT is active
    HEXEND -2                               ; will report invalid start address, but also does close!
    HEXEND &                                ; syntax error (start expression) + no hex output active
    HEXOUT ""
