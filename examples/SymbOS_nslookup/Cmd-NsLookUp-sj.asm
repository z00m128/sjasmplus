; define substitutions for directives which have different name in WinAPE
    DEFINE write OUTPUT
    DEFINE READ INCLUDE
    DEFINE nolist OPT listoff

; reconfigure the sjasmplus to a bit stricter syntax with extra warnings
; and enable directives at the beginning of the line (--dirbol)
    OPT --syntax=abfw --dirbol

; include original "head" file which will produce the com file
    INCLUDE "src/Cmd-NsLookUp-head.asm"
