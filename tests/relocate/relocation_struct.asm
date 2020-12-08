    ORG $1000
    RELOCATE_START
    ASSERT 2 * relocate_count == relocate_size
    ASSERT 17 == relocate_count
    dw      relocate_count
    dw      relocate_size

    STRUCT st1
x       BYTE    $12
y       WORD    absolute1
relInit WORD    reloc1          ; the default init value should be relocated
noRel   WORD    reloc2-reloc1
badRel  WORD    2*reloc1        ; warning about not simple "+offset"
badRel2 WORD    2*reloc1        ; reldiverts-ok ; suppressed warning
warn1   BYTE    high reloc1     ; warning because unstable
warn2   D24     reloc1          ; warning - D24 is not supported for relocation
warn3   DWORD   reloc1          ; warning - D24 is not supported for relocation
Swarn1  BYTE    high reloc1     ; relunstable-ok ; suppressed warning
Swarn2  D24     reloc1          ; relunstable-ok ; suppressed warning
Swarn3  DWORD   reloc1          ; relunstable-ok ; suppressed warning
    ENDS

reloc1:

    ; instancing the struct in relocatable block
.t1 st1     {}                  ; default "relInit" value is to be relocated
.t2 st1     {,reloc1,absolute1} ; "y" to be relocated, "relInit" NOT (absolute value)
    ; warning about non-word members
.t3 st1     {high reloc1, $3412, $7856}
.t4 st1     {high reloc1, $3412, $7856}     ; relunstable-ok ; suppressed warning
    ; warning about unrelocatable value
.t5 st1     {,, 2*reloc1}
.t6 st1     {,, 2*reloc1}       ; reldiverts-ok ; suppressed warning

    ld      ix,reloc1.t1        ; to be relocated (address of instance)
    ld      iy,.t2              ; to be relocated (address of instance)

    ; using the struct offsets - no relocation data needed (offsets are relative values)
    ld      a,(ix+st1.x)
    ld      a,(ix+st1.y)
    ld      a,(ix+st1.relInit)
    ld      a,(ix+st1.noRel)
    ld      a,st1               ; struct length is absolute

    ; using struct addresses - to be relocated
    ld      a,(reloc1.t1.x)
    ld      hl,(reloc1.t1.y)
    ld      de,(reloc1.t1.relInit)
    ld      bc,(reloc1.t1.noRel)
    ld      a,(.t2.x)
    ld      hl,(.t2.y)
    ld      de,(.t2.relInit)
    ld      bc,(.t2.noRel)

    ; using absolute struct instance = to be ignored
    ld      a,(absolute1.t1.x)
    ld      hl,(absolute1.t1.y)
    ld      de,(absolute1.t1.relInit)
    ld      bc,(absolute1.t1.noRel)

    ; using alias instance placed at particular address
akaT1   st1 = .t1               ; transitive relocation - to be relocated
    ld      a,(akaT1.x)
    ld      hl,(akaT1.y)
    ld      de,(akaT1.relInit)
    ld      bc,(akaT1.noRel)
    ld      ix,akaT1

    ; same alias test, but with absolute instance = no relocation data
akaA1   st1 = absolute1.t1
    ld      a,(akaA1.x)
    ld      hl,(akaA1.y)
    ld      de,(akaA1.relInit)
    ld      bc,(akaA1.noRel)
    ld      ix,akaA1

reloc2:
    RELOCATE_END

    ORG $2000
    RELOCATE_TABLE

; no relocation area (no warnings, no relocation data)
    ORG $87DC
absolute1:

    ; instancing the struct in absolute block - NOTHING to be relocated
.t1 st1     {}
.t2 st1     {,reloc1,absolute1}
    ; no warning about unstable values or value being different
.t3 st1     {high reloc1}
.t5 st1     {,, 2*reloc1}

    ld      ix,reloc1.t1        ; not to be relocated even when using relocatable instance
    ld      iy,absolute1.t2

    ; using the struct offsets - no relocation data needed (offsets are relative values)
    ld      a,(ix+st1.x)
    ld      a,(ix+st1.y)
    ld      a,(ix+st1.relInit)
    ld      a,(ix+st1.noRel)

    ; using struct addresses (relocatable ones and absolute ones - either should be NOT relocated)
    ld      a,(reloc1.t1.x)
    ld      hl,(reloc1.t1.y)
    ld      de,(reloc1.t1.relInit)
    ld      bc,(reloc1.t1.noRel)
    ld      a,(absolute1.t2.x)
    ld      hl,(absolute1.t2.y)
    ld      de,(absolute1.t2.relInit)
    ld      bc,(absolute1.t2.noRel)

    ; using relocatable alias (not outside of block = no relocation)
    ld      a,(akaT1.x)
    ld      hl,(akaT1.y)
    ld      de,(akaT1.relInit)
    ld      bc,(akaT1.noRel)
    ld      ix,akaT1

    ASSERT 0 == __ERRORS__
    ASSERT 6 == __WARNINGS__
