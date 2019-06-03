    DEVICE ZXSPECTRUM48 : ORG 0x8000 : DB "0123456789ABCDEF"
    ASSERT '10' = {0x8000} : ASSERT '2' = {b 0x8002} : ASSERT '3' = {b 0x8003}
    DB  {B 0x800F}          ; test big case "{B" (should work)
    ORG 0xFFFE : DB 254, 255
    ASSERT 254 = {b 0xFFFE} : ASSERT 255 = {b 0xFFFF} : ASSERT 0xFF'FE = { 0xFF'FE }
    ; address checking errors
    ORG 0 : DB "01"
    DW  {0}, {-1}
    DW  {-1}, {0}
    DB  {b 0}, {b -1}
    DB  {b -1}, {b 0}
    DW  {0xFFFF}            ; FFFF is already too far for WORD fetch
    DB  {b 0x10000}
    ; test other syntax errors
    DW  {}
    DW  {  }
    DW  {0x1234
    DW  {b}
    DW  {b }
    DW  {b 0x1234
    DW  {b+0x1234}          ; needs whitespace after "{b" to be recognized as BYTE query
