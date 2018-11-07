;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test case for IFUSED / IFNUSED ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Compilation:
;;      sjasmplus.exe ifused_test.asm --lstlab --lst=ifused_test.lst
;;
;; After compilation, please check the listing file "ifused_test.lst"


;; This must generate syntax errors

        IFUSED
        IFNUSED

;; All rest of code must be compiled without errors

start

;; Some little user program :)

.noused call    EnableInt
.used   call    Wait
        jr      .used

;; Some little direct tests

        IFUSED
        db      'ok'
        ELSE
        db      'fail'
        ENDIF

        IFNUSED
        db      'fail'
        ELSE
        db      'ok'
        ENDIF

        IFUSED  .used
        db      'ok'
        ENDIF

        IFUSED  .noused
        db      'fail'
        ENDIF

        IFUSED  not_defined_label
        db      'fail'
        ENDIF

;; Some little library :)

EnableInt
        IFUSED  EnableInt
        ei
        ret
        ENDIF

Wait    IFUSED
        ld      b,#FF
.loop
        IFUSED  EnableInt
.halter halt
        ELSE
        ld      c,#FF           ;; When the "call EnableInt" is commented out,
.cycle  dec     c               ;; this branch after ELSE must be generated.
        jr      nz,.cycle
        ENDIF                   ;; End of IFUSED EnableInt

        djnz    .loop
        ret
        ENDIF                   ;; End of IFUSED Wait
