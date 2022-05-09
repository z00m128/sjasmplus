; test include paths on command line and their priorities:
; includeSSSS_.asm = +include paths "includeSSSS_i", "includeSSSS_v"
; ^^ testing also error when some include is not found

    INCLUDE includeSSSS_all.i.asm

    INCLUDE <includeSSSS_all.i.asm>

    INCLUDE <missing_file>

    ASSERT 0 == __INCLUDE_LEVEL__
    rst 0
