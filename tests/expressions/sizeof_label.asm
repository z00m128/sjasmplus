; design based on notes in Issue #16: https://github.com/z00m128/sjasmplus/issues/16

;;; basic syntax/behavior test

        ORG $1234
L1:     db  "abc"
.locL1  db  "d"
.locL2  db  "ef"
L2:
.locL1: ds  10 :.:
        db  0
.locL2: ds  5 ::
        db  0

    ASSERT 6 == SIZEOF(L1)
    ASSERT 6 == sizeof(L1)                  ; lowercase
    ASSERT 1 == SIZEOF(L1.locL1)
    ASSERT 2 == SIZEOF(L1.locL2)
    ASSERT 16 == SIZEOF(L2)
    ASSERT 10 == SIZEOF(L2.locL1)
    ASSERT 5 == SIZEOF(L2.locL2)

;;; forward reference should also be possible

    ASSERT 3 == SIZEOF(FwdRef)

FwdRef: db  "ghi"
        ::

;;; MODULE, ENDMODULE and ORG are also boundary

Lmod:   db  "abc"
        MODULE mod_example
            db  "def"                       ; should not count toward Lmod
Lmodin:     db  "ab"
        ENDMODULE
        db  "cd"                            ; should not count toward Lmodin

Lorg:   db  "abc"
        ORG $3456
        db  "def"                           ; should not count toward Lorg

    ASSERT 3 == SIZEOF(Lmod)
    ASSERT 2 == SIZEOF(mod_example.Lmodin)
    ASSERT 3 == SIZEOF(Lorg)

;;; INCLUDE should not set boundary, even if it contains labels

Linc1:  db  "in1"
        INCLUDE "sizeof_label.1.i.asm"      ; has size of 9
        db  "e1"

    ASSERT 3 + 9 + 2 == SIZEOF(Linc1)

Linc2:  db  "in2"
        INCLUDE "sizeof_label.2.i.asm"      ; has ORG after size of 4, another 2 after ORG (not counted)
        db  "!"                             ; not counted either

    ; ORG should have spawn warning about SIZEOF tracking in parent scope (recorded in listing file)
    ASSERT 3 + 4 == SIZEOF(Linc2)           ; partial size up to nested ORG

;;; MACRO should sets boundaries only on its own source-block-scope, ie. "invisible" for outer emitter

    MACRO SizeMacro1                        ; total size 6
@Mac1_ _ __COUNTER__:                       ; make sure nested global label does not set boundary for outer global labels
            db  "1"
.MyL1:      db  "m1::"
            ::
            db  "!"

        ASSERT 4 == SIZEOF(.MyL1)

    ENDM

    MACRO SizeMacro2                        ; total size 5 + 6 + 4 = 15
@Mac2_ _ __COUNTER__:                       ; make sure nested global label does not set boundary to outer global labels
            db  "2"
.MyL2:      db  "m2::"
            SizeMacro1                      ; nest the SizeMacro1 here
            :.:                             ; test local boundary tag inside macro body
            db  "2::"
            ::                              ; test main boundary tag inside macro body
            db  "!"

        ASSERT 4 + 6 == SIZEOF(.MyL2)

    ENDM

AheadMacro:
        db  "0"
        SizeMacro1
        SizeMacro2
        db  "::0::"
        ::
        db  "!"

    ASSERT 1 + 6 + 15 + 5 == SIZEOF(AheadMacro)
    ASSERT 5 == SIZEOF(Mac1_0)
    ASSERT 5 + 6 + 3 == SIZEOF(Mac2_1)
    ASSERT 5 == SIZEOF(Mac1_2)

;;; check if sizeof is reserved keyword

sizeof:
SIZEOF:

;;; non-standard edge cases

MyEqu:  EQU $-$100                          ; warn about sizeof equ, also size should be 0
        db  '.'     ::
        db  '!'

    ASSERT 0 == SIZEOF(MyEqu)

