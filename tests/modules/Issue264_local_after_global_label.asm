    ORG $3210
    MODULE mod
abc:    nop
.local: nop     ; "mod.abc.local" defined here
@abc:   nop
.local: nop     ; "abc.local" | before v1.21.0: "mod.abc.local" = duplicate error
    ENDMODULE
    ASSERT $3210 == mod.abc
    ASSERT $3211 == mod.abc.local
    ASSERT $3212 == abc
    ASSERT $3213 == abc.local
