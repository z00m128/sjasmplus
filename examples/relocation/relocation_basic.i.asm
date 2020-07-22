        ; based on examples/TapLib/TapLib.asm from Busy soft
        MACRO        MakeTape tape_file?, prog_name?, code_adr?, code_len?

ZXB_CLEAR       EQU     $FD
ZXB_VAL         EQU     $B0
ZXB_INPUT       EQU     $EE
ZXB_LOAD        EQU     $EF
ZXB_CODE        EQU     $AF
ZXB_RANDOMIZE   EQU     $F9
ZXB_USR         EQU     $C0

                ORG     #5C00
.bas_start      DB      0,1                     ;; Line number
                DW      .line_len               ;; Line length
.line_start     DB      ZXB_CLEAR, ZXB_VAL, '"23999":'          ; CLEAR VAL "23999":
                DB      ZXB_INPUT, '"Enter address:";a:'        ; INPUT "Enter address:";a:
                DB      ZXB_LOAD, '"'                           ; LOAD "
.code_name      DB      prog_name?                              ; code name
                ASSERT ($ - .code_name) <= 10                   ; (max 10 chars)
                DB      '"',ZXB_CODE,'a:'                       ; " CODE a:
                DB      ZXB_RANDOMIZE, ZXB_USR, 'a'             ; RANDOMIZE USR a
                DB      13                                      ; <enter>
.line_len       EQU     $-.line_start
.bas_len        EQU     $-.bas_start

            EMPTYTAP tape_file?
            SAVETAP  tape_file?,BASIC,prog_name?,.bas_start,.bas_len,1
            ; make CODE-block load address 0, so it must be overriden by "LOAD CODE" explicitly
            SAVETAP  tape_file?,CODE,prog_name?,code_adr?,code_len?,0

        ENDM
