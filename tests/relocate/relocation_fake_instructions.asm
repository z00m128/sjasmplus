    ORG $1000

    RELOCATE_START

    ASSERT 2 * relocate_count == relocate_size
    ASSERT 0 == relocate_count
    dw      relocate_count
    dw      relocate_size

ixy_fakes_16b:
    ld      bc,(ix+high ixy_fakes_16b)
    ld      de,(ix+high ixy_fakes_16b)
    ld      hl,(ix+high ixy_fakes_16b)
    ld      (ix+high ixy_fakes_16b),bc
    ld      (ix+high ixy_fakes_16b),de
    ld      (ix+high ixy_fakes_16b),hl
    ldi     bc,(ix+high ixy_fakes_16b)
    ldi     de,(ix+high ixy_fakes_16b)
    ldi     hl,(ix+high ixy_fakes_16b)
    ldi     (ix+high ixy_fakes_16b),bc
    ldi     (ix+high ixy_fakes_16b),de
    ldi     (ix+high ixy_fakes_16b),hl

    ld      bc,(iy+high ixy_fakes_16b)
    ld      de,(iy+high ixy_fakes_16b)
    ld      hl,(iy+high ixy_fakes_16b)
    ld      (iy+high ixy_fakes_16b),bc
    ld      (iy+high ixy_fakes_16b),de
    ld      (iy+high ixy_fakes_16b),hl
    ldi     bc,(iy+high ixy_fakes_16b)
    ldi     de,(iy+high ixy_fakes_16b)
    ldi     hl,(iy+high ixy_fakes_16b)
    ldi     (iy+high ixy_fakes_16b),bc
    ldi     (iy+high ixy_fakes_16b),de
    ldi     (iy+high ixy_fakes_16b),hl

ixy_fakes_8b:
    ldi     a,(ix+high ixy_fakes_8b)
    ldi     b,(ix+high ixy_fakes_8b)
    ldi     c,(ix+high ixy_fakes_8b)
    ldi     d,(ix+high ixy_fakes_8b)
    ldi     e,(ix+high ixy_fakes_8b)
    ldi     h,(ix+high ixy_fakes_8b)
    ldi     l,(ix+high ixy_fakes_8b)
    ldd     a,(ix+high ixy_fakes_8b)
    ldd     b,(ix+high ixy_fakes_8b)
    ldd     c,(ix+high ixy_fakes_8b)
    ldd     d,(ix+high ixy_fakes_8b)
    ldd     e,(ix+high ixy_fakes_8b)
    ldd     h,(ix+high ixy_fakes_8b)
    ldd     l,(ix+high ixy_fakes_8b)
    ldi     (ix+high ixy_fakes_8b),a
    ldi     (ix+high ixy_fakes_8b),b
    ldi     (ix+high ixy_fakes_8b),c
    ldi     (ix+high ixy_fakes_8b),d
    ldi     (ix+high ixy_fakes_8b),e
    ldi     (ix+high ixy_fakes_8b),h
    ldi     (ix+high ixy_fakes_8b),l
    ldd     (ix+high ixy_fakes_8b),a
    ldd     (ix+high ixy_fakes_8b),b
    ldd     (ix+high ixy_fakes_8b),c
    ldd     (ix+high ixy_fakes_8b),d
    ldd     (ix+high ixy_fakes_8b),e
    ldd     (ix+high ixy_fakes_8b),h
    ldd     (ix+high ixy_fakes_8b),l

    ldi     a,(iy+high ixy_fakes_8b)
    ldi     b,(iy+high ixy_fakes_8b)
    ldi     c,(iy+high ixy_fakes_8b)
    ldi     d,(iy+high ixy_fakes_8b)
    ldi     e,(iy+high ixy_fakes_8b)
    ldi     h,(iy+high ixy_fakes_8b)
    ldi     l,(iy+high ixy_fakes_8b)
    ldd     a,(iy+high ixy_fakes_8b)
    ldd     b,(iy+high ixy_fakes_8b)
    ldd     c,(iy+high ixy_fakes_8b)
    ldd     d,(iy+high ixy_fakes_8b)
    ldd     e,(iy+high ixy_fakes_8b)
    ldd     h,(iy+high ixy_fakes_8b)
    ldd     l,(iy+high ixy_fakes_8b)
    ldi     (iy+high ixy_fakes_8b),a
    ldi     (iy+high ixy_fakes_8b),b
    ldi     (iy+high ixy_fakes_8b),c
    ldi     (iy+high ixy_fakes_8b),d
    ldi     (iy+high ixy_fakes_8b),e
    ldi     (iy+high ixy_fakes_8b),h
    ldi     (iy+high ixy_fakes_8b),l
    ldd     (iy+high ixy_fakes_8b),a
    ldd     (iy+high ixy_fakes_8b),b
    ldd     (iy+high ixy_fakes_8b),c
    ldd     (iy+high ixy_fakes_8b),d
    ldd     (iy+high ixy_fakes_8b),e
    ldd     (iy+high ixy_fakes_8b),h
    ldd     (iy+high ixy_fakes_8b),l

imm8_fakes:
    ldi     (hl),high imm8_fakes
    ldi     (ix+12),high imm8_fakes
    ldi     (iy+23),high imm8_fakes
    ldi     (ix+high imm8_fakes),34
    ldi     (iy+high imm8_fakes),45

    ldd     (hl),high imm8_fakes
    ldd     (ix+12),high imm8_fakes
    ldd     (iy+23),high imm8_fakes
    ldd     (ix+high imm8_fakes),34
    ldd     (iy+high imm8_fakes),45

    RELOCATE_END

    RELOCATE_TABLE

