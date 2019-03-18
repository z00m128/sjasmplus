        device zxspectrum128
; options were modified to save --sym=test.tap as TAP to get binary diff in CI tests
; the BIN is also tested. Remaining outputs are NOT tested.
; TODO modify CI script to handle even these more exotic tests with custom checks
        OUTPUT test.bin

        org #0
label0  ld hl,$
        jp label0

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
