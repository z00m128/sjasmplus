    DB  '2/b['
    IF __INCLUDE_LEVEL__ < 2
        INCLUDE "launch_dir/1/launch_dir_a.i.asm"   ; launch dir is implicit include path by default
        INCLUDE <launch_dir/1/launch_dir_a.i.asm>   ; = makes *these two* work, should fail with: --inc
        INCLUDE "../1/launch_dir_a.i.asm"           ; relative path works from current file dir
        INCLUDE <../1/launch_dir_a.i.asm>
        INCLUDE "launch_dir_b.i.asm"                ; these should find "2/b" variant in current dir
        INCLUDE <launch_dir_b.i.asm>
    ENDIF
    DB  ']'