; Based on documentation example (definitions same as tests/docs_examples/c_structures.asm)
; But this test does focus on stressing initializers syntax

        STRUCT substr1
sm00    BYTE    '1'
        ENDS

        STRUCT substr2
        byte    '2'
sub0    substr1 '3'
        byte    '4'
sub1    substr1 '5'
        byte    '6'
        ENDS


        STRUCT  str, 1
m00     byte    'A'
m01     db      'B'
m02     defb    'C'
m03     word    'ED'
m04     dw      'GF'
m05     defw    'IH'
m06     d24     'LKJ'
m07     dword   'PONM'
m08     dd      'TSRQ'
m09     defd    'XWVU'
m10     block   1, 'Y'
m11     ds      1, 'Z'
m12     defs    1, 'a'
m13     #       1, 'b'
m14     align   2, 'c'
m15     ##      4, 'd'  ; 2x 'd'
m16     substr2
        ENDS

        DEVICE ZXSPECTRUM48

        ORG 0x8000
        ds  0x4000, '_'     ; fill memory with '_'
        ORG 0x8000
;; first set testing init-values list structure parsing
d01     str                                                         : ALIGN   4, "\n"
    ; "_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdd23456\n\n\n"
d02     str     {{{'!'}}}                                           : ALIGN   4, "\n"
    ; "_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdd2!456\n\n\n"
d03     str     {'!'{'!'{'!'}}}                                     : ALIGN   4, "\n"
    ; "_!BCDEFGHIJKLMNOPQRSTUVWXYZabcdd!!456\n\n\n"
d04     str     {'!'{'!',{'!'}}}                                    : ALIGN   4, "\n"
    ; "_!BCDEFGHIJKLMNOPQRSTUVWXYZabcdd!!456\n\n\n"
d05     str     {'!'{'!',,{'!'}}}                                   : ALIGN   4, "\n"
    ; "_!BCDEFGHIJKLMNOPQRSTUVWXYZabcdd!34!6\n\n\n"
d06     str     {'!'{,'!',{'!'}}}                                   : ALIGN   4, "\n"
    ; "_!BCDEFGHIJKLMNOPQRSTUVWXYZabcdd2!4!6\n\n\n"
d07     str     {'!'{,'!','!'}}                                     : ALIGN   4, "\n"
    ; "_!BCDEFGHIJKLMNOPQRSTUVWXYZabcdd2!!56\n\n\n"
d08     str     {'!'{'!',,{'!'},'!'}}                               : ALIGN   4, "\n"
    ; "_!BCDEFGHIJKLMNOPQRSTUVWXYZabcdd!34!!\n\n\n"
d09     str     {'!'{'!',{'!'},'!'}}                                : ALIGN   4, "\n"
    ; "_!BCDEFGHIJKLMNOPQRSTUVWXYZabcdd!!!56\n\n\n"
d10     str     {,'!',,'!!',{{'!'}}}                                : ALIGN   4, "\n"
    ; "_A!C!!FGHIJKLMNOPQRSTUVWXYZabcdd2!456\n\n\n"
d11     str     {,'!',,'!!',{'!'}}                                  : ALIGN   4, "\n"
    ; "_A!C!!FGHIJKLMNOPQRSTUVWXYZabcdd!3456\n\n\n"

;; identical test cases as d02..d11, but without the top-level enclosing {}
d12     str     ,{{'!'}}                                            : ALIGN   4, "\n"
    ; ^^^ Needs at least some hint the first { is not global level => "," added
    ; "_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdd2!456\n\n\n"
d13     str     '!'{'!'{'!'}}                                       : ALIGN   4, "\n"
    ; "_!BCDEFGHIJKLMNOPQRSTUVWXYZabcdd!!456\n\n\n"
d14     str     '!'{'!',{'!'}}                                      : ALIGN   4, "\n"
    ; "_!BCDEFGHIJKLMNOPQRSTUVWXYZabcdd!!456\n\n\n"
d15     str     '!'{'!',,{'!'}}                                     : ALIGN   4, "\n"
    ; "_!BCDEFGHIJKLMNOPQRSTUVWXYZabcdd!34!6\n\n\n"
d16     str     '!'{,'!',{'!'}}                                     : ALIGN   4, "\n"
    ; "_!BCDEFGHIJKLMNOPQRSTUVWXYZabcdd2!4!6\n\n\n"
d17     str     '!'{,'!','!'}                                       : ALIGN   4, "\n"
    ; "_!BCDEFGHIJKLMNOPQRSTUVWXYZabcdd2!!56\n\n\n"
d18     str     '!'{'!',,{'!'},'!'}                                 : ALIGN   4, "\n"
    ; "_!BCDEFGHIJKLMNOPQRSTUVWXYZabcdd!34!!\n\n\n"
d19     str     '!'{'!',{'!'},'!'}                                  : ALIGN   4, "\n"
    ; "_!BCDEFGHIJKLMNOPQRSTUVWXYZabcdd!!!56\n\n\n"
d20     str     ,'!',,'!!',{{'!'}}                                  : ALIGN   4, "\n"
    ; "_A!C!!FGHIJKLMNOPQRSTUVWXYZabcdd2!456\n\n\n"
d21     str     ,'!',,'!!',{'!'}                                    : ALIGN   4, "\n"
    ; "_A!C!!FGHIJKLMNOPQRSTUVWXYZabcdd!3456\n\n\n"

;; few more extra tests
d22     str     {'!'{'!',{'!'}'!'}}                                 : ALIGN   4, "\n"
    ; "_!BCDEFGHIJKLMNOPQRSTUVWXYZabcdd!!!56\n\n\n"
d23     str     {'!'{'!',{}'!'}}                                    : ALIGN   4, "\n"
    ; "_!BCDEFGHIJKLMNOPQRSTUVWXYZabcdd!3!56\n\n\n"
@d24    str     {'!'{'!',{},'!'}}                                   : ALIGN   4, "\n"
    ; "_!BCDEFGHIJKLMNOPQRSTUVWXYZabcdd!3!56\n\n\n"

;; value warnings
w0     str     '!!'                                : ALIGN   4, "\n"
    ; "_!BCDEFGHIJKLMNOPQRSTUVWXYZabcdd23456\n\n\n"

        SAVEBIN  "fields_types.bin", 0x8000, $-0x8000