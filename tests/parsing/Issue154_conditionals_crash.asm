    macro prn6x8f_simple
    endm

    ; error - duplicate macro name, ignoring this definition
    macro prn6x8f_simple FontAddr, shift
    endm

    macro prn6x8f_loop FontAddr
        ; error, too many arguments -> but should recover from it, 1.18.3 will hard-crash due to losing FontAddr
        prn6x8f_simple FontAddr, 1
        ; same error as previous line, FontAddr should be correctly substituted (in 1.18.3 it's lost)
        prn6x8f_simple FontAddr, 2
    endm

    macro print6x8_84_fast FontAddr
        prn6x8f_loop FontAddr
    endm

start print6x8_84_fast $c000
