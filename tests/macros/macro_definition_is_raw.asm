    DEFINE+ mymacro defmacro
    DEFINE+ myarg defarg
    MACRO mymacro myarg
        ld hl,myarg
    ENDM

; **BEFORE** v1.24.0 the definition itself was substituted and body of macro was stored raw, so:
    ; MACRO defmacro defarg
    ;     ld hl,myarg
    ; ENDM
; the emit A001 worked because emit was substituted fully (both emit and body)
; the emit A002 failed on `ld hl,myarg`, because macro arg name was `defarg`, but body contains `myarg`
; the emit A003 and A004 failed on `Unrecognized instruction: mymacro` because `defmacro` was defined

; since v1.24.0 the definition of MACRO is now protected from substitution, the `MACRO` keyword stops
; substitution for remaining part of line, so this is defined:
    ; MACRO mymacro myarg
    ;     ld hl,myarg
    ; ENDM
; the emit A001 and A002 now fails on unrecognized instruction `defmacro` (no such macro defined)
; the emit A003 works with value 0xA003 as intended
; the emit A004 works with value 0xA004 b/c macro arg `myarg`->0xA004 has higher priority than define `myarg`

    mymacro 0xA001          ; substitution defines: mymacro->defmacro and myarg->defarg
    UNDEFINE myarg
    mymacro 0xA002          ; substitution define: mymacro->defmacro
    UNDEFINE mymacro
    mymacro 0xA003          ; no substitution at all
    DEFINE+ myarg defarg
    mymacro 0xA004          ; substitution define: myarg->defarg

; WARNING, the macro definition using name of macro ahead like "label" will have the name substituted!
; the argument names in definition will be NOT substituted, as they are protected by the `MACRO` keyword

    DEFINE+ labmacro d2macro
    DEFINE+ myarg defarg

labmacro MACRO myarg
        ld hl,myarg
    ENDM
; so this was defined here:
    ; d2macro MACRO myarg
    ;         ld hl,myarg
    ;     ENDM

    labmacro 0xB001         ; substitutions saves the day and emits macro `d2macro`
    UNDEFINE labmacro
    labmacro 0xB002         ; unrecognized instruction, the macro was defined as d2macro
    d2macro  0xB003         ; emitting `d2macro` directly
    ; all this time define `myarg` exists and doesn't change result as inside macro it has lower priority
