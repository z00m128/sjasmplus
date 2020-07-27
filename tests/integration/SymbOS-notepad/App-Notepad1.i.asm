;nolist

    org #1000
    OUTPUT "SymbOS-notepad.bin" ; notepad.exe (renamed to trigger test-runner functionality)

    INCLUDE "SymbOS-Constants.i.asm"

    relocate_start

    INCLUDE "App-Notepad-head.i.asm"
    INCLUDE "App-Notepad-lib.i.asm"
    INCLUDE "App-Notepad.i.asm"

    relocate_table
    relocate_end
