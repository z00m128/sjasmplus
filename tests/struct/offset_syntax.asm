        STRUCT S_s0  /* bc */   ; no offset specified
f1          DB  '-'
f2          DW  0x2000
        ENDS
s0      S_s0

        STRUCT S_s1, 2      ; correct way of offset specification
f1          DB  'x'
f2          DW  0x4000
        ENDS
s1      S_s1

        STRUCT S_s2 2       ; syntax error (silently ignored in v1.13.0 = bug)
f1          DB  'y'
f2          DW  0x6000
        ENDS
s2      S_s2

        STRUCT S_s3, xx     ; offset by forward-reference of label = error (missing label)
f1          DB  'z'
f2          DW  0x8000
        ENDS
s3      S_s3

        STRUCT S_s4, yy     ; offset by forward-reference of label = error (existing)
f1          DB  'z'
f2          DW  0xA000
        ENDS
s4      S_s4
yy:             ; this will move with every pass further down then = lot of errors
