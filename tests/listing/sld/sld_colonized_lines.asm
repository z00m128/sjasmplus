    DEVICE  ZXSPECTRUMNEXT : nop : ORG $8000 : nop : MMU 0 7, 32
colonsTest1: nop : rla : rlca : rra : rrca : ret
colonsTest2: nop : rla : rlca : rra : rrca : ret     ; eol comment
 ::: ; just condenzed empty lines, shouldn't generate anything in SLD

mac1    MACRO   arg1
 ld a,arg1:ld b,arg1:ld c,b:ret nz
        ENDM

 djnz $:mac1 '!':jr $
