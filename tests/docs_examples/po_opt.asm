    POP bc, hl   ; pops BC first
    OPT push reset --reversepop --syntax=af
    POP bc,,hl   ; pops HL first
    LD  bc,hl    ; warning about Fake instruction
    LD  bc,hl    ; warning supressed by lowercase "fake" in this comment
    OPT reset --syntax=a
    POP bc,,hl   ; pop BC first (--reversepop was reset)
    OPT pop      ; restoring syntax to original state
