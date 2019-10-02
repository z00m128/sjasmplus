; test include paths on command line and their priorities, there are multiple steps:
; include.asm       = no extra include path, should include from working directory
; includeS.asm      = +include paths reset + "includeSSSS_v"
; includeSS.asm     = +include paths reset + "includeSSSS_i"
; includeSSS.asm    = +include paths reset + "includeSSSS_v", "includeSSSS_i"
; includeSSSS.asm   = +include paths reset + "includeSSSS_i", "includeSSSS_v"

    INCLUDE includeSSSS_all.i.asm

    INCLUDE <includeSSSS_all.i.asm>

    rst 0
