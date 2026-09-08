; the user issue was detecting overflow of code/data in individual bank/section
; work around idea was to modify --longptr in DEVICE mode to keep `$` 24 bit addressable
; it turned out that is what is happening already without --longptr, so
; `$` can be checked to see how far the assembling went, except some directives
; hard-mask the `$` to 16bit

; this test is to find such directives/situations and ensure they
; do NOT modify `$` itself, but just mask its value to device address space

; directives still truncating `$` to 16b (currently intentionally):
;   - ORG (and various built-in ORG calls) (--longptr enables large address)
;   - MMU (even without optional ORG argument!)
;   - DISP block auto-wraps the displaced address (0xFFFF advances to 0x0000) (--longptr enables also large displaced address)

    DEVICE NOSLOT64K

    ORG 0x100
    DS 60000,0
    ASSERT 60000 + 0x100 == $

; produce error about write outside of device memory at: 65536
; this is intended and wanted behavior, the leak of device address space is error
    DS 60000,0
    ASSERT 2 * 60000 + 0x100 == $   ; but the `$` should keep the large address
; only one error per one leak, so second 60k block just advances `$` further
    DS 60000,0
    ASSERT 3 * 60000 + 0x100 == $
    DS 1
    ASSERT 1 + 3 * 60000 + 0x100 == $
; before fix `DS 1,0` did truncate the address from 0x2'C020 to 0xC021 (-0x2'0000)
    DS 1,0
    ASSERT 2 + 3 * 60000 + 0x100 == $
    DS 2,0
    ASSERT 4 + 3 * 60000 + 0x100 == $

    ORG 65535
    res 4,(ix+5),l  ; new error ; long bytecode instruction
    ASSERT 0x1'0003 == $
    ld a,7
    ASSERT 0x1'0005 == $

    ORG 65535
    ld (ix+123),bc  ; new error ; fake instruction composed of two long instructions
    ASSERT 0x1'0005 == $
    ld a,7
    ASSERT 0x1'0007 == $
    ; verify memory content, FFFF is overwriten by `ld` fake instruction,
    ; but wrap-around in listing to 0000+ is NOT real, the machine code is just LOST
    ; after error about writing outside of device. This is intended at this moment.
    ; (DISP *has* wrap-around on the displaced address)
    ASSERT $DD == {b $FFFF} && $0000 == {$0000} && $0000 == {$0005}

    ORG 0
    ld a,7
    ASSERT $3E == {b $0000}
    DS -5           ; warns about negative block size
    res 4,(ix+5),l  ; new error ; write outside of device memory should be detected also here
    ASSERT +2-5+4 == $
    ; verify memory content, end of RAM is intact by `res`, but $0000 becomes $A5 (last byte of opcode), 07 is from previous `ld a,7`
    ASSERT $DD00 == {$FFFE} && $07A5 == {$0000}

; non-device assembling mode
    DEVICE NONE
    ORG 65535
    res 4,(ix+5),l  ; just warning about RAM-limit exceeded in non-device mode
    ASSERT 0x1'0003 == $
    ld a,7
    ASSERT 0x1'0005 == $

    ORG 0x100
    DS 0x1'0000,0xAA        ; warning
    ASSERT 0x1'0100 == $
    DS 1, 0
    ASSERT 0x1'0101 == $    ; the `$` should retain large address
