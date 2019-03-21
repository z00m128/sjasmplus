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

    ; Cyrillic long dash, code 151, should work as non-one (10101010 01010101)
    DG —-—-—-—- -—-—-—-—

    END
