    ; test data
    DEVICE ZXSPECTRUM128 : ORG $C000, 7 : db "page 7" : ORG $C000, 6 : db "page 6"

    EMPTYTRD "savetrd.trd"      ;create empty TRD image
    PAGE 7 ;set 7 page to current slot
    SAVETRD "savetrd.trd","myfile1.C",$C000,$4000
    PAGE 6 ;set 6 page to current slot
    SAVETRD "savetrd.trd","_myfile2.C",$C000,$201-4,$1234   ; test also "autostart" value
    SAVETRD "savetrd.trd","myfile3.C",$C001,$200-4,$1234    ; sector length test
    ; save the same file again (testing original behaviour before v1.13.2+)
    PAGE 7 ;set 7 page to current slot
    SAVETRD "savetrd.trd","myfile1.C",$C000,$100