;===================================================================================
; here comes the copy of all the instructions, but outside of relocation block
; but using the labels which are affected by relocation (this should still *NOT*
; add to the relocation table, as instructions are outside of relocation block)
; and thus this should also *NOT* warn about unstable relocation.
;===================================================================================

;ixy_fakes_16b:
    ld      bc,(ix+high ixy_fakes_16b)
    ld      de,(ix+high ixy_fakes_16b)
    ld      hl,(ix+high ixy_fakes_16b)
    ld      (ix+high ixy_fakes_16b),bc
    ld      (ix+high ixy_fakes_16b),de
    ld      (ix+high ixy_fakes_16b),hl
    ldi     bc,(ix+high ixy_fakes_16b)
    ldi     de,(ix+high ixy_fakes_16b)
    ldi     hl,(ix+high ixy_fakes_16b)
    ldi     (ix+high ixy_fakes_16b),bc
    ldi     (ix+high ixy_fakes_16b),de
    ldi     (ix+high ixy_fakes_16b),hl

    ld      bc,(iy+high ixy_fakes_16b)
    ld      de,(iy+high ixy_fakes_16b)
    ld      hl,(iy+high ixy_fakes_16b)
    ld      (iy+high ixy_fakes_16b),bc
    ld      (iy+high ixy_fakes_16b),de
    ld      (iy+high ixy_fakes_16b),hl
    ldi     bc,(iy+high ixy_fakes_16b)
    ldi     de,(iy+high ixy_fakes_16b)
    ldi     hl,(iy+high ixy_fakes_16b)
    ldi     (iy+high ixy_fakes_16b),bc
    ldi     (iy+high ixy_fakes_16b),de
    ldi     (iy+high ixy_fakes_16b),hl

;ixy_fakes_8b:
    ldi     a,(ix+high ixy_fakes_8b)
    ldi     b,(ix+high ixy_fakes_8b)
    ldi     c,(ix+high ixy_fakes_8b)
    ldi     d,(ix+high ixy_fakes_8b)
    ldi     e,(ix+high ixy_fakes_8b)
    ldi     h,(ix+high ixy_fakes_8b)
    ldi     l,(ix+high ixy_fakes_8b)
    ldd     a,(ix+high ixy_fakes_8b)
    ldd     b,(ix+high ixy_fakes_8b)
    ldd     c,(ix+high ixy_fakes_8b)
    ldd     d,(ix+high ixy_fakes_8b)
    ldd     e,(ix+high ixy_fakes_8b)
    ldd     h,(ix+high ixy_fakes_8b)
    ldd     l,(ix+high ixy_fakes_8b)
    ldi     (ix+high ixy_fakes_8b),a
    ldi     (ix+high ixy_fakes_8b),b
    ldi     (ix+high ixy_fakes_8b),c
    ldi     (ix+high ixy_fakes_8b),d
    ldi     (ix+high ixy_fakes_8b),e
    ldi     (ix+high ixy_fakes_8b),h
    ldi     (ix+high ixy_fakes_8b),l
    ldd     (ix+high ixy_fakes_8b),a
    ldd     (ix+high ixy_fakes_8b),b
    ldd     (ix+high ixy_fakes_8b),c
    ldd     (ix+high ixy_fakes_8b),d
    ldd     (ix+high ixy_fakes_8b),e
    ldd     (ix+high ixy_fakes_8b),h
    ldd     (ix+high ixy_fakes_8b),l

    ldi     a,(iy+high ixy_fakes_8b)
    ldi     b,(iy+high ixy_fakes_8b)
    ldi     c,(iy+high ixy_fakes_8b)
    ldi     d,(iy+high ixy_fakes_8b)
    ldi     e,(iy+high ixy_fakes_8b)
    ldi     h,(iy+high ixy_fakes_8b)
    ldi     l,(iy+high ixy_fakes_8b)
    ldd     a,(iy+high ixy_fakes_8b)
    ldd     b,(iy+high ixy_fakes_8b)
    ldd     c,(iy+high ixy_fakes_8b)
    ldd     d,(iy+high ixy_fakes_8b)
    ldd     e,(iy+high ixy_fakes_8b)
    ldd     h,(iy+high ixy_fakes_8b)
    ldd     l,(iy+high ixy_fakes_8b)
    ldi     (iy+high ixy_fakes_8b),a
    ldi     (iy+high ixy_fakes_8b),b
    ldi     (iy+high ixy_fakes_8b),c
    ldi     (iy+high ixy_fakes_8b),d
    ldi     (iy+high ixy_fakes_8b),e
    ldi     (iy+high ixy_fakes_8b),h
    ldi     (iy+high ixy_fakes_8b),l
    ldd     (iy+high ixy_fakes_8b),a
    ldd     (iy+high ixy_fakes_8b),b
    ldd     (iy+high ixy_fakes_8b),c
    ldd     (iy+high ixy_fakes_8b),d
    ldd     (iy+high ixy_fakes_8b),e
    ldd     (iy+high ixy_fakes_8b),h
    ldd     (iy+high ixy_fakes_8b),l

;imm8_fakes:
    ldi     (hl),high imm8_fakes
    ldi     (ix+12),high imm8_fakes
    ldi     (iy+23),high imm8_fakes
    ldi     (ix+high imm8_fakes),34
    ldi     (iy+high imm8_fakes),45

    ldd     (hl),high imm8_fakes
    ldd     (ix+12),high imm8_fakes
    ldd     (iy+23),high imm8_fakes
    ldd     (ix+high imm8_fakes),34
    ldd     (iy+high imm8_fakes),45

    RELOCATE_TABLE

    ASSERT 0 == __ERRORS__
    ASSERT 90 == __WARNINGS__
