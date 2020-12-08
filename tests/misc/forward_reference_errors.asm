        ;; DEFL vs EQU difference
defl_lab2   DEFL    0x1234              ;; DEFL (and alias "=") are like "variables"
defl_lab2   =       0x5678              ;; so modifying them is OK

equ_lab2    EQU     0x1234              ;; EQU is like "const", should be defined only once
equ_lab2    EQU     0x5678              ;; error, different value

        ;; valid forward reference
        call    normal_label
normal_label:
        ret

        ;; invalid forward references
defl_lab    DEFL    defl_lab_fwd
equ_lab     EQU     equ_lab_fwd         ;; !! VALID since v1.13.3 !!

        IF 0 < normal_label2_fwd
            ; <some instruction> - would modify results of pass2 vs pass3
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

        IF 0 < normal_label3_fwd    ; fwdref-ok - since v1.15.0 it's possible to suppress the warning
            ASSERT 0 < $
        ENDIF

        IF 4 = normal_label3_fwd    ; fwdref-ok - but label reports warning even when IF warning is suppressed
            nop
        ENDIF

normal_label3_fwd:
