    IFNDEF MAIN_FILE
        DEFINE MAIN_FILE
        OUTPUT "predefined_include_level.bin"
myIncludeLevel = 0
    ENDIF

    ; before another INCLUDE
    ASSERT __INCLUDE_LEVEL__ == myIncludeLevel
    DB __INCLUDE_LEVEL__, myIncludeLevel

    IF myIncludeLevel < 6
myIncludeLevel = myIncludeLevel + 1
        INCLUDE "predefined_include_level.asm"
myIncludeLevel = myIncludeLevel - 1
    ENDIF

    ; after another INCLUDE
    ASSERT __INCLUDE_LEVEL__ == myIncludeLevel
    DB __INCLUDE_LEVEL__, myIncludeLevel
