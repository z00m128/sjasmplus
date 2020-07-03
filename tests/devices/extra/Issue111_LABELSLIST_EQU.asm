    DEVICE  NONE

NONE_EQU    EQU     $1234
NONE_EQU2   EQU     $DEF0

    DEVICE  zxspectrum128

ADDR0_8000  EQU     $8000   ; expecting 02:0000
ADDR0_0     EQU     0       ; expecting :0000
ADDR0_C000  EQU     $C000   ; expecting 00:0000

    PAGE    3

ADDR3_8000  EQU     $8000   ; expecting 02:0000
ADDR3_0     EQU     0       ; expecting :0000
ADDR3_C000  EQU     $C000   ; expecting 03:0000

OTHER_EQU   EQU     $10000

PagesTab:
        DB  $$ADDR3_8000, $$ADDR3_0, $$ADDR3_C000, $$OTHER_EQU, $$PagesTab

    ORG     $C000

ORG_ADR:
ORG_ADR_EQU EQU     $8000

OTHER_EQU2  EQU     $10000

        DB  $$ORG_ADR, $$ORG_ADR_EQU, $$OTHER_EQU2

    LABELSLIST "Issue111_LABELSLIST_EQU.lbl"
