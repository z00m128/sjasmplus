    POP bc, hl   ; pops BC first
    OPT --reversepop --syntax=af
    POP bc,,hl   ; pops HL first
    LD  bc,hl    ; warning about Fake instruction
    LD  bc,hl    ; warning supressed by lowercase "fake" in this comment
    OPT --syntax=A
    POP bc `` hl ; pop BC first (--reversepop was reset)
    OPT : OPT    ; restoring syntax to original state (2x OPT without argument)
