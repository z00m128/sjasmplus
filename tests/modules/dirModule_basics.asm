    OPT --syntax=abfw
        MODULE module1
Fn1:        ret

            MODULE nestedModule
; check labels composing after MODULE
.localWithoutNonLocal1:
Fn1.n:          ldir
.local1:
@GlobalLabel1:
.localAfterGlobal1:     ; GlobalLabel1.localAfterGlobal1
            ENDMODULE

            MODULE nested.Invalid.Name
Fn1.nin         cpl
            ; ENDMODULE  (not needed, because the module was not created)

        ENDMODULE

; check labels composing after ENDMODULE
.localWithoutNonLocal2:
NonLocal2:
.local2:

        ; some error states
        MODULE 1nvalid name
Fn1nvalid:  daa
        ENDMODULE

        MODULE missingEndModule
Fn2:        nop
