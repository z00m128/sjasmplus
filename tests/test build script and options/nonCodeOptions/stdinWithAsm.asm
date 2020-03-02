; this source will be assembled twice, once coming from STDIN, second time as regular file
; and each time it will also include itself as include file (so 6x times assembled)

    IFNDEF  __ALREADY_INITIALIZED__
        DEFINE __ALREADY_INITIALIZED__
        OUTPUT "stdinWithAsm.bin"
x = 0
    ENDIF

    IFNDEF __INCLUDED__
        DEFINE __INCLUDED__
        INCLUDE "stdinWithAsm.asm"
        UNDEFINE __INCLUDED__
    ENDIF

x = x+1

    DB x
