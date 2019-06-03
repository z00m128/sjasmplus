        STRUCT BIN_FILE_MAP, 256
value1      BYTE
value2      WORD
        ENDS

        ORG  0x8000
binData BIN_FILE_MAP = $        ; set up label values only (no bytes)
        ; INCBIN "some_data.bin"  ; load the bytes from file instead
        INCBIN "st_usage_example_6_5.asm"   ; include the source itself to not error out

        ; using the data through struct definition
        ld  a,(binData.value1)
        ld  hl,(binData.value2)
