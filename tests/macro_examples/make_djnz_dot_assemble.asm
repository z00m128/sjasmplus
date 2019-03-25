;; while trying to compile one larger legacy code written with Zeus syntax on mind,
;; I run into lines "DJNZ .", which are basically the same thing as "DJNZ $" in sjasmplus
;; To avoid editing whole file and replacing those on each occurence, I managed to get
;; them fixed by defining this macro at beginning of the file:

    ;; fix "DJNZ ." to "DJNZ $"
    MACRO DJNZ arg0?
        DEFINE .._arg0?
        IFDEF .._.
            djnz $
        ELSE
            djnz arg0?
        ENDIF
        IFDEF .._           ;; extra test for "$" argument, that one produces ".._" define
            UNDEFINE .._
        ELSE
            UNDEFINE .._arg0?
        ENDIF
    ENDM

;; let's see it in action

OrdinaryLabelDjnz   DJNZ    OrdinaryLabelDjnz

        DJNZ    $           ;; sjasmplus syntax

        DJNZ    .           ;; Zeus syntax, will be corrected by the macro "DJNZ"

        djnz    $           ;; avoid macro by using lowercase :D
