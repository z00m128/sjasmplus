    DUP &
        nop
    EDUP

    DUP 3
        nop
    ENDM    ; warning about deprecation

    DEFARRAY 1nvalidName 1, 2, 3
    DEFARRAY,InvalidSyntax 1, 2, 3
    DEFARRAY InvalidSyntax+1, 2, 3
    DEFARRAY+ 1nvalidName 1, 2, 3
    DEFARRAY+InvalidSyntax 1, 2, 3
    DEFARRAY+ UnknownId 1, 2, 3
    DEFARRAY+ InvalidSyntax+1, 2, 3

    DEFARRAY syntaxErrArr  1, 2, "3
    DEFARRAY syntaxErrArr  1, 2, "3'
    DEFARRAY syntaxErrArr  1, 2, '3
    DEFARRAY syntaxErrArr  1, 2, <3
    DEFARRAY syntaxErrArr  1, 2, 3"
    DEFARRAY syntaxErrArr  1, 2, ,4
    DB syntaxErrArr[2]
    DB syntaxErrArr[3]
    DB syntaxErrArr[4]
    DEFARRAY syntaxErrArr2
    DEFARRAY syntaxErrArr2  ; empty
    DEFARRAY syntaxErrArr2  1, 2,
    DEFARRAY syntaxErrArr2  1, 2,,
    DEFARRAY+ syntaxErrArr2  3, 4,
    DEFARRAY+ syntaxErrArr2
    DEFARRAY+ syntaxErrArr2    ; empty
    DEFARRAY+ syntaxErrArr2  5, 6,,
    DEFARRAY+ syntaxErrArr2  7, 8, "3
    DB syntaxErrArr2[0]
    DB syntaxErrArr2[1]
    DB syntaxErrArr2[2]
    DB syntaxErrArr2[3]
    DB syntaxErrArr2[4]
    DB syntaxErrArr2[5]
    DB syntaxErrArr2[6]
    DB syntaxErrArr2[7]
    DB syntaxErrArr2[8]
    DB syntaxErrArr2[9]
    DB syntaxErrArr2[10]
    DB syntaxErrArr2[11]
    DB syntaxErrArr2[12]
    DB syntaxErrArr2[13]

    DEVICE &syntaxErrorName
