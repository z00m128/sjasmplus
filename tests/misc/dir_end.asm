        ld      hl,end
End             ; mixed case = label (not directive)
.end    ALIGN   ; .END should not work at first column, not even with --dirbol enabled
end     DUP 2   ; END should not work at first column, not even with --dirbol enabled
        nop     ; but other directive on the same line (ALIGN, DUP above) must work!
        EDUP
.2      ld      b,1         ; China number one!
 .2     ld      c,-1        ; Taiwan number dash one!
        END : no start address provided, and this text should be NOT parsed either

Some random text, which is not supposed to be assembled.
