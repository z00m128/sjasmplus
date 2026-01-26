; Test for Issue #149: Optional string-filler for DEFS directive
; Tests operand parsing with mixed types, overflows, and device modes

; ===== PIPE MODE (DEVICE NONE) =====
    DEVICE NONE

    ORG $0000

; Case 1: DEFS without operands (default fill 0x00)
test1
    DEFS 5

; Case 2: DEFS with single numeric operand (backward compat: DEFS 5, 0x42)
test2
    DEFS 5, 0x42

; Case 3: DEFS with string operand (no suffix: DEFS 5, "A")
test3
    DEFS 5, "A"

; Case 4: DEFS with longer suffixed string operand
test4
    DEFS 10, "AB"Z

; Case 5: DEFS with mixed operands (DEFS 10, 1, 'x', 3)
test5
    DEFS 10, 1, 'x', 3

; Case 6: DEFS with exact-fit operands (DEFS 3, 0x11, 0x22, 0x33)
test6
    DEFS 3, 0x11, 0x22, 0x33

; Case 7: DEFS with 129-byte operand list (tests GetBytes 128-byte limit)
; This should trigger GetBytes error "Over 128 bytes defined..."
test7
    DEFS 150, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@"

; Case 8: DEFS with operands exceeding DEFS size (DEFS 3, 1, 2, 3, 4, 5, 6)
; Expected for DEFS: emit 1, 2, 3; truncate 4, 5, 6; use last byte (3) as filler; error
test8
    DEFS 3, 1, 2, 3, 4, 5, 6

; Case 9: DEFS with string and numeric overflow (DEFS 2, "ABC", 0x44)
; Expected for DEFS: emit 'A', 'B'; truncate 'C', 0x44; use last byte ('B'=0x42) as filler; error
test9
    DEFS 2, "ABC", 0x44

; ===== DEVICE MODE (NOSLOT64K) ===== **** NEEDS UPDATE OF .LST FILE AFTER DEFS IS EXTENDED ****
    DEVICE NOSLOT64K

    ORG $4000

; Case 10: DEFS without operands (device mode)
test10
    DEFS 5

; Case 11: DEFS with mixed operands (device mode: DEFS 10, 1, 'x', 3)
test11
    DEFS 10, 1, 'x', 3

; Case 12: DEFS with exact-fit operands (device mode: DEFS 3, 0x11, 0x22, 0x33)
test12
    DEFS 3, 0x11, 0x22, 0x33

; Case 13: DEFS with operands exceeding size (device mode: DEFS 3, 1, 2, 3, 4, 5, 6)
test13
    DEFS 3, 1, 2, 3, 4, 5, 6

; Comment: Cases testing C suffix (high-bit setting) can be added if implementation 
; shows special handling needed. Currently trusting GetCharConstAsString() handles it.
; Cases for zero DEFS size or negative size not included - existing dirBLOCK already warns,
; should be covered by existing tests.

    END
