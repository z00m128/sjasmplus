        device zxspectrum128
        OUTPUT test.bin

        org #0          ; since v1.12.0 ROM area is by default mapped as Page 7
label0  ld hl,$         ; so label0 will emit 07:0000 into labelslist file
        jp label0       ; for old ":0000" output it would need some fake "ROM Page"

        org #4000
label1  ld hl,$
        jp label1

        org #8000
label2  ld hl,$
        jp label2

        org #c000
label3  ld hl,$
        jp label3

        org #d000,1
label4  ld hl,$
        jp label4

        LABELSLIST test.lbl
