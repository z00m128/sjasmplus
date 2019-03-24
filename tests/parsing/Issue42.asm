    DEVICE ZXSPECTRUM128
    OUTPUT "Issue42.bin"
    ORG #8000

    MODULE M1

LABEL equ 0

    ENDMODULE

    MODULE M2

    IFNUSED M1.LABEL
.tmp = M1.LABEL
    ; two lines (L15 + L16) with any content was "error", one line only + ENDIF was "OK"
    ; L16 comment (breaking sjasmplus v1.11 (and older))
    ENDIF

    ; the issue was, that the lines inside IFNUSED are parsed in first pass only
    ; (condition is different in second and third pass)
    ; making the search for local labels to operate on different source-structure in 2nd+ pass

    ; this particular source will now compile after some updates to the local labels code,
    ; but in principle it is easy to produce other code which would not reach stable
    ; structure within 3-pass assembling process, making local labels out of sync again.

    ENDMODULE

1
    jr 2f
    jr 1b
2