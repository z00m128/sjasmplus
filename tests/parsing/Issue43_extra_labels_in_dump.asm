    ORG 0x8000

    MODULE ma
lb: equ 6
    nop
    ld a,lb
    ld a,ma.lb
    ld a,lb2
    ld a,ma.lb2
lb2=8
    ENDMODULE
