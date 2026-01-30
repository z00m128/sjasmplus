    STRUCT TEST_STRUCT
s1      BYTE
    ENDS

M_.!?#@acroName MACRO
@.L_.!?#@ocalInMacro:   nop     ; local to emit
.L_.!?#@ocalInMacro:    nop     ; local to macro
                ENDM

;;; current status, hopefully covering almost everything except Temporary labels
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
SMC_Auto_InMod+*:       ld hl,12345  ; *MUST* have instruction
S_.!?#@tructInMod       TEST_STRUCT { 3 }
234                     ld  hl,234_B
    ENDMODULE


;;; EQU directive as workaround for indenting some labels (since v1.21.2)
;;; !!! no colons !!! colon is instruction delimiter (optional label char only when label starts line)
;;; Also good luck with syntax highlight and other 3rd party tools :shrug:
    ORG $6000

    STRUCT EQU_STRUCT
        EQU     s1      BYTE                ; error, not supported
    ENDS
    EQU EquM_.!?#@acroName  MACRO           ; this is explicitly not supported, just DO NOT, see next line
    MACRO M_.!?#@acroWithEqu
        EQU @.EquL_.!?#@ocalInMacro     nop     ; local to emit
        EQU .EquL_.!?#@ocalInMacro      nop     ; local to macro
    ENDM

    EQU EquR_.!?#@egular            nop
    EQU !EquK_.!?#@eepRegForLocal   nop
    EQU .EquL_.!?#@ocal             nop
    EQU .EquE_.!?#@mitMacro         M_.!?#@acroWithEqu  ; emit macro
    EQU EquR_.!?#@egEqu             EQU $1050
    EQU EquR_.!?#@egDefl            = $1060
    EQU EquR_.!?#@egSelfModifyCode+1        nop
    EQU EquR_.!?#@egSelfModifyCodeAuto+*    ld hl,12345 ; and this WORKS OMG
    EQU EquS_.!?#@tructInstance     TEST_STRUCT { 4 }   ; this also WORKS
    EQU 123                         ld  hl,123_B

    MODULE EquM_!?#@odul
    EQU @EquG_.!?#@lobal            nop
    EQU EquR_.!?#@egInMod           nop
    EQU !EquK_.!?#@eepRegInMod      nop
    EQU .EquL_.!?#@ocalInMod        nop
    EQU .EquE_.!?#@mitMacroInMod    M_.!?#@acroWithEqu  ; emit macro
    EQU EquR_.!?#@egEquInMod        EQU $1070
    EQU EquR_.!?#@egDeflInMod       = $1080
    EQU EquSMC_.!?#@_InMod+1        nop
    EQU EquSMC_.!?#@_Auto_InMod+*   ld hl,12345  ; *MUST* have instruction
    EQU EquS_.!?#@tructInMod        TEST_STRUCT { 5 }
    EQU 234                         ld  hl,234_B
    ENDMODULE

;;; verify there's no infinite cycle of EQU in EQU, it naturally failed without extra code check
;;; but extra check was added to make it fail explicitly

; Nested1 will eat second EQU as regular label would, evaluating "Nested2 EQU $EEEE" as expression
    EQU Nested1 EQU Nested2 EQU $EEEE

; Second EQU becomes label, all whitespace is skipped in special EQU mode before attempting to find indented label
    EQU         EQU Nested2 EQU $1090

; But this was "EQU EQU Nested1" without extra check, so it somewhat worked before extra check
    EQU         EQU         EQU Nested1












;;; line 100+ in listing
