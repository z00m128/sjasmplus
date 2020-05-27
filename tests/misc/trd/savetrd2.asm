    ; prepare test data
    DEVICE ZXSPECTRUM128 : MMU 0 3, 0 : ORG 0 : DS $10000, 0 : ASSERT $10000 = $ ; clear whole RAM first
    ORG $0000 : DB "<Area 0000" : ORG $4000-2 : DB "/><Area 4000"
    ORG $8000-2 : DB "/><Area 8000" : ORG $C000-2 : DB "/><Area C000" : ORG $10000-2 : DB "/>"

    EMPTYTRD "savetrd2.trd" ; new empty TRD = playground to verify fixes and changes

    ; the next-free-sector calculation bug in original sjasmplus
    SAVETRD "savetrd2.trd","s15.C",0,$1EFA      ; make the next free sector/track [15, 2]
    SAVETRD "savetrd2.trd","s15bug.C",0,$F200   ; next free should be [1,18]

    ; test new "replace" functionality (it will salvage the disc space in the most trivial case)
    SAVETRD "savetrd2.trd",|"s15.C",$8000,$4100  ; area 8000+C000 in file (allocating new sectors after s15bug.C)
    ; one more time
    SAVETRD "savetrd2.trd",|"s15.C",$4000,$C000  ; area 4000+8000+C000 in file (should overwrite previous replace)
    ; and one more time
    SAVETRD "savetrd2.trd",|"s15.C",0,$4000  ; area 0000 in file (should overwrite previous replace)
