;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; see listing file for resulting macro expansion
;;; in each example

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Macro without parameters

  MACRO ADD_HL_A
    ADD A,L
    JR NC,.hup
    INC H
.hup
    LD L,A
  ENDM

  ADD_HL_A

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; A macro with parameters

  MACRO WAVEOUT reg, data
    LD A,reg
    OUT (7EH),A
    LD A,data
    OUT (7FH),A
  ENDM

  WAVEOUT 2,17

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Another example

    MACRO LOOP
      IF $-.lus<127
        DJNZ .lus
      ELSE
        DEC B
        JP NZ,.lus
      ENDIF
    ENDM

Main
.lus
    CALL DoALot
    LOOP
DoALot:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Argument in angle brackets

    MACRO UseLess data
      DB data
    ENDM

    UseLess <10,12,13,0>
; use '!' to include '!' and '>' in those strings.
    UseLess <5, 6 !> 3>
    UseLess <"Kip!!",3>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Macro name at beginning of line

LabelAsMacroName    MACRO  arg1?, arg2?
                        ld  a,arg1?
                        ld  hl,arg2?
                    ENDM

                LabelAsMacroName 1,$1234

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Inhibit macro expansion operator

djnz    MACRO   arg1?
            dec c
            jr  nz,arg1?
            @djnz arg1? ; avoid self-reference and use real instruction
        ENDM

1:      djnz    1B      ; macro replacement will be used here
1:      @djnz   1B      ; original djnz instruction here
