    ;;;;;;;;;;;;;;;;;;;;;;;; DG ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; new directives DG for v1.11 (should be compatible with Zeus assembler)
    DG --#----#
    DG "--#----#"
    DG '--#----#'

    ; 64 bits defined
    DG ---#--##-#-#####---#--##-#-#####---#--##-#-#####---#--##-#-#####

    ;; skip spaces
    DG --#- ---#                ; 8 bits defined
    DG ---# #--- ---- ----      ; 16 bits defined

    ;; warning about multiple chars used for ones -> should be emitted only once per assembling
    DG --#----1
    DG --#----1

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

    ;; error when digit "grouping" through space is more than single character long
    DG --#-  ---#               ; 8 bits defined, but two spaces in middle = error

    ; Cyrillic long dash, code 151, should work as 'one' (10101010 01010101)
    DG —-—-—-—- -—-—-—-—

    ;;;;;;;;;;;;;;;;;;;;;;;; DH ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; new directives DH for v1.11 (should be compatible with Zeus assembler)
    DH "0123456789ABCDEF"           ; recommended syntax
    DH '0123456789ABCDEF'           ; but this works too
    DH 0123456789ABCDEF             ; and this works too

    ; single space between values is legit
    DH "01 23 45 67 89 AB CD EF"    ; the check is not 100% perfect,
    DH '01 23 45 67 89 AB CD EF'    ; extra spaces after last value are ignored too
    DH 01 23 45 67 89 AB CD EF      ; but that's implementation quirk (not in test)

    ; error states
    DH 123          ; syntax error (digits are not in pairs
    DH "123"
    DH 12G034       ; wrong base
    DH "12G034"
    DH 12  34       ; two+ spaces between
    DH "12  34"
                    ; missing delimiter
    DH "0123456789ABCDEF

    ; 128 arguments at most (256 chars)
    DH 0123456789ABCDEF0123456789ABCDEF 0123456789ABCDEF0123456789ABCD0F 0123456789ABCDEF0123456789ABCDEF 0123456789ABCDEF0123456789ABCD0F 0123456789ABCDEF0123456789ABCDEF 0123456789ABCDEF0123456789ABCD0F 0123456789ABCDEF0123456789ABCDEF 0123456789ABCDEF0123456789ABCD0F ; should be OK (8x16 = 128)
    ; 129 -> should error
    DH 0123456789ABCDEF0123456789ABCDEF 0123456789ABCDEF0123456789ABCD0F 0123456789ABCDEF0123456789ABCDEF 0123456789ABCDEF0123456789ABCD0F 0123456789ABCDEF0123456789ABCDEF 0123456789ABCDEF0123456789ABCD0F 0123456789ABCDEF0123456789ABCDEF 0123456789ABCDEF0123456789ABCD0F EE

    END
