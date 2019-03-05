; test include paths on command line and their priorities, there are multiple steps:
; luainc.asm       = no extra include path, should include from working directory
; luaincS.asm      = +include paths "luaincSSSS_v"
; luaincSS.asm     = +include paths "luaincSSSS_i"
; luaincSSS.asm    = +include paths "luaincSSSS_v", "luaincSSSS_i"
; luaincSSSS.asm   = +include paths "luaincSSSS_i", "luaincSSSS_v"

; The following code is intentionally mischievous and damaging assembling process, and
; the results of the assembling will very likely change in the future, as the work
; on consolidation of sjasmplus will continue, this is NOT example how to use lua scripts!
; it's more like anti-example, how to NOT use it.

    LUA PASS1
        pass = 0
    ENDLUA
    LUA ALLPASS
        pass = pass + 1
        sj.warning('Pass updated to ' .. pass .. ', device: ' .. sj.get_device())
    ENDLUA

    DEVICE ZXSPECTRUM1024

    ORG     $8000

    INCLUDELUA luaincSSSS.lua

loopyLoop:

    LUA ALLPASS
        inc_ld('A', pass + 10)
    ENDLUA

    INCLUDELUA <luaincSSSS.lua>

    call    forwardyLabelo

    LUA ALLPASS
        inc_ld('A', pass)
    ENDLUA

    jr  loopyLoop

forwardyLabelo:
    rst 0

    ds  stretchItEvenMore-forwardyLabelo-1, 201

    ALIGN 256
stretchItEvenMore:
    rst 16
