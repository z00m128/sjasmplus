    ;;;;;;;;;;;;;;;;;;;;;;;; DG ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; new directives DG for v1.11 (should be compatible with Zeus assembler)
    DG --#----#
    DG "--#----#"
    DG '--#----#'
    DG ..$....$
    DG "..$....$"
    DG '..$....$'
    DG __@____@
    DG "__@____@"
    DG '__@____@'

    ; 64 bits defined
    DG ---#--##-#-#####---#--##-#-#####---#--##-#-#####---#--##-#-#####

    ;; skip spaces
    DG --#- ---#                ; 8 bits defined
    DG ---# #---    ---- ----   ; 16 bits defined

    ;; warning about multiple chars used for ones -> should be emitted only once per assembling
    DG --#----1
    DG --#----1

    ;; warning about char '0' being used -> should be emitted only once per assembling
    DG --0----0
    DG --0----0

    ;; errors - wrong delimiters will get eaten as part of value
    DG "--#----'
    DG '--#----"

    ;; (3+3)x error short strings
    DG --
    DG "--"
    DG '--'

    DG --#----#--#      ; 8 + 3 bits
    DG "--#----#--#"
    DG '--#----#--#'

    ; Cyrillic cp1251 long dash, code 151, should work as 'one' (10101010 01010101)
    DG —-—-—-—- -—-—-—-—

    ;;;;;;;;;;;;;;;;;;;;;;;; DH ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; new directives DH for v1.11 (should be compatible with Zeus assembler)
    DH "0123456789ABCDEF"           ; recommended syntax
    DH '0123456789ABCDEF'           ; but this works too
    DH 0123456789ABCDEF             ; and this works too

    DH "012345", "6789ABCDEF"       ; should work (although not sure who would want it)
    DH 01 23 45, 67 89 AB CD EF

    ; space between values is legit
    DH "01 23 45 67   89 AB CD EF"
    DH '01 23 45 67   89 AB CD EF'
    DH  01 23 45 67   89 AB CD EF

    ; error states
    DH 123          ; 4x syntax error (digits are not in pairs
    DH "123"
    DH 12 3
    DH "12  3"
    DH 12,          ; 2x no arguments
    DH "12",

    DH 12G034       ; wrong base
    DH "12G034"

                    ; missing delimiter
    DH "0123456789ABCDEF

    ; 128 arguments at most (256 chars)
    DH 0123456789ABCDEF0123456789ABCDEF 0123456789ABCDEF0123456789ABCD0F 0123456789ABCDEF0123456789ABCDEF 0123456789ABCDEF0123456789ABCD0F 0123456789ABCDEF0123456789ABCDEF 0123456789ABCDEF0123456789ABCD0F 0123456789ABCDEF0123456789ABCDEF 0123456789ABCDEF0123456789ABCD0F ; should be OK (8x16 = 128)
    ; 129 -> should error
    DH 0123456789ABCDEF0123456789ABCDEF 0123456789ABCDEF0123456789ABCD0F 0123456789ABCDEF0123456789ABCDEF 0123456789ABCDEF0123456789ABCD0F 0123456789ABCDEF0123456789ABCDEF 0123456789ABCDEF0123456789ABCD0F 0123456789ABCDEF0123456789ABCDEF 0123456789ABCDEF0123456789ABCD0F EE EE EE, EE, EE

    END
