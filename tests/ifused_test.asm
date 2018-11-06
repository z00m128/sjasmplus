;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test source for IFUSED / IFNUSED ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Compilation:
;;      sjasmplus.exe ifused_test.asm --lstlab --lst=ifused-test.lst
;;
;; After compilation, please check the listing file "ifused-test.lst"


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
        nop     ;; Must generate NOP
        ELSE
        nop     ;; Must be skipped
        ENDIF

        IFNUSED
        nop     ;; Must be skipped
        ELSE
        nop     ;; Must generate NOP
        ENDIF

        IFUSED  .used
        nop     ;; Must generate NOP
        ENDIF

        IFUSED  .noused
        nop     ;; Must be skipped
        ENDIF

        IFUSED  not_defined_label
        nop     ;; Must be skipped
        ENDIF

;; Some little library :)

EnableInt
        IFUSED  EnableInt
        ei
        ret
        ENDIF

        IFUSED  Wait
Wait    ld      b,#FF
.loop
        IFUSED  EnableInt
.halter halt                    ;; This "halt" must be generated now
        ELSE
        ld      c,#FF           ;; When the "call EnableInt" is commented out,
.cycle  dec     c               ;; this branch after ELSE must be generated.
        jr      nz,.cycle
        ENDIF                   ;; End of IFUSED EnableInt

        djnz    .loop
        ret
        ENDIF                   ;; End of IFUSED Wait
