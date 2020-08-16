        STRUCT BLOCK_HEADER
length      WORD    BLOCK_HEADER
type        BYTE    $AB
name        TEXT    10, { "none", 32, '!' } ; will produce "none !!!!!" default data
                    ; because this is definition of the field, here last byte is "filler"
datastart   WORD
datalen     WORD
checksum    BYTE    $CC
        ENDS

        ORG  0x8000
head1   BLOCK_HEADER {      ; Multi-line initialization requires curly braces.
    , ,                     ; Keeping default length and type by specifying empty values.
    { 'New',                ; The final `name` data will be "New Name!!"
        32,                 ; overwriting only 8 bytes of default data.
        "Name" },           ; The last "e" is NOT "filler" in the non-default value.
        $8000, $1234        ; Explicit datastart and datalen values.
}                           ; End of initial data block ("checksum" keeps default value).

; machine code (struct data):
; 12 00 AB 4E 65 77 20 4E 61 6D 65 21 21 00 80 34 12 CC
; = { $0012, $AB, "New Name!!", $8000, $1234, $CC }
