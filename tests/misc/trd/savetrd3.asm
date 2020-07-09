    ; test data SAVETRD <TRDname>,&<Filename>,<start>,<lenght>
    DEVICE ZXSPECTRUM128 : ORG $C000, 7 : db "page 7" : ORG $C000, 6 : db "page 6" : ORG $C000, 3 : db "page 3"

    EMPTYTRD "savetrd3.trd"      ;create empty TRD image

    PAGE 7 ;set 7 page to current slot
    SAVETRD "savetrd3.trd",&"file0.C",$C000,$4000  ; error - not file for addition data

    SAVETRD "savetrd3.trd","file1.C",$C000,$4000   ; save file 1
    PAGE 6 ;set 6 page to current slot
    SAVETRD "savetrd3.trd","file2.C",$C000,$4000   ; save file 2
    PAGE 3 ;set 3 page to current slot
    SAVETRD "savetrd3.trd","file3.C",$C000,$4000   ; save file 3

    SAVETRD "savetrd3.trd",&"file1.C",$C000,8     ; add 1 sector to file 1
    PAGE 7 ;set 7 page to current slot
    SAVETRD "savetrd3.trd",&"file2.C",$C000,380   ; add 2 sector to file 2
    PAGE 6 ;set 6 page to current slot
    SAVETRD "savetrd3.trd",&"file3.C",$C000,$4000   ; add 64 sector to file 3

    SAVETRD "savetrd3.trd",&"file1.C",$C000,$4000,10     ; error - not autostart used here

    ; on trd: file1.C = 65 sec. , file2.C = 66 sec. , file3.C = 128 sec.