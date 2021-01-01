; check sorting of labels, especially when labels differ only in case
        DEVICE ZXSPECTRUM128 : ORG $8000
; block 3. C
ccccC       rrca
ccCcc       rra
Ccccc       cpl
cCccc       ccf
ccccc       rlca

; block 2. B
bbbbB       rrca
bbBbb       rra
Bbbbb       cpl
bBbbb       ccf
bbbbb       rlca

; block 5. E
eeeeE       rrca
eeEee       rra
Eeeee       cpl
eEeee       ccf
eeeee       rlca

; block 1. A
aaaaA       rrca
aaAaa       rra
Aaaaa       cpl
aAaaa       ccf
aaaaa       rlca

; block 4. D
ddddD       rrca
ddDdd       rra
Ddddd       cpl
dDddd       ccf
ddddd       rlca

    ; unreal emulator export
    LABELSLIST "lstlab_sort.lbl"

    ; #CSpect map export
    CSPECTMAP "lstlab_sort.exp"

; --sym was not exporting symbols starting with non-alpha character, ie. underscore labels
; This seems rather bug than feature, so changed for v1.18.1
; (I guess the original test was to hide macro labels only, the ones starting with digit)
_underscoreLabel    nop
