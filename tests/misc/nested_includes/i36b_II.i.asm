INC_DEPTH=INC_DEPTH+1 : IF INC_DEPTH < 7 : INCLUDE "i36b_II.i.asm" : ENDIF
    ld  b,INC_DEPTH : DUP INC_DEPTH : rra
    nop : ret
    daa : EDUP : scf
INC_DEPTH=INC_DEPTH-1