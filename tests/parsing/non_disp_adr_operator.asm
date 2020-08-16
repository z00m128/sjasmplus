;; DEVICE + DISP case
    DEVICE ZXSPECTRUM1024
    SLOT 2 : ORG $8000, 2 : DISP $A000, 3
        ; inside DISP block displaced to fake $A000 and page 3
        ; machine code landing to $8000 and page 2 (physically)
dispAdr     EQU     $
dispPage    EQU     $$
noDispAdr   EQU     $$$     ; (!) this symbol has still "page" set to 3 (disp page)
noDispPage  EQU     $$$$    ; you must use `$$$$` operator to extract non-disp page
    ENT

    ASSERT $A000 == dispAdr
    ASSERT 3 == $$dispAdr
    ASSERT 3 == dispPage
    ASSERT $8000 == noDispAdr
    ASSERT 2 == noDispPage

    ; "2 == $$noDispAdr" would be more logical, but impossible to implement in simple way
    ASSERT 3 == $$noDispAdr

;; NO_DEVICE + DISP
    DEVICE NONE
    ORG $C000 : DISP $E000
        ; inside DISP block displaced to $E000, machine code landing to $C000
        ; no pages, because no virtual device is used
dispAdr2    EQU     $
dispPage2   EQU     $$      ; error: unexpected "$"
noDispAdr2  EQU     $$$
noDispPage2 EQU     $$$$
    ENT

    ASSERT $E000 == dispAdr2
    ASSERT $C000 == noDispAdr2
    ASSERT -1 == noDispPage2

;; NO_DEVICE + NO_DISP
    ORG $4000
        ; NO disp block, no DEVICE block
dispAdr3    EQU     $
dispPage3   EQU     $$      ; error: unexpected "$"
noDispAdr3  EQU     $$$     ; error: unexpected "$$"
noDispPage3 EQU     $$$$    ; error: unexpected "$$$"

    ASSERT $4000 == dispAdr3

;; DEVICE + NO_DISP
    DEVICE ZXSPECTRUM1024
    SLOT 1 : ORG $6000, 4
        ; inside DISP block displaced to fake $A000 and page 3
        ; machine code landing to $8000 and page 2 (physically)
dispAdr4    EQU     $
dispPage4   EQU     $$
noDispAdr4  EQU     $$$     ; error: unexpected "$"
noDispPage4 EQU     $$$$    ; error: unexpected "$$"

    ASSERT $6000 == dispAdr4
    ASSERT 4 == $$dispAdr4
    ASSERT 4 == dispPage4

;;;; extended test/example after explicit ",pageNum" was added to EQU mechanics

;; DEVICE + DISP case
    DEVICE ZXSPECTRUM1024
    SLOT 2 : ORG $8000, 2 : DISP $A000, 3
nda1        EQU     $$$,$$$$    ; this symbol has now page 2 (not disp page 3)
    ENT

    ASSERT $8000 == nda1
    ASSERT 2 == $$nda1

;; NO_DEVICE + DISP
    DEVICE NONE
    ORG $C000 : DISP $E000
nda2        EQU     $$$,$$$$    ; extended example after adding explicit ",pageNum" to EQU
    ENT

    ASSERT $C000 == nda2
    ASSERT $$nda2               ; error: "unexpected $nda2", $$label is disabled w/o device

;; NO_DEVICE + NO_DISP
    ORG $4000
nda3        EQU     $$$,$$$$    ; error: "unexpected $$,$$$$"

;; DEVICE + NO_DISP
    DEVICE ZXSPECTRUM1024
    SLOT 1 : ORG $6000, 4
nda4        EQU     $$$,$$$$    ; error: "unexpected $,$$$$"
