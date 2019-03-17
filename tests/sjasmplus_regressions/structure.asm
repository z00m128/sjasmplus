        device zxspectrum128
        
        struct str
f0      byte 0
f1      byte 0
        byte 0
        ends
        
        struct str1
        byte 0
f0      byte 0
        ends        
        
        module mod
        struct str
f0      word 0
f1      word 0
f2      word 0
        word 0
        ends

        ;offsets
        db str
        db str.f0
        db str.f1
        db str.f2
        
        db str1
        db str1.f0
        endmod        
        
        db str
        db str.f0
        db str.f1
        db mod.str
        db mod.str.f0
        db mod.str.f1
        db mod.str.f2

        ;usage
usestr  str 1,2,3
;EDITED: seems to work in v1.11 (original comment "TODO: fix structs usage without labels")
        str1 4,5
