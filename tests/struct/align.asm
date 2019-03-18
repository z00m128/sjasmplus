        STRUCT SPOS,4
X       WORD
Y       BYTE
        ALIGN 2
        BLOCK   3, '_'
        ALIGN 4, '!'
AD      WORD
        ENDS

    ASSERT SPOS.X == 4 && SPOS.Y == 6 && SPOS.AD == 12 && SPOS == 14

        STRUCT ST2
ONEB    DB      'a'
P1      SPOS    { 'bc', 'd', 'ef' }     ; will emit warning about misalignment (4 vs 3)
        ENDS

    ASSERT ST2.ONEB == 0 && ST2.P1 == 1 && ST2.P1.X == 5 && ST2.P1.Y == 7 && ST2.P1.AD == 13 && ST2 == 15

        DEVICE  ZXSPECTRUM48
        ; "old data" in memory (structs will be defined over, to check preservation)
        ORG     0x8000
        db      "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        db      "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

        ;; TEST data from structs
        ORG     0x8000

POS1    SPOS    '12', '3', '4:'
        ; 4Bx old_value (to reach offset 4), X:0x1234, Y:0x56, 1Bx old_value, AD:0x789A

POS2    ST2     "\n", {,,"\ne"}
        ; '\n' (ONEB), then 4x old value (offset), 'cbd' (X,Y), 1x old (align)
        ; '___!' (block+align), 'e\n' (AD) => final result: "\nPQRScbdW___!e\n"

        SAVEBIN "align.bin", POS1, SPOS + ST2

; more misalignment warnings tests

        ORG     0x8000
NoWarning   SPOS    {1, 2, 3}
        ORG     0x8001
Warn3B  SPOS    {1, 2, 3}
        ORG     0x8002
Warn2B  SPOS    {1, 2, 3}
        ORG     0x8003
Warn1B  SPOS    {1, 2, 3}
        ORG     0x8004
NoWarning2  SPOS    {1, 2, 3}
