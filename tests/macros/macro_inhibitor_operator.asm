        OUTPUT "macro_inhibitor_operator.bin"

djnz    MACRO   arg1?
            dec c
            jr  nz,arg1?
        ENDM

1:
        djnz    1B      ; macro replacement
        @djnz   1B      ; original djnz instruction
        @ djnz  1B      ; can be space separated
@label  djnz    label   ; this "@" belongs to the label, macro expanded
        djnz    @label
@label2 @djnz   label2  ; this is original djnz instruction
        @djnz   @label2

db      MACRO   arg1?
            dw  arg1?
        ENDM

        db      0x1234  ; macro replacement
        @db     0x35    ; original db directive
        @ db    0x36    ; can be space separated
