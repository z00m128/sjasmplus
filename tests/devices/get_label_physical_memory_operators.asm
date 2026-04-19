    DEVICE ZXSPECTRUMNEXT
;;; labels now track their "physical" position as well as regular/displaced address
    MMU $0000 $E000, 30, $4000-2
orgL1:
.local:                 ; regular label, page 31
    DB      'A'
    DISP    $C000-1, 41
dispL1:                 ; disp lavel, disp page 41, physical still page 31 (last byte)
.local:
    DB      'B'
dispL2:                 ; goes into page 32 physically, but has enforced DISP page 41
.local:
    DB      'C'
    ENT
orgL2:
.local:
    DB      'D'
    ; regular labels should report same value/page also for "physical" address
    ASSERT  $3FFE == orgL1          && 31 == $$orgL1        && $3FFE == $$$orgL1        && 31 == $$$$orgL1
    ASSERT  $3FFE == orgL1.local    && 31 == $$orgL1.local  && $3FFE == $$$orgL1.local  && 31 == $$$$orgL1.local
    ASSERT  $BFFF == dispL1         && 41 == $$dispL1       && $3FFF == $$$dispL1       && 31 == $$$$dispL1
    ASSERT  $BFFF == dispL1.local   && 41 == $$dispL1.local && $3FFF == $$$dispL1.local && 31 == $$$$dispL1.local
    ASSERT  $C000 == dispL2         && 41 == $$dispL2       && $4000 == $$$dispL2       && 32 == $$$$dispL2
    ASSERT  $C000 == dispL2.local   && 41 == $$dispL2.local && $4000 == $$$dispL2.local && 32 == $$$$dispL2.local
    ASSERT  $4001 == orgL2          && 32 == $$orgL2        && $4001 == $$$orgL2        && 32 == $$$$orgL2
    ASSERT  $4001 == orgL2.local    && 32 == $$orgL2.local  && $4001 == $$$orgL2.local  && 32 == $$$$orgL2.local

;;; EQU tracks program counter where it was defined in the physical page/address
;;; just emerging behaviour out of implementation, no deep idea behind it, probably useless
    DISP $D000
Equ1        EQU     $EE01           ; picks up page from $EE01 value itself, ie. 37
Equ2        EQU     $EE02, 51       ; explicit equ page
    ENT
    DB      'E'
    DISP $D000, 61
Equ3        EQU     $EE03           ; picks up page from explicit DISP page 61
Equ4        EQU     $EE04, 52       ; explicit equ page
    ENT
    DB      'F'
    ASSERT  $EE01 == Equ1           && 37 == $$Equ1         && $4002 == $$$Equ1         && 32 == $$$$Equ1
    ASSERT  $EE02 == Equ2           && 51 == $$Equ2         && $4002 == $$$Equ2         && 32 == $$$$Equ2
    ASSERT  $EE03 == Equ3           && 61 == $$Equ3         && $4003 == $$$Equ3         && 32 == $$$$Equ3
    ASSERT  $EE04 == Equ4           && 52 == $$Equ4         && $4003 == $$$Equ4         && 32 == $$$$Equ4

;;; exercise parsing of label with modifiers
MainLab:
.local:
    DB      'G'
    ASSERT  $4004 == $$$@MainLab && $4004 == $$$@MainLab.local && $4004 == $$$.local
    ASSERT  32 == $$$$@MainLab && 32 == $$$$@MainLab.local && 32 == $$$$.local

;;; DEFL does what exactly? (exploring implementation, not designed)
Defl        DEFL    $DEF1           ; page comes from value itself (36), physical address/page tracks place of definition
    DB      'H'
    ASSERT  $DEF1 == Defl           && 36 == $$Defl         && $4005 == $$$Defl         && 32 == $$$$Defl

;;; STRUCT labels
;;; unfortunately, the members have physical address of beginning of structure, not member itself
;;; documenting this by test, this is not deliberate design, but accepting it right now as is
    STRUCT S_MyStruct
X       WORD
Y       BYTE
    ENDS

MyS1        S_MyStruct { 0x1234, 0x56 }
    DISP $C000, 62
MyS2        S_MyStruct { 0x2345, 0x78 }
    ENT
    DB      'I'
    ASSERT  $0003 == S_MyStruct     && 30 == $$S_MyStruct   && $4006 == $$$S_MyStruct   && 32 == $$$$S_MyStruct
    ASSERT  $4006 == MyS1           && 32 == $$MyS1         && $4006 == $$$MyS1         && 32 == $$$$MyS1
    ASSERT  $C000 == MyS2           && 62 == $$MyS2         && $4009 == $$$MyS2         && 32 == $$$$MyS2
    ASSERT  $C002 == MyS2.Y         && 62 == $$MyS2.Y       && $4009 == $$$MyS2.Y       && 32 == $$$$MyS2.Y
    ; if you need physical address of member, you can work around by using STRUCT mechanics
    ASSERT  $400B == ($$$MyS2 + S_MyStruct.Y)

;;; anything else WRT to labels??

Smc+*   ld  a,123                   ; self-modify-code type of label ; physical address points to start of instruction
    ASSERT  $400E == Smc            && 32 == $$Smc          && $400D == $$$Smc          && 32 == $$$$Smc

    DEVICE NONE
NoDevice:
    DB      'J'
    DISP $B000
NoDeviceDisp:
    DB      'K'
    ENT
    ASSERT  $400F == NoDevice       && 1/* no device no $$*/&& $400F == $$$NoDevice     && 0x7F00 /* LABEL_PAGE_ROM */ == $$$$NoDevice
    ASSERT  $B000 == NoDeviceDisp                           && $4010 == $$$NoDeviceDisp && 0x7F00 /* LABEL_PAGE_ROM */ == $$$$NoDeviceDisp
