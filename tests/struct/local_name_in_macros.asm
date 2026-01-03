; local struct names inside macros are not supported, not even non-macro local ones with "@" prefix
; this is just exercising the errors reported when such construct is attempted
; (doesn't even have specific error messages, it's just documenting what happens in current implementation)

MACRO_STRUCT_1      MACRO init_value?
                        STRUCT @.Data               ; <- FAILS, non-macro-local struct names are NOT supported
Mx1L                        BYTE    init_value?
Mx2L                        BYTE    (init_value?) + 1
                        ENDS
MacroD1                 .Data
                    ENDM
        MACRO_STRUCT_1  $40                    ; trigger the failure
        ; ^ IMHO you are complicating it too much if you need this feature, maybe you can refactor sjasmplus internals then...

MACRO_STRUCT_LOCAL  MACRO init_value?
                        STRUCT .Data                ; <- FAILS, macro-local struct names are NOT supported (and not planned)
Mx1L                        BYTE    init_value?
Mx2L                        BYTE    (init_value?) + 1
                        ENDS
MacroDf                 .Data
                    ENDM
        MACRO_STRUCT_LOCAL   $40                    ; trigger the FATAL failure
        ; no more code below gets assembled
