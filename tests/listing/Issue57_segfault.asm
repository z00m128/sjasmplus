; label as macro name (new in v1.13.1) triggers segfault with "--sym=..." option
LabelAsMacroName    MACRO  arg1?, arg2?
                        ld  a,arg1?
                        ld  hl,arg2?
                    ENDM

                LabelAsMacroName 1,$1234

SomeRegularLabel:   nop
