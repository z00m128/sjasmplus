; this is currently (v1.18.2) invalid construction of nested DUP->EDUP inside different conditional blocks
; and will not work, but the sjasmplus does segfault hard on this instead of just reporting error
i1: ifndef SKIP_DUP
        dup 3
        daa
    else
        nop
    endif
i2: ifndef SKIP_DUP
        edup
    endif
