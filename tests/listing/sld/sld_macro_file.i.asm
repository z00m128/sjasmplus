;; define macro to be used in other file
mac1    MACRO
.mac1Start:
            jr      c,.mac1End
            ld      c,b
            mac2
.mac1End:
            ld      b,b
        ENDM

mac2    MACRO
.mac2Start:
            djnz    $
.mac2End:
        ENDM
