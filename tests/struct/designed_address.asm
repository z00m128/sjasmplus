        STRUCT  S_TEST
byte    BYTE 'B'
word    WORD '2W'
dword   DWORD '432D'
        ENDS

        ORG 0x6780 : OUTPUT designed_address.bin

default     S_TEST      ; default initial values
        DB 0
designed    S_TEST = 0x1234     ; should not emit any bytes, but assign labels from 0x1234
initialized S_TEST 'A','/B','/__C'
        DB 0

        S_TEST = $      ; shoud not emit bytes, but also no label = warning

syntaxE S_TEST = ++     ; test syntax error
