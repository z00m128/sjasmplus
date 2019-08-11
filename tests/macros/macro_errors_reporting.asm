        MACRO

; label-named macros
LmP0    MACRO
            nop
        ENDM

LmP1    MACRO   arg1?
            DB arg1?
        ENDM

LmP2    MACRO   arg1?, arg2?
            DB arg1?, arg2?
        ENDM

; regular macro name syntax
        MACRO   mP0
            daa
        ENDM

        MACRO   mP1 arg1?
            DW arg1?
        ENDM

        MACRO   mP2 arg1?, arg2?
            DW arg1?, arg2?
        ENDM

; try to emit macros (also with wrong syntax/error cases)
        LmP0                    ; correct
        LmP1 111                ; correct
        LmP1 <112, 113, 114>    ; correct
        LmP2 121, 122           ; correct
        LmP2 123, <124, 125>    ; correct

        mP0                     ; correct
        mP1  161                ; correct
        mP1  <162, 163, 164>    ; correct
        mP2  171, 172           ; correct
        mP2  173, <174, 175>    ; correct

        LmP0 201
        LmP1
        LmP1 211, 212
        LmP2
        LmP2 221
        LmP2 222, 223, 224

        mP0  251
        mP1 
        mP1  261, 262
        mP2 
        mP2  271
        mP2  272, 273, 274
