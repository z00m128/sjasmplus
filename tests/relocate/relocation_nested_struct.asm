    ORG $1000
    RELOCATE_START
    ASSERT 2 * relocate_count == relocate_size
    ASSERT 19 == relocate_count
    dw      relocate_count
    dw      relocate_size

    STRUCT st1
b       BYTE    $12
w       WORD    absolute1
relInit WORD    reloc1          ; the default init value should be relocated
noRel   WORD    reloc2-reloc1
badRel  WORD    2*reloc1        ; warning about not simple "+offset"
    ENDS

    STRUCT st2
b       BYTE    $34
w       WORD    absolute1
relInit WORD    reloc2          ; the default init value should be relocated
noRel   WORD    reloc2-reloc1
badRel  WORD    2*reloc2        ; warning about not simple "+offset"
st1A    st1
st1B    st1     { high reloc1, absolute2, reloc2, reloc1-reloc2, 2*reloc2 }
    ENDS

reloc1:

    ; instancing the struct in relocatable block
.t1 st2     {}                  ; default init (no warnings, those were at definition, but relocation data in table)
; ^ expected relocation data: 07 10 10 10 19 10 
.t2 st2     {,,$ABCD,,,{,,$ABCD,,},{$EF,,$ABCD,,}}   ; remove any relocatable data
.t3 st2     {,,$ABCD,,,{high reloc2,,$ABCD,,},{$EF,,2*reloc1,,reloc2}}   ; some relocatable and 2x warnings
; ^ expected relocation data: 53 10

    ld      ix,reloc1.t1        ; to be relocated (address of instance)
    ld      iy,.t2              ; to be relocated (address of instance)

    ; using the struct offsets - no relocation data needed (offsets are relative values)
    ld      a,(ix+st2.st1A.b)
    ld      a,(ix+st2.st1A.w)
    ld      a,(ix+st2.st1A.relInit)
    ld      a,(ix+st2.st1A.noRel)
    ld      a,st2               ; struct length is absolute
    ld      a,st2.st1B          ; offset to nested sub-structure is absolute

    ; using struct addresses - to be relocated
    ld      a,(reloc1.t1.st1A.b)
    ld      hl,(reloc1.t1.st1A.w)
    ld      de,(reloc1.t1.st1A.relInit)
    ld      bc,(reloc1.t1.st1A.noRel)
    ld      a,(.t2.st1B.b)
    ld      hl,(.t2.st1B.w)
    ld      de,(.t2.st1B.relInit)
    ld      bc,(.t2.st1B.noRel)

    ; using absolute struct instance = to be ignored
    ld      a,(absolute1.t1.st1A.b)
    ld      hl,(absolute1.t1.st1A.w)
    ld      de,(absolute1.t1.st1A.relInit)
    ld      bc,(absolute1.t1.st1A.noRel)

    ; using alias instance placed at particular address
akaT1   st2 = .t1               ; transitive relocation - to be relocated
    ld      de,(akaT1.b)
    ld      bc,(akaT1.w)
    ld      a,(akaT1.st1B.b)
    ld      hl,(akaT1.st1B.w)
    ld      ix,akaT1.st1B

    ; same alias test, but with absolute instance = no relocation data
akaA1   st2 = absolute1.t1
    ld      a,(akaA1.st1A.b)
    ld      hl,(akaA1.st1A.w)
    ld      de,(akaA1.st1A.relInit)
    ld      bc,(akaA1.st1A.noRel)
    ld      ix,akaA1.st1A

reloc2:
    RELOCATE_END

    ORG $2000
    RELOCATE_TABLE

; no relocation area (no warnings, no relocation data)
    ORG $87DC
absolute1:

    ; instancing the struct in absolute block - NOTHING to be relocated
.t1 st2     {}
    ; no warning about unstable values or value being different
.t2 st2     {,,$ABCD,,,{high reloc2,,$ABCD,,},{$EF,,2*reloc1,,reloc2}}

    ld      ix,reloc1.t1        ; not to be relocated even when using relocatable instance
    ld      iy,absolute1.t2

    ; using the struct offsets - no relocation data needed (offsets are relative values)
    ld      a,(ix+st2.st1A.b)
    ld      a,(ix+st2.st1A.w)
    ld      a,(ix+st2.st1A.relInit)
    ld      a,(ix+st2.st1A.noRel)
    ld      a,st2               ; struct length is absolute
    ld      a,st2.st1B          ; offset to nested sub-structure is absolute

    ; using struct addresses (relocatable ones and absolute ones - either should be NOT relocated)
    ld      a,(reloc1.t1.st1A.b)
    ld      hl,(reloc1.t1.st1A.w)
    ld      de,(reloc1.t1.st1A.relInit)
    ld      bc,(reloc1.t1.st1A.noRel)
    ld      a,(absolute1.t2.st1B.b)
    ld      hl,(absolute1.t2.st1B.w)
    ld      de,(absolute1.t2.st1B.relInit)
    ld      bc,(absolute1.t2.st1B.noRel)

    ; using relocatable alias (outside of block = no relocation)
    ld      de,(akaT1.b)
    ld      bc,(akaT1.w)
    ld      a,(akaT1.st1B.b)
    ld      hl,(akaT1.st1B.w)
    ld      ix,akaT1.st1B
absolute2:

    ASSERT 0 == __ERRORS__
    ASSERT 6 == __WARNINGS__
