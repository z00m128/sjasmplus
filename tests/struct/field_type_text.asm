        STRUCT substr1
sm00    text    5, { "12!" }    ; last byte fills remaining size, i.e. `12!!!` (in definition)
        ENDS

        STRUCT substr2
        byte    '3'
sub0    substr1 { { "4", "5", "67" } }  ; `4567!` - init value does only replace definition values
        byte    '8'
sub1    text    3, { '?' }              ; `???`
        byte    'A'
        ENDS


        STRUCT  str, 1
m00     byte    'B'
m01     text    10, { "CDEFG", "H", $40+9, "JKL" }  ; `CDEFGHIJKL`
m02     block   1, 'M'
m03     TEXT    5, { 'N' }              ; `NNNNN`
m04     defs    1, 'O'
m05     substr2 { 'P', { {"QRSTU"} }, 'V', { 'W', "XY" }, 'Z' }
m06     substr2
m07     substr1
m08     substr2 { 'a', 'b', 'c' }           ; texts are skipped with default initializer
m09     substr2 { 'd', {}, 'e', {}, 'f' }   ; texts are skipped with default initializer
        ENDS

        DEVICE ZXSPECTRUM48

        ORG 0x8000
        ds  0x4000, '_'     ; fill memory with '_'
        ORG 0x8000
;; first set testing init-values list structure parsing
d01     str                                                         : DB "\n"
    ; "_BCDEFGHIJKLMNNNNNOPQRSTUVWXYZ34567!8???A12!!!a4567!b???cd4567!e???f\n"
d02     str     {,,,{'#'}}                                          : DB "\n"
    ; "_BCDEFGHIJKLMNNNNNO#QRSTUVWXYZ34567!8???A12!!!a4567!b???cd4567!e???f\n"
d03     str     {{},{}{'#'{{"Q##"}}}}                               : DB "\n"
    ; "_BCDEFGHIJKLMNNNNNO#Q##TUVWXYZ34567!8???A12!!!a4567!b???cd4567!e???f\n"
d04     str     {{},{},{'#',{{"Q##"}}}}                             : DB "\n"
    ; "_BCDEFGHIJKLMNNNNNO#Q##TUVWXYZ34567!8???A12!!!a4567!b???cd4567!e???f\n"
d05     str     {{},{},{{}},{'#',{},,{"."}}}                        : DB "\n"
    ; "_BCDEFGHIJKLMNNNNNOPQRSTUVWXYZ#4567!8.??A12!!!a4567!b???cd4567!e???f\n"

;; identical test cases as d02..d05, but without the top-level enclosing {}
;; but then these need initial comma for 'B' byte, to force first {} to "CDEFG.." text
dx2     str      ,,,{'#'}                                           : DB "\n"
    ; "_BCDEFGHIJKLMNNNNNO#QRSTUVWXYZ34567!8???A12!!!a4567!b???cd4567!e???f\n"
dx3     str      ,{},{}{'#'{{"Q##"}}}                               : DB "\n"
    ; "_BCDEFGHIJKLMNNNNNO#Q##TUVWXYZ34567!8???A12!!!a4567!b???cd4567!e???f\n"
dx4     str      ,{},{},{'#',{{"Q##"}}}                             : DB "\n"
    ; "_BCDEFGHIJKLMNNNNNO#Q##TUVWXYZ34567!8???A12!!!a4567!b???cd4567!e???f\n"
dx5     str      ,{},{},{{}},{'#',{},,{"."}}                        : DB "\n"
    ; "_BCDEFGHIJKLMNNNNNOPQRSTUVWXYZ#4567!8.??A12!!!a4567!b???cd4567!e???f\n"

;; initial 'B' explicitly modified
dy2     str      'g',,,{'#'}                                        : DB "\n"
    ; "_gCDEFGHIJKLMNNNNNO#QRSTUVWXYZ34567!8???A12!!!a4567!b???cd4567!e???f\n"
dy3     str      'h',{},{}{'#'{{"Q##"}}}                            : DB "\n"
    ; "_hCDEFGHIJKLMNNNNNO#Q##TUVWXYZ34567!8???A12!!!a4567!b???cd4567!e???f\n"
dy4     str      'i',{},{},{'#',{{"Q##"}}}                          : DB "\n"
    ; "_iCDEFGHIJKLMNNNNNO#Q##TUVWXYZ34567!8???A12!!!a4567!b???cd4567!e???f\n"
dy5     str      'j',{},{},{{}},{'#',{},,{"."}}                     : DB "\n"
    ; "_jCDEFGHIJKLMNNNNNOPQRSTUVWXYZ#4567!8.??A12!!!a4567!b???cd4567!e???f\n"

parse1  substr1 {{'0'|1,'0'|2,'0'+3}}                               : DB "\n"
    ; "123!!\n"

    ; BIN is produced only from valid emits (skipping the following error checking part)
        SAVEBIN  "field_type_text.bin", 0x8000, $-0x8000

;; too long text initializer
err1    substr1 {{"abcde!"}}

;; too long text initializer (defined by single bytes)
err2    substr1 {{'a','b','c','d','e','!'}}
err3    substr1 {{'a','b','c','d','e',$21}}

    ; error in text field definition
        STRUCT S_ERR1
        text    2           ; valid (zeroed)
        text    1, {'1'}    ; valid
        text    1, {   }    ; valid (zeroed)
        text    128, {'2'}  ; valid ; 128 was old maximum, now it is 8192 (not testing)
        ; invalid ones (some error should be reported):
        text
        text    0, {'3'}
        text    -1, {'4'}
        text    8193, {'5'}
        ; next line emits 00 00
        text    2 @
        ; next line emits 00 00
        text    2,
        ; next line emits 00 00
        text    2, {,
        ; next line emits 00 00
        text    2, {'
        '
        ; next line emits 36 00
        text    2, {'6
        '
        ; next line emits 37 00
        text    2, {'7'
endIt
        ; next line emits 00 00
        text    2, "89"
        ; next line emits 00 00
        text    2, { @, @ }
        ENDS
emitE1  S_ERR1

        STRUCT S_ERR2
        texts   30, { "invalid type" }  ; but looks similar
        TEXTS   30, { "invalid type" }  ; but looks similar
        ENDS
