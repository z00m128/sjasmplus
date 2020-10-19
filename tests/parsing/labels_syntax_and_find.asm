    OUTPUT "labels_syntax_and_find.bin"

    MODULE mod1 : ORG $3130
label:
        dec hl
.local:
        inc l

        dw  label
        dw  .local
        dw  label.local
        dw  mod1.label.local
        dw  @mod1.label.local
        ; global one!
        dw  @label
        dw  @label.local
        dw  @unique
        dw  unique
        ; mod1 unique
        dw  mod1unique
        dw  mod1.mod1unique
        dw  @mod1.mod1unique
mod1unique:
        ; mod2 unique
        dw  '!!'+mod2unique ; should be error, searching only: mod1.mod2unique, @mod2unique
        dw  mod2.mod2unique
        dw  @mod2.mod2unique
        ; mod1 nested
        dw  nested.label
        dw  nested.label.local
        dw  mod1.nested.label.local
        dw  @mod1.nested.label.local
        dw  '!!'+nest1unique    ; should be error
        dw  nested.nest1unique
        dw  mod1.nested.nest1unique
        dw  @mod1.nested.nest1unique
        ; mod2 nested
        dw  mod2.nested.label
        dw  @mod2.nested.label
        dw  mod2.nested.label.local
        dw  @mod2.nested.label.local
        dw  '!!'+nested.nest2unique ; should be error
        dw  mod2.nested.nest2unique
        dw  @mod2.nested.nest2unique

        MODULE nested
label:
            dec l
.local:
            cpl
nest1unique:
        ENDMODULE

    ENDMODULE

    MODULE mod2 : ORG $3332
label:
        add hl,hl
.local:
        daa

        dw  label
        dw  .local
        dw  label.local
        dw  mod2.label.local
        dw  @mod2.label.local
        ; global one!
        dw  @label
        dw  @label.local
        dw  @unique
        dw  unique
        ; mod2 unique
        dw  mod2unique
        dw  mod2.mod2unique
        dw  @mod2.mod2unique
mod2unique:
        ; mod1 unique
        dw  '!!'+mod1unique ; should be error, searching only: mod2.mod1unique, @mod1unique
        dw  mod1.mod1unique
        dw  @mod1.mod1unique
        ; mod2 nested
        dw  nested.label
        dw  nested.label.local
        dw  mod2.nested.label.local
        dw  @mod2.nested.label.local
        dw  '!!'+nest2unique    ; should be error
        dw  nested.nest2unique
        dw  mod2.nested.nest2unique
        dw  @mod2.nested.nest2unique
        ; mod1 nested
        dw  mod1.nested.label
        dw  @mod1.nested.label
        dw  mod1.nested.label.local
        dw  @mod1.nested.label.local
        dw  '!!'+nested.nest1unique ; should be error
        dw  mod1.nested.nest1unique
        dw  @mod1.nested.nest1unique

        MODULE nested
label:
            inc h
.local:
            dec h
nest2unique:
        ENDMODULE

    ENDMODULE

    ORG $3534
label:
    dec hl
.local:
    inc l

    dw  label
    dw  .local
    dw  label.local
    dw  @label.local
    dw  mod1.label.local
    dw  @mod1.label.local
    dw  mod2.label.local
    dw  @mod2.label.local
    ; uniques
    dw  unique
    dw  @unique
    dw  '!!'+mod1unique ; should be error
    dw  mod1.mod1unique
    dw  @mod1.mod1unique
    dw  mod1.nested.nest1unique
    dw  @mod1.nested.nest1unique
    dw  '!!'+mod2unique ; should be error
    dw  mod2.mod2unique
    dw  @mod2.mod2unique
    dw  mod2.nested.nest2unique
    dw  @mod2.nested.nest2unique
    ; nested
    dw  '!!'+nested.label       ; should be error
    dw  '!!'+nested.label.local ; should be error
    dw  mod1.nested.label
    dw  @mod1.nested.label
    dw  mod2.nested.label.local
    dw  @mod2.nested.label.local

unique:
    dec l

..invalidLabelName:
@.invalidLabelName:
.@invalidLabelName:
.1nvalidLabelName:
@1nvalidLabelName:
.@1nvalidLabelName:
@.1nvalidLabelName:
1nvalidLabelName: jr  nz,1B
Inv&lidL&belN&me:
100     equ     should not work
101     =       should not work
102     defl    should not work
103:    equ     should not work
104:    =       should not work
105:    defl    should not work

EquLineRemnants1:   EQU $+1-$100    cpl     ; error
EquLineRemnants2:   EQU $+2-$100  : cpl     ; valid
DeflLineRemnants1:  DEFL $+3-$100   cpl     ; error
DeflLineRemnants2:  DEFL $+4-$100 : cpl     ; valid
DeflLineRemnants3:  = $+5-$100      cpl     ; error
DeflLineRemnants4:  = $+6-$100    : cpl     ; valid

; the ones without colon are reported as errors since v1.17.1, because without colon
; this is total "gotcha":
noColonProblemDemonstration EQU $   and 7
    ; ^^ the expression parser will eat whole "$ and 7", no instruction/error here
    ; obviously *this* does NOT report error even after change, it's valid expression...
