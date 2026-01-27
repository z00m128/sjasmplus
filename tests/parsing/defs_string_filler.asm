; Test for Issue #149: Optional string-filler for DEFS directive
; Tests operand parsing with mixed types, overflows, and device modes

; ===== PIPE MODE (DEVICE NONE) =====
    DEVICE NONE : ORG $2000

; Case 1: DEFS without operands (default fill 0x00)
    DEFS 5

; Case 2: DEFS with single numeric operand (backward compat: DEFS 5, 0x42)
    DEFS 5, 0x42

; Case 3: DEFS with string operand (filler is 'B')
    DEFS 5, "AB"

; Case 4: DEFS with suffixed string operand (filler is zero)
    DEFS 10, "AB"Z

; Case 5: DEFS with mixed operands (filler is 3)
    DEFS 10, 1, 2, 'x', 3

; Case 6: DEFS with exact-fit operands (no implicit fill)
    DEFS 3, 0x11, 0x22, 0x33

; Case 7: DEFS with 129-byte operand list (tests GetBytes 128-byte limit)
; This should trigger GetBytes error "Over 128 bytes defined..." and init values are truncated to 128 bytes, but total fill is 150 bytes as specified
    DEFS 150, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@"

; Case 8: DEFS with operands exceeding DEFS size, warns and truncates init data to length 3
    DEFS 3, 1, 2, 3, 4, 5, 6

; Case 8b: suppress truncation warning
    DEFS 3, 1, 2, 3, 4, 5, 6    ; shortblock-ok

; Case 9: DEFS with string and numeric overflow ("AB" is used, rest is truncated)
    DEFS 2, "ABC", 0x44

; ===== DEVICE MODE (NOSLOT64K) =====
    DEVICE NOSLOT64K : ORG $4000

; Case 10: DEFS without operands
    DEFS 5

; Case 11: DEFS with mixed operands
    DEFS 10, 1, 'x', 3

; Case 12: DEFS with exact-fit operands
    DEFS 3, 0x11, 0x22, 0x33

; Case 13: DEFS with operands exceeding size
    DEFS 3, 1, 2, 3, 4, 5, 6

; Case 13b: suppress warning
    DEFS 3, 1, 2, 3, 4, 5, 6    ; shortblock-ok

; Case 14: DEFS with invalid data (truncating value warning)
    DEFS 16, 1, 256, 3, 4, 5, 6

; Examples from Issue #149
  DEFS 10, "name_1st"Z  ; -> 6e 61 6d 65 5f 31 73 74 00 00 (filler zero)
  DEFS 10, "name_2"     ; -> 6e 61 6d 65 5f 32 32 32 32 32 (filler '2')
  DEFS 10, "name_3 "    ; -> 6e 61 6d 65 5f 33 20 20 20 20 (filler space)
  DEFS 10, 1, 'x', 3    ; -> 01 78 03 03 03 03 03 03 03 03 (filler 3)
