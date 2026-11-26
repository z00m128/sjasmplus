    DEVICE ZXSPECTRUM128
    ORG $8000
    INCLUDE "unicode_paths_Тест 漢字/часть.i.asm"
    ASSERT UNICODE_INCLUDED == 1
    INCBIN "unicode_paths_Тест 漢字/данные.txt"
    INCLUDELUA "unicode_paths_Тест 漢字/скрипт.lua"
    LUA ALLPASS
        assert(UNICODE_LUA_VALUE == 201)
    ENDLUA
    SAVEBIN "unicode_paths_Тест 漢字/выход.bin", $8000, 2
#line 10 "unicode_paths_Тест 漢字/generated.asm"
    ASSERT $ == $8002