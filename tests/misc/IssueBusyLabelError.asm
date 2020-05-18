    MODULE t1
    DEVICE  ZXSPECTRUM48
    org     #4000
    disp    #FFFF
zac     db      #11
        db      #22
len = $-zac
    ENT
    ENDMODULE

    MODULE t2
    DEVICE  NONE
    org     #4000
    disp    #FFFF
zac     db      #11
        db      #22
len = $-zac
    ENT
    ENDMODULE

    MODULE t3
    DEVICE  ZXSPECTRUM48
    org     #FFFF
zac     db      #11
        db      #22
len = $-zac
    ENDMODULE

    MODULE t4
    DEVICE  NONE
    org     #FFFF
zac     db      #33
        db      #44
len = $-zac
    ENDMODULE
