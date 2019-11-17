    IFNDEF included
        DEFINE included
        ; these will be now converted to "/" on any platform
        ; as windows `fopen` implementation should accept also "/"
        OUTPUT ".\include_paths_in_linux.bin"
        INCLUDE ".\include_paths_in_linux.asm"
        INCBIN ".\include_paths_in_linux.asm", 4, 1

        ; the correct "/" paths should of course work any way
        INCLUDE "./include_paths_in_linux.asm"
        INCBIN "./include_paths_in_linux.asm", 4, 1

        ASSERT 4 == $
    ENDIF

    inc sp
    ASSERT 1 == $ || 3 == $ || 5 == $
