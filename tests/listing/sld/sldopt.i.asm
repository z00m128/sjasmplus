    MACRO SWAPIN_OTHER_FILE
        SLDOPT swapon
        ld h,c
        SLDOPT swapoff
    ENDM

    MACRO SWAPON_MISMATCH
        SLDOPT swapon
        ld h,d
    ENDM

    MACRO SWAPOFF_MISMATCH
        SLDOPT swapoff
        ld h,d
    ENDM

    MACRO SWAPON_MISMATCH_SUP
        SLDOPT swapon
        ld (hl),c           ; sldswap-ok ; suppress warning
    ENDM

    MACRO SWAPOFF_MISMATCH_SUP
        SLDOPT swapoff
        ld (hl),d           ; sldswap-ok ; suppress warning
    ENDM

    SLDOPT swapon   ; mismatch include file as whole
