    MODULE xxx
Kip:                ; label xxx.Kip
    ld  hl,@Kip     ; global Kip
    ld  hl,@Kop     ; global Kop
    ld  hl,Kop      ; xxx.Kop
Kop:                ; label xxx.Kop
    ld  hl,Kip      ; xxx.Kip
    ld  hl,yyy.Kip  ; yyy.Kip
    ld  hl,nested.Kip   ; xxx.nested.Kip
        MODULE nested
Kip:        ret     ; label xxx.nested.Kip
        ENDMODULE
    ENDMODULE

    MODULE yyy
Kip:    ret         ; label yyy.Kip
@Kop:   ret         ; label Kop (global one, no module prefix)
@xxx.Kop: nop       ; ERROR: duplicate: label xxx.Kop
    ENDMODULE

Kip     ret         ; global label Kip

    ; invalid since v1.14.0
        MODULE older.version
fn1:        ret        ; final label: @older.version.fn1
        ENDMODULE
    ; can be replaced in v1.14.0 with
        MODULE new
            MODULE version
fn1:            ret    ; final label: @new.version.fn1
            ENDMODULE
        ENDMODULE
    ; or you can just rename "older.version" to something like "older_version" instead

Kep:    ; "Kep" label (global one), and also works as "non-local" prefix for local labels
    MODULE zzz
.local: ; in v1.14.0 this will be "zzz._.local" label, previously it was "zzz.Kep.local"
Kup:    ; this is "zzz.Kup", but also defines "non-local" prefix as "Kup"
.local  ; this is "zzz.Kup.local"
    ENDMODULE
.local: ; in v1.14.0 this will be "_.local" label, previously it was "Kup.local"
