    ; dot repeater is partially tested in docs_examples, here are more complex cases and errors
    .16     ld  (hl),c                ; 16x 0x71
x:
    .( ( 2*2 ) + 12 )   ret z       ; 16x 0xC8
    .(x)    ld  (hl),d              ; 16x 0x72

    ;; syntax errors
    .2.3    nop     ; there must be space after repeat-counter
    . 16    nop     ; but no space after dot
    . (16)  nop
    .-1     nop
    .(zz)   nop     ; undefined label
    .16+2   nop     ; expressions must be in parentheses
    .1 +2   nop     ; expressions must be in parentheses (this one is ugly :/ )

    ;; value errors
    .0      nop     ; counter must be positive value
    .(x-32) nop     ; error should show calculated repeat-counter value

    ;; whole expression must be enclosed in parentheses (did work as "x7" up to v1.17.0)
    .(-1) +8 nop    ; error -1 count

    .(4-2)  and 1   ; counter example why the above is NOT harmless (revealed in v1.17.0)
        ; this produces 2x "and 1" (in v1.17.0 it does instead add `and 1` to expression)

    .(5-3   and 2   ; parentheses are not closed
    .(6-4)) and 3   ; one too many closing parentheses
