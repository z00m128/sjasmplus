;Note: the sjasmplus now supports the unofficial 3 letter extensions as described by Dart_Alver
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
        SAVETRD "trd.trd","label1.txt",label1,5     ; new warnings about 3-letter extension
        SAVETRD "trd.trd","label2.txt",label2,5
        SAVETRD "trd.trd","label3.txt",label3,5
        SAVETRD "trd.trd","label4.txt",label2,5     ; ok ; warning suppressed
    ; test the "invalid extension warning" and if it can be suppressed
        SAVETRD "trd.trd","label2.B",label2,5       ; no warning
        SAVETRD "trd.trd","label2.J",label2,5       ; warning
        SAVETRD "trd.trd","label3.J",label2,5       ; ok ; warning suppressed
    ; test the new warning about saving same file second time (v1.15.1+)
        SAVETRD "trd.trd","label2.B",label2,5       ; warning
        SAVETRD "trd.trd","label2.B",label2,5       ; ok ; warning suppressed

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
