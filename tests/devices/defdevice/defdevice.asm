    DEFDEVICE LikeZx48,     $4000,  4       ; auto initial pages expected: 0, 1, 2, 3
    DEFDEVICE LikeZxNext,   $2000, 96, 14, 15, 10, 11, 4, 5, 0  ; last slot page should be auto-set to 1
    DEFDEVICE SmallSlot,    $0100, 16, 2, 7, 13  ; auto initial pages expected: 2, 7, 13, 14, 15, 15, ...

    DEVICE LIKEZX48
    ORG $0000 : ASSERT  0 == $$
    ORG $4000 : ASSERT  1 == $$
    ORG $8000 : ASSERT  2 == $$
    ORG $C000 : ASSERT  3 == $$

    DEVICE LIKEZXNEXT
    ORG $0000 : ASSERT 14 == $$
    ORG $2000 : ASSERT 15 == $$
    ORG $4000 : ASSERT 10 == $$
    ORG $6000 : ASSERT 11 == $$
    ORG $8000 : ASSERT  4 == $$
    ORG $A000 : ASSERT  5 == $$
    ORG $C000 : ASSERT  0 == $$
    ORG $E000 : ASSERT  1 == $$

    DEVICE SMALLSLOT
    ORG $0000 : ASSERT  2 == $$
    ORG $0100 : ASSERT  7 == $$
    ORG $0200 : ASSERT 13 == $$
    ORG $0300 : ASSERT 14 == $$
    ORG $0400 : ASSERT 15 == $$
    ORG $0500 : ASSERT 15 == $$
    ORG $0600 : ASSERT 15 == $$
    ; MMU test
    MMU $0500 $1400, 0
    ORG $0500 : ASSERT  0 == $$
    ORG $0600 : ASSERT  1 == $$
    ORG $0700 : ASSERT  2 == $$
    ORG $0800 : ASSERT  3 == $$
    ORG $0900 : ASSERT  4 == $$
    ORG $0A00 : ASSERT  5 == $$
    ORG $0B00 : ASSERT  6 == $$
    ORG $0C00 : ASSERT  7 == $$
    ORG $0D00 : ASSERT  8 == $$
    ORG $0E00 : ASSERT  9 == $$
    ORG $0F00 : ASSERT 10 == $$
    ORG $1000 : ASSERT 11 == $$
    ORG $1100 : ASSERT 12 == $$
    ORG $1200 : ASSERT 13 == $$
    ORG $1300 : ASSERT 14 == $$
    ORG $1400 : ASSERT 15 == $$

    MMU $2000 n, 14, $2000
label1:
    DS 256, $AA
label2:
    ASSERT $ == $2000 && 15 == $$
    ret
