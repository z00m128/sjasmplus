    ;; invalid numeric literals errors

    ;; missing digits
    DD      #
    ;DD $   => is actual valid syntax for current address pointer
    DD      0x
    DD      %

    ;; hard 32b overflow
    DD      0xFFFFFFFF                          ; OK
    DD      0x100000000                         ; overflow error
    DD      %11111111111111111111111111111111   ; OK
    DD      %100000000000000000000000000000000  ; overflow error
    DD      37777777777o                        ; OK
    DD      40000000000o                        ; overflow error
    DD      4294967295                          ; OK
    DD      4294967296                          ; overflow error

    ;; digit out of base
    DD      12A0
    DD      12A0d
    DD      0FFGFh
    DD      0xFFGF
    DD      $FFGF
    DD      #FFGF
    DD      1002001b
    DD      01002001b
    DD      %1002001
    DD      %01002001
    DD      12834q
    DD      12834o
