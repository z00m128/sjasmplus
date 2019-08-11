    FPOS 1
    OUTPUT "ignore.bin",r
    SIZE 1              ; will cause error about exceeeding output size
    OPT --syntax=w      ; warnings as errors
    EXPORT error_about_default_file
    ENDMODULE   ; error: without beginning of module
    IF 1
        DISP        0x1234
            nop
        ENDT
        FPOS 0
        TEXTAREA    0x2345
            ret
        DEPHASE
        PHASE       0x3456
            cpl
        UNPHASE
        daa
        OUTEND
    ELSE
        ; no endif to fall through the <EOF>