MyDefl  =   $-$100
        db  '.'     ::
        db  '!'

    ASSERT 0 == SIZEOF(MyDefl)

SmcLabel+*: ld  hl,$1234

    ASSERT 0 == SIZEOF(SmcLabel)

    ASSERT 0 == SIZEOF(1nvalidLabel)

;;; STRUCT has implicit SIZEOF for main label/emit, and zero SIZEOF for members of struct

    STRUCT S_MyStruct
Item1   WORD
Item2   BYTE
Item3   TEXT 6, {' '}
    ENDS

Struct1 S_MyStruct

    ASSERT S_MyStruct == SIZEOF(S_MyStruct) ; struct itself is already size, but for convenience make also SIZEOF(struct) work
    ASSERT S_MyStruct == SIZEOF(Struct1)    ; emitted struct will also have SIZEOF defined, this may be even more convenient
    ASSERT Struct1 != SIZEOF(Struct1)       ; but emitted label has value of its address of course, not size
    ; members of struct will report zero as SIZEOF(..), silently without warning (CBA to differ them from main label)
    ASSERT 0 == SIZEOF(S_MyStruct.Item1) && 0 == SIZEOF(S_MyStruct.Item2) &&  0 == SIZEOF(S_MyStruct.Item3)
    ASSERT 0 == SIZEOF(Struct1.Item1) && 0 == SIZEOF(Struct1.Item2) &&  0 == SIZEOF(Struct1.Item3)

;;; nested MODULE should kill all counting with warning like ORG

    MACRO NestedModuleMacro
        MODULE NestedModule
        ENDMODULE
    ENDM

AheadOfNestedModule:
    db  "mod"
    NestedModuleMacro                       ; should warn

    ASSERT 3 == SIZEOF(AheadOfNestedModule)

;;; nested ORG inside macro

    MACRO NestedOrgMacro
        ORG $
    ENDM

AheadOfNestedOrg:
    db  "org"
    NestedOrgMacro                       ; should warn

    ASSERT 3 == SIZEOF(AheadOfNestedOrg)

;;; SIZEOF counts **across** DISP (displaced) blocks

AcrossDisp:
    db  '!'
    DISP    $A000
    db  "disp"
    ENT
    db  '.' :: db  '!'

    ASSERT 6 == SIZEOF(AcrossDisp)

OrgInDisp:
    db  ':'
    DISP    $A000
    db  "di"
    ; in this specific case the physical memory flow is not interrupted, labels count size across such "ORG"
    ORG     $B000           ; displacedorg-ok: not a true physical address ORG, just changing displacement
    db  "sp"
    ASSERT 6 == SIZEOF(OrgInDisp)       ; should count correct size even *inside* the size-block
    ENT
    db  '.' :: db  '!'

;;; non-longptr wrap around 64ki in DISP (emitBlock, emitByteNoListing) does not stop the count (physical memory matters)

    DEVICE NONE
    ORG $FFFE
AcrossNoneDevice64ki:       ; will cross into 0x1'0000 territory, but not wrap-around! (not even w/o --longptr)
    dd  $12345678
AcrossNoneDevice64ki_2:
    dw  $1234   ::          ; count works even in 0x1'0000+ land
    ORG $FF00
    DISP $FFFE
    >AcrossNoneDevice64ki_3 ; this one does not care about DISP wrap-around, physically it's FF00..FF03 = size 4
        dd  $12345678 ::
    ENT

    ASSERT 4 == SIZEOF(AcrossNoneDevice64ki) && 2 == SIZEOF(AcrossNoneDevice64ki_2)
    ASSERT 4 == SIZEOF(AcrossNoneDevice64ki_3)

;;; DEVICE going outside of address space, MMU (ORG and wrap-around)

    DEVICE ZXSPECTRUMNEXT

    ORG $FFF9               ; only 7 bytes left till 64ki address space ends
