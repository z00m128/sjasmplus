    DEVICE AMSTRADCPC464

    ORG $1000
Code:
    ld  b,c
Start:
    ld  b,d
Data:
    dz  "C"
End:

    DEVICE NONE
    ; error about device mode
    SAVEAMSDOS "saveamsdos.bin", Code, End-Code, Start

    DEVICE AMSTRADCPC464
    ; check parsing errors
    SAVEAMSDOS
    SAVEAMSDOS "saveamsdos.bin"
    SAVEAMSDOS "saveamsdos.bin",
    SAVEAMSDOS "saveamsdos.bin", Code
    SAVEAMSDOS "saveamsdos.bin", Code,
    SAVEAMSDOS "saveamsdos.bin", Code, End-Code,
    SAVEAMSDOS "saveamsdos.bin", Code, End-Code, Start,
    SAVEAMSDOS "saveamsdos.bin", Code, End-Code, Start, 2,
    ; check errors of main arguments
    SAVEAMSDOS "", Code, End-Code
    SAVEAMSDOS "saveamsdos.bin", -1, End-Code
    SAVEAMSDOS "saveamsdos.bin", Code, $10001-Code
    ; check "start" and "type" validity warning
    SAVEAMSDOS "saveamsdos.bin", Code, End-Code, -1
    SAVEAMSDOS "saveamsdos.bin", Code, End-Code, $10000
    SAVEAMSDOS "saveamsdos.bin", Code, End-Code, Start, -1
    SAVEAMSDOS "saveamsdos.bin", Code, End-Code, Start, 256

    ; valid line with all arguments
    SAVEAMSDOS "saveamsdos.bin", Code, End-Code, Start, 0
    ; valid line with default start and type
    SAVEAMSDOS "saveamsdos.raw", Code, End-Code
