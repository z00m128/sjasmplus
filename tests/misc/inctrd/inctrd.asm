    OUTPUT "inctrd.bin"

    INCTRD "inctrd/inctrd.trd","testfile.C"
    INCTRD "inctrd/inctrd.trd","testfile.C",0,7
    INCTRD "inctrd/inctrd.trd","testfile.C",7
    INCTRD "inctrd/inctrd.trd","testfile.C",0,1
    INCTRD "inctrd/inctrd.trd","testfile.C",1,5
    db "\n" ; add <EOL> to make the "bin" simpler to edit in text editor

    OUTEND
