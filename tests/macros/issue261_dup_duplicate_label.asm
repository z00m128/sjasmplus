blah    EQU 42
        DUP 3, blah : DB blah : EDUP  ; DUP variable is clashing with EQU symbol -> report error
