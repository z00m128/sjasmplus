; there are some unreachable lines in numbers parsing (defensive programming, don't want to remove them)
kickoffWithDotDefl  .defl   1234
    .OPT reset --syntax=ab : ld a,(
    .ASSERT(0 == not 1)
    .DB  "\x"
    .DB  1+""
    .INCLUDE "missing_delimiter
    .INCLUDE ""
    .STRUCT coverageStruct
LL1 BYME    1
ll1 byme    1
LL2 WORR    2
ll2 worr    2
LL3 BLICK   3
ll3 blick   3
LL4 DBBB    4
ll4 dbbb    4
LL5 DWWW    5
ll5 dwww    5
LL6 DSSS    6
ll6 dsss    6
LL7 DDDD    7
ll7 dddd    7
LL8 ALONG   8
ll8 along   8
LL9 DEDE    9
ll9 dede    9
LLA D255    A
lla d255    a
    .ENDS
