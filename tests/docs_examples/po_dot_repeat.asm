 .3        INC A    ;will be compiled to INC A:INC A:INC A
len        EQU 10
 .(12-len) BYTE 0   ;will be compiled to BYTE 0,0

 .4 .3 ret          ;will be compiled to 12x ret
