    DEVICE  zxspectrum128

    ; check syntax error report for virtual labels argument
    LABELSLIST "PR122_LABELSLIST_virtualAdr.lbl", @

        ORG 0
ADR_0:      ; at ROM addresses the "bank 7" is paged in ZX128 device, so page 7
ADR_1       EQU     $FEDC, 2    ; force page 2 to the label ADR_1
ADR_2       EQU     $1FEDC, 3   ; out of 64ki range, and page 3
ADR_3       EQU     -123        ; "out of bounds" page

        ; verify that labels have the designed pages
        ASSERT 7 == $$ADR_0
        ASSERT 2 == $$ADR_1
        ASSERT 3 == $$ADR_2
        ASSERT 8 <= $$ADR_3     ; "out of bounds" is currently $7F80, but that may change in future, just check for >= 8

    ; emit labelslist with "virtual labels", so:
    ; * the page info should be not listed at all
    ; * the values are truncated to full 64ki range
    LABELSLIST "PR122_LABELSLIST_virtualAdr.lbl", 1

/*
;;;; the expected output is (no pages, 64ki range):

:0000 ADR_0
:FEDC ADR_1
:FEDC ADR_2
:FF85 ADR_3


;;;; without virtual labels the output would look like this (pages + truncated to 16ki range)

07:0000 ADR_0
02:3EDC ADR_1
03:3EDC ADR_2
:3F85 ADR_3

*/
