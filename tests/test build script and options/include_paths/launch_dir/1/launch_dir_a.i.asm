    DB  "1/a"
    IF __INCLUDE_LEVEL__ < 2
        DB  '.'
        INCLUDE "launch_dir_a.i.asm"    ; should find "1/a" in current dir
    ELSE
        DB  '.'
        INCLUDE "launch_dir_b.i.asm"    ; should find "1/b" variant in current dir
    ENDIF