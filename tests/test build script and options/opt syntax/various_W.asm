; various -W<warning_id> combinations (hopefully all of them, if possible)

; the default is "enabled" for all warnings
abs:
    ld hl,abs
    DEVICE ZXSPECTRUMNEXT, $8000
    DEVICE NOSLOT64K, $8000
    DEVICE ZXSPECTRUM48, $8000 : DEVICE ZXSPECTRUM48, $8001

; disable/enable specific warning and test specific-suppression in eol comment

    ; abs
    OPT -Wno-abs
    ld hl,abs
    OPT -Wabs
    ld hl,abs   ; devramtop-ok - some other id, should not suppress abs
    ld hl,abs   ; but abs-ok should suppress it

    ; impossible to re-test zxnramtop and noslotramtop, because they are emitted just once

    ; devramtop
    OPT -Wno-devramtop
    DEVICE ZXSPECTRUM48, $8000 : DEVICE ZXSPECTRUM48, $8001
    OPT -Wdevramtop
    DEVICE ZXSPECTRUM48, $8000 : DEVICE ZXSPECTRUM48, $8001 ; abs-ok - some other id, should not suppress abs
    DEVICE ZXSPECTRUM48, $8000 : DEVICE ZXSPECTRUM48, $8001 ; but devramtop-ok should suppress it
