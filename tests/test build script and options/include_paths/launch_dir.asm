    ; check if CWD (LaunchingDirectory) is implicit include path
    OUTPUT "launch_dir.bin"
    ORG ' '
    DB  '"'
    INCLUDE "launch_dir/1/launch_dir_a.i.asm"
    INCLUDE "launch_dir/1/launch_dir_b.i.asm"
    INCLUDE "launch_dir/2/launch_dir_b.i.asm"
    DB  '"'
    DB  10
    ORG ' '
    DB  "<"
    INCLUDE <launch_dir/1/launch_dir_a.i.asm>
    INCLUDE <launch_dir/1/launch_dir_b.i.asm>
    INCLUDE <launch_dir/2/launch_dir_b.i.asm>
    DB  ">"
    DB  10
    OUTEND
