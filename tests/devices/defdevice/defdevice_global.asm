
    ORG $0000 : ASSERT  0 == $$
    ORG $4000 : ASSERT  1 == $$
    ORG $8000 : ASSERT  2 == $$
    ORG $C000 : ASSERT  3 == $$
    ret

    DEVICE LIKEZX48                         ; only one DEVICE -> global -> also can be used before DEF

    DEFDEVICE LikeZx48,     $4000,  4       ; auto initial pages expected: 0, 1, 2, 3
