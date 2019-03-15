    ;; defines to require multi define-substitution
    DEFINE _zzzzz _zzzz
    DEFINE _zzzz _zzz
    DEFINE _zzz _zz
    DEFINE _zz _z
    DEFINE _z hl

    MACRO xxx
        /* /*
        /* 3x nested
        block
        comment */ */
        */
        halt
    ENDM
/*  ld _zzzzz,0
/* 2x nested block comment
  assdada */ ld _zzzzz,0
/*
  ass dada */ ld _zzzzz,0
*/
    DUP /* inbetween arguments for DUP-macro */ 2
    ret/* some live code on block comment line
    zzz
    */ld  _zzzzz,0
    xxx     ; emit macro
    EDUP

    // similar test, but outside of DUP

  /* block1 */  cpl /* block2 */
    ret/*
    zzz
//  ;  '*/ld  _zzzzz,0
    xxx:ldi/* : */::ldd:ldir:/*:"*/:lddr

:   daa
/* END ... // : block comment */ : nop ; LIVE instr!
    /* invalid * * / amount of close blocks */ */ /* : */ : ; and no <EOL> here