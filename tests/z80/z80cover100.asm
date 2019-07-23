    ;; few more test cases not covered by regular tests,
    ;; but were discovered by code coverage as code not executed in tests

    ; some tests need more strict syntax rules to hit specific code paths
    OPT reset --syntax=ab

    xor     [1234   ; "Operand expected" error when parsing of no-memory argument fails

    call            ; "Operand expected" error

    ld      a,high af           ; tricky way to write "ld a,a" :) ("high af" covered)

    in      low af,(c)          ; tricky way to write "in f,(c)" ("low af" covered)

    ; nonexistent register pairs (with possible match) in `GetRegister` function
    pop az : pop ha : pop xa : pop ya : pop YA

    ; invalid registers in common ALU instructions
    xor af : xor sp : xor i : xor r : xor f

    adc     hl      ; "Comma expected" error
    adc     hl,ix   ; invalid instr.
    adc     b ,, c  ; multiarg
