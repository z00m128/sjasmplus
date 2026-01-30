    STRUCT TEST_STRUCT
s1      BYTE
    ENDS

M_.!?#@acroName MACRO
@.L_.!?#@ocalInMacro:   nop                 ; local to emit
.L_.!?#@ocalInMacro:    nop                 ; local to macro
                ENDM

;;; old labels syntax requiring labels at beginning of line
    ORG $4000
R_.!?#@egular:          nop
!K_.!?#@eepRegForLocal: nop
.L_.!?#@ocal:           nop
.E_.!?#@mitMacro:       M_.!?#@acroName     ; emit macro
R_.!?#@egEqu:           EQU $1010
R_.!?#@egDefl           = $1020
R_.!?#@egSelfModifyCode+1:      nop
R_.!?#@egSelfModifyCodeAuto+*:  ld hl,12345 ; *MUST* have instruction
S_.!?#@tructInstance    TEST_STRUCT { 2 }
123                     ld  hl,123_B

    MODULE M_!?#@odul   ; can't contain dot
@G_.!?#@lobal:          nop
R_.!?#@egInMod:         nop
!K_.!?#@eepRegInModForLocal:    nop
.L_.!?#@ocalInMod:      nop
.E_.!?#@mitMacroInMod:  M_.!?#@acroName     ; emit macro
R_.!?#@egEquInMod:      EQU $1030
R_.!?#@egDeflInMod      = $1040
SMC_InMod+1:            nop
SMC_Auto_InMod+*:       ld hl,12345         ; *MUST* have instruction
S_.!?#@tructInMod       TEST_STRUCT { 3 }
234                     ld  hl,234_B
    ENDMODULE


;;; indented '>' as workaround for indenting labels (since v1.21.2)
;;; Good luck with syntax highlight and other 3rd party tools :shrug:
    ORG $6000

    STRUCT IND_STRUCT
        >s1Ind  BYTE
    ENDS
    >M_.!?#@acroNameInd     MACRO
    >@.L_.!?#@ocalInMacroInd:       nop     ; local to emit
    >.L_.!?#@ocalInMacroInd:        nop     ; local to macro
    >                       ENDM

    MACRO M_.!?#@acroWithI2
        >@.L_.!?#@ocalInMacroI2:    nop     ; local to emit
        >.L_.!?#@ocalInMacroI2:     nop     ; local to macro
    ENDM

    >R_.!?#@egularInd:              nop
    >!K_.!?#@eepRegForLocalInd:     nop
    >.L_.!?#@ocalInd:               nop
    >.E_.!?#@mitMacroInd:           M_.!?#@acroWithI2   ; emit macro
    >.E_.!?#@mitMacroInd2:          M_.!?#@acroNameInd  ; emit macro
    >R_.!?#@egEquInd:               EQU $1050
    >R_.!?#@egDeflInd               = $1060
    >R_.!?#@egSelfModifyCodeInd+1:  nop
    >R_.!?#@egSelfModifyCodeAutoInd+*:      ld hl,12345
    >S_.!?#@tructInstanceInd        TEST_STRUCT { 4 }
    >123                            ld  hl,123_B

    MODULE M_!?#@odulInd
        >@G_.!?#@lobalInd:          nop
        >R_.!?#@egInModInd:         nop
        >!K_.!?#@eepRegInModInd:    nop
        >.L_.!?#@ocalInModInd:      nop
        >.E_.!?#@mitMacroInModInd:  M_.!?#@acroWithI2   ; emit macro
        >.E_.!?#@mitMacroInModInd2: M_.!?#@acroNameInd  ; emit macro
        >R_.!?#@egEquInModInd:      EQU $1070
        >R_.!?#@egDeflInModInd      = $1080
        >SMC_.!?#@_InModInd+1:      nop
        >SMC_.!?#@_Auto_InModInd+*: ld hl,12345
        >S_.!?#@tructInModInd       TEST_STRUCT { 5 }
        >234                        ld  hl,234_B
    ENDMODULE

; valid syntax example/edge cases
    nop:nop:nop         ; old syntax, should still produce 3x nop
    >nop:nop:nop        ; new enhancement, 1x label "nop", 2x nop
    > nop               ; this is legal instruction nop, indentation doesn't enforce label to be used
>NotTrulyIndentedLabel: ; '>' is allowed also at beginning of line (in case you want visual consistency of all labels)

; error reporting cases
    >   >NoLabelHere    ; error, indented label can be used only once, at start of line
    >Label1:nop:    >Label2:nop     ; only first indentation works, Label2 is error

; check LUA blocks are intact by the new syntax (shouldn't apply inside lua block)
    LUA allpass
        >sj.add_byte(123)       -- error
    ENDLUA

/*
    this feature shouldn't be active in block comments:
        > don't tamper with this
*/
    IF 0
        > will be discarded as regular asm code, whether the block is active does not matter
        ; sjio.cpp doesn't know if the block is active early enough AND this makes sense in a way,
        ; the block should contain valid asm code in case it hypothetically becomes active
        ; if it was used just as other variant of block-comment, then it gets mangled, tough luck
    ENDIF

; line with just whitespace
        
; indentation line right ahead of <EOF>
        >