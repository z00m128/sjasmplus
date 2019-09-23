;; options used to assemble this test:
;; sjasmplus --fullpath --nologo --lst="struct_in_files.lst" --lstlab --msg=war "struct_in_files.asm" --zxnext=cspect
        INCLUDE "struct_in_files.def.s1.i.asm"
        INCLUDE "struct_in_files.def.s2.i.asm"
        INCLUDE "struct_in_files.def.s12.i.asm"

        DEVICE ZXSPECTRUMNEXT
        ORG $4000

        INCLUDE "struct_in_files.use.s1.i.asm"
        INCLUDE "struct_in_files.use.s2.i.asm"
        INCLUDE "struct_in_files.use.s12.i.asm"

    MODULE  modMain
        STRUCT @struct_1_2_12
s1          struct_1    { 0, 0 }
s2:         @mod2.struct_2   { $A4, $A5, $A6 }
s12:        struct_12
        ENDS
    ENDMODULE

    MODULE modNonMain
xyz:    struct_1_2_12
abc:    struct_1_2_12 = $9000
def:    @struct_1_2_12
ghi:    @struct_1_2_12 = $9100
jkl:    @struct_1_2_12 { 1, 2 { 3, 4 } }
    ENDMODULE
