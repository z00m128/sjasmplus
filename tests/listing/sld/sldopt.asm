    DEVICE ZXSPECTRUMNEXT
    ORG $8000
        daa         ; some eol comments with keyword1 included
        nop         ; some eol comment without any keyword
; full line comment with keyword2 included (line without code)
; full line without any keyword, but wrong cased Keyword2 (SLD keywords are case sensitive)
label1: DB  1,"b",3 ; some keyword3 here
label2: DB  4,"e",6 ; keyword none here

    SLDOPT COMMENT keyword1, keyword2   ; SLDOPT is global directive
    SLDOPT comment keyword2, keyword3   ; and keywords could be added over multiple lines

        ret         ; some keyword1 also after SLDOPT specified (should not matter)
        nop         ; some eol comment without any keyword
    MMU 6, 100
    DISP 50000, 100
        cpl         ; keyword2 in displacement block (displaced address reported)
    ENT

        ORG 60000
    MACRO MEMGUARD
        defb 0  ; WPMEM keyword1
        nop     ; keyword3
    ENDM

    MEMGUARD
someData:   dw 1234
    MEMGUARD

    ; syntax error
    SLDOPT INVALID whatever
    SLDOPT COMMENT @@@  ; invalid keyword (must roughly fit rules of valid labels)
    SLDOPT COMMENT
    SLDOPT

    SLDOPT swapon       ; swap source pos <-> definition pos in SLD
    MEMGUARD
    SLDOPT swapoff      ; swap off
    MEMGUARD

    ; define some macro with swap on+off inside
    MACRO SWAPON_IN_MACRO
        SLDOPT swapon
        scf
        SLDOPT swapoff
    ENDM
    MACRO SWAPOFF_IN_MACRO
        SLDOPT swapoff
        ccf
        SLDOPT swapon
    ENDM
    MACRO NESTED_SWAPOFF
        SLDOPT swapon
        ld b,c
        SWAPOFF_IN_MACRO
        ld b,d
        SLDOPT swapoff
    ENDM

    ; swap off initially
    SWAPON_IN_MACRO     ; swap for scf
    NESTED_SWAPOFF      ; swap on -> off -> on
    SWAPOFF_IN_MACRO    ; swap off (2x inside)
    SWAPON_IN_MACRO     ; swap for scf (again to verify pairings)

    ; check external file and mismatched pairing warnings
    INCLUDE "sldopt.i.asm" : SLDOPT swapoff      ; fix include mismatch to known state
    ld h,e
    SWAPIN_OTHER_FILE
    SWAPON_MISMATCH
    ld h,h
    MEMGUARD            ; swap should be still on
    SWAPOFF_MISMATCH
    ld h,l
    MEMGUARD            ; swap should be still off

    SLDOPT swapon       ; mismatch main file as whole (deliberately NOT warning)

    ; check warning suppression
    SWAPOFF_MISMATCH_SUP
    SWAPON_MISMATCH_SUP
