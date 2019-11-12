    OUTPUT "org.bin"

    DEVICE NONE
    ; no errors/warnings expected because of the --longptr option
    ORG $FFFF
longptr1:   DB      'A'
longptr2:   DB      'B'
longptr3:   DB      'C'

    DEVICE ZXSPECTRUM48
    ; the --longptr should NOT affect actual devices => errors will be reported
    ORG $FFFF
devbyte1:   DB      'a'
devbyte2:   DB      'b'     ; error crossing $10000 address boundary
devbyte3:   DB      'c'     ; silent after first error reported
