    DEVICE ZXSPECTRUM1024
                ORG     $8000
regular:

equClassic:     EQU     $4000
    ; actually in current v1.17.0 this will still receive "page 5" page based
    ; on the current memory mapping and the address value, but in docs it's
    ; described as "irrelevant". This test is documenting the behaviour for
    ; the sake of the test, not making it official/guaranteed, avoid using it

equWithPage:    EQU     $4001  ,  1

    ASSERT $8000 == regular && 2 == $$regular
    ASSERT $4000 == equClassic && 5 == $$equClassic
    ASSERT $4001 == equWithPage && 1 == $$equWithPage

errorEqu1       EQU     $4002 ,
errorEqu2       EQU     $4003 , @
