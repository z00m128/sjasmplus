    INCBIN "data.bin"           ; should include "B" from current dir
    INCBIN <data.bin>           ; should include "b" from 229bininc/ sub-dir (because of include paths)

    INCHOB "data.hob", 0, 1     ; "H"
    INCHOB <data.hob>, 0, 1     ; "h"

    INCTRD "data.trd", "f.C"    ; "T"
    INCTRD <data.trd>, "f.C"    ; "t"
