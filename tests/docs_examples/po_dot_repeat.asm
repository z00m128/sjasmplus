 .3        INC A    ;will be compiled to INC A:INC A:INC A
len        EQU 10
 .(12-len) BYTE 0   ;will be compiled to BYTE 0,0
 .2 .3     RET      ;will be compiled to 6x RET