Device64kiWrap:
    ASSERT 8 == SIZEOF(Device64kiWrap)
    db  "12345678" ::       ; warns about writing outside of device mem
    ASSERT $10001 == $      ; confirm being outside of device

    ORG $6000
MmuOrgBoundary:
    ASSERT 3 == SIZEOF(MmuOrgBoundary)
    db  'mmu'
    MMU $6000 n, 67, $7FF9  ; no warning, this is not nested
MmuSlotWrap:
    ASSERT 7 == SIZEOF(MmuSlotWrap) ; only 7 bytes left in this slot
    db  "12345678"          ; warns about wrap-around finishing sizeof-tracking
    ASSERT $6001 == $       ; confirm wrap-around

;;; conditional tag-boundary parsing

ConditionalShortening1:
    ASSERT 11 + 9 + 1 == SIZEOF(ConditionalShortening1)
    db  "shortening-"
    IFDEF SOME_DEFINE
        db  "defined" ::
    ELSE
        db  "undefined"
    ENDIF
    db "!" ::

ConditionalShortening2:
    ASSERT 11 + 9 == SIZEOF(ConditionalShortening2)
    db  "shortening-"
    IFNDEF SOME_DEFINE
        db  "undefined" ::
    ELSE
        db  "defined"
    ENDIF
    db "!" ::

;;; some more tags tests

.tagTestLocal:
::  ; needs whitespace to work, this is just empty label + single colon splitter
:.: ; as above, this becomes empty label, unrecognized instruction and single colons splitter
    db  "tag" ::
    ASSERT 3 == SIZEOF(.tagTestLocal)

;;; Some examples from original issue post and docs

; #1
FOO:
        ld      a,3
        call    BAR
        jr      c,.skip
        ld      a,1
        ret

.skip:  ld      a,2
        ret

BAR:
        cp      5
        ret

    ASSERT 13 == SIZEOF(FOO)

; #2
CHKCHARS:
    ASSERT 43 + 4 + 3 + 8 == SIZEOF(CHKCHARS)
    ASSERT 4 == SIZEOF(.charlist1)
    ASSERT 3 == SIZEOF(.charlist2)
    ASSERT 8 == SIZEOF(.charlist3)
                ds  43      ; fake "code" omitted, only some bytes reserved here
.charlist1:     db  "ABCD"
.charlist2:     db  "EFG"
.charlist3:     db  "HIHKLMNO"

CHKCHARS_BAR:

; #3
I16_Label:
    db "abc"  ; 3 bytes
    IF (0) :: ENDIF
    ; ^ that syntax should work, because "::" is also instruction delimiter,
    ; not just sizeof "counting" stopper, i.e. ENDIF will be found and assembled.
    db "d" ; 4th byte
    IF (0)
I16_Label2:   ; this one will not assemble into regular labels
    ENDIF
    db "e" ; 5th byte
    IF (1) :: ENDIF
    ld bc,SIZEOF(I16_Label) ; 3, 4 or 5?
    ASSERT 5 == SIZEOF(I16_Label)   ; the correct answer is c) "5"

; #4
        MACRO MyMacro
@NewGlobalLabel:
          xor a
        ENDM        ; SIZEOF(NewGlobalLabel) is 1, ENDM is nesting-boundary ending its count
MyRoutine:
        MyMacro     ; +1
        rld ::      ; +2
    ASSERT 1 == SIZEOF(NewGlobalLabel)
    ASSERT 3 == SIZEOF(MyRoutine)

;;; Temporary labels should not interfere with SIZEOF in any way, let's see what they do

TempLabelMidway:
        db      "first "
123:
        db      "second" :: dw 123_B, SIZEOF(123_B) ; error: invalid start of labelname

    ASSERT 6 + 6 == SIZEOF(TempLabelMidway) ; first+second counted together

;;; SIZEOF boundary by EOF of main file

    ASSERT 4 == SIZEOF(EndOfMainAsm)

EndOfMainAsm:
        db  "EOF"Z
