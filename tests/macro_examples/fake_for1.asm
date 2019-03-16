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

;; first version - does work as intended, exploits DUP directive, looks ugly

    MACRO instanceExample half.from?, half.to?, half.step?
.HALF=half.from?
        DUP 1+(half.to? - half.from? + half.step? - 1) / half.step?
.Y=0
            DUP 1+($E0 / $20)
.X=0
                DUP 1+($700/$100)
                    ;DISPLAY "Doing DW with [half: ", .HALF, " y: ", .Y, " x: ", .X, "]"
                    dw ScreenBufferCWGI + .X + .Y + .HALF
.X=.X+$100
                EDUP
.Y=.Y+$20
            EDUP
.HALF=.HALF + half.step?
        EDUP
    ENDM

    OUTPUT "fake_for1.bin"
ScreenBufferCWGI=$4000
    instanceExample $0, $800, $800
