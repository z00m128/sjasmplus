    CALL LABEL3 ; LABEL3 - yes
    LD A,(LABEL1) ; LABEL1 - yes

    jr  1B      ;; error
    jr  1F
    jr  4F
1
    jr  1B
    jr  1F      ;; error
    IFUSED LABEL1
LABEL1:
    DB '1'
    ENDIF

    jr  2F
    jr  4F
2
    jr  1B
    jr  2B
    IFUSED LABEL2
LABEL2:
    DB '2'
    ENDIF

    jr  3F
    jr  4F
3
    jr  1B
    jr  3B
    IFUSED LABEL3
LABEL3:
    DB '3'
    ENDIF

    jr  4B      ;; error
    jr  4F
4
    jr  1B
    jr  4B
    jr  4F
    IFUSED LABEL4
LABEL4:
    DB '4'
    ENDIF

    jr  4B
    jr  4F
4               ;; double "4" local label (according to docs this should work)
    jr  1B
    jr  4B
    jr  4F      ;; error

    LD A,LABEL2 ; LABEL2 - yes

    call LABEL1
    call LABEL2
    call LABEL3
;    call LABEL4 - stay unused

    RET
