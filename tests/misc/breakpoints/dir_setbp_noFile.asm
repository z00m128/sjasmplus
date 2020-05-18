    DEVICE NONE
    BPLIST "dir_setbp_noFile.exp" zesarux  ; not in DEVICE mode

    DEVICE ZXSPECTRUM48
    BPLIST "" invalid_type  ; empty filename, invalid type

    SETBREAKPOINT $     ; ok ; warning suppressed
    SETBREAKPOINT $     ; warning about no file
