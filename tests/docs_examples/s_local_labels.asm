    ORG 0x8000
    MODULE main             ; module "main"
Main:                       ; main.Main
        CALL SetScreen      ; SetScreen
        CALL vdp.Cls        ; main.vdp.Cls
.loop:                      ; main.Main.loop
        LD A,(.event)       ; main.Main.event
        CALL ProcessEvent   ; label not found: main.ProcessEvent
        DJNZ .loop          ; main.Main.loop

        MODULE vdp          ; module "main.vdp"
@SetScreen:                 ; SetScreen
.loop:                      ; main.vdp.SetScreen.loop
            RET
Cls:                        ; main.vdp.Cls
!KeepClsForLocal:           ; main.vdp.KeepClsForLocal (since v1.18.0)
.loop:      DJNZ .loop      ; main.vdp.Cls.loop
            RET
        ENDMODULE

Main.event DB 0             ; main.Main.event
    ENDMODULE
