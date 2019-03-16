; this is example of "for ... next" like logic recreated by current sjasmplus syntax

; The original example source (coming from one "can I do something like..." discussion):
;
;     for half=$0000 to $0800 step $0800       ; This is calculated so it works for any buffer address.
;         for y=$0000 to $00E0 step $0020        ; (in theory)
;             for x=$0000 to $0700 step $0100
;                 dw ScreenBufferCWGI+x+y+half
;             next
;         next
;     next

;; second version, does define "generic" FOR macro, with a subtle catch:
;; the "code?" argument can be only single expression/instruction/macro
;; But "single macro" can take you to great lengths...

    MACRO FOR var?, from?, to?, step?, code?
var?=from?
dup_count?=-1
        IF from? <= to? && 0 < step?
dup_count?=(to? - from?) / step?
        ENDIF
        IF to? <= from? && step? < 0
dup_count?=(from? - to?) / -step?
        ENDIF
        IF dup_count? < 0
            DISPLAY "illegal from ", from?, " to ", to?, " step ", step?, " => count=", 1+dup_count?
        ELSE
            DUP 1+dup_count?
            code?
var?=var?+step?
            EDUP
        ENDIF
    ENDM

    MACRO fn_body
        ;DISPLAY "Doing DW with [half: ", half, " y: ", y, " x: ", x, "]"
        dw ScreenBufferCWGI+x+y+half
    ENDM

    OUTPUT "fake_for2.bin"
ScreenBufferCWGI=$4000
    ;FOR half, 0, $800, $800, <FOR y, 0, $E0, $20, <FOR x, 0, $700, $100, dw ScreenBufferCWGI+x+y+half !> >
    ; example with fn_body macro usage (and how to break "single instruction" limit in practice)
    FOR half, 0, $800, $800, <FOR y, 0, $E0, $20, <FOR x, 0, $700, $100, fn_body !> >
