    INCLUDE "sj_sysvars.i.asm"

    ORG     $8000
    ; direct access to sysvar
    ld      a,(SYSVARS.LAST_K)
    ld      hl,(SYSVARS.DEST)
    ; IY access to sysvar
    ld      a,(iy+IY_VARS.LAST_K)
    ld      hl,(iy+IY_VARS.DEST)    ; fake instruction
