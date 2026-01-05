    OUTPUT "srcStdIn.bin"

    INCLUDE "srcStdIn.i.asm"

    ORG $8000       ; fileorg-ok ;; uncut align blocks
    ALIGN 4
    DB  1
    ALIGN 4
    DB  2, 3
    ALIGN 4
    DB  4, 5, 6
    ALIGN 4
    DB  7, 8, 9, 10
    ALIGN 4

    ORG $8100       ; fileorg-ok ;; cut to 3 and "..." align blocks
    ALIGN 16
    DB  1
    ALIGN 16
    DB  2, 3
    ALIGN 16
    DB  4, 5, 6
    ALIGN 16
    DB  7, 8, 9, 10
    ALIGN 16

    ORG $8200       ; fileorg-ok ;; some should fit fully, some should be cut
    ALIGN 8
    DB   1,  2,  3
    ALIGN 8
    DB   4,  5,  6,  7
    ALIGN 8
    DB   8,  9, 10, 11, 12
    ALIGN 8
    DB  13, 14, 15, 16, 17, 18
    ALIGN 8

    ORG $8300       ; fileorg-ok ;; same as $8200 case, crammed into single source line
    ALIGN 8:DB 1,2,3:ALIGN 8:DB 4,5,6,7:ALIGN 8:DB 8,9,10,11,12:ALIGN 8:DB 13,14,15,16,17,18:ALIGN 8

    ORG $9000       ; fileorg-ok ;; BLOCK emit
    BLOCK   1, 1
    BLOCK   2, 2
    BLOCK   3, 3
    BLOCK   4, 4
    BLOCK   5, 5
    BLOCK   6, 6
    BLOCK   7, 7
    BLOCK   8, 8
