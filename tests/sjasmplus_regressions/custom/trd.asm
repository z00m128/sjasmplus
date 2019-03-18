        device zxspectrum128
        
        org #8000
label1  db 'text1'
        org #8100
label2  db 'text2'
        org #8200
label3  db 'text3'
end

        EMPTYTRD trd.trd
        SAVETRD "trd.trd","label1.txt",label1,5
        SAVETRD "trd.trd","label2.txt",label2,5
        SAVETRD "trd.trd","label3.txt",label3,5
        SAVETRD "trd.trd","label2.txt",label2,5

        SAVEHOB "trd.$t","labels.txt",label1,end-label1

; TODO add some check to validate resulting files
