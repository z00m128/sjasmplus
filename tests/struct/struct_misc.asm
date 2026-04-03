    IFNDEF INCLUDED_ONCE
        DEFINE INCLUDED_ONCE
        INCLUDE "struct_misc.asm"

    ; instance defined structures (those which exist, which includes notEndedOne?!)
i1      name1
imod1   @mod1.name1
i2      name2
ie      notEndedOne
    ELSE

        STRUCT  name1
x           BYTE    100
        ENDS

        MODULE mod1
            STRUCT  name1
x               BYTE    101
            ENDS

            STRUCT  @name2
x               BYTE    102
            ENDS
        ENDMODULE

        STRUCT 1llegal name
        ENDS

        STRUCT @.
        ENDS

        STRUCT name3, &
        ENDS

        STRUCT  name1   ; error duplicate structure name
x           BYTE    $CC
        ENDS

        ; duplicate label may happen even when main struct name is unique
        MODULE whatever
            STRUCT name1
a               BYTE    104
            ENDS
        ENDMODULE
        STRUCT whatever
name1.a     BYTE    105 ; compounds into whatever.name1.a -> clash with previous struct
        ENDS
        STRUCT name1.x  ; clash with name1 struct element x from line 13
y           BYTE    106
        ENDS

        STRUCT notEndedOne
x           BYTE    103
    ENDIF
