; The CHK macro causes a checksum to be computed and deposited at the current location.
; The starting point of the checksum calculation is indicated as an argument.
;
; The checksum is calculated as the simple arithmetic sum of all bytes starting
; at the provided address up to but not including the address of the CHK macro instance.
; The least significant byte is all that is used.
;
; The macro requires the virtual DEVICE memory (checksum needs access to previously
; defined machine code bytes).

; CHK macro definition
    MACRO .CHK address?
.SUM = 0                        ; init values for checksumming
.ADR = address? ASSERT address? < $   ; starting address must be below current
        DUP $ - address?        ; do simple sum of all bytes
.SUM = (.SUM + {.ADR})&$FF
.ADR = .ADR + 1
        EDUP
        DB      .SUM
    ENDM

; Examples and verification (ZX Spectrum 48 virtual device is used for the test)

    DEVICE ZXSPECTRUM48 : OUTPUT "sum_checksum.bin"
TEST1   DB      'A'
        .CHK    TEST1           ; expected 'A'

TEST2   DS      300, 'b'
        DB      'B' - ((300*'b')&$FF)   ; adjust checksum to become 'B'
        .CHK    TEST2           ; expected 'B'

TEST3   inc     hl              ; $23
        inc     h               ; $24
        .CHK    TEST3           ; expected 'G' ($47)
