;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test case for IFUSED / IFNUSED ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Compilation:
;;      sjasmplus.exe ifused_test.asm --lstlab --lst=ifused_test.lst
;;
;; After compilation, please check the listing file "ifused_test.lst"


;; This must generate syntax errors

        IFUSED                      /* some white space */ ; in comments
        IFNUSED                     /* some white space */ ; in comments

;; All rest of code must be compiled without errors

start

;; Some little user program :)

.noused call    EnableInt
.used   call    Wait
        jr      .used

;; Some little direct tests

        IFUSED                      /* some white space */ ; in comments
            db      'ok'
        ELSE
            fail
        ENDIF

        IFNUSED                     /* some white space */ ; in comments
            fail
        ELSE
            db      'ok'
        ENDIF

        IFUSED  .used               /* some white space */ ; in comments
            db      'ok'
        ELSE
            fail
        ENDIF
        IFUSED  start.used          /* some white space */ ; in comments
            org $-2 : db      'ok'
        ELSE
            fail
        ENDIF
        IFUSED  @start.used         /* some white space */ ; in comments
            org $-2 : db      'ok'
        ELSE
            fail
        ENDIF

        IFUSED  .noused             /* some white space */ ; in comments
            fail
        ENDIF
        IFUSED  start.noused        /* some white space */ ; in comments
            fail
        ENDIF
        IFUSED  @start.noused       /* some white space */ ; in comments
            fail
        ENDIF

        IFUSED  not_defined_label   /* some white space */ ; in comments
            fail
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

;; ADDENDUM: different code path to generate some more syntax errors
        IFUSED  Invalid&Label
        IFNUSED Invalid%Label
        IFUSED  ..InvalidLabel
        IFNUSED  ..InvalidLabel
