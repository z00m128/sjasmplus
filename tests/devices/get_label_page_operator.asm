    DEVICE ZXSPECTRUM128
    MMU 0 3, 4
    ORG     0x4000-2
orgL1:
.local:
    ASSERT  4 == $$.local
    DISP    0xC000-1
dispL1:
    ASSERT  4 == $$orgL1 && 4 == $$     ; label and page in 0000-3FFF is 4
    ASSERT  6 == $$dispL1               ; dispL1 page is taken from current mapping
    ; also the CSpect export of displaced labels is sort of "bogus", affected by this
    set     5,(ix+0x41)     ; 4B opcode across both ORG and DISP boundaries
    ENT
orgL1end:
    ASSERT  5 == $$orgL1end && 5 == $$  ; label and page in 4000-7FFF is 5

    ; exercise the label parsing/evaluation, line parsin
    ASSERT  4 == $$orgL1.local && 4 == $$@orgL1.local && 1
    ASSERT  -1 == $$MissingLabel && 1
    ASSERT  $$ == $$..invalidLabelName  ; parsing breaks completely, evaluating only first part

    ;; exercise macro nesting and reaching out for labels
TM  MACRO   expPageOuter?, expPage1?, expPage2?, recursion?
        ASSERT  expPageOuter? == $$.outer
        ASSERT  expPageOuter? == $$MacroNestingAndReaching.outer
        ASSERT  expPageOuter? == $$@MacroNestingAndReaching.outer
        IF recursion?
            ASSERT  expPage1? == $$.inner
            TM expPageOuter?, expPage1?, expPage2?, 0
        ELSE
            ASSERT  expPage2? == $$.inner
        ENDIF
.inner:
        nop
    ENDM

    ORG $7FFF
MacroNestingAndReaching:
    ; MacroNestingAndReaching.outer = $8001, 0>inner = $8000, 1.0>inner = $7FFF
    TM      6, 6, 5, 1
.outer:

    CSPECTMAP "get_label_page_operator.sym"
