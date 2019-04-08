;##########################################################################
;# BSrom140 - Modified ZX Spectrum ROM - (c) Busy soft - Release 22.04.97 #
;##########################################################################
;                   Original ROM: (c) Amstrad



		OUTPUT	"bsrom140.bin"

VERZIA:		EQU	140

VERA:		EQU	VERZIA/100
VERB:		EQU	VERA*100
VERC:		EQU	VERZIA-VERB
VERD:		EQU	VERC/10
VERE:		EQU	VERD*10
VERF:		EQU	VERC-VERE

VER1:		EQU	'0'+VERA
VER2:		EQU	'0'+VERD
VER3:		EQU	'0'+VERF

		ORG	#0000

; RST #00
START:		DI
		XOR	A
		LD	DE,#FFFF
		JP	NMI_MENU		; BSROM - jumps to NMI menu instead of START_NEW

; Error restart
; RST #08
ERROR_1:	LD	HL,(#5C5D)
		CALL	TOERR			; BSROM - cursor jumps to error
		JR	ERROR_2

; Print a character
; RST #10
PRINT_A:	JP	PRINT_A_2

; Unused bytes
		DW	#FFFF
		DW	#FFFF
		DB	#FF

; Collect a character
; RST #18
GET_CHAR:	LD	HL,(#5C5D)
		LD	A,(HL)
TEST_CHAR:	CALL	SKIP_OVER
		RET	NC
NEXT_CHAR:	CALL	CH_ADD_1
		JR	TEST_CHAR

; Unused bytes
		DW	#FFFF
		DB	#FF

; Calculator restart
; RST #28
		JP	CALCULATE

; Unused bytes
		DW	#FFFF
		DW	#FFFF
		DB	#FF

; Create free locations in work space
; RST #30
BC_SPACES:	PUSH	BC
		LD	HL,(#5C61)
		PUSH	HL
		JP	RESERVE

; Maskable interrupt routine
; RST #38
MASK_INT:	PUSH	AF
		PUSH	HL
		LD	HL,(#5C78)
		INC	HL
		LD	(#5C78),HL
		LD	A,H
		OR	L
		JR	NZ,KEY_INT
		INC	(IY+#40)
KEY_INT:	PUSH	BC
		PUSH	DE
		CALL	KEYBOARD
		POP	DE
		POP	BC
		POP	HL
		POP	AF
		EI
		RET

; A continuation of the code at #0008
ERROR_2:	POP	HL
		LD	L,(HL)
ERROR_3:	LD	(IY+#00),L
		LD	SP,(#5C3D)
		JP	SET_STK

; Unused bytes
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DB	#FF

; Non-maskable interrupt routine
; RST #66
RESET:		JP	NMI_MENU		; BSROM - jumps to NMI menu

		DB	#B0			; Looks like this is unused torso 
		DB	#5C			; of the original RESET routine.
		DB	#7C			;
		DB	#B5			;
		DB	#20, #01		;
		DB	#E9			;
		DB	#E1			;
		DB	#F1			;
		DB	#ED, #45		; End of unused bytes.

; Fetch the next immediate character following the current valid character address
; and update the associated system variable.
CH_ADD_1:	LD	HL,(#5C5D)
TEMP_PTR1:	INC	HL
TEMP_PTR2:	LD	(#5C5D),HL
		LD	A,(HL)
		RET

; Skip over white-space and other characters irrelevant to the parsing of a basic line
SKIP_OVER:	CP	#21
		RET	NC
		CP	#0D
		RET	Z
		CP	#10
		RET	C
		CP	#18
		CCF
		RET	C
		INC	HL
		CP	#16
		JR	C,SKIPS
		INC	HL
SKIPS:		SCF
		LD	(#5C5D),HL
		RET

; Six look-up tables for keyboard reading routine to decode the key values.
; Table for tokenized characters (134d-255d).
; Begins with function type words without a leading space.
; The last byte of a token is inverted to denote the end of the word.
TKN_TABLE:	DC	"?"				
		DC	"RND"
		DC	"INKEY$"
		DC	"PI"
		DC	"FN"
		DC	"POINT"
		DC	"SCREEN$"
		DC	"ATTR"
		DC	"AT"
		DC	"TAB"
		DC	"VAL$"
		DC	"CODE"
		DC	"VAL"
		DC	"LEN"
		DC	"SIN"
		DC	"COS"
		DC	"TAN"
		DC	"ASN"
		DC	"ACS"
		DC	"ATN"
		DC	"LN"
		DC	"EXP"
		DC	"INT"
		DC	"SQR"
		DC	"SGN"
		DC	"ABS"
		DC	"PEEK"
		DC	"IN"
		DC	"USR"
		DC	"STR$"
		DC	"CHR$"
		DC	"NOT"
		DC	"BIN"
		
; Function type words with a leading space
; if they begin with a letter.	
		DC	"OR"			
		DC	"AND"
		DC	"<="
		DC	">="
		DC	"<>"
		DC	"LINE"
		DC	"THEN"
		DC	"TO"
		DC	"STEP"
		DC	"DEF FN"
		DC	"CAT"
		DC	"FORMAT"
		DC	"MOVE"
		DC	"ERASE"
		DC	"OPEN #"
		DC	"CLOSE #"
		DC	"MERGE"
		DC	"VERIFY"
		DC	"BEEP"
		DC	"CIRCLE"
		DC	"INK"
		DC	"PAPER"
		DC	"FLASH"
		DC	"BRIGHT"
		DC	"INVERSE"
		DC	"OVER"
		DC	"OUT"
		DC	"LPRINT"
		DC	"LLIST"
		DC	"STOP"
		DC	"READ"
		DC	"DATA"
		DC	"RESTORE"
		DC	"NEW"
		DC	"BORDER"
		DC	"CONTINUE"
		DC	"DIM"
		DC	"REM"
		DC	"FOR"
		DC	"GO TO"
		DC	"GO SUB"
		DC	"INPUT"
		DC	"LOAD"
		DC	"LIST"
		DC	"LET"
		DC	"PAUSE"
		DC	"NEXT"
		DC	"POKE"
		DC	"PRINT"
		DC	"PLOT"
		DC	"RUN"
		DC	"SAVE"
		DC	"RANDOMIZE"
		DC	"IF"
		DC	"CLS"
		DC	"DRAW"
		DC	"CLEAR"
		DC	"RETURN"
		DC	"COPY"

; maps for the standard 40-key ZX Spectrum keyboard
; SHIFT (#27) is read directly.
MAIN_KEYS:	DB	#42			;B
		DB	#48			;H
		DB	#59			;Y
		DB	#36			;6
		DB	#35			;5
		DB	#54			;T
		DB	#47			;G
		DB	#56			;V
		DB	#4E			;N
		DB	#4A			;J
		DB	#55			;U
		DB	#37			;7
		DB	#34			;4
		DB	#52			;R
		DB	#46			;F
		DB	#43			;C
		DB	#4D			;M
		DB	#4B			;K
		DB	#49			;I
		DB	#38			;8
		DB	#33			;3
		DB	#45			;E
		DB	#44			;D
		DB	#58			;X
		DB	#0E			;Symbol shift
		DB	#4C			;L
		DB	#4F			;O
		DB	#39			;9
		DB	#32			;2
		DB	#57			;W
		DB	#53			;S
		DB	#5A			;Z
		DB	#20			;Space
		DB	#0D			;Enter
		DB	#50			;P
		DB	#30			;0
		DB	#31			;1
		DB	#51			;Q
		DB	#41			;A

; Unshifted extended mode keys.
; The green keywords on the original keyboard.
E_UNSHIFT:	DB	#E3			;READ
		DB	#C4			;BIN
		DB	#E0			;LPRINT
		DB	#E4			;DATA
		DB	#B4			;TAN
		DB	#BC			;SGN
		DB	#BD			;ABS
		DB	#BB			;SQR
		DB	#AF			;CODE
		DB	#B0			;VAL
		DB	#B1			;LEN
		DB	#C0			;USR
		DB	#A7			;PI
		DB	#A6			;INKEY$
		DB	#BE			;PEEK
		DB	#AD			;TAB
		DB	#B2			;SIN
		DB	#BA			;INT
		DB	#E5			;RESTORE
		DB	#A5			;RND
		DB	#C2			;CHR$
		DB	#E1			;LLIST
		DB	#B3			;COS
		DB	#B9			;EXP
		DB	#C1			;STR$
		DB	#B8			;LN

; Shifted extended mode keys.
; The red keywords below keys on the original keyboard.
EXT_SHIFT:	DB	#7E			;~
		DB	#DC			;BRIGHT
		DB	#DA			;PAPER
		DB	#5C			;\
		DB	#B7			;ATN
		DB	#7B			;{
		DB	#7D			;}
		DB	#D8			;CIRCLE
		DB	#BF			;IN
		DB	#AE			;VAL$
		DB	#AA			;SCREEN$
		DB	#AB			;ATTR
		DB	#DD			;INVERSE
		DB	#DE			;OVER
		DB	#DF			;OUT
		DB	#7F			;(c)
		DB	#B5			;ASN
		DB	#D6			;VERIFY
		DB	#7C			;|
		DB	#D5			;MERGE
		DB	#5D			;]
		DB	#DB			;FLASH
		DB	#B6			;ACS
		DB	#D9			;INK
		DB	#5B			;[
		DB	#D7			;BEEP

; Shift key control codes assigned to the digits.
; White labels above the number characters on the digits keys on the orig. keyboard.
CTL_CODES:	DB	#0C			;DELETE
		DB	#07			;EDIT
		DB	#06			;Caps lock
		DB	#04			;True video
		DB	#05			;Inverse video
		DB	#08			;Cursor left
		DB	#0A			;Cursor down
		DB	#0B			;Cursor up
		DB	#09			;Cursor right
		DB	#0F			;GRAPH

; Keys shifted with Symbol shift.
; Red symbols on the alphabetic characters on the original keyboard.
SYM_CODES:	DB	#E2			;STOP
		DB	#2A			;*
		DB	#3F			;?
		DB	#CD			;STEP
		DB	#C8			;>=
		DB	#CC			;TO
		DB	#CB			;THEN
		DB	#5E			;^
		DB	#AC			;AT
		DB	#2D			;-
		DB	#2B			;+
		DB	#3D			;=
		DB	#2E			;.
		DB	#2C			;,
		DB	#3B			;;
		DB	#22			;"
		DB	#C7			;<=
		DB	#3C			;<
		DB	#C3			;NOT
		DB	#3E			;>
		DB	#C5			;OR
		DB	#2F			;/
		DB	#C9			;<>
		DB	#60			;£
		DB	#C6			;AND
		DB	#3A			;:

; Keywords assigned to the digits in extended mode.
; On the original keyboard those are remaining red keywords below the keys.
E_DIGITS:	DB	#D0			;FORMAT
		DB	#CE			;DEF FN
		DB	#A8			;FN
		DB	#CA			;LINE
		DB	#D3			;OPEN #
		DB	#D4			;CLOSE #
		DB	#D1			;MOVE
		DB	#D2			;ERASE
		DB	#A9			;POINT
		DB	#CF			;CAT

; Keyboard scanning
; returns 1 or 2 keys in DE
KEY_SCAN:	LD	L,#2F
		LD	DE,#FFFF
		LD	BC,#FEFE
KEY_LINE:	IN	A,(C)
		CPL
		AND	#1F
		JR	Z,KEY_DONE
		LD	H,A
		LD	A,L
KEY_3KEYS:	INC	D
		RET	NZ
KEY_BITS:	SUB	#08
		SRL	H
		JR	NC,KEY_BITS
		LD	D,E
		LD	E,A
		JR	NZ,KEY_3KEYS
KEY_DONE:	DEC	L
		RLC	B
		JR	C,KEY_LINE
		LD	A,D
		INC	A
		RET	Z
		CP	#28
		RET	Z
		CP	#19
		RET	Z
		LD	A,E
		LD	E,D
		LD	D,A
		CP	#18
		RET

; Scan keyboard and decode value
KEYBOARD:	CALL	KEY_SCAN
		RET	NZ
		LD	HL,#5C00
K_ST_LOOP:	BIT	7,(HL)
		JR	NZ,K_CH_SET
		INC	HL
		DEC	(HL)
		DEC	HL
		JR	NZ,K_CH_SET
		LD	(HL),#FF
K_CH_SET:	LD	A,L
		LD	HL,#5C04
		CP	L
		JR	NZ,K_ST_LOOP
		CALL	K_TEST
		RET	NC
		LD	HL,#5C00
		CP	(HL)
		JR	Z,K_REPEAT
		EX	DE,HL
		LD	HL,#5C04
		CP	(HL)
		JR	Z,K_REPEAT
		BIT	7,(HL)
		JR	NZ,K_NEW
		EX	DE,HL
		BIT	7,(HL)
		RET	Z
K_NEW:		LD	E,A
		LD	(HL),A
		INC	HL
		LD	(HL),#05
		INC	HL
		LD	A,(#5C09)
		LD	(HL),A
		INC	HL
		LD	C,(IY+#07)
		LD	D,(IY+#01)
		PUSH	HL
		CALL	K_DECODE
		POP	HL
		LD	(HL),A
K_END:		LD	(#5C08),A
		SET	5,(IY+#01)
		RET

; Repeat key routine
K_REPEAT:	INC	HL
		LD	(HL),#05
		INC	HL
		DEC	(HL)
		RET	NZ
		LD	A,(#5C0A)
		LD	(HL),A
		INC	HL
		LD	A,(HL)
		JR	K_END

; Test key value
K_TEST:		LD	B,D
		LD	D,#00
		LD	A,E
		CP	#27
		RET	NC
		CP	#18
		JR	NZ,K_MAIN
		BIT	7,B
		RET	NZ
K_MAIN:		LD	HL,MAIN_KEYS
		ADD	HL,DE
		LD	A,(HL)
		SCF
		RET

; Keyboard decoding
K_DECODE:	LD	A,E
		CP	#3A
		JR	C,K_DIGIT
		DEC	C
		JP	M,K_KLC_LET
		JR	Z,K_E_LET
		ADD	A,#4F
		RET

; Test if B is empty (i.e. not a shift)
; forward to K_LOOK_UP if neither shift
K_E_LET:	LD	HL,#01EB		;E_UNSHIFT-#41
		INC	B
		JR	Z,K_LOOK_UP
		LD	HL,#0205		;EXT_SHIFT-#41

; Prepare to index
K_LOOK_UP:	LD	D,#00
		ADD	HL,DE
		LD	A,(HL)
		RET

; Prepare base of SYM_CODES
K_KLC_LET:	LD	HL,#0229		;SYM_CODES-#41
		BIT	0,B
		JR	Z,K_LOOK_UP
		BIT	3,D
		JR	Z,K_TOKENS
		BIT	3,(IY+#30)
		RET	NZ
		INC	B
		RET	NZ
		ADD	A,#20
		RET
; Add offset to main code to get tokens
K_TOKENS:	ADD	A,#A5
		RET

; Digits, space, enter and symbol shift decoding
K_DIGIT:	CP	#30
		RET	C
		DEC	C
		JP	M,K_KLC_DGT
		JR	NZ,K_GRA_DGT
		LD	HL,#0254		;E_DIGITS-#30
		BIT	5,B
		JR	Z,K_LOOK_UP
		CP	#38
		JR	NC,K_8_AND_9
		SUB	#20
		INC	B
		RET	Z
		ADD	A,#08
		RET

; Digits 8 and 9 decoding
K_8_AND_9:	SUB	#36
		INC	B
		RET	Z
		ADD	A,#FE
		RET

; Graphics mode with digits
K_GRA_DGT:	LD	HL,#0230		;CTL_CODES-#30
		CP	#39
		JR	Z,K_LOOK_UP
		CP	#30
		JR	Z,K_LOOK_UP
		AND	#07
		ADD	A,#80
		INC	B
		RET	Z
		XOR	#0F
		RET

; Digits in 'KLC' mode
K_KLC_DGT:	INC	B
		RET	Z
		BIT	5,B
		LD	HL,#0230		;CTL_CODES-#30
		JR	NZ,K_LOOK_UP
		SUB	#10
		CP	#22
		JR	Z,K_AT_CHAR
		CP	#20
		RET	NZ
		LD	A,#5F
		RET

; Substitute ascii '@'
K_AT_CHAR:	LD	A,#40
		RET

; Routine to control loudspeaker
BEEPER:		DI
		LD	A,L
		SRL	L
		SRL	L
		CPL
		AND	#03
		LD	C,A
		LD	B,#00
		LD	IX,BE_IX_3
		ADD	IX,BC
		LD	A,(#5C48)
		AND	#38
		RRCA
		RRCA
		RRCA
		OR	#08
BE_IX_3:	NOP
		NOP
		NOP
		INC	B
		INC	C
BE_HL_LP:	DEC	C
		JR	NZ,BE_HL_LP
		LD	C,#3F
		DEC	B
		JP	NZ,BE_HL_LP
		XOR	#10
		OUT	(#FE),A
		LD	B,H
		LD	C,A
		BIT	4,A
		JR	NZ,BE_AGAIN
		LD	A,D
		OR	E
		JR	Z,BE_END
		LD	A,C
		LD	C,L
		DEC	DE
L_03F0:		JP	(IX)
BE_AGAIN:	LD	C,L
		INC	C
		JP	(IX)
BE_END:		EI
		RET

; Handle BEEP command
BEEP:		RST	#28			;FP_CALC
		DB	#31			;DUPLICATE - duplicate pitch
		DB	#27			;INT - convert to integer
		DB	#C0			;ST_MEM_0 - store integer pitch to memory 0
		DB	#03			;SUBTRACT - calculate fractional part of pitch = fp_pitch - int_pitch
		DB	#34			;STK_DATA - push constant
		DB	#EC			;Exponent: #7C, Bytes: 4 - constant = 0.05762265
		DB	#6C,#98,#1F,#F5 	;(#6C,#98,#1F,#F5)
		DB	#04			;MULTIPLY - compute:
		DB	#A1			;STK_ONE - 1 + 0.05762265 * fraction_part(pitch)
		DB	#0F			;ADDITION
		DB	#38			;END_CALC - leave on calc stack

		LD	HL,#5C92
		LD	A,(HL)
		AND	A
		JR	NZ,REPORT_B
		INC	HL
		LD	C,(HL)
		INC	HL
		LD	B,(HL)
		LD	A,B
		RLA
		SBC	A,A
		CP	C
		JR	NZ,REPORT_B
		INC	HL
		CP	(HL)
		JR	NZ,REPORT_B
		LD	A,B
		ADD	A,#3C
		JP	P,BE_I_OK
		JP	PO,REPORT_B
BE_I_OK:	LD	B,#FA
BE_OCTAVE:	INC	B
		SUB	#0C
		JR	NC,BE_OCTAVE
		ADD	A,#0C
		PUSH	BC
		LD	HL,SEMI_TONE
		CALL	LOC_MEM
		CALL	STACK_NUM

		RST	#28			;FP_CALC
		DB	#04			;MULTIPLY
		DB	#38			;END_CALC

		POP	AF
		ADD	A,(HL)
		LD	(HL),A

		RST	#28			;FP_CALC
		DB	#C0			;ST_MEM_0
		DB	#02			;DELETE
		DB	#31			;DUPLICATE
		DB	#38			;END_CALC

		CALL	FIND_INT1
		CP	#0B
		JR	NC,REPORT_B

		RST	#28			;FP_CALC
		DB	#E0			;GET_MEM_0
		DB	#04			;MULTIPLY
		DB	#E0			;GET_MEM_0
		DB	#34			;STK_DATA
		DB	#80			;Exponent #93, Bytes: 3
		DB	#43, #55, #9F, #80
		DB	#01			;EXCHANGE
		DB	#05			;DIVISION
		DB	#34			;STK_DATA
		DB	#35			;Exponent: #85, Bytes: 1
		DB	#71
		DB	#03			;SUBTRACT
		DB	#38			;END_CALC

		CALL	FIND_INT2
		PUSH	BC
		CALL	FIND_INT2
		POP	HL
		LD	D,B
		LD	E,C
		LD	A,D
		OR	E
		RET	Z
		DEC	DE
		JP	BEEPER

REPORT_B:	RST	#08			; Error report
		DB	#0A			; Integer out of range

; Semi-tone table.
; Holds frequencies corresponding to semitones in middle octave.
SEMI_TONE:	DB	#89, #02, #D0, #12, #86
		DB	#89, #0A, #97, #60, #75
		DB	#89, #12, #D5, #17, #1F
		DB	#89, #1B, #90, #41, #02
		DB	#89, #24, #D0, #53, #CA
		DB	#89, #2E, #9D, #36, #B1
		DB	#89, #38, #FF, #49, #3E
		DB	#89, #43, #FF, #6A, #73
		DB	#89, #4F, #A7, #00, #54
		DB	#89, #5C, #00, #00, #00
		DB	#89, #69, #14, #F6, #24
		DB	#89, #76, #F1, #10, #05

; BSROM - file name is optional now.
; There was ZX81_NAME routine at this place, but it was not used anyway.
NONAME:		RST	#18
		LD	HL,NNTAB
		LD	BC,#0005
		CPIR
		JP	NZ,EXPT_EXP
		LD	C,#00
		JP	SL_OVER1
NNTAB:		DB	#3A
		DW	#AA0D
		DW	#E4AF
		DW	#0000

; Save header and program or data
SA_BYTES:	LD	HL,SA_LD_RET
		PUSH	HL
SA_BYTES1:	LD	HL,#1F80
		BIT	7,A
		JR	Z,SA_FLAG
		LD	HL,#0C98
SA_FLAG:	EX	AF,AF'
		INC	DE
		DEC	IX
		DI
		LD	A,#02
		LD	B,A
SA_LEADER:	DJNZ	SA_LEADER
		OUT	(#FE),A
		XOR	#0F
		LD	B,#A4
		DEC	L
		JR	NZ,SA_LEADER
		DEC	B
		DEC	H
		JP	P,SA_LEADER
		LD	B,#2F
SA_SYNC_1:	DJNZ	SA_SYNC_1
		OUT	(#FE),A
		LD	A,#0D
		LD	B,#37
SA_SYNC_2:	DJNZ	SA_SYNC_2
		OUT	(#FE),A
		LD	BC,#3B0E		; B=#3B time; C=#0E YELLOW, MIC OFF.
		EX	AF,AF'
		LD	L,A
		JP	SA_START

SA_LOOP:	LD	A,D
		OR	E
		JR	Z,SA_PARITY
		LD	L,(IX+#00)
SA_LOOP_P:	LD	A,H
		XOR	L
SA_START:	LD	H,A
		LD	A,#01
		SCF
		JP	SA_8_BITS

SA_PARITY:	LD	L,H
		JR	SA_LOOP_P

SA_BIT_2:	LD	A,C
		BIT	7,B
SA_BIT_1:	DJNZ	SA_BIT_1
		JR	NC,SA_OUT
		LD	B,#42
SA_SET:		DJNZ	SA_SET
SA_OUT:		OUT	(#FE),A
		LD	B,#3E
		JR	NZ,SA_BIT_2
		DEC	B
		XOR	A
		INC	A
SA_8_BITS:	RL	L
		JP	NZ,SA_BIT_1
		DEC	DE
		INC	IX
		LD	B,#31
		LD	A,#7F
		IN	A,(#FE)
		RRA
		RET	NC
		LD	A,D
		INC	A
		JP	NZ,SA_LOOP
		LD	B,#3B
SA_DELAY:	DJNZ	SA_DELAY
		RET

; Reset border nad check BREAK for LOAD and SAVE
SA_LD_RET:	PUSH	AF
		LD	A,(#5C48)
		AND	#38
		RRCA
		RRCA
		RRCA
		OUT	(#FE),A
		LD	A,#7F
		IN	A,(#FE)
		RRA
		EI
		JR	C,SA_LD_END
REPORT_DA:	RST	#08			; Error report
		DB	#0C			; BREAK - CONT repeats
SA_LD_END:	POP	AF
		RET

; Load header or data
LD_BYTES:	INC	D
		EX	AF,AF'
		DEC	D
		DI
		LD	A,#0F
		OUT	(#FE),A
		LD	HL,SA_LD_RET
		PUSH	HL
		IN	A,(#FE)
		RRA
LD_BYTES1:	AND	#20
		OR	#02
		LD	C,A
		CP	A
LD_BREAK:	RET	NZ
LD_START:	CALL	LD_EDGE_1
		JR	NC,LD_BREAK
		LD	HL,#0115		; BSROM - short delay (was #0415 in orig. ROM)
LD_WAIT:	DJNZ	LD_WAIT
		DEC	HL
		LD	A,H
		OR	L
		JR	NZ,LD_WAIT
		CALL	LD_EDGE_2
		JR	NC,LD_BREAK
LD_LEADER:	LD	B,#9C
		CALL	LD_EDGE_2
		JR	NC,LD_BREAK
		LD	A,#C6
		CP	B
		JR	NC,LD_START
		INC	H
		JR	NZ,LD_LEADER
LD_SYNC:	LD	B,#C9
		CALL	LD_EDGE_1
		JR	NC,LD_BREAK
		LD	A,B
		CP	#D4
		JR	NC,LD_SYNC
		CALL	LD_EDGE_1
		RET	NC
		LD	A,C
		XOR	#03
		LD	C,A
		LD	H,#00
		LD	B,#B0
		JR	LD_MARKER

LD_LOOP:	EX	AF,AF'
		JR	NZ,LD_FLAG
		JR	NC,LD_VERIFY
		LD	(IX+#00),L
		JR	LD_NEXT

LD_FLAG:	RL	C
		XOR	L
		RET	NZ
		LD	A,C
		RRA
		LD	C,A
		INC	DE
		JR	LD_DEC

LD_VERIFY:	LD	A,(IX+#00)
		XOR	L
		RET	NZ
LD_NEXT:	INC	IX
LD_DEC:		DEC	DE
		EX	AF,AF'
		LD	B,#B2
LD_MARKER:	LD	L,#01
LD_8_BITS:	CALL	LD_EDGE_2
		RET	NC
		LD	A,#CB
		CP	B
		RL	L
		LD	B,#B0
		JP	NC,LD_8_BITS
		LD	A,H
		XOR	L
		LD	H,A
		LD	A,D
		OR	E
		JR	NZ,LD_LOOP
		LD	A,H
		CP	#01
		RET

; Check signal being loaded
LD_EDGE_2:	CALL	LD_EDGE_1
		RET	NC
LD_EDGE_1:	LD	A,#16
LD_DELAY:	DEC	A
		JR	NZ,LD_DELAY
		AND	A
LD_SAMPLE:	INC	B
		RET	Z
		LD	A,#7F
		IN	A,(#FE)
		RRA
		RET	NC
		XOR	C
		AND	#20
		JR	Z,LD_SAMPLE
		LD	A,C
		CPL
		LD	C,A
		AND	#07
		OR	#08
		OUT	(#FE),A
		SCF
		RET

; Entry point for tape commands
SAVE_ETC:	POP	AF
		LD	A,(#5C74)
		SUB	#E0
		LD	(#5C74),A
		CALL	NONAME			; BSROM - file name is optional now
		CALL	SYNTAX_Z
		JR	Z,SA_DATA
		LD	BC,#0011
		LD	A,(#5C74)
		AND	A
		JR	Z,SA_SPACE
		LD	C,#22
SA_SPACE:	RST	#30
		PUSH	DE
		POP	IX
		LD	B,#0B
		LD	A,#20
SA_BLANK:	LD	(DE),A
		INC	DE
		DJNZ	SA_BLANK
		LD	(IX+#01),#FF
		CALL	STK_FETCH
		LD	HL,#FFF6
		DEC	BC
		ADD	HL,BC
		INC	BC
		JR	NC,SA_NAME
		LD	A,(#5C74)
		AND	A
		JR	NZ,SA_NULL
REPORT_FA:	RST	#08			; Error report
		DB	#0E			; Invalid file name
SA_NULL:	LD	A,B
		OR	C
		JR	Z,SA_DATA
		LD	BC,#000A
SA_NAME:	PUSH	IX
		POP	HL
		INC	HL
		EX	DE,HL
		LDIR
SA_DATA:	RST	#18
		CP	#E4
		JR	NZ,SA_SCR
		LD	A,(#5C74)
		CP	#03
		JP	Z,REPORT_C
		RST	#20
		CALL	LOOK_VARS
		SET	7,C
		JR	NC,SA_V_OLD
		LD	HL,#0000
		LD	A,(#5C74)
		DEC	A
		JR	Z,SA_V_NEW
REPORT_2A:	RST	#08			; Error report
		DB	#01			; Variable not found
SA_V_OLD:	JP	NZ,REPORT_C
		CALL	SYNTAX_Z
		JR	Z,SA_DATA_1
		INC	HL
		LD	A,(HL)
		LD	(IX+#0B),A
		INC	HL
		LD	A,(HL)
		LD	(IX+#0C),A
		INC	HL
SA_V_NEW:	LD	(IX+#0E),C
		LD	A,#01
		BIT	6,C
		JR	Z,SA_V_TYPE
		INC	A
SA_V_TYPE:	LD	(IX+#00),A
SA_DATA_1:	EX	DE,HL
		RST	#20
		CP	#29
		JR	NZ,SA_V_OLD
		RST	#20
		CALL	CHECK_END
		EX	DE,HL
		JP	SA_ALL

SA_SCR:		CP	#AA
		JR	NZ,SA_CODE
		LD	A,(#5C74)
		CP	#03
		JP	Z,REPORT_C
		RST	#20
		CALL	CHECK_END
		LD	(IX+#0B),#00
		LD	(IX+#0C),#1B
		LD	HL,#4000
		LD	(IX+#0D),L
		LD	(IX+#0E),H
		JR	SA_TYPE_3

SA_CODE:	CP	#AF
		JR	NZ,SA_LINE
		LD	A,(#5C74)
		CP	#03
		JP	Z,REPORT_C
		RST	#20
		CALL	PR_ST_END
		JR	NZ,SA_CODE_1
		LD	A,(#5C74)
		AND	A
		JP	Z,REPORT_C
		CALL	USE_ZERO
		JR	SA_CODE_2

SA_CODE_1:	CALL	EXPT_1NUM
		RST	#18
		CP	#2C
		JR	Z,SA_CODE_3
		LD	A,(#5C74)
		AND	A
		JP	Z,REPORT_C
SA_CODE_2:	CALL	USE_ZERO
		JR	SA_CODE_4

SA_CODE_3:	RST	#20
		CALL	EXPT_1NUM
SA_CODE_4:	CALL	CHECK_END
		CALL	FIND_INT2
		LD	(IX+#0B),C
		LD	(IX+#0C),B
		CALL	FIND_INT2
		LD	(IX+#0D),C
		LD	(IX+#0E),B
		LD	H,B
		LD	L,C
SA_TYPE_3:	LD	(IX+#00),#03
		JR	SA_ALL

SA_LINE:	CP	#CA
		JR	Z,SA_LINE_1
		CALL	CHECK_END
		LD	(IX+#0E),#80
		JR	SA_TYPE_0

SA_LINE_1:	LD	A,(#5C74)
		AND	A
		JP	NZ,REPORT_C
		RST	#20
		CALL	EXPT_1NUM
		CALL	CHECK_END
		CALL	FIND_INT2
		LD	(IX+#0D),C
		LD	(IX+#0E),B
SA_TYPE_0:	LD	(IX+#00),#00
		LD	HL,(#5C59)
		LD	DE,(#5C53)
		SCF
		SBC	HL,DE
		LD	(IX+#0B),L
		LD	(IX+#0C),H
		LD	HL,(#5C4B)
		SBC	HL,DE
		LD	(IX+#0F),L
		LD	(IX+#10),H
		EX	DE,HL
SA_ALL:		LD	A,(#5C74)
		AND	A
		JP	Z,SA_CONTRL
		PUSH	HL
		LD	BC,#0011
		ADD	IX,BC
LD_LOOK_H:	PUSH	IX
		LD	DE,#0011
		XOR	A
		SCF
		CALL	LD_BYTES
		POP	IX
		JR	NC,LD_LOOK_H
		LD	A,#FE
		CALL	CHAN_OPEN
		LD	(IY+#52),#FF		; BSROM - fixed "scroll?" troubles when tape header is shown, was LD (IY+$52),$03
		LD	C,#80
		LD	A,(IX+#00)
		CP	(IX-#11)
		JR	NZ,LD_TYPE
		LD	C,#F6
LD_TYPE:	CP	#04
		JR	NC,LD_LOOK_H
		LD	DE,TAPE_MSGS2
		PUSH	BC
		CALL	PO_MSG
		POP	BC
		PUSH	IX
		POP	DE
		LD	HL,#FFF0
		ADD	HL,DE
		LD	B,#0A
		LD	A,(HL)
		INC	A
		JR	NZ,LD_NAME
		LD	A,C
		ADD	A,B
		LD	C,A
LD_NAME:	INC	DE
		LD	A,(DE)
		CP	(HL)
		INC	HL
		JR	NZ,LD_CH_PR
		INC	C
LD_CH_PR:	RST	#10
		DJNZ	LD_NAME
		BIT	7,C
		JR	NZ,LD_LOOK_H
		LD	A,#0D
		RST	#10
		POP	HL
		LD	A,(IX+#00)
		CP	#03
		JR	Z,VR_CONTROL
		LD	A,(#5C74)
		DEC	A
		JP	Z,LD_CONTRL
		CP	#02
		JP	Z,ME_CONTRL
VR_CONTROL:	PUSH	HL			; Handle VERIFY control
		LD	L,(IX-#06)
		LD	H,(IX-#05)
		LD	E,(IX+#0B)
		LD	D,(IX+#0C)
		LD	A,H
		OR	L
		JR	Z,VR_CONT_1
		SBC	HL,DE
		JR	C,REPORT_R
		JR	Z,VR_CONT_1
		LD	A,(IX+#00)
		CP	#03
		JR	NZ,REPORT_R
VR_CONT_1:	POP	HL
		LD	A,H
		OR	L
		JR	NZ,VR_CONT_2
		LD	L,(IX+#0D)
		LD	H,(IX+#0E)
VR_CONT_2:	PUSH	HL
		POP	IX
		LD	A,(#5C74)
		CP	#02
		SCF
		JR	NZ,VR_CONT_3
		AND	A
VR_CONT_3:	LD	A,#FF
LD_BLOCK:	CALL	LD_BYTES		; Load a block of data
		RET	C
REPORT_R:	RST	#08			; Error report
		DB	#1A			; Tape loading error
LD_CONTRL:	LD	E,(IX+#0B)		; Handle LOAD control
		LD	D,(IX+#0C)
		PUSH	HL
		LD	A,H
		OR	L
		JR	NZ,LD_CONT_1
		INC	DE
		INC	DE
		INC	DE
		EX	DE,HL
		JR	LD_CONT_2

LD_CONT_1:	LD	L,(IX-#06)
		LD	H,(IX-#05)
		EX	DE,HL
		SCF
		SBC	HL,DE
		JR	C,LD_DATA
LD_CONT_2:	LD	DE,#0005
		ADD	HL,DE
		LD	B,H
		LD	C,L
		CALL	TEST_ROOM
LD_DATA:	POP	HL
		LD	A,(IX+#00)
		AND	A
		JR	Z,LD_PROG
		LD	A,H
		OR	L
		JR	Z,LD_DATA_1
		DEC	HL
		LD	B,(HL)
		DEC	HL
		LD	C,(HL)
		DEC	HL
		INC	BC
		INC	BC
		INC	BC
		LD	(#5C5F),IX
		CALL	RECLAIM_2
		LD	IX,(#5C5F)
LD_DATA_1:	LD	HL,(#5C59)
		DEC	HL
		LD	C,(IX+#0B)
		LD	B,(IX+#0C)
		PUSH	BC
		INC	BC
		INC	BC
		INC	BC
		LD	A,(IX-#03)
		PUSH	AF
		CALL	MAKE_ROOM
		INC	HL
		POP	AF
		LD	(HL),A
		POP	DE
		INC	HL
		LD	(HL),E
		INC	HL
		LD	(HL),D
		INC	HL
		PUSH	HL
		POP	IX
		SCF
		LD	A,#FF
		JP	LD_BLOCK

LD_PROG:	EX	DE,HL
		LD	HL,(#5C59)
		DEC	HL
		LD	(#5C5F),IX
		LD	C,(IX+#0B)
		LD	B,(IX+#0C)
		PUSH	BC
		CALL	RECLAIM_1
		POP	BC
		PUSH	HL
		PUSH	BC
		CALL	MAKE_ROOM
		LD	IX,(#5C5F)
		INC	HL
		LD	C,(IX+#0F)
		LD	B,(IX+#10)
		ADD	HL,BC
		LD	(#5C4B),HL
		LD	H,(IX+#0E)
		LD	A,H
		AND	#C0
		JR	NZ,LD_PROG_1
		LD	L,(IX+#0D)
		LD	(#5C42),HL
		LD	(IY+#0A),#00
LD_PROG_1:	POP	DE
		POP	IX
		SCF
		LD	A,#FF
		JP	LD_BLOCK

; Handle MERGE control
ME_CONTRL:	LD	C,(IX+#0B)
		LD	B,(IX+#0C)
		PUSH	BC
		INC	BC
		RST	#30
		LD	(HL),#80
		EX	DE,HL
		POP	DE
		PUSH	HL
		PUSH	HL
		POP	IX
		SCF
		LD	A,#FF
		CALL	LD_BLOCK
		POP	HL
		LD	DE,(#5C53)
ME_NEW_LP:	LD	A,(HL)
		AND	#C0
		JR	NZ,ME_VAR_LP
ME_OLD_LP:	LD	A,(DE)
		INC	DE
		CP	(HL)
		INC	HL
		JR	NZ,ME_OLD_L1
		LD	A,(DE)
		CP	(HL)
ME_OLD_L1:	DEC	DE
		DEC	HL
		JR	NC,ME_NEW_L2
		PUSH	HL
		EX	DE,HL
		CALL	NEXT_ONE
		POP	HL
		JR	ME_OLD_LP

ME_NEW_L2:	CALL	ME_ENTER
		JR	ME_NEW_LP

ME_VAR_LP:	LD	A,(HL)
		LD	C,A
		CP	#80
		RET	Z
		PUSH	HL
		LD	HL,(#5C4B)
ME_OLD_VP:	LD	A,(HL)
		CP	#80
		JR	Z,ME_VAR_L2
		CP	C
		JR	Z,ME_OLD_V2
ME_OLD_V1:	PUSH	BC
		CALL	NEXT_ONE
		POP	BC
		EX	DE,HL
		JR	ME_OLD_VP

ME_OLD_V2:	AND	#E0
		CP	#A0
		JR	NZ,ME_VAR_L1
		POP	DE
		PUSH	DE
		PUSH	HL
ME_OLD_V3:	INC	HL
		INC	DE
		LD	A,(DE)
		CP	(HL)
		JR	NZ,ME_OLD_V4
		RLA
		JR	NC,ME_OLD_V3
		POP	HL
		JR	ME_VAR_L1

ME_OLD_V4:	POP	HL
		JR	ME_OLD_V1

ME_VAR_L1:	LD	A,#FF
ME_VAR_L2:	POP	DE
		EX	DE,HL
		INC	A
		SCF
		CALL	ME_ENTER
		JR	ME_VAR_LP

; Merge a line or variable
ME_ENTER:	JR	NZ,ME_ENT_1
		EX	AF,AF'
		LD	(#5C5F),HL
		EX	DE,HL
		CALL	NEXT_ONE
		CALL	RECLAIM_2
		EX	DE,HL
		LD	HL,(#5C5F)
		EX	AF,AF'
ME_ENT_1:	EX	AF,AF'
		PUSH	DE
		CALL	NEXT_ONE
		LD	(#5C5F),HL
		LD	HL,(#5C53)
		EX	(SP),HL
		PUSH	BC
		EX	AF,AF'
		JR	C,ME_ENT_2
		DEC	HL
		CALL	MAKE_ROOM
		INC	HL
		JR	ME_ENT_3

ME_ENT_2:	CALL	MAKE_ROOM
ME_ENT_3:	INC	HL
		POP	BC
		POP	DE
		LD	(#5C53),DE
		LD	DE,(#5C5F)
		PUSH	BC
		PUSH	DE
		EX	DE,HL
		LDIR
		POP	HL
		POP	BC
		PUSH	DE
		CALL	RECLAIM_2
		POP	DE
		RET

; Handle SAVE control
SA_CONTRL:	PUSH	HL
		LD	A,#FD
		CALL	CHAN_OPEN
		XOR	A
		LD	DE,TAPE_MSGS
		CALL	PO_MSG
		SET	5,(IY+#02)
		CALL	WAIT_KEY
		PUSH	IX
		LD	DE,#0011
		XOR	A
		CALL	SA_BYTES
		POP	IX
		LD	B,#32
SA_1_SEC:	HALT
		DJNZ	SA_1_SEC
		LD	E,(IX+#0B)
		LD	D,(IX+#0C)
		POP	IX			; BSROM - LD A,#FF and POP IX swapped
		LD	A,#FF
		JP	SA_BYTES

; Tape mesages
TAPE_MSGS:	DB	#80
		DC	"Press REC & PLAY, then any key."
TAPE_MSGS2:	EQU	$-1
		DB	#0D
		DC	"Program: "
		DB	#0D
		DC	"Number array: "
		DB	#0D
		DC	"Character array: "
		DB	#0D
		DC	"Bytes: "

; Genereal PRINT routine
PRINT_OUT:	CALL	DISPL			; BSROM - disabled autolist of control codes
		CP	#1E
		JP	NC,PO_ABLE
		CP	#06
		JR	C,PO_QUEST
		CP	#18
		JR	NC,PO_QUEST
		LD	HL,CTLCHRTAB-6
		LD	E,A
		LD	D,#00
		ADD	HL,DE
		LD	E,(HL)
		ADD	HL,DE
		PUSH	HL
		JP	PO_FETCH

;Control character table
CTLCHRTAB:	DB	#4E			; PO_COMMA
		DB	#57			; PO_QUEST
		DB	#10			; PO_BACK_1
		DB	#29			; PO_RIGHT
		DB	#54			; PO_QUEST
		DB	#53			; PO_QUEST
		DB	#52			; PO_QUEST
		DB	#37			; PO_ENTER
		DB	#50			; PO_QUEST
		DB	#4F			; PO_QUEST
		DB	#5F			; PO_1_OPER
		DB	#5E			; PO_1_OPER
		DB	#5D			; PO_1_OPER
		DB	#5C			; PO_1_OPER
		DB	#5B			; PO_1_OPER
		DB	#5A			; PO_1_OPER
		DB	#54			; PO_2_OPER
		DB	#53			; PO_2_OPER

; Cursor left routine
PO_BACK_1:	INC	C
		LD	A,#22
		CP	C
		JR	NZ,PO_BACK_3
		BIT	1,(IY+#01)
		JR	NZ,PO_BACK_2
		INC	B
		LD	C,#02
		LD	A,#19			; BSROM - bugfix - was LD A,#18
		CP	B
		JR	NZ,PO_BACK_3
		DEC	B
PO_BACK_2:	LD	C,#21
PO_BACK_3:	JP	CL_SET

; Cursor right routine
PO_RIGHT:	LD	A,(#5C91)
		PUSH	AF
		LD	(IY+#57),#01
		LD	A,#20
		CALL	PO_ABLE			; BSROM - bugfix - was CALL PO_BACK
		POP	AF
		LD	(#5C91),A
		RET

; Carriage return / Enter
PO_ENTER:	BIT	1,(IY+#01)
		JP	NZ,COPY_BUFF
		LD	C,#21
		CALL	PO_SCR
		DEC	B
		JP	CL_SET

; Print comma
PO_COMMA:	CALL	PO_FETCH
		LD	A,C
		DEC	A
		DEC	A
		AND	#10
		JR	PO_FILL

; Print question mark
PO_QUEST:	LD	A,#3F
		JR	PO_ABLE

; Control characters with operands
PO_TV_2:	LD	DE,PO_CONT
		LD	(#5C0F),A
		JR	PO_CHANGE

PO_2_OPER:	LD	DE,PO_TV_2
		JR	PO_TV_1

PO_1_OPER:	LD	DE,PO_CONT
PO_TV_1:	LD	(#5C0E),A
PO_CHANGE:	LD	HL,(#5C51)
		LD	(HL),E
		INC	HL
		LD	(HL),D
		RET

PO_CONT:	LD	DE,PRINT_OUT
		CALL	PO_CHANGE
		LD	HL,(#5C0E)
		LD	D,A
		LD	A,L
		CP	#16
		JP	C,CO_TEMP_5
		JR	NZ,PO_TAB
		LD	B,H
		LD	C,D
		LD	A,#1F
		SUB	C
		JR	C,PO_AT_ERR
		ADD	A,#02
		LD	C,A
		BIT	1,(IY+#01)
		JR	NZ,PO_AT_SET
		LD	A,#16
		SUB	B
PO_AT_ERR:	JP	C,REPORT_BB
		INC	A
		LD	B,A
		INC	B
		BIT	0,(IY+#02)
		JP	NZ,PO_SCR
		CP	(IY+#31)
		JP	C,REPORT_5
PO_AT_SET:	JP	CL_SET

PO_TAB:		LD	A,H
PO_FILL:	CALL	PO_FETCH
		ADD	A,C
		DEC	A
		AND	#1F
		RET	Z
		LD	D,A
		SET	0,(IY+#01)
PO_SPACE:	LD	A,#20
		CALL	PO_SAVE
		DEC	D
		JR	NZ,PO_SPACE
		RET

; Print printable character(s)
PO_ABLE:	CALL	PO_ANY

; Store line, column and pixel address
PO_STORE:	BIT	1,(IY+#01)
		JR	NZ,PO_ST_PR
		BIT	0,(IY+#02)
		JR	NZ,PO_ST_E
		LD	(#5C88),BC
		LD	(#5C84),HL
		RET

PO_ST_E:	LD	(#5C8A),BC
		LD	(#5C82),BC
		LD	(#5C86),HL
		RET

PO_ST_PR:	LD	(IY+#45),C
		LD	(#5C80),HL
		RET

; Fetch position parameters
PO_FETCH:	BIT	1,(IY+#01)
		JR	NZ,PO_F_FR
		LD	BC,(#5C88)
		LD	HL,(#5C84)
		BIT	0,(IY+#02)
		RET	Z
		LD	BC,(#5C8A)
		LD	HL,(#5C86)
		RET

PO_F_FR:	LD	C,(IY+#45)
		LD	HL,(#5C80)
		RET

; Print any character
PO_ANY:		CP	#80
		JR	C,PO_CHAR
		CP	#90
		JR	NC,PO_T_UDG
		LD	B,A
		CALL	PO_GR_1
		CALL	PO_FETCH
		LD	DE,#5C92
		JR	PR_ALL

PO_GR_1:	LD	HL,#5C92
		CALL	PO_GR_2
PO_GR_2:	RR	B
		SBC	A,A
		AND	#0F
		LD	C,A
		RR	B
		SBC	A,A
		AND	#F0
		OR	C
		LD	C,#04
PO_GR_3:	LD	(HL),A
		INC	HL
		DEC	C
		JR	NZ,PO_GR_3
		RET

PO_T_UDG:	SUB	#A5
		JR	NC,PO_T
		ADD	A,#15
		PUSH	BC
		LD	BC,(#5C7B)
		JR	PO_CHAR_2

PO_T:		CALL	PO_TOKENS
		JP	PO_FETCH

PO_CHAR:	PUSH	BC
		LD	BC,(#5C36)
PO_CHAR_2:	EX	DE,HL
		LD	HL,#5C3B
		RES	0,(HL)
		CP	#20
		JR	NZ,PO_CHAR_3
		SET	0,(HL)
PO_CHAR_3:	LD	H,#00
		LD	L,A
		ADD	HL,HL
		ADD	HL,HL
		ADD	HL,HL
		ADD	HL,BC
		POP	BC
		EX	DE,HL
PR_ALL:		LD	A,C			; Print all characters
		DEC	A
		LD	A,#21
		JR	NZ,PR_ALL_1
		DEC	B
		LD	C,A
		BIT	1,(IY+#01)
		JR	Z,PR_ALL_1
		PUSH	DE
		CALL	COPY_BUFF
		POP	DE
		LD	A,C
PR_ALL_1:	CP	C
		PUSH	DE
		CALL	Z,PO_SCR
		POP	DE
		PUSH	BC
		PUSH	HL
		LD	A,(#5C91)
		LD	B,#FF
		RRA
		JR	C,PR_ALL_2
		INC	B
PR_ALL_2:	RRA
		RRA
		SBC	A,A
		LD	C,A
		LD	A,#08
		AND	A
		BIT	1,(IY+#01)
		JR	Z,PR_ALL_3
		SET	1,(IY+#30)
		SCF
PR_ALL_3:	EX	DE,HL
PR_ALL_4:	EX	AF,AF'
		LD	A,(DE)
		AND	B
		XOR	(HL)
		XOR	C
		LD	(DE),A
		EX	AF,AF'
		JR	C,PR_ALL_6
		INC	D
PR_ALL_5:	INC	HL
		DEC	A
		JR	NZ,PR_ALL_4
		EX	DE,HL
		DEC	H
		BIT	1,(IY+#01)
		CALL	Z,PO_ATTR
		POP	HL
		POP	BC
		DEC	C
		INC	HL
		RET

PR_ALL_6:	EX	AF,AF'
		LD	A,#20
		ADD	A,E
		LD	E,A
		EX	AF,AF'
		JR	PR_ALL_5

; Set attribute
PO_ATTR:	LD	A,H
		RRCA
		RRCA
		RRCA
		AND	#03
		OR	#58
		LD	H,A
		LD	DE,(#5C8F)
		LD	A,(HL)
		XOR	E
		AND	D
		XOR	E
		BIT	6,(IY+#57)
		JR	Z,PO_ATTR_1
		AND	#C7
		BIT	2,A
		JR	NZ,PO_ATTR_1
		XOR	#38
PO_ATTR_1:	BIT	4,(IY+#57)
		JR	Z,PO_ATTR_2
		AND	#F8
		BIT	5,A
		JR	NZ,PO_ATTR_2
		XOR	#07
PO_ATTR_2:	LD	(HL),A
		RET

; Message printing (boot-up, tape, scroll, error reports)
PO_MSG:		PUSH	HL
		LD	H,#00
		EX	(SP),HL
		JR	PO_TABLE

PO_TOKENS:	LD	DE,TKN_TABLE
PO_TOKENS1:	PUSH	AF
PO_TABLE:	CALL	PO_SEARCH
		JR	C,PO_EACH
		LD	A,#20
		BIT	0,(IY+#01)
		CALL	Z,PO_SAVE
PO_EACH:	LD	A,(DE)
		AND	#7F
		CALL	PO_SAVE
		LD	A,(DE)
		INC	DE
		ADD	A,A
		JR	NC,PO_EACH
		POP	DE
		CP	#48
		JR	Z,PO_TR_SP
		CP	#82
		RET	C
PO_TR_SP:	LD	A,D
		CP	#03
		RET	C
		LD	A,#20
PO_SAVE:	PUSH	DE			; Handle recursive printing
		EXX
		RST	#10
		EXX
		POP	DE
		RET

; Token table search
PO_SEARCH:	PUSH	AF
		EX	DE,HL
		INC	A
PO_STEP:	BIT	7,(HL)
		INC	HL
		JR	Z,PO_STEP
		DEC	A
		JR	NZ,PO_STEP
		EX	DE,HL
		POP	AF
		CP	#20
		RET	C
		LD	A,(DE)
		SUB	#41
		RET

; Test for scroll
PO_SCR:		BIT	1,(IY+#01)
		RET	NZ
		LD	DE,CL_SET
		PUSH	DE
		LD	A,B
		BIT	0,(IY+#02)
		JP	NZ,PO_SCR_4
		CP	(IY+#31)
		JR	C,REPORT_5
		RET	NZ
		BIT	4,(IY+#02)
		JR	Z,PO_SCR_2
		LD	E,(IY+#2D)
		DEC	E
		JR	Z,PO_SCR_3
		LD	A,#00
		CALL	CHAN_OPEN
		LD	SP,(#5C3F)
		RES	4,(IY+#02)
		RET

REPORT_5:	RST	#08			; Error report
		DB	#04			; Out of screen
PO_SCR_2:	DEC	(IY+#52)
		JR	NZ,PO_SCR_3
		LD	A,#18
		SUB	B
		LD	(#5C8C),A
		LD	HL,(#5C8F)
		PUSH	HL
		LD	A,(#5C91)
		PUSH	AF
		LD	A,#FD
		CALL	CHAN_OPEN
		XOR	A
		LD	DE,SCRL_MSG
		CALL	PO_MSG
		SET	5,(IY+#02)
		LD	HL,#5C3B
		SET	3,(HL)
		RES	5,(HL)
		EXX
		CALL	WAIT_KEY
		EXX
		CP	#20
		JR	Z,REPORT_D
		CP	#E2
		JR	Z,REPORT_D
		OR	#20
		CP	#6E
		JR	Z,REPORT_D
		LD	A,#FE
		CALL	CHAN_OPEN
		POP	AF
		LD	(#5C91),A
		POP	HL
		LD	(#5C8F),HL
PO_SCR_3:	CALL	CL_SC_ALL
		LD	B,(IY+#31)
		INC	B
		LD	C,#21
		PUSH	BC
		CALL	CL_ADDR
		LD	A,H
		RRCA
		RRCA
		RRCA
		AND	#03
		OR	#58
		LD	H,A
		LD	DE,#5AE0
		LD	A,(DE)
		LD	C,(HL)
		LD	B,#20
		EX	DE,HL
PO_SCR_3A:	LD	(DE),A
		LD	(HL),C
		INC	DE
		INC	HL
		DJNZ	PO_SCR_3A
		POP	BC
		RET

SCRL_MSG:	DB	#80
		DC	"scroll?"

REPORT_D:	RST	#08			; Error report
		DB	#0C			; BREAK - CONT repeats
PO_SCR_4:	CP	#02
		JR	C,REPORT_5
		ADD	A,(IY+#31)
		SUB	#19
		RET	NC
		NEG
		PUSH	BC
		LD	B,A
		LD	HL,(#5C8F)
		PUSH	HL
		LD	HL,(#5C91)
		PUSH	HL
		CALL	TEMPS
		LD	A,B
PO_SCR_4A:	PUSH	AF
		LD	HL,#5C6B
		LD	B,(HL)
		LD	A,B
		INC	A
		LD	(HL),A
		LD	HL,#5C89
		CP	(HL)
		JR	C,PO_SCR_4B
		INC	(HL)
		LD	B,#18
PO_SCR_4B:	CALL	CL_SCROLL
		POP	AF
		DEC	A
		JR	NZ,PO_SCR_4A
		POP	HL
		LD	(IY+#57),L
		POP	HL
		LD	(#5C8F),HL
		LD	BC,(#5C88)
		RES	0,(IY+#02)
		CALL	CL_SET
		SET	0,(IY+#02)
		POP	BC
		RET

; Copy temporary items
TEMPS:		XOR	A
		LD	HL,(#5C8D)
		BIT	0,(IY+#02)
		JR	Z,TEMPS_1
		LD	H,A
		LD	L,(IY+#0E)
TEMPS_1:	LD	(#5C8F),HL
		LD	HL,#5C91
		JR	NZ,TEMPS_2
		LD	A,(HL)
		RRCA
TEMPS_2:	XOR	(HL)
		AND	#55
		XOR	(HL)
		LD	(HL),A
		RET

; Handle CLS command
CLS:		CALL	CL_ALL
CLS_LOWER:	LD	HL,#5C3C
		RES	5,(HL)
		SET	0,(HL)
		CALL	TEMPS
		LD	B,(IY+#31)
		CALL	CL_LINE
		LD	HL,#5AC0
		LD	A,(#5C8D)
		DEC	B
		JR	CLS_3

CLS_1:		LD	C,#20
CLS_2:		DEC	HL
		LD	(HL),A
		DEC	C
		JR	NZ,CLS_2
CLS_3:		DJNZ	CLS_1
		LD	(IY+#31),#02
CL_CHAN:	LD	A,#FD
		CALL	CHAN_OPEN
		LD	HL,(#5C51)
		LD	DE,PRINT_OUT
		AND	A
CL_CHAN_A:	LD	(HL),E
		INC	HL
		LD	(HL),D
		INC	HL
		LD	DE,KEY_INPUT
		CCF
		JR	C,CL_CHAN_A
		LD	BC,#1721
		JR	CL_SET

; Clear display area
CL_ALL:		LD	HL,#0000
		LD	(#5C7D),HL
		RES	0,(IY+#30)
		CALL	CL_CHAN
		LD	A,#FE
		CALL	CHAN_OPEN
		CALL	TEMPS
		LD	B,#18
		CALL	CL_LINE
		LD	HL,(#5C51)
		LD	DE,PRINT_OUT
		LD	(HL),E
		INC	HL
		LD	(HL),D
		LD	(IY+#52),#01
		LD	BC,#1821
CL_SET:		LD	HL,#5B00		; Set line and column numbers
		BIT	1,(IY+#01)
		JR	NZ,CL_SET_2
		LD	A,B
		BIT	0,(IY+#02)
		JR	Z,CL_SET_1
		ADD	A,(IY+#31)
		SUB	#18
CL_SET_1:	PUSH	BC
		LD	B,A
		CALL	CL_ADDR
		POP	BC
CL_SET_2:	LD	A,#21
		SUB	C
		LD	E,A
		LD	D,#00
		ADD	HL,DE
		JP	PO_STORE

; Scroll part or whole display
CL_SC_ALL:	LD	B,#17
CL_SCROLL:	CALL	CL_ADDR
		LD	C,#08
CL_SCR_1:	PUSH	BC
		PUSH	HL
		LD	A,B
		AND	#07
		LD	A,B
		JR	NZ,CL_SCR_3
CL_SCR_2:	EX	DE,HL
		LD	HL,#F8E0
		ADD	HL,DE
		EX	DE,HL
		LD	BC,#0020
		DEC	A
		LDIR
CL_SCR_3:	EX	DE,HL
		LD	HL,#FFE0
		ADD	HL,DE
		EX	DE,HL
		LD	B,A
		AND	#07
		RRCA
		RRCA
		RRCA
		LD	C,A
		LD	A,B
		LD	B,#00
		LDIR
		LD	B,#07
		ADD	HL,BC
		AND	#F8
		JR	NZ,CL_SCR_2
		POP	HL
		INC	H
		POP	BC
		DEC	C
		JR	NZ,CL_SCR_1
		CALL	CL_ATTR
		LD	HL,#FFE0
		ADD	HL,DE
		EX	DE,HL
		LDIR
		LD	B,#01
CL_LINE:	PUSH	BC			; Clear text lines at the bottom of display
		CALL	CL_ADDR
		LD	C,#08
CL_LINE_1:	PUSH	BC
		PUSH	HL
		LD	A,B
CL_LINE_2:	AND	#07
		RRCA
		RRCA
		RRCA
		LD	C,A
		LD	A,B
		LD	B,#00
		DEC	C
		LD	D,H
		LD	E,L
		LD	(HL),#00
		INC	DE
		LDIR
		LD	DE,#0701
		ADD	HL,DE
		DEC	A
		AND	#F8
		LD	B,A
		JR	NZ,CL_LINE_2
		POP	HL
		INC	H
		POP	BC
		DEC	C
		JR	NZ,CL_LINE_1
		CALL	CL_ATTR
		LD	H,D
		LD	L,E
		INC	DE
		LD	A,(#5C8D)
		BIT	0,(IY+#02)
		JR	Z,CL_LINE_3
		LD	A,(#5C48)
CL_LINE_3:	LD	(HL),A
		DEC	BC
		LDIR
		POP	BC
		LD	C,#21
		RET

; Attribute handling
CL_ATTR:	LD	A,H
		RRCA
		RRCA
		RRCA
		DEC	A
		OR	#50
		LD	H,A
		EX	DE,HL
		LD	H,C
		LD	L,B
		ADD	HL,HL
		ADD	HL,HL
		ADD	HL,HL
		ADD	HL,HL
		ADD	HL,HL
		LD	B,H
		LD	C,L
		RET

; Handle display with line number
CL_ADDR:	LD	A,#18
		SUB	B
		LD	D,A
		RRCA
		RRCA
		RRCA
		AND	#E0
		LD	L,A
		LD	A,D
		AND	#18
		OR	#40
		LD	H,A
		RET

; Handle COPY command
COPY:		DI
		LD	B,#B0
		LD	HL,#4000
COPY_1:		PUSH	HL
		PUSH	BC
		CALL	COPY_LINE
		POP	BC
		POP	HL
		INC	H
		LD	A,H
		AND	#07
		JR	NZ,COPY_2
		LD	A,L
		ADD	A,#20
		LD	L,A
		CCF
		SBC	A,A
		AND	#F8
		ADD	A,H
		LD	H,A
COPY_2:		DJNZ	COPY_1
		JR	COPY_END

; Pass printer buffer to printer
COPY_BUFF:	DI
		LD	HL,#5B00
		LD	B,#08
COPY_3:		PUSH	BC
		CALL	COPY_LINE
		POP	BC
		DJNZ	COPY_3
COPY_END:	LD	A,#04
		OUT	(#FB),A
		EI
CLEAR_PRB:	LD	HL,#5B00		; Clear printer buffer
		LD	(IY+#46),L
		XOR	A
		LD	B,A
PRB_BYTES:	LD	(HL),A
		INC	HL
		DJNZ	PRB_BYTES
		RES	1,(IY+#30)
		LD	C,#21
		JP	CL_SET

; Output 32 bytes (line) to the printer
COPY_LINE:	LD	A,B
		CP	#03
		SBC	A,A
		AND	#02
		OUT	(#FB),A
		LD	D,A
COPY_L_1:	CALL	BREAK_KEY
		JR	C,COPY_L_2
		LD	A,#04
		OUT	(#FB),A
		EI
		CALL	CLEAR_PRB
REPORT_DC:	RST	#08			; Error report
		DB	#0C			; BREAK - CONT repeats
COPY_L_2:	IN	A,(#FB)
		ADD	A,A
		RET	M
		JR	NC,COPY_L_1
		LD	C,#20
COPY_L_3:	LD	E,(HL)
		INC	HL
		LD	B,#08
COPY_L_4:	RL	D
		RL	E
		RR	D
COPY_L_5:	IN	A,(#FB)
		RRA
		JR	NC,COPY_L_5
		LD	A,D
		OUT	(#FB),A
		DJNZ	COPY_L_4
		DEC	C
		JR	NZ,COPY_L_3
		RET

; The editor routine - prepare or edit BASIC line, or handle INPUT expression
EDITOR:		LD	HL,(#5C3D)
		PUSH	HL
ED_AGAIN:	LD	HL,ED_ERROR
		PUSH	HL
		LD	(#5C3D),SP
ED_LOOP:	CALL	WAIT_KEY
		PUSH	AF
		LD	D,#00
		LD	E,(IY-#01)
		LD	HL,#00C8
		CALL	BEEPER
		POP	AF
		LD	HL,ED_LOOP
		PUSH	HL
		CP	#18
		JR	NC,ADD_CHAR
		CP	#07
		JR	C,ADD_CHAR
		CP	#10
		JR	C,ED_KEYS
		LD	BC,#0002
		LD	D,A
		CP	#16
		JR	C,ED_CONTR
		INC	BC
		BIT	7,(IY+#37)
		JP	Z,ED_IGNORE
		CALL	WAIT_KEY
		LD	E,A
ED_CONTR:	CALL	WAIT_KEY
		PUSH	DE
		LD	HL,(#5C5B)
		RES	0,(IY+#07)
		CALL	MAKE_ROOM
		POP	BC
		INC	HL
		LD	(HL),B
		INC	HL
		LD	(HL),C
		JR	ADD_CH_1

; Add code to current line
ADD_CHAR:	RES	0,(IY+#07)
		LD	HL,(#5C5B)
		CALL	ONE_SPACE
ADD_CH_1:	LD	(DE),A
		INC	DE
		LD	(#5C5B),DE
		RET

ED_KEYS:	LD	E,A
		LD	D,#00
		LD	HL,ED_KEYS_T-7
		ADD	HL,DE
		LD	E,(HL)
		ADD	HL,DE
		PUSH	HL
		LD	HL,(#5C5B)
		RET

; Editing keys table
ED_KEYS_T:	DB	#09			; ED_EDIT
		DB	#66			; ED_LEFT
		DB	#6A			; ED_RIGHT
		DB	#50			; ED_DOWN
		DB	#B5			; ED_UP
		DB	#70			; ED_DELETE
		DB	#7E			; ED_ENTER
		DB	#CF			; ED_SYMBOL
		DB	#D4			; ED_GRAPH

; Handle EDIT key
ED_EDIT:	LD	HL,(#5C49)
		BIT	5,(IY+#37)
		JP	NZ,CLEAR_SP
		CALL	LINE_ADDR
		CALL	LIN2			; BSROM - modified BASIC program presence test
		AND	#C0
		JP	NZ,CLEAR_SP
		PUSH	HL
		INC	HL
		LD	C,(HL)
		INC	HL
		LD	B,(HL)
		LD	HL,#000A
		ADD	HL,BC
		LD	B,H
		LD	C,L
		CALL	TEST_ROOM
		CALL	CLEAR_SP
		LD	HL,(#5C51)
		EX	(SP),HL
		PUSH	HL
		LD	A,#FF
		CALL	CHAN_OPEN
		POP	HL
		DEC	HL
		CALL	OUT_LINE		;BSROM - cursor placement after EDIT
		LD	DE,#0005
		LD	HL,(#5C59)
		ADD	HL,DE
		LD	(#5C5B),HL
		POP	HL
		JP	CHAN_FLAG

TOERR:		LD	(#5C5F),HL		; BSROM - cursor jumps to error
		LD	(#5C5B),HL
		RET

; Cursor down editing
ED_DOWN:	CALL	DOLE			; BSROM - free cursor moving
		BIT	5,(IY+#37)
		RET	NZ
		NOP
		CALL	LN_FETCH
		JR	ED_LIST

ED_STOP:	LD	(IY+#00),#10
		JR	ED_ENTER

; Cursor left editing
ED_LEFT:	CALL	ED_EDGE
		JR	ED_CUR

; Cursor right editing
ED_RIGHT:	LD	A,(HL)
		CP	#0D
		RET	Z
		INC	HL
ED_CUR:		LD	(#5C5B),HL
		RET

; Handling DELETE
ED_DELETE:	CALL	ED_EDGE
		LD	BC,#0001
		JP	RECLAIM_2

; Ignore next two codes from KEY_INPUT routine
ED_IGNORE:	CALL	WAIT_KEY
		CALL	WAIT_KEY
ED_ENTER:	POP	HL			; Handle ENTER
		POP	HL
ED_END:		POP	HL
		LD	(#5C3D),HL
		BIT	7,(IY+#00)
		RET	NZ
		LD	SP,HL
		RET

; Move cursor left when editing
ED_EDGE:	SCF
		CALL	SET_DE
		SBC	HL,DE
		ADD	HL,DE
		INC	HL
		POP	BC
		RET	C
		PUSH	BC
		LD	B,H
		LD	C,L
ED_EDGE_1:	LD	H,D
		LD	L,E
		INC	HL
		LD	A,(DE)
		AND	#F0
		CP	#10
		JR	NZ,ED_EDGE_2
		INC	HL
		LD	A,(DE)
		SUB	#17
		ADC	A,#00
		JR	NZ,ED_EDGE_2
		INC	HL
ED_EDGE_2:	AND	A
		SBC	HL,BC
		ADD	HL,BC
		EX	DE,HL
		JR	C,ED_EDGE_1
		RET

; Cursor up editing
ED_UP:		CALL	HORE			; BSROM - free cursor moving
		BIT	5,(IY+#37)
		RET	NZ
		CALL	LINE_ADDR
		EX	DE,HL
		CALL	LINE_NO
		LD	HL,#5C4A
		CALL	LN_STORE
ED_LIST:	CALL	AUTO_LIST
ED_LIST_1:	LD	A,#00
		JP	CHAN_OPEN

; Use of symbol and graphic codes
ED_SYMBOL:	BIT	7,(IY+#37)
		JR	Z,ED_ENTER
ED_GRAPH:	JP	ADD_CHAR

; Editor error handling
ED_ERROR:	BIT	4,(IY+#30)
		JR	Z,ED_END
		LD	(IY+#00),#FF
		LD	D,#00
		LD	E,(IY-#02)
		LD	HL,#0190		; BSROM - higher tone of error beep, was LD HL,#1A90
		CALL	BEEPER
		JP	ED_AGAIN

; Clear workspace
CLEAR_SP:	PUSH	HL
		CALL	SET_HL
		DEC	HL
		CALL	RECLAIM_1
		LD	(#5C5B),HL
		LD	(IY+#07),#00
		POP	HL
		RET

; Handle keyboard input
KEY_INPUT:	BIT	3,(IY+#02)
		CALL	NZ,ED_COPY
		AND	A
		BIT	5,(IY+#01)
		RET	Z
		LD	A,(#5C08)
		RES	5,(IY+#01)
		PUSH	AF
		BIT	5,(IY+#02)
		CALL	NZ,CLS_LOWER
		POP	AF
		CP	#20
		JR	NC,KEY_DONE2
		CP	#10
		JR	NC,KEY_CONTR
		CP	#06
		JR	NC,KEY_M_CL
		LD	B,A
		AND	#01
		LD	C,A
		LD	A,B
		RRA
		ADD	A,#12
		JR	KEY_DATA

; Separate caps lock
KEY_M_CL:	JR	NZ,KEY_MODE
		LD	HL,#5C6A
		LD	A,#08
		XOR	(HL)
		LD	(HL),A
		JR	KEY_FLAG

; Mode handling
KEY_MODE:	CP	#0E
		RET	C
		SUB	#0D
		LD	HL,#5C41
		CP	(HL)
		LD	(HL),A
		JR	NZ,KEY_FLAG
		LD	(HL),#00
KEY_FLAG:	SET	3,(IY+#02)
		CP	A
		RET

; Handle colour controls
KEY_CONTR:	LD	B,A
		AND	#07
		LD	C,A
		LD	A,#10
		BIT	3,B
		JR	NZ,KEY_DATA
		INC	A
KEY_DATA:	LD	(IY-#2D),C
		LD	DE,KEY_NEXT
		JR	KEY_CHAN

KEY_NEXT:	LD	A,(#5C0D)
		LD	DE,KEY_INPUT
KEY_CHAN:	LD	HL,(#5C4F)
		INC	HL
		INC	HL
		LD	(HL),E
		INC	HL
		LD	(HL),D
KEY_DONE2:	SCF
		RET

; Print lower screen workspace
ED_COPY:	CALL	TEMPS
		RES	3,(IY+#02)
		RES	5,(IY+#02)
		LD	HL,(#5C8A)
		PUSH	HL
		LD	HL,(#5C3D)
		PUSH	HL
		LD	HL,ED_FULL
		PUSH	HL
		LD	(#5C3D),SP
		LD	HL,(#5C82)
		PUSH	HL
		SCF
		CALL	SET_DE
		EX	DE,HL
		CALL	OUT_LINE2
		EX	DE,HL
		CALL	OUT_CURS
		LD	HL,(#5C8A)
		EX	(SP),HL
		EX	DE,HL
		CALL	TEMPS
ED_BLANK:	LD	A,(#5C8B)
		SUB	D
		JR	C,ED_C_DONE
		JR	NZ,ED_SPACES
		LD	A,E
		SUB	(IY+#50)
		JR	NC,ED_C_DONE
ED_SPACES:	LD	A,#20
		PUSH	DE
		CALL	PRINT_OUT
		POP	DE
		JR	ED_BLANK

; Error handling
ED_FULL:	LD	D,#00
		LD	E,(IY-#02)
		LD	HL,#0190		; BSROM - higher tone of error beep, was LD HL,#1A90
		CALL	BEEPER
		LD	(IY+#00),#FF
		LD	DE,(#5C8A)
		JR	ED_C_END

ED_C_DONE:	POP	DE
		POP	HL
ED_C_END:	POP	HL
		LD	(#5C3D),HL
		POP	BC
		PUSH	DE
		CALL	CL_SET
		POP	HL
		LD	(#5C82),HL
		LD	(IY+#26),#00
		RET

; Ensure that the proper pointers are selected for workspace
SET_HL:		LD	HL,(#5C61)
		DEC	HL
		AND	A
SET_DE:		LD	DE,(#5C59)
		BIT	5,(IY+#37)
		RET	Z
		LD	DE,(#5C61)
		RET	C
		LD	HL,(#5C63)
		RET

; Remove floating point from line
REMOVE_FP:	LD	A,(HL)
		CP	#0E
		LD	BC,#0006
		CALL	Z,RECLAIM_2
		LD	A,(HL)
		INC	HL
		CP	#0D
		JR	NZ,REMOVE_FP
		RET

; Handle NEW command
NEW:		DI
		LD	A,#FF
		LD	DE,(#5CB2)
NEW_1:		EXX
		LD	BC,(#5CB4)
		LD	DE,(#5C38)
		LD	HL,(#5C7B)
		EXX
START_NEW:	LD	B,A
		XOR	A			; BSROM - faster RAM clear, RAM is not tested for errors
		LD	I,A
		LD	C,A
		LD	H,D
		LD	L,E
		LD	A,B
		LD	B,C
		LD	SP,HL
CLSUJ:		PUSH	BC
		PUSH	BC
		PUSH	BC
		PUSH	BC
		PUSH	BC
		PUSH	BC
		PUSH	BC
		PUSH	BC
		LD	HL,#A7FF
		ADD	HL,SP
		JR	C,CLSUJ
		EX	DE,HL
		JR	RAM_DONE1

; Modified CONTINUE command
NEW_CONT:	CALL	FIND_INT2
		LD	A,B
		OR	C
		JP	Z,CONTINUE
		PUSH	BC
		RET
; Remains of original RAM_DONE routine
RAM_DONE1:	EXX
		LD	(#5CB4),BC
		LD	(#5C38),DE
		LD	(#5C7B),HL
		EXX	
		INC	A			; BSROM - changed for new NEW command, was INC B
		JR	Z,RAM_SET
RAM_DONE2:	LD	(#5CB4),HL
		LD	DE,#3EAF
		LD	BC,#00A8
		EX	DE,HL
		LDDR
		EX	DE,HL
		INC	HL
		LD	(#5C7B),HL
		DEC	HL
		LD	BC,#0040
		LD	(#5C38),BC
RAM_SET:	LD	(#5CB2),HL
		LD	HL,#3C00
		LD	(#5C36),HL
		LD	HL,(#5CB2)
		LD	(HL),#3E
		DEC	HL
		LD	SP,HL
		DEC	HL
		DEC	HL
		LD	(#5C3D),HL
		IM	1
		LD	IY,#5C3A
		EI
		LD	HL,#5CB6
		LD	(#5C4F),HL
		LD	DE,INIT_CHAN
		LD	BC,#0015
		EX	DE,HL
		LDIR
		EX	DE,HL
		DEC	HL
		LD	(#5C57),HL
		INC	HL
		LD	(#5C53),HL
		LD	(#5C4B),HL
		LD	(HL),#80
		INC	HL
		LD	(#5C59),HL
WARM_ST:	LD	(HL),#0D
		INC	HL
		LD	(HL),#80
		INC	HL
		LD	(#5C61),HL
		LD	(#5C63),HL
		LD	(#5C65),HL
		LD	A,#07			; BSROM - changed colors, blue border, black paper, white ink
		LD	(#5C8D),A
		LD	(#5C8F),A
		LD	(#5C48),A
		LD	HL,#0114		; BSROM - REPDEL and REPPER were changed, was #0523
		LD	(#5C09),HL
		DEC	(IY-#3A)
		DEC	(IY-#36)
		LD	HL,INIT_STRM
		LD	DE,#5C10
		LD	BC,#000E
		LDIR
		LD	(IY+#31),#02		; BSROM - printer vars initialization removed
		LD	(IY+#0E),#0F
		CALL	HARD			; reset AY, DMA, FDC
		CALL	SET_MIN
		LD	(IY+#00),#FF
		CALL	INFO			; copyright message replaced with status info
		CALL	SA_LD_RET
		JP	MAIN_4

; Main execution loop
MAIN_EXEC:	LD	(IY+#31),#02
		CALL	AUTO_LIST
MAIN_1:		CALL	SET_MIN
MAIN_2:		LD	A,#00
		CALL	CHAN_OPEN
		CALL	EDITOR
		CALL	LINE_SCAN
		BIT	7,(IY+#00)
		JR	NZ,MAIN_3
		BIT	4,(IY+#30)
		JR	Z,MAIN_4
		LD	HL,(#5C59)
		CALL	REMOVE_FP
		LD	(IY+#00),#FF
		JR	MAIN_2

MAIN_3:		LD	HL,(#5C59)
		LD	(#5C5D),HL
		CALL	LIN3			; BSROM - modified test of number at the begin of BASIC line
		NOP
		NOP
		JP	NC,MAIN_ADD		; BSROM - don't test zero, so line 0 can be used and/or edited
		RST	#18
		CP	#0D
		JR	Z,MAIN_EXEC
		BIT	0,(IY+#30)
		CALL	NZ,CL_ALL
		CALL	CLS_LOWER
		LD	A,#19
		SUB	(IY+#4F)
		LD	(#5C8C),A
		SET	7,(IY+#01)
		LD	(IY+#00),#FF
		LD	(IY+#0A),#01
		CALL	LINE_RUN
MAIN_4:		RST	#38			; BSROM - bugfix - was HALT
		RES	5,(IY+#01)
		BIT	1,(IY+#30)
		CALL	NZ,COPY_BUFF
		LD	A,(#5C3A)
		INC	A
MAIN_G:		PUSH	AF
		LD	HL,#0000
		LD	(IY+#37),H
		LD	(IY+#26),H
		LD	(#5C0B),HL
		LD	HL,#0001
		LD	(#5C16),HL
		CALL	SET_MIN
		RES	5,(IY+#37)
		CALL	CLS_LOWER
		SET	5,(IY+#02)
		POP	AF
		LD	B,A
		CP	#0A
		JR	C,MAIN_5
		ADD	A,#07
MAIN_5:		CALL	OUT_CODE
		LD	A,#20
		RST	#10
		LD	A,B
		LD	DE,RPT_MESGS
		CALL	PO_MSG
		XOR	A
		LD	DE,COMMA_SP-1
		CALL	PO_MSG
		LD	BC,(#5C45)
		CALL	OUT_NUM_1
		LD	A,#3A
		RST	#10
		LD	C,(IY+#0D)
		LD	B,#00
		CALL	OUT_NUM_1
		CALL	CLEAR_SP
		LD	A,(#5C3A)
		INC	A
		JR	Z,MAIN_9
		CP	#09
		JR	Z,MAIN_6
		CP	#15
		JR	NZ,MAIN_7
MAIN_6:		INC	(IY+#0D)
MAIN_7:		LD	BC,#0003
		LD	DE,#5C70
		LD	HL,#5C44
		BIT	7,(HL)
		JR	Z,MAIN_8
		ADD	HL,BC
MAIN_8:		LDDR
MAIN_9:		LD	(IY+#0A),#FF
		RES	3,(IY+#01)
		JP	MAIN_2

;The error mesages, with last byte inverted.
;The first #80 entry is dummy entry.
RPT_MESGS:	DB	#80
		DC	"OK"
		DC	"NEXT without FOR"
		DC	"Variable not found"
		DC	"Subscript wrong"
		DC	"Out of memory"
		DC	"Out of screen"
		DC	"Number too big"
		DC	"RETURN without GOSUB"
		DC	"End of file"
		DC	"STOP statement"
		DC	"Invalid argument"
		DC	"Integer out of range"
		DC	"Nonsense in BASIC"
		DC	"BREAK - CONT repeats"
		DC	"Out of DATA"
		DC	"Invalid file name"
		DC	"No room for line"
		DC	"STOP in INPUT"
		DC	"FOR without NEXT"
		DC	"Invalid I/O device"
		DC	"Invalid colour"
		DC	"BREAK into program"
		DC	"RAMTOP no good"
		DC	"Statement lost"
		DC	"Invalid stream"
		DC	"FN without DEF"
		DC	"Parameter error"
		DC	"Tape loading error"
COMMA_SP:	DC	", "

; BSROM - here was the copyright message in the original ZX Spectrum ROM.
COPYRIGHT:	DC	"Rom 140"
		DC	"Prog:"
		DB	#16
		DB	#00
		DB	#0B

		DC	"Vars:"
		DB	#16
		DB	#00
		DB	#16

		DC	"Free:"

; Out of memory handling
REPORT_G:	LD	A,#10
		LD	BC,#0000
		JP	MAIN_G

; Handle additon of BASIC line
MAIN_ADD:	LD	(#5C49),BC
		LD	HL,(#5C5D)
		EX	DE,HL
		LD	HL,REPORT_G
		PUSH	HL
		LD	HL,(#5C61)
		SCF
		SBC	HL,DE
		PUSH	HL
		LD	H,B
		LD	L,C
		CALL	LINE_ADDR
		JR	NZ,MAIN_ADD1
		CALL	NEXT_ONE
		CALL	RECLAIM_2
MAIN_ADD1:	POP	BC
		LD	A,C
		DEC	A
		OR	B
		JR	Z,MAIN_ADD2
		PUSH	BC
		INC	BC
		INC	BC
		INC	BC
		INC	BC
		DEC	HL
		LD	DE,(#5C53)
		PUSH	DE
		CALL	MAKE_ROOM
		POP	HL
		LD	(#5C53),HL
		POP	BC
		PUSH	BC
		INC	DE
		LD	HL,(#5C61)
		DEC	HL
		DEC	HL
		LDDR
		LD	HL,(#5C49)
		EX	DE,HL
		POP	BC
		LD	(HL),B
		DEC	HL
		LD	(HL),C
		DEC	HL
		LD	(HL),E
		DEC	HL
		LD	(HL),D
MAIN_ADD2:	POP	AF
		JP	MAIN_EXEC

; Initial channel information
INIT_CHAN:	DW	PRINT_OUT
		DW	KEY_INPUT
		DB	"K"
		DW	PRINT_OUT
		DW	REPORT_J
		DB	"S"
		DW	ADD_CHAR
		DW	REPORT_J
		DB	"R"
		DW	PRINT_OUT
		DW	REPORT_J
		DB	"P"
		DB	#80			; End marker

REPORT_J:	RST	#08			; Error report
		DB	#12			; Invalid I/O device

; Initial stream data
INIT_STRM:	DB	#01, #00		; stream #FD offset to channel 'K'
		DB	#06, #00		; stream #FE offset to channel 'S'
		DB	#0B, #00		; stream #FF offset to channel 'R'
		DB	#01, #00		; stream #00 offset to channel 'K'
		DB	#01, #00		; stream #01 offset to channel 'K'
		DB	#06, #00		; stream #02 offset to channel 'S'
		DB	#10, #00		; stream #03 offset to channel 'P'

; Control for input subroutine
WAIT_KEY:	BIT	5,(IY+#02)
		JR	NZ,WAIT_KEY1
		SET	3,(IY+#02)
WAIT_KEY1:	CALL	INPUT_AD
		RET	C
		JR	Z,WAIT_KEY1
REPORT_8:	RST	#08			; Error report
		DB	#07			; End of file
INPUT_AD:	EXX
		PUSH	HL
		LD	HL,(#5C51)
		INC	HL
		INC	HL
		JR	CALL_SUB

; Print ascii equivalent of a value 0-9
OUT_CODE:	LD	E,#30
		ADD	A,E
PRINT_A_2:	EXX
		PUSH	HL
		LD	HL,(#5C51)
CALL_SUB:	LD	E,(HL)
		INC	HL
		LD	D,(HL)
		EX	DE,HL
		CALL	CALL_JUMP
		POP	HL
		EXX
		RET

; Open a channel 'K', 'S', 'R' or 'P'
CHAN_OPEN:	ADD	A,A
		ADD	A,#16
		LD	L,A
		LD	H,#5C
		LD	E,(HL)
		INC	HL
		LD	D,(HL)
		LD	A,D
		OR	E
		JR	NZ,CHAN_OP_1
REPORT_OA:	RST	#08			; Error report
		DB	#17			; Invalid stream
CHAN_OP_1:	DEC	DE
		LD	HL,(#5C4F)
		ADD	HL,DE
CHAN_FLAG:	LD	(#5C51),HL		; Set channel flags
		RES	4,(IY+#30)
		INC	HL
		INC	HL
		INC	HL
		INC	HL
		LD	C,(HL)
		LD	HL,CH_CD_LU
		CALL	INDEXER
		RET	NC
		LD	D,#00
		LD	E,(HL)
		ADD	HL,DE
CALL_JUMP:	JP	(HL)

; Channel code lookup table
CH_CD_LU:	DB	"K", #06		; CHAN_K
		DB	"S", #12		; CHAN_S
		DB	"P", #1B		; CHAN_P
		DB	#00			; End marker

; Channel K flag
CHAN_K:		SET	0,(IY+#02)
		RES	5,(IY+#01)
		SET	4,(IY+#30)
		JR	CHAN_S_1

; Channel S flag
CHAN_S:		RES	0,(IY+#02)
CHAN_S_1:	RES	1,(IY+#01)
		JP	TEMPS

; Channel P flag
CHAN_P:		SET	1,(IY+#01)
		RET

; Create a single space in workspace by ADD_CHAR
ONE_SPACE:	LD	BC,#0001
MAKE_ROOM:	PUSH	HL		; Create BC spaces in various areas
		CALL	TEST_ROOM
		POP	HL
		CALL	POINTERS
		LD	HL,(#5C65)
		EX	DE,HL
		LDDR
		RET

; Adjust pointers before making or reclaiming room
POINTERS:	PUSH	AF
		PUSH	HL
		LD	HL,#5C4B
		LD	A,#0E
PTR_NEXT:	LD	E,(HL)
		INC	HL
		LD	D,(HL)
		EX	(SP),HL
		AND	A
		SBC	HL,DE
		ADD	HL,DE
		EX	(SP),HL
		JR	NC,PTR_DONE
		PUSH	DE
		EX	DE,HL
		ADD	HL,BC
		EX	DE,HL
		LD	(HL),D
		DEC	HL
		LD	(HL),E
		INC	HL
		POP	DE
PTR_DONE:	INC	HL
		DEC	A
		JR	NZ,PTR_NEXT
		EX	DE,HL
		POP	DE
		POP	AF
		AND	A
		SBC	HL,DE
		LD	B,H
		LD	C,L
		INC	BC
		ADD	HL,DE
		EX	DE,HL
		RET

; Collect line number
LINE_ZERO:	DB	#00, #00		; Dummy line number for direct commands

LINE_NO_A:	EX	DE,HL
		LD	DE,LINE_ZERO
LINE_NO:	LD	A,(HL)
		AND	#C0
		JR	NZ,LINE_NO_A
		LD	D,(HL)
		INC	HL
		LD	E,(HL)
		RET

; Handle reserve room, continuation of the restart BC_SPACES
RESERVE:	LD	HL,(#5C63)
		DEC	HL
		CALL	MAKE_ROOM
		INC	HL
		INC	HL
		POP	BC
		LD	(#5C61),BC
		POP	BC
		EX	DE,HL
		INC	HL
		RET

; Clear editing areas
SET_MIN:	LD	HL,(#5C59)
		LD	(HL),#0D
		LD	(#5C5B),HL
		INC	HL
		LD	(HL),#80
		INC	HL
		LD	(#5C61),HL
SET_WORK:	LD	HL,(#5C61)
		LD	(#5C63),HL
SET_STK:	LD	HL,(#5C63)
		LD	(#5C65),HL
		PUSH	HL
		LD	HL,#5C92
		LD	(#5C68),HL
		POP	HL
		RET

; Not used code, remains of ZX80/ZX81 legacy code
REC_EDIT:	LD	DE,(#5C59)
		JP	RECLAIM_1

; Table indexing routine
INDEXER_1:	INC	HL
INDEXER:	LD	A,(HL)
		AND	A
		RET	Z
		CP	C
		INC	HL
		JR	NZ,INDEXER_1
		SCF
		RET

; Handle CLOSE# command
CLOSE:		CALL	STR_DATA
		CALL	CLOSE_2
		LD	BC,#0000
		LD	DE,#A3E2
		EX	DE,HL
		ADD	HL,DE
		JR	C,CLOSE_1
		LD	BC,INIT_STRM+14
		ADD	HL,BC
		LD	C,(HL)
		INC	HL
		LD	B,(HL)
CLOSE_1:	EX	DE,HL
		LD	(HL),C
		INC	HL
		LD	(HL),B
		RET

CLOSE_2:	PUSH	HL
		LD	HL,(#5C4F)
		ADD	HL,BC
		INC	HL
		INC	HL
		INC	HL
		LD	C,(HL)
		EX	DE,HL
		LD	HL,CL_STR_LU
		CALL	INDEXER
		LD	C,(HL)
		LD	B,#00
		ADD	HL,BC
		JP	(HL)

; Close stream lookup table
CL_STR_LU:	DB	"K", #05
		DB	"S", #03
		DB	"P", #01

CLOSE_STR:	POP	HL
		RET

; Stream data
STR_DATA:	CALL	FIND_INT1
		CP	#10
		JR	C,STR_DATA1
REPORT_OB:	RST	#08			; Error report
		DB	#17			; Invalid stream
STR_DATA1:	ADD	A,#03
		RLCA
		LD	HL,#5C10
		LD	C,A
		LD	B,#00
		ADD	HL,BC
		LD	C,(HL)
		INC	HL
		LD	B,(HL)
		DEC	HL
		RET

; Handle OPEN# command
OPEN:		RST	#28			;FP_CALC
		DB	#01			;EXCHANGE
		DB	#38			;END_CALC
		CALL	STR_DATA
		LD	A,B
		OR	C
		JR	Z,OPEN_1
		EX	DE,HL
		LD	HL,(#5C4F)
		ADD	HL,BC
		INC	HL
		INC	HL
		INC	HL
		LD	A,(HL)
		EX	DE,HL
		CP	#4B
		JR	Z,OPEN_1
		CP	#53
		JR	Z,OPEN_1
		CP	#50
		JR	NZ,REPORT_OB
OPEN_1:		CALL	OPEN_2
		LD	(HL),E
		INC	HL
		LD	(HL),D
		RET

OPEN_2:		PUSH	HL
		CALL	STK_FETCH
		LD	A,B
		OR	C
		JR	NZ,OPEN_3
REPORT_F:	RST	#08			; Error report
		DB	#0E			; Invalid file name
OPEN_3:		PUSH	BC
		LD	A,(DE)
		AND	#DF
		LD	C,A
		LD	HL,OP_STR_LU
		CALL	INDEXER
		JR	NC,REPORT_F
		LD	C,(HL)
		LD	B,#00
		ADD	HL,BC
		POP	BC
		JP	(HL)

; Open stream lookup table
OP_STR_LU:	DB	"K", #06		; OPEN_K
		DB	"S", #08		; OPEN_S
		DB	"P", #0A		; OPEN_P
		DB	#00			; End marker

; Open keyboard stream
OPEN_K:		LD	E,#01
		JR	OPEN_END

; Open Screen stream
OPEN_S:		LD	E,#06
		JR	OPEN_END

; Open printer stream
OPEN_P:		LD	E,#10
OPEN_END:	DEC	BC
		LD	A,B
		OR	C
		JR	NZ,REPORT_F
		LD	D,A
		POP	HL
		RET

; Handle CAT, ERASE, FORMAT and MOVE commands
CAT_ETC:	JR	REPORT_OB

; Automatic listing in the upper screen
AUTO_LIST:	LD	(#5C3F),SP
		LD	(IY+#02),#10
		CALL	CL_ALL
		SET	0,(IY+#02)
		LD	B,(IY+#31)
		CALL	CL_LINE
		RES	0,(IY+#02)
		SET	0,(IY+#30)
		LD	HL,(#5C49)
		LD	DE,(#5C6C)
		AND	A
		SBC	HL,DE
		ADD	HL,DE
		JR	C,AUTO_L_2
		PUSH	DE
		CALL	LINE_ADDR
		LD	DE,#02C0
		EX	DE,HL
		SBC	HL,DE
		EX	(SP),HL
		CALL	LINE_ADDR
		POP	BC
AUTO_L_1:	PUSH	BC
		CALL	NEXT_ONE
		POP	BC
		ADD	HL,BC
		JR	C,AUTO_L_3
		EX	DE,HL
		LD	D,(HL)
		INC	HL
		LD	E,(HL)
		DEC	HL
		LD	(#5C6C),DE
		JR	AUTO_L_1

AUTO_L_2:	LD	(#5C6C),HL
AUTO_L_3:	LD	HL,(#5C6C)
		CALL	LINE_ADDR
		JR	Z,AUTO_L_4
		EX	DE,HL
AUTO_L_4:	CALL	LIST_ALL
		RES	4,(IY+#02)
		RET

; Handle LLIST command
LLIST:		LD	A,#03
		JR	LIST_1

; Handle LIST command
LIST:		LD	A,#02
LIST_1:		LD	(IY+#02),#00
		CALL	SYNTAX_Z
		CALL	NZ,CHAN_OPEN
		RST	#18
		CALL	STR_ALTER
		JR	C,LIST_4
		RST	#18
		CP	#3B
		JR	Z,LIST_2
		CP	#2C
		JR	NZ,LIST_3
LIST_2:		RST	#20
		CALL	EXPT_1NUM
		JR	LIST_5

LIST_3:		CALL	USE_ZERO
		JR	LIST_5

LIST_4:		CALL	FETCH_NUM
LIST_5:		CALL	CHECK_END
		CALL	FIND_INT2
		LD	A,B
		AND	#3F
		LD	H,A
		LD	L,C
		LD	(#5C49),HL
		CALL	LINE_ADDR
LIST_ALL:	LD	E,#01
LIST_ALL_2:	CALL	OUT_LINE
		RST	#10
		BIT	4,(IY+#02)
		JR	Z,LIST_ALL_2
		LD	A,(#5C6B)
		SUB	(IY+#4F)
		JR	NZ,LIST_ALL_2
		XOR	E
		RET	Z
		PUSH	HL
		PUSH	DE
		LD	HL,#5C6C
		CALL	LN_FETCH
		POP	DE
		POP	HL
		JR	LIST_ALL_2

; Print a whole BASIC line
OUT_LINE:	LD	BC,(#5C49)
		CALL	CP_LINES
		LD	D,#2A			; BSROM - line cursor is "*" instead of ">"
		JR	Z,OUT_LINE1
		LD	DE,#2000		; BSROM - " " instead of suppressing line cursor
		RL	E
OUT_LINE1:	LD	(IY+#2D),E
		LD	A,(HL)
		CP	#40
		POP	BC
		RET	NC
		PUSH	BC
		CALL	LIN4			; BSROM - no cursor
		INC	HL
		INC	HL
		INC	HL
		XOR	A
		XOR	D
		JR	Z,OUT_LINE1A
		RST	#10
OUT_LINE1A:	NOP				; remains of old code are replaced with NOPs
		NOP
		NOP
		NOP
OUT_LINE2:	SET	0,(IY+#01)
OUT_LINE3:	PUSH	DE
		EX	DE,HL
		RES	2,(IY+#30)
		LD	HL,#5C3B
		RES	2,(HL)
		BIT	5,(IY+#37)
		JR	Z,OUT_LINE4
		SET	2,(HL)
OUT_LINE4:	LD	HL,(#5C5F)
		AND	A
		SBC	HL,DE
		JR	NZ,OUT_LINE5
		LD	A,#3F
		CALL	OUT_FLASH
OUT_LINE5:	CALL	OUT_CURS
		EX	DE,HL
		LD	A,(HL)
		CALL	NUMBER
		INC	HL
		CP	#0D
		JR	Z,OUT_LINE6
		EX	DE,HL
		CALL	OUT_CHAR
		JR	OUT_LINE4

OUT_LINE6:	POP	DE
		RET

; Check for a number marker
NUMBER:		CP	#0E
		RET	NZ
		INC	HL
		INC	HL
		INC	HL
		INC	HL
		INC	HL
		INC	HL
		LD	A,(HL)
		RET

; Print a flashing character
OUT_FLASH:	EXX
		LD	HL,(#5C8F)
		PUSH	HL
		RES	7,H
		SET	7,L
		LD	(#5C8F),HL
		LD	HL,#5C91
		LD	D,(HL)
		PUSH	DE
		LD	(HL),#00
		CALL	PRINT_OUT
		POP	HL
		LD	(IY+#57),H
		POP	HL
		LD	(#5C8F),HL
		EXX
		RET

; Print the cursor
OUT_CURS:	LD	HL,(#5C5B)
		AND	A
		SBC	HL,DE
		RET	NZ
		LD	A,(#5C41)
		RLC	A
		JR	Z,OUT_C_1
		ADD	A,#43
		JR	OUT_C_2

OUT_C_1:	LD	HL,#5C3B
		RES	3,(HL)
		LD	A,#4B
		BIT	2,(HL)
		JR	Z,OUT_C_2
		SET	3,(HL)
		INC	A
		BIT	3,(IY+#30)
		JR	Z,OUT_C_2
		LD	A,#43
OUT_C_2:	PUSH	DE
		CALL	OUT_FLASH
		POP	DE
		RET

; Get line number of the next line
LN_FETCH:	LD	E,(HL)
		INC	HL
		LD	D,(HL)
		PUSH	HL
		EX	DE,HL
		INC	HL
		CALL	LINE_ADDR
		CALL	LINE_NO
		POP	HL
LN_STORE:	BIT	5,(IY+#37)
		RET	NZ
		LD	(HL),D
		DEC	HL
		LD	(HL),E
		RET

; Outputting numbers at start of BASIC line
OUT_SP_2:	LD	A,E
		AND	A
		RET	M
		JR	OUT_CHAR

OUT_SP_NO:	XOR	A
OUT_SP_1:	ADD	HL,BC
		INC	A
		JR	C,OUT_SP_1
		SBC	HL,BC
		DEC	A
		JR	Z,OUT_SP_2
		JP	OUT_CODE

; Outputting characters in a BASIC line
OUT_CHAR:	CALL	NUMERIC
		JR	NC,OUT_CH_3
		CP	#21
		JR	C,OUT_CH_3
		RES	2,(IY+#01)
		CP	#CB
		JR	Z,OUT_CH_3
		CP	#3A
		JR	NZ,OUT_CH_1
		BIT	5,(IY+#37)
		JR	NZ,OUT_CH_2
		BIT	2,(IY+#30)
		JR	Z,OUT_CH_3
		JR	OUT_CH_2

OUT_CH_1:	CP	#22
		JR	NZ,OUT_CH_2
		PUSH	AF
		LD	A,(#5C6A)
		XOR	#04
		LD	(#5C6A),A
		POP	AF
OUT_CH_2:	SET	2,(IY+#01)
OUT_CH_3:	RST	#10
		RET

; Get starting address of line (or line after)
LINE_ADDR:	PUSH	HL
		LD	HL,(#5C53)
		LD	D,H
		LD	E,L
LINE_AD_1:	POP	BC
		CALL	LIN1			; BSROM - modified line number test
		RET	NC
		PUSH	BC
		CALL	NEXT_ONE
		EX	DE,HL
		JR	LINE_AD_1

; Compare line numbers
CP_LINES:	LD	A,(HL)
		CP	B
		RET	NZ
		INC	HL
		LD	A,(HL)
		DEC	HL
		CP	C
		RET

; Find each statement
		INC	HL			; 3x INC HL not used in this ROM
		INC	HL
		INC	HL
EACH_STMT:	LD	(#5C5D),HL
		LD	C,#00
EACH_S_1:	DEC	D
		RET	Z
		RST	#20
		CP	E
		JR	NZ,EACH_S_3
		AND	A
		RET

EACH_S_2:	INC	HL
		LD	A,(HL)
EACH_S_3:	CALL	NUMBER
		LD	(#5C5D),HL
		CP	#22
		JR	NZ,EACH_S_4
		DEC	C
EACH_S_4:	CP	#3A
		JR	Z,EACH_S_5
		CP	#CB
		JR	NZ,EACH_S_6
EACH_S_5:	BIT	0,C
		JR	Z,EACH_S_1
EACH_S_6:	CP	#0D
		JR	NZ,EACH_S_2
		DEC	D
		SCF
		RET

; Find the address of the next line in the program area,
; or the next variable in the variables area
NEXT_ONE:	PUSH	HL
		LD	A,(HL)
		CP	#40
		JR	C,NEXT_O_3
		BIT	5,A
		JR	Z,NEXT_O_4
		ADD	A,A
		JP	M,NEXT_O_1
		CCF
NEXT_O_1:	LD	BC,#0005
		JR	NC,NEXT_O_2
		LD	C,#12
NEXT_O_2:	RLA
		INC	HL
		LD	A,(HL)
		JR	NC,NEXT_O_2
		JR	NEXT_O_5

NEXT_O_3:	INC	HL
NEXT_O_4:	INC	HL
		LD	C,(HL)
		INC	HL
		LD	B,(HL)
		INC	HL
NEXT_O_5:	ADD	HL,BC
		POP	DE
DIFFER:		AND	A
		SBC	HL,DE
		LD	B,H
		LD	C,L
		ADD	HL,DE
		EX	DE,HL
		RET

; Handle reclaiming space
RECLAIM_1:	CALL	DIFFER
RECLAIM_2:	PUSH	BC
		LD	A,B
		CPL
		LD	B,A
		LD	A,C
		CPL
		LD	C,A
		INC	BC
		CALL	POINTERS
		EX	DE,HL
		POP	HL
		ADD	HL,DE
		PUSH	DE
		LDIR
		POP	HL
		RET
		
; Read line number of line editing area
E_LINE_NO:	LD	HL,(#5C59)
		DEC	HL
		LD	(#5C5D),HL
		RST	#20
		LD	HL,#5C92
		LD	(#5C65),HL
		CALL	INT_TO_FP
		CALL	FP_TO_BC
		JR	C,E_L_1
		LD	HL,#C000		; BSROM - line number can be 0..16383 now, was LD HL,$D8F0 (max 9999 lines)
		ADD	HL,BC
E_L_1:		JP	C,REPORT_C
		JP	SET_STK

; Report and line number outputting
OUT_NUM_1:	PUSH	DE
		PUSH	HL
		XOR	A
		BIT	7,B
		JR	NZ,OUT_NUM_4
		LD	H,B
		LD	E,#FF			;BSROM - lines 0..16383
		JP	NUMCOM

OUT_NUM_2:	PUSH	DE
		LD	D,(HL)
		INC	HL
		LD	E,(HL)
		PUSH	HL
		EX	DE,HL
		LD	E,#20
OUT_NUM_3:	LD	BC,#FC18
		CALL	OUT_SP_NO
		LD	BC,#FF9C
		CALL	OUT_SP_NO
		LD	C,#F6
		CALL	OUT_SP_NO
		LD	A,L
OUT_NUM_4:	CALL	OUT_CODE
		POP	HL
		POP	DE
		RET

; The offset table for command interpretation
OFFST_TBL:	DB	#B1			; P_DEF_FN
		DB	#CB			; P_CAT
		DB	#BC			; P_FORMAT
		DB	#BF			; P_MOVE
		DB	#C4			; P_ERASE
		DB	#AF			; P_OPEN
		DB	#B4			; P_CLOSE
		DB	#93			; P_MERGE
		DB	#91			; P_VERIFY
		DB	#92			; P_BEEP
		DB	#95			; P_CIRCLE
		DB	#98			; P_INK
		DB	#98			; P_PAPER
		DB	#98			; P_FLASH
		DB	#98			; P_BRIGHT
		DB	#98			; P_INVERSE
		DB	#98			; P_OVER
		DB	#98			; P_OUT
		DB	#7F			; P_LPRINT
		DB	#81			; P_LLIST
		DB	#2E			; P_STOP
		DB	#6C			; P_READ
		DB	#6E			; P_DATA
		DB	#70			; P_RESTORE
		DB	#48			; P_NEW
		DB	#94			; P_BORDER
		DB	#56			; P_CONT
		DB	#3F			; P_DIM
		DB	#41			; P_REM
		DB	#2B			; P_FOR
		DB	#17			; P_GO_TO
		DB	#1F			; P_GO_SUB
		DB	#37			; P_INPUT
		DB	#77			; P_LOAD
		DB	#44			; P_LIST
		DB	#0F			; P_LET
		DB	#59			; P_PAUSE
		DB	#2B			; P_NEXT
		DB	#43			; P_POKE
		DB	#2D			; P_PRINT
		DB	#51			; P_PLOT
		DB	#3A			; P_RUN
		DB	#6D			; P_SAVE
		DB	#42			; P_RANDOM
		DB	#0D			; P_IF
		DB	#49			; P_CLS
		DB	#5C			; P_DRAW
		DB	#44			; P_CLEAR
		DB	#15			; P_RETURN
		DB	#5D			; P_COPY

; The parameter table. List of parameters for commands.		
P_LET:		DB	#01
		DB	"="
		DB	#02

P_GO_TO:	DB	#03			; BSROM - enhanced GOTO command, parameter is optional
		DW	GO_TO
		DB	#00

P_IF:		DB	#06
		DB	#CB
		DB	#05
		DW	IF_CMD

P_GO_SUB:	DB	#03			; BSROM - enhanced GOSUB command, parameter is optional
		DW	GO_SUB
		DB	#00
	
P_STOP:		DB	#00
		DW	STOP

P_RETURN:	DB	#00
		DW	RETURN

P_FOR:		DB	#04
		DB	"="
		DB	#06
		DB	#CC
		DB	#06
		DB	#05
		DW	FOR

P_NEXT:		DB	#04
		DB	#00
		DW	NEXT

P_PRINT:	DB	#05
		DW	PRINT

P_INPUT:	DB	#05
		DW	INPUT

P_DIM:		DB	#05
		DW	DIM

P_REM:		DB	#05
		DW	REM

P_NEW:		DB	#00
		DW	NEW

P_RUN:		DB	#03
		DW	RUN

P_LIST:		DB	#05
		DW	LIST

P_POKE:		DB	#06			; BSROM - enhanced POKE comand, added more items
		DB	#05
		DW	NEW_POKE

P_RANDOM:	DB	#03
		DW	RANDOMIZE

P_CONT:		DB	#03			; BSROM - enhanced CONTINUE command, added numeric parameter
		DW	NEW_CONT
	
P_CLEAR:	DB	#03
		DW	CLEAR

P_CLS:		DB	#03			; BSROM - enhanced CLS command, added numeric parameter
		DW	NEW_CLS

P_PLOT:		DB	#09
		DB	#00
		DW	PLOT

P_PAUSE:	DB	#03			; BSROM - enhanced PAUSE command, parameter is optional
		DW	PAUSE
		DB	#00

P_READ:		DB	#05
		DW	READ

P_DATA:		DB	#05
		DW	DATA

P_RESTORE:	DB	#03
		DW	RESTORE

P_DRAW:		DB	#09
		DB	#05
		DW	DRAW

P_COPY:		DB	#00
		DW	COPY

P_LPRINT:	DB	#05
		DW	LPRINT

P_LLIST:	DB	#05
		DW	LLIST

P_SAVE:		DB	#0B
P_LOAD:		DB	#0B
P_VERIFY:	DB	#0B
P_MERGE:	DB	#0B

P_BEEP:		DB	#08
		DB	#00
		DW	BEEP

P_CIRCLE:	DB	#09
		DB	#05
		DW	CIRCLE

P_INK:		DB	#07
P_PAPER:	DB	#07
P_FLASH:	DB	#07
P_BRIGHT:	DB	#07
P_INVERSE:	DB	#07
P_OVER:		DB	#07

P_OUT:		DB	#08
		DB	#00
		DW	OUT_CMD

P_BORDER:	DB	#03			; BSROM - enhanced BORDER command, parameter s optional
		DW	BORDER
		DB	#00
	
P_DEF_FN:	DB	#05
		DW	DEF_FN

P_OPEN:		DB	#06
		DB	","
		DB	#0A
		DB	#00
		DW	OPEN

P_CLOSE:	DB	#06
		DB	#00
		DW	CLOSE

P_FORMAT:	DB	#0A
		DB	#00
		DW	CAT_ETC

P_MOVE:		DB	#0A
		DB	","
		DB	#0A
		DB	#00
		DW	CAT_ETC

P_ERASE:	DB	#0A
		DB	#00
		DW	CAT_ETC

P_CAT:		DB	#00
		DW	CAT_ETC

; Main parser of BASIC interpreter
LINE_SCAN:	RES	7,(IY+#01)
		CALL	E_LINE_NO
		XOR	A
		LD	(#5C47),A
		DEC	A
		LD	(#5C3A),A
		JR	STMT_L_1

; Statement loop
STMT_LOOP:	RST	#20
STMT_L_1:	CALL	SET_WORK
		INC	(IY+#0D)
		JP	M,REPORT_C
		RST	#18
		LD	B,#00
		CP	#0D
		JR	Z,LINE_END
		CP	#3A
		JR	Z,STMT_LOOP
		LD	HL,STMT_RET
		PUSH	HL
		CP	#CE			;BSROM - automatic print
		JP	C,COMM
		SUB	#CE
		LD	C,A
		RST	#20
		LD	HL,OFFST_TBL
		ADD	HL,BC
		LD	C,(HL)
		ADD	HL,BC
		JR	GET_PARAM

; The main scanning loop
SCAN_LOOP:	LD	HL,(#5C74)
GET_PARAM:	LD	A,(HL)
		INC	HL
		LD	(#5C74),HL
		LD	BC,SCAN_LOOP
		PUSH	BC
		LD	C,A
		CP	#20
		JR	NC,SEPARATOR
		LD	HL,CLASS_TBL
		LD	B,#00
		ADD	HL,BC
		LD	C,(HL)
		ADD	HL,BC
		PUSH	HL
		RST	#18
		DEC	B
		RET

; Verify that the mandatory separator is present in correct location
SEPARATOR:	RST	#18
		CP	C
		JP	NZ,REPORT_C
		RST	#20
		RET

; Handle BREAK, return, and direct commands
STMT_RET:	CALL	BREAK_KEY
		JR	C,STMT_R_1
REPORT_L:	RST	#08			; Error report
		DB	#14			; BREAK into program
STMT_R_1:	BIT	7,(IY+#0A)
		JR	NZ,STMT_NEXT
		LD	HL,(#5C42)
		BIT	7,H
		JR	Z,LINE_NEW
LINE_RUN:	LD	HL,#FFFE
		LD	(#5C45),HL
		LD	HL,(#5C61)
		DEC	HL
		LD	DE,(#5C59)
		DEC	DE
		LD	A,(#5C44)
		JR	NEXT_LINE

; Find start address of a new line
LINE_NEW:	CALL	LINE_ADDR
		LD	A,(#5C44)
		JR	Z,LINE_USE
		AND	A
		JR	NZ,REPORT_N
		LD	B,A
		LD	A,(HL)
		AND	#C0
		LD	A,B
		JR	Z,LINE_USE
REPORT_0:	RST	#08			; Error report
		DB	#FF			; OK

; REM command
REM:		POP	BC

; End of line test
LINE_END:	CALL	SYNTAX_Z
		RET	Z
		LD	HL,(#5C55)
		LD	A,#C0
		AND	(HL)
		RET	NZ
		XOR	A
LINE_USE:	CP	#01			; General line checking
		ADC	A,#00
		LD	D,(HL)
		INC	HL
		LD	E,(HL)
		LD	(#5C45),DE
		INC	HL
		LD	E,(HL)
		INC	HL
		LD	D,(HL)
		EX	DE,HL
		ADD	HL,DE
		INC	HL
NEXT_LINE:	LD	(#5C55),HL
		EX	DE,HL
		LD	(#5C5D),HL
		LD	D,A
		LD	E,#00
		LD	(IY+#0A),#FF
		DEC	D
		LD	(IY+#0D),D
		JP	Z,STMT_LOOP
		INC	D
		CALL	EACH_STMT
		JR	Z,STMT_NEXT
REPORT_N:	RST	#08			; Error report
		DB	#16			; Statement lost

; End of statements
CHECK_END:	CALL	SYNTAX_Z
		RET	NZ
		POP	BC
		POP	BC
STMT_NEXT:	RST	#18			; Go to next statement
		CP	#0D
		JR	Z,LINE_END
		CP	#3A
		JP	Z,STMT_LOOP
		JP	REPORT_C

; Command class table
CLASS_TBL:	DB	#0F			; CLASS_00
		DB	#1D			; CLASS_01
		DB	#4B			; CLASS_02
		DB	#09			; CLASS_03
		DB	#67			; CLASS_04
		DB	#0B			; CLASS_05
		DB	#7B			; CLASS_06
		DB	#8E			; CLASS_07
		DB	#71			; CLASS_08
		DB	#B4			; CLASS_09
		DB	#81			; CLASS_0A
		DB	#CF			; CLASS_0B

; Command classes 00 - no operand, 03 - optional operand, 05 - variable syntax checked by routine
CLASS_03:	CALL	FETCH_NUM
CLASS_00:	CP	A
CLASS_05:	POP	BC
		CALL	Z,CHECK_END
		EX	DE,HL
		LD	HL,(#5C74)
		LD	C,(HL)
		INC	HL
		LD	B,(HL)
		EX	DE,HL
		PUSH	BC
		RET

; Command classes
; 01 - variable is required 
; 02 - expression is required
; 04 - single character variable is required 
CLASS_01:	CALL	LOOK_VARS
VAR_A_1:	LD	(IY+#37),#00
		JR	NC,VAR_A_2
		SET	1,(IY+#37)
		JR	NZ,VAR_A_3
REPORT_2:	RST	#08			; Error report
		DB	#01			; Variable not found;
VAR_A_2:	CALL	Z,STK_VAR
		BIT	6,(IY+#01)
		JR	NZ,VAR_A_3
		XOR	A
		CALL	SYNTAX_Z
		CALL	NZ,STK_FETCH
		LD	HL,#5C71
		OR	(HL)
		LD	(HL),A
		EX	DE,HL
VAR_A_3:	LD	(#5C72),BC
		LD	(#5C4D),HL
		RET

CLASS_02:	POP	BC
		CALL	VAL_FET_1
		CALL	CHECK_END
		RET

; Fetch a value
VAL_FET_1:	LD	A,(#5C3B)
VAL_FET_2:	PUSH	AF
		CALL	SCANNING
		POP	AF
		LD	D,(IY+#01)
		XOR	D
		AND	#40
		JR	NZ,REPORT_C
		BIT	7,D
		JP	NZ,LET
		RET

CLASS_04:	CALL	LOOK_VARS
		PUSH	AF
		LD	A,C
		OR	#9F
		INC	A
		JR	NZ,REPORT_C
		POP	AF
		JR	VAR_A_1

; Command classes
; 06 - numeric expression is expected
; 08 - two numeric expressions separated by comma are expected
; 0A - string expression is expected
NEXT_2NUM:	RST	#20
EXPT_2NUM:	CALL	EXPT_1NUM		; CLASS_08
		CP	#2C
		JR	NZ,REPORT_C
		RST	#20
EXPT_1NUM:	CALL	SCANNING		; CLASS_06
		BIT	6,(IY+#01)
		RET	NZ
REPORT_C:	RST	#08			; Error report
		DB	#0B			; Nonsense in BASIC
EXPT_EXP:	CALL	SCANNING		; CLASS_0A
		BIT	6,(IY+#01)
		RET	Z
		JR	REPORT_C

; Command class 07 - set permanent colors
CLASS_07:	BIT	7,(IY+#01)
		RES	0,(IY+#02)
		CALL	NZ,TEMPS
		POP	AF
		LD	A,(#5C74)
		SUB	#13
		CALL	CO_TEMP_4
		CALL	CHECK_END
		LD	HL,(#5C8F)
		LD	(#5C8D),HL
		LD	HL,#5C91
		LD	A,(HL)
		RLCA
		XOR	(HL)
		AND	#AA
		XOR	(HL)
		LD	(HL),A
		RET

; Command class 09 - two coordinates, could be preceded by embedded color commands
CLASS_09:	CALL	SYNTAX_Z
		JR	Z,CL_09_1
		RES	0,(IY+#02)
		CALL	TEMPS
		LD	HL,#5C90
		LD	A,(HL)
		OR	#F8
		LD	(HL),A
		RES	6,(IY+#57)
		RST	#18
CL_09_1:	CALL	CO_TEMP_2
		JR	EXPT_2NUM

; Command class 09 - four commands handling
		JP	SAVE_ETC

; Fetch a number
FETCH_NUM:	CP	#0D
		JR	Z,USE_ZERO
		CP	#3A
		JR	NZ,EXPT_1NUM		
USE_ZERO:	CALL	SYNTAX_Z		; Place 0 on the calculator stack
		RET	Z
		RST	#28			;FP_CALC
		DB	#A0			;STK_ZERO
		DB	#38			;END_CALC
		RET

; Handle STOP command
STOP:		RST	#08			; Error report
		DB	#08			; STOP statement

; Handle IF command
IF_CMD:		POP	BC
		CALL	SYNTAX_Z
		JR	Z,IF_1
		RST	#28			;FP_CALC
		DB	#02			;DELETE
		DB	#38			;END_CALC
		EX	DE,HL
		CALL	TEST_ZERO
		JP	C,LINE_END
IF_1:		JP	STMT_L_1

; Handle FOR command
FOR:		CP	#CD
		JR	NZ,F_USE_1
		RST	#20
		CALL	EXPT_1NUM
		CALL	CHECK_END
		JR	F_REORDER

F_USE_1:	CALL	CHECK_END
		RST	#28			;FP_CALC
		DB	#A1			;STK_ONE
		DB	#38			;END_CALC
F_REORDER:	RST	#28			;FP_CALC
		DB	#C0			;ST_MEM_0
		DB	#02			;DELETE
		DB	#01			;EXCHANGE
		DB	#E0			;GET_MEM_0
		DB	#01			;EXCHANGE
		DB	#38			;END_CALC
		CALL	LET
		LD	(#5C68),HL
		DEC	HL
		LD	A,(HL)
		SET	7,(HL)
		LD	BC,#0006
		ADD	HL,BC
		RLCA
		JR	C,F_L_S
		LD	C,#0D
		CALL	MAKE_ROOM
		INC	HL
F_L_S:		PUSH	HL
		RST	#28			;FP_CALC
		DB	#02			;DELETE
		DB	#02			;DELETE
		DB	#38			;END_CALC
		POP	HL
		EX	DE,HL
		LD	C,#0A
		LDIR
		LD	HL,(#5C45)
		EX	DE,HL
		LD	(HL),E
		INC	HL
		LD	(HL),D
		LD	D,(IY+#0D)
		INC	D
		INC	HL
		LD	(HL),D
		CALL	NEXT_LOOP
		RET	NC
		LD	B,(IY+#38)
		LD	HL,(#5C45)
		LD	(#5C42),HL
		LD	A,(#5C47)
		NEG
		LD	D,A
		LD	HL,(#5C5D)
		LD	E,#F3
F_LOOP:		PUSH	BC
		LD	BC,(#5C55)
		CALL	LOOK_PROG
		LD	(#5C55),BC
		POP	BC
		JR	C,REPORT_I
		RST	#20
		OR	#20
		CP	B
		JR	Z,F_FOUND
		RST	#20
		JR	F_LOOP

F_FOUND:	RST	#20
		LD	A,#01
		SUB	D
		LD	(#5C44),A
		RET

REPORT_I:	RST	#08			; Error report
		DB	#11			; FOR without NEXT

; Search the program area for DATA, DEF FN or NEXT keywords
LOOK_PROG:	LD	A,(HL)
		CP	#3A
		JR	Z,LOOK_P_2
LOOK_P_1:	INC	HL
		LD	A,(HL)
		AND	#C0
		SCF
		RET	NZ
		LD	B,(HL)
		INC	HL
		LD	C,(HL)
		LD	(#5C42),BC
		INC	HL
		LD	C,(HL)
		INC	HL
		LD	B,(HL)
		PUSH	HL
		ADD	HL,BC
		LD	B,H
		LD	C,L
		POP	HL
		LD	D,#00
LOOK_P_2:	PUSH	BC
		CALL	EACH_STMT
		POP	BC
		RET	NC
		JR	LOOK_P_1

; Handle NEXT command
NEXT:		BIT	1,(IY+#37)
		JP	NZ,REPORT_2
		LD	HL,(#5C4D)
		BIT	7,(HL)
		JR	Z,REPORT_1
		INC	HL
		LD	(#5C68),HL
		RST	#28			;FP_CALC
		DB	#E0			;GET_MEM_0
		DB	#E2			;GET_MEM_2
		DB	#0F			;ADDITION
		DB	#C0			;ST_MEM_0
		DB	#02			;DELETE
		DB	#38			;END_CALC
		CALL	NEXT_LOOP
		RET	C
		LD	HL,(#5C68)
		LD	DE,#000F
		ADD	HL,DE
		LD	E,(HL)
		INC	HL
		LD	D,(HL)
		INC	HL
		LD	H,(HL)
		EX	DE,HL
		JP	GO_TO_2

REPORT_1:	RST	#08			; Error report
		DB	#00			; NEXT withou FOR

; Test iterations for FOR command
NEXT_LOOP:	RST	#28			;FP_CALC
		DB	#E1			;GET_MEM_1
		DB	#E0			;GET_MEM_0
		DB	#E2			;GET_MEM_2
		DB	#36			;LESS_0
		DB	#00			;JUMP_TRUE
		DB	#02			;NEXT_1 if step negative
		DB	#01			;EXCHANGE
NEXT_1:		DB	#03			;SUBTRACT
		DB	#37			;GREATER_0
		DB	#00			;JUMP_TRUE
		DB	#04			;NEXT_2 if finished
		DB	#38			;END_CALC
		AND	A
		RET
	
NEXT_2:		DB	#38			;END_CALC
		SCF
		RET

; Handle READ command
READ_3:		RST	#20
READ:		CALL	CLASS_01
		CALL	SYNTAX_Z
		JR	Z,READ_2
		RST	#18
		LD	(#5C5F),HL
		LD	HL,(#5C57)
		LD	A,(HL)
		CP	#2C
		JR	Z,READ_1
		LD	E,#E4
		CALL	LOOK_PROG
		JR	NC,READ_1
REPORT_E:	RST	#08			; Error report
		DB	#0D			; Out of data
READ_1:		CALL	TEMP_PTR1
		CALL	VAL_FET_1
		RST	#18
		LD	(#5C57),HL
		LD	HL,(#5C5F)
		LD	(IY+#26),#00
		CALL	TEMP_PTR2
READ_2:		RST	#18
		CP	#2C
		JR	Z,READ_3
		CALL	CHECK_END
		RET

; Handle DATA command
DATA:		CALL	SYNTAX_Z
		JR	NZ,DATA_2
DATA_1:		CALL	SCANNING
		CP	#2C
		CALL	NZ,CHECK_END
		RST	#20
		JR	DATA_1

DATA_2:		LD	A,#E4
PASS_BY:	LD	B,A
		CPDR
		LD	DE,#0200
		JP	EACH_STMT

; Handle RESTORE command
RESTORE:	CALL	FIND_INT2
REST_RUN:	LD	H,B
		LD	L,C
		CALL	LINE_ADDR
		DEC	HL
		LD	(#5C57),HL
		RET

; Handle RANDOMIZE command
RANDOMIZE:	CALL	FIND_INT2
		LD	A,B
		OR	C
		JR	NZ,RAND_1
		LD	BC,(#5C78)
RAND_1:		LD	(#5C76),BC
		RET

; Handle CONTINUE command
CONTINUE:	LD	HL,(#5C6E)
		LD	D,(IY+#36)
		JR	GO_TO_2

; Handle GOTO command
GO_TO:		CALL	FIND_INT2
		LD	H,B
		LD	L,C
		LD	D,#00
		LD	A,H
		CP	#F0
		JR	NC,REPORT_BB
GO_TO_2:	LD	(#5C42),HL
		LD	(IY+#0A),D
		RET

; Handle OUT command
OUT_CMD:	CALL	TWO_PARAM
		OUT	(C),A
		RET

; BSROM - fix for rewriting first bytes of ROM
; was POKE command handling here originally
NO_RW_AT0:	LD	DE,(#5C65)
		RET

; BSROM - extended command parameters
TWO_PARAM:	CALL	FP_TO_A
		PUSH	AF
		CALL	FIND_INT2
		POP	AF
ROZPAR:		JR	C,REPORT_BB
		JR	Z,ROZPAR_1
		NEG
ROZPAR_1:	RET

; Find integers
FIND_INT1:	CALL	FP_TO_A
		JR	ROZPAR

FIND_INT2:	CALL	FP_TO_BC
		JR	C,REPORT_BB
		RET	Z

REPORT_BB:	RST	#08			; Error report
		DB	#0A			; Integer out of range

; Handle RUN command
RUN:		CALL	GO_TO
		LD	BC,#0000
		CALL	REST_RUN
		JR	CLEAR_RUN

; Handle CLEAR command
CLEAR:		CALL	FIND_INT2
CLEAR_RUN:	LD	A,B
		OR	C
		JR	NZ,CLEAR_1
		LD	BC,(#5CB2)
CLEAR_1:	PUSH	BC
		LD	DE,(#5C4B)
		LD	HL,(#5C59)
		DEC	HL
		CALL	RECLAIM_1
		CALL	CLS
		LD	HL,(#5C65)
		LD	DE,#0032
		ADD	HL,DE
		POP	DE
		SBC	HL,DE
		JR	NC,REPORT_M
		LD	HL,(#5CB4)
		AND	A
		SBC	HL,DE
		JR	NC,CLEAR_2
REPORT_M:	RST	#08			; Error report
		DB	#15			; RAMTOP no good
CLEAR_2:	EX	DE,HL
		LD	(#5CB2),HL
		POP	DE
		POP	BC
		LD	(HL),#3E
		DEC	HL
		LD	SP,HL
		PUSH	BC
		LD	(#5C3D),SP
		EX	DE,HL
		JP	(HL)

; Handle GO SUB command
GO_SUB:		POP	DE
		LD	H,(IY+#0D)
		INC	H
		EX	(SP),HL
		INC	SP
		LD	BC,(#5C45)
		PUSH	BC
		PUSH	HL
		LD	(#5C3D),SP
		PUSH	DE
		CALL	GO_TO
		LD	BC,#0014
TEST_ROOM:	LD	HL,(#5C65)		; Check available memory
		ADD	HL,BC
		JR	C,REPORT_4
		EX	DE,HL
		LD	HL,#0050
		ADD	HL,DE
		JR	C,REPORT_4
		SBC	HL,SP
		RET	C
REPORT_4:	LD	L,#03
		JP	ERROR_3

; Get free memory. Not used in ROM, but can be used by user
FREE_MEM:	LD	BC,#0000
		CALL	TEST_ROOM
		LD	B,H
		LD	C,L
		RET

; Handle RETURN command
RETURN:		POP	BC
		POP	HL
		POP	DE
		LD	A,D
		CP	#3E
		JR	Z,REPORT_7
		DEC	SP
		EX	(SP),HL
		EX	DE,HL
		LD	(#5C3D),SP
		PUSH	BC
		JP	GO_TO_2
REPORT_7:	PUSH	DE
		PUSH	HL
		RST	#08			; Error report
		DB	#06			; RETURN without GOSUB

; Handle PAUSE command
PAUSE:		CALL	FIND_INT2
PAUSE_1:	HALT
		DEC	BC
		LD	A,B
		OR	C
		JR	Z,PAUSE_END
		LD	A,B
		AND	C
		INC	A
		JR	NZ,PAUSE_2
		INC	BC
PAUSE_2:	BIT	5,(IY+#01)
		JR	Z,PAUSE_1
PAUSE_END:	RES	5,(IY+#01)
		RET

; Check for BREAK key
BREAK_KEY:	LD	A,#7F
		IN	A,(#FE)
		RRA
		RET	C
		LD	A,#FE
		IN	A,(#FE)
		RRA
		RET

; Handle DEF FN command
DEF_FN:		CALL	SYNTAX_Z
		JR	Z,DEF_FN_1
		LD	A,#CE
		JP	PASS_BY

DEF_FN_1:	SET	6,(IY+#01)
		CALL	ALPHA
		JR	NC,DEF_FN_4
		RST	#20
		CP	#24
		JR	NZ,DEF_FN_2
		RES	6,(IY+#01)
		RST	#20
DEF_FN_2:	CP	#28
		JR	NZ,DEF_FN_7
		RST	#20
		CP	#29
		JR	Z,DEF_FN_6
DEF_FN_3:	CALL	ALPHA
DEF_FN_4:	JP	NC,REPORT_C
		EX	DE,HL
		RST	#20
		CP	#24
		JR	NZ,DEF_FN_5
		EX	DE,HL
		RST	#20
DEF_FN_5:	EX	DE,HL
		LD	BC,#0006
		CALL	MAKE_ROOM
		INC	HL
		INC	HL
		LD	(HL),#0E
		CP	#2C
		JR	NZ,DEF_FN_6
		RST	#20
		JR	DEF_FN_3

DEF_FN_6:	CP	#29
		JR	NZ,DEF_FN_7
		RST	#20
		CP	#3D
		JR	NZ,DEF_FN_7
		RST	#20
		LD	A,(#5C3B)
		PUSH	AF
		CALL	SCANNING
		POP	AF
		XOR	(IY+#01)
		AND	#40
DEF_FN_7:	JP	NZ,REPORT_C
		CALL	CHECK_END
UNSTACK_Z:	CALL	SYNTAX_Z
		POP	HL
		RET	Z
		JP	(HL)

; Handle LPRINT command
LPRINT:		LD	A,#03
		JR	PRINT_1

; Handle PRINT command
PRINT:		LD	A,#02
PRINT_1:	CALL	SYNTAX_Z
		CALL	NZ,CHAN_OPEN
		CALL	TEMPS
		CALL	PRINT_2
		CALL	CHECK_END
		RET

PRINT_2:	RST	#18
		CALL	PR_END_Z
		JR	Z,PRINT_4
PRINT_3:	CALL	PR_POSN_1
		JR	Z,PRINT_3
		CALL	PR_ITEM_1
		CALL	PR_POSN_1
		JR	Z,PRINT_3
PRINT_4:	CP	#29
		RET	Z
PRINT_CR:	CALL	UNSTACK_Z
PRINT_5:	LD	A,#0D
		RST	#10
		RET

; Print items
PR_ITEM_1:	RST	#18
		CP	#AC
		JR	NZ,PR_ITEM_2
		CALL	NEXT_2NUM
		CALL	UNSTACK_Z
		CALL	STK_TO_BC
		LD	A,#16
		JR	PR_AT_TAB

PR_ITEM_2:	CP	#AD
		JR	NZ,PR_ITEM_3
		RST	#20
		CALL	EXPT_1NUM
		CALL	UNSTACK_Z
		CALL	FIND_INT2
		LD	A,#17
PR_AT_TAB:	RST	#10
		LD	A,C
		RST	#10
		LD	A,B
		RST	#10
		RET

PR_ITEM_3:	CALL	CO_TEMP_3
		RET	NC
		CALL	STR_ALTER
		RET	NC
		CALL	SCANNING
		CALL	UNSTACK_Z
		BIT	6,(IY+#01)
		CALL	Z,STK_FETCH
		JP	NZ,PRINT_FP
PR_STRING:	LD	A,B
		OR	C
		DEC	BC
		RET	Z
		LD	A,(DE)
		INC	DE
		RST	#10
		JR	PR_STRING

; End of printing
PR_END_Z:	CP	#29			; ')'
		RET	Z
PR_ST_END:	CP	#0D			; carriage return
		RET	Z
		CP	#3A			; ':'
		RET

; Consider print position by ';' or ',' or '''
PR_POSN_1:	RST	#18
		CP	#3B
		JR	Z,PR_POSN_3
		CP	#2C
		JR	NZ,PR_POSN_2
		CALL	SYNTAX_Z
		JR	Z,PR_POSN_3
		LD	A,#06
		RST	#10
		JR	PR_POSN_3

PR_POSN_2:	CP	#27
		RET	NZ
		CALL	PRINT_CR
PR_POSN_3:	RST	#20
		CALL	PR_END_Z
		JR	NZ,PR_POSN_4
		POP	BC
PR_POSN_4:	CP	A
		RET

; Alter stream
STR_ALTER:	CP	#23
		SCF
		RET	NZ
		RST	#20
		CALL	EXPT_1NUM
		AND	A
		CALL	UNSTACK_Z
		CALL	FIND_INT1
		CP	#10
		JP	NC,REPORT_OA
		CALL	CHAN_OPEN
		AND	A
		RET

; Handle INPUT command
INPUT:		CALL	SYNTAX_Z
		JR	Z,INPUT_1
		LD	A,#01
		CALL	CHAN_OPEN
		CALL	CLS_LOWER
INPUT_1:	LD	(IY+#02),#01
		CALL	IN_ITEM_1
		CALL	CHECK_END
		LD	BC,(#5C88)
		LD	A,(#5C6B)
		CP	B
		JR	C,INPUT_2
		LD	C,#21
		LD	B,A
INPUT_2:	LD	(#5C88),BC
		LD	A,#19
		SUB	B
		LD	(#5C8C),A
		RES	0,(IY+#02)
		CALL	CL_SET
		JP	CLS_LOWER

; Handle input items from the current input channel
IN_ITEM_1:	CALL	PR_POSN_1
		JR	Z,IN_ITEM_1
		CP	#28
		JR	NZ,IN_ITEM_2
		RST	#20
		CALL	PRINT_2
		RST	#18
		CP	#29
		JP	NZ,REPORT_C
		RST	#20
		JP	IN_NEXT_2

IN_ITEM_2:	CP	#CA
		JR	NZ,IN_ITEM_3
		RST	#20
		CALL	CLASS_01
		SET	7,(IY+#37)
		BIT	6,(IY+#01)
		JP	NZ,REPORT_C
		JR	IN_PROMPT

IN_ITEM_3:	CALL	ALPHA
		JP	NC,IN_NEXT_1
		CALL	CLASS_01
		RES	7,(IY+#37)
IN_PROMPT:	CALL	SYNTAX_Z
		JP	Z,IN_NEXT_2
		CALL	SET_WORK
		LD	HL,#5C71
		RES	6,(HL)
		SET	5,(HL)
		LD	BC,#0001
		BIT	7,(HL)
		JR	NZ,IN_PR_2
		LD	A,(#5C3B)
		AND	#40
		JR	NZ,IN_PR_1
		LD	C,#03
IN_PR_1:	OR	(HL)
		LD	(HL),A
IN_PR_2:	RST	#30
		LD	(HL),#0D
		LD	A,C
		RRCA
		RRCA
		JR	NC,IN_PR_3
		LD	A,#22
		LD	(DE),A
		DEC	HL
		LD	(HL),A
IN_PR_3:	LD	(#5C5B),HL
		BIT	7,(IY+#37)
		JR	NZ,IN_VAR_3
		LD	HL,(#5C5D)
		PUSH	HL
		LD	HL,(#5C3D)
		PUSH	HL
IN_VAR_1:	LD	HL,IN_VAR_1
		PUSH	HL
		BIT	4,(IY+#30)
		JR	Z,IN_VAR_2
		LD	(#5C3D),SP
IN_VAR_2:	LD	HL,(#5C61)
		CALL	REMOVE_FP
		LD	(IY+#00),#FF
		CALL	EDITOR
		RES	7,(IY+#01)
		CALL	IN_ASSIGN
		JR	IN_VAR_4

IN_VAR_3:	CALL	EDITOR
IN_VAR_4:	LD	(IY+#22),#00
		CALL	IN_CHAN_K
		JR	NZ,IN_VAR_5
		CALL	ED_COPY
		LD	BC,(#5C82)
		CALL	CL_SET
IN_VAR_5:	LD	HL,#5C71
		RES	5,(HL)
		BIT	7,(HL)
		RES	7,(HL)
		JR	NZ,IN_VAR_6
		POP	HL
		POP	HL
		LD	(#5C3D),HL
		POP	HL
		LD	(#5C5F),HL
		SET	7,(IY+#01)
		CALL	IN_ASSIGN
		LD	HL,(#5C5F)
		LD	(IY+#26),#00
		LD	(#5C5D),HL
		JR	IN_NEXT_2

IN_VAR_6:	LD	HL,(#5C63)
		LD	DE,(#5C61)
		SCF
		SBC	HL,DE
		LD	B,H
		LD	C,L
		CALL	STK_STO_D
		CALL	LET
		JR	IN_NEXT_2

IN_NEXT_1:	CALL	PR_ITEM_1
IN_NEXT_2:	CALL	PR_POSN_1
		JP	Z,IN_ITEM_1
		RET

; INPUT sytax check and assignment
IN_ASSIGN:	LD	HL,(#5C61)
		LD	(#5C5D),HL
		RST	#18
		CP	#E2			; STOP
		JR	Z,IN_STOP
		LD	A,(#5C71)
		CALL	VAL_FET_2
		RST	#18
		CP	#0D			; carriage return
		RET	Z
REPORT_CB:	RST	#08			; Error report
		DB	#0B			; Nonsense in BASIC
IN_STOP:	CALL	SYNTAX_Z
		RET	Z
REPORT_H:	RST	#08			; Error report
		DB	#10			; STOP in INPUT
IN_CHAN_K:	LD	HL,(#5C51)		; Test for K channel
		INC	HL
		INC	HL
		INC	HL
		INC	HL
		LD	A,(HL)
		CP	#4B
		RET

; Color item routines
CO_TEMP_1:	RST	#20
CO_TEMP_2:	CALL	CO_TEMP_3
		RET	C
		RST	#18
		CP	#2C
		JR	Z,CO_TEMP_1
		CP	#3B
		JR	Z,CO_TEMP_1
		JP	REPORT_C

CO_TEMP_3:	CP	#D9
		RET	C
		CP	#DF
		CCF
		RET	C
		PUSH	AF
		RST	#20
		POP	AF
CO_TEMP_4:	SUB	#C9
		PUSH	AF
		CALL	EXPT_1NUM
		POP	AF
		AND	A
		CALL	UNSTACK_Z
		PUSH	AF
		CALL	FIND_INT1
		LD	D,A
		POP	AF
		RST	#10
		LD	A,D
		RST	#10
		RET

; The color system variable handler
CO_TEMP_5:	SUB	#11
		ADC	A,#00
		JR	Z,CO_TEMP_7
		SUB	#02
		ADC	A,#00
		JR	Z,CO_TEMP_C
		CP	#01
		LD	A,D
		LD	B,#01
		JR	NZ,CO_TEMP_6
		RLCA
		RLCA
		LD	B,#04
CO_TEMP_6:	LD	C,A
		LD	A,D
		CP	#02
		JR	NC,REPORT_K
		LD	A,C
		LD	HL,#5C91
		JR	CO_CHANGE
CO_TEMP_7:	LD	A,D
		LD	B,#07
		JR	C,CO_TEMP_8
		RLCA
		RLCA
		RLCA
		LD	B,#38
CO_TEMP_8:	LD	C,A
		LD	A,D
		CP	#0A
		JR	C,CO_TEMP_9
REPORT_K:	RST	#08			; Error report
		DB	#13			; Invalid colour
CO_TEMP_9:	LD	HL,#5C8F
		CP	#08
		JR	C,CO_TEMP_B
		LD	A,(HL)
		JR	Z,CO_TEMP_A
		OR	B
		CPL
		AND	#24
		JR	Z,CO_TEMP_A
		LD	A,B
CO_TEMP_A:	LD	C,A
CO_TEMP_B:	LD	A,C
		CALL	CO_CHANGE
		LD	A,#07
		CP	D
		SBC	A,A
		CALL	CO_CHANGE
		RLCA
		RLCA
		AND	#50
		LD	B,A
		LD	A,#08
		CP	D
		SBC	A,A

; Handle change of color
CO_CHANGE:	XOR	(HL)
		AND	B
		XOR	(HL)
		LD	(HL),A
		INC	HL
		LD	A,B
		RET

CO_TEMP_C:	SBC	A,A
		LD	A,D
		RRCA
		LD	B,#80
		JR	NZ,CO_TEMP_D
		RRCA
		LD	B,#40
CO_TEMP_D:	LD	C,A
		LD	A,D
		CP	#08
		JR	Z,CO_TEMP_E
		CP	#02
		JR	NC,REPORT_K
CO_TEMP_E:	LD	A,C
		LD	HL,#5C8F
		CALL	CO_CHANGE
		LD	A,C
		RRCA
		RRCA
		RRCA
		JR	CO_CHANGE

; Handle BORDER command
BORDER:		CALL	FIND_INT1
		CP	#08
		JR	NC,REPORT_K
		OUT	(#FE),A
		RLCA
		RLCA
		RLCA
		BIT	5,A
		JR	NZ,BORDER_1
		XOR	#07
BORDER_1:	LD	(#5C48),A
		RET

; Get pixel address
PIXEL_ADD:	LD	A,#AF
		SUB	B
		JP	C,REPORT_BC
		LD	B,A
		AND	A
		RRA
		SCF
		RRA
		AND	A
		RRA
		XOR	B
		AND	#F8
		XOR	B
		LD	H,A
		LD	A,C
		RLCA
		RLCA
		RLCA
		XOR	B
		AND	#C7
		XOR	B
		RLCA
		RLCA
		LD	L,A
		LD	A,C
		AND	#07
		RET

; Point subroutine
POINT_SUB:	CALL	STK_TO_BC
		CALL	PIXEL_ADD
		LD	B,A
		INC	B
		LD	A,(HL)
POINT_LP:	RLCA
		DJNZ	POINT_LP
		AND	#01
		JP	STACK_A

; Handle PLOT command
PLOT:		CALL	STK_TO_BC
		CALL	PLOT_SUB
		JP	TEMPS

PLOT_SUB:	LD	(#5C7D),BC
		CALL	PIXEL_ADD
		LD	B,A
		INC	B
		LD	A,#FE
PLOT_LOOP:	RRCA
		DJNZ	PLOT_LOOP
		LD	B,A
		LD	A,(HL)
		LD	C,(IY+#57)
		BIT	0,C
		JR	NZ,PL_TST_IN
		AND	B
PL_TST_IN:	BIT	2,C
		JR	NZ,PLOT_END
		XOR	B
		CPL
PLOT_END:	LD	(HL),A
		JP	PO_ATTR

; Put two numbers in BC register
STK_TO_BC:	CALL	STK_TO_A
		LD	B,A
		PUSH	BC
		CALL	STK_TO_A
		LD	E,C
		POP	BC
		LD	D,C
		LD	C,A
		RET

; Put the last value on the calc stack into the accumulator
STK_TO_A:	CALL	FP_TO_A
		JP	C,REPORT_BC
		LD	C,#01
		RET	Z
		LD	C,#FF
		RET

; Handle CIRCLE command
CIRCLE:		RST	#18
		CP	#2C
		JP	NZ,REPORT_C
		RST	#20
		CALL	EXPT_1NUM
		CALL	CHECK_END
		RST	#28			;FP_CALC
		DB	#2A			;ABS
		DB	#3D			;RE_STACK
		DB	#38			;END_CALC
		LD	A,(HL)
		CP	#81
		JR	NC,C_R_GRE_1
		RST	#28			;FP_CALC
		DB	#02			;DELETE
		DB	#38			;END_CALC
		JR	PLOT

C_R_GRE_1:	RST	#28			;FP_CALC
		DB	#A3			;STK_PI_2
		DB	#38			;END_CALC
		LD	(HL),#83
		RST	#28			;FP_CALC
		DB	#C5			;ST_MEM_5
		DB	#02			;DELETE
		DB	#38			;END_CALC
		CALL	CD_PRMS1
		PUSH	BC
		RST	#28			;FP_CALC
		DB	#31			;DUPLICATE
		DB	#E1			;GET_MEM_1
		DB	#04			;MULTIPLY
		DB	#38			;END_CALC
		LD	A,(HL)
		CP	#80
		JR	NC,C_ARC_GE1
		RST	#28			;FP_CALC
		DB	#02			;DELETE
		DB	#02			;DELETE
		DB	#38			;END_CALC
		POP	BC
		JP	PLOT

C_ARC_GE1:	RST	#28			;FP_CALC
		DB	#C2			;ST_MEM_2
		DB	#01			;EXCHANGE
		DB	#C0			;ST_MEM_0
		DB	#02			;DELETE
		DB	#03			;SUBTRACT
		DB	#01			;EXCHANGE
		DB	#E0			;GET_MEM_0
		DB	#0F			;ADDITION
		DB	#C0			;ST_MEM_0
		DB	#01			;EXCHANGE
		DB	#31			;DUPLICATE
		DB	#E0			;GET_MEM_0
		DB	#01			;EXCHANGE
		DB	#31			;DUPLICATE
		DB	#E0			;GET_MEM_0
		DB	#A0			;STK_ZERO
		DB	#C1			;ST_MEM_1
		DB	#02			;DELETE
		DB	#38			;END_CALC
		INC	(IY+#62)
		CALL	FIND_INT1
		LD	L,A
		PUSH	HL
		CALL	FIND_INT1
		POP	HL
		LD	H,A
		LD	(#5C7D),HL
		POP	BC
		JP	DRW_STEPS

; Handle DRAW command
DRAW:		RST	#18
		CP	#2C
		JR	Z,DR_3_PRMS
		CALL	CHECK_END
		JP	LINE_DRAW

DR_3_PRMS:	RST	#20
		CALL	EXPT_1NUM
		CALL	CHECK_END
		RST	#28			;FP_CALC
		DB	#C5			;ST_MEM_5
		DB	#A2			;STK_HALF
		DB	#04			;MULTIPLY
		DB	#1F			;SIN
		DB	#31			;DUPLICATE
		DB	#30			;NOT
		DB	#30			;NOT
		DB	#00			;JUMP_TRUE
		DB	#06			;to DR_SIN_NZ
		DB	#02			;DELETE
		DB	#38			;END_CALC
		JP	LINE_DRAW

DR_SIN_NZ:	DB	#C0			;ST_MEM_0
		DB	#02			;DELETE
		DB	#C1			;ST_MEM_1
		DB	#02			;DELETE
		DB	#31			;DUPLICATE
		DB	#2A			;ABS
		DB	#E1			;GET_MEM_1
		DB	#01			;EXCHANGE
		DB	#E1			;GET_MEM_1
		DB	#2A			;ABS
		DB	#0F			;ADDITION
		DB	#E0			;GET_MEM_0
		DB	#05			;DIVISION
		DB	#2A			;ABS
		DB	#E0			;GET_MEM_0
		DB	#01			;EXCHANGE
		DB	#3D			;RE_STACK
		DB	#38			;END_CALC
		LD	A,(HL)
		CP	#81
		JR	NC,DR_PRMS
		RST	#28			;FP_CALC
		DB	#02			;DELETE
		DB	#02			;DELETE
		DB	#38			;END_CALC
		JP	LINE_DRAW

DR_PRMS:	CALL	CD_PRMS1
		PUSH	BC
		RST	#28			;FP_CALC
		DB	#02			;DELETE
		DB	#E1			;GET_MEM_1
		DB	#01			;EXCHANGE
		DB	#05			;DIVISION
		DB	#C1			;ST_MEM_1
		DB	#02			;DELETE
		DB	#01			;EXCHANGE
		DB	#31			;DUPLICATE
		DB	#E1			;GET_MEM_1
		DB	#04			;MULTIPLY
		DB	#C2			;ST_MEM_2
		DB	#02			;DELETE
		DB	#01			;EXCHANGE
		DB	#31			;DUPLICATE
		DB	#E1			;GET_MEM_1
		DB	#04			;MULTIPLY
		DB	#E2			;GET_MEM_2
		DB	#E5			;GET_MEM_5
		DB	#E0			;GET_MEM_0
		DB	#03			;SUBTRACT
		DB	#A2			;STK_HALF
		DB	#04			;MULTIPLY
		DB	#31			;DUPLICATE
		DB	#1F			;SIN
		DB	#C5			;ST_MEM_5
		DB	#02			;DELETE
		DB	#20			;COS
		DB	#C0			;ST_MEM_0
		DB	#02			;DELETE
		DB	#C2			;ST_MEM_2
		DB	#02			;DELETE
		DB	#C1			;ST_MEM_1
		DB	#E5			;GET_MEM_5
		DB	#04			;MULTIPLY
		DB	#E0			;GET_MEM_0
		DB	#E2			;GET_MEM_2
		DB	#04			;MULTIPLY
		DB	#0F			;ADDITION
		DB	#E1			;GET_MEM_1
		DB	#01			;EXCHANGE
		DB	#C1			;ST_MEM_1
		DB	#02			;DELETE
		DB	#E0			;GET_MEM_0
		DB	#04			;MULTIPLY
		DB	#E2			;GET_MEM_2
		DB	#E5			;GET_MEM_5
		DB	#04			;MULTIPLY
		DB	#03			;SUBTRACT
		DB	#C2			;ST_MEM_2
		DB	#2A			;ABS
		DB	#E1			;GET_MEM_1
		DB	#2A			;ABS
		DB	#0F			;ADDITION
		DB	#02			;DELETE
		DB	#38			;END_CALC
		LD	A,(DE)
		CP	#81
		POP	BC
		JP	C,LINE_DRAW
		PUSH	BC
		RST	#28			;FP_CALC
		DB	#01			;EXCHANGE
		DB	#38			;END_CALC
		LD	A,(#5C7D)
		CALL	STACK_A
		RST	#28			;FP_CALC
		DB	#C0			;ST_MEM_0
		DB	#0F			;ADDITION
		DB	#01			;EXCHANGE
		DB	#38			;END_CALC
		LD	A,(#5C7E)
		CALL	STACK_A
		RST	#28			;FP_CALC
		DB	#C5			;ST_MEM_5
		DB	#0F			;ADDITION
		DB	#E0			;GET_MEM_0
		DB	#E5			;GET_MEM_5
		DB	#38			;END_CALC
		POP	BC
DRW_STEPS:	DEC	B
		JR	Z,ARC_END
		JR	ARC_START

ARC_LOOP:	RST	#28			;FP_CALC
		DB	#E1			;GET_MEM_1
		DB	#31			;DUPLICATE
		DB	#E3			;GET_MEM_3
		DB	#04			;MULTIPLY
		DB	#E2			;GET_MEM_2
		DB	#E4			;GET_MEM_4
		DB	#04			;MULTIPLY
		DB	#03			;SUBTRACT
		DB	#C1			;ST_MEM_1
		DB	#02			;DELETE
		DB	#E4			;GET_MEM_4
		DB	#04			;MULTIPLY
		DB	#E2			;GET_MEM_2
		DB	#E3			;GET_MEM_3
		DB	#04			;MULTIPLY
		DB	#0F			;ADDITION
		DB	#C2			;ST_MEM_2
		DB	#02			;DELETE
		DB	#38			;END_CALC
ARC_START:	PUSH	BC
		RST	#28			;FP_CALC
		DB	#C0			;ST_MEM_0
		DB	#02			;DELETE
		DB	#E1			;GET_MEM_1
		DB	#0F			;ADDITION
		DB	#31			;DUPLICATE
		DB	#38			;END_CALC
		LD	A,(#5C7D)
		CALL	STACK_A
		RST	#28			;FP_CALC
		DB	#03			;SUBTRACT
		DB	#E0			;GET_MEM_0
		DB	#E2			;GET_MEM_2
		DB	#0F			;ADDITION
		DB	#C0			;ST_MEM_0
		DB	#01			;EXCHANGE
		DB	#E0			;GET_MEM_0
		DB	#38			;END_CALC
		LD	A,(#5C7E)
		CALL	STACK_A
		RST	#28			;FP_CALC
		DB	#03			;SUBTRACT
		DB	#38			;END_CALC
		CALL	DRAW_LINE
		POP	BC
		DJNZ	ARC_LOOP
ARC_END:	RST	#28			;FP_CALC
		DB	#02			;DELETE
		DB	#02			;DELETE
		DB	#01			;EXCHANGE
		DB	#38			;END_CALC
		LD	A,(#5C7D)
		CALL	STACK_A
		RST	#28			;FP_CALC
		DB	#03			;SUBTRACT
		DB	#01			;EXCHANGE
		DB	#38			;END_CALC
		LD	A,(#5C7E)
		CALL	STACK_A
		RST	#28			;FP_CALC
		DB	#03			;SUBTRACT
		DB	#38			;END_CALC
LINE_DRAW:	CALL	DRAW_LINE
		JP	TEMPS

; Initial parameters
CD_PRMS1:	RST	#28			;FP_CALC
		DB	#31			;DUPLICATE
		DB	#28			;SQR
		DB	#34			;STK_DATA
		DB	#32			;EXPONENT
		DB	#00			;
		DB	#01			;EXCHANGE
		DB	#05			;DIVISION
		DB	#E5			;GET_MEM_5
		DB	#01			;EXCHANGE
		DB	#05			;DIVISION
		DB	#2A			;ABS
		DB	#38			;END_CALC
		CALL	FP_TO_A
		JR	C,USE_252
		AND	#FC
		ADD	A,#04
		JR	NC,DRAW_SAVE
USE_252:	LD	A,#FC
DRAW_SAVE:	PUSH	AF
		CALL	STACK_A
		RST	#28			;FP_CALC
		DB	#E5			;GET_MEM_5
		DB	#01			;EXCHANGE
		DB	#05			;DIVISION
		DB	#31			;DUPLICATE
		DB	#1F			;SIN
		DB	#C4			;ST_MEM_4
		DB	#02			;DELETE
		DB	#31			;DUPLICATE
		DB	#A2			;STK_HALF
		DB	#04			;MULTIPLY
		DB	#1F			;SIN
		DB	#C1			;ST_MEM_1
		DB	#01			;EXCHANGE
		DB	#C0			;ST_MEM_0
		DB	#02			;DELETE
		DB	#31			;DUPLICATE
		DB	#04			;MULTIPLY
		DB	#31			;DUPLICATE
		DB	#0F			;ADDITION
		DB	#A1			;STK_ONE
		DB	#03			;SUBTRACT
		DB	#1B			;NEGATE
		DB	#C3			;ST_MEM_3
		DB	#02			;DELETE
		DB	#38			;END_CALC
		POP	BC
		RET

; Line drawing
DRAW_LINE:	CALL	STK_TO_BC
		LD	A,C
		CP	B
		JR	NC,DL_X_GE_Y
		LD	L,C
		PUSH	DE
		XOR	A
		LD	E,A
		JR	DL_LARGER

DL_X_GE_Y:	OR	C
		RET	Z
		LD	L,B
		LD	B,C
		PUSH	DE
		LD	D,#00
DL_LARGER:	LD	H,B
		LD	A,B
		RRA
D_L_LOOP:	ADD	A,L
		JR	C,D_L_DIAG
		CP	H
		JR	C,D_L_HR_VT
D_L_DIAG:	SUB	H
		LD	C,A
		EXX
		POP	BC
		PUSH	BC
		JR	D_L_STEP

D_L_HR_VT:	LD	C,A
		PUSH	DE
		EXX
		POP	BC
D_L_STEP:	LD	HL,(#5C7D)
		LD	A,B
		ADD	A,H
		LD	B,A
		LD	A,C
		INC	A
		ADD	A,L
		JR	C,D_L_RANGE
		JR	Z,REPORT_BC
D_L_PLOT:	DEC	A
		LD	C,A
		CALL	PLOT_SUB
		EXX
		LD	A,C
		DJNZ	D_L_LOOP
		POP	DE
		RET

D_L_RANGE:	JR	Z,D_L_PLOT
REPORT_BC:	RST	#08			; Error report
		DB	#0A			; Integer out of range

; Scan expression or sub expression
SCANNING:	RST	#18
		LD	B,#00
		PUSH	BC
S_LOOP_1:	LD	C,A
		CALL	HEXA			; BSROM - hexadecimal numbers handling
		CALL	INDEXER
		LD	A,C
		JP	NC,S_ALPHNUM
		LD	B,#00
		LD	C,(HL)
		ADD	HL,BC
		JP	(HL)

S_QUOTE_S:	CALL	CH_ADD_1
		INC	BC
		CP	#0D
		JP	Z,REPORT_C
		CP	#22
		JR	NZ,S_QUOTE_S
		CALL	CH_ADD_1
		CP	#22
		RET

S_2_COORD:	RST	#20
		CP	#28
		JR	NZ,S_RPORT_C
		CALL	NEXT_2NUM
		RST	#18
		CP	#29
S_RPORT_C:	JP	NZ,REPORT_C

; Check syntax
SYNTAX_Z:	BIT	7,(IY+#01)
		RET

; Scanning SCREEN$
S_SCRN_S:	CALL	STK_TO_BC
		LD	HL,(#5C36)
		LD	DE,#0100
		ADD	HL,DE
		LD	A,C
		RRCA
		RRCA
		RRCA
		AND	#E0
		XOR	B
		LD	E,A
		LD	A,C
		AND	#18
		XOR	#40
		LD	D,A
		LD	B,#60
S_SCRN_LP:	PUSH	BC
		PUSH	DE
		PUSH	HL
		LD	A,(DE)
		XOR	(HL)
		JR	Z,S_SC_MTCH
		INC	A
		JR	NZ,S_SCR_NXT
		DEC	A
S_SC_MTCH:	LD	C,A
		LD	B,#07
S_SC_ROWS:	INC	D
		INC	HL
		LD	A,(DE)
		XOR	(HL)
		XOR	C
		JR	NZ,S_SCR_NXT
		DJNZ	S_SC_ROWS
		POP	BC
		POP	BC
		POP	BC
		LD	A,#80
		SUB	B
		LD	BC,#0001
		RST	#30
		LD	(DE),A
		JR	S_SCR_STO

S_SCR_NXT:	POP	HL
		LD	DE,#0008
		ADD	HL,DE
		POP	DE
		POP	BC
		DJNZ	S_SCRN_LP
		LD	C,B
S_SCR_STO:	RET				; BSROM - bugfix - don't store string after SCREEN$
		DB	#B2,#2A			; remains of JP STK_STO_D (#2AB2)

; Scanning attributes
S_ATTR_S:	CALL	STK_TO_BC
		LD	A,C
		RRCA
		RRCA
		RRCA
		LD	C,A
		AND	#E0
		XOR	B
		LD	L,A
		LD	A,C
		AND	#03
		XOR	#58
		LD	H,A
		LD	A,(HL)
		JP	STACK_A

; Scanning function table
SCAN_FUNC:	DB	#22, #1C		; S_QUOTE
		DB	#28, #4F		; S_BRACKET
		DB	#2E, #F2		; S_DECIMAL
		DB	#2B, #12		; S_U_PLUS
		DB	#A8, #56		; S_FN
		DB	#A5, #57		; S_RND
		DB	#A7, #84		; S_PI
		DB	#A6, #8F		; S_INKEY
		DB	#C4, #E6		; S_BIN
		DB	#AA, #BF		; S_SCREEN
		DB	#AB, #C7		; S_ATTR
		DB	#A9, #CE		; S_POINT
		DB	#00			; End marker

; Scanning function routines
S_U_PLUS:	RST	#20
		JP	S_LOOP_1

S_QUOTE:	RST	#18
		INC	HL
		PUSH	HL
		LD	BC,#0000
		CALL	S_QUOTE_S
		JR	NZ,S_Q_PRMS
S_Q_AGAIN:	CALL	S_QUOTE_S
		JR	Z,S_Q_AGAIN
		CALL	SYNTAX_Z
		JR	Z,S_Q_PRMS
		RST	#30
		POP	HL
		PUSH	DE
S_Q_COPY:	LD	A,(HL)
		INC	HL
		LD	(DE),A
		INC	DE
		CP	#22
		JR	NZ,S_Q_COPY
		LD	A,(HL)
		INC	HL
		CP	#22
		JR	Z,S_Q_COPY
S_Q_PRMS:	DEC	BC
		POP	DE
S_STRING:	LD	HL,#5C3B
		RES	6,(HL)
		BIT	7,(HL)
		CALL	NZ,STK_STO_D
		JP	S_CONT_2

S_BRACKET:	RST	#20
		CALL	SCANNING
		CP	#29
		JP	NZ,REPORT_C
		RST	#20
		JP	S_CONT_2

S_FN:		JP	S_FN_SBRN

S_RND:		CALL	SYNTAX_Z
		JR	Z,S_RND_END
		LD	BC,(#5C76)
		CALL	STACK_BC
		RST	#28			;FP_CALC
		DB	#A1			;STK_ONE
		DB	#0F			;ADDITION
		DB	#34			;STK_DATA
		DB	#37			;Exponent
		DB	#16			;
		DB	#04			;MULTIPLY
		DB	#34			;STK_DATA
		DB	#80			;
		DB	#41			;Exponent
		DB	#00			;
		DB	#00			;
		DB	#80			;
		DB	#32			;N_MOD_M
		DB	#02			;DELETE
		DB	#A1			;STK_ONE
		DB	#03			;SUBTRACT
		DB	#31			;DUPLICATE
		DB	#38			;END_CALC
		CALL	FP_TO_BC
		LD	(#5C76),BC
		LD	A,(HL)
		AND	A
		JR	Z,S_RND_END
		SUB	#10
		LD	(HL),A
S_RND_END:	JR	S_PI_END

S_PI:		CALL	SYNTAX_Z
		JR	Z,S_PI_END
		RST	#28			;FP_CALC
		DB	#A3			;STK_PI_2
		DB	#38			;END_CALC
		INC	(HL)
S_PI_END:	RST	#20
		JP	S_NUMERIC

S_INKEY:	LD	BC,#105A
		RST	#20
		CP	#23
		JP	Z,S_PUSH_PO
		LD	HL,#5C3B
		RES	6,(HL)
		BIT	7,(HL)
		JR	Z,S_INK_EN
		CALL	KEY_SCAN
		LD	C,#00
		JR	NZ,S_IK_STK
		CALL	K_TEST
		JR	NC,S_IK_STK
		DEC	D
		LD	E,A
		CALL	K_DECODE
		PUSH	AF
		LD	BC,#0001
		RST	#30
		POP	AF
		LD	(DE),A
		LD	C,#01
S_IK_STK:	LD	B,#00
		CALL	STK_STO_D
S_INK_EN:	JP	S_CONT_2

S_SCREEN:	CALL	S_2_COORD
		CALL	NZ,S_SCRN_S
		RST	#20
		JP	S_STRING

S_ATTR:		CALL	S_2_COORD
		CALL	NZ,S_ATTR_S
		RST	#20
		JR	S_NUMERIC

S_POINT:	CALL	S_2_COORD
		CALL	NZ,POINT_SUB
		RST	#20
		JR	S_NUMERIC

S_ALPHNUM:	CALL	ALPHANUM
		JR	NC,S_NEGATE
		CP	#41
		JR	NC,S_LETTER
S_DECIMAL:		
S_BIN:		CALL	SYNTAX_Z
		JR	NZ,S_STK_DEC
		CALL	DEC_TO_FP
S_BIN_1:	RST	#18
		LD	BC,#0006
		CALL	MAKE_ROOM
		INC	HL
		LD	(HL),#0E
		INC	HL
		EX	DE,HL
		LD	HL,(#5C65)
		LD	C,#05
		AND	A
		SBC	HL,BC
		LD	(#5C65),HL
		LDIR
		EX	DE,HL
		DEC	HL
		CALL	TEMP_PTR1
		JR	S_NUMERIC

S_STK_DEC:	RST	#18
S_SD_SKIP:	INC	HL
		LD	A,(HL)
		CP	#0E
		JR	NZ,S_SD_SKIP
		INC	HL
		CALL	STACK_NUM
		LD	(#5C5D),HL
S_NUMERIC:	SET	6,(IY+#01)
		JR	S_CONT_1

; Scanning variable routines
S_LETTER:	CALL	LOOK_VARS
		JP	C,REPORT_2
		CALL	Z,STK_VAR
		LD	A,(#5C3B)
		CP	#C0
		JR	C,S_CONT_1
		INC	HL
		CALL	STACK_NUM
S_CONT_1:	JR	S_CONT_2

S_NEGATE:	LD	BC,#09DB
		CP	#2D
		JR	Z,S_PUSH_PO
		LD	BC,#1018
		CP	#AE
		JR	Z,S_PUSH_PO
		SUB	#AF
		JP	C,REPORT_C
		LD	BC,#04F0
		CP	#14
		JR	Z,S_PUSH_PO
		JP	NC,REPORT_C
		LD	B,#10
		ADD	A,#DC
		LD	C,A
		CP	#DF
		JR	NC,S_NO_TO
		RES	6,C
S_NO_TO:	CP	#EE
		JR	C,S_PUSH_PO
		RES	7,C
S_PUSH_PO:	PUSH	BC
		RST	#20
		JP	S_LOOP_1

S_CONT_2:	RST	#18
S_CONT_3:	CP	#28
		JR	NZ,S_OPERTR
		BIT	6,(IY+#01)
		JR	NZ,S_LOOP
		CALL	SLICING
		RST	#20
		JR	S_CONT_3

S_OPERTR:	LD	B,#00
		LD	C,A
		LD	HL,TBL_OF_OPS
		CALL	INDEXER
		JR	NC,S_LOOP
		LD	C,(HL)
		LD	HL,#26ED
		ADD	HL,BC
		LD	B,(HL)

; Scanning main loop
S_LOOP:		POP	DE
		LD	A,D
		CP	B
		JR	C,S_TIGHTER
		AND	A
		JP	Z,GET_CHAR
		PUSH	BC
		LD	HL,#5C3B
		LD	A,E
		CP	#ED
		JR	NZ,S_STK_LST
		BIT	6,(HL)
		JR	NZ,S_STK_LST
		LD	E,#99
S_STK_LST:	PUSH	DE
		CALL	SYNTAX_Z
		JR	Z,S_SYNTEST
		LD	A,E
		AND	#3F
		LD	B,A
		RST	#28			;FP_CALC
		DB	#3B			;FP_CALC_2
		DB	#38			;END_CALC
		JR	S_RUNTEST

S_SYNTEST:	LD	A,E
		CALL	VAL1			; BSROM - enhanced VAL & VAL$
		AND	#40
S_RPORT_C2:	JP	NZ,REPORT_C
S_RUNTEST:	POP	DE
		LD	HL,#5C3B
		SET	6,(HL)
		BIT	7,E
		JR	NZ,S_LOOPEND
		RES	6,(HL)
S_LOOPEND:	POP	BC
		JR	S_LOOP

S_TIGHTER:	PUSH	DE
		LD	A,C
		BIT	6,(IY+#01)
		JR	NZ,S_NEXT
		AND	#3F
		ADD	A,#08
		LD	C,A
		CP	#10
		JR	NZ,S_NOT_AND
		SET	6,C
		JR	S_NEXT

S_NOT_AND:	JR	C,S_RPORT_C2
		CP	#17
		JR	Z,S_NEXT
		SET	7,C
S_NEXT:		PUSH	BC
		RST	#20
		JP	S_LOOP_1

; Table of operators
TBL_OF_OPS:	DB	"+", #CF		; ADDITION
		DB	"-", #C3		; SUBTRACT
		DB	"*", #C4		; MULTIPLY
		DB	"/", #C5		; DIVISION
		DB	"^", #C6		; TO_POWER
		DB	"=", #CE		; NOS_EQL
		DB	">", #CC		; NO_GRTR
		DB	"<", #CD		; NO_LESS
		DB	#C7, #C9		; NO_L_EQL '<='
		DB	#C8, #CA		; NO_GR_EQL '>='
		DB	#C9, #CB		; NOS_NEQL '<>'
		DB	#C5, #C7		; OR
		DB	#C6, #C8		; AND
		DB	#00			; End marker

; Table of priorities
TBL_PRIORS:	DB	#06			; '-'
		DB	#08			; '*'
		DB	#08			; '/'
		DB	#0A			; '^'
		DB	#02			; OR
		DB	#03			; AND
		DB	#05			; '<='
		DB	#05			; '>='
		DB	#05			; '<>'
		DB	#05			; '>'
		DB	#05			; '<'
		DB	#05			; '='
		DB	#06			; '+'

; User defined functions handling
S_FN_SBRN:	CALL	SYNTAX_Z
		JR	NZ,SF_RUN
		RST	#20
		CALL	ALPHA
		JP	NC,REPORT_C
		RST	#20
		CP	#24
		PUSH	AF
		JR	NZ,SF_BRKT_1
		RST	#20
SF_BRKT_1:	CP	#28
		JR	NZ,SF_RPRT_C
		RST	#20
		CP	#29
		JR	Z,SF_FLAG_6
SF_ARGMTS:	CALL	SCANNING
		RST	#18
		CP	#2C
		JR	NZ,SF_BRKT_2
		RST	#20
		JR	SF_ARGMTS

SF_BRKT_2:	CP	#29
SF_RPRT_C:	JP	NZ,REPORT_C
SF_FLAG_6:	RST	#20
		LD	HL,#5C3B
		RES	6,(HL)
		POP	AF
		JR	Z,SF_SYN_EN
		SET	6,(HL)
SF_SYN_EN	JP	S_CONT_2

SF_RUN:		RST	#20
		AND	#DF
		LD	B,A
		RST	#20
		SUB	#24
		LD	C,A
		JR	NZ,SF_ARGMT1
		RST	#20
SF_ARGMT1:	RST	#20
		PUSH	HL
		LD	HL,(#5C53)
		DEC	HL
SF_FND_DF:	LD	DE,#00CE
		PUSH	BC
		CALL	LOOK_PROG
		POP	BC
		JR	NC,SF_CP_DEF
REPORT_P:	RST	#08			; Error report
		DB	#18			; FN without DEF
SF_CP_DEF:	PUSH	HL
		CALL	FN_SKPOVR
		AND	#DF
		CP	B
		JR	NZ,SF_NOT_FD
		CALL	FN_SKPOVR
		SUB	#24
		CP	C
		JR	Z,SF_VALUES
SF_NOT_FD:	POP	HL
		DEC	HL
		LD	DE,#0200
		PUSH	BC
		CALL	EACH_STMT
		POP	BC
		JR	SF_FND_DF

SF_VALUES:	AND	A
		CALL	Z,FN_SKPOVR
		POP	DE
		POP	DE
		LD	(#5C5D),DE
		CALL	FN_SKPOVR
		PUSH	HL
		CP	#29
		JR	Z,SF_R_BR_2
SF_ARG_LP:	INC	HL
		LD	A,(HL)
		CP	#0E
		LD	D,#40
		JR	Z,SF_ARG_VR
		DEC	HL
		CALL	FN_SKPOVR
		INC	HL
		LD	D,#00
SF_ARG_VR:	INC	HL
		PUSH	HL
		PUSH	DE
		CALL	SCANNING
		POP	AF
		XOR	(IY+#01)
		AND	#40
		JR	NZ,REPORT_Q
		POP	HL
		EX	DE,HL
		LD	HL,(#5C65)
		LD	BC,#0005
		SBC	HL,BC
		LD	(#5C65),HL
		LDIR
		EX	DE,HL
		DEC	HL
		CALL	FN_SKPOVR
		CP	#29
		JR	Z,SF_R_BR_2
		PUSH	HL
		RST	#18
		CP	#2C
		JR	NZ,REPORT_Q
		RST	#20
		POP	HL
		CALL	FN_SKPOVR
		JR	SF_ARG_LP

SF_R_BR_2:	PUSH	HL
		RST	#18
		CP	#29
		JR	Z,SF_VALUE
REPORT_Q:	RST	#08			; Error report
		DB	#19			; Parameter error
SF_VALUE:	POP	DE
		EX	DE,HL
		LD	(#5C5D),HL
		LD	HL,(#5C0B)
		EX	(SP),HL
		LD	(#5C0B),HL
		PUSH	DE
		RST	#20
		RST	#20
		CALL	SCANNING
		POP	HL
		LD	(#5C5D),HL
		POP	HL
		LD	(#5C0B),HL
		RST	#20
		JP	S_CONT_2

; Skip spaces and color control codes in DEF FN
FN_SKPOVR:	INC	HL
		LD	A,(HL)
		CP	#21
		JR	C,FN_SKPOVR
		RET

; Variables lookup
LOOK_VARS:	SET	6,(IY+#01)
		RST	#18
		CALL	ALPHA
		JP	NC,REPORT_C
		PUSH	HL
		AND	#1F
		LD	C,A
		RST	#20
		PUSH	HL
		CP	#28
		JR	Z,V_RUN_SYN
		SET	6,C
		CP	#24
		JR	Z,V_STR_VAR
		SET	5,C
		CALL	ALPHANUM
		JR	NC,V_TEST_FN
V_CHAR:		CALL	ALPHANUM
		JR	NC,V_RUN_SYN
		RES	6,C
		RST	#20
		JR	V_CHAR

V_STR_VAR:	RST	#20
		RES	6,(IY+#01)
V_TEST_FN:	LD	A,(#5C0C)
		AND	A
		JR	Z,V_RUN_SYN
		CALL	SYNTAX_Z
		JP	NZ,STK_F_ARG
V_RUN_SYN:	LD	B,C
		CALL	SYNTAX_Z
		JR	NZ,V_RUN
		LD	A,C
		AND	#E0
		SET	7,A
		LD	C,A
		JR	V_SYNTAX

V_RUN:		LD	HL,(#5C4B)
V_EACH:		LD	A,(HL)
		AND	#7F
		JR	Z,V_80_BYTE
		CP	C
		JR	NZ,V_NEXT
		RLA
		ADD	A,A
		JP	P,V_FOUND_2
		JR	C,V_FOUND_2
		POP	DE
		PUSH	DE
		PUSH	HL
V_MATCHES:	INC	HL
V_SPACES:	LD	A,(DE)
		INC	DE
		CP	#20
		JR	Z,V_SPACES
		OR	#20
		CP	(HL)
		JR	Z,V_MATCHES
		OR	#80
		CP	(HL)
		JR	NZ,V_GET_PTR
		LD	A,(DE)
		CALL	ALPHANUM
		JR	NC,V_FOUND_1
V_GET_PTR:	POP	HL
V_NEXT:		PUSH	BC
		CALL	NEXT_ONE
		EX	DE,HL
		POP	BC
		JR	V_EACH

V_80_BYTE:	SET	7,B
V_SYNTAX:	POP	DE
		RST	#18
		CP	#28
		JR	Z,V_PASS
		SET	5,B
		JR	V_END

V_FOUND_1:	POP	DE
V_FOUND_2:	POP	DE
		POP	DE
		PUSH	HL
		RST	#18
V_PASS:		CALL	ALPHANUM
		JR	NC,V_END
		RST	#20
		JR	V_PASS

V_END:		POP	HL
		RL	B
		BIT	6,B
		RET

; Stack function argument
STK_F_ARG:	LD	HL,(#5C0B)
		LD	A,(HL)
		CP	#29
		JP	Z,V_RUN_SYN
SFA_LOOP:	LD	A,(HL)
		OR	#60
		LD	B,A
		INC	HL
		LD	A,(HL)
		CP	#0E
		JR	Z,SFA_CP_VR
		DEC	HL
		CALL	FN_SKPOVR
		INC	HL
		RES	5,B
SFA_CP_VR:	LD	A,B
		CP	C
		JR	Z,SFA_MATCH
		INC	HL
		INC	HL
		INC	HL
		INC	HL
		INC	HL
		CALL	FN_SKPOVR
		CP	#29
		JP	Z,V_RUN_SYN
		CALL	FN_SKPOVR
		JR	SFA_LOOP

SFA_MATCH:	BIT	5,C
		JR	NZ,SFA_END
		INC	HL
		LD	DE,(#5C65)
		CALL	MOVE_FP
		EX	DE,HL
		LD	(#5C65),HL
SFA_END:	POP	DE
		POP	DE
		XOR	A
		INC	A
		RET

; Stack variable component
STK_VAR:	XOR	A
		LD	B,A
		BIT	7,C
		JR	NZ,SV_COUNT
		BIT	7,(HL)
		JR	NZ,SV_ARRAYS
		INC	A
SV_SIMPLE:	INC	HL
		LD	C,(HL)
		INC	HL
		LD	B,(HL)
		INC	HL
		EX	DE,HL
		CALL	STK_STO_D
		RST	#18
		JP	SV_SLICE_EX

SV_ARRAYS:	INC	HL
		INC	HL
		INC	HL
		LD	B,(HL)
		BIT	6,C
		JR	Z,SV_PTR
		DEC	B
		JR	Z,SV_SIMPLE
		EX	DE,HL
		RST	#18
		CP	#28
		JR	NZ,REPORT_3
		EX	DE,HL
SV_PTR:		EX	DE,HL
		JR	SV_COUNT

SV_COMMA:	PUSH	HL
		RST	#18
		POP	HL
		CP	#2C
		JR	Z,SV_LOOP
		BIT	7,C
		JR	Z,REPORT_3
		BIT	6,C
		JR	NZ,SV_CLOSE
		CP	#29
		JR	NZ,SV_RPT_C
		RST	#20
		RET

SV_CLOSE:	CP	#29
		JR	Z,SV_DIM
		CP	#CC
		JR	NZ,SV_RPT_C
SV_CH_ADD:	RST	#18
		DEC	HL
		LD	(#5C5D),HL
		JR	SV_SLICE

SV_COUNT:	LD	HL,#0000
SV_LOOP:	PUSH	HL
		RST	#20
		POP	HL
		LD	A,C
		CP	#C0
		JR	NZ,SV_MULT
		RST	#18
		CP	#29
		JR	Z,SV_DIM
		CP	#CC
		JR	Z,SV_CH_ADD
SV_MULT:	PUSH	BC
		PUSH	HL
		CALL	DE_DE_1
		EX	(SP),HL
		EX	DE,HL
		CALL	INT_EXP1
		JR	C,REPORT_3
		DEC	BC
		CALL	GET_HL_DE
		ADD	HL,BC
		POP	DE
		POP	BC
		DJNZ	SV_COMMA
		BIT	7,C
SV_RPT_C:	JR	NZ,SL_RPT_C
		PUSH	HL
		BIT	6,C
		JR	NZ,SV_ELEM
		LD	B,D
		LD	C,E
		RST	#18
		CP	#29
		JR	Z,SV_NUMBER
REPORT_3:	RST	#08			; Error report
		DB	#02			; Subscript wrong
SV_NUMBER:	RST	#20
		POP	HL
		LD	DE,#0005
		CALL	GET_HL_DE
		ADD	HL,BC
		RET

SV_ELEM:	CALL	DE_DE_1
		EX	(SP),HL
		CALL	GET_HL_DE
		POP	BC
		ADD	HL,BC
		INC	HL
		LD	B,D
		LD	C,E
		EX	DE,HL
		CALL	STK_ST_0
		RST	#18
		CP	#29
		JR	Z,SV_DIM
		CP	#2C
		JR	NZ,REPORT_3
SV_SLICE:	CALL	SLICING
SV_DIM:		RST	#20
SV_SLICE_EX:	CP	#28
		JR	Z,SV_SLICE
		RES	6,(IY+#01)
		RET

; Handle slicing of strings
SLICING:	CALL	SYNTAX_Z
		CALL	NZ,STK_FETCH
		RST	#20
		CP	#29
		JR	Z,SL_STORE
		PUSH	DE
		XOR	A
		PUSH	AF
		PUSH	BC
		LD	DE,#0001
		RST	#18
		POP	HL
		CP	#CC
		JR	Z,SL_SECOND
		POP	AF
		CALL	INT_EXP2
		PUSH	AF
		LD	D,B
		LD	E,C
		PUSH	HL
		RST	#18
		POP	HL
		CP	#CC
		JR	Z,SL_SECOND
		CP	#29
SL_RPT_C:	JP	NZ,REPORT_C
		LD	H,D
		LD	L,E
		JR	SL_DEFINE

SL_SECOND:	PUSH	HL
		RST	#20
		POP	HL
		CP	#29
		JR	Z,SL_DEFINE
		POP	AF
		CALL	INT_EXP2
		PUSH	AF
		RST	#18
		LD	H,B
		LD	L,C
		CP	#29
		JR	NZ,SL_RPT_C
SL_DEFINE:	POP	AF
		EX	(SP),HL
		ADD	HL,DE
		DEC	HL
		EX	(SP),HL
		AND	A
		SBC	HL,DE
		LD	BC,#0000
		JR	C,SL_OVER
		INC	HL
		AND	A
		JP	M,REPORT_3
		LD	B,H
		LD	C,L
SL_OVER:	POP	DE
SL_OVER1:	RES	6,(IY+#01)
SL_STORE:	CALL	SYNTAX_Z
		RET	Z
STK_ST_0:	XOR	A
STK_STO_D:	RES	6,(IY+#01)
STK_STORE:	PUSH	BC			; Put five registers on the calc stack
		CALL	TEST_5_SP
		POP	BC
		LD	HL,(#5C65)
		LD	(HL),A
		INC	HL
		LD	(HL),E
		INC	HL
		LD	(HL),D
		INC	HL
		LD	(HL),C
		INC	HL
		LD	(HL),B
		INC	HL
		LD	(#5C65),HL
		RET

; Check and evaluate an integer expression
INT_EXP1:	XOR	A
INT_EXP2:	PUSH	DE
		PUSH	HL
		PUSH	AF
		CALL	EXPT_1NUM
		POP	AF
		CALL	SYNTAX_Z
		JR	Z,I_RESTORE
		PUSH	AF
		CALL	FIND_INT2
		POP	DE
		LD	A,B
		OR	C
		SCF
		JR	Z,I_CARRY
		POP	HL
		PUSH	HL
		AND	A
		SBC	HL,BC
I_CARRY:	LD	A,D
		SBC	A,#00
I_RESTORE:	POP	HL
		POP	DE
		RET

; Load DE+1 into DE
DE_DE_1:	EX	DE,HL
		INC	HL
		LD	E,(HL)
		INC	HL
		LD	D,(HL)
		RET

; Multiply HL by DE
GET_HL_DE:	CALL	SYNTAX_Z
		RET	Z
		CALL	HL_HL_DE
		JP	C,REPORT_4
		RET

; Handle LET command
LET:		LD	HL,(#5C4D)
		BIT	1,(IY+#37)
		JR	Z,L_EXISTS
		LD	BC,#0005
L_EACH_CH:	INC	BC
L_NO_SP:	INC	HL
		LD	A,(HL)
		CP	#20
		JR	Z,L_NO_SP
		JR	NC,L_TEST_CH
		CP	#10
		JR	C,L_SPACES
		CP	#16
		JR	NC,L_SPACES
		INC	HL
		JR	L_NO_SP

L_TEST_CH:	CALL	ALPHANUM
		JR	C,L_EACH_CH
		CP	#24
		JP	Z,L_NEW
L_SPACES:	LD	A,C
		LD	HL,(#5C59)
		DEC	HL
		CALL	MAKE_ROOM
		INC	HL
		INC	HL
		EX	DE,HL
		PUSH	DE
		LD	HL,(#5C4D)
		DEC	DE
		SUB	#06
		LD	B,A
		JR	Z,L_SINGLE
L_CHAR:		INC	HL
		LD	A,(HL)
		CP	#21
		JR	C,L_CHAR
		OR	#20
		INC	DE
		LD	(DE),A
		DJNZ	L_CHAR
		OR	#80
		LD	(DE),A
		LD	A,#C0
L_SINGLE:	LD	HL,(#5C4D)
		XOR	(HL)
		OR	#20
		POP	HL
		CALL	L_FIRST
L_NUMERIC:	PUSH	HL
		RST	#28			;FP_CALC
		DB	#02			;DELETE
		DB	#38			;END_CALC
		POP	HL
		LD	BC,#0005
		AND	A
		SBC	HL,BC
		JR	L_ENTER

L_EXISTS:	BIT	6,(IY+#01)
		JR	Z,L_DELETE
		LD	DE,#0006
		ADD	HL,DE
		JR	L_NUMERIC

L_DELETE:	LD	HL,(#5C4D)
		LD	BC,(#5C72)
		BIT	0,(IY+#37)
		JR	NZ,L_ADD
		LD	A,B
		OR	C
		RET	Z
		PUSH	HL
		RST	#30
		PUSH	DE
		PUSH	BC
		LD	D,H
		LD	E,L
		INC	HL
		LD	(HL),#20
		LDDR
		PUSH	HL
		CALL	STK_FETCH
		POP	HL
		EX	(SP),HL
		AND	A
		SBC	HL,BC
		ADD	HL,BC
		JR	NC,L_LENGTH
		LD	B,H
		LD	C,L
L_LENGTH:	EX	(SP),HL
		EX	DE,HL
		LD	A,B
		OR	C
		JR	Z,L_IN_W_S
		LDIR
L_IN_W_S:	POP	BC
		POP	DE
		POP	HL
L_ENTER:	EX	DE,HL
		LD	A,B
		OR	C
		RET	Z
		PUSH	DE
		LDIR
		POP	HL
		RET

L_ADD:		DEC	HL
		DEC	HL
		DEC	HL
		LD	A,(HL)
		PUSH	HL
		PUSH	BC
		CALL	L_STRING
		POP	BC
		POP	HL
		INC	BC
		INC	BC
		INC	BC
		JP	RECLAIM_2

L_NEW:		LD	A,#DF
		LD	HL,(#5C4D)
		AND	(HL)
L_STRING:	PUSH	AF
		CALL	STK_FETCH
		EX	DE,HL
		ADD	HL,BC
		PUSH	BC
		DEC	HL
		LD	(#5C4D),HL
		INC	BC
		INC	BC
		INC	BC
		LD	HL,(#5C59)
		DEC	HL
		CALL	MAKE_ROOM
		LD	HL,(#5C4D)
		POP	BC
		PUSH	BC
		INC	BC
		LDDR
		EX	DE,HL
		INC	HL
		POP	BC
		LD	(HL),B
		DEC	HL
		LD	(HL),C
		POP	AF
L_FIRST:	DEC	HL
		LD	(HL),A
		LD	HL,(#5C59)
		DEC	HL
		RET

; Get last value from the calc stack
STK_FETCH:	LD	HL,(#5C65)
		DEC	HL
		LD	B,(HL)
		DEC	HL
		LD	C,(HL)
		DEC	HL
		LD	D,(HL)
		DEC	HL
		LD	E,(HL)
		DEC	HL
		LD	A,(HL)
		LD	(#5C65),HL
		RET

; Handle DIM command
DIM:		CALL	LOOK_VARS
D_RPORT_C:	JP	NZ,REPORT_C
		CALL	SYNTAX_Z
		JR	NZ,D_RUN
		RES	6,C
		CALL	STK_VAR
		CALL	CHECK_END
D_RUN:		JR	C,D_LETTER
		PUSH	BC
		CALL	NEXT_ONE
		CALL	RECLAIM_2
		POP	BC
D_LETTER:	SET	7,C
		LD	B,#00
		PUSH	BC
		LD	HL,#0001
		BIT	6,C
		JR	NZ,D_SIZE
		LD	L,#05
D_SIZE:		EX	DE,HL
D_NO_LOOP:	RST	#20
		LD	H,#FF
		CALL	INT_EXP1
		JP	C,REPORT_3
		POP	HL
		PUSH	BC
		INC	H
		PUSH	HL
		LD	H,B
		LD	L,C
		CALL	GET_HL_DE
		EX	DE,HL
		RST	#18
		CP	#2C
		JR	Z,D_NO_LOOP
		CP	#29
		JR	NZ,D_RPORT_C
		RST	#20
		POP	BC
		LD	A,C
		LD	L,B
		LD	H,#00
		INC	HL
		INC	HL
		ADD	HL,HL
		ADD	HL,DE
		JP	C,REPORT_4
		PUSH	DE
		PUSH	BC
		PUSH	HL
		LD	B,H
		LD	C,L
		LD	HL,(#5C59)
		DEC	HL
		CALL	MAKE_ROOM
		INC	HL
		LD	(HL),A
		POP	BC
		DEC	BC
		DEC	BC
		DEC	BC
		INC	HL
		LD	(HL),C
		INC	HL
		LD	(HL),B
		POP	BC
		LD	A,B
		INC	HL
		LD	(HL),A
		LD	H,D
		LD	L,E
		DEC	DE
		LD	(HL),#00
		BIT	6,C
		JR	Z,DIM_CLEAR
		LD	(HL),#20
DIM_CLEAR:	POP	BC
		LDDR
DIM_SIZES:	POP	BC
		LD	(HL),B
		DEC	HL
		LD	(HL),C
		DEC	HL
		DEC	A
		JR	NZ,DIM_SIZES
		RET

; Check that the character in A is alphanumeric
ALPHANUM:	CALL	NUMERIC
		CCF
		RET	C
ALPHA:		CP	#41
		CCF
		RET	NC
		CP	#5B
		RET	C
		CP	#61
		CCF
		RET	NC
		CP	#7B
		RET

; Decimal to floating point
DEC_TO_FP:	CP	#C4
		JR	NZ,NOT_BIN
		LD	DE,#0000
BIN_DIGIT:	RST	#20
		SUB	#31
		ADC	A,#00
		JR	NZ,BIN_END
		EX	DE,HL
		CCF
		ADC	HL,HL
		JP	C,REPORT_6
		EX	DE,HL
		JR	BIN_DIGIT

BIN_END:	LD	B,D
		LD	C,E
		JP	STACK_BC

NOT_BIN:	CP	#2E
		JR	Z,DECIMAL
		CALL	INT_TO_FP
		CP	#2E
		JR	NZ,E_FORMAT
		RST	#20
		CALL	NUMERIC
		JR	C,E_FORMAT
		JR	DEC_STO_1

DECIMAL:	RST	#20
		CALL	NUMERIC
DEC_RPT_C:	JP	C,REPORT_C
		RST	#28			;FP_CALC
		DB	#A0			;STK_ZERO
		DB	#38			;END_CALC

DEC_STO_1:	RST	#28			;FP_CALC
		DB	#A1			;STK_ONE
		DB	#C0			;ST_MEM_0
		DB	#02			;DELETE
		DB	#38			;END_CALC

NXT_DGT_1:	RST	#18
		CALL	STK_DIGIT
		JR	C,E_FORMAT
		RST	#28			;FP_CALC
		DB	#E0			;GET_MEM_0
		DB	#A4			;STK_TEN
		DB	#05			;DIVISION
		DB	#C0			;ST_MEM_0
		DB	#04			;MULTIPLY
		DB	#0F			;ADDITION
		DB	#38			;END_CALC
		RST	#20
		JR	NXT_DGT_1

E_FORMAT:	CP	#45
		JR	Z,SIGN_FLAG
		CP	#65
		RET	NZ
SIGN_FLAG:	LD	B,#FF
		RST	#20
		CP	#2B
		JR	Z,SIGN_DONE
		CP	#2D
		JR	NZ,ST_E_PART
		INC	B
SIGN_DONE:	RST	#20
ST_E_PART:	CALL	NUMERIC
		JR	C,DEC_RPT_C
		PUSH	BC
		CALL	INT_TO_FP
		CALL	FP_TO_A
		POP	BC
		JP	C,REPORT_6
		AND	A
		JP	M,REPORT_6
		INC	B
		JR	Z,E_FP_JUMP
		NEG
E_FP_JUMP:	JP	E_TO_FP

; Check for valid digit
NUMERIC:	CP	#30
		RET	C
		CP	#3A
		CCF
		RET

; Stack digit
STK_DIGIT:	CALL	NUMERIC
		RET	C
		SUB	#30
STACK_A:	LD	C,A			;Stack accumulator
		LD	B,#00
STACK_BC:	LD	IY,#5C3A		;Stack BC register pair
		XOR	A
		LD	E,A
		LD	D,C
		LD	C,B
		LD	B,A
		CALL	STK_STORE
		RST	#28			;FP_CALC
		DB	#38			;END_CALC
		AND	A
		RET

; Integer to floating point
INT_TO_FP:	PUSH	AF
		RST	#28			;FP_CALC
		DB	#A0			;STK_ZERO
		DB	#38			;END_CALC
		POP	AF
NXT_DGT_2:	CALL	STK_DIGIT
		RET	C
		RST	#28			;FP_CALC
		DB	#01			;EXCHANGE
		DB	#A4			;STK_TEN
		DB	#04			;MULTIPLY
		DB	#0F			;ADDITION
		DB	#38			;END_CALC
		CALL	CH_ADD_1
		JR	NXT_DGT_2

; E-format to floating point
E_TO_FP:	RLCA
		RRCA
		JR	NC,E_SAVE
		CPL
		INC	A
E_SAVE:		PUSH	AF
		LD	HL,#5C92
		CALL	FP_0_1
		RST	#28			;FP_CALC
		DB	#A4			;STK_TEN
		DB	#38			;END_CALC
		POP	AF
E_LOOP:		SRL	A
		JR	NC,E_TST_END
		PUSH	AF
		RST	#28			;FP_CALC
		DB	#C1			;ST_MEM_1
		DB	#E0			;GET_MEM_0
		DB	#00			;JUMP_TRUE
		DB	#04			;to E_DIVSN
		DB	#04			;MULTIPLY
		DB	#33			;JUMP
		DB	#02			;to E_FETCH
E_DIVSN:	DB	#05			;DIVISION
E_FETCH:	DB	#E1			;GET_MEM_1
		DB	#38			;END_CALC
		POP	AF
E_TST_END:	JR	Z,E_END
		PUSH	AF
		RST	#28			;FP_CALC
		DB	#31			;DUPLICATE
		DB	#04			;MULTIPLY
		DB	#38			;END_CALC
		POP	AF
		JR	E_LOOP

E_END:		RST	#28			;FP_CALC
		DB	#02			;DELETE
		DB	#38			;END_CALC
		RET

; Fetch integer
INT_FETCH:	INC	HL
		LD	C,(HL)
		INC	HL
		LD	A,(HL)
		XOR	C
		SUB	C
		LD	E,A
		INC	HL
		LD	A,(HL)
		ADC	A,C
		XOR	C
		LD	D,A
		RET

; Store a positive integer. Not used in ROM.
P_INT_STO:	LD	C,#00

; Store an integer
INT_STORE:	PUSH	HL
		LD	(HL),#00
		INC	HL
		LD	(HL),C
		INC	HL
		LD	A,E
		XOR	C
		SUB	C
		LD	(HL),A
		INC	HL
		LD	A,D
		ADC	A,C
		XOR	C
		LD	(HL),A
		INC	HL
		LD	(HL),#00
		POP	HL
		RET

; Get floating point number from the calc stack to the BC
FP_TO_BC:	RST	#28			;FP_CALC
		DB	#38			;END_CALCS
		LD	A,(HL)
		AND	A
		JR	Z,FP_DELETE
		RST	#28			;FP_CALC
		DB	#A2			;STK_HALF
		DB	#0F			;ADDITION
		DB	#27			;INT
		DB	#38			;END_CALC

FP_DELETE:	RST	#28			;FP_CALC
		DB	#02			;DELETE
		DB	#38			;END_CALC
		PUSH	HL
		PUSH	DE
		EX	DE,HL
		LD	B,(HL)
		CALL	INT_FETCH
		XOR	A
		SUB	B
		BIT	7,C
		LD	B,D
		LD	C,E
		LD	A,E
		POP	DE
		POP	HL
		RET

LOG_2_A:	LD	D,A
		RLA
		SBC	A,A
		LD	E,A
		LD	C,A
		XOR	A
		LD	B,A
		CALL	STK_STORE
		RST	#28			;FP_CALC
		DB	#34			;STK_DATA
		DB	#EF			;Exponent
		DB	#1A			;
		DB	#20			;
		DB	#9A			;
		DB	#85			;
		DB	#04			;MULTIPLY
		DB	#27			;INT
		DB	#38			;END_CALC

; Floating point to A
FP_TO_A:	CALL	FP_TO_BC
		RET	C
		PUSH	AF
		DEC	B
		INC	B
		JR	Z,FP_A_END
		POP	AF
		SCF
		RET

FP_A_END:	POP	AF
		RET

; Print a floating point number
PRINT_FP:	RST	#28		;FP_CALC
		DB	#31		;DUPLICATE
		DB	#36		;LESS_0
		DB	#00		;JUMP_TRUE
		DB	#0B		;to PF_NEGTVE
		DB	#31		;DUPLICATE
		DB	#37		;GREATER_0
		DB	#00		;JUMP_TRUE
		DB	#0D		;to PS_POSTVE
		DB	#02		;DELETE
		DB	#38		;END_CALC
		LD	A,#30
		RST	#10
		RET

PF_NEGTVE:	DB	#2A		;ABS
		DB	#38		;END_CALC
		LD	A,#2D
		RST	#10
		RST	#28		;FP_CALC
PF_POSTVE:	DB	#A0		;STK_ZERO
		DB	#C3		;ST_MEM_3
		DB	#C4		;ST_MEM_4
		DB	#C5		;ST_MEM_5
		DB	#02		;DELETE
		DB	#38		;END_CALC
		EXX
		PUSH	HL
		EXX
PF_LOOP:	RST	#28		;FP_CALC
		DB	#31		;DUPLICATE
		DB	#27		;INT
		DB	#C2		;ST_MEM_2
		DB	#03		;SUBTRACT
		DB	#E2		;GET_MEM_2
		DB	#01		;EXCHANGE
		DB	#C2		;ST_MEM_2
		DB	#02		;DELETE
		DB	#38		;END_CALC
		LD	A,(HL)
		AND	A
		JR	NZ,PF_LARGE
		CALL	INT_FETCH
		LD	B,#10
		LD	A,D
		AND	A
		JR	NZ,PF_SAVE
		OR	E
		JR	Z,PF_SMALL
		LD	D,E
		LD	B,#08
PF_SAVE:	PUSH	DE
		EXX
		POP	DE
		EXX
		JR	PF_BITS

PF_SMALL:	RST	#28		;FP_CALC
		DB	#E2		;GET_MEM_2
		DB	#38		;END_CALC
		LD	A,(HL)
		SUB	#7E
		CALL	LOG_2_A
		LD	D,A
		LD	A,(#5CAC)
		SUB	D
		LD	(#5CAC),A
		LD	A,D
		CALL	E_TO_FP
		RST	#28		;FP_CALC
		DB	#31		;DUPLICATE
		DB	#27		;21
		DB	#C1		;ST_MEM_1
		DB	#03		;SUBTRACT
		DB	#E1		;GET_MEM_1
		DB	#38		;END_CALC
		CALL	FP_TO_A
		PUSH	HL
		LD	(#5CA1),A
		DEC	A
		RLA
		SBC	A,A
		INC	A
		LD	HL,#5CAB
		LD	(HL),A
		INC	HL
		ADD	A,(HL)
		LD	(HL),A
		POP	HL
		JP	PF_FRACTN

PF_LARGE:	SUB	#80
		CP	#1C
		JR	C,PF_MEDIUM
		CALL	LOG_2_A
		SUB	#07
		LD	B,A
		LD	HL,#5CAC
		ADD	A,(HL)
		LD	(HL),A
		LD	A,B
		NEG
		CALL	E_TO_FP
		JR	PF_LOOP

PF_MEDIUM:	EX	DE,HL
		CALL	FETCH_TWO
		EXX
		SET	7,D
		LD	A,L
		EXX
		SUB	#80
		LD	B,A
PF_BITS:	SLA	E
		RL	D
		EXX
		RL	E
		RL	D
		EXX
		LD	HL,#5CAA
		LD	C,#05
PF_BYTES:	LD	A,(HL)
		ADC	A,A
		DAA
		LD	(HL),A
		DEC	HL
		DEC	C
		JR	NZ,PF_BYTES
		DJNZ	PF_BITS
		XOR	A
		LD	HL,#5CA6
		LD	DE,#5CA1
		LD	B,#09
		RLD
		LD	C,#FF
PF_DIGITS:	RLD
		JR	NZ,PF_INSERT
		DEC	C
		INC	C
		JR	NZ,PF_TEST_2
PF_INSERT:	LD	(DE),A
		INC	DE
		INC	(IY+#71)
		INC	(IY+#72)
		LD	C,#00
PF_TEST_2:	BIT	0,B
		JR	Z,PF_ALL_9
		INC	HL
PF_ALL_9:	DJNZ	PF_DIGITS
		LD	A,(#5CAB)
		SUB	#09
		JR	C,PF_MORE
		DEC	(IY+#71)
		LD	A,#04
		CP	(IY+#6F)
		JR	PF_ROUND

PF_MORE:	RST	#28			;FP_CALC
		DB	#02			;DELETE
		DB	#E2			;GET_MEM_2
		DB	#38			;END_CALC

PF_FRACTN:	EX	DE,HL
		CALL	FETCH_TWO
		EXX
		LD	A,#80
		SUB	L
		LD	L,#00
		SET	7,D
		EXX
		CALL	SHIFT_FP
PF_FRN_LP:	LD	A,(IY+#71)
		CP	#08
		JR	C,PF_FR_DGT
		EXX
		RL	D
		EXX
		JR	PF_ROUND

PF_FR_DGT:	LD	BC,#0200
PF_FR_EXX:	LD	A,E
		CALL	CA_10_A_C
		LD	E,A
		LD	A,D
		CALL	CA_10_A_C
		LD	D,A
		PUSH	BC
		EXX
		POP	BC
		DJNZ	PF_FR_EXX
		LD	HL,#5CA1
		LD	A,C
		LD	C,(IY+#71)
		ADD	HL,BC
		LD	(HL),A
		INC	(IY+#71)
		JR	PF_FRN_LP

PF_ROUND:	PUSH	AF
		LD	HL,#5CA1
		LD	C,(IY+#71)
		LD	B,#00
		ADD	HL,BC
		LD	B,C
		POP	AF
PF_RND_LP:	DEC	HL
		LD	A,(HL)
		ADC	A,#00
		LD	(HL),A
		AND	A
		JR	Z,PF_R_BACK
		CP	#0A
		CCF
		JR	NC,PF_COUNT
PF_R_BACK:	DJNZ	PF_RND_LP
		LD	(HL),#01
		INC	B
		INC	(IY+#72)
PF_COUNT:	LD	(IY+#71),B
		RST	#28			;FP_CALC
		DB	#02			;DELETE
		DB	#38			;END_CALC
		EXX
		POP	HL
		EXX
		LD	BC,(#5CAB)
		LD	HL,#5CA1
		LD	A,B
		CP	#09
		JR	C,PF_NOT_E
		CP	#FC
		JR	C,PF_E_FRMT
PF_NOT_E:	AND	A
		CALL	Z,OUT_CODE
PF_E_SBRN:	XOR	A
		SUB	B
		JP	M,PF_OUT_LP
		LD	B,A
		JR	PF_DC_OUT

PF_OUT_LP:	LD	A,C
		AND	A
		JR	Z,PF_OUT_DT
		LD	A,(HL)
		INC	HL
		DEC	C
PF_OUT_DT:	CALL	OUT_CODE
		DJNZ	PF_OUT_LP
PF_DC_OUT:	LD	A,C
		AND	A
		RET	Z
		INC	B
		LD	A,#2E
PF_DEC_0:	RST	#10
		LD	A,#30
		DJNZ	PF_DEC_0
		LD	B,C
		JR	PF_OUT_LP

PF_E_FRMT:	LD	D,B
		DEC	D
		LD	B,#01
		CALL	PF_E_SBRN
		LD	A,#45
		RST	#10
		LD	C,D
		LD	A,C
		AND	A
		JP	P,PF_E_POS
		NEG
		LD	C,A
		LD	A,#2D
		JR	PF_E_SIGN

PF_E_POS:	LD	A,#2B
PF_E_SIGN:	RST	#10
		LD	B,#00
		JP	OUT_NUM_1

; Handle printing of floating point
CA_10_A_C:	PUSH	DE
		LD	L,A
		LD	H,#00
		LD	E,L
		LD	D,H
		ADD	HL,HL
		ADD	HL,HL
		ADD	HL,DE
		ADD	HL,HL
		LD	E,C
		ADD	HL,DE
		LD	C,H
		LD	A,L
		POP	DE
		RET

; Prepare the two numbers for addition
PREP_ADD:	LD	A,(HL)
		LD	(HL),#00
		AND	A
		RET	Z
		INC	HL
		BIT	7,(HL)
		SET	7,(HL)
		DEC	HL
		RET	Z
		PUSH	BC
		LD	BC,#0005
		ADD	HL,BC
		LD	B,C
		LD	C,A
		SCF
NEG_BYTE:	DEC	HL
		LD	A,(HL)
		CPL
		ADC	A,#00
		LD	(HL),A
		DJNZ	NEG_BYTE
		LD	A,C
		POP	BC
		RET

; Fetch two numbers
FETCH_TWO:	PUSH	HL
		PUSH	AF
		LD	C,(HL)
		INC	HL
		LD	B,(HL)
		LD	(HL),A
		INC	HL
		LD	A,C
		LD	C,(HL)
		PUSH	BC
		INC	HL
		LD	C,(HL)
		INC	HL
		LD	B,(HL)
		EX	DE,HL
		LD	D,A
		LD	E,(HL)
		PUSH	DE
		INC	HL
		LD	D,(HL)
		INC	HL
		LD	E,(HL)
		PUSH	DE
		EXX
		POP	DE
		POP	HL
		POP	BC
		EXX
		INC	HL
		LD	D,(HL)
		INC	HL
		LD	E,(HL)
		POP	AF
		POP	HL
		RET

; Shift floating point numer to right
SHIFT_FP:	AND	A
		RET	Z
		CP	#21
		JR	NC,ADDEND_0
		PUSH	BC
		LD	B,A
ONE_SHIFT:	EXX
		SRA	L
		RR	D
		RR	E
		EXX
		RR	D
		RR	E
		DJNZ	ONE_SHIFT
		POP	BC
		RET	NC
		CALL	ADD_BACK
		RET	NZ
ADDEND_0:	EXX
		XOR	A
ZEROS_4_5:	LD	L,#00
		LD	D,A
		LD	E,L
		EXX
		LD	DE,#0000
		RET

; Add back any carry
ADD_BACK:	INC	E
		RET	NZ
		INC	D
		RET	NZ
		EXX
		INC	E
		JR	NZ,ALL_ADDED
		INC	D
ALL_ADDED:	EXX
		RET

; Handle subtraction
SUBTRACT:	EX	DE,HL
		CALL	NEGATE
		EX	DE,HL

; Handle Addition
ADDITION:	LD	A,(DE)
		OR	(HL)
		JR	NZ,FULL_ADDN
		PUSH	DE
		INC	HL
		PUSH	HL
		INC	HL
		LD	E,(HL)
		INC	HL
		LD	D,(HL)
		INC	HL
		INC	HL
		INC	HL
		LD	A,(HL)
		INC	HL
		LD	C,(HL)
		INC	HL
		LD	B,(HL)
		POP	HL
		EX	DE,HL
		ADD	HL,BC
		EX	DE,HL
		ADC	A,(HL)
		RRCA
		ADC	A,#00
		CALL	E65536
		LD	(HL),A
		INC	HL
		LD	(HL),E
		INC	HL
		LD	(HL),D
		DEC	HL
		DEC	HL
		DEC	HL
		POP	DE
		RET

ADDN_OFLW:	DEC	HL
		POP	DE
FULL_ADDN:	CALL	RE_ST_TWO
		EXX
		PUSH	HL
		EXX
		PUSH	DE
		PUSH	HL
		CALL	PREP_ADD
		LD	B,A
		EX	DE,HL
		CALL	PREP_ADD
		LD	C,A
		CP	B
		JR	NC,SHIFT_LEN
		LD	A,B
		LD	B,C
		EX	DE,HL
SHIFT_LEN:	PUSH	AF
		SUB	B
		CALL	FETCH_TWO
		CALL	SHIFT_FP
		POP	AF
		POP	HL
		LD	(HL),A
		PUSH	HL
		LD	L,B
		LD	H,C
		ADD	HL,DE
		EXX
		EX	DE,HL
		ADC	HL,BC
		EX	DE,HL
		LD	A,H
		ADC	A,L
		LD	L,A
		RRA
		XOR	L
		EXX
		EX	DE,HL
		POP	HL
		RRA
		JR	NC,TEST_NEG
		LD	A,#01
		CALL	SHIFT_FP
		INC	(HL)
		JR	Z,ADD_REP_6
TEST_NEG:	EXX
		LD	A,L
		AND	#80
		EXX
		INC	HL
		LD	(HL),A
		DEC	HL
		JR	Z,GO_NC_MLT
		LD	A,E
		NEG
		CCF
		LD	E,A
		LD	A,D
		CPL
		ADC	A,#00
		LD	D,A
		EXX
		LD	A,E
		CPL
		ADC	A,#00
		LD	E,A
		LD	A,D
		CPL
		ADC	A,#00
		JR	NC,END_COMPL
		RRA
		EXX
		INC	(HL)
ADD_REP_6:	JP	Z,REPORT_6
		EXX
END_COMPL:	LD	D,A
		EXX
GO_NC_MLT:	XOR	A
		JP	TEST_NORM

; HL - HL * DE
HL_HL_DE:	PUSH	BC
		LD	B,#10
		LD	A,H
		LD	C,L
		LD	HL,#0000
HL_LOOP:	ADD	HL,HL
		JR	C,HL_END
		RL	C
		RLA
		JR	NC,HL_AGAIN
		ADD	HL,DE
		JR	C,HL_END
HL_AGAIN:	DJNZ	HL_LOOP
HL_END:		POP	BC
		RET

; Prepare to multiply or divide
PREP_M_D:	CALL	TEST_ZERO
		RET	C
		INC	HL
		XOR	(HL)
		SET	7,(HL)
		DEC	HL
		RET

; Handle multiplication
MULTIPLY:	LD	A,(DE)
		OR	(HL)
		JR	NZ,MULT_LONG
		PUSH	DE
		PUSH	HL
		PUSH	DE
		CALL	INT_FETCH
		EX	DE,HL
		EX	(SP),HL
		LD	B,C
		CALL	INT_FETCH
		LD	A,B
		XOR	C
		LD	C,A
		POP	HL
		CALL	HL_HL_DE
		EX	DE,HL
		POP	HL
		JR	C,MULT_OFLW
		LD	A,D
		OR	E
		JR	NZ,MULT_RSLT
		LD	C,A
MULT_RSLT:	CALL	INT_STORE
		POP	DE
		RET

MULT_OFLW:	POP	DE
MULT_LONG:	CALL	RE_ST_TWO
		XOR	A
		CALL	PREP_M_D
		RET	C
		EXX
		PUSH	HL
		EXX
		PUSH	DE
		EX	DE,HL
		CALL	PREP_M_D
		EX	DE,HL
		JR	C,ZERO_RSLT
		PUSH	HL
		CALL	FETCH_TWO
		LD	A,B
		AND	A
		SBC	HL,HL
		EXX
		PUSH	HL
		SBC	HL,HL
		EXX
		LD	B,#21
		JR	STRT_MLT

MLT_LOOP:	JR	NC,NO_ADD
		ADD	HL,DE
		EXX
		ADC	HL,DE
		EXX
NO_ADD:		EXX
		RR	H
		RR	L
		EXX
		RR	H
		RR	L
STRT_MLT:	EXX
		RR	B
		RR	C
		EXX
		RR	C
		RRA
		DJNZ	MLT_LOOP
		EX	DE,HL
		EXX
		EX	DE,HL
		EXX
		POP	BC
		POP	HL
		LD	A,B
		ADD	A,C
		JR	NZ,MAKE_EXPT
		AND	A
MAKE_EXPT:	DEC	A
		CCF
DIVN_EXPT:	RLA
		CCF
		RRA
		JP	P,OFLW1_CLR
		JR	NC,REPORT_6
		AND	A
OFLW1_CLR:	INC	A
		JR	NZ,OFLW2_CLR
		JR	C,OFLW2_CLR
		EXX
		BIT	7,D
		EXX
		JR	NZ,REPORT_6
OFLW2_CLR	LD	(HL),A
		EXX
		LD	A,B
		EXX
TEST_NORM:	JR	NC,NORMALISE
		LD	A,(HL)
		AND	A
NEAR_ZERO:	LD	A,#80
		JR	Z,SKIP_ZERO
ZERO_RSLT:	XOR	A
SKIP_ZERO:	EXX
		AND	D
		CALL	ZEROS_4_5
		RLCA
		LD	(HL),A
		JR	C,OFLOW_CLR
		INC	HL
		LD	(HL),A
		DEC	HL
		JR	OFLOW_CLR

NORMALISE:	LD	B,#20
SHIFT_ONE:	EXX
		BIT	7,D
		EXX
		JR	NZ,NORML_NOW
		RLCA
		RL	E
		RL	D
		EXX
		RL	E
		RL	D
		EXX
		DEC	(HL)
		JR	Z,NEAR_ZERO
		DJNZ	SHIFT_ONE
		JR	ZERO_RSLT

NORML_NOW:	RLA
		JR	NC,OFLOW_CLR
		CALL	ADD_BACK
		JR	NZ,OFLOW_CLR
		EXX
		LD	D,#80
		EXX
		INC	(HL)
		JR	Z,REPORT_6
OFLOW_CLR:	PUSH	HL
		INC	HL
		EXX
		PUSH	DE
		EXX
		POP	BC
		LD	A,B
		RLA
		RL	(HL)
		RRA
		LD	(HL),A
		INC	HL
		LD	(HL),C
		INC	HL
		LD	(HL),D
		INC	HL
		LD	(HL),E
		POP	HL
		POP	DE
		EXX
		POP	HL
		EXX
		RET

REPORT_6:	RST	#08			; Error report
		DB	#05			; Number too big

; Handle division
DIVISION:	CALL	RE_ST_TWO
		EX	DE,HL
		XOR	A
		CALL	PREP_M_D
		JR	C,REPORT_6
		EX	DE,HL
		CALL	PREP_M_D
		RET	C
		EXX
		PUSH	HL
		EXX
		PUSH	DE
		PUSH	HL
		CALL	FETCH_TWO
		EXX
		PUSH	HL
		LD	H,B
		LD	L,C
		EXX
		LD	H,C
		LD	L,B
		XOR	A
		LD	B,#DF
		JR	DIV_START

DIV_LOOP:	RLA
		RL	C
		EXX
		RL	C
		RL	B
		EXX
DIV_34TH:	ADD	HL,HL
		EXX
		ADC	HL,HL
		EXX
		JR	C,SUBN_ONLY
DIV_START:	SBC	HL,DE
		EXX
		SBC	HL,DE
		EXX
		JR	NC,NO_RSTORE
		ADD	HL,DE
		EXX
		ADC	HL,DE
		EXX
		AND	A
		JR	COUNT_ONE

SUBN_ONLY:	AND	A
		SBC	HL,DE
		EXX
		SBC	HL,DE
		EXX
NO_RSTORE:	SCF
COUNT_ONE:	INC	B
		JP	M,DIV_LOOP
		PUSH	AF
		JR	Z,DIV_34TH		; BSROM - bugfix - was DIV_START
		LD	E,A
		LD	D,C
		EXX
		LD	E,C
		LD	D,B
		POP	AF
		RR	B
		POP	AF
		RR	B
		EXX
		POP	BC
		POP	HL
		LD	A,B
		SUB	C
		JP	DIVN_EXPT

; Integer truncation towards zero
TRUNCATE:	LD	A,(HL)
		AND	A
		RET	Z
		CP	#81
		JR	NC,T_GR_ZERO		; BSROM - bugfixed INT
		LD	(HL),#00
		LD	A,#20
		JR	NIL_BYTES

E65536:		JR	NZ,S65536
		SBC	A,A
		LD	C,A
		INC	A
		OR	D
		OR	E
		LD	A,C
		RET	NZ
S65536:		POP	AF
		JP	ADDN_OFLW

NEW_CHR:	CALL	FP_TO_A			; BSROM - bugfixed CHR$
		RET	C
		RET	Z
		POP	AF
		LD	DE,#0001
		LD	BC,#FFFF
		JP	CHR_DLR1

T_GR_ZERO:	CP	#91			; BSROM - modified INT
T_SMALL:	JR	NC,X_LARGE
		PUSH	DE
		CPL
		ADD	A,#91
		INC	HL
		LD	D,(HL)
		INC	HL
		LD	E,(HL)
		DEC	HL
		DEC	HL
		LD	C,#00
		BIT	7,D
		JR	Z,T_NUMERIC
		DEC	C
T_NUMERIC:	SET	7,D
		LD	B,#08
		SUB	B
		ADD	A,B
		JR	C,T_TEST
		LD	E,D
		LD	D,#00
		SUB	B
T_TEST:		JR	Z,T_STORE
		LD	B,A
T_SHIFT:	SRL	D
		RR	E
		DJNZ	T_SHIFT
T_STORE:	CALL	INT_STORE
		POP	DE
		RET

T_EXPNENT:	LD	A,(HL)
X_LARGE:	SUB	#A0
		RET	P
		NEG
NIL_BYTES:	PUSH	DE
		EX	DE,HL
		DEC	HL
		LD	B,A
		SRL	B
		SRL	B
		SRL	B
		JR	Z,BITS_ZERO
BYTE_ZERO:	LD	(HL),#00
		DEC	HL
		DJNZ	BYTE_ZERO
BITS_ZERO:	AND	#07
		JR	Z,IX_END
		LD	B,A
		LD	A,#FF
LESS_MASK:	SLA	A
		DJNZ	LESS_MASK
		AND	(HL)
		LD	(HL),A
IX_END:		EX	DE,HL
		POP	DE
		RET

; Re-stack two numbers in full floating point
RE_ST_TWO:	CALL	RESTK_SUB
RESTK_SUB:	EX	DE,HL

; Re-stack number in full form
RE_STACK:	LD	A,(HL)
		AND	A
		RET	NZ
		PUSH	DE
		CALL	INT_FETCH
		XOR	A
		INC	HL
		LD	(HL),A
		DEC	HL
		LD	(HL),A
		LD	B,#91
		LD	A,D
		AND	A
		JR	NZ,RS_NRMLSE
		OR	E
		LD	B,D
		JR	Z,RS_STORE
		LD	D,E
		LD	E,B
		LD	B,#89
RS_NRMLSE:	EX	DE,HL
RSTK_LOOP:	DEC	B
		ADD	HL,HL
		JR	NC,RSTK_LOOP
		RRC	C
		RR	H
		RR	L
		EX	DE,HL
RS_STORE:	DEC	HL
		LD	(HL),E
		DEC	HL
		LD	(HL),D
		DEC	HL
		LD	(HL),B
		POP	DE
		RET

; Floating point calculator
; Table of constants
STK_ZERO:	DB	#00
		DB	#B0
		DB	#00

STK_ONE:	DB	#40
		DB	#B0
		DB	#00
		DB	#01

STK_HALF:	DB	#30
		DB	#00
	
STK_PI_2:	DB	#F1
		DB	#49
		DB	#0F
		DB	#DA
		DB	#A2
	
STK_TEN:	DB	#40
		DB	#B0
		DB	#00
		DB	#0A

; Floating point calculator
; Table of addresses
TBL_ADDRS:	DW	JUMP_TRUE
		DW	EXCHANGE
		DW	DELETE
		DW	SUBTRACT
		DW	MULTIPLY
		DW	DIVISION
		DW	TO_POWER
		DW	OR_FUNC
		DW	NO_AND_NO
		DW	NO_L_EQL
		DW	NO_GR_EQL
		DW	NOS_NEQL
		DW	NO_GRTR
		DW	NO_LESS
		DW	NOS_EQL
		DW	ADDITION
		DW	STR_AND_NO
		DW	STR_L_EQL
		DW	STR_GR_EQL
		DW	STRS_NEQL
		DW	STR_GRTR
		DW	STR_LESS
		DW	STRS_EQL
		DW	STRS_ADD
		DW	VAL_DLR
		DW	USR_STR
		DW	READ_IN
		DW	NEGATE
		DW	CODE
		DW	VAL
		DW	LEN
		DW	SIN_FUNC
		DW	COS_FUNC
		DW	TAN_FUNC
		DW	ASN_FUNC
		DW	ACS_FUNC
		DW	ATN_FUNC
		DW	LN
		DW	EXP
		DW	INT
		DW	SQR_FUNC
		DW	SGN
		DW	ABS
		DW	PEEK
		DW	IN_FUNC
		DW	USR_NO
		DW	STR_DLR
		DW	CHR_DLR
		DW	NOT_FUNC
		DW	DUPLICATE
		DW	N_MOD_M
		DW	JUMP
		DW	STK_DATA
		DW	DEC_JR_NZ
		DW	LESS_0
		DW	GREATER_0
		DW	END_CALC
		DW	GET_ARGT
		DW	TRUNCATE
		DW	FP_CALC_2
		DW	E_TO_FP
		DW	RE_STACK
		DW	SERIES_XX
		DW	STK_CONST_XX
		DW	ST_MEM_XX
		DW	GET_MEM_XX

; The Calculator
CALCULATE:	CALL	STK_PNTRS
GEN_ENT_1:	LD	A,B
		LD	(#5C67),A
GEN_ENT_2:	EXX
		EX	(SP),HL
		EXX
RE_ENTRY:	LD	(#5C65),DE
		EXX
		LD	A,(HL)
		INC	HL
SCAN_ENT:	PUSH	HL
		AND	A
		JP	P,FIRST_3D
		LD	D,A
		AND	#60
		RRCA
		RRCA
		RRCA
		RRCA
		ADD	A,#7C
		LD	L,A
		LD	A,D
		AND	#1F
		JR	ENT_TABLE

FIRST_3D:	CP	#18
		JR	NC,DOUBLE_A
		EXX
		LD	BC,#FFFB
		LD	D,H
		LD	E,L
		ADD	HL,BC
		EXX
DOUBLE_A:	RLCA
		LD	L,A
ENT_TABLE:	LD	DE,TBL_ADDRS
		LD	H,#00
		ADD	HL,DE
		LD	E,(HL)
		INC	HL
		LD	D,(HL)
		LD	HL,RE_ENTRY
		EX	(SP),HL
		PUSH	DE
		EXX
		LD	BC,(#5C66)

; Handle DELETE		
DELETE:		RET

; Single operation
FP_CALC_2:	POP	AF
		LD	A,(#5C67)
		EXX
		JR	SCAN_ENT

; Test that there is enough space between the calc stack and the machine stack
TEST_5_SP:	PUSH	DE
		PUSH	HL
		LD	BC,#0005
		CALL	TEST_ROOM
		POP	HL
		POP	DE
		RET

; Stack floating point number, numeric variable value or an entry in the BEEP's semi-tone table
STACK_NUM:	LD	DE,(#5C65)
		CALL	MOVE_FP
		LD	(#5C65),DE
		RET

; Move a floating point number
DUPLICATE:
MOVE_FP:	CALL	TEST_5_SP
		LDIR
		RET

; Stack literals
STK_DATA:	LD	H,D
		LD	L,E
STK_CONST:	CALL	TEST_5_SP
		EXX
		PUSH	HL
		EXX
		EX	(SP),HL
		PUSH	BC
		LD	A,(HL)
		AND	#C0
		RLCA
		RLCA
		LD	C,A
		INC	C
		LD	A,(HL)
		AND	#3F
		JR	NZ,FORM_EXP
		INC	HL
		LD	A,(HL)
FORM_EXP:	ADD	A,#50
		LD	(DE),A
		LD	A,#05
		SUB	C
		INC	HL
		INC	DE
		LD	B,#00
		LDIR
		POP	BC
		EX	(SP),HL
		EXX
		POP	HL
		EXX
		LD	B,A
		XOR	A
STK_ZEROS:	DEC	B
		RET	Z
		LD	(DE),A
		INC	DE
		JR	STK_ZEROS

; Skip constants
SKIP_CONS:	AND	A
SKIP_NEXT:	RET	Z
		PUSH	AF
		PUSH	DE
		CALL	NO_RW_AT0		; BSROM - fix for rewriting first bytes of ROM
		CALL	STK_CONST
		POP	DE
		POP	AF
		DEC	A
		JR	SKIP_NEXT

; Calculate memory location
LOC_MEM:	LD	C,A
		RLCA
		RLCA
		ADD	A,C
		LD	C,A
		LD	B,#00
		ADD	HL,BC
		RET

; Get from memory area
GET_MEM_XX:	PUSH	DE
		LD	HL,(#5C68)
		CALL	LOC_MEM
		CALL	MOVE_FP
		POP	HL
		RET

; Stack a constant
STK_CONST_XX:	LD	H,D
		LD	L,E
		EXX
		PUSH	HL
		LD	HL,STK_ZERO
		EXX
		CALL	SKIP_CONS
		CALL	STK_CONST
		EXX
		POP	HL
		EXX
		RET

; Store in a memory area
ST_MEM_XX:	PUSH	HL
		EX	DE,HL
		LD	HL,(#5C68)
		CALL	LOC_MEM
		EX	DE,HL
		CALL	MOVE_FP
		EX	DE,HL
		POP	HL
		RET

; Swap first number with second number
EXCHANGE:	LD	B,#05
SWAP_BYTE:	LD	A,(DE)
		LD	C,(HL)
		EX	DE,HL
		LD	(DE),A
		LD	(HL),C
		INC	HL
		INC	DE
		DJNZ	SWAP_BYTE
		EX	DE,HL
		RET

; Series generator
SERIES_XX:	LD	B,A
		CALL	GEN_ENT_1
		DB	#31			;DUPLICATE
		DB	#0F			;ADDITION
		DB	#C0			;ST_MEM_0
		DB	#02			;DELETE
		DB	#A0			;STK_ZERO
		DB	#C2			;ST_MEM_2
G_LOOP:		DB	#31			;DUPLICATE
		DB	#E0			;GET_MEM_0
		DB	#04			;MULTIPLY
		DB	#E2			;GET_MEM_2
		DB	#C1			;ST_MEM_1
		DB	#03			;SUBTRACT
		DB	#38			;END_CALC
		CALL	STK_DATA
		CALL	GEN_ENT_2
		DB	#0F			;ADDITION
		DB	#01			;EXCHANGE
		DB	#C2			;ST_MEM_2
		DB	#02			;DELETE
		DB	#35			;DEC_JR_NZ
		DB	#EE			;back to G_LOOP
		DB	#E1			;GET_MEM_1
		DB	#03			;SUBTRACT
		DB	#38			;END_CALC
		RET

; Find the absolute value of the last value, integer or floating point on the calc stack
ABS:		LD	B,#FF
		JR	NEG_TEST

; Handle unary minus
NEGATE:		CALL	TEST_ZERO
		RET	C
		LD	B,#00
NEG_TEST:	LD	A,(HL)
		AND	A
		JR	Z,INT_CASE
		INC	HL
		LD	A,B
		AND	#80
		OR	(HL)
		RLA
		CCF
		RRA
		LD	(HL),A
		DEC	HL
		RET

INT_CASE:	PUSH	DE
		PUSH	HL
		CALL	INT_FETCH
		POP	HL
		LD	A,B
		OR	C
		CPL
		LD	C,A
		CALL	INT_STORE
		POP	DE
		RET

; Signum
SGN:		CALL	TEST_ZERO
		RET	C
		PUSH	DE
		LD	DE,#0001
		INC	HL
		RL	(HL)
		DEC	HL
		SBC	A,A
		LD	C,A
		CALL	INT_STORE
		POP	DE
		RET

; Handle IN function
IN_FUNC:	CALL	FIND_INT2
		IN	A,(C)
		JR	IN_PK_STK

; Handle PEEK function
PEEK:		CALL	FIND_INT2
		LD	A,(BC)
IN_PK_STK:	JP	STACK_A

; Handle USR number
USR_NO:		CALL	FIND_INT2
		LD	HL,STACK_BC
		PUSH	HL
		PUSH	BC
		RET

; Handle USR string
USR_STR:	CALL	STK_FETCH
		DEC	BC
		LD	A,B
		OR	C
		JR	NZ,REPORT_A
		LD	A,(DE)
		CALL	ALPHA
		JR	C,USR_RANGE
		SUB	#90
		JR	C,REPORT_A
		CP	#15
		JR	NC,REPORT_A
		INC	A
USR_RANGE:	DEC	A
		ADD	A,A
		ADD	A,A
		ADD	A,A
		CP	#A8
		JR	NC,REPORT_A
		LD	BC,(#5C7B)
		ADD	A,C
		LD	C,A
		JR	NC,USR_STACK
		INC	B
USR_STACK:	JP	STACK_BC

REPORT_A:	RST	#08			; Error report
		DB	#09			; Invalid argument

; Test if top value on calc stack is zero
TEST_ZERO:	PUSH	HL
		PUSH	BC
		LD	B,A
		LD	A,(HL)
		INC	HL
		OR	(HL)
		INC	HL
		OR	(HL)
		INC	HL
		OR	(HL)
		LD	A,B
		POP	BC
		POP	HL
		RET	NZ
		SCF
		RET

; Test if the last value on calc stack is greater than zero
GREATER_0:	CALL	TEST_ZERO
		RET	C
		LD	A,#FF
		JR	SIGN_TO_C

; Handle NOT operator
NOT_FUNC:	CALL	TEST_ZERO
		JR	FP_0_1

; Test if the last value on calc stack is less than zero
LESS_0:		XOR	A
SIGN_TO_C:	INC	HL
		XOR	(HL)
		DEC	HL
		RLCA

; Place an iteger value zero or one at the calc stack or memory area
FP_0_1:		PUSH	HL
		LD	A,#00
		LD	(HL),A
		INC	HL
		LD	(HL),A
		INC	HL
		RLA
		LD	(HL),A
		RRA
		INC	HL
		LD	(HL),A
		INC	HL
		LD	(HL),A
		POP	HL
		RET

; Handle OR operator
OR_FUNC:	EX	DE,HL
		CALL	TEST_ZERO
		EX	DE,HL
		RET	C
		SCF
		JR	FP_0_1

; Handle number AND number
NO_AND_NO:	EX	DE,HL
		CALL	TEST_ZERO
		EX	DE,HL
		RET	NC
		AND	A
		JR	FP_0_1

; Handle string AND number
STR_AND_NO:	EX	DE,HL
		CALL	TEST_ZERO
		EX	DE,HL
		RET	NC
		PUSH	DE
		DEC	DE
		XOR	A
		LD	(DE),A
		DEC	DE
		LD	(DE),A
		POP	DE
		RET

; Perform numeric or string comparison
NO_L_EQL:
NO_GR_EQL:
NOS_NEQL:
NO_GRTR:
NO_LESS:
NOS_EQL:
STR_L_EQL:
STR_GR_EQL:
STRS_NEQL:
STR_GRTR:
STR_LESS:
STRS_EQL:	LD	A,B
		SUB	#08
		BIT	2,A
		JR	NZ,EX_OR_NOT
		DEC	A
EX_OR_NOT:	RRCA
		JR	NC,NU_OR_STR
		PUSH	AF
		PUSH	HL
		CALL	EXCHANGE
		POP	DE
		EX	DE,HL
		POP	AF
NU_OR_STR:	BIT	2,A
		JR	NZ,STRINGS
		RRCA
		PUSH	AF
		CALL	SUBTRACT
		JR	END_TESTS

STRINGS:	RRCA
		PUSH	AF
		CALL	STK_FETCH
		PUSH	DE
		PUSH	BC
		CALL	STK_FETCH
		POP	HL
BYTE_COMP:	LD	A,H
		OR	L
		EX	(SP),HL
		LD	A,B
		JR	NZ,SEC_PLUS
		OR	C
SECND_LOW:	POP	BC
		JR	Z,BOTH_NULL
		POP	AF
		CCF
		JR	STR_TEST

BOTH_NULL:	POP	AF
		JR	STR_TEST

SEC_PLUS:	OR	C
		JR	Z,FRST_LESS
		LD	A,(DE)
		SUB	(HL)
		JR	C,FRST_LESS
		JR	NZ,SECND_LOW
		DEC	BC
		INC	DE
		INC	HL
		EX	(SP),HL
		DEC	HL
		JR	BYTE_COMP

FRST_LESS:	POP	BC
		POP	AF
		AND	A
STR_TEST:	PUSH	AF
		RST	#28			;FP_CALC
		DB	#A0			;STK_ZERO
		DB	#38			;END_CALC

END_TESTS:	POP	AF
		PUSH	AF
		CALL	C,NOT_FUNC
		POP	AF
		PUSH	AF
		CALL	NC,GREATER_0
		POP	AF
		RRCA
		CALL	NC,NOT_FUNC
		RET

; Combine two strings into one
STRS_ADD:	CALL	STK_FETCH
		PUSH	DE
		PUSH	BC
		CALL	STK_FETCH
		POP	HL
		PUSH	HL
		PUSH	DE
		PUSH	BC
		ADD	HL,BC
		LD	B,H
		LD	C,L
		RST	#30
		CALL	STK_STO_D
		POP	BC
		POP	HL
		LD	A,B
		OR	C
		JR	Z,OTHER_STR
		LDIR
OTHER_STR:	POP	BC
		POP	HL
		LD	A,B
		OR	C
		JR	Z,STK_PNTRS
		LDIR

; Check stack pointers
STK_PNTRS:	LD	HL,(#5C65)
		LD	DE,#FFFB
		PUSH	HL
		ADD	HL,DE
		POP	DE
		RET

; Handle CHR$
CHR_DLR:	CALL	NEW_CHR			;BSROM - bugfixed CHR$
		JR	C,REPORT_BD
		JR	NZ,REPORT_BD
		PUSH	AF
		LD	BC,#0001
		RST	#30
		POP	AF
		LD	(DE),A
CHR_DLR1:	CALL	STK_STO_D
		EX	DE,HL
		RET

REPORT_BD:	RST	#08			; Error report
		DB	#0A			; Integer out of range

; Handle VAL and VAL$
VAL:
VAL_DLR:	CALL	VAL2			; BSROM - enhanced VAL & VAL$
		PUSH	HL
		LD	A,B
		ADD	A,#E3
		SBC	A,A
		PUSH	AF
		CALL	STK_FETCH
		PUSH	DE
		INC	BC
		RST	#30
		POP	HL
		LD	(#5C5D),DE
		PUSH	DE
		LDIR
		EX	DE,HL
		DEC	HL
		LD	(HL),#0D
		RES	7,(IY+#01)
		CALL	SCANNING
		RST	#18
		CP	#0D
		JR	NZ,V_RPORT_C
		POP	HL
		POP	AF
		XOR	(IY+#01)
		AND	#40
V_RPORT_C:	JP	NZ,REPORT_C
		LD	(#5C5D),HL
		SET	7,(IY+#01)
		CALL	SCANNING
		POP	HL
		LD	(#5C5D),HL
		JR	STK_PNTRS

; Handle STR$
STR_DLR:	LD	BC,#0001
		RST	#30
		LD	(#5C5B),HL
		PUSH	HL
		LD	HL,(#5C51)
		PUSH	HL
		LD	A,#FF
		CALL	CHAN_OPEN
		CALL	PRINT_FP
		POP	HL
		CALL	CHAN_FLAG
		POP	DE
		LD	HL,(#5C5B)
		AND	A
		SBC	HL,DE
		LD	B,H
		LD	C,L
		CALL	STK_STO_D
		EX	DE,HL
		RET

; Read in for INKEY$
READ_IN:	CALL	FIND_INT1
		CP	#10
		JP	NC,REPORT_BB
		LD	HL,(#5C51)
		PUSH	HL
		CALL	CHAN_OPEN
		CALL	INPUT_AD
		LD	BC,#0000
		JR	NC,R_I_STORE
		INC	C
		RST	#30
		LD	(DE),A
R_I_STORE:	CALL	STK_STO_D
		POP	HL
		CALL	CHAN_FLAG
		JP	STK_PNTRS

; Handle CODE
CODE:		CALL	STK_FETCH
		LD	A,B
		OR	C
		JR	Z,STK_CODE
		LD	A,(DE)
STK_CODE	JP	STACK_A

; Handle LEN
LEN:		CALL	STK_FETCH
		JP	STACK_BC

; Decrease the counter
DEC_JR_NZ:	EXX
		PUSH	HL
		LD	HL,#5C67
		DEC	(HL)
		POP	HL
		JR	NZ,JUMP_2
		INC	HL
		EXX
		RET

; Relative jump
JUMP:		EXX
JUMP_2:		LD	E,(HL)
		LD	A,E
		RLA
		SBC	A,A
		LD	D,A
		ADD	HL,DE
		EXX
		RET

; Jump on true
JUMP_TRUE:	INC	DE
		INC	DE
		LD	A,(DE)
		DEC	DE
		DEC	DE
		AND	A
		JR	NZ,JUMP
		EXX
		INC	HL
		EXX
		RET

; End of calculation
END_CALC:	POP	AF
		EXX
		EX	(SP),HL
		EXX
		RET

; Modulus
N_MOD_M:	RST	#28			;FP_CALC
		DB	#C0			;ST_MEM_0
		DB	#02			;DELETE
		DB	#31			;DUPLICATE
		DB	#E0			;GET_MEM_0
		DB	#05			;DIVISION
		DB	#27			;INT
		DB	#E0			;GET_MEM_0
		DB	#01			;EXCHANGE
		DB	#C0			;ST_MEM_0
		DB	#04			;MULTIPLY
		DB	#03			;SUBTRACT
		DB	#E0			;GET_MEM_0
		DB	#38			;END_CALC
		RET

; Handle INT
INT:		RST	#28			;FP_CALC
		DB	#31			;DUPLICATE
		DB	#36			;LESS_0
		DB	#00			;JUMP_TRUE
		DB	#04			;to X_NEG
		DB	#3A			;TRUNCATE
		DB	#38			;END_CALC
		RET

X_NEG:		DB	#31			;DUPLICATE
		DB	#3A			;TRUNCATE
		DB	#C0			;ST_MEM_0
		DB	#03			;SUBTRACT
		DB	#E0			;GET_MEM_0
		DB	#01			;EXCHANGE
		DB	#30			;NOT
		DB	#00			;JUMP_TRUE
		DB	#03			;to EXIT
		DB	#A1			;STK_ONE
		DB	#03			;SUBTRACT
EXIT:		DB	#38			;END_CALC
		RET

; Exponential
EXP:		RST	#28			;FP_CALC
		DB	#3D			;RE_STACK
		DB	#34			;STK_DATA
		DB	#F1			;Exponent
		DB	#38			;
		DB	#AA			;
		DB	#3B			;
		DB	#29			;
		DB	#04			;MULTIPLY
		DB	#31			;DUPLICATE
		DB	#27			;INT
		DB	#C3			;ST_MEM_3
		DB	#03			;SUBTRACT
		DB	#31			;DUPLICATE
		DB	#0F			;ADDITION
		DB	#A1			;STK_ONE
		DB	#03			;SUBTRACT
		DB	#88			;SERIES_08
		DB	#13			;Exponent
		DB	#36			;
		DB	#58			;Exponent
		DB	#65			;
		DB	#66			;
		DB	#9D			;Exponent
		DB	#78			;
		DB	#65			;
		DB	#40			;
		DB	#A2			;Exponent
		DB	#60			;
		DB	#32			;
		DB	#C9			;
		DB	#E7			;Exponent
		DB	#21			;
		DB	#F7			;
		DB	#AF			;
		DB	#24			;
		DB	#EB			;Exponent
		DB	#2F			;
		DB	#B0			;
		DB	#B0			;
		DB	#14			;
		DB	#EE			;Exponent
		DB	#7E			;
		DB	#BB			;
		DB	#94			;
		DB	#58			;
		DB	#F1			;Exponent
		DB	#3A			;
		DB	#7E			;
		DB	#F8			;
		DB	#CF			;
		DB	#E3			;GET_MEM_3
		DB	#38			;END-CALC
		CALL	FP_TO_A
		JR	NZ,N_NEGTV
		JR	C,REPORT_6B
		ADD	A,(HL)
		JR	NC,RESULT_OK
REPORT_6B:	RST	#08			; Error report
		DB	#05			; Number too big

N_NEGTV:	JR	C,RSLT_ZERO
		SUB	(HL)
		JR	NC,RSLT_ZERO
		NEG
RESULT_OK:	LD	(HL),A
		RET

RSLT_ZERO:	RST	#28			;FP_CALC
		DB	#02			;DELETE
		DB	#A0			;STK_ZERO
		DB	#38			;END_CALC
		RET

; Natural logarithm
LN:		RST	#28			;FP_CALC
		DB	#3D			;RE_STACK
		DB	#31			;DUPLICATE
		DB	#37			;GREATER_0
		DB	#00			;JUMP_TRUE
		DB	#04			;to VALID
		DB	#38			;END_CALC

REPORT_AB:	RST	#08			; Error report
		DB	#09			; Invalid argument

VALID:		DB	#A0			;STK_ZERO
		DB	#02			;DELETE
		DB	#38			;END_CALC
		LD	A,(HL)
		LD	(HL),#80
		CALL	STACK_A
		RST	#28			;FP_CALC
		DB	#34			;STK_DATA
		DB	#38			;Exponent
		DB	#00			;
		DB	#03			;SUBTRACT
		DB	#01			;EXCHANGE
		DB	#31			;DUPLICATE
		DB	#34			;STK_DATA
		DB	#F0			;Exponent
		DB	#4C			;
		DB	#CC			;
		DB	#CC			;
		DB	#CD			;
		DB	#03			;SUBTRACT
		DB	#37			;GREATER_0
		DB	#00			;JUMP_TURE
		DB	#08			;to GRE_8
		DB	#01			;EXCHANGE
		DB	#A1			;STK_ONE
		DB	#03			;SUBTRACT
		DB	#01			;EXCHANGE
		DB	#38			;END_CALC
		INC	(HL)
		RST	#28			;FP_CALC
GRE_8:		DB	#01			;EXCHANGE
		DB	#34			;STK_DATA
		DB	#F0			;Exponent
		DB	#31			;
		DB	#72			;
		DB	#17			;
		DB	#F8			;
		DB	#04			;MULTIPLY
		DB	#01			;EXCHANGE
		DB	#A2			;STK_HALF
		DB	#03			;SUBTRACT
		DB	#A2			;STK_HALF
		DB	#03			;SUBTRACT
		DB	#31			;DUPLICATE
		DB	#34			;STK_DATA
		DB	#32			;Exponent
		DB	#20			;
		DB	#04			;MULTIPLY
		DB	#A2			;STK_HALF
		DB	#03			;SUBTRACT
		DB	#8C			;SERIES_0C
		DB	#11			;Exponent
		DB	#AC			;
		DB	#14			;Exponent
		DB	#09			;
		DB	#56			;Exponent
		DB	#DA			;
		DB	#A5			;
		DB	#59			;Exponent
		DB	#30			;
		DB	#C5			;
		DB	#5C			;Exponent
		DB	#90			;
		DB	#AA			;
		DB	#9E			;Exponent
		DB	#70			;
		DB	#6F			;
		DB	#61			;
		DB	#A1			;Exponent
		DB	#CB			;
		DB	#DA			;
		DB	#96			;
		DB	#A4			;Exponent
		DB	#31			;
		DB	#9F			;
		DB	#B4			;
		DB	#E7			;Exponent
		DB	#A0			;
		DB	#FE			;
		DB	#5C			;
		DB	#FC			;
		DB	#EA			;Exponent
		DB	#1B			;
		DB	#43			;
		DB	#CA			;
		DB	#36			;
		DB	#ED			;Exponent
		DB	#A7			;	
		DB	#9C			;
		DB	#7E			;
		DB	#5E			;
		DB	#F0			;Exponent
		DB	#6E			;
		DB	#23			;
		DB	#80			;
		DB	#93			;
		DB	#04			;MULTIPLY
		DB	#0F			;ADDITION
		DB	#38			;END_CALC
		RET

; Reduce argument
GET_ARGT:	RST	#28			;FP_CALC
		DB	#3D			;RE_STACK
		DB	#34			;STK_DATA
		DB	#EE			;Exponent
		DB	#22			;
		DB	#F9			;
		DB	#83			;
		DB	#6E			;
		DB	#04			;MULTIPLY
		DB	#31			;DUPLICATE
		DB	#A2			;STK_HALF
		DB	#0F			;ADDITION
		DB	#27			;INT
		DB	#03			;SUBTRACT
		DB	#31			;DUPLICATE
		DB	#0F			;ADDITION
		DB	#31			;DUPLICATE
		DB	#0F			;ADDITION
		DB	#31			;DUPLICATE
		DB	#2A			;ABS
		DB	#A1			;STK_ONE
		DB	#03			;SUBTRACT
		DB	#31			;DUPLICATE
		DB	#37			;GREATER_0
		DB	#C0			;ST-MEM-0
		DB	#00			;JUMP_TRUE
		DB	#04			;to ZPLUS
		DB	#02			;DELETE
		DB	#38			;END_CALC
		RET

ZPLUS:		DB	#A1			;STK_ONE
		DB	#03			;SUBTRACT
		DB	#01			;EXCHANGE
		DB	#36			;LESS_0
		DB	#00			;JUMP_TRUE
		DB	#02			;to YNEG
		DB	#1B			;NEGATE
YNEG:		DB	#38			;END_CALC
		RET

; Handle cosine
COS_FUNC:	RST	#28			;FP_CALC
		DB	#39			;GET_ARGT
		DB	#2A			;ABS
		DB	#A1			;STK_ONE
		DB	#03			;SUBTRACT
		DB	#E0			;GET-MEM-0
		DB	#00			;JUMP_TRUE
		DB	#06			;fwd to C_ENT
		DB	#1B			;NEGATE
		DB	#33			;jump
		DB	#03			;fwd to C_ENT

; Handle sine
SIN_FUNC:	RST	#28			;FP_CALC
		DB	#39			;GET_ARGT
C_ENT:		DB	#31			;DUPLICATE
		DB	#31			;DUPLICATE
		DB	#04			;MULTIPLY
		DB	#31			;DUPLICATE
		DB	#0F			;ADDITION
		DB	#A1			;STK_ONE
		DB	#03			;SUBTRACT
		DB	#86			;SERIES-06
		DB	#14			;Exponent			
		DB	#E6			;
		DB	#5C			;Exponent
		DB	#1F			;
		DB	#0B			;
		DB	#A3			;Exponent
		DB	#8F			;
		DB	#38			;
		DB	#EE			;
		DB	#E9			;Exponent
		DB	#15			;
		DB	#63			;
		DB	#BB			;
		DB	#23			;
		DB	#EE			;Exponent
		DB	#92			;
		DB	#0D			;
		DB	#CD			;
		DB	#ED			;
		DB	#F1			;Exponent
		DB	#23			;
		DB	#5D			;
		DB	#1B			;
		DB	#EA			;
		DB	#04			;MULTIPLY
		DB	#38			;END_CALC
		RET

; Handle tangent
TAN_FUNC:	RST	#28			;FP_CALC
		DB	#31			;DUPLICATE
		DB	#1F			;SIN
		DB	#01			;EXCHANGE
		DB	#20			;COS
		DB	#05			;DIVISION
		DB	#38			;END_CALC
		RET

; Handle arctan
ATN_FUNC:	CALL	RE_STACK
		LD	A,(HL)
		CP	#81
		JR	C,SMALL
		RST	#28			;FP_CALC
		DB	#A1			;STK_ONE
		DB	#1B			;NEGATE
		DB	#01			;EXCHANGE
		DB	#05			;DIVISION
		DB	#31			;DUPLICATE
		DB	#36			;LESS_0
		DB	#A3			;STK_PI_2
		DB	#01			;EXCHANGE
		DB	#00			;JUMP_TRUE
		DB	#06			;to CASES
		DB	#1B			;NEGATE
		DB	#33			;jump
		DB	#03			;to CASES
SMALL:		RST	#28			;FP_CALC
		DB	#A0			;STK_ZERO
CASES:		DB	#01			;EXCHANGE
		DB	#31			;DUPLICATE
		DB	#31			;DUPLICATE
		DB	#04			;MULTIPLY
		DB	#31			;DUPLICATE
		DB	#0F			;ADDITION
		DB	#A1			;STK_ONE
		DB	#03			;SUBTRACT
		DB	#8C			;SERIES_0C
		DB	#10			;Exponent
		DB	#B2			;
		DB	#13			;Exponent
		DB	#0E			;
		DB	#55			;Exponent
		DB	#E4			;
		DB	#8D			;
		DB	#58			;Exponent
		DB	#39			;
		DB	#BC			;
		DB	#5B			;Exponent
		DB	#98			;
		DB	#FD			;
		DB	#9E			;Exponent
		DB	#00			;
		DB	#36			;
		DB	#75			;
		DB	#A0			;Exponent
		DB	#DB			;
		DB	#E8			;
		DB	#B4			;
		DB	#63			;Exponent
		DB	#42			;
		DB	#C4			;
		DB	#E6			;Exponent
		DB	#B5			;
		DB	#09			;
		DB	#36			;
		DB	#BE			;
		DB	#E9			;Exponent
		DB	#36			;
		DB	#73			;
		DB	#1B			;
		DB	#5D			;
		DB	#EC			;Exponent
		DB	#D8			;
		DB	#DE			;
		DB	#63			;
		DB	#BE			;
		DB	#F0			;Exponent
		DB	#61			;
		DB	#A1			;
		DB	#B3			;
		DB	#0C			;
		DB	#04			;MULTIPLY
		DB	#0F			;ADDITION
		DB	#38			;END_CALC
		RET

; Handle arcsin
ASN_FUNC:	RST	#28			;FP_CALC
		DB	#31			;DUPLICATE
		DB	#31			;DUPLICATE
		DB	#04			;MULTIPLY
		DB	#A1			;STK_ONE
		DB	#03			;SUBTRACT
		DB	#1B			;NEGATE
		DB	#28			;SQR
		DB	#A1			;STK_ONE
		DB	#0F			;ADDITION
		DB	#05			;DIVISION
		DB	#24			;ATN
		DB	#31			;DUPLICATE
		DB	#0F			;ADDITION
		DB	#38			;END_CALC
		RET

; Handle arccos
ACS_FUNC:	RST	#28			;FP_CALC
		DB	#22			;ASN
		DB	#A3			;STK_PI_2
		DB	#03			;SUBTRACT
		DB	#1B			;NEGATE
		DB	#38			;END_CALC
		RET

; Handle square root
SQR_FUNC:	RST	#28			;FP_CALC
		DB	#31			;DUPLICATE
		DB	#30			;NOT
		DB	#00			;JUMP_TRUE
		DB	#1E			;to LAST
		DB	#A2			;STK_HALF
		DB	#38			;END_CALC

; Handle exponential
TO_POWER:	RST	#28			;FP_CALC
		DB	#01			;EXCHANGE
		DB	#31			;DUPLICATE
		DB	#30			;NOT
		DB	#00			;JUMP_TRUE
		DB	#07			;to XISO
		DB	#25			;LN
		DB	#04			;MULTIPLY
		DB	#38			;END_CALC
		JP	EXP			

XISO:		DB	#02			;DELETE
		DB	#31			;DUPLICATE
		DB	#30			;NOT
		DB	#00			;JUMP_TRUE
		DB	#09			;to ONE
		DB	#A0			;STK_ZERO
		DB	#01			;EXCHANGE
		DB	#37			;GREATER_0
		DB	#00			;JUMP_TRUE
		DB	#06			;to LAST
		DB	#A1			;STK_ONE
		DB	#01			;EXCHANGE
		DB	#05			;DIVISION
ONE:		DB	#02			;DELETE
		DB	#A1			;STK_ONE
LAST:		DB	#38			;END_CALC
		RET

; BSROM additional routines
; Input of HEX numbers
HEXA:		LD	HL,SCAN_FUNC
		CP	#25
		RET	NZ
		POP	AF
		CALL	SYNTAX_Z
		JP	NZ,S_STK_DEC
		LD	DE,#0000
HEX1:		RST	#20
		CALL	ALPHANUM
		JR	NC,HEXEND
		CP	#41
		JR	C,CIS
		OR	#20
		CP	#67
		JR	NC,HEXEND
		SUB	#27
CIS:		AND	#0F
		LD	C,A
		LD	A,D
		AND	#F0
		JP	NZ,REPORT_6
		LD	A,C
		EX	DE,HL
		ADD	HL,HL
		ADD	HL,HL
		ADD	HL,HL
		ADD	HL,HL
		OR	L
		LD	L,A
		EX	DE,HL
		JR	HEX1

HEXEND:		CALL	BIN_END
		JP	S_BIN_1

; Allow number in VAL$ and VAL
VAL1:		CP	#18
		RET	Z
		CP	#9D
		RET	Z
		XOR	(IY+#01)
		RET

; Evaluation of VAL and VAL$
VAL2:		LD	HL,(#5C5D)
		BIT	6,(IY+#01)
		RET	Z
		POP	AF
		PUSH	BC
		CALL	FIND_INT2
		POP	AF
		RRCA
		JR	NC,DOLAR
		LD	H,B
		LD	L,C
		LD	C,(HL)
		INC	HL
		LD	B,(HL)
		JP	STACK_BC

DOLAR:		PUSH	BC
		LD	BC,#0004
		RST	#30
		POP	HL
		PUSH	DE
		LD	A,H
		CALL	HEX99
		LD	A,L
		CALL	HEX99
		POP	DE
		JP	CHR_DLR1

; Hex numbers
HEX99:		PUSH	AF
		RRCA
		RRCA
		RRCA
		RRCA
		CALL	HEX98
		POP	AF
HEX98:		AND	#0F
		OR	#30
		CP	#3A
		JR	C,HEX98_1
		ADD	A,#27
HEX98_1:	LD	(DE),A
		INC	DE
		RET

INFSUB:		LD	DE,COPYRIGHT+5
		CALL	PO_TOKENS1
		JP	HLO

MM:		DW	#FFFF

USERJP:		JP	#0052

DISKTOOLS:	DW	#0052

; 128k reset
RES128:		DI
		XOR	A
		LD	I,A
		OUT	(#FE),A
		LD	E,#17
CC0:		LD	BC,#7FFD
		OUT	(C),E
		LD	BC,#0008
		LD	H,A
		LD	L,A
		LD	SP,HL
CC1:		PUSH	HL
		PUSH	HL
		PUSH	HL
		PUSH	HL
		DJNZ	CC1
		DEC	C
		JR	NZ,CC1
		DEC	E
		BIT	4,E
		JR	NZ,CC0
		LD	B,#5C
CC2:		LD	(BC),A
		INC	C
		JR	NZ,CC2
		DEC	HL
		JP	RAM_DONE2

; NMI Menu
NMI_MENU:	PUSH	AF
		PUSH	HL
		LD	HL,#BFE0
		ADD	HL,SP
		JR	C,MM1
		LD	SP,#5800
		LD	HL,NMI_MENU
		PUSH	HL
		PUSH	HL
		PUSH	HL
MM1:		PUSH	BC
		PUSH	DE
		PUSH	IX
		LD	A,I
		PUSH	AF
MMRET:		DI
		LD	C,#FE
		LD	A,R
		OUT	(C),A
		OUT 	(C),0
		CALL	KEY_SCAN
		INC	E
		JR	Z,MMRET
		DEC	E
		CALL	K_TEST
		LD	XH,A
		LD	A,#22
		OUT	(#FE),A
PUST:		CALL	KEY_SCAN
		INC	E
		JR	NZ,PUST
		LD	A,#08
		OUT	(#FE),A
		LD	A,XH
		LD	HL,MMRET
		PUSH	HL
		CP	'U'			; U - user function.
		JR	Z,USERJP
		CP	'E'			; E - extended 128k reset.
		JR	Z,RES128
		CP	'I'			; I - quiet AY. Reset FDC, DMA and stop disk drive if MB-02 is present.
		JP	Z,HARD
		CP	'T'			; T - set tape as actual device (only on MB-02).
		JP	Z,JP15522
		CP	'D'			; D - set disk as actual device (only on MB-02)
		JP	Z,JP15524
		CP	'B'			; B - warm start. BASIC program with variables is not deleted.
		JP	Z,BASIC
		CP	'Z'			; Z - user function like 'U' but this key is reserved for MB-02 applications.
		LD	HL,(DISKTOOLS)
		JR	NZ,DSKIP
		JP	(HL)
DSKIP:		CP	'N'			; N - CLEAR #5FFF: NEW - memory above #6000 is not changed.
		LD	DE,#5FFF
		JR	Z,RESNEW
		CP	'R'			; R - CLEAR #FFFF: NEW - classic 48k reset.
		LD	D,E
RESNEW:		JP	Z,NEW_1
NERES:		CP	'S'			; S - save SCREEN$ on tape, or disk if MB-02 is present.
		JR	NZ,NESAV
		LD	IX,#4000
		LD	DE,#1B00
		LD	A,#FF
		JP	SA_BYTES1
NESAV:		CP	'Q'			; Q - quit / return from NMI menu.
		JR	Z,QUIT
		CP	'M'			; M - jump to MRS debugger (MRS must be loaded in memory).
		JR	Z,MRS
		CALL	NUMERIC
		RET	C
		LD	HL,#4000
		ADD	HL,SP
		JR	NC,DD0
		LD	SP,#57F0
DD0:		POP	BC
		CALL	OUT128
		JP	MMRET

; Quit from NMI Menu		
QUIT:		POP	AF
		POP	AF
		LD	I,A
		JP	PO,RET_I
		EI
RET_I:		POP	IX
		POP	DE
		POP	BC
		POP	HL
		POP	AF
		RET

; Jump to MRS debugger
MRS:		POP	AF
		POP	AF
		LD	I,A
		POP	IX
		POP	DE
		POP	BC
		POP	HL
		POP	AF
		LD	(#F4FF),HL
		POP	HL
		LD	(#F544),HL
		JP	#F514

; Print general number
HLODVA:		LD	A,':'
		RST	#10
HLO:		LD	B,H
		LD	C,L
		CALL	STACK_BC
		JP	PRINT_FP

TT:		DW	#0000			;DS #39FF-TT
UU:		DW	#FFFF

DISPL:		LD	C,A
		LD	A,(IY+#02)
		CP	#10
		LD	A,C
		JR	NZ,DIS
		LD	BC,#FBFE
		IN	C,(C)
		RRC	C
		JR	C,DII
PUSTI:		XOR	A
		IN	A,(#FE)
		RRCA
		JR	NC,PUSTI
		LD	SP,(#5C3F)		;LISTSP
		RES	5,(IY+#01)
		RET

DII:		LD	C,(IY+#76)
		BIT	1,C			;bit1=1 don't show colors during autolist
		JR	Z,DIS
		CP	#0D
		JR	Z,DIS
		CP	#20
		JR	C,DIP
DIS:		JP	PO_FETCH

DIP:		BIT	2,C			;bit2=1 show comma instead of codes
		JR	NZ,DID
		POP	AF
DID:		LD	A,#1E
		JR	DIS

; General number printing with spaces
NUM_NEW:	PUSH	DE
		PUSH	HL
		LD	E,' '
		DB	#06
NUMCOM:		LD	L,C
		LD	BC,#D8F0
		CALL	OUT_SP_NO
		JP	OUT_NUM_3

; Check of BASIC program presence
LIN2:		CALL	LINE_NO
		PUSH	HL
		LD	HL,(#5C53)
		LD	A,(HL)
		POP	HL
		RET

; Test of numbers at the begin of line
LIN3:		RST	#18
		CALL	NUMERIC
		PUSH	AF
		CALL	E_LINE_NO
		POP	AF
		RET

; Show empty cursor instead of '*' 
LIN4:		LD	A,(IY+#02)
		CP	#10
		JR	Z,LL40
		LD	D,#20
LL40:		PUSH	HL
		XOR	A
		LD	HL,(#5C51)		;channel R?
		LD	BC,#5CC0
		SBC	HL,BC
		POP	HL
		JR	Z,LL41
		BIT	0,(IY+#76)
		JP	Z,OUT_NUM_2
		DB	#01
LL41:		LD	D,#00			; no cursor at 'R'
		PUSH	DE
		LD	D,(HL)
		INC	HL
		LD	E,(HL)
		EX	DE,HL
		CALL	NUM_NEW
		EX	DE,HL
		POP	DE
		RET

; Moving around edit zone
DOLE:		CALL	ED_RIGHT
		LD	IX,ED_RIGHT
		JR	NZ,HORDOL
		LD	HL,#5C49
		RET

HORE:		CALL	ED_LEFT
		LD	IX,ED_LEFT
		JR	NC,HORDOL
		LD	HL,(#5C49)
		RET

HORDOL:		POP	BC
		LD	B,#00
HD1:		INC	B
		BIT	5,B
		RET	NZ
		PUSH	BC
		CALL	L_03F0
		POP	BC
		LD	A,(HL)
		CP	#0D
		RET	Z
		CP	' '
		JR	C,HD1+1
		SUB	#A5
		JR	C,HD1
		EXX
		LD	HL,INCB-2
		LD	(#5C51),HL
		CALL	PO_TOKENS
		CALL	ED_LIST_1
		EXX
		JR	HD1+1

		DW	INCB
INCB:		EXX
		INC	B
		EXX
		RET

; Switch 128k bank
BANKA:		RST	#20
		CALL	FETCH_NUM
		CALL	CHECK_END
		CALL	FIND_INT1
OUT128:		AND	#0F
		OR	#10
		LD	BC,#7FFD
		OUT	(C),A
		RET

; Comma instead of semicolon
EDIT:		RST	#20
		CALL	FETCH_NUM
		CALL	CHECK_END
		CALL	FIND_INT2
		LD	(#5C49),BC
		CALL	SET_MIN
		CALL	CLS_LOWER
		RES	5,(IY+#37)
VV:		DW	#FFFF
		RES	3,(IY+#01)
		CALL	ED_EDIT
		LD	SP,(#5C3D)
		POP	AF
		JP	MAIN_2

; Modified CLS command
NEW_CLS:	CALL	FIND_INT1
		OR	A
		JR	Z,NECOL
		LD	(#5C48),A
		LD	(#5C8D),A
		CALL	SA_LD_RET
NECOL:		JP	CLS

; New commands
COMM:		CP	#27			;"'"
		JR	Z,BANKA
		CP	#2C			;","
		JR	Z,EDIT
		LD	HL,NEWTAB
COM1:		BIT	7,(HL)
		JP	NZ,PRINT
		CP	(HL)
		INC	HL
		LD	E,(HL)
		INC	HL
		LD	D,(HL)
		INC	HL
		JR	NZ,COM1
		RST	#20
		CALL	CHECK_END
		EX	DE,HL
		JP	(HL)

NEWTAB:		DB	'#'
		DW	54885	
		DB	'_'
		DW	#66
		DB	'*'
		DW	HEA
		DB	'?'
		DW	INFO
		DB	#7F			;(c)
		DW	BASIC
		DB	'^'
		DW	RES128
		DB	'!'
		DW	HARD
		DB	'='
		DW	USERJP

; Quiet AY. Reset FDC, DMA, stop drives if MB-02 is present
HARD:		XOR	A
		LD	BC,#FFFD
		OUT	(#13),A			; FDD motor
		LD	A,#D0
		OUT	(#0F),A			; FDC
		LD	A,#C3
		OUT	(#0B),A			; DMA
		LD	A,#07	
		OUT	(C),A			; AY
		LD	A,#BF
		OUT	(#FD),A
		LD	A,#0D
		OUT	(C),A
		LD	A,#80
		OUT	(#FD),A
		RET

; Warm start
BASIC:		LD	HL,INIT_CHAN
		LD	DE,#5CB6
		LD	BC,#0015
		LD	(#5C4F),DE
		LDIR
		LD	HL,#3C00
		LD	(#5C36),HL
		LD	HL,#0040
		LD	(#5C38),HL
		LD	IY,#5C3A
		LD	HL,(#5CB2)
		LD	(HL),#3E
		DEC	HL
		LD	SP,HL
		DEC	HL
		DEC	HL
		LD	(#5C3D),HL
		IM	1
		EI
		LD	HL,(#5C59)
		JP	WARM_ST

; Enhanced POKE
NEW_POKE:	CALL	SYNTAX_Z
		CALL	NZ,FIND_INT2
		LD	D,B
		LD	E,C
POKLOP:		RST	#18
		CP	#2C
		JR	Z,POKOK
		CP	#3B
		RET	NZ
POKOK:		PUSH	DE
		PUSH	AF
		RST	#20
		CALL	SCANNING
		POP	AF
		POP	DE
		CALL	SYNTAX_Z
		JR	Z,POKLOP
		BIT	6,(IY+#01)
		JR	NZ,POKNUM
POKRET:		PUSH	AF
		PUSH	DE
		CALL	STK_FETCH
		EX	DE,HL
		POP	DE
		LD	A,B
		OR	C
		JR	Z,POKNIC
		LDIR
		POP	AF
		RRCA
		JR	NC,POKLOP
		LD	H,D
		LD	L,E
		DEC	HL
		SET	7,(HL)
		PUSH	AF
POKNIC:		POP	AF
		JR	POKLOP

POKNUM:		PUSH	DE
		RRCA
		JR	C,POKDW
POKDB:		CALL	FIND_INT1
		POP	DE
		JR	POKLD

POKDW:		CALL	FIND_INT2
		POP	DE
		LD	A,C
		LD	(DE),A
		INC	DE
		LD	A,B
POKLD:		LD	(DE),A
		INC	DE
		JR	POKLOP

SS:		DB	#FF
WW:		DW	#FFFF

; New line number test
LIN1:		CALL	CP_LINES
		RET	NC
		LD	A,(HL)
		AND	#C0
		RET	NZ
		SCF
		RET

; New boot screen
INFO:		CALL	CLS
		LD	A,#FE
		CALL	CHAN_OPEN
		LD	HL,(#5C4B)
		LD	BC,(#5C53)
		XOR	A
		PUSH	HL
		SBC	HL,BC
		CALL	INFSUB
		POP	BC
		SCF
		LD	HL,(#5C59)
		SBC	HL,BC
		LD	A,#01
		CALL	INFSUB
		LD	BC,(#5C65)
		LD	HL,#0000
		ADD	HL,SP
		SBC	HL,BC
		LD	A,#02
		CALL	INFSUB
		JP	PRINT_5

; Header command
HEA:		LD	A,#FE
		CALL	CHAN_OPEN
ZNOVU:		DI
		LD	IX,#5C9E
		LD	DE,#0010
		XOR	A
		INC	E
		SCF
		EX	AF,AF'
		LD	A,#0E
		OUT	(#FE),A
		IN	A,(#FE)
		RRA
		CALL	LD_BYTES1
		CALL	SA_LD_RET
		JR	NC,ZNOVU
		LD	(#5C8C),A
		LD	A,#17
		RST	#10
		XOR	A
		RST	#10
		RST	#10
		LD	HL,#5C9E
		LD	A,(HL)
		OR	#30
		RST	#10
		LD	A,#3A
		RST	#10
		LD	B,#0A
MENO:		INC	HL
		LD	A,(HL)
		CP	#20
		JR	NC,MENO1
		LD	A,#1E
MENO1:		RST	#10
		DJNZ	MENO
		LD	A,#17
		RST	#10
		LD	A,#15
		RST	#10
		RST	#10
		LD	HL,(#5CAB)
		CALL	NUM_NEW
		LD	HL,(#5CA9)
		CALL	HLODVA
		LD	A,#0D
		RST	#10
		JR	ZNOVU

; Unused bytes
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DB	#FF

JP15522:	RET

		DB	#FF

JP15524:	RET

		DB	#FF

		DB	" Busy soft rom " 
		DB	VER1, VER2, VER3
		DB	" "

; Unused bytes
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DW	#FFFF
		DB	#FF
; BSROM - new characters
CHAR_SET_N:	DB	#00,#00,#00,#00,#00,#00,#7E,#00	;line
		DB	#00,#7E,#7E,#7E,#7E,#7E,#7E,#00	;square

; Character set
CHAR_SET:	DB	#00,#00,#00,#00,#00,#00,#00,#00	;space
		DB	#00,#10,#10,#10,#10,#00,#10,#00	;!
		DB	#00,#24,#24,#00,#00,#00,#00,#00	;"
		DB	#00,#24,#7E,#24,#24,#7E,#24,#00	;#
		DB	#00,#08,#3E,#28,#3E,#0A,#3E,#08	;$
		DB	#00,#62,#64,#08,#10,#26,#46,#00	;%
		DB	#00,#10,#28,#10,#2A,#44,#3A,#00	;&
		DB	#00,#08,#10,#00,#00,#00,#00,#00	;'
		DB	#00,#04,#08,#08,#08,#08,#04,#00	;(
		DB	#00,#20,#10,#10,#10,#10,#20,#00	;)
		DB	#00,#00,#14,#08,#3E,#08,#14,#00	;*
		DB	#00,#00,#08,#08,#3E,#08,#08,#00	;+
		DB	#00,#00,#00,#00,#00,#08,#08,#10	;,
		DB	#00,#00,#00,#00,#3E,#00,#00,#00	;-
		DB	#00,#00,#00,#00,#00,#18,#18,#00	;.
		DB	#00,#00,#02,#04,#08,#10,#20,#00	;/
		DB	#00,#3C,#46,#4A,#52,#62,#3C,#00	;0
		DB	#00,#18,#28,#08,#08,#08,#3E,#00	;1
		DB	#00,#3C,#42,#02,#3C,#40,#7E,#00	;2
		DB	#00,#3C,#42,#0C,#02,#42,#3C,#00	;3
		DB	#00,#08,#18,#28,#48,#7E,#08,#00	;4
		DB	#00,#7E,#40,#7C,#02,#42,#3C,#00	;5
		DB	#00,#3C,#40,#7C,#42,#42,#3C,#00	;6
		DB	#00,#7E,#02,#04,#08,#10,#10,#00	;7
		DB	#00,#3C,#42,#3C,#42,#42,#3C,#00	;8
		DB	#00,#3C,#42,#42,#3E,#02,#3C,#00	;9
		DB	#00,#00,#00,#10,#00,#00,#10,#00	;:
		DB	#00,#00,#10,#00,#00,#10,#10,#20	;;
		DB	#00,#00,#04,#08,#10,#08,#04,#00	;<
		DB	#00,#00,#00,#3E,#00,#3E,#00,#00	;=
		DB	#00,#00,#10,#08,#04,#08,#10,#00	;>
		DB	#00,#3C,#42,#04,#08,#00,#08,#00	;?
		DB	#00,#3C,#02,#3A,#4A,#4A,#3C,#00	;@ BSROM - more beautiful @ character
		DB	#00,#3C,#42,#42,#7E,#42,#42,#00	;A
		DB	#00,#7C,#42,#7C,#42,#42,#7C,#00	;B
		DB	#00,#3C,#42,#40,#40,#42,#3C,#00	;C
		DB	#00,#78,#44,#42,#42,#44,#78,#00	;D
		DB	#00,#7E,#40,#7C,#40,#40,#7E,#00	;E
		DB	#00,#7E,#40,#7C,#40,#40,#40,#00	;F
		DB	#00,#3C,#42,#40,#4E,#42,#3C,#00	;G
		DB	#00,#42,#42,#7E,#42,#42,#42,#00	;H
		DB	#00,#3E,#08,#08,#08,#08,#3E,#00	;I
		DB	#00,#02,#02,#02,#42,#42,#3C,#00	;J
		DB	#00,#44,#48,#70,#48,#44,#42,#00	;K
		DB	#00,#40,#40,#40,#40,#40,#7E,#00	;L
		DB	#00,#42,#66,#5A,#42,#42,#42,#00	;M
		DB	#00,#42,#62,#52,#4A,#46,#42,#00	;N
		DB	#00,#3C,#42,#42,#42,#42,#3C,#00	;O
		DB	#00,#7C,#42,#42,#7C,#40,#40,#00	;P
		DB	#00,#3C,#42,#42,#52,#4A,#3C,#00	;Q
		DB	#00,#7C,#42,#42,#7C,#44,#42,#00	;R
		DB	#00,#3C,#40,#3C,#02,#42,#3C,#00	;S
		DB	#00,#FE,#10,#10,#10,#10,#10,#00	;T
		DB	#00,#42,#42,#42,#42,#42,#3C,#00	;U
		DB	#00,#42,#42,#42,#42,#24,#18,#00	;V
		DB	#00,#42,#42,#42,#42,#5A,#24,#00	;W
		DB	#00,#42,#24,#18,#18,#24,#42,#00	;X
		DB	#00,#82,#44,#28,#10,#10,#10,#00	;Y
		DB	#00,#7E,#04,#08,#10,#20,#7E,#00	;Z
		DB	#00,#0E,#08,#08,#08,#08,#0E,#00	;[
		DB	#00,#00,#40,#20,#10,#08,#04,#00	;\
		DB	#00,#70,#10,#10,#10,#10,#70,#00	;]
		DB	#00,#10,#38,#54,#10,#10,#10,#00	;^
		DB	#00,#00,#00,#00,#00,#00,#00,#FF	;_
		DB	#00,#1C,#22,#78,#20,#20,#7E,#00	;£
		DB	#00,#00,#38,#04,#3C,#44,#3C,#00	;a
		DB	#00,#20,#20,#3C,#22,#22,#3C,#00	;b
		DB	#00,#00,#1C,#20,#20,#20,#1C,#00	;c
		DB	#00,#04,#04,#3C,#44,#44,#3C,#00	;d
		DB	#00,#00,#38,#44,#78,#40,#3C,#00	;e
		DB	#00,#0C,#10,#18,#10,#10,#10,#00	;f
		DB	#00,#00,#3C,#44,#44,#3C,#04,#38	;g
		DB	#00,#40,#40,#78,#44,#44,#44,#00	;h
		DB	#00,#10,#00,#30,#10,#10,#38,#00	;i
		DB	#00,#04,#00,#04,#04,#04,#24,#18	;j
		DB	#00,#20,#28,#30,#30,#28,#24,#00	;k
		DB	#00,#10,#10,#10,#10,#10,#0C,#00	;l
		DB	#00,#00,#68,#54,#54,#54,#54,#00	;m
		DB	#00,#00,#78,#44,#44,#44,#44,#00	;n
		DB	#00,#00,#38,#44,#44,#44,#38,#00	;o
		DB	#00,#00,#78,#44,#44,#78,#40,#40	;p
		DB	#00,#00,#3C,#44,#44,#3C,#04,#06	;q
		DB	#00,#00,#1C,#20,#20,#20,#20,#00	;r
		DB	#00,#00,#38,#40,#38,#04,#78,#00	;s
		DB	#00,#10,#38,#10,#10,#10,#0C,#00	;t
		DB	#00,#00,#44,#44,#44,#44,#38,#00	;u
		DB	#00,#00,#44,#44,#28,#28,#10,#00	;v
		DB	#00,#00,#44,#54,#54,#54,#28,#00	;w
		DB	#00,#00,#44,#28,#10,#28,#44,#00	;x
		DB	#00,#00,#44,#44,#44,#3C,#04,#38	;y
		DB	#00,#00,#7C,#08,#10,#20,#7C,#00	;z
		DB	#00,#0E,#08,#30,#08,#08,#0E,#00	;{
		DB	#00,#08,#08,#08,#08,#08,#08,#00	;|
		DB	#00,#70,#10,#0C,#10,#10,#70,#00	;}
		DB	#00,#14,#28,#00,#00,#00,#00,#00	;~
		DB	#3C,#42,#99,#A1,#A1,#99,#42,#3C	;(c)
