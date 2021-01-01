; during working on advent-of-code 2020 as sjasmplus scripts, I have run into
; insufficient syntax error reporting

; AFTER FIX: the while is not executed even once, only syntax error is reported

    DEVICE ZXSPECTRUMNEXT
counter = 1
    WHILE (counter < 2)) || (counter < 4)
                    ;  ^ silent extra closing parenthesis - missing syntax error
        nop         ; it was producing only one nop, as if the expression did end there
counter = counter + 1
    ENDW
