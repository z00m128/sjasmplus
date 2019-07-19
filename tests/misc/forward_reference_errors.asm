        ; DEFL vs EQU difference
defl_lab2   DEFL    0x1234
equ_lab2    EQU     0x1234
defl_lab2   DEFL    0x5678
equ_lab2    EQU     0x5678

        ;; valid forward reference
        call    normal_label
normal_label:
        ret

        ;; invalid forward references
defl_lab    DEFL    defl_lab_fwd
equ_lab     EQU     equ_lab_fwd

        IF 0 < normal_label2_fwd
            ; nop - would move pass2 vs pass3
        ENDIF

        STRUCT test_struct, struct_lab_fwd
xyz         BYTE
        ENDS

        DUP dup_label_fwd
        EDUP

defl_lab_fwd:
equ_lab_fwd:
struct_lab_fwd:
normal_label2_fwd:
dup_label_fwd:
