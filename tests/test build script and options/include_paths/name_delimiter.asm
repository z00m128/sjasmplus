; issue #406, reported issue when delimited by tab instead of space

    IFNDEF MAIN
        DEFINE MAIN
        OUTPUT "name_delimiter.bin"
        ld b,c
        INCLUDE "name_delimiter.asm"    ; delimited by quotes
    ELSE
        IFNDEF QUOTED
            DEFINE QUOTED
            ld b,d
            INCLUDE name_delimiter.asm  ; delimited by space
        ELSE
            IFNDEF SPACED
                DEFINE SPACED
                ld b,e
                INCLUDE	name_delimiter.asm	; delimited by tab
            ELSE
                ; tab-delimited
                ld b,h
            ENDIF
        ENDIF
    ENDIF
