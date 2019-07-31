        ld      hl,end
End             ; mixed case = label (not directive)
.end    ALIGN   ; .END should not work at first column, not even with --dirbol enabled
end     DUP 2   ; END should not work at first column, not even with --dirbol enabled
        nop     ; but other directive on the same line (ALIGN, DUP above) must work!
        EDUP
verifyLabel:
.2      ld      b,1         ; China number one!
 .2     ld      c,-1        ; Taiwan number dash one!
    some_error to check file paths output
        END : no start address provided, and this text should be NOT parsed either

This is basically identical to tests/misc/dir_end.asm, but this is using .options
file to do multi-source-file command line argument test.

The `END` directive should affect only current source file (but with all includes and/or
when `END` is triggered in include file).

Test files:
dir_end.asm (this one)  - simple single file, no includes, just ENDs few lines above
dir_end/dir_end1.a80    - another simple file, but second on command line
dir_end/dir_end2.a80    - has single include dir_end/dir_end2.i.asm (which ENDs)
dir_end/dir_end3.a80    - has single include dir_end/dir_end3.i.asm (which does not END)
