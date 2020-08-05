    STRUCT shortBlock
byte    BYTE    'A'
block   BLOCK   5, 'B'
word    WORD    'DC'
    ENDS

    STRUCT onLimitBlock
byte    BYTE    'A'
block   BLOCK   8, 'B'      ; should be emitted without ellipsis
word    WORD    'DC'
    ENDS

    STRUCT longBlock
byte    BYTE    'A'
block   BLOCK   9, 'B'      ; listed with ellipsis, needs fix of following address
word    WORD    'DC'
    ENDS

    ; verify offsets
    ASSERT  6 == shortBlock.word
    ASSERT  9 == onLimitBlock.word
    ASSERT 10 == longBlock.word

    ORG $1000
    ; this should list normally
sb      shortBlock          ; should produce continuous 1+5+2 = 8 bytes listing

    ORG $2000
mb      onLimitBlock        ; should produce continuous 1+8+2 = 11 bytes listing

    ORG $3000
lb      longBlock           ; should produce ellipsis after "block" + extra "ListFile()" call
                            ; and advance address for "word"

    ; one more ellipsis not aligning to the very beginning of MC byte quartet in LST
    STRUCT longBlock2
byte    BYTE    'A'
block1  BLOCK   9, '!'
block2  BLOCK   9, 'B'
word    WORD    'DC'
    ENDS

    ORG $8000
lb2     longBlock2          ; some eol comment

    ; verify final addresses
    ASSERT $1006 == sb.word
    ASSERT $2009 == mb.word
    ASSERT $300A == lb.word
    ASSERT $8001 == lb2.block1 && $800A == lb2.block2 && $8013 == lb2.word
