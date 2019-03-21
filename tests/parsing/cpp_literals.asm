    OUTPUT "cpp_literals.bin"

    END : FIXME ... v1.12+ feature?

    ; following are C++ rules plus extra octal rules
    ; C++ rules
    dd  0x1234abcd, 0XE78F, 0x12'34'ab'cd
    dd  1234, 1'234
    dd  0b01010011010101, 0b0101'0011'0101
    ; octals can't reasonably abide the C++ rules (leading zero), so let's make up `0q`
    dd  0q1234, 0q12'34

    END     ; scratch for some experiments
