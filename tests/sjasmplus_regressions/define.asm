        device zxspectrum128

        org #8000
        
        DEFINE Scalar db 1
        DEFARRAY Array,db 2,db 3,db 4
        
        Scalar
        Array[3]
        Array[2]
        Array[1]
        Array[0]
        Array

; original test has invalid syntax of DEFARRAY (by Docs definition), when "fixed":
        DEFARRAY Array2 db 2,db 3,db 4
        Array2[3]
        Array2[2]
        Array2[1]
        Array2[0]
        Array2
