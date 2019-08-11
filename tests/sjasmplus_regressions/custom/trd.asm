;Note: the input TR-DOS filenames in this test are incorrect, and will be currently truncated as 'label1.txt' -> 'label1.t'. Change this if needed.
;A TR-DOS filename is max. 8 characters, with a single-character extension. http://zx-modules.de/fileformats/hobetaformat.html

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

    ; some more syntax error tests for better code coverage
        SAVEHOB "trd.$t"
        SAVEHOB "trd.$t",
        SAVEHOB "trd.$t",,
        DEVICE NONE
        SAVEHOB "trd.$t","labels.txt",label1,end-label1
        EMPTYTRD
        SAVETRD "trd.trd","label1.txt",label1,5
