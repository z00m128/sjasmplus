;************************************************************************
;** An assembly file listing to generate a 16K Rom for the ZX Spectrum **
;************************************************************************
;
; Copyright (c) Amstrad plc. All rights reserved.
;
; Acknowledgements
; -----------------
; Sean Irvine		for default list of section headings
;			(author unknown).
; Dr. Ian Logan		for labels and functional disassembly.
; Dr. Frank O'Hara	for labels and functional disassembly.
;
; Credits
; -------
; Alex Pallero Gonzales	for corrections.
; Mike Dailly		for comments.
; Alvin Albrecht	for comments.
; Hob of c.s.s		for full relocatability implementation and testing.
;			
; z00m^SinDiKAT		sjasmplus adaptation and dirty reformat.
;
; obsolete labels
; L1C16 JUMP-C-R

		OUTPUT	"zx-spectrum-rom.bin"

; System variables definitions

		include	"zx-spectrum-rom-sysvars.i.asm"

;*****************************************
;** Part 1. RESTART ROUTINES AND TABLES **
;*****************************************

;------
; Start
;------
; At switch on, the Z80 chip is in interrupt mode 0.
; This location can also be 'called' to reset the machine.
; Typically with PRINT USR 0.

		ORG	$0000
					;;;$0000
START:		DI			; disable interrupts.
		XOR	A		; signal coming from START.
		LD	DE,$FFFF	; top of possible physical RAM.
		JP	START_NEW	; jump forward to common code at START_NEW.

;--------------
; Error restart
;--------------
; The error pointer is made to point to the position of the error to enable
; the editor to show the error if it occurred during syntax checking.
; It is used at 37 places in the program.
; An instruction fetch on address $0008 may page in a peripheral ROM
; although this was not an original design concept.

					;;;$0008
ERROR_1:	LD	HL,(CH_ADD)	; fetch the character address from CH_ADD.
		LD	(X_PTR),HL	; copy it to the error pointer X_PTR.
		JR	ERROR_2		; forward to continue at ERROR_2.

;------------------
; Print a character
;------------------
; The A register holds the code of the character that is to be sent to
; the output stream of the current channel.
; The alternate register set is used to output a character in the A register
; so there is no need to preserve any of the current registers.
; This restart occurs 21 times.

					;;;$0010
PRINT_A:	JP	PRINT_A_2	; jump forward to continue at PRINT_A_2.

		DEFB	$FF, $FF, $FF	; five unused locations.
		DEFB	$FF, $FF

;--------------------
; Collect a character
;--------------------
; The contents of the location currently addressed by CH_ADD are fetched.
; A return is made if the value represents a character that has
; relevance to the BASIC parser. Otherwise CH_ADD is incremented and the
; tests repeated. CH_ADD will be addressing somewhere -
; 1) in the basic program area during line execution.
; 2) in workspace if evaluating, for example, a string expression.
; 3) in the edit buffer if parsing a direct command or a new basic line.
; 4) in workspace if accepting input but not that from INPUT LINE.

					;;;$0018
GET_CHAR:	LD	HL,(CH_ADD)	; fetch the address from CH_ADD.
		LD	A,(HL)		; use it to pick up current character.

					;;;$001C
TEST_CHAR:	CALL	SKIP_OVER	; routine SKIP_OVER tests if the character
		RET	NC		; is relevant. Return if it is so.

;-----------------------
; Collect next character
;-----------------------
; As the BASIC commands and expressions are interpreted, this routine is
; called repeatedly to step along the line. It is used 83 times.

					;;;$0020
NEXT_CHAR:	CALL	CH_ADD_1	; routine CH_ADD_1 fetches the next immediate character.
		JR	TEST_CHAR	; jump back to TEST_CHAR until a valid
					; character is found.
		DEFB	$FF, $FF, $FF	; unused

;-------------------
; Calculator restart
;-------------------
; This restart enters the Spectrum's internal, floating-point,
; stack-based, FORTH-like language.
; It is further used recursively from within the calculator.
; It is used on 77 occasions.

					;;;$0028
FP_CALC:	JP	CALCULATE	; jump forward to the CALCULATE routine.

		DEFB	$FF, $FF, $FF	; spare - note that on the ZX81, space being a 
		DEFB	$FF, $FF	; little cramped, these same locations were
					; used for the five-byte END_CALC literal.

;------------------------------------
; Create free locations in work space
;------------------------------------
; This restart is used on only 12 occasions to create BC spaces
; between workspace and the calculator stack.

					;;;$0030
BC_SPACES:	PUSH	BC		; save number of spaces.
		LD	HL,(WORKSP)	; fetch WORKSP.
		PUSH	HL		; save address of workspace.
		JP	RESERVE		; jump forward to continuation code RESERVE.

;---------------------------
; Maskable interrupt routine
;---------------------------
; This routine increments the Spectrum's three-byte FRAMES counter
; fifty times a second (sixty times a second in the USA ).
; Both this routine and the called KEYBOARD subroutine use 
; the IY register to access system variables and flags so a user-written
; program must disable interrupts to make use of the IY register.

					;;;$0038
MASK_INT:	PUSH	AF		; save the registers.
		PUSH	HL		; but not IY unfortunately.
		LD	HL,(FRAMES1)	; fetch two bytes at FRAMES1.
		INC	HL		; increment lowest two bytes of counter.
		LD	(FRAMES1),HL	; place back in FRAMES1.
		LD	A,H		; test if the result
		OR	L		; was zero.
		JR	NZ,KEY_INT	; forward to KEY_INT if not.

		INC	(IY+$40)	; otherwise increment FRAMES3 the third byte.

					; now save the rest of the main registers and read and decode the keyboard.

					;;;$0048
KEY_INT:	PUSH	BC		; save the other
		PUSH	DE		; main registers.
		CALL	KEYBOARD	; routine KEYBOARD executes a stage in the process of reading a key-press.
		POP	DE
		POP	BC		; restore registers.
		POP	HL
		POP	AF
		EI			; enable interrupts.
		RET			; return.

;----------------
; ERROR_2 routine
;----------------
; A continuation of the code at 0008.
; The error code is stored and after clearing down stacks,
; an indirect jump is made to MAIN_4, etc. to handle the error.

					;;;$0053
ERROR_2:	POP	HL		; drop the return address - the location
					; after the RST 08H instruction.
		LD	L,(HL)		; fetch the error code that follows.
					; (nice to see this instruction used.)

					; Note. this entry point is used when out of memory at REPORT_4.
					; The L register has been loaded with the report code but X_PTR 
					; is not updated.

					;;;$0055
ERROR_3:	LD	(IY+$00),L	; store it in the system variable ERR_NR.
		LD	SP,(ERR_SP)	; ERR_SP points to an error handler on the
					; machine stack. There may be a hierarchy
					; of routines.
					; to MAIN_4 initially at base.
					; or REPORT_G on line entry.
					; or ED_ERROR when editing.
					; or ED_FULL during ED_ENTER.
					; or IN_VAR_1 during runtime input etc.

		JP	SET_STK		; jump to SET_STK to clear the calculator
					; stack and reset MEM to usual place in the
					; systems variables area.
					; and then indirectly to MAIN_4, etc.

		DEFB	$FF, $FF, $FF	; unused locations
		DEFB	$FF, $FF, $FF	; before the fixed-position
		DEFB	$FF 		; NMI routine.

;-------------------------------
; Non-maskable interrupt routine
;-------------------------------
; There is no NMI switch on the standard Spectrum.
; When activated, a location in the system variables is tested
; and if the contents are zero a jump made to that location else
; a return is made. Perhaps a disabled development feature but
; if the logic was reversed, no program would be safe from
; copy-protection and the Spectrum would have had no software base.
; The location NMIADD was later used by Interface 1 for other purposes
; ironically to make use of the Spectrum's RS232 TAB character
; which was not understood when the Interface was designed.
; On later Spectrums, and the Brazilian Spectrum, the logic of this
; routine was reversed.

					;;;$0066
RESET:		PUSH	AF		; save the
		PUSH	HL		; registers.
		LD	HL,(NMIADD)	; fetch the system variable NMIADD.
		LD	A,H		; test address
		OR	L		; for zero.
		JR	NZ,NO_RESET	; skip to NO_RESET if NOT ZERO

		JP	(HL)		; jump to routine ( i.e. START )

					;;;$0070
NO_RESET:	POP	HL		; restore the
		POP	AF		; registers.
		RETN			; return to previous interrupt state.

;----------------------
; CH ADD + 1 subroutine
;----------------------
; This subroutine is called from RST 20, and three times from elsewhere
; to fetch the next immediate character following the current valid character
; address and update the associated system variable.
; The entry point TEMP_PTR1 is used from the SCANNING routine.
; Both TEMP_PTR1 and TEMP_PTR2 are used by the READ command routine.

					;;;$0074
CH_ADD_1:	LD	HL,(CH_ADD)	; fetch address from CH_ADD.

					;;;$0077
TEMP_PTR1:	INC	HL		; increase the character address by one.

					;;;$0078
TEMP_PTR2:	LD	(CH_ADD),HL	; update CH_ADD with character address.
		LD	A,(HL)		; load character to A from HL.
		RET			; and return.

;----------
; Skip over
;----------
; This subroutine is called once from RST 18 to skip over white-space and
; other characters irrelevant to the parsing of a basic line etc. .
; Initially the A register holds the character to be considered
; and HL holds it's address which will not be within quoted text
; when a basic line is parsed.
; Although the 'tab' and 'at' characters will not appear in a basic line,
; they could be present in a string expression, and in other situations.
; Note. although white-space is usually placed in a program to indent loops
; and make it more readable, it can also be used for the opposite effect and
; spaces may appear in variable names although the parser never sees them.
; It is this routine that helps make the variables 'Anum bEr5 3BUS' and
; 'a number 53 bus' appear the same to the parser.

					;;;$007D
SKIP_OVER:	CP	$21		; test if higher than space.
		RET	NC		; return with carry clear if so.

		CP	$0D		; carriage return ?
		RET	Z		; return also with carry clear if so.

					; all other characters have no relevance
					; to the parser and must be returned with
					; carry set.

		CP	$10		; test if 0-15d
		RET	C		; return, if so, with carry set.

		CP	$18		; test if 24-32d
		CCF			; complement carry flag.
		RET	C		; return with carry set if so.

					; now leaves 16d-23d

		INC	HL		; all above have at least one extra character
					; to be stepped over.
		CP	$16		; controls 22d ('at') and 23d ('tab') have two.
		JR	C,SKIPS		; forward to SKIPS with ink, paper, flash,
					; bright, inverse or over controls.
					; Note. the high byte of tab is for RS232 only.
					; it has no relevance on this machine.
		INC	HL		; step over the second character of 'at'/'tab'.

					;;;$0090
SKIPS:		SCF			; set the carry flag
		LD	(CH_ADD),HL	; update the CH_ADD system variable.
		RET			; return with carry set.


;-------------
; Token tables
;-------------
; The tokenized characters 134d (RND) to 255d (COPY) are expanded using
; this table. The last byte of a token is inverted to denote the end of
; the word. The first is an inverted step-over byte.

					;;;$0095
TKN_TABLE:	DEFB	'?'+$80
		DEFB	"RN",'D'+$80
		DEFB	"INKEY",'$'+$80
		DEFB	"P",'I'+$80
		DEFB	"F",'N'+$80
		DEFB	"POIN",'T'+$80
		DEFB	"SCREEN",'$'+$80
		DEFB	"ATT",'R'+$80
		DEFB	"A",'T'+$80
		DEFB	"TA",'B'+$80
		DEFB	"VAL",'$'+$80
		DEFB	"COD",'E'+$80
		DEFB	"VA",'L'+$80
		DEFB	"LE",'N'+$80
		DEFB	"SI",'N'+$80
		DEFB	"CO",'S'+$80
		DEFB	"TA",'N'+$80
		DEFB	"AS",'N'+$80
		DEFB	"AC",'S'+$80
		DEFB	"AT",'N'+$80
		DEFB	"L",'N'+$80
		DEFB	"EX",'P'+$80
		DEFB	"IN",'T'+$80
		DEFB	"SQ",'R'+$80
		DEFB	"SG",'N'+$80
		DEFB	"AB",'S'+$80
		DEFB	"PEE",'K'+$80
		DEFB	"I",'N'+$80
		DEFB	"US",'R'+$80
		DEFB	"STR",'$'+$80
		DEFB	"CHR",'$'+$80
		DEFB	"NO",'T'+$80
		DEFB	"BI",'N'+$80

					; The previous 32 function-type words are printed without a leading space
					; The following have a leading space if they begin with a letter

		DEFB	"O",'R'+$80
		DEFB	"AN",'D'+$80
		DEFB	$3C,'='+$80	; <=
		DEFB	$3E,'='+$80	; >=
		DEFB	$3C,$3E+$80	; <>
		DEFB	"LIN",'E'+$80
		DEFB	"THE",'N'+$80
		DEFB	"T",'O'+$80
		DEFB	"STE",'P'+$80
		DEFB	"DEF F",'N'+$80
		DEFB	"CA",'T'+$80
		DEFB	"FORMA",'T'+$80
		DEFB	"MOV",'E'+$80
		DEFB	"ERAS",'E'+$80
		DEFB	"OPEN ",'#'+$80
		DEFB	"CLOSE ",'#'+$80
		DEFB	"MERG",'E'+$80
		DEFB	"VERIF",'Y'+$80
		DEFB	"BEE",'P'+$80
		DEFB	"CIRCL",'E'+$80
		DEFB	"IN",'K'+$80
		DEFB	"PAPE",'R'+$80
		DEFB	"FLAS",'H'+$80
		DEFB	"BRIGH",'T'+$80
		DEFB	"INVERS",'E'+$80
		DEFB	"OVE",'R'+$80
		DEFB	"OU",'T'+$80
		DEFB	"LPRIN",'T'+$80
		DEFB	"LLIS",'T'+$80
		DEFB	"STO",'P'+$80
		DEFB	"REA",'D'+$80
		DEFB	"DAT",'A'+$80
		DEFB	"RESTOR",'E'+$80
		DEFB	"NE",'W'+$80
		DEFB	"BORDE",'R'+$80
		DEFB	"CONTINU",'E'+$80
		DEFB	"DI",'M'+$80
		DEFB	"RE",'M'+$80
		DEFB	"FO",'R'+$80
		DEFB	"GO T",'O'+$80
		DEFB	"GO SU",'B'+$80
		DEFB	"INPU",'T'+$80
		DEFB	"LOA",'D'+$80
		DEFB	"LIS",'T'+$80
		DEFB	"LE",'T'+$80
		DEFB	"PAUS",'E'+$80
		DEFB	"NEX",'T'+$80
		DEFB	"POK",'E'+$80
		DEFB	"PRIN",'T'+$80
		DEFB	"PLO",'T'+$80
		DEFB	"RU",'N'+$80
		DEFB	"SAV",'E'+$80
		DEFB	"RANDOMIZ",'E'+$80
		DEFB	"I",'F'+$80
		DEFB	"CL",'S'+$80
		DEFB	"DRA",'W'+$80
		DEFB	"CLEA",'R'+$80
		DEFB	"RETUR",'N'+$80
		DEFB	"COP",'Y'+$80
		
;-----------
; Key tables
;-----------
; These six look-up tables are used by the keyboard reading routine
; to decode the key values.

; The first table contains the maps for the 39 keys of the standard
; 40-key Spectrum keyboard. The remaining key [SHIFT $27] is read directly.
; The keys consist of the 26 upper-case alphabetic characters, the 10 digit
; keys and the space, ENTER and symbol shift key.
; Unshifted alphabetic keys have $20 added to the value.
; The keywords for the main alphabetic keys are obtained by adding $A5 to
; the values obtained from this table.

					;;;$0205
MAIN_KEYS:	DEFB	$42		; B
		DEFB	$48		; H
		DEFB	$59		; Y
		DEFB	$36		; 6
		DEFB	$35		; 5
		DEFB	$54		; T
		DEFB	$47		; G
		DEFB	$56		; V
		DEFB	$4E		; N
		DEFB	$4A		; J
		DEFB	$55		; U
		DEFB	$37		; 7
		DEFB	$34		; 4
		DEFB	$52		; R
		DEFB	$46		; F
		DEFB	$43		; C
		DEFB	$4D		; M
		DEFB	$4B		; K
		DEFB	$49		; I
		DEFB	$38		; 8
		DEFB	$33		; 3
		DEFB	$45		; E
		DEFB	$44		; D
		DEFB	$58		; X
		DEFB	$0E		; SYMBOL SHIFT
		DEFB	$4C		; L
		DEFB	$4F		; O
		DEFB	$39		; 9
		DEFB	$32		; 2
		DEFB	$57		; W
		DEFB	$53		; S
		DEFB	$5A		; Z
		DEFB	$20		; SPACE
		DEFB	$0D		; ENTER
		DEFB	$50		; P
		DEFB	$30		; 0
		DEFB	$31		; 1
		DEFB	$51		; Q
		DEFB	$41		; A

					;;;$022C
					;  The 26 unshifted extended mode keys for the alphabetic characters.
					;  The green keywords on the original keyboard.
E_UNSHIFT:	DEFB	$E3		; READ
		DEFB	$C4		; BIN
		DEFB	$E0		; LPRINT
		DEFB	$E4		; DATA
		DEFB	$B4		; TAN
		DEFB	$BC		; SGN
		DEFB	$BD		; ABS
		DEFB	$BB		; SQR
		DEFB	$AF		; CODE
		DEFB	$B0		; VAL
		DEFB	$B1		; LEN
		DEFB	$C0		; USR
		DEFB	$A7		; PI
		DEFB	$A6		; INKEY$
		DEFB	$BE		; PEEK
		DEFB	$AD		; TAB
		DEFB	$B2		; SIN
		DEFB	$BA		; INT
		DEFB	$E5		; RESTORE
		DEFB	$A5		; RND
		DEFB	$C2		; CHR$
		DEFB	$E1		; LLIST
		DEFB	$B3		; COS
		DEFB	$B9		; EXP
		DEFB	$C1		; STR$
		DEFB	$B8		; LN

					;;;$0246
					;  The 26 shifted extended mode keys for the alphabetic characters.
					;  The red keywords below keys on the original keyboard.
EXT_SHIFT:	DEFB	$7E		; ~
		DEFB	$DC		; BRIGHT
		DEFB	$DA		; PAPER
		DEFB	$5C		; \ ;
		DEFB	$B7		; ATN
		DEFB	$7B		; {
		DEFB	$7D		; }
		DEFB	$D8		; CIRCLE
		DEFB	$BF		; IN
		DEFB	$AE		; VAL$
		DEFB	$AA		; SCREEN$
		DEFB	$AB		; ATTR
		DEFB	$DD		; INVERSE
		DEFB	$DE		; OVER
		DEFB	$DF		; OUT
		DEFB	$7F		; (Copyright character)
		DEFB	$B5		; ASN
		DEFB	$D6		; VERIFY
		DEFB	$7C		; |
		DEFB	$D5		; MERGE
		DEFB	$5D		; ]
		DEFB	$DB		; FLASH
		DEFB	$B6		; ACS
		DEFB	$D9		; INK
		DEFB	$5B		; [
		DEFB	$D7		; BEEP

					;;;$0260
					;  The ten control codes assigned to the top line of digits when the shift 
					;  key is pressed.
CTL_CODES:	DEFB	$0C		; DELETE
		DEFB	$07		; EDIT
		DEFB	$06		; CAPS LOCK
		DEFB	$04		; TRUE VIDEO
		DEFB	$05		; INVERSE VIDEO
		DEFB	$08		; CURSOR LEFT
		DEFB	$0A		; CURSOR DOWN
		DEFB	$0B		; CURSOR UP
		DEFB	$09		; CURSOR RIGHT
		DEFB	$0F		; GRAPHICS

					;;;$026A
					;  The 26 red symbols assigned to the alphabetic characters of the keyboard.
					;  The ten single-character digit symbols are converted without the aid of
					;  a table using subtraction and minor manipulation. 
SYM_CODES:	DEFB	$E2		; STOP
		DEFB	$2A		; *
		DEFB	$3F		; ?
		DEFB	$CD		; STEP
		DEFB	$C8		; >=
		DEFB	$CC		; TO
		DEFB	$CB		; THEN
		DEFB	$5E		; ^
		DEFB	$AC		; AT
		DEFB	$2D		; -
		DEFB	$2B		; +
		DEFB	$3D		; =
		DEFB	$2E		; .
		DEFB	$2C		; ,
		DEFB	$3B		; ;
		DEFB	$22		; "
		DEFB	$C7		; <=
		DEFB	$3C		; <
		DEFB	$C3		; NOT
		DEFB	$3E		; >
		DEFB	$C5		; OR
		DEFB	$2F		; /
		DEFB	$C9		; <>
		DEFB	$60		; pound
		DEFB	$C6		; AND
		DEFB	$3A		; :

					;;;$0284
					;  The ten keywords assigned to the digits in extended mode.
					;  The remaining red keywords below the keys.
E_DIGITS:	DEFB	$D0		; FORMAT
		DEFB	$CE		; DEF FN
		DEFB	$A8		; FN
		DEFB	$CA		; LINE
		DEFB	$D3		; OPEN#
		DEFB	$D4		; CLOSE#
		DEFB	$D1		; MOVE
		DEFB	$D2		; ERASE
		DEFB	$A9		; POINT
		DEFB	$CF		; CAT


;*******************************
;** Part 2. KEYBOARD ROUTINES **
;*******************************

; Using shift keys and a combination of modes the Spectrum 40-key keyboard
; can be mapped to 256 input characters

;----------------------------------------------------------------------------
;
;         0     1     2     3     4 -Bits-  4     3     2     1     0
; PORT                                                                    PORT
;
; F7FE  [ 1 ] [ 2 ] [ 3 ] [ 4 ] [ 5 ]  |  [ 6 ] [ 7 ] [ 8 ] [ 9 ] [ 0 ]   EFFE
;  ^                                   |                                   v
; FBFE  [ Q ] [ W ] [ E ] [ R ] [ T ]  |  [ Y ] [ U ] [ I ] [ O ] [ P ]   DFFE
;  ^                                   |                                   v
; FDFE  [ A ] [ S ] [ D ] [ F ] [ G ]  |  [ H ] [ J ] [ K ] [ L ] [ ENT ] BFFE
;  ^                                   |                                   v
; FEFE  [SHI] [ Z ] [ X ] [ C ] [ V ]  |  [ B ] [ N ] [ M ] [sym] [ SPC ] 7FFE
;  ^     $27                                                 $18           v
; Start                                                                   End
;        00100111                                            00011000
;
;----------------------------------------------------------------------------
; The above map may help in reading.
; The neat arrangement of ports means that the B register need only be
; rotated left to work up the left hand side and then down the right
; hand side of the keyboard. When the reset bit drops into the carry
; then all 8 half-rows have been read. Shift is the first key to be
; read. The lower six bits of the shifts are unambiguous.

;------------------
; Keyboard scanning
;------------------
; from keyboard and S_INKEY
; returns 1 or 2 keys in DE, most significant shift first if any
; key values 0-39 else 255

					;;;$028E
KEY_SCAN:	LD	L,$2F		; initial key value
					; valid values are obtained by subtracting
					; eight five times.
		LD	DE,$FFFF	; a buffer to receive 2 keys.
		LD	BC,$FEFE	; the commencing port address
					; B holds 11111110 initially and is also
					; used to count the 8 half-rows
					;;;$0296
KEY_LINE:	IN	A,(C)		; read the port to A - bits will be reset
					; if a key is pressed else set.
		CPL			; complement - pressed key-bits are now set
		AND	$1F		; apply 00011111 mask to pick up the
					; relevant set bits.
		JR	Z,KEY_DONE	; forward to KEY_DONE if zero and therefore
					; no keys pressed in row at all.
		LD	H,A		; transfer row bits to H
		LD	A,L		; load the initial key value to A

					;;;$029F
KEY_3KEYS:	INC	D		; now test the key buffer
		RET	NZ		; if we have collected 2 keys already
					; then too many so quit.

					;;;$02A1
KEY_BITS:	SUB	$08		; subtract 8 from the key value
					; cycling through key values (top = $27)
					; e.g. 2F>  27>1F>17>0F>07
					;      2E>  26>1E>16>0E>06
		SRL	H		; shift key bits right into carry.
		JR	NC,KEY_BITS	; back to KEY_BITS if not pressed
					; but if pressed we have a value (0-39d)
		LD	D,E		; transfer a possible previous key to D
		LD	E,A		; transfer the new key to E
		JR	NZ,KEY_3KEYS	; back to KEY_3KEYS if there were more
					; set bits - H was not yet zero.

					;;;$02AB
KEY_DONE:	DEC	L		; cycles 2F>2E>2D>2C>2B>2A>29>28 for
					; each half-row.
		RLC	B		; form next port address e.g. FEFE > FDFE
		JR	C,KEY_LINE	; back to KEY_LINE if still more rows to do.

		LD	A,D		; now test if D is still FF ?
		INC	A		; if it is zero we have at most 1 key
					; range now $01-$28  (1-40d)
		RET	Z		; return if one key or no key.

		CP	$28		; is it capsshift (was $27) ?
		RET	Z		; return if so.

		CP	$19		; is it symbol shift (was $18) ?
		RET	Z		; return also

		LD	A,E		; now test E
		LD	E,D		; but first switch
		LD	D,A		; the two keys.
		CP	$18		; is it symbol shift ?
		RET			; return (with zero set if it was).
					; but with symbol shift now in D

;-------------------------------
; Scan keyboard and decode value
;-------------------------------
; from interrupt 50 times a second

					;;;$02BF
KEYBOARD:	CALL	KEY_SCAN	; routine KEY_SCAN
		RET	NZ		; return if invalid combinations

					; then decrease the counters within the two key-state maps
					; as this could cause one to become free.
					; if the keyboard has not been pressed during the last five interrupts
					; then both sets will be free.


		LD	HL,KSTATE_0	; point to KSTATE_0

					;;;$02C6
K_ST_LOOP:	BIT	7,(HL)		; is it free ?  ($FF)
		JR	NZ,K_CH_SET	; forward to K_CH_SET if so

		INC	HL		; address 5-counter
		DEC	(HL)		; decrease counter
		DEC	HL		; step back
		JR	NZ,K_CH_SET	; forward to K_CH_SET if not at end of count

		LD	(HL),$FF	; else mark it free.

					;;;$02D1
K_CH_SET:	LD	A,L		; store low address byte.
		LD	HL,KSTATE_4	; point to KSTATE_4
					; (ld l, $04)
		CP	L		; have 2 been done ?
		JR	NZ,K_ST_LOOP	; back to K_ST_LOOP to consider this 2nd set

					; now the raw key (0-38) is converted to a main key (uppercase).

		CALL	K_TEST		; routine K_TEST to get main key in A
		RET	NC		; return if single shift

		LD	HL,KSTATE_0	; point to KSTATE_0
		CP	(HL)		; does it match ?
		JR	Z,K_REPEAT	; forward to K_REPEAT if so

					; if not consider the second key map.

		EX	DE,HL		; save KSTATE_0 in DE
		LD	HL,KSTATE_4	; point to KSTATE_4
		CP	(HL)		; does it match ?
		JR	Z,K_REPEAT	; forward to K_REPEAT if so

					; having excluded a repeating key we can now consider a new key.
					; the second set is always examined before the first.

		BIT	7,(HL)		; is it free ?
		JR	NZ,K_NEW	; forward to K_NEW if so.

		EX	DE,HL		; bring back KSTATE_0
		BIT	7,(HL)		; is it free ?
		RET	Z		; return if not.
					; as we have a key but nowhere to put it yet.

					; continue or jump to here if one of the buffers was free.

					;;;$02F1
K_NEW:		LD	E,A		; store key in E
		LD	(HL),A		; place in free location
		INC	HL		; advance to interrupt counter
		LD	(HL),$05	; and initialize to 5
		INC	HL		; advance to delay
		LD	A,(REPDEL)	; pick up system variable REPDEL
		LD	(HL),A		; and insert that for first repeat delay.
		INC	HL		; advance to last location of state map.
		LD	C,(IY+$07)	; pick up MODE  (3 bytes)
		LD	D,(IY+$01)	; pick up FLAGS (3 bytes)
		PUSH	HL		; save state map location
					; Note. could now have used.
 					; ld l,$41; ld c,(hl); ld l,$3B; ld d,(hl).
					; six and two threes of course.
		CALL	K_DECODE	; routine K_DECODE
		POP	HL		; restore map pointer
		LD	(HL),A		; put decoded key in last location of map.

					;;;$0308
K_END:		LD	(LASTK),A	; update LASTK system variable.
		SET	5,(IY+$01)	; update FLAGS - signal new key.
		RET			; done

;-------------------
; Repeat key routine
;-------------------
; A possible repeat has been identified. HL addresses the raw (main) key.
; The last location holds the decoded key (from the first context).

					;;;$0310
K_REPEAT:	INC	HL		; advance
		LD	(HL),$05	; maintain interrupt counter at 5
		INC	HL		; advance
		DEC	(HL)		; decrease REPDEL value.
		RET	NZ		; return if not yet zero.

		LD	A,(REPPER)	; REPPER
		LD	(HL),A		; but for subsequent repeats REPPER will be used.
		INC	HL		; advance
		LD	A,(HL)		; pick up the key decoded possibly in another context.
		JR	K_END		; back to K_END

;---------------
; Test key value
;---------------
; also called from S_INKEY
; begin by testing for a shift with no other.

					;;;$031E
K_TEST:		LD	B,D		; load most significant key to B
					; will be $FF if not shift.
		LD	D,$00		; and reset D to index into main table
		LD	A,E		; load least significant key from E
		CP	$27		; is it higher than 39d	i.e. FF
		RET	NC		; return with just a shift (in B now)

		CP	$18		; is it symbol shift ?
		JR	NZ,K_MAIN	; forward to K_MAIN if not

					; but we could have just symbol shift and no other

		BIT	7,B		; is other key $FF (ie not shift)
		RET	NZ		; return with solitary symbol shift

					;;;$032C
K_MAIN:		LD	HL,MAIN_KEYS	; address: MAIN_KEYS
		ADD	HL,DE		; add offset 0-38
		LD	A,(HL)		; pick up main key value
		SCF			; set carry flag
		RET			; return  (B has other key still)

;------------------
; Keyboard decoding
;------------------
; also called from S_INKEY

					;;;$0333
K_DECODE:	LD	A,E		; pick up the stored main key
		CP	$3A		; an arbitrary point between digits and letters
		JR	C,K_DIGIT	; forward to K_DIGIT with digits,space,enter

		DEC	C		; decrease MODE ( 0='KLC', 1='E', 2='G')
		JP	M,K_KLC_LET	; to K_KLC_LET if was zero

		JR	Z,K_E_LET	; to K_E_LET if was 1 for extended letters.

					; proceed with graphic codes.
					; Note. should selectively drop return address if code > 'U' ($55).
					; i.e. abort the KEYBOARD call.
					; e.g. cp 'V'; jr c addit; pop af; ;;addit etc. (5 bytes of instruction).
					; (S_INKEY never gets into graphics mode.)

					;; addit
		ADD	A,$4F		; add offset to augment 'A' to graphics A say.
		RET			; return.
					; Note. ( but [GRAPH] V gives RND, etc ).

					; the jump was to here with extended mode with uppercase A-Z.

					;;;$0341
K_E_LET:	LD	HL,E_UNSHIFT-$41; base address of E_UNSHIFT-$41
					; ( $01EB in standard ROM ) 
		INC	B		; test B is it empty i.e. not a shift
		JR	Z,K_LOOK_UP	; forward to K_LOOK_UP if neither shift

		LD	HL,EXT_SHIFT-$41; Address: $0205 EXT_SHIFT-$41 base

					;;;$034A
K_LOOK_UP:	LD	D,$00		; prepare to index
		ADD	HL,DE		; add the main key value
		LD	A,(HL)		; pick up other mode value
		RET			; return

					; the jump was here with mode = 0

					;;;$034F
K_KLC_LET:	LD	HL,SYM_CODES-$41; prepare base of SYM_CODES
		BIT	0,B		; shift=$27 sym-shift=$18
		JR	Z,K_LOOK_UP	; back to K_LOOK_UP with symbol-shift

		BIT	3,D		; test FLAGS is it 'K' mode (from OUT_CURS)
		JR	Z,K_TOKENS	; skip to K_TOKENS if so

		BIT	3,(IY+$30)	; test FLAGS2 - consider CAPS LOCK ?
		RET	NZ		; return if so with main code.

		INC	B		; is shift being pressed ?
					; result zero if not
		RET	NZ		; return if shift pressed.

		ADD	A,$20		; else convert the code to lower case.
		RET			; return.

					; the jump was here for tokens

					;;;$0364
K_TOKENS:	ADD	A,$A5		; add offset to main code so that 'A'
					; becomes 'NEW' etc.
		RET			; return

					; the jump was here with digits, space, enter and symbol shift (< $xx)

					;;;$0367
K_DIGIT:	CP	$30		; is it '0' or higher ?
		RET	C		; return with space, enter and symbol-shift

		DEC	C		; test MODE (was 0='KLC', 1='E', 2='G')
		JP	M,K_KLC_DGT	; jump to K_KLC_DGT if was 0.

		JR	NZ,K_GRA_DGT	; forward to K_GRA_DGT if mode was 2.

					; continue with extended digits 0-9.

		LD	HL,E_DIGITS-$30	; $0254 - base of E_DIGITS
		BIT	5,B		; test - shift=$27 sym-shift=$18
		JR	Z,K_LOOK_UP	; to K_LOOK_UP if sym-shift

		CP	$38		; is character '8' ?
		JR	NC,K_8_AND_9	; to K_8_AND_9 if greater than '7'

		SUB	$20		; reduce to ink range $10-$17
		INC	B		; shift ?
		RET	Z		; return if not.

		ADD	A,$08		; add 8 to give paper range $18 - $1F
		RET			; return

					; 89

					;;;$0382
K_8_AND_9:	SUB	$36		; reduce to 02 and 03  bright codes
		INC	B		; test if shift pressed.
		RET	Z		; return if not.

		ADD	A,$FE		; subtract 2 setting carry
		RET			; to give 0 and 1 flash codes.

					; graphics mode with digits

					;;;$0389
K_GRA_DGT:	LD	HL,CTL_CODES-$30; $0230 base address of CTL_CODES

		CP	$39		; is key '9' ?
		JR	Z,K_LOOK_UP	; back to K_LOOK_UP - changed to $0F, GRAPHICS.

		CP	$30		; is key '0' ?
		JR	Z,K_LOOK_UP	; back to K_LOOK_UP - changed to $0C, delete.

					; for keys '0' - '7' we assign a mosaic character depending on shift.

		AND	$07		; convert character to number. 0 - 7.
		ADD	A,$80		; add offset - they start at $80
		INC	B		; destructively test for shift
		RET	Z		; and return if not pressed.

		XOR	$0F		; toggle bits becomes range $88-$8F
		RET			; return.

					; now digits in 'KLC' mode

					;;;$039D
K_KLC_DGT:	INC	B		; return with digit codes if neither
		RET	Z		; shift key pressed.

		BIT	5,B		; test for caps shift.
		LD	HL,CTL_CODES-$30; prepare base of table CTL_CODES.
		JR	NZ,K_LOOK_UP	; back to K_LOOK_UP if shift pressed.

					; must have been symbol shift

		SUB	$10		; for ascii most will now be correct
					; on a standard typewriter.
		CP	$22		; but '@' is not - see below.
		JR	Z,K_AT_CHAR	; forward to to K_AT_CHAR if so

		CP	$20		; '_' is the other one that fails
		RET	NZ		; return if not.

		LD	A,$5F		; substitute ascii '_'
		RET			; return.

					;;;$03B2
K_AT_CHAR:	LD	A,$40		; substitute ascii '@'
		RET			; return.


;-------------------------------------------------------------------------
; The Spectrum Input character keys. One or two are abbreviated.
; From $00 Flash 0 to $FF COPY. The routine above has decoded all these.

;  | 00 Fl0| 01 Fl1| 02 Br0| 03 Br1| 04 In0| 05 In1| 06 CAP| 07 EDT|
;  | 08 LFT| 09 RIG| 0A DWN| 0B UP | 0C DEL| 0D ENT| 0E SYM| 0F GRA|
;  | 10 Ik0| 11 Ik1| 12 Ik2| 13 Ik3| 14 Ik4| 15 Ik5| 16 Ik6| 17 Ik7|
;  | 18 Pa0| 19 Pa1| 1A Pa2| 1B Pa3| 1C Pa4| 1D Pa5| 1E Pa6| 1F Pa7|
;  | 20 SP | 21  ! | 22  " | 23  # | 24  $ | 25  % | 26  & | 27  ' |
;  | 28  ( | 29  ) | 2A  * | 2B  + | 2C  , | 2D  - | 2E  . | 2F  / |
;  | 30  0 | 31  1 | 32  2 | 33  3 | 34  4 | 35  5 | 36  6 | 37  7 |
;  | 38  8 | 39  9 | 3A  : | 3B  ; | 3C  < | 3D  = | 3E  > | 3F  ? |
;  | 40  @ | 41  A | 42  B | 43  C | 44  D | 45  E | 46  F | 47  G |
;  | 48  H | 49  I | 4A  J | 4B  K | 4C  L | 4D  M | 4E  N | 4F  O |
;  | 50  P | 51  Q | 52  R | 53  S | 54  T | 55  U | 56  V | 57  W |
;  | 58  X | 59  Y | 5A  Z | 5B  [ | 5C  \ | 5D  ] | 5E  ^ | 5F  _ |
;  | 60 ukp| 61  a | 62  b | 63  c | 64  d | 65  e | 66  f | 67  g |
;  | 68  h | 69  i | 6A  j | 6B  k | 6C  l | 6D  m | 6E  n | 6F  o |
;  | 70  p | 71  q | 72  r | 73  s | 74  t | 75  u | 76  v | 77  w |
;  | 78  x | 79  y | 7A  z | 7B  { | 7C  | | 7D  } | 7E  ~ | 7F (c)|
;  | 80 128| 81 129| 82 130| 83 131| 84 132| 85 133| 86 134| 87 135|
;  | 88 136| 89 137| 8A 138| 8B 139| 8C 140| 8D 141| 8E 142| 8F 143|
;  | 90 [A]| 91 [B]| 92 [C]| 93 [D]| 94 [E]| 95 [F]| 96 [G]| 97 [H]|
;  | 98 [I]| 99 [J]| 9A [K]| 9B [L]| 9C [M]| 9D [N]| 9E [O]| 9F [P]|
;  | A0 [Q]| A1 [R]| A2 [S]| A3 [T]| A4 [U]| A5 RND| A6 IK$| A7 PI |
;  | A8 FN | A9 PNT| AA SC$| AB ATT| AC AT | AD TAB| AE VL$| AF COD|
;  | B0 VAL| B1 LEN| B2 SIN| B3 COS| B4 TAN| B5 ASN| B6 ACS| B7 ATN|
;  | B8 LN | B9 EXP| BA INT| BB SQR| BC SGN| BD ABS| BE PEK| BF IN |
;  | C0 USR| C1 ST$| C2 CH$| C3 NOT| C4 BIN| C5 OR | C6 AND| C7 <= |
;  | C8 >= | C9 <> | CA LIN| CB THN| CC TO | CD STP| CE DEF| CF CAT|
;  | D0 FMT| D1 MOV| D2 ERS| D3 OPN| D4 CLO| D5 MRG| D6 VFY| D7 BEP|
;  | D8 CIR| D9 INK| DA PAP| DB FLA| DC BRI| DD INV| DE OVR| DF OUT|
;  | E0 LPR| E1 LLI| E2 STP| E3 REA| E4 DAT| E5 RES| E6 NEW| E7 BDR|
;  | E8 CON| E9 DIM| EA REM| EB FOR| EC GTO| ED GSB| EE INP| EF LOA|
;  | F0 LIS| F1 LET| F2 PAU| F3 NXT| F4 POK| F5 PRI| F6 PLO| F7 RUN|
;  | F8 SAV| F9 RAN| FA IF | FB CLS| FC DRW| FD CLR| FE RET| FF CPY|

; Note that for simplicity, Sinclair have located all the control codes
; below the space character.
; ascii DEL, $7F, has been made a copyright symbol.
; Also $60, '`', not used in Basic but used in other languages, has been
; allocated the local currency symbol for the relevant country -
; ukp in most Spectrums.

;-------------------------------------------------------------------------

;**********************************
;** Part 3. LOUDSPEAKER ROUTINES **
;**********************************


; Documented by Alvin Albrecht.


;-------------------------------
; Routine to control loudspeaker
;-------------------------------
; Outputs a square wave of given duration and frequency
; to the loudspeaker.
;   Enter with: DE = #cycles - 1
;               HL = tone period as described next
;
; The tone period is measured in T states and consists of
; three parts: a coarse part (H register), a medium part
; (bits 7..2 of L) and a fine part (bits 1..0 of L) which
; contribute to the waveform timing as follows:
;
;                          coarse    medium       fine
; duration of low  = 118 + 1024*H + 16*(L>>2) + 4*(L&0x3)
; duration of hi   = 118 + 1024*H + 16*(L>>2) + 4*(L&0x3)
; Tp = tone period = 236 + 2048*H + 32*(L>>2) + 8*(L&0x3)
;                  = 236 + 2048*H + 8*L = 236 + 8*HL
;
; As an example, to output five seconds of middle C (261.624 Hz):
;   (a) Tone period = 1/261.624 = 3.822ms
;   (b) Tone period in T-States = 3.822ms*fCPU = 13378
;         where fCPU = clock frequency of the CPU = 3.5MHz
;   (c) Find H and L for desired tone period:
;         HL = (Tp - 236) / 8 = (13378 - 236) / 8 = 1643 = 0x066B
;   (d) Tone duration in cycles = 5s/3.822ms = 1308 cycles
;         DE = 1308 - 1 = 0x051B
;
; The resulting waveform has a duty ratio of exactly 50%.

					;;;$03B5
BEEPER:		DI			; Disable Interrupts so they don't disturb timing
		LD	A,L
		SRL	L
		SRL	L		; L = medium part of tone period
		CPL
		AND	$03		; A = 3 - fine part of tone period
		LD	C,A
		LD	B,$00
		LD	IX,BE_IX_3	; Address: BE_IX_3
		ADD	IX,BC		; IX holds address of entry into the loop
					; the loop will contain 0-3 NOPs, implementing
					; the fine part of the tone period.
		LD	A,(BORDCR)	; BORDCR
		AND	$38		; bits 5..3 contain border colour
		RRCA			; border colour bits moved to 2..0
		RRCA			; to match border bits on port #FE
		RRCA
		OR	$08		; bit 3 set (tape output bit on port #FE)
					; for loud sound output
					;;;$03D1
BE_IX_3:	NOP			;(4)	; optionally executed NOPs for small
					; 	  adjustments to tone period
					;;;$03D2
BE_IX_2:	NOP			;(4)
					;;;$03D3
BE_IX_1:	NOP			;(4)
					;;;$03D4
BE_IX_0:	INC	B		;(4)
		INC	C		;(4)

					;;;$03D6
BE_HL_LP:	DEC	C		;(4)	; timing loop for duration of
		JR	NZ,BE_HL_LP 	;(12/7) ; high or low pulse of waveform

		LD	C,$3F		;(7)
		DEC	B		;(4)
		JP	NZ,BE_HL_LP 	;(10)   ; to BE_HL_LP

		XOR	$10		;(7)    ; toggle output beep bit
		OUT	($FE),A  	;(11)   ; output pulse
		LD	B,H		;(4)    ; B = coarse part of tone period
		LD	C,A		;(4)    ; save port #FE output byte
		BIT	4,A		;(8)    ; if new output bit is high, go
		JR	NZ,BE_AGAIN 	;(12/7) ; to BE_AGAIN

		LD	A,D		;(4)	; one cycle of waveform has completed
		OR	E		;(4)	; (low->low). if cycle countdown = 0
		JR	Z,BE_END  	;(12/7) ; go to BE_END

		LD	A,C		;(4)	; restore output byte for port #FE
		LD	C,L		;(4)	; C = medium part of tone period
		DEC	DE		;(6)	; decrement cycle count
		JP	(IX)		;(8)	; do another cycle

					;;;$03F2; halfway through cycle
BE_AGAIN:	LD	C,L		;(4)	; C = medium part of tone period
		INC	C		;(4)	; adds 16 cycles to make duration of high = duration of low
		JP	(IX)		;(8)	; do high pulse of tone

					;;;$03F6
BE_END:		EI			; Enable Interrupts
		RET


;--------------------
; Handle BEEP command
;--------------------
; BASIC interface to BEEPER subroutine.
; Invoked in BASIC with:
;   BEEP dur,pitch
;   where dur   = duration in seconds
;         pitch = # of semitones above/below middle C
;
; Enter with: pitch on top of calculator stack
;             duration next on calculator stack

					;;;$03F8
BEEP:		RST	28H		;; FP_CALC
		DEFB	$31		;;DUPLICATE			; duplicate pitch
		DEFB	$27		;;INT				; convert to integer
		DEFB	$C0		;;st-mem-0			; store integer pitch to memory 0
		DEFB	$03		;;SUBTRACT			; calculate fractional part of pitch = fp_pitch - int_pitch
		DEFB	$34		;;STK_DATA			; push constant
		DEFB	$EC		;;Exponent: $7C, Bytes: 4	; constant = 0.05762265
		DEFB	$6C,$98,$1F,$F5 ;;($6C,$98,$1F,$F5)
		DEFB	$04		;;MULTIPLY			; compute:
		DEFB	$A1		;;STK_ONE			; 1 + 0.05762265 * fraction_part(pitch)
		DEFB	$0F		;;ADDITION
		DEFB	$38		;;END_CALC			; leave on calc stack

		LD	HL,MEM_0	; MEM_0: number stored here is in 16 bit integer format (pitch)
					;  0, 0/FF (pos/neg), LSB, MSB, 0
					;  LSB/MSB is stored in two's complement
					; In the following, the pitch is checked if it is in the range -128<=p<=127
		LD	A,(HL)		; First byte must be zero, otherwise
		AND	A		; error in integer conversion
		JR	NZ,REPORT_B	; to REPORT_B

		INC	HL
		LD	C,(HL)		; C = pos/neg flag = 0/FF
		INC	HL
		LD	B,(HL)		; B = LSB, two's complement
		LD	A,B
		RLA
		SBC	A,A		; A = 0/FF if B is pos/neg
		CP	C		; must be the same as C if the pitch is -128<=p<=127
		JR	NZ,REPORT_B	; if no, error REPORT_B

		INC	HL		; if -128<=p<=127, MSB will be 0/FF if B is pos/neg
		CP	(HL)		; verify this
		JR	NZ,REPORT_B	; if no, error REPORT_B
					; now we know -128<=p<=127
		LD	A,B		; A = pitch + 60
		ADD	A,$3C		; if -60<=pitch<=67,
		JP	P,BE_I_OK	; goto BE_I_OK

		JP	PO,REPORT_B	; if pitch <= 67 goto REPORT_B
					; lower bound of pitch set at -60

					;;;$0425; here, -60<=pitch<=127
					; 	        and A=pitch+60 -> 0<=A<=187

BE_I_OK:	LD	B,$FA		; 6 octaves below middle C

					;;;$0427				; A=# semitones above 5 octaves below middle C
BE_OCTAVE:	INC	B		; increment octave
		SUB	$0C		; 12 semitones = one octave
		JR	NC,BE_OCTAVE	; to BE_OCTAVE

		ADD	A,$0C		; A = # semitones above C (0-11)
		PUSH	BC		; B = octave displacement from middle C, 2's complement: -5<=B<=10
		LD	HL,SEMI_TONE	; Address: SEMI_TONE
		CALL	LOC_MEM		; routine LOC_MEM
					;  HL = 5*A + $046E
		CALL	STACK_NUM	; routine STACK_NUM
					;  read FP value (freq) from semitone table (HL) and push onto calc stack

		RST	28H		;; FP_CALC
		DEFB	$04		;;MULTIPLY	mult freq by 1 + 0.0576 * fraction_part(pitch) stacked earlier
					;;		thus taking into account fractional part of pitch.
					;;		the number 0.0576*frequency is the distance in Hz to the next
					;;		note (verify with the frequencies recorded in the semitone
					;;		table below) so that the fraction_part of the pitch does
					;;		indeed represent a fractional distance to the next note.
		DEFB	$38		;;END_CALC	HL points to first byte of fp num on stack = middle frequency to generate

		POP	AF		; A = octave displacement from middle C, 2's complement: -5<=A<=10
		ADD	A,(HL)		; increase exponent by A (equivalent to multiplying by 2^A)
		LD	(HL),A
		RST	28H		;; FP_CALC
		DEFB	$C0		;;st-mem-0		; store frequency in memory 0
		DEFB	$02		;;DELETE		; remove from calc stack
		DEFB	$31		;;DUPLICATE		; duplicate duration (seconds)
		DEFB	$38		;;END_CALC

		CALL	FIND_INT1	; routine FIND_INT1	; FP duration to A
		CP	$0B		; if dur > 10 seconds,
		JR	NC,REPORT_B	; goto REPORT_B

		;;; The following calculation finds the tone period for HL and the cycle count
		;;; for DE expected in the BEEPER subroutine.  From the example in the BEEPER comments,
		;;;
		;;; HL = ((fCPU / f) - 236) / 8 = fCPU/8/f - 236/8 = 437500/f -29.5
		;;; DE = duration * frequency - 1
		;;;
		;;; Note the different constant (30.125) used in the calculation of HL
		;;; below.  This is probably an error.

		RST	28H		;; FP_CALC
		DEFB	$E0		;;get-mem-0			; push frequency
		DEFB	$04		;;MULTIPLY			; result1: #cycles = duration * frequency
		DEFB	$E0		;;get-mem-0			; push frequency
		DEFB	$34		;;STK_DATA			; push constant
		DEFB	$80		;;Exponent $93, Bytes: 3	; constant = 437500
		DEFB	$43,$55,$9F,$80 ;;($55,$9F,$80,$00)
		DEFB	$01		;;EXCHANGE			; frequency on top
		DEFB	$05		;;DIVISION			; 437500 / frequency
		DEFB	$34		;;STK_DATA			; push constant
		DEFB	$35		;;Exponent: $85, Bytes: 1	; constant = 30.125
		DEFB	$71		;;($71,$00,$00,$00)
		DEFB	$03		;;SUBTRACT			; result2: tone_period(HL) = 437500 / freq - 30.125
		DEFB	$38		;;END_CALC

		CALL	FIND_INT2	; routine FIND_INT2
		PUSH	BC		; BC = tone_period(HL)
		CALL	FIND_INT2	; routine FIND_INT2, BC = #cycles to generate
		POP	HL		; HL = tone period
		LD	D,B
		LD	E,C		; DE = #cycles
		LD	A,D
		OR	E
		RET	Z		; if duration = 0, skip BEEP and avoid 65536 cycle
					; boondoggle that would occur next
		DEC	DE		; DE = #cycles - 1
		JP	BEEPER		; to BEEPER

					;;;$046C
REPORT_B:	RST	08H		; ERROR_1
		DEFB	$0A		; Error Report: Integer out of range



;----------------
; Semi-tone table
;----------------
;
; Holds frequencies corresponding to semitones in middle octave.
; To move n octaves higher or lower, frequencies are multiplied by 2^n.

;;;$046E                five byte fp              decimal freq          note (middle)
SEMI_TONE:	DEFB	$89, $02, $D0, $12, $86;  261.625565290	        C
		DEFB	$89, $0A, $97, $60, $75;  277.182631135	        C#
		DEFB	$89, $12, $D5, $17, $1F;  293.664768100	        D
		DEFB	$89, $1B, $90, $41, $02;  311.126983881	        D#
		DEFB	$89, $24, $D0, $53, $CA;  329.627557039	        E
		DEFB	$89, $2E, $9D, $36, $B1;  349.228231549	        F
		DEFB	$89, $38, $FF, $49, $3E;  369.994422674	        F#
		DEFB	$89, $43, $FF, $6A, $73;  391.995436072	        G
		DEFB	$89, $4F, $A7, $00, $54;  415.304697513	        G#
		DEFB	$89, $5C, $00, $00, $00;  440.000000000	        A
		DEFB	$89, $69, $14, $F6, $24;  466.163761616	        A#
		DEFB	$89, $76, $F1, $10, $05;  493.883301378	        B


;****************************************
;** Part 4. CASSETTE HANDLING ROUTINES **
;****************************************

; These routines begin with the service routines followed by a single
; command entry point.
; The first of these service routines is a curiosity.

;------------------
; ZX81_NAME routine
;------------------
; This routine fetches a filename in ZX81 format.
; and is not used by the cassette handling routines in this ROM.

					;;;$04AA
ZX81_NAME:	CALL	SCANNING	; routine SCANNING to evaluate expression.
		LD	A,(FLAGS)	; fetch system variable FLAGS.
		ADD	A,A		; test bit 7 - syntax, bit 6 - result type.
		JP	M,REPORT_C	; to REPORT_C if not string result
					; 'Nonsense in Basic'.
		POP	HL		; drop return address.
		RET	NC		; return early if checking syntax.

		PUSH	HL		; re-save return address.
		CALL	STK_FETCH	; routine STK_FETCH fetches string parameters.
		LD	H,D		; transfer start of filename
		LD	L,E		; to the HL register.
		DEC	C		; adjust to point to last character and
		RET	M		; return if the null string.
					; or multiple of 256!
		ADD	HL,BC		; find last character of the filename.
					; and also clear carry.
		SET	7,(HL)		; invert it.
		RET			; return.

; =========================================
;
; PORT 254 ($FE)
;
;                      spk mic { border  }  
;          ___ ___ ___ ___ ___ ___ ___ ___ 
; PORT    |   |   |   |   |   |   |   |   |
; 254     |   |   |   |   |   |   |   |   |
; $FE     |___|___|___|___|___|___|___|___|
;           7   6   5   4   3   2   1   0
;

;-----------------------------------
; Save header and program/data bytes
;-----------------------------------
; This routine saves a section of data. It is called from SA-CTRL to save the
; seventeen bytes of header data. It is also the exit route from that routine
; when it is set up to save the actual data.
; On entry -
; HL points to start of data.
; IX points to descriptor.
; The accumulator is set to  $00 for a header, $FF for data.

					;;;$04C2
SA_BYTES:	LD	HL,SA_LD_RET	; address: SA_LD_RET
		PUSH	HL		; is pushed as common exit route.
					; however there is only one non-terminal exit point.
		LD	HL,$1F80	; a timing constant H=$1F, L=$80
					; inner and outer loop counters
					; a five second lead-in is used for a header.
		BIT	7,A		; test one bit of accumulator.
					; (AND A ?)
		JR	Z,SA_FLAG	; skip to SA_FLAG if a header is being saved.

					; else is data bytes and a shorter lead-in is used.

		LD	HL,$0C98	; another timing value H=$0C, L=$98.
					; a two second lead-in is used for the data.

					;;;$04D0
SA_FLAG:	EX	AF,AF'		; save flag
		INC	DE		; increase length by one.
		DEC	IX		; decrease start.
		DI			; disable interrupts
		LD	A,$02		; select red for border, microphone bit on.
		LD	B,A		; also does as an initial slight counter value.

					;;;$04D8
SA_LEADER:	DJNZ	SA_LEADER	; self loop to SA_LEADER for delay.
					; after initial loop, count is $A4 (or $A3)
		OUT	($FE),A		; output byte $02/$0D to tape port.
		XOR	$0F		; switch from RED (mic on) to CYAN (mic off).
		LD	B,$A4		; hold count. also timed instruction.
		DEC	L		; originally $80 or $98.
					; but subsequently cycles 256 times.
		JR	NZ,SA_LEADER	; back to SA_LEADER until L is zero.

					; the outer loop is counted by H

		DEC	B		; decrement count
		DEC	H		; originally  twelve or thirty-one.
		JP	P,SA_LEADER	; back to SA_LEADER until H becomes $FF

					; now send a synch pulse. At this stage mic is off and A holds value
					; for mic on.
					; A synch pulse is much shorter than the steady pulses of the lead-in.

		LD	B,$2F		; another short timed delay.

					;;;$04EA
SA_SYNC_1:	DJNZ	SA_SYNC_1	; self loop to SA_SYNC_1
		OUT	($FE),A		; switch to mic on and red.
		LD	A,$0D		; prepare mic off - cyan
		LD	B,$37		; another short timed delay.

					;;;$04F2
SA_SYNC_2:	DJNZ	SA_SYNC_2	; self loop to SA_SYNC_2
		OUT	($FE),A		; output mic off, cyan border.
		LD	BC,$3B0E	; B=$3B time(*), C=$0E, YELLOW, MIC OFF.
		EX	AF,AF'		; restore saved flag
					; which is 1st byte to be saved.
		LD	L,A		; and transfer to L.
					; the initial parity is A, $FF or $00.
		JP	SA_START	; jump forward to SA_START     ->
					; the mid entry point of loop.

					; -------------------------
					; During the save loop a parity byte is maintained in H.
					; the save loop begins by testing if reduced length is zero and if so
					; the final parity byte is saved reducing count to $FFFF.

					;;;$04FE
SA_LOOP:	LD	A,D		; fetch high byte
		OR	E		; test against low byte.
		JR	Z,SA_PARITY	; forward to SA_PARITY if zero.

		LD	L,(IX+$00)	; load currently addressed byte to L.

					;;;$0505
SA_LOOP_P:	LD	A,H		; fetch parity byte.
		XOR	L		; exclusive or with new byte.

					; -> the mid entry point of loop.

					;;;$0507
SA_START:	LD	H,A		; put parity byte in H.
		LD	A,$01		; prepare blue, mic=on.
		SCF			; set carry flag ready to rotate in.
		JP	SA_8_BITS	; jump forward to SA_8_BITS    -8->

					;;;$050E
SA_PARITY:	LD	L,H		; transfer the running parity byte to L and
		JR	SA_LOOP_P	; back to SA_LOOP_P 
					; to output that byte before quitting normally.

					;--------------------------
					; entry point to save yellow part of bit.
					; a bit consists of a period with mic on and blue border followed by 
					; a period of mic off with yellow border. 
					; Note. since the DJNZ instruction does not affect flags, the zero flag is used
					; to indicate which of the two passes is in effect and the carry maintains the
					; state of the bit to be saved.

					;;;$0511
SA_BIT_2:	LD	A,C		; fetch 'mic on and yellow' which is  held permanently in C.
		BIT	7,B		; set the zero flag. B holds $3E.

					; entry point to save 1 entire bit. For first bit B holds $3B(*).
					; Carry is set if saved bit is 1. zero is reset NZ on entry.

					;;;$0514
SA_BIT_1:	DJNZ	SA_BIT_1	; self loop for delay to SA_BIT_1
		JR	NC,SA_OUT	; forward to SA_OUT if bit is 0.

					; but if bit is 1 then the mic state is held for longer.

		LD	B,$42		; set timed delay. (66 decimal)

					;;;$051A
SA_SET:		DJNZ	SA_SET		; self loop to SA_SET 
					; (roughly an extra 66*13 clock cycles)

					;;;$051C
SA_OUT:		OUT	($FE),A		; blue and mic on OR  yellow and mic off.
		LD	B,$3E		; set up delay
		JR	NZ,SA_BIT_2	; back to SA_BIT_2 if zero reset NZ (first pass)

					; proceed when the blue and yellow bands have been output.

		DEC	B		; change value $3E to $3D.
		XOR	A		; clear carry flag (ready to rotate in).
		INC	A		; reset zero flag ie. NZ.

					; -8-> 

					;;;$0525
SA_8_BITS:	RL	L		; rotate left through carry
					; C<76543210<C  
		JP	NZ,SA_BIT_1	; jump back to SA_BIT_1 
					; until all 8 bits done.

					; when the initial set carry is passed out again then a byte is complete.

		DEC	DE		; decrease length
		INC	IX		; increase byte pointer
		LD	B,$31		; set up timing.
		LD	A,$7F		; test the space key and
		IN	A,($FE)		; return to common exit (to restore border)
		RRA			; if a space is pressed
		RET	NC		; return to SA_LD_RET - - >

					; now test if byte counter has reached $FFFF.

		LD	A,D		; fetch high byte
		INC	A		; increment.
		JP	NZ,SA_LOOP	; jump to SA_LOOP if more bytes.

		LD	B,$3B		; a final delay. 

					;;;$053C
SA_DELAY:	DJNZ	SA_DELAY	; self loop to SA_DELAY
		RET			; return - - >

;---------------------------------------------------
; Reset border and check BREAK key for LOAD and SAVE
;---------------------------------------------------
; the address of this routine is pushed on the stack prior to any load/save
; operation and it handles normal completion with the restoration of the
; border and also abnormal termination when the break key, or to be more
; precise the space key is pressed during a tape operation.
; - - >

					;;;$053F
SA_LD_RET:	PUSH	AF		; preserve accumulator throughout.
		LD	A,(BORDCR)	; fetch border colour from BORDCR.
		AND	$38		; mask off paper bits.
		RRCA			; rotate
		RRCA			; to the
		RRCA			; range 0-7.
		OUT	($FE),A		; change the border colour.
		LD	A,$7F		; read from port address $7FFE the
		IN	A,($FE)		; row with the space key at outside.
 		RRA			; test for space key pressed.
		EI			; enable interrupts
		JR	C,SA_LD_END	; forward to SA_LD_END if not

					;;;$0552
REPORT_DA:	RST	08H		; ERROR_1
		DEFB	$0C		; Error Report: BREAK - CONT repeats

					;;;$0554
SA_LD_END:	POP	AF		; restore the accumulator.
		RET			; return.

;-------------------------------------
; Load header or block of information
;-------------------------------------
; This routine is used to load bytes and on entry A is set to $00 for a 
; header or to $FF for data.  IX points to the start of receiving location 
; and DE holds the length of bytes to be loaded. If, on entry the carry flag 
; is set then data is loaded, if reset then it is verified.

					;;;$0556
LD_BYTES:	INC	D		; reset the zero flag without disturbing carry.
		EX	AF,AF'		; preserve entry flags.
		DEC	D		; restore high byte of length.
		DI			; disable interrupts
		LD	A,$0F		; make the border white and mic off.
		OUT	($FE),A		; output to port.
		LD	HL,SA_LD_RET	; Address: SA_LD_RET
		PUSH	HL		; is saved on stack as terminating routine.

					; the reading of the EAR bit (D6) will always be preceded by a test of the 
					; space key (D0), so store the initial post-test state.

		IN	A,($FE)		; read the ear state - bit 6.
		RRA			; rotate to bit 5.
		AND	$20		; isolate this bit.
		OR	$02		; combine with red border colour.
		LD	C,A		; and store initial state long-term in C.
		CP	A		; set the zero flag.
 
					;;;$056B
LD_BREAK:	RET	NZ		; return if at any time space is pressed.

					;;;$056C
LD_START:	CALL	LD_EDGE_1	; routine LD_EDGE_1
		JR	NC,LD_BREAK	; back to LD_BREAK with time out and no
					; edge present on tape.

					; but continue when a transition is found on tape.

		LD	HL,$0415	; set up 16-bit outer loop counter for 
					; approx 1 second delay.

					;;;$0574
LD_WAIT:	DJNZ	LD_WAIT		; self loop to LD_WAIT (for 256 times)
		DEC	HL		; decrease outer loop counter.
		LD	A,H		; test for
		OR	L		; zero.
		JR	NZ,LD_WAIT	; back to LD_WAIT, if not zero, with zero in B.

					; continue after delay with H holding zero and B also.
					; sample 256 edges to check that we are in the middle of a lead-in section. 

		CALL	LD_EDGE_2	; routine LD_EDGE_2
		JR	NC,LD_BREAK	; back to LD_BREAK
					; if no edges at all.

					;;;$0580
LD_LEADER:	LD	B,$9C		; set timing value.
		CALL	LD_EDGE_2	; routine LD_EDGE_2
		JR	NC,LD_BREAK	; back to LD_BREAK if time-out

		LD	A,$C6		; two edges must be spaced apart.
		CP	B		; compare
		JR	NC,LD_START	; back to LD_START if too close together for a 
					; lead-in.
		INC	H		; proceed to test 256 edged sample.
		JR	NZ,LD_LEADER	; back to LD_LEADER while more to do.

					; sample indicates we are in the middle of a two or five second lead-in.
					; Now test every edge looking for the terminal synch signal.

					;;;$058F
LD_SYNC:	LD	B,$C9		; initial timing value in B.
		CALL	LD_EDGE_1	; routine LD_EDGE_1
		JR	NC,LD_BREAK	; back to LD_BREAK with time-out.

		LD	A,B		; fetch augmented timing value from B.
		CP	$D4		; compare 
		JR	NC,LD_SYNC	; back to LD_SYNC if gap too big, that is,
					; a normal lead-in edge gap.

					; but a short gap will be the synch pulse.
					; in which case another edge should appear before B rises to $FF

		CALL	LD_EDGE_1	; routine LD_EDGE_1
		RET	NC		; return with time-out.

					; proceed when the synch at the end of the lead-in is found.
					; We are about to load data so change the border colours.

		LD	A,C		; fetch long-term mask from C
		XOR	$03		; and make blue/yellow.
		LD	C,A		; store the new long-term byte.
		LD	H,$00		; set up parity byte as zero.
		LD	B,$B0		; timing.
		JR	LD_MARKER	; forward to LD_MARKER 
					; the loop mid entry point with the alternate 
					; zero flag reset to indicate first byte 
					; is discarded.

					; the loading loop loads each byte and is entered at the mid point.

					;;;$05A9
LD_LOOP:	EX	AF,AF'		; restore entry flags and type in A.
		JR	NZ,LD_FLAG	; forward to LD_FLAG if awaiting initial flag
					; which is to be discarded.
		JR	NC,LD_VERIFY	; forward to LD_VERIFY if not to be loaded.

		LD	(IX+$00),L	; place loaded byte at memory location.
		JR	LD_NEXT		; forward to LD_NEXT

					;;;$05B3
LD_FLAG:	RL	C		; preserve carry (verify) flag in long-term
					; state byte. Bit 7 can be lost.
		XOR	L		; compare type in A with first byte in L.
		RET	NZ		; return if no match e.g. CODE vs DATA.

					; continue when data type matches.

		LD	A,C		; fetch byte with stored carry
		RRA			; rotate it to carry flag again
		LD	C,A		; restore long-term port state.
		INC	DE		; increment length ??
		JR	LD_DEC		; forward to LD_DEC.
					; but why not to location after ?

					; for verification the byte read from tape is compared with that in memory.

					;;;$05BD
LD_VERIFY:	LD	A,(IX+$00)	; fetch byte from memory.
		XOR	L		; compare with that on tape
		RET	NZ		; return if not zero. 

					;;;$05C2
LD_NEXT:	INC	IX		; increment byte pointer.

					;;;$05C4
LD_DEC:		DEC	DE		; decrement length.
		EX	AF,AF'		; store the flags.
		LD	B,$B2		; timing.

					; when starting to read 8 bits the receiving byte is marked with bit at right.
					; when this is rotated out again then 8 bits have been read.

					;;;$05C8
LD_MARKER:	LD	L,$01		; initialize as %00000001

					;;;$05CA
LD_8_BITS:	CALL	LD_EDGE_2	; routine LD_EDGE_2 increments B relative to
					; gap between 2 edges.
		RET	NC		; return with time-out.

		LD	A,$CB		; the comparison byte.
		CP	B		; compare to incremented value of B.
					; if B is higher then bit on tape was set.
					; if <= then bit on tape is reset. 

		RL	L		; rotate the carry bit into L.
		LD	B,$B0		; reset the B timer byte.
		JP	NC,LD_8_BITS	; jump back to LD_8_BITS

					; when carry set then marker bit has been passed out and byte is complete.

		LD	A,H		; fetch the running parity byte.
		XOR	L		; include the new byte.
		LD	H,A		; and store back in parity register.
		LD	A,D		; check length of
		OR	E		; expected bytes.
		JR	NZ,LD_LOOP	; back to LD_LOOP 
					; while there are more.

					; when all bytes loaded then parity byte should be zero.

		LD	A,H		; fetch parity byte.
		CP	$01		; set carry if zero.
		RET			; return
					; in no carry then error as checksum disagrees.

;--------------------------
; Check signal being loaded
;--------------------------
; An edge is a transition from one mic state to another.
; More specifically a change in bit 6 of value input from port $FE.
; Graphically it is a change of border colour, say, blue to yellow.
; The first entry point looks for two adjacent edges. The second entry point
; is used to find a single edge.
; The B register holds a count, up to 256, within which the edge (or edges) 
; must be found. The gap between two edges will be more for a '1' than a '0'
; so the value of B denotes the state of the bit (two edges) read from tape.

					; ->

					;;;$05E3
LD_EDGE_2:	CALL	LD_EDGE_1	; call routine LD_EDGE_1 below.
		RET	NC		; return if space pressed or time-out.
					; else continue and look for another adjacent 
					; edge which together represent a bit on the 
					; tape.

					; -> 
					; this entry point is used to find a single edge from above but also 
					; when detecting a read-in signal on the tape.

					;;;$05E7
LD_EDGE_1:	LD	A,$16		; a delay value of twenty two.

					;;;$05E9
LD_DELAY:	DEC	A		; decrement counter
		JR	NZ,LD_DELAY	; loop back to LD_DELAY 22 times.

		AND	A		; clear carry.

					;;;$05ED
LD_SAMPLE:	INC	B		; increment the time-out counter.
		RET	Z		; return with failure when $FF passed.

		LD	A,$7F		; prepare to read keyboard and EAR port
		IN	A,($FE)		; row $7FFE. bit 6 is EAR, bit 0 is SPACE key.
		RRA			; test outer key the space. (bit 6 moves to 5)
		RET	NC		; return if space pressed.  >>>

		XOR	C		; compare with initial long-term state.
		AND	$20		; isolate bit 5
		JR	Z,LD_SAMPLE	; back to LD_SAMPLE if no edge.

					; but an edge, a transition of the EAR bit, has been found so switch the
					; long-term comparison byte containing both border colour and EAR bit. 

		LD	A,C		; fetch comparison value.
		CPL			; switch the bits
		LD	C,A		; and put back in C for long-term.
		AND	$07		; isolate new colour bits.
		OR	$08		; set bit 3 - MIC off.
		OUT	($FE),A		; send to port to effect change of colour. 
		SCF			; set carry flag signalling edge found within
					; time allowed.
		RET			; return.

;----------------------------------
; Entry point for all tape commands
;----------------------------------
; This is the single entry point for the four tape commands.
; The routine first determines in what context it has been called by examining
; the low byte of the Syntax table entry which was stored in T_ADDR.
; Subtracting $EO (the present arrangement) gives a value of
; $00 - SAVE
; $01 - LOAD
; $02 - VERIFY
; $03 - MERGE
; As with all commands the address STMT_RET is on the stack.

					;;;$0605
SAVE_ETC:	POP	AF		; discard address STMT_RET.
		LD	A,(T_ADDR)	; fetch T_ADDR

					; Now reduce the low byte of the Syntax table entry to give command.

		SUB	$E0		; subtract the known offset - giving 0 for SAVE,
					; 1 for LOAD, 2 for VERIFY and 3 for MERGE
		LD	(T_ADDR),A	; and put back in T_ADDR as 0,1,2, or 3
					; for future reference.
		CALL	EXPT_EXP	; routine EXPT_EXP checks that a string
					; expression follows and stacks the
					; parameters in run-time.
		CALL	SYNTAX_Z	; routine SYNTAX_Z
		JR	Z,SA_DATA	; forward to SA_DATA if checking syntax.

		LD	BC,$0011	; presume seventeen bytes for a header.
		LD	A,(T_ADDR)	; fetch command from T_ADDR.
		AND	A		; test for zero - SAVE.
		JR	Z,SA_SPACE	; forward to SA_SPACE if so.

		LD	C,$22		; else double length to thirty four.

					;;;$0621
SA_SPACE:	RST	30H		; BC_SPACES creates 17/34 bytes in workspace.
		PUSH	DE		; transfer the start of new space to
		POP	IX		; the available index register.

					; ten spaces are required for the default filename but it is simpler to
					; overwrite the first file-type indicator byte as well.

		LD	B,$0B		; set counter to eleven.
		LD	A,$20		; prepare a space.

					;;;$0629
SA_BLANK:	LD	(DE),A		; set workspace location to space.
		INC	DE		; next location.
		DJNZ	SA_BLANK	; loop back to SA_BLANK till all eleven done.
		LD	(IX+$01),$FF	; set first byte of ten character filename
					; to $FF as a default to signal null string.
		CALL	STK_FETCH	; routine STK_FETCH fetches the filename
					; parameters from the calculator stack.
					; length of string in BC.
					; start of string in DE.
		LD	HL,$FFF6	; prepare the value minus ten.
		DEC	BC		; decrement length.
					; ten becomes nine, zero becomes $FFFF.
		ADD	HL,BC		; trial addition.
		INC	BC		; restore true length.
		JR	NC,SA_NAME	; forward to SA_NAME if length is one to ten.

					; the filename is more than ten characters in length or the null string.

		LD	A,(T_ADDR)	; fetch command from T_ADDR.
		AND	A		; test for zero - SAVE.
		JR	NZ,SA_NULL	; forward to SA_NULL if not the SAVE command.

					; but no more than ten characters are allowed for SAVE.
					; The first ten characters of any other command parameter are acceptable.
					; Weird, but necessary, if saving to sectors.
					; Note. the golden rule that there are no restriction on anything is broken.

					;;;$0642
REPORT_FA:	RST	08H		; ERROR_1
		DEFB	$0E		; Error Report: Invalid file name

					; continue with LOAD, MERGE, VERIFY and also SAVE within ten character limit.

					;;;$0644
SA_NULL:	LD	A,B		; test length of filename
		OR	C		; for zero.
		JR	Z,SA_DATA	; forward to SA_DATA if so using the 255 
					; indicator followed by spaces.
		LD	BC,$000A	; else trim length to ten.

					; other paths rejoin here with BC holding length in range 1 - 10.

					;;;$064B
SA_NAME:	PUSH	IX		; push start of file descriptor.
		POP	HL		; and pop into HL.
		INC	HL		; HL now addresses first byte of filename.
		EX	DE,HL		; transfer destination address to DE, start
					; of string in command to HL.
		LDIR			; copy up to ten bytes
					; if less than ten then trailing spaces follow.

					; the case for the null string rejoins here.

					;;;$0652
SA_DATA:	RST	18H		; GET_CHAR
		CP	$E4		; is character after filename the token 'DATA' ?
		JR	NZ,SA_SCR	; forward to SA_SCR to consider SCREEN$ if not.

					; continue to consider DATA.

		LD	A,(T_ADDR)	; fetch command from T_ADDR
		CP	$03		; is it 'VERIFY' ?
		JP	Z,REPORT_C	; jump forward to REPORT_C if so.
					; 'Nonsense in basic'
					; VERIFY "d" DATA is not allowed.

					; continue with SAVE, LOAD, MERGE of DATA.

		RST	20H		; NEXT_CHAR
		CALL	LOOK_VARS	; routine LOOK_VARS searches variables area
					; returning with carry reset if found or
					; checking syntax.
		SET	7,C		; this converts a simple string to a 
					; string array. The test for an array or string
					; comes later.
		JR	NC,SA_V_OLD	; forward to SA_V_OLD if variable found.

		LD	HL,$0000	; set destination to zero as not fixed.
		LD	A,(T_ADDR)	; fetch command from T_ADDR
		DEC	A		; test for 1 - LOAD
		JR	Z,SA_V_NEW	; forward to SA_V_NEW with LOAD DATA.
					; to load a new array.

					; otherwise the variable was not found in run-time with SAVE/MERGE.

					;;;$0670
REPORT_2A:	RST	08H		; ERROR_1
		DEFB	$01		; Error Report: Variable not found

					; continue with SAVE/LOAD  DATA

					;;;$0672
SA_V_OLD:	JP	NZ,REPORT_C	; to REPORT_C if not an array variable.
					; or erroneously a simple string.
					; 'Nonsense in basic'


		CALL	SYNTAX_Z	; routine SYNTAX_Z
		JR	Z,SA_DATA_1	; forward to SA_DATA_1 if checking syntax.

		INC	HL		; step past single character variable name.
		LD	A,(HL)		; fetch low byte of length.
		LD	(IX+$0B),A	; place in descriptor.
		INC	HL		; point to high byte.
		LD	A,(HL)		; and transfer that
		LD	(IX+$0C),A	; to descriptor.
		INC	HL		; increase pointer within variable.

					;;;$0685
SA_V_NEW:	LD	(IX+$0E),C	; place character array name in  header.
		LD	A,$01		; default to type numeric.
		BIT	6,C		; test result from LOOK_VARS.
		JR	Z,SA_V_TYPE	; forward to SA_V_TYPE if numeric.

		INC	A		; set type to 2 - string array.

					;;;$068F
SA_V_TYPE:	LD	(IX+$00),A	; place type 0, 1 or 2 in descriptor.

					;;;$0692
SA_DATA_1:	EX	DE,HL		; save var pointer in DE

		RST	20H		; NEXT_CHAR
		CP	$29		; is character ')' ?
		JR	NZ,SA_V_OLD	; back if not to SA_V_OLD to report
					; 'Nonsense in basic'

		RST	20H		; NEXT_CHAR advances character address.
		CALL	CHECK_END	; routine CHECK_END errors if not end of the statement.
		EX	DE,HL		; bring back variables data pointer.
		JP	SA_ALL		; jump forward to SA_ALL

					; the branch was here to consider a 'SCREEN$', the display file.

					;;;$06A0
SA_SCR: 	CP	$AA		; is character the token 'SCREEN$' ?
		JR	NZ,SA_CODE	; forward to SA_CODE if not.

		LD	A,(T_ADDR)	; fetch command from T_ADDR
		CP	$03		; is it MERGE ?
		JP	Z,REPORT_C	; jump to REPORT_C if so.
					; 'Nonsense in basic'

					; continue with SAVE/LOAD/VERIFY SCREEN$.

		RST	20H		; NEXT_CHAR
		CALL	CHECK_END	; routine CHECK_END errors if not at end of
					; statement.

					; continue in runtime.

		LD	(IX+$0B),$00	; set descriptor length
		LD	(IX+$0C),$1B	; to $1b00 to include bitmaps and attributes.
		LD	HL,$4000	; set start to display file start.
		LD	(IX+$0D),L	; place start in
		LD	(IX+$0E),H	; the descriptor.
		JR	SA_TYPE_3	; forward to SA_TYPE_3

					; the branch was here to consider CODE.

					;;;$06C3
SA_CODE:	CP	$AF		; is character the token 'CODE' ?
		JR	NZ,SA_LINE	; forward if not to SA_LINE to consider an
					; auto-started basic program.
		LD	A,(T_ADDR)	; fetch command from T_ADDR
		CP	$03		; is it MERGE ?
		JP	Z,REPORT_C	; jump forward to REPORT_C if so.
					; 'Nonsense in basic'

		RST	20H		; NEXT_CHAR advances character address.
		CALL	PR_ST_END	; routine PR_ST_END checks if a carriage
					; return or ':' follows.
		JR	NZ,SA_CODE_1	; forward to SA_CODE_1 if there are parameters.

		LD	A,(T_ADDR)	; else fetch the command from T_ADDR.
		AND	A		; test for zero - SAVE without a specification.
		JP	Z,REPORT_C	; jump to REPORT_C if so.
					; 'Nonsense in basic'

					; for LOAD/VERIFY put zero on stack to signify handle at location saved from.

		CALL	USE_ZERO	; routine USE_ZERO
		JR	SA_CODE_2	; forward to SA_CODE_2

					; if there are more characters after CODE expect start and possibly length.

					;;;$06E1
SA_CODE_1:	CALL	EXPT_1NUM	; routine EXPT_1NUM checks for numeric
					; expression and stacks it in run-time.
		RST	18H		; GET_CHAR
		CP	$2C		; does a comma follow ?
		JR	Z,SA_CODE_3	; forward if so to SA_CODE_3

					; else allow saved code to be loaded to a specified address.

		LD	A,(T_ADDR)	; fetch command from T_ADDR.
		AND	A		; is the command SAVE which requires length ?
		JP	Z,REPORT_C	; jump to REPORT_C if so.
					; 'Nonsense in basic'

					; the command LOAD code may rejoin here with zero stacked as start.

					;;;$06F0
SA_CODE_2:	CALL	USE_ZERO	; routine USE_ZERO stacks zero for length.
		JR	SA_CODE_4	; forward to SA_CODE_4

					; the branch was here with SAVE CODE start, 

					;;;$06F5
SA_CODE_3:	RST	20H		; NEXT_CHAR advances character address.
		CALL	EXPT_1NUM	; routine EXPT_1NUM checks for expression
					; and stacks in run-time.

					; paths converge here and nothing must follow.

					;;;$06F9
SA_CODE_4:	CALL	CHECK_END	; routine CHECK_END errors with extraneous
					; characters and quits if checking syntax.

					; in run-time there are two 16-bit parameters on the calculator stack.

		CALL	FIND_INT2	; routine FIND_INT2 gets length.
		LD	(IX+$0B),C	; place length 
		LD	(IX+$0C),B	; in descriptor.
		CALL	FIND_INT2	; routine FIND_INT2 gets start.
		LD	(IX+$0D),C	; place start
		LD	(IX+$0E),B	; in descriptor.
		LD	H,B		; transfer the
		LD	L,C		; start to HL also.

					;;;$0710
SA_TYPE_3:	LD	(IX+$00),$03	; place type 3 - code in descriptor. 
		JR	SA_ALL		; forward to SA_ALL.


					; the branch was here with basic to consider an optional auto-start line number.

					;;;$0716
SA_LINE:	CP	$CA		; is character the token 'LINE' ?
		JR	Z,SA_LINE_1	; forward to SA_LINE_1 if so.

					; else all possibilities have been considered and nothing must follow.

		CALL	CHECK_END	; routine CHECK_END

					; continue in run-time to save basic without auto-start.

		LD	(IX+$0E),$80	; place high line number in descriptor to disable auto-start.
		JR	SA_TYPE_0	; forward to SA_TYPE_0 to save program.

					; the branch was here to consider auto-start.

					;;;$0723
SA_LINE_1:	LD	A,(T_ADDR)	; fetch command from T_ADDR
		AND	A		; test for SAVE.
		JP	NZ,REPORT_C	; jump forward to REPORT_C with anything else.
					; 'Nonsense in basic' 
		RST	20H		; NEXT_CHAR
		CALL	EXPT_1NUM	; routine EXPT_1NUM checks for numeric
					; expression and stacks in run-time.
		CALL	CHECK_END	; routine CHECK_END quits if syntax path.
		CALL	FIND_INT2	; routine FIND_INT2 fetches the numeric expression.
		LD	(IX+$0D),C	; place the auto-start
		LD	(IX+$0E),B	; line number in the descriptor.

					; Note. this isn't checked, but is subsequently handled by the system.
					; If the user typed 40000 instead of 4000 then it won't auto-start
					; at line 4000, or indeed, at all.

					; continue to save program and any variables.

					;;;$073A
SA_TYPE_0:	LD	(IX+$00),$00	; place type zero - program in descriptor.
		LD	HL,(E_LINE)	; fetch E_LINE to HL.
		LD	DE,(PROG)	; fetch PROG to DE.
		SCF			; set carry flag to calculate from end of
					; variables E_LINE -1.
		SBC	HL,DE		; subtract to give total length.
		LD	(IX+$0B),L	; place total length
		LD	(IX+$0C),H	; in descriptor.
		LD	HL,(VARS)	; load HL from system variable VARS
		SBC	HL,DE		; subtract to give program length.
		LD	(IX+$0F),L	; place length of program
		LD	(IX+$10),H	; in the descriptor.
		EX	DE,HL		; start to HL, length to DE.

					;;;$075A
SA_ALL:		LD	A,(T_ADDR)	; fetch command from T_ADDR
		AND	A		; test for zero - SAVE.
		JP	Z,SA_CONTRL	; jump forward to SA_CONTRL with SAVE  ->

					; continue with LOAD, MERGE and VERIFY.

		PUSH	HL		; save start.
		LD	BC,$0011	; prepare to add seventeen
		ADD	IX,BC		; to point IX at second descriptor.

					;;;$0767
LD_LOOK_H:	PUSH	IX		; save IX
		LD	DE,$0011	; seventeen bytes
		XOR	A		; reset zero flag
		SCF			; set carry flag
		CALL	LD_BYTES	; routine LD_BYTES loads a header from tape
					; to second descriptor.
		POP	IX		; restore IX.
		JR	NC,LD_LOOK_H	; loop back to LD_LOOK_H until header found.

		LD	A,$FE		; select system channel 'S'
		CALL	CHAN_OPEN	; routine CHAN_OPEN opens it.
		LD	(IY+$52),$03	; set SCR_CT to 3 lines.
		LD	C,$80		; C has bit 7 set to indicate type mismatch as
					; a default startpoint.
		LD	A,(IX+$00)	; fetch loaded header type to A
		CP	(IX-$11)	; compare with expected type.
		JR	NZ,LD_TYPE	; forward to LD_TYPE with mis-match.

		LD	C,$F6		; set C to minus ten - will count characters up to zero.

					;;;$078A
LD_TYPE:	CP	$04		; check if type in acceptable range 0 - 3.
		JR	NC,LD_LOOK_H	; back to LD_LOOK_H with 4 and over.

					; else A indicates type 0-3.

		LD	DE,TAPE_MSGS2	; address base of last 4 tape messages
		PUSH	BC		; save BC
		CALL	PO_MSG		; routine PO_MSG outputs relevant message.
					; Note. all messages have a leading newline.
		POP	BC		; restore BC
		PUSH	IX		; transfer IX,
		POP	DE		; the 2nd descriptor, to DE.
		LD	HL,$FFF0	; prepare minus seventeen.
		ADD	HL,DE		; add to point HL to 1st descriptor.
		LD	B,$0A		; the count will be ten characters for the filename.
		LD	A,(HL)		; fetch first character and test for 
		INC	A		; value 255.
		JR	NZ,LD_NAME	; forward to LD_NAME if not the wildcard.

					; but if it is the wildcard, then add ten to C which is minus ten for a type
					; match or -128 for a type mismatch. Although characters have to be counted
					; bit 7 of C will not alter from state set here.

		LD	A,C		; transfer $F6 or $80 to A
		ADD	A,B		; add $0A
		LD	C,A		; place result, zero or -118, in C.

					; At this point we have either a type mismatch, a wildcard match or ten
					; characters to be counted. The characters must be shown on the screen.

					;;;$07A6
LD_NAME:	INC	DE		; address next input character
		LD	A,(DE)		; fetch character
		CP	(HL)		; compare to expected
		INC	HL		; address next expected character
		JR	NZ,LD_CH_PR	; forward to LD_CH_PR with mismatch

		INC	C		; increment matched character count

					;;;$07AD
LD_CH_PR:	RST	10H		; PRINT_A prints character
		DJNZ	LD_NAME		; loop back to LD_NAME for ten characters.

					; if ten characters matched and the types previously matched then C will 
					; now hold zero.

		BIT	7,C		; test if all matched
		JR	NZ,LD_LOOK_H	; back to LD_LOOK_H if not

					; else print a terminal carriage return.

		LD	A,$0D		; prepare carriage return.
		RST	10H		; PRINT_A outputs it.

					; The various control routines for LOAD, VERIFY and MERGE are executed 
					; during the one-second gap following the header on tape.

		POP	HL		; restore xx
		LD	A,(IX+$00)	; fetch incoming type 
		CP	$03		; compare with CODE
		JR	Z,VR_CONTROL	; forward to VR_CONTROL if it is CODE.

					; type is a program or an array.

		LD	A,(T_ADDR)	; fetch command from T_ADDR
		DEC	A		; was it LOAD ?
		JP	Z,LD_CONTRL	; jump forward to LD_CONTRL if so to 
					; load BASIC or variables.
		CP	$02		; was command MERGE ?
		JP	Z,ME_CONTRL	; jump forward to ME_CONTRL if so.

					; else continue into VERIFY control routine to verify.

;----------------------
; Handle VERIFY control
;----------------------
; There are two branches to this routine.
; 1) From above to verify a program or array
; 2) from earlier with no carry to load or verify code.

					;;;$07CB
VR_CONTROL:	PUSH	HL		; save pointer to data.
		LD	L,(IX-$06)	; fetch length of old data 
		LD	H,(IX-$05)	; to HL.
		LD	E,(IX+$0B)	; fetch length of new data
		LD	D,(IX+$0C)	; to DE.
		LD	A,H		; check length of old
		OR	L		; for zero.
		JR	Z,VR_CONT_1	; forward to VR_CONT_1 if length unspecified
					; e.g LOAD "x" CODE

					; as opposed to, say, LOAD 'x' CODE 32768,300.

		SBC	HL,DE		; subtract the two lengths.
		JR	C,REPORT_R	; forward to REPORT_R if the length on tape is 
					; larger than that specified in command.
					; 'Tape loading error'

		JR	Z,VR_CONT_1	; forward to VR_CONT_1 if lengths match.

					; a length on tape shorter than expected is not allowed for CODE

		LD	A,(IX+$00)	; else fetch type from tape.
		CP	$03		; is it CODE ?
		JR	NZ,REPORT_R	; forward to REPORT_R if so
					; 'Tape loading error'

					;;;$07E9
VR_CONT_1:	POP	HL		; pop pointer to data
		LD	A,H		; test for zero
		OR	L		; e.g. LOAD 'x' CODE
		JR	NZ,VR_CONT_2	; forward to VR_CONT_2 if destination specified.

		LD	L,(IX+$0D)	; else use the destination in the header
		LD	H,(IX+$0E)	; and load code at address saved from.

					;;;$07F4
VR_CONT_2:	PUSH	HL		; push pointer to start of data block.
		POP	IX		; transfer to IX.
		LD	A,(T_ADDR)	; fetch reduced command from T_ADDR
		CP	$02		; is it VERIFY ?
		SCF			; prepare a set carry flag
		JR	NZ,VR_CONT_3	; skip to VR_CONT_3 if not

		AND	A		; clear carry flag for VERIFY so that 
					; data is not loaded.

					;;;$0800
VR_CONT_3:	LD	A,$FF		; signal data block to be loaded

;------------------
; Load a data block
;------------------
; This routine is called from 3 places other than above to load a data block.
; In all cases the accumulator is first set to $FF so the routine could be 
; called at the previous instruction.

					;;;$0802
LD_BLOCK:	CALL	LD_BYTES	; routine LD_BYTES
		RET	C		; return if successful.


					;;;$0806
REPORT_R:	RST	08H		; ERROR_1
		DEFB	$1A		; Error Report: Tape loading error

;--------------------
; Handle LOAD control
;--------------------
; This branch is taken when the command is LOAD with type 0, 1 or 2. 

					;;;$0808
LD_CONTRL:	LD	E,(IX+$0B)	; fetch length of found data block 
		LD	D,(IX+$0C)	; from 2nd descriptor.
		PUSH	HL		; save destination
		LD	A,H		; test for zero
		OR	L
		JR	NZ,LD_CONT_1	; forward if not to LD_CONT_1

		INC	DE		; increase length
		INC	DE		; for letter name
		INC	DE		; and 16-bit length
		EX	DE,HL		; length to HL, 
		JR	LD_CONT_2	; forward to LD_CONT_2

					;;;$0819
LD_CONT_1:	LD	L,(IX-$06)	; fetch length from 
		LD	H,(IX-$05)	; the first header.
		EX	DE,HL
		SCF			; set carry flag
		SBC	HL,DE
		JR	C,LD_DATA	; to LD_DATA

					;;;$0825
LD_CONT_2:	LD	DE,$0005	; allow overhead of five bytes.
		ADD	HL,DE		; add in the difference in data lengths.
		LD	B,H		; transfer to
		LD	C,L		; the BC register pair
		CALL	TEST_ROOM	; routine TEST_ROOM fails if not enough room.

					;;;$082E
LD_DATA:	POP	HL		; pop destination
		LD	A,(IX+$00)	; fetch type 0, 1 or 2.
		AND	A		; test for program and variables.
		JR	Z,LD_PROG	; forward if so to LD_PROG

					; the type is a numeric or string array.

		LD	A,H		; test the destination for zero
		OR	L		; indicating variable does not already exist.
		JR	Z,LD_DATA_1	; forward if so to LD_DATA_1

					; else the destination is the first dimension within the array structure

		DEC	HL		; address high byte of total length
		LD	B,(HL)		; transfer to B.
		DEC	HL		; address low byte of total length.
		LD	C,(HL)		; transfer to C.
		DEC	HL		; point to letter of variable.
		INC	BC		; adjust length to
		INC	BC		; include these
		INC	BC		; three bytes also.
		LD	(X_PTR),IX	; save header pointer in X_PTR.
		CALL	RECLAIM_2	; routine RECLAIM_2 reclaims the old variable
					; sliding workspace including the two headers downwards.
		LD	IX,(X_PTR)	; reload IX from X_PTR which will have been
					; adjusted down by POINTERS routine.

					;;;$084C
LD_DATA_1:	LD	HL,(E_LINE)	; address E_LINE
		DEC	HL		; now point to the $80 variables end-marker.
		LD	C,(IX+$0B)	; fetch new data length 
		LD	B,(IX+$0C)	; from 2nd header.
		PUSH	BC		; * save it.
		INC	BC		; adjust the 
		INC	BC		; length to include
		INC	BC		; letter name and total length.
		LD	A,(IX-$03)	; fetch letter name from old header.
		PUSH	AF		; preserve accumulator though not corrupted.
		CALL	MAKE_ROOM	; routine MAKE_ROOM creates space for variable
					; sliding workspace up. IX no longer addresses
					; anywhere meaningful.
		INC	HL		; point to first new location.
		POP	AF		; fetch back the letter name.
		LD	(HL),A		; place in first new location.
		POP	DE		; * pop the data length.
		INC	HL		; address 2nd location
		LD	(HL),E		; store low byte of length.
		INC	HL		; address next.
		LD	(HL),D		; store high byte.
		INC	HL		; address start of data.
		PUSH	HL		; transfer address
		POP	IX		; to IX register pair.
		SCF			; set carry flag indicating load not verify.
		LD	A,$FF		; signal data not header.
		JP	LD_BLOCK	; jump back to LD_BLOCK

					; the branch is here when a program as opposed to an array is to be loaded.

					;;;$0873
LD_PROG:	EX	DE,HL		; transfer dest to DE.
		LD	HL,(E_LINE)	; address E_LINE
		DEC	HL		; now variables end-marker.
		LD	(X_PTR),IX	; place the IX header pointer in X_PTR
		LD	C,(IX+$0B)	; get new length
		LD	B,(IX+$0C)	; from 2nd header
		PUSH	BC		; and save it.
		CALL	RECLAIM_1	; routine RECLAIM_1 reclaims program and vars.
					; adjusting X_PTR.
		POP	BC		; restore new length.
		PUSH	HL		; * save start
		PUSH	BC		; ** and length.
		CALL	MAKE_ROOM	; routine MAKE_ROOM creates the space.
		LD	IX,(X_PTR)	; reload IX from adjusted X_PTR
		INC	HL		; point to start of new area.
		LD	C,(IX+$0F)	; fetch length of BASIC on tape
		LD	B,(IX+$10)	; from 2nd descriptor
		ADD	HL,BC		; add to address the start of variables.
		LD	(VARS),HL	; set system variable VARS
		LD	H,(IX+$0E)	; fetch high byte of autostart line number.
		LD	A,H		; transfer to A
		AND	$C0		; test if greater than $3F.
		JR	NZ,LD_PROG_1	; forward to LD_PROG_1 if so with no autostart.

		LD	L,(IX+$0D)	; else fetch the low byte.
		LD	(NEWPPC),HL	; set sytem variable to line number NEWPPC
		LD	(IY+$0A),$00	; set statement NSPPC to zero.

					;;;$08AD
LD_PROG_1:	POP	DE		; ** pop the length
		POP	IX		; * and start.
		SCF			; set carry flag
		LD	A,$FF		; signal data as opposed to a header.
		JP	LD_BLOCK	; jump back to LD_BLOCK

;---------------------
; Handle MERGE control
;---------------------
; the branch was here to merge a program and it's variables or an array.

					;;;$08B6
ME_CONTRL:	LD	C,(IX+$0B)	; fetch length
		LD	B,(IX+$0C)	; of data block on tape.
		PUSH	BC		; save it.
		INC	BC		; one for the pot.
		RST	30H		; BC_SPACES creates room in workspace.
					; HL addresses last new location.
		LD	(HL),$80	; place end-marker at end.
		EX	DE,HL		; transfer first location to HL.
		POP	DE		; restore length to DE.
		PUSH	HL		; save start.
		PUSH	HL		; and transfer it
		POP	IX		; to IX register.
		SCF			; set carry flag to load data on tape.
		LD	A,$FF		; signal data not a header.
		CALL	LD_BLOCK	; routine LD_BLOCK loads to workspace.
		POP	HL		; restore first location in workspace to HL.
		LD	DE,(PROG)	; set DE from system variable PROG.

					; now enter a loop to merge the data block in workspace with the program and 
					; variables. 

					;;;$08D2
ME_NEW_LP:	LD	A,(HL)		; fetch next byte from workspace.
		AND	$C0		; compare with $3F.
		JR	NZ,ME_VAR_LP	; forward to ME_VAR_LP if a variable.

					; continue when HL addresses a Basic line number.

					;;;$08D7
ME_OLD_LP:	LD	A,(DE)		; fetch high byte from program area.
		INC	DE		; bump prog address.
		CP	(HL)		; compare with that in workspace.
		INC	HL		; bump workspace address.
		JR	NZ,ME_OLD_L1	; forward to ME_OLD_L1 if high bytes don't match

		LD	A,(DE)		; fetch the low byte of program line number.
		CP	(HL)		; compare with that in workspace.

					;;;$08DF
ME_OLD_L1:	DEC	DE		; point to start of
		DEC	HL		; respective lines again.
		JR	NC,ME_NEW_L2	; forward to ME_NEW_L2 if line number in 
					; workspace is less than or equal to current
					; program line as has to be added to program.
		PUSH	HL		; else save workspace pointer. 
		EX	DE,HL		; transfer prog pointer to HL
		CALL	NEXT_ONE	; routine NEXT_ONE finds next line in DE.
		POP	HL		; restore workspace pointer
		JR	ME_OLD_LP	; back to ME_OLD_LP until destination position 
					; in program area found.

					; the branch was here with an insertion or replacement point.

					;;;$08EB:
ME_NEW_L2:	CALL	ME_ENTER	; routine ME_ENTER enters the line
		JR	ME_NEW_LP	; loop back to ME_NEW_LP.

					; the branch was here when the location in workspace held a variable.

					;;;$08F0
ME_VAR_LP:	LD	A,(HL)		; fetch first byte of workspace variable.
		LD	C,A		; copy to C also.
		CP	$80		; is it the end-marker ?
		RET	Z		; return if so as complete.  >>>>>

		PUSH	HL		; save workspace area pointer.
		LD	HL,(VARS)	; load HL with VARS - start of variables area.

					;;;$08F9
ME_OLD_VP:	LD	A,(HL)		; fetch first byte.
		CP	$80		; is it the end-marker ?
		JR	Z,ME_VAR_L2	; forward if so to ME_VAR_L2 to add
					; variable at end of variables area.
		CP	C		; compare with variable in workspace area.
		JR	Z,ME_OLD_V2	; forward to ME_OLD_V2 if a match to replace.

					; else entire variables area has to be searched.

					;;;$0901
ME_OLD_V1:	PUSH	BC		; save character in C.
		CALL	NEXT_ONE	; routine NEXT_ONE gets following variable address in DE.
		POP	BC		; restore character in C
		EX	DE,HL		; transfer next address to HL.
		JR	ME_OLD_VP	; loop back to ME_OLD_VP

					; the branch was here when first characters of name matched. 

					;;;$0909
ME_OLD_V2:	AND	$E0		; keep bits 11100000
		CP	$A0		; compare   10100000 - a long-named variable.
		JR	NZ,ME_VAR_L1	; forward to ME_VAR_L1 if just one-character.

					; but long-named variables have to be matched character by character.

		POP	DE		; fetch workspace 1st character pointer
		PUSH	DE		; and save it on the stack again.
		PUSH	HL		; save variables area pointer on stack.

					;;;$0912
ME_OLD_V3:	INC	HL		; address next character in vars area.
		INC	DE		; address next character in workspace area.
		LD	A,(DE)		; fetch workspace character.
		CP	(HL)		; compare to variables character.
		JR	NZ,ME_OLD_V4	; forward to ME_OLD_V4 with a mismatch.

		RLA			; test if the terminal inverted character.
		JR	NC,ME_OLD_V3	; loop back to ME_OLD_V3 if more to test.

					; otherwise the long name matches in it's entirety.

		POP	HL		; restore pointer to first character of variable
		JR	ME_VAR_L1	; forward to ME_VAR_L1

					; the branch is here when two characters don't match

					;;;$091E
ME_OLD_V4:	POP	HL		; restore the prog/vars pointer.
		JR	ME_OLD_V1	; back to ME_OLD_V1 to resume search.

					; branch here when variable is to replace an existing one

					;;;$0921
ME_VAR_L1:	LD	A,$FF		; indicate a replacement.

					; this entry point is when A holds $80 indicating a new variable.

					;;;$0923
ME_VAR_L2:	POP	DE		; pop workspace pointer.
		EX	DE,HL		; now make HL workspace pointer, DE vars pointer
		INC	A		; zero flag set if replacement.
		SCF			; set carry flag indicating a variable not a program line.
		CALL	ME_ENTER	; routine ME_ENTER copies variable in.
		JR	ME_VAR_LP	; loop back to ME_VAR_LP

;-------------------------
; Merge a Line or Variable
;-------------------------
; A Basic line or variable is inserted at the current point. If the line numbers
; or variable names match (zero flag set) then a replacement takes place.

					;;;$092C
ME_ENTER:	JR	NZ,ME_ENT_1	; forward to ME_ENT_1 for insertion only.

					; but the program line or variable matches so old one is reclaimed.

		EX	AF,AF'		; save flag??
		LD	(X_PTR),HL	; preserve workspace pointer in dynamic X_PTR
		EX	DE,HL		; transfer program dest pointer to HL.
		CALL	NEXT_ONE	; routine NEXT_ONE finds following location
					; in program or variables area.
		CALL	RECLAIM_2	; routine RECLAIM_2 reclaims the space between.
		EX	DE,HL		; transfer program dest pointer back to DE.
		LD	HL,(X_PTR)	; fetch adjusted workspace pointer from X_PTR
		EX	AF,AF'		; restore flags.

					; now the new line or variable is entered.

					;;;$093E
ME_ENT_1:	EX	AF,AF'		; save or re-save flags.
		PUSH	DE		; save dest pointer in prog/vars area.
		CALL	NEXT_ONE	; routine NEXT_ONE finds next in workspace.
					; gets next in DE, difference in BC.
					; prev addr in HL
		LD	(X_PTR),HL	; store pointer in X_PTR
		LD	HL,(PROG)	; load HL from system variable PROG
		EX	(SP),HL		; swap with prog/vars pointer on stack. 
		PUSH	BC		; ** save length of new program line/variable.
		EX	AF,AF'		; fetch flags back.
		JR	C,ME_ENT_2	; skip to ME_ENT_2 if variable

		DEC	HL		; address location before pointer
		CALL	MAKE_ROOM	; routine MAKE_ROOM creates room for basic line
		INC	HL		; address next.
		JR	ME_ENT_3	; forward to ME_ENT_3

					;;;$0955
ME_ENT_2:	CALL	MAKE_ROOM	; routine MAKE_ROOM creates room for variable.

					;;;$0958
ME_ENT_3:	INC	HL		; address next?
		POP	BC		; ** pop length
		POP	DE		; * pop value for PROG which may have been 
					; altered by POINTERS if first line.
		LD	(PROG),DE	; set PROG to original value.
		LD	DE,(X_PTR)	; fetch adjusted workspace pointer from X_PTR
		PUSH	BC		; save length
		PUSH	DE		; and workspace pointer
		EX	DE,HL		; make workspace pointer source, prog/vars
					; pointer the destination
		LDIR			; copy bytes of line or variable into new area.
		POP	HL		; restore workspace pointer.
		POP	BC		; restore length.
		PUSH	DE		; save new prog/vars pointer.
		CALL	RECLAIM_2	; routine RECLAIM_2 reclaims the space used
					; by the line or variable in workspace block
					; as no longer required and space could be 
					; useful for adding more lines.
		POP	DE		; restore the prog/vars pointer
		RET			; return.

;--------------------
; Handle SAVE control
;--------------------
; A branch from the main SAVE_ETC routine at SAVE-ALL.
; First the header data is saved. Then after a wait of 1 second
; the data itself is saved.
; HL points to start of data.
; IX points to start of descriptor.

					;;;$0970
SA_CONTRL:	PUSH	HL		; save start of data
		LD	A,$FD		; select system channel 'S'
		CALL	CHAN_OPEN	; routine CHAN_OPEN
		XOR	A		; clear to address table directly
		LD	DE,TAPE_MSGS	; address: TAPE_MSGS
		CALL	PO_MSG		; routine PO_MSG -
					; 'Start tape then press any key.'
		SET	5,(IY+$02)	; TV_FLAG  - Signal lower screen requires  clearing
		CALL	WAIT_KEY	; routine WAIT_KEY
		PUSH	IX		; save pointer to descriptor.
		LD	DE,$0011	; there are seventeen bytes.
		XOR	A		; signal a header.
		CALL	SA_BYTES	; routine SA_BYTES
		POP	IX		; restore descriptor pointer.
		LD	B,$32		; wait for a second - 50 interrupts.

					;;;$0991
SA_1_SEC:	HALT			; wait for interrupt
		DJNZ	SA_1_SEC	; back to SA_1_SEC until pause complete.
		LD	E,(IX+$0B)	; fetch length of bytes from the
		LD	D,(IX+$0C)	; descriptor.
		LD	A,$FF		; signal data bytes.
		POP	IX		; retrieve pointer to start
		JP	SA_BYTES	; jump back to SA_BYTES


; Arrangement of two headers in workspace.
; Originally IX addresses first location and only one header is required
; when saving.
;
;   OLD     NEW         PROG   DATA  DATA  CODE 
;   HEADER  HEADER             num   chr          NOTES.
;   ------  ------      ----   ----  ----  ----   -----------------------------
;   IX-$11  IX+$00      0      1     2     3      Type.
;   IX-$10  IX+$01      x      x     x     x      F  ($FF if filename is null).
;   IX-$0F  IX+$02      x      x     x     x      i
;   IX-$0E  IX+$03      x      x     x     x      l
;   IX-$0D  IX+$04      x      x     x     x      e
;   IX-$0C  IX+$05      x      x     x     x      n
;   IX-$0B  IX+$06      x      x     x     x      a
;   IX-$0A  IX+$07      x      x     x     x      m
;   IX-$09  IX+$08      x      x     x     x      e
;   IX-$08  IX+$09      x      x     x     x      .
;   IX-$07  IX+$0A      x      x     x     x      (terminal spaces).
;   IX-$06  IX+$0B      lo     lo    lo    lo     Total  
;   IX-$05  IX+$0C      hi     hi    hi    hi     Length of datablock.
;   IX-$04  IX+$0D      Auto   -     -     Start  Various
;   IX-$03  IX+$0E      Start  a-z   a-z   addr   ($80 if no autostart).
;   IX-$02  IX+$0F      lo     -     -     -      Length of Program 
;   IX-$01  IX+$10      hi     -     -     -      only i.e. without variables.

;-------------------------
; Canned cassette messages
;-------------------------
; The last-character-inverted Cassette messages.
; Starts with normal initial step-over byte.

					;;;$09A1
TAPE_MSGS:	DEFB	$80
		DEFB	"Start tape, then press any key"
TAPE_MSGS2:	DEFB	'.'+$80
		DEFB	$0D
		DEFB	"Program:",' '+$80
		DEFB	$0D
		DEFB	"Number array:",' '+$80
		DEFB	$0D
		DEFB	"Character array:",' '+$80
		DEFB	$0D
		DEFB	"Bytes:",' '+$80



;**************************************************
;** Part 5. SCREEN AND PRINTER HANDLING ROUTINES **
;**************************************************

;----------------------
; General PRINT routine
;----------------------
; This is the routine most often used by the RST 10 restart although the
; subroutine is on two occasions called directly when it is known that
; output will definitely be to the lower screen.

					;;;$09F4
PRINT_OUT:	CALL	PO_FETCH	; routine PO_FETCH fetches print position
					; to HL register pair.
		CP	$20		; is character a space or higher ?
		JP	NC,PO_ABLE	; jump forward to PO_ABLE if so.

		CP	$06		; is character in range 00-05 ?
		JR	C,PO_QUEST	; to PO_QUEST to print '?' if so.

		CP	$18		; is character in range 24d - 31d ?
		JR	NC,PO_QUEST	; to PO_QUEST to also print '?' if so.

		LD	HL,CTLCHRTAB - 6; address $0A0B - the base address of control
					; character table - where zero would be.
		LD	E,A		; control character 06 - 23d
		LD	D,$00		; is transferred to DE.
		ADD	HL,DE		; index into table.
		LD	E,(HL)		; fetch the offset to routine.
		ADD	HL,DE		; add to make HL the address.
		PUSH	HL		; push the address.
		JP	PO_FETCH	; to PO_FETCH, as the screen/printer position
					; has been disturbed, and indirectly to
					; routine on stack.

;------------------------
; Control character table
;------------------------
; For control characters in the range 6 - 23d the following table
; is indexed to provide an offset to the handling routine that
; follows the table.

					;;;$0A11 
CTLCHRTAB:	DEFB	PO_COMMA - $	; 06d offset $4E to Address: PO_COMMA
		DEFB	PO_QUEST - $	; 07d offset $57 to Address: PO_QUEST
		DEFB	PO_BACK_1 - $	; 08d offset $10 to Address: PO_BACK_1
		DEFB	PO_RIGHT - $	; 09d offset $29 to Address: PO_RIGHT
		DEFB	PO_QUEST - $	; 10d offset $54 to Address: PO_QUEST
		DEFB	PO_QUEST - $	; 11d offset $53 to Address: PO_QUEST
		DEFB	PO_QUEST - $	; 12d offset $52 to Address: PO_QUEST
		DEFB	PO_ENTER - $	; 13d offset $37 to Address: PO_ENTER
		DEFB	PO_QUEST - $	; 14d offset $50 to Address: PO_QUEST
		DEFB	PO_QUEST - $	; 15d offset $4F to Address: PO_QUEST
		DEFB	PO_1_OPER - $	; 16d offset $5F to Address: PO_1_OPER
		DEFB	PO_1_OPER - $	; 17d offset $5E to Address: PO_1_OPER
		DEFB	PO_1_OPER - $	; 18d offset $5D to Address: PO_1_OPER
		DEFB	PO_1_OPER - $	; 19d offset $5C to Address: PO_1_OPER
		DEFB	PO_1_OPER - $	; 20d offset $5B to Address: PO_1_OPER
		DEFB	PO_1_OPER - $	; 21d offset $5A to Address: PO_1_OPER
		DEFB	PO_2_OPER - $	; 22d offset $54 to Address: PO_2_OPER
		DEFB	PO_2_OPER - $	; 23d offset $53 to Address: PO_2_OPER


;--------------------
; Cursor left routine
;--------------------
; Backspace and up a line if that action is from the left of screen.
; For ZX printer backspace up to first column but not beyond.

					;;;$0A23
PO_BACK_1:	INC	C		; move left one column.
		LD	A,$22		; value $21 is leftmost column.
		CP	C		; have we passed ?
		JR	NZ,PO_BACK_3	; to PO_BACK_3 if not and store new position.

		BIT	1,(IY+$01)	; test FLAGS  - is printer in use ?
		JR	NZ,PO_BACK_2	; to PO_BACK_2 if so, as we are unable to
					; backspace from the leftmost position.
		INC	B		; move up one screen line
		LD	C,$02		; the rightmost column position.
		LD	A,$18		; Note. This should be $19
					; credit. Dr. Frank O'Hara, 1982
		CP	B		; has position moved past top of screen ?
		JR	NZ,PO_BACK_3	; to PO_BACK_3 if not and store new position.

		DEC	B		; else back to $18.

					;;;$0A38
PO_BACK_2:	LD	C,$21		; the leftmost column position.

					;;;$0A3A
PO_BACK_3:	JP	CL_SET		; to CL_SET and PO_STORE to save new
					; position in system variables.

;---------------------
; Cursor right routine
;---------------------
; This moves the print position to the right leaving a trail in the
; current background colour.
; "However the programmer has failed to store the new print position
;  so CHR$ 9 will only work if the next print position is at a newly
;  defined place.
;   e.g. PRINT PAPER 2; CHR$ 9; AT 4,0;
;  does work but is not very helpful"
; - Dr. Ian Logan, Understanding Your Spectrum, 1982.

					;;;$0A3D
PO_RIGHT:	LD	A,(P_FLAG)	; fetch P_FLAG value
		PUSH	AF		; and save it on stack.
		LD	(IY+$57),$01	; temporarily set P_FLAG 'OVER 1'.
		LD	A,$20		; prepare a space.
		CALL	PO_CHAR		; routine PO_CHAR to print it.
					; Note. could be PO_ABLE which would update
					; the column position.
		POP	AF		; restore the permanent flag.
		LD	(P_FLAG),A	; and restore system variable P_FLAG
		RET			; return without updating column position

;------------------------
; Perform carriage return
;------------------------
; A carriage return is 'printed' to screen or printer buffer.

					;;;$0A4F
PO_ENTER:	BIT	1,(IY+$01)	; test FLAGS  - is printer in use ?
		JP	NZ,COPY_BUFF	; to COPY_BUFF if so, to flush buffer and reset
					; the print position.
		LD	C,$21		; the leftmost column position.
		CALL	PO_SCR		; routine PO_SCR handles any scrolling required.
		DEC	B		; to next screen line.
		JP	CL_SET		; jump forward to CL_SET to store new position.

;------------
; Print comma
;------------
; The comma control character. The 32 column screen has two 16 character
; tabstops.  The routine is only reached via the control character table.

					;;;$0A5F
PO_COMMA:	CALL	PO_FETCH	; routine PO_FETCH - seems unnecessary.
		LD	A,C		; the column position. $21-$01
		DEC	A		; move right. $20-$00
		DEC	A		; and again   $1F-$00 or $FF if trailing
		AND	$10		; will be $00 or $10.
		JR	PO_FILL		; forward to PO_FILL

;--------------------
; Print question mark
;--------------------
; This routine prints a question mark which is commonly
; used to print an unassigned control character in range 0-31d.
; there are a surprising number yet to be assigned.

					;;;$0A69
PO_QUEST:	LD	A,$3F		; prepare the character '?'.
		JR	PO_ABLE		; forward to PO_ABLE.

;---------------------------------
; Control characters with operands
;---------------------------------
; Certain control characters are followed by 1 or 2 operands.
; The entry points from control character table are PO_2_OPER and PO_1_OPER.
; The routines alter the output address of the current channel so that
; subsequent RST $10 instructions take the appropriate action
; before finally resetting the output address back to PRINT_OUT.

					;;;$0A6D
PO_TV_2:	LD	DE,PO_CONT	; address: PO_CONT will be next output routine
		LD	(TVDATA_HI),A	; store first operand in TVDATA_HI
		JR	PO_CHANGE	; forward to PO_CHANGE >>

					; -> This initial entry point deals with two operands - AT or TAB.

					;;;$0A75
PO_2_OPER:	LD	DE,PO_TV_2	; address: PO_TV_2 will be next output routine
		JR	PO_TV_1		; forward to PO_TV_1

					; -> This initial entry point deals with one operand INK to OVER.

					;;;$0A7A
PO_1_OPER:	LD	DE,PO_CONT	; address: PO_CONT will be next output routine

					;;;$0A7D
PO_TV_1:	LD	(TVDATA_LO),A	; store control code in TVDATA_LO

					;;;$0A80
PO_CHANGE:	LD	HL,(CURCHL)	; use CURCHL to find current output channel.
		LD	(HL),E		; make it
		INC	HL		; the supplied
		LD	(HL),D		; address from DE.
		RET			; Note. should clear carry before returning

					;;;$0A87
PO_CONT:	LD	DE,PRINT_OUT	; Address: PRINT_OUT
		CALL	PO_CHANGE	; routine PO_CHANGE to restore normal channel.
		LD	HL,(TVDATA_LO)	; TVDATA gives control code and possible
					; subsequent character
		LD	D,A		; save current character
		LD	A,L		; the stored control code
		CP	$16		; was it INK to OVER (1 operand) ?
		JP	C,CO_TEMP_5	; to CO_TEMP_5

		JR	NZ,PO_TAB	; to PO_TAB if not 22d i.e. 23d TAB.

					; else must have been 22d AT.
		LD	B,H		; line to   H (0-23d)
		LD	C,D		; column to C (0-31d)
		LD	A,$1F		; the value 31d
		SUB	C		; reverse the column number.
		JR	C,PO_AT_ERR	; to PO_AT_ERR if C was greater than 31d.

		ADD	A,$02		; transform to system range $02-$21
		LD	C,A		; and place in column register.
		BIT	1,(IY+$01)	; test FLAGS  - is printer in use ?
		JR	NZ,PO_AT_SET	; to PO_AT_SET as line can be ignored.

		LD	A,$16		; 22 decimal
		SUB	B		; subtract line number to reverse
					; 0 - 22 becomes 22 - 0.

					;;;$0AAC
PO_AT_ERR:	JP	C,REPORT_BB	; to REPORT_BB if higher than 22 decimal
					; Integer out of range.
		INC	A		; adjust for system range $01-$17
		LD	B,A		; place in line register
		INC	B		; adjust to system range  $02-$18
		BIT	0,(IY+$02)	; TV_FLAG  - Lower screen in use ?
		JP	NZ,PO_SCR	; exit to PO_SCR to test for scrolling

		CP	(IY+$31)	; Compare against DF_SZ
		JP	C,REPORT_5	; to REPORT_5 if too low
					; Out of screen.

					;;;$0ABF
PO_AT_SET:	JP	CL_SET		; print position is valid so exit via CL_SET

					; Continue here when dealing with TAB.
					; Note. In basic TAB is followed by a 16-bit number and was initially
					; designed to work with any output device.

					;;;$0AC2
PO_TAB:		LD	A,H		; transfer parameter to A
					; Losing current character -
					; High byte of TAB parameter.

					;;;$0AC3
PO_FILL:	CALL	PO_FETCH	; routine PO_FETCH, HL-addr, BC=line/column.
					; column 1 (right), $21 (left)
		ADD	A,C		; add operand to current column
		DEC	A		; range 0 - 31+
		AND	$1F		; make range 0 - 31d
		RET	Z		; return if result zero

		LD	D,A		; Counter to D
		SET	0,(IY+$01)	; update FLAGS  - signal suppress leading space.

					;;;$0AD0
PO_SPACE:	LD	A,$20		; space character.
		CALL	PO_SAVE		; routine PO_SAVE prints the character
					; using alternate set (normal output routine)
		DEC	D		; decrement counter.
		JR	NZ,PO_SPACE	; to PO_SPACE until done

		RET			; return

;-----------------------
; Printable character(s)
;-----------------------
; This routine prints printable characters and continues into
; the position store routine

					;;;$0AD9
PO_ABLE:	CALL	PO_ANY		; routine PO_ANY
					; and continue into position store routine.

;--------------------------------------
; Store line, column, and pixel address
;--------------------------------------
; This routine updates the system variables associated with
; The main screen, lower screen/input buffer or ZX printer.

					;;;$0ADC
PO_STORE:	BIT	1,(IY+$01)	; test FLAGS  - Is printer in use ?
		JR	NZ,PO_ST_PR	; to PO_ST_PR if so

		BIT	0,(IY+$02)	; TV_FLAG  - Lower screen in use ?
		JR	NZ,PO_ST_E	; to PO_ST_E if so

		LD	(S_POSN),BC	; S_POSN line/column upper screen
		LD	(DF_CC),HL	; DF_CC  display file address
		RET

					;;;$0AF0:
PO_ST_E:	LD	(SPOSNL),BC	; SPOSNL line/column lower screen
		LD	(ECHO_E),BC	; ECHO_E line/column input buffer
		LD	(DFCCL),HL	; DFCCL  lower screen memory address
		RET

					;;;$0AFC
PO_ST_PR:	LD	(IY+$45),C	; P_POSN column position printer
		LD	(PR_CC),HL	; PR_CC  full printer buffer memory address
		RET

;--------------------------
; Fetch position parameters
;--------------------------
; This routine fetches the line/column and display file address
; of the upper and lower screen or, if the printer is in use,
; the column position and absolute memory address.
; Note. that PR-CC-hi (23681) is used by this routine and the one above
; and if, in accordance with the manual (that says this is unused), the
; location has been used for other purposes, then subsequent output
; to the printer buffer could corrupt a 256-byte section of memory.

					;;;$0B03
PO_FETCH:	BIT	1,(IY+$01)	; test FLAGS  - Is printer in use
		JR	NZ,PO_F_PR	; to PO_F_PR if so
					; assume upper screen
		LD	BC,(S_POSN)	; S_POSN
		LD	HL,(DF_CC)	; DF_CC display file address
		BIT	0,(IY+$02)	; TV_FLAG  - Lower screen in use ?
		RET	Z		; return if upper screen
					; ah well, was lower screen
		LD	BC,(SPOSNL)	; SPOSNL
		LD	HL,(DFCCL)	; DFCCL
		RET			; return

					;;;$0B1D
PO_F_PR:	LD	C,(IY+$45)	; P_POSN column only
		LD	HL,(PR_CC)	; PR_CC printer buffer address
		RET			; return

;--------------------
; Print any character
;--------------------
; This routine is used to print any character in range 32d - 255d
; It is only called from PO_ABLE and continues into PO_STORE

					;;;$0B24
PO_ANY:		CP	$80		; ascii ?
		JR	C,PO_CHAR	; to PO_CHAR is so.

		CP	$90		; test if a block graphic character.
		JR	NC,PO_T_UDG	; to PO_T_UDG to print tokens and udg's

					; The 16 2*2 mosaic characters 128-143 decimal are formed from
					; bits 0-3 of the character.

		LD	B,A		; save character
		CALL	PO_GR_1		; routine PO_GR_1 to construct top half then bottom half.
		CALL	PO_FETCH	; routine PO_FETCH fetches print position.
		LD	DE,MEM_0	; MEM_0 is location of 8 bytes of character
		JR	PR_ALL		; to PR_ALL to print to screen or printer

					;;;$0B38
PO_GR_1:	LD	HL,MEM_0	; address MEM_0 - a temporary buffer in
					; systems variables which is normally used by the calculator.
		CALL	PO_GR_2		; routine PO_GR_2 to construct top half
					; and continue into routine to construct bottom half.

					;;;$0B3E
PO_GR_2:	RR	B		; rotate bit 0/2 to carry
		SBC	A,A		; result $00 or $FF
		AND	$0F		; mask off right hand side
		LD	C,A		; store part in C
		RR	B		; rotate bit 1/3 of original chr to carry
		SBC	A,A		; result $00 or $FF
		AND	$F0		; mask off left hand side
		OR	C		; combine with stored pattern
		LD	C,$04		; four bytes for top/bottom half

					;;;$0B4C
PO_GR_3:	LD	(HL),A		; store bit patterns in temporary buffer
		INC	HL		; next address
		DEC	C		; jump back to
		JR	NZ,PO_GR_3	; to PO_GR_3 until byte is stored 4 times

		RET			; return

					; Tokens and User defined graphics are now separated.

					;;;$0B52
PO_T_UDG:	SUB	$A5		; the 'RND' character
		JR	NC,PO_T		; to PO_T to print tokens

		ADD	A,$15		; add 21d to restore to 0 - 20
		PUSH	BC		; save current print position
		LD	BC,(UDG)	; fetch UDG to address bit patterns
		JR	PO_CHAR_2	; to PO_CHAR_2 - common code to lay down
					; a bit patterned character

					;;;$0B5F
PO_T:		CALL	PO_TOKENS	; routine PO_TOKENS prints tokens
		JP	PO_FETCH	; exit via PO_FETCH as this routine must continue into PO_STORE

					; This point is used to print ascii characters  32d - 127d.

					;;;$0B65
PO_CHAR:	PUSH	BC		; save print position
		LD	BC,(CHARS)	; address CHARS

					; This common code is used to transfer the character bytes to memory.

					;;;$0B6A
PO_CHAR_2:	EX	DE,HL		; transfer destination address to DE
		LD	HL,FLAGS	; point to FLAGS
		RES	0,(HL)		; allow for leading space
		CP	$20		; is it a space ?
		JR	NZ,PO_CHAR_3	; to PO_CHAR_3 if not

		SET	0,(HL)		; signal no leading space to FLAGS

					;;;$0B76
PO_CHAR_3:	LD	H,$00		; set high byte to 0
		LD	L,A		; character to A
					; 0-21 UDG or 32-127 ascii.
		ADD	HL,HL		; multiply
		ADD	HL,HL		; by
		ADD	HL,HL		; eight
		ADD	HL,BC		; HL now points to first byte of character
		POP	BC		; the source address CHARS or UDG
		EX	DE,HL		; character address to DE

;---------------------
; Print all characters
;---------------------
; This entry point entered from above to print ascii and UDGs
; but also from earlier to print mosaic characters.
; HL=destination
; DE=character source
; BC=line/column

					;;;$0B7F
PR_ALL:		LD	A,C		; column to A
		DEC	A		; move right
		LD	A,$21		; pre-load with leftmost position
		JR	NZ,PR_ALL_1	; but if not zero to PR_ALL_1

		DEC	B		; down one line
		LD	C,A		; load C with $21
		BIT	1,(IY+$01)	; test FLAGS  - Is printer in use
		JR	Z,PR_ALL_1	; to PR_ALL_1 if not

		PUSH	DE		; save source address
		CALL	COPY_BUFF	; routine COPY_BUFF outputs line to printer
		POP	DE		; restore character source address
		LD	A,C		; the new column number ($21) to C

					;;;$0B93
PR_ALL_1:	CP	C		; this test is really for screen - new line ?
		PUSH	DE		; save source
		CALL	Z,PO_SCR	; routine PO_SCR considers scrolling
		POP	DE		; restore source
		PUSH	BC		; save line/column
		PUSH	HL		; and destination
		LD	A,(P_FLAG)	; fetch P_FLAG to accumulator
		LD	B,$FF		; prepare OVER mask in B.
		RRA			; bit 0 set if OVER 1
		JR	C,PR_ALL_2	; to PR_ALL_2

		INC	B		; set OVER mask to 0

					;;;$0BA4
PR_ALL_2:	RRA			; skip bit 1 of P_FLAG
		RRA			; bit 2 is INVERSE
		SBC	A,A		; will be FF for INVERSE 1 else zero
		LD	C,A		; transfer INVERSE mask to C
		LD	A,$08		; prepare to count 8 bytes
		AND	A		; clear carry to signal screen
		BIT	1,(IY+$01)	; test FLAGS  - Is printer in use ?
		JR	Z,PR_ALL_3	; to PR_ALL_3 if screen

		SET	1,(IY+$30)	; update FLAGS2  - Signal printer buffer has been used.
		SCF			; set carry flag to signal printer.

					;;;$0BB6
PR_ALL_3:	EX	DE,HL		; now HL=source, DE=destination

					;;;$0BB7
PR_ALL_4:	EX	AF,AF'		; save printer/screen flag
		LD	A,(DE)		; fetch existing destination byte
		AND	B		; consider OVER
		XOR	(HL)		; now XOR with source
		XOR	C		; now with INVERSE MASK
		LD	(DE),A		; update screen/printer
		EX	AF,AF'		; restore flag
		JR	C,PR_ALL_6	; to PR_ALL_6 - printer address update

		INC	D		; gives next pixel line down screen

					;;;$0BC1
PR_ALL_5:	INC	HL		; address next character byte
		DEC	A		; the byte count is decremented
		JR	NZ,PR_ALL_4	; back to PR_ALL_4 for all 8 bytes

		EX	DE,HL		; destination to HL
		DEC	H		; bring back to last updated screen position
		BIT	1,(IY+$01)	; test FLAGS  - is printer in use ?
		CALL	Z,PO_ATTR	; if not, call routine PO_ATTR to update corresponding colour attribute.
		POP	HL		; restore original screen/printer position
		POP	BC		; and line column
		DEC	C		; move column to right
		INC	HL		; increase screen/printer position
		RET			; return and continue into PO_STORE within PO_ABLE

					; This branch is used to update the printer position by 32 places
					; Note. The high byte of the address D remains constant (which it should).

					;;;$0BD3
PR_ALL_6:	EX	AF,AF'		; save the flag
		LD	A,$20		; load A with 32 decimal
		ADD	A,E		; add this to E
		LD	E,A		; and store result in E
		EX	AF,AF'		; fetch the flag
		JR	PR_ALL_5	; back to PR_ALL_5

;--------------
; Set attribute
;--------------
; This routine is entered with the HL register holding the last screen
; address to be updated by PRINT or PLOT.
; The Spectrum screen arrangement leads to the L register holding
; the correct value for the attribute file and it is only necessary
; to manipulate H to form the correct colour attribute address.

					;;;$0BDB
PO_ATTR:	LD	A,H		; fetch high byte $40 - $57
		RRCA			; shift
		RRCA			; bits 3 and 4
		RRCA			; to right.
		AND	$03		; range is now 0 - 2
		OR	$58		; form correct high byte for third of screen
		LD	H,A		; HL is now correct
		LD	DE,(ATTRT_MASKT); make D hold ATTR_T, E hold MASK-T
		LD	A,(HL)		; fetch existing attribute
		XOR	E		; apply masks
		AND	D
		XOR	E
		BIT	6,(IY+$57)	; test P_FLAG  - is this PAPER 9 ??
		JR	Z,PO_ATTR_1	; skip to PO_ATTR_1 if not.

		AND	$C7		; set paper
		BIT	2,A		; to contrast with ink
		JR	NZ,PO_ATTR_1	; skip to PO_ATTR_1

		XOR	$38

					;;;$0BFA
PO_ATTR_1:	BIT	4,(IY+$57)	; test P_FLAG  - Is this INK 9 ??
		JR	Z,PO_ATTR_2	; skip to PO_ATTR_2 if not

		AND	$F8		; make ink
		BIT	5,A		; contrast with paper.
		JR	NZ,PO_ATTR_2	; to PO_ATTR_2

		XOR	$07

					;;;$0C08
PO_ATTR_2:	LD	(HL),A		; save the new attribute.
		RET			; return.

;-----------------
; Message printing
;-----------------
; This entry point is used to print tape, boot-up, scroll? and error messages
; On entry the DE register points to an initial step-over byte or
; the inverted end-marker of the previous entry in the table.
; A contains the message number, often zero to print first message.
; (HL has nothing important usually P_FLAG)

					;;;$0C0A
PO_MSG:		PUSH	HL		; put hi-byte zero on stack to suppress
		LD	H,$00		; trailing spaces
		EX	(SP),HL		; ld h,0; push hl would have done ?.
		JR	PO_TABLE	; forward to PO_TABLE.

					; This entry point prints the basic keywords, '<>' etc. from alt set

					;;;$0C10
PO_TOKENS:	LD	DE,TKN_TABLE	; address: TKN_TABLE
		PUSH	AF		; save the token number to control
					; trailing spaces - see later *

					;;;$0C14
PO_TABLE:	CALL	PO_SEARCH	; routine PO_SEARCH will set carry for
					; all messages and function words.
		JR	C,PO_EACH	; forward to PO_EACH if not a command,
					; '<>' etc.

		LD	A,$20		; prepare leading space
		BIT	0,(IY+$01)	; test FLAGS  - leading space if not set
		CALL	Z,PO_SAVE	; routine PO_SAVE to print a space
					; without disturbing registers

					;;;$0C22
PO_EACH:	LD	A,(DE)		; fetch character
		AND	$7F		; remove any inverted bit
		CALL	PO_SAVE		; routine PO_SAVE to print using alternate set of registers.
		LD	A,(DE)		; re-fetch character.
		INC	DE		; address next
		ADD	A,A		; was character inverted? (this also doubles character)
		JR	NC,PO_EACH	; back to PO_EACH if not

		POP	DE		; * re-fetch trailing space flag to D (was A)
		CP	$48		; was last character '$' ($24*2)
		JR	Z,PO_TR_SP	; forward to PO_TR_SP to consider trailing space if so.

		CP	$82		; was it < 'A' i.e. '#','>','=' from tokens
					; or ' ','.' (from tape) or '?' from scroll
		RET	C		; no trailing space

					;;;$0C35
PO_TR_SP:	LD	A,D		; the trailing space flag (zero if an error msg)
		CP	$03		; test against RND, INKEY$ and PI
					; which have no parameters and
		RET	C		; therefore no trailing space so return.

		LD	A,$20		; else continue and print a trailing space.

;--------------------------
; Handle recursive printing
;--------------------------
; This routine which is part of PRINT_OUT allows RST $10 to be
; used recursively to print tokens and the spaces associated with them.

					;;;$0C3B
PO_SAVE:	PUSH	DE		; save DE as CALL_SUB doesn't.
		EXX			; switch in main set
		RST	10H		; PRINT_A prints using this alternate set.
		EXX			; back to this alternate set.
		POP	DE		; restore initial DE.
		RET			; return.

;-------------
; Table search
;-------------
; This subroutine searches a message or the token table for the
; message number held in A. DE holds the address of the table.

					;;;$0C41
PO_SEARCH:	PUSH	AF		; save the message/token number
		EX	DE,HL		; transfer DE to HL
		INC	A		; adjust for initial step-over byte

					;;;$0C44
PO_STEP:	BIT	7,(HL)		; is character inverted ?
		INC	HL		; address next
		JR	Z,PO_STEP	; back to PO-STEP if not inverted.

		DEC	A		; decrease counter
		JR	NZ,PO_STEP	; back to PO-STEP if not zero

		EX	DE,HL		; transfer address to DE
		POP	AF		; restore message/token number
		CP	$20		; return with carry set
		RET	C		; for all messages and function tokens

		LD	A,(DE)		; test first character of token
		SUB	$41		; and return with carry set
		RET			; if it is less that 'A'
					; i.e. '<>', '<=', '>='

;----------------
; Test for scroll
;----------------
; This test routine is called when printing carriage return, when considering
; PRINT AT and from the general PRINT ALL characters routine to test if
; scrolling is required, prompting the user if necessary.
; This is therefore using the alternate set.
; The B register holds the current line.

					;;;$0C55
PO_SCR:		BIT	1,(IY+$01)	; test FLAGS  - is printer in use ?
		RET	NZ		; return immediately if so.

		LD	DE,CL_SET	; set DE to address: CL_SET
		PUSH	DE		; and push for return address.
		LD	A,B		; transfer the line to A.
		BIT	0,(IY+$02)	; test TV_FLAG  - Lower screen in use ?
		JP	NZ,PO_SCR_4	; jump forward to PO_SCR_4 if so.

		CP	(IY+$31)	; greater than DF_SZ display file size ?
		JR	C,REPORT_5	; forward to REPORT_5 if less.
					; 'Out of screen'
		RET	NZ		; return (via CL_SET) if greater

		BIT	4,(IY+$02)	; test TV_FLAG  - Automatic listing ?
		JR	Z,PO_SCR_2	; forward to PO_SCR_2 if not.

		LD	E,(IY+$2D)	; fetch BREG - the count of scroll lines to E.
		DEC	E		; decrease and jump
		JR	Z,PO_SCR_3	; to PO_SCR_3 if zero and scrolling required.

		LD	A,$00		; explicit - select channel zero.
		CALL	CHAN_OPEN	; routine CHAN_OPEN opens it.
		LD	SP,(LIST_SP)	; set stack pointer to LIST_SP
		RES	4,(IY+$02)	; reset TV_FLAG  - signal auto listing finished.
		RET			; return ignoring pushed value, CL_SET
					; to MAIN or EDITOR without updating
					; print position			->


					;;;$0C86
REPORT_5:	RST	08H		; ERROR_1
		DEFB	$04		; Error Report: Out of screen

					; continue here if not an automatic listing.

					;;;$0C88
PO_SCR_2:	DEC	(IY+$52)	; decrease SCR_CT
		JR	NZ,PO_SCR_3	; forward to PO_SCR_3 to scroll display if
					; result not zero.

					; now produce prompt.

		LD	A,$18		; reset
		SUB	B		; the
		LD	(SCR_CT),A	; SCR_CT scroll count
		LD	HL,(ATTRT_MASKT); L=ATTR_T, H=MASK_T
		PUSH	HL		; save on stack
		LD	A,(P_FLAG)	; P_FLAG
		PUSH	AF		; save on stack to prevent lower screen
					; attributes (BORDCR etc.) being applied.
		LD	A,$FD		; select system channel 'K'
		CALL	CHAN_OPEN	; routine CHAN_OPEN opens it
		XOR	A		; clear to address message directly
		LD	DE,SCRL_MSSG	; make DE address: SCRL_MSSG
		CALL	PO_MSG		; routine PO_MSG prints to lower screen
		SET	5,(IY+$02)	; set TV_FLAG  - signal lower screen requires clearing
		LD	HL,FLAGS	; make HL address FLAGS
		SET	3,(HL)		; signal 'L' mode.
		RES	5,(HL)		; signal 'no new key'.
		EXX			; switch to main set.
					; as calling chr input from alternative set.
		CALL	WAIT_KEY	; routine WAIT_KEY waits for new key
					; Note. this is the right routine but the
					; stream in use is unsatisfactory. From the
					; choices available, it is however the best.
		EXX			; switch back to alternate set.
		CP	$20		; space is considered as BREAK
		JR	Z,REPORT_D	; forward to REPORT_D if so
					; 'BREAK - CONT repeats'
		CP	$E2		; is character 'STOP' ?
		JR	Z,REPORT_D	; forward to REPORT_D if so

		OR	$20		; convert to lower-case
		CP	$6E		; is character 'n' ?
		JR	Z,REPORT_D	; forward to REPORT_D if so else scroll.

		LD	A,$FE		; select system channel 'S'
		CALL	CHAN_OPEN	; routine CHAN_OPEN
		POP	AF		; restore original P_FLAG
		LD	(P_FLAG),A	; and save in P_FLAG.
		POP	HL		; restore original ATTR_T, MASK_T
		LD	(ATTRT_MASKT),HL; and reset ATTR_T, MASK-T as 'scroll?' has been printed.

					;;;$0CD2
PO_SCR_3:	CALL	CL_SC_ALL	; routine CL_SC_ALL to scroll whole display
		LD	B,(IY+$31)	; fetch DF_SZ to B
		INC	B		; increase to address last line of display
		LD	C,$21		; set C to $21 (was $21 from above routine)
		PUSH	BC		; save the line and column in BC.
		CALL	CL_ADDR		; routine CL_ADDR finds display address.
		LD	A,H		; now find the corresponding attribute byte
		RRCA			; (this code sequence is used twice
		RRCA			; elsewhere and is a candidate for
		RRCA			; a subroutine.)
		AND	$03
		OR	$58
		LD	H,A
		LD	DE,$5AE0	; start of last 'line' of attribute area
		LD	A,(DE)		; get attribute for last line
		LD	C,(HL)		; transfer to base line of upper part
		LD	B,$20		; there are thirty two bytes
		EX	DE,HL		; swap the pointers.

					;;;$0CF0
PO_SCR_3A:	LD	(DE),A		; transfer
		LD	(HL),C		; attributes.
		INC	DE		; address next.
		INC	HL		; address next.
		DJNZ	PO_SCR_3A	; loop back to PO_SCR_3A for all adjacent
					; attribute lines.
		POP	BC		; restore the line/column.
		RET			; return via CL_SET (was pushed on stack).

					; The message 'scroll?' appears here with last byte inverted.

					;;;$0CF8
SCRL_MSSG:	DEFB	$80		; initial step-over byte.
		DEFB	"scroll",'?'+$80

					;;;$0D00
REPORT_D:	RST	08H		; ERROR_1
		DEFB	$0C		; Error Report: BREAK - CONT repeats

					; continue here if using lower display - A holds line number.

					;;;$0D02
PO_SCR_4:	CP	$02		; is line number less than 2 ?
		JR	C,REPORT_5	; to REPORT_5 if so
					; 'Out of Screen'.
		ADD	A,(IY+$31)	; add DF_SZ
		SUB	$19
		RET	NC		; return if scrolling unnecessary

		NEG			; Negate to give number of scrolls required.
		PUSH	BC		; save line/column
		LD	B,A		; count to B
		LD	HL,(ATTRT_MASKT); fetch current ATTR_T, MASK_T to HL.
		PUSH	HL		; and save
		LD	HL,(P_FLAG)	; fetch P_FLAG
		PUSH	HL		; and save.
					; to prevent corruption by input AT
		CALL	TEMPS		; routine TEMPS sets to BORDCR etc
		LD	A,B		; transfer scroll number to A.

					;;;$0D1C
PO_SCR_4A:	PUSH	AF		; save scroll number.
		LD	HL,DF_SZ	; address DF_SZ
		LD	B,(HL)		; fetch old value
		LD	A,B		; transfer to A
		INC	A		; and increment
		LD	(HL),A		; then put back.
		LD	HL,S_POSN_HI	; address S_POSN_HI - line
		CP	(HL)		; compare
		JR	C,PO_SCR_4B	; forward to PO_SCR_4B if scrolling required

		INC	(HL)		; else increment S_POSN_HI
		LD	B,$18		; set count to whole display ??
					; Note. should be $17 and the top line
					; will be scrolled into the ROM which
					; is harmless on the standard set up.

					;;;$0D2D
PO_SCR_4B:	CALL	CL_SCROLL	; routine CL_SCROLL scrolls B lines
		POP	AF		; restore scroll counter.
		DEC	A		; decrease
		JR	NZ,PO_SCR_4A	; back to to PO_SCR_4A until done

		POP	HL		; restore original P_FLAG.
		LD	(IY+$57),L	; and overwrite system variable P_FLAG.
		POP	HL		; restore original ATTR_T/MASK_T.
		LD	(ATTRT_MASKT),HL; and update system variables.
		LD	BC,(S_POSN)	; fetch S_POSN to BC.
		RES	0,(IY+$02)	; signal to TV_FLAG  - main screen in use.
		CALL	CL_SET		; call routine CL_SET for upper display.
		SET	0,(IY+$02)	; signal to TV_FLAG  - lower screen in use.
		POP	BC		; restore line/column
		RET			; return via CL_SET for lower display.

;-----------------------
; Temporary colour items
;-----------------------
; This subroutine is called 11 times to copy the permanent colour items
; to the temporary ones.

					;;;$0D4D
TEMPS:		XOR	A		; clear the accumulator
		LD	HL,(ATTRP_MASKP); fetch L=ATTR_P and H=MASK_P
		BIT	0,(IY+$02)	; test TV_FLAG  - is lower screen in use ?
		JR	Z,TEMPS_1	; skip to TEMPS_1 if not

		LD	H,A		; set H, MASK P, to 00000000.
		LD	L,(IY+$0E)	; fetch BORDCR to L which is used for lower screen.

					;;;$0D5B
TEMPS_1:	LD	(ATTRT_MASKT),HL; transfer values to ATTR_T and MASK_T

					; for the print flag the permanent values are odd bits, temporary even bits.

		LD	HL,P_FLAG	; address P_FLAG.
		JR	NZ,TEMPS_2	; skip to TEMPS_2 if lower screen using A=0.

		LD	A,(HL)		; else pick up flag bits.
		RRCA			; rotate permanent bits to temporary bits.

					;;;$0D65
TEMPS_2:	XOR	(HL)
		AND	$55		; BIN 01010101
		XOR	(HL)		; permanent now as original
		LD	(HL),A		; apply permanent bits to temporary bits.
		RET			; and return.

;-------------------
; Handle CLS command
;-------------------
; clears the display.
; if it's difficult to write it should be difficult to read.

					;;;$0D6B
CLS:		CALL	CL_ALL		; routine CL_ALL  clears display and
					; resets attributes to permanent.
					; re-attaches it to this computer.

					; this routine called from input, **

					;;;$0D6E
CLS_LOWER:	LD	HL,TV_FLAG	; address TV_FLAG
		RES	5,(HL)		; TV_FLAG - signal do not clear lower screen.
		SET	0,(HL)		; TV_FLAG - signal lower screen in use.
		CALL	TEMPS		; routine TEMPS picks up temporary colours.
		LD	B,(IY+$31)	; fetch lower screen DF_SZ
		CALL	CL_LINE		; routine CL_LINE clears lower part
					; and sets permanent attributes.
		LD	HL,$5AC0	; fetch attribute address leftmost cell, second line up.
		LD	A,(ATTRP_MASKP)	; fetch permanent attribute from ATTR_P.
		DEC	B		; decrement lower screen display file size
		JR	CLS_3		; forward to CLS_3 ->

					;;;$0D87
CLS_1:		LD	C,$20		; set counter to 32 characters per line

					;;;$0D89
CLS_2:		DEC	HL		; decrease attribute address.
		LD	(HL),A		; and place attributes in next line up.
		DEC	C		; decrease 32 counter.
		JR	NZ,CLS_2	; loop back to CLS_2 until all 32 done.

					;;;$0D8E
CLS_3:		DJNZ	CLS_1		; decrease B counter and back to CLS_1
					; if not zero.
		LD	(IY+$31),$02	; set DF_SZ lower screen to 2

					; This entry point is called from CL_ALL below to
					; reset the system channel input and output addresses to normal.

					;;;$0D94
CL_CHAN:	LD	A,$FD		; select system channel 'K'
		CALL	CHAN_OPEN	; routine CHAN_OPEN opens it.
		LD	HL,(CURCHL)	; fetch CURCHL to HL to address current channel
		LD	DE,PRINT_OUT	; set address to PRINT_OUT for first pass.
		AND	A		; clear carry for first pass.

					;;;$0DA0
CL_CHAN_A:	LD	(HL),E		; insert output address first pass.
		INC	HL		; or input address on second pass.
		LD	(HL),D
		INC	HL
		LD	DE,KEY_INPUT	; fetch address KEY_INPUT for second pass
		CCF			; complement carry flag - will set on pass 1.
		JR	C,CL_CHAN_A	; back to CL_CHAN_A if first pass else done.

		LD	BC,$1721	; line 23 for lower screen
		JR	CL_SET		; exit via CL_SET to set column
					; for lower display

;----------------------------
; Clearing whole display area
;----------------------------
; This subroutine called from CLS, AUTO_LIST and MAIN_3
; clears 24 lines of the display and resets the relevant system variables
; and system channels.

					;;;$0DAF
CL_ALL:		LD	HL,$0000	; initialize plot coordinates.
		LD	(COORDS),HL	; set COORDS to 0,0.
		RES	0,(IY+$30)	; update FLAGS2  - signal main screen is clear.
		CALL	CL_CHAN		; routine CL_CHAN makes channel 'K' 'normal'.
		LD	A,$FE		; select system channel 'S'
		CALL	CHAN_OPEN	; routine CHAN_OPEN opens it
		CALL	TEMPS		; routine TEMPS picks up permanent values.
		LD	B,$18		; There are 24 lines.
		CALL	CL_LINE		; routine CL_LINE clears 24 text lines
					; (and sets BC to $1821)
		LD	HL,(CURCHL)	; fetch CURCHL make HL address current channel 'S'
		LD	DE,PRINT_OUT	; address: PRINT_OUT
		LD	(HL),E		; is made
		INC	HL		; the normal
		LD	(HL),D		; output address.
		LD	(IY+$52),$01	; set SCR_CT - scroll count is set to default.
					; Note. BC already contains $1821.
		LD	BC,$1821	; reset column and line to 0,0
					; and continue into CL_SET, below, exiting
					; via PO_STORE (for upper screen).

;----------------------------
; Set line and column numbers
;----------------------------
; This important subroutine is used to calculate the character output
; address for screens or printer based on the line/column for screens
; or the column for printer.

					;;;$0DD9
CL_SET:		LD	HL,$5B00	; the base address of printer buffer
		BIT	1,(IY+$01)	; test FLAGS  - is printer in use ?
		JR	NZ,CL_SET_2	; forward to CL_SET_2 if so.

		LD	A,B		; transfer line to A.
		BIT	0,(IY+$02)	; test TV_FLAG  - lower screen in use ?
		JR	Z,CL_SET_1	; skip to CL_SET_1 if handling upper part

		ADD	A,(IY+$31)	; add DF_SZ for lower screen
		SUB	$18		; and adjust.

					;;;$0DEE
CL_SET_1:	PUSH	BC		; save the line/column.
		LD	B,A		; transfer line to B
					; (adjusted if lower screen)
		CALL	CL_ADDR		; routine CL_ADDR calculates address at left of screen.
		POP	BC		; restore the line/column.

					;;;$0DF4
CL_SET_2:	LD	A,$21		; the column $1-$21 is reversed
		SUB	C		; to range $00 - $20
		LD	E,A		; now transfer to DE
		LD	D,$00		; prepare for addition
		ADD	HL,DE		; and add to base address
		JP	PO_STORE	; exit via PO_STORE to update relevant
					; system variables.
;-----------------
; Handle scrolling
;-----------------
; The routine CL_SC_ALL is called once from PO to scroll all the display
; and from the routine CL_SCROLL, once, to scroll part of the display.

					;;;$0DFE
CL_SC_ALL:	LD	B,$17		; scroll 23 lines, after 'scroll?'.

					;;;$0E00
CL_SCROLL:	CALL	CL_ADDR		; routine CL_ADDR gets screen address in HL.
		LD	C,$08		; there are 8 pixel lines to scroll.

					;;;$0E05
CL_SCR_1:	PUSH	BC		; save counters.
		PUSH	HL		; and initial address.
		LD	A,B		; get line count.
		AND	$07		; will set zero if all third to be scrolled.
		LD	A,B		; re-fetch the line count.
		JR	NZ,CL_SCR_3	; forward to CL_SCR_3 if partial scroll.

					; HL points to top line of third and must be copied to bottom of previous 3rd.
					; ( so HL = $4800 or $5000 ) ( but also sometimes $4000 )

					;;;$0E0D
CL_SCR_2:	EX	DE,HL		; copy HL to DE.
		LD	HL,$F8E0	; subtract $08 from H and add $E0 to L -
		ADD	HL,DE		; to make destination bottom line of previous third.
		EX	DE,HL		; restore the source and destination.
		LD	BC,$0020	; thirty-two bytes are to be copied.
		DEC	A		; decrement the line count.
		LDIR			; copy a pixel line to previous third.

					;;;$0E19
CL_SCR_3:	EX	DE,HL		; save source in DE.
		LD	HL,$FFE0	; load the value -32.
		ADD	HL,DE		; add to form destination in HL.
		EX	DE,HL		; switch source and destination
		LD	B,A		; save the count in B.
		AND	$07		; mask to find count applicable to current
		RRCA			; third and
		RRCA			; multiply by
		RRCA			; thirty two (same as 5 RLCAs)
		LD	C,A		; transfer byte count to C ($E0 at most)
		LD	A,B		; store line count to A
		LD	B,$00		; make B zero
		LDIR			; copy bytes (BC=0, H incremented, L=0)
		LD	B,$07		; set B to 7, C is zero.
		ADD	HL,BC		; add 7 to H to address next third.
		AND	$F8		; has last third been done ?
		JR	NZ,CL_SCR_2	; back to CL_SCR_2 if not

		POP	HL		; restore topmost address.
		INC	H		; next pixel line down.
		POP	BC		; restore counts.
		DEC	C		; reduce pixel line count.
		JR	NZ,CL_SCR_1	; back to CL_SCR_1 if all eight not done.

		CALL	CL_ATTR		; routine CL_ATTR gets address in attributes
					; from current 'ninth line', count in BC.
		LD	HL,$FFE0	; set HL to the 16-bit value -32.
		ADD	HL,DE		; and add to form destination address.
		EX	DE,HL		; swap source and destination addresses.
		LDIR			; copy bytes scrolling the linear attributes.
		LD	B,$01		; continue to clear the bottom line.

;----------------------------
; Clear text lines of display
;----------------------------
; This subroutine, called from CL_ALL, CLS_LOWER and AUTO_LIST and above,
; clears text lines at bottom of display.
; The B register holds on entry the number of lines to be cleared 1-24.

					;;;$0E44
CL_LINE:	PUSH	BC		; save line count
		CALL	CL_ADDR		; routine CL_ADDR gets top address
		LD	C,$08		; there are eight screen lines to a text line.

					;;;$0E4A
CL_LINE_1:	PUSH	BC		; save pixel line count
		PUSH	HL		; and save the address
		LD	A,B		; transfer the line to A (1-24).

					;;;$0E4D
CL_LINE_2:	AND	$07		; mask 0-7 to consider thirds at a time
		RRCA			; multiply
		RRCA			; by 32  (same as five RLCA instructions)
		RRCA			; now 32 - 256(0)
		LD	C,A		; store result in C
		LD	A,B		; save line in A (1-24)
		LD	B,$00		; set high byte to 0, prepare for ldir.
		DEC	C		; decrement count 31-255.
		LD	D,H		; copy HL
		LD	E,L		; to DE.
		LD	(HL),$00	; blank the first byte.
		INC	DE		; make DE point to next byte.
		LDIR			; ldir will clear lines.
		LD	DE,$0701	; now address next third adjusting
		ADD	HL,DE		; register E to address left hand side
		DEC	A		; decrease the line count.
		AND	$F8		; will be 16, 8 or 0  (AND $18 will do).
		LD	B,A		; transfer count to B.
		JR	NZ,CL_LINE_2	; back to CL_LINE_2 if 16 or 8 to do
					; the next third.
		POP	HL		; restore start address.
		INC	H		; address next line down.
		POP	BC		; fetch counts.
		DEC	C		; decrement pixel line count
		JR	NZ,CL_LINE_1	; back to CL_LINE_1 till all done.

		CALL	CL_ATTR		; routine CL_ATTR gets attribute address
					; in DE and B * 32 in BC.
		LD	H,D		; transfer the address
		LD	L,E		; to HL.
		INC	DE		; make DE point to next location.
		LD	A,(ATTRP_MASKP)	; fetch ATTR_P - permanent attributes
		BIT	0,(IY+$02)	; test TV_FLAG  - lower screen in use ?
		JR	Z,CL_LINE_3	; skip to CL_LINE_3 if not.

		LD	A,(BORDCR)	; else lower screen uses BORDCR as attribute.

					;;;$0E80
CL_LINE_3:	LD	(HL),A		; put attribute in first byte.
		DEC	BC		; decrement the counter.
		LDIR			; copy bytes to set all attributes.
		POP	BC		; restore the line $01-$24.
		LD	C,$21		; make column $21. (No use is made of this)
		RET			; return to the calling routine.

;-------------------
; Attribute handling
;-------------------
; This subroutine is called from CL_LINE or CL_SCROLL with the HL register
; pointing to the 'ninth' line and H needs to be decremented before or after
; the division. Had it been done first then either present code or that used
; at the start of PO_ATTR could have been used.
; The Spectrum screen arrangement leads to the L register holding already
; the correct value for the attribute file and it is only necessary
; to manipulate H to form the correct colour attribute address.

					;;;$0E88
CL_ATTR:	LD	A,H		; fetch H to A - $48, $50, or $58.
		RRCA			; divide by
		RRCA			; eight.
		RRCA			; $09, $0A or $0B.
		DEC	A		; $08, $09 or $0A.
		OR	$50		; $58, $59 or $5A.
		LD	H,A		; save high byte of attributes.
		EX	DE,HL		; transfer attribute address to DE
		LD	H,C		; set H to zero - from last LDIR.
		LD	L,B		; load L with the line from B.
		ADD	HL,HL		; multiply
		ADD	HL,HL		; by
		ADD	HL,HL		; thirty two
		ADD	HL,HL		; to give count of attribute
		ADD	HL,HL		; cells to end of display.
		LD	B,H		; transfer result
		LD	C,L		; to register BC.
		RET			; and return.

;--------------------------------
; Handle display with line number
;--------------------------------
; This subroutine is called from four places to calculate the address
; of the start of a screen character line which is supplied in B.

					;;;$0E9B
CL_ADDR:	LD	A,$18		; reverse the line number
		SUB	B		; to range $00 - $17.
		LD	D,A		; save line in D for later.
		RRCA			; multiply
		RRCA			; by
		RRCA			; thirty-two.
		AND	$E0		; mask off low bits to make
		LD	L,A		; L a multiple of 32.
		LD	A,D		; bring back the line to A.
		AND	$18		; now $00, $08 or $10.
		OR	$40		; add the base address of screen.
		LD	H,A		; HL now has the correct address.
		RET			; return.

;--------------------
; Handle COPY command
;--------------------
; This command copies the top 176 lines to the ZX Printer
; It is popular to call this from machine code at point
; L0EAF with B holding 192 (and interrupts disabled) for a full-screen
; copy. This particularly applies to 16K Spectrums as time-critical
; machine code routines cannot be written in the first 16K of RAM as
; it is shared with the ULA which has precedence over the Z80 chip.

					;;;$0EAC
COPY:		DI			; disable interrupts as this is time-critical.
		LD	B,$B0		; top 176 lines.
L0EAF:		LD	HL,$4000	; address start of the display file.

					; now enter a loop to handle each pixel line.

					;;;$0EB2
COPY_1:		PUSH	HL		; save the screen address.
		PUSH	BC		; and the line counter.
		CALL	COPY_LINE	; routine COPY_LINE outputs one line.
		POP	BC		; restore the line counter.
		POP	HL		; and display address.
		INC	H		; next line down screen within 'thirds'.
		LD	A,H		; high byte to A.
		AND	$07		; result will be zero if we have left third.
		JR	NZ,COPY_2	; forward to COPY_2 if not to continue loop.

		LD	A,L		; consider low byte first.
		ADD	A,$20		; increase by 32 - sets carry if back to zero.
		LD	L,A		; will be next group of 8.
		CCF			; complement - carry set if more lines in the previous third.
		SBC	A,A		; will be FF, if more, else 00.
		AND	$F8		; will be F8 (-8) or 00.
		ADD	A,H		; that is subtract 8, if more to do in third.
		LD	H,A		; and reset address.

					;;;$0EC9
COPY_2:		DJNZ	COPY_1		; back to COPY_1 for all lines.
		JR	COPY_END	; forward to COPY_END to switch off the printer
					; motor and enable interrupts.
					; Note. Nothing else required.

;-------------------------------
; Pass printer buffer to printer
;-------------------------------
; This routine is used to copy 8 text lines from the printer buffer
; to the ZX Printer. These text lines are mapped linearly so HL does
; not need to be adjusted at the end of each line.

					;;;$0ECD
COPY_BUFF:	DI			; disable interrupts
		LD	HL,$5B00	; the base address of the Printer Buffer.
		LD	B,$08		; set count to 8 lines of 32 bytes.

					;;;$0ED3
COPY_3:		PUSH	BC		; save counter.
		CALL	COPY_LINE	; routine COPY_LINE outputs 32 bytes
		POP	BC		; restore counter.
		DJNZ	COPY_3		; loop back to COPY_3 for all 8 lines.
					; then stop motor and clear buffer.

					; Note. the COPY command rejoins here, essentially to execute the next
					; three instructions.

					;;;$0EDA
COPY_END:	LD	A,$04		; output value 4 to port
		OUT	($FB),A		; to stop the slowed printer motor.
		EI			; enable interrupts.

;---------------------
; Clear Printer Buffer
;---------------------
; This routine clears an arbitrary 256 bytes of memory.
; Note. The routine seems designed to clear a buffer that follows the
; system variables.
; The routine should check a flag or HL address and simply return if COPY
; is in use.
; (T-ADDR-lo would work for the system but not if COPY called externally.)
; As a consequence of this omission the buffer will needlessly
; be cleared when COPY is used and the screen/printer position may be set to
; the start of the buffer and the line number to 0 (B)
; giving an 'Out of Screen' error.
; There seems to have been an unsuccessful attempt to circumvent the use
; of PR_CC_hi.

					;;;$0EDF
CLEAR_PRB:	LD	HL,$5B00	; the location of the buffer.
		LD	(IY+$46),L	; update PR_CC_lo - set to zero - superfluous.
		XOR	A		; clear the accumulator.
		LD	B,A		; set count to 256 bytes.

					;;;$0EE7
PRB_BYTES:	LD	(HL),A		; set addressed location to zero.
		INC	HL		; address next byte - Note. not INC L.
		DJNZ	PRB_BYTES	; back to PRB_BYTES. repeat for 256 bytes.
		RES	1,(IY+$30)	; set FLAGS2 - signal printer buffer is clear.
		LD	C,$21		; set the column position .
		JP	CL_SET		; exit via CL_SET and then PO_STORE.

;------------------
; Copy line routine
;------------------
; This routine is called from COPY and COPY_BUFF to output a line of
; 32 bytes to the ZX Printer.
; Output to port $FB -
; bit 7 set - activate stylus.
; bit 7 low - deactivate stylus.
; bit 2 set - stops printer.
; bit 2 reset - starts printer
; bit 1 set - slows printer.
; bit 1 reset - normal speed.

					;;;$0EF4
COPY_LINE:	LD	A,B		; fetch the counter 1-8 or 1-176
		CP	$03		; is it 01 or 02 ?.
		SBC	A,A		; result is $FF if so else $00.
		AND	$02		; result is 02 now else 00.
					; bit 1 set slows the printer.
		OUT	($FB),A		; slow the printer for the
					; last two lines.
		LD	D,A		; save the mask to control the printer later.

					;;;$0EFD
COPY_L_1:	CALL	BREAK_KEY	; call BREAK_KEY to read keyboard immediately.
		JR	C,COPY_L_2	; forward to COPY_L_2 if 'break' not pressed.

		LD	A,$04		; else stop the
		OUT	($FB),A		; printer motor.
		EI			; enable interrupts.
		CALL	CLEAR_PRB	; call routine CLEAR_PRB.
					; Note. should not be cleared if COPY in use.

					;;;$0F0A
REPORT_DC:	RST	08H		; ERROR_1
		DEFB	$0C		; Error Report: BREAK - CONT repeats

					;;;$0F0C
COPY_L_2:	IN	A,($FB)		; test now to see if
		ADD	A,A		; a printer is attached.
		RET	M		; return if not - but continue with parent
					; command.
		JR	NC,COPY_L_1	; back to COPY_L_1 if stylus of printer not
					; in position.
		LD	C,$20		; set count to 32 bytes.

					;;;$0F14
COPY_L_3:	LD	E,(HL)		; fetch a byte from line.
		INC	HL		; address next location. Note. not INC L.
		LD	B,$08		; count the bits.

					;;;$0F18
COPY_L_4:	RL	D		; prepare mask to receive bit.
		RL	E		; rotate leftmost print bit to carry
		RR	D		; and back to bit 7 of D restoring bit 1

					;;;$0F1E
COPY_L_5:	IN	A,($FB)		; read the port.
		RRA			; bit 0 to carry.
		JR	NC,COPY_L_5	; back to COPY_L_5 if stylus not in position.

		LD	A,D		; transfer command bits to A.
		OUT	($FB),A		; and output to port.
		DJNZ	COPY_L_4	; loop back to COPY_L_4 for all 8 bits.
		DEC	C		; decrease the byte count.
		JR	NZ,COPY_L_3	; back to COPY_L_3 until 256 bits done.

		RET			; return to calling routine COPY/COPY_BUFF.


;-----------------------------------
; Editor routine for BASIC and INPUT
;-----------------------------------
; The editor is called to prepare or edit a basic line.
; It is also called from INPUT to input a numeric or string expression.
; The behaviour and options are quite different in the various modes
; and distinguished by bit 5 of FLAGX.
;
; This is a compact and highly versatile routine.

					;;;$0F2C
EDITOR:		LD	HL,(ERR_SP)	; fetch ERR_SP
		PUSH	HL		; save on stack

					;;;$0F30
ED_AGAIN:	LD	HL,ED_ERROR	; address: ED_ERROR
		PUSH	HL		; save address on stack and
		LD	(ERR_SP),SP	; make ERR_SP point to it.

					; Note. While in editing/input mode should an error occur then RST 08 will
					; update X_PTR to the location reached by CH_ADD and jump to ED_ERROR
					; where the error will be cancelled and the loop begin again from ED_AGAIN
					; above. The position of the error will be apparent when the lower screen is
					; reprinted. If no error then the re-iteration is to ED_LOOP below when
					; input is arriving from the keyboard.

					;;;$0F38
ED_LOOP:	CALL	WAIT_KEY	; routine WAIT_KEY gets key possibly changing the mode.
		PUSH	AF		; save key.
		LD	D,$00		; and give a short click based
		LD	E,(IY-$01)	; on PIP value for duration.
		LD	HL,$00C8	; and pitch.
		CALL	BEEPER		; routine BEEPER gives click - effective with rubber keyboard.
		POP	AF		; get saved key value.
		LD	HL,ED_LOOP	; address: ED_LOOP is loaded to HL.
		PUSH	HL		; and pushed onto stack.

					; At this point there is a looping return address on the stack, an error
					; handler and an input stream set up to supply characters.
					; The character that has been received can now be processed.

		CP	$18		; range 24 to 255 ?
		JR	NC,ADD_CHAR	; forward to ADD_CHAR if so.

		CP	$07		; lower than 7 ?
		JR	C,ADD_CHAR	; forward to ADD_CHAR also.
					; Note. This is a 'bug' and CHR$ 6, the comma
					; control character, should have had an
					; entry in the ED_KEYS table.
					; Steven Vickers, 1984, Pitman.
		CP	$10		; less than 16 ?
		JR	C,ED_KEYS	; forward to ED_KEYS if editing control
					; range 7 to 15 dealt with by a table
		LD	BC,$0002	; prepare for ink/paper etc.
		LD	D,A		; save character in D
		CP	$16		; is it ink/paper/bright etc. ?
		JR	C,ED_CONTR	; forward to ED_CONTR if so

					; leaves 22d AT and 23d TAB
					; which can't be entered via KEY_INPUT.
					; so this code is never normally executed
					; when the keyboard is used for input.

		INC	BC		; if it was AT/TAB - 3 locations required
		BIT	7,(IY+$37)	; test FLAGX  - Is this INPUT LINE ?
		JP	Z,ED_IGNORE	; jump to ED_IGNORE if not, else 

		CALL	WAIT_KEY	; routine WAIT_KEY - input address is KEY_NEXT
					; but is reset to KEY_INPUT
		LD	E,A		; save first in E

					;;;$0F6C
ED_CONTR:	CALL	WAIT_KEY	; routine WAIT_KEY for control.
					; input address will be KEY_NEXT.
		PUSH	DE		; saved code/parameters
		LD	HL,(K_CUR)	; fetch address of keyboard cursor from K_CUR
		RES	0,(IY+$07)	; set MODE to 'L'
		CALL	MAKE_ROOM	; routine MAKE_ROOM makes 2/3 spaces at cursor
		POP	BC		; restore code/parameters
		INC	HL		; address first location
		LD	(HL),B		; place code (ink etc.)
		INC	HL		; address next
		LD	(HL),C		; place possible parameter. If only one
					; then DE points to this location also.
		JR	ADD_CH_1	; forward to ADD_CH_1

;-------------------------
; Add code to current line
;-------------------------
; this is the branch used to add normal non-control characters
; with ED_LOOP as the stacked return address.
; it is also the OUTPUT service routine for system channel 'R'.

					;;;$0F81
ADD_CHAR:	RES	0,(IY+$07)	; set MODE to 'L'
		LD	HL,(K_CUR)	; fetch address of keyboard cursor from K_CUR
		CALL	ONE_SPACE	; routine ONE_SPACE creates one space.

					; either a continuation of above or from ED_CONTR with ED_LOOP on stack.

					;;;$0F8B
ADD_CH_1:	LD	(DE),A		; load current character to last new location.
		INC	DE		; address next
		LD	(K_CUR),DE	; and update K_CUR system variable.
		RET			; return - either a simple return
					; from ADD_CHAR or to ED_LOOP on stack.

					; a branch of the editing loop to deal with control characters
					; using a look-up table.

					;;;$0F92
ED_KEYS:	LD	E,A		; character to E.
		LD	D,$00		; prepare to add.
		LD	HL,ED_KEYS_T - 7; base address of editing keys table. $0F99
		ADD	HL,DE		; add E
		LD	E,(HL)		; fetch offset to E
		ADD	HL,DE		; add offset for address of handling routine.
		PUSH	HL		; push the address on machine stack.
		LD	HL,(K_CUR)	; load address of cursor from K_CUR.
		RET			; an make an indirect jump forward to routine.

;-------------------
; Editing keys table
;-------------------
; For each code in the range $07 to $0F this table contains a
; single offset byte to the routine that services that code.
; Note. for what was intended there should also have been an
; entry for CHR$ 6 with offset to ED_SYMBOL.

					;;;$0FA0
ED_KEYS_T:	DEFB	ED_EDIT - $	; 07d offset $09 to Address: ED_EDIT
		DEFB	ED_LEFT - $	; 08d offset $66 to Address: ED_LEFT
		DEFB	ED_RIGHT - $	; 09d offset $6A to Address: ED_RIGHT
		DEFB	ED_DOWN - $	; 10d offset $50 to Address: ED_DOWN
		DEFB	ED_UP - $	; 11d offset $B5 to Address: ED_UP
		DEFB	ED_DELETE - $	; 12d offset $70 to Address: ED_DELETE
		DEFB	ED_ENTER - $	; 13d offset $7E to Address: ED_ENTER
		DEFB	ED_SYMBOL - $	; 14d offset $CF to Address: ED-SYMBOL
		DEFB	ED_GRAPH - $	; 15d offset $D4 to Address: ED_GRAPH

;----------------
; Handle EDIT key
;----------------
; The user has pressed SHIFT 1 to bring edit line down to bottom of screen.
; Alternatively the user wishes to clear the input buffer and start again.
; Alternatively ...

					;;;$0FA9
ED_EDIT:	LD	HL,(E_PPC)	; fetch E_PPC the last line number entered.
					; Note. may not exist and may follow program.
		BIT	5,(IY+$37)	; test FLAGX  - input mode ?
		JP	NZ,CLEAR_SP	; jump forward to CLEAR_SP if not in editor.

		CALL	LINE_ADDR	; routine LINE_ADDR to find address of line
					; or following line if it doesn't exist.
		CALL	LINE_NO		; routine LINE_NO will get line number from
					; address or previous line if at end-marker.
		LD	A,D		; if there is no program then DE will
		OR	E		; contain zero so test for this.
		JP	Z,CLEAR_SP	; jump to to CLEAR_SP if so.

					; Note. at this point we have a validated line number, not just an
					; approximation and it would be best to update E_PPC with the true
					; cursor line value which would enable the line cursor to be suppressed
					; in all situations - see shortly.

		PUSH	HL		; save address of line.
		INC	HL		; address low byte of length.
		LD	C,(HL)		; transfer to C
		INC	HL		; next to high byte
		LD	B,(HL)		; transfer to B.
		LD	HL,$000A	; an overhead of ten bytes
		ADD	HL,BC		; is added to length.
		LD	B,H		; transfer adjusted value
		LD	C,L		; to BC register.
		CALL	TEST_ROOM	; routine TEST_ROOM checks free memory.
		CALL	CLEAR_SP	; routine CLEAR_SP clears editing area.
		LD	HL,(CURCHL)	; address CURCHL
		EX	(SP),HL		; swap with line address on stack
		PUSH	HL		; save line address underneath
		LD	A,$FF		; select system channel 'R'
		CALL	CHAN_OPEN	; routine CHAN_OPEN opens it
		POP	HL		; drop line address
		DEC	HL		; make it point to first byte of line num.
		DEC	(IY+$0F)	; decrease E_PPC_LO to suppress line cursor.
					; Note. ineffective when E_PPC is one
					; greater than last line of program perhaps
					; as a result of a delete.
					; credit. Paul Harrison 1982.

		CALL	OUT_LINE	; routine OUT_LINE outputs the BASIC line
					; to the editing area.
		INC	(IY+$0F)	; restore E_PPC_LO to the previous value.
		LD	HL,(E_LINE)	; address E_LINE in editing area.
		INC	HL		; advance
		INC	HL		; past space
		INC	HL		; and digit characters
		INC	HL		; of line number.
		LD	(K_CUR),HL	; update K_CUR to address start of BASIC.
		POP	HL		; restore the address of CURCHL.
		CALL	CHAN_FLAG	; routine CHAN_FLAG sets flags for it.
		RET			; return to ED_LOOP.

;--------------------
; Cursor down editing
;--------------------
; The basic lines are displayed at the top of the screen and the user
; wishes to move the cursor down one line in edit mode.
; In input mode this key can be used as an alternative to entering STOP.

					;;;$0FF3
ED_DOWN:	BIT	5,(IY+$37)	; test FLAGX  - Input Mode ?
		JR	NZ,ED_STOP	; skip to ED_STOP if so

		LD	HL,E_PPC	; address E_PPC - 'current line'
		CALL	LN_FETCH	; routine LN_FETCH fetches number of next
					; line or same if at end of program.
		JR	ED_LIST		; forward to ED_LIST to produce an
					; automatic listing.

					;;;$1001
ED_STOP:	LD	(IY+$00),$10	; set ERR_NR to 'STOP in INPUT' code
		JR	ED_ENTER	; forward to ED_ENTER to produce error.

;--------------------
; Cursor left editing
;--------------------
; This acts on the cursor in the lower section of the screen in both
; editing and input mode.

					;;;$1007
ED_LEFT:	CALL	ED_EDGE		; routine ED_EDGE moves left if possible
		JR	ED_CUR		; forward to ED_CUR to update K-CUR
					; and return to ED_LOOP.

;---------------------
; Cursor right editing
;---------------------
; This acts on the cursor in the lower screen in both editing and input
; mode and moves it to the right.

					;;;$100C
ED_RIGHT:	LD	A,(HL)		; fetch addressed character.
		CP	$0D		; is it carriage return ?
		RET	Z		; return if so to ED_LOOP

		INC	HL		; address next character

					;;;$1011
ED_CUR:		LD	(K_CUR),HL	; update K_CUR system variable
		RET			; return to ED_LOOP

;---------------
; DELETE editing
;---------------
; This acts on the lower screen and deletes the character to left of
; cursor. If control characters are present these are deleted first
; leaving the naked parameter (0-7) which appears as a '?' except in the
; case of CHR$ 6 which is the comma control character. It is not mandatory
; to delete these second characters.

					;;;$1015
ED_DELETE:	CALL	ED_EDGE		; routine ED_EDGE moves cursor to left.
		LD	BC,$0001	; of character to be deleted.
		JP	RECLAIM_2	; to RECLAIM_2 reclaim the character.

;-------------------------------------------
; Ignore next 2 codes from KEY_INPUT routine
;-------------------------------------------
; Since AT and TAB cannot be entered this point is never reached
; from the keyboard. If inputting from a tape device or network then
; the control and two following characters are ignored and processing
; continues as if a carriage return had been received.
; Here, perhaps, another Spectrum has said print #15; AT 0,0; "This is yellow"
; and this one is interpreting input #15; a$.

					;;;$101E
ED_IGNORE:	CALL	WAIT_KEY	; routine WAIT_KEY to ignore keystroke.
		CALL	WAIT_KEY	; routine WAIT_KEY to ignore next key.

;--------------
; Enter/newline
;--------------
; The enter key has been pressed to have basic line or input accepted.

					;;;$1024
ED_ENTER:	POP	HL		; discard address ED_LOOP
		POP	HL		; drop address ED_ERROR

					;;;$1026
ED_END:		POP	HL		; the previous value of ERR_SP
		LD	(ERR_SP),HL	; is restored to ERR_SP system variable
		BIT	7,(IY+$00)	; is ERR_NR $FF (= 'OK') ?
		RET	NZ		; return if so
		LD	SP,HL		; else put error routine on stack
		RET			; and make an indirect jump to it.

;------------------------------
; Move cursor left when editing
;------------------------------
; This routine moves the cursor left. The complication is that it must
; not position the cursor between control codes and their parameters.
; It is further complicated in that it deals with TAB and AT characters
; which are never present from the keyboard.
; The method is to advance from the beginning of the line each time,
; jumping one, two, or three characters as necessary saving the original
; position at each jump in DE. Once it arrives at the cursor then the next
; legitimate leftmost position is in DE.

					;;;$1031
ED_EDGE:	SCF			; carry flag must be set to call the nested
		CALL	SET_DE		; subroutine SET_DE.
					; if input   then DE=WORKSP
					; if editing then DE=E_LINE
		SBC	HL,DE		; subtract address from start of line
		ADD	HL,DE		; and add back.
		INC	HL		; adjust for carry.
		POP	BC		; drop return address
		RET	C		; return to ED_LOOP if already at left of line.

		PUSH	BC		; resave return address - ED_LOOP.
		LD	B,H		; transfer HL - cursor address
		LD	C,L		; to BC register pair.
					; at this point DE addresses start of line.

					;;;$103E
ED_EDGE_1:	LD	H,D		; transfer DE - leftmost pointer
		LD	L,E		; to HL
		INC	HL		; address next leftmost character to advance position each time.
		LD	A,(DE)		; pick up previous in A
		AND	$F0		; lose the low bits
		CP	$10		; is it INK to TAB $10-$1F ?
					; that is, is it followed by a parameter ?
		JR	NZ,ED_EDGE_2	; to ED_EDGE_2 if not
					; HL has been incremented once

		INC	HL		; address next as at least one parameter.

					; in fact since 'tab' and 'at' cannot be entered the next section seems
					; superfluous.
					; The test will always fail and the jump to ED_EDGE_2 will be taken.

		LD	A,(DE)		; reload leftmost character
		SUB	$17		; decimal 23 ('tab')
		ADC	A,$00		; will be 0 for 'tab' and 'at'.
		JR	NZ,ED_EDGE_2	; forward to ED_EDGE_2 if not
					; HL has been incremented twice
		INC	HL		; increment a third time for 'at'/'tab'

					;;;$1051
ED_EDGE_2:	AND	A		; prepare for true subtraction
		SBC	HL,BC		; subtract cursor address from pointer
		ADD	HL,BC		; and add back
					; Note when HL matches the cursor position BC,
					; there is no carry and the previous
					; position is in DE.
		EX	DE,HL		; transfer result to DE if looping again.
					; transfer DE to HL to be used as K-CUR
					; if exiting loop.
		JR	C,ED_EDGE_1	; back to ED_EDGE_1 if cursor not matched.

		RET			; return.

;------------------
; Cursor up editing
;------------------
; The main screen displays part of the BASIC program and the user wishes
; to move up one line scrolling if necessary.
; This has no alternative use in input mode.

					;;;$1059
ED_UP:		BIT	5,(IY+$37)	; test FLAGX  - input mode ?
		RET	NZ		; return if not in editor - to ED_LOOP.

		LD	HL,(E_PPC)	; get current line from E_PPC
		CALL	LINE_ADDR	; routine LINE_ADDR gets address
		EX	DE,HL		; and previous in DE
		CALL	LINE_NO		; routine LINE_NO gets prev line number
		LD	HL,E_PPC_HI	; set HL to E_PPC_HI as next routine stores top first.
		CALL	LN_STORE	; routine LN_STORE loads DE value to HL
					; high byte first - E_PPC_LO takes E

					; this branch is also taken from ED_DOWN.

					;;;$106E
ED_LIST:	CALL	AUTO_LIST	; routine AUTO_LIST lists to upper screen
					; including adjusted current line.
		LD	A,$00		; select lower screen again
		JP	CHAN_OPEN	; exit via CHAN_OPEN to ED_LOOP

;---------------------------------
; Use of symbol and graphics codes
;---------------------------------
; These will not be encountered with the keyboard but would be handled
; otherwise as follows.
; As noted earlier, Vickers says there should have been an entry in
; the KEYS table for CHR$ 6 which also pointed here.
; If, for simplicity, two Spectrums were both using #15 as a bi-directional
; channel connected to each other:-
; then when the other Spectrum has said PRINT #15; x, y
; input #15; i ; j  would treat the comma control as a newline and the
; control would skip to input j.
; You can get round the missing CHR$ 6 handler by sending multiple print
; items separated by a newline '.

; CHR$ 14 would have the same functionality.

; This is CHR$ 14.
					;;;$1076
ED_SYMBOL:	BIT	7,(IY+$37)	; test FLAGX - is this INPUT LINE ?
		JR	Z,ED_ENTER	; back to ED_ENTER if not to treat as if
					; enter had been pressed.
					; else continue and add code to buffer.

					; Next is CHR$ 15
					; Note that ADD_CHAR precedes the table so we can't offset to it directly.

					;;;$107C
ED_GRAPH:	JP	ADD_CHAR	; jump back to ADD_CHAR

;---------------------
; Editor error routine
;---------------------
; If an error occurs while editing, or inputting, then ERR_SP
; points to the stack location holding address ED_ERROR.

					;;;$107F
ED_ERROR:	BIT	4,(IY+$30)	; test FLAGS2  - is K channel in use ?
		JR	Z,ED_END	; back to ED_END if not.

					; but as long as we're editing lines or inputting from the keyboard, then
					; we've run out of memory so give a short rasp.

		LD	(IY+$00),$FF	; reset ERR_NR to 'OK'.
		LD	D,$00		; prepare for beeper.
		LD	E,(IY-$02)	; use RASP value.
		LD	HL,$1A90	; set a duration.
		CALL	BEEPER		; routine BEEPER emits a warning rasp.
		JP	ED_AGAIN	; to ED_AGAIN to re-stack address of
					; this routine and make ERR_SP point to it.

;----------------------
; Clear edit/work space
;----------------------
; The editing area or workspace is cleared depending on context.
; This is called from ED_EDIT to clear workspace if edit key is
; used during input, to clear editing area if no program exists
; and to clear editing area prior to copying the edit line to it.
; It is also used by the error routine to clear the respective
; area depending on FLAGX.

					;;;$1097
CLEAR_SP:	PUSH	HL		; preserve HL
		CALL	SET_HL		; routine SET_HL
					; if in edit   HL = WORKSP-1, DE = E_LINE
					; if in input  HL = STKBOT,   DE = WORKSP
		DEC	HL		; adjust
		CALL	RECLAIM_1	; routine RECLAIM_1 reclaims space
		LD	(K_CUR),HL	; set K_CUR to start of empty area
		LD	(IY+$07),$00	; set MODE to 'KLC'
		POP	HL		; restore HL.
		RET			; return.

;----------------------
; Handle keyboard input
;----------------------
; This is the service routine for the input stream of the keyboard
; channel 'K'.

					;;;$10A8
KEY_INPUT:	BIT	3,(IY+$02)	; test TV_FLAG  - has a key been pressed in editor ?
		CALL	NZ,ED_COPY	; routine ED_COPY if so to reprint the lower
					; screen at every keystroke.
		AND	A		; clear carry - required exit condition.
		BIT	5,(IY+$01)	; test FLAGS  - has a new key been pressed ?
		RET	Z		; return if not.

		LD	A,(LASTK)	; system variable LASTK will hold last key -
					; from the interrupt routine.
		RES	5,(IY+$01)	; update FLAGS  - reset the new key flag.
		PUSH	AF		; save the input character.
		BIT	5,(IY+$02)	; test TV_FLAG  - clear lower screen ?
		CALL	NZ,CLS_LOWER	; routine CLS_LOWER if so.
		POP	AF		; restore the character code.
		CP	$20		; if space or higher then
		JR	NC,KEY_DONE2	; forward to KEY_DONE2 and return with carry
					; set to signal key-found.
		CP	$10		; with 16d INK and higher skip
		JR	NC,KEY_CONTR	; forward to KEY_CONTR.

		CP	$06		; for 6 - 15d
		JR	NC,KEY_M_CL	; skip forward to KEY_M_CL to handle Modes
					; and CapsLock.

					; that only leaves 0-5, the flash bright inverse switches.

		LD	B,A		; save character in B
		AND	$01		; isolate the embedded parameter (0/1).
		LD	C,A		; and store in C
		LD	A,B		; re-fetch copy (0-5)
		RRA			; halve it 0, 1 or 2.
		ADD	A,$12		; add 18d gives 'flash', 'bright' and 'inverse'.
		JR	KEY_DATA	; forward to KEY_DATA with the 
					; parameter (0/1) in C.

					; Now separate capslock 06 from modes 7-15.

					;;;$10DB
KEY_M_CL:	JR	NZ,KEY_MODE	; forward to KEY_MODE if not 06 (capslock)

		LD	HL,FLAGS2	; point to FLAGS2
		LD	A,$08		; value 00000100
		XOR	(HL)		; toggle BIT 2 of FLAGS2 the capslock bit
		LD	(HL),A		; and store result in FLAGS2 again.
		JR	KEY_FLAG	; forward to KEY_FLAG to signal no-key.

					;;;$10E6
KEY_MODE:	CP	$0E		; compare with chr 14d
		RET	C		; return with carry set "key found" for
					; codes 7 - 13d leaving 14d and 15d
					; which are converted to mode codes.
		SUB	$0D		; subtract 13d leaving 1 and 2
					; 1 is 'E' mode, 2 is 'G' mode.
		LD	HL,MODE		; address the MODE system variable.
		CP	(HL)		; compare with existing value before
		LD	(HL),A		; inserting the new value.
		JR	NZ,KEY_FLAG	; forward to KEY_FLAG if it has changed.

		LD	(HL),$00	; else make MODE zero - KLC mode
					; Note. while in Extended/Graphics mode,
					; the Extended Mode/Graphics key is pressed
					; again to get out.

					;;;$10F4
KEY_FLAG:	SET	3,(IY+$02)	; update TV_FLAG  - show key state has changed
		CP	A		; clear carry and reset zero flags - no actual key returned.
		RET			; make the return.

					; now deal with colour controls - 16-23 ink, 24-31 paper

					;;;$10FA
KEY_CONTR:	LD	B,A		; make a copy of character.
		AND	$07		; mask to leave bits 0-7
		LD	C,A		; and store in C.
		LD	A,$10		; initialize to 16d - INK.
		BIT	3,B		; was it paper ?
		JR	NZ,KEY_DATA	; forward to KEY_DATA with INK 16d and colour in C.

		INC	A		; else change from INK to PAPER (17d) if so.

					;;;$1105
KEY_DATA:	LD	(IY-$2D),C	; put the colour (0-7)/state(0/1) in KDATA
		LD	DE,KEY_NEXT	; address: KEY_NEXT will be next input stream
		JR	KEY_CHAN	; forward to KEY_CHAN to change it ...

					; ... so that INPUT_AD directs control to here at next call to WAIT_KEY

					;;;$110D
KEY_NEXT:	LD	A,(KDATA)	; pick up the parameter stored in KDATA.
		LD	DE,KEY_INPUT	; address: KEY_INPUT will be next input stream
					; continue to restore default channel and
					; make a return with the control code.

					;;;$1113
KEY_CHAN:	LD	HL,(CHANS)	; address start of CHANNELS area using CHANS
					; Note. One might have expected CURCHL to
					; have been used.
		INC	HL		; step over the
		INC	HL		; output address
		LD	(HL),E		; and update the input
		INC	HL		; routine address for
		LD	(HL),D		; the next call to WAIT_KEY.

					;;;$111B
KEY_DONE2:	SCF			; set carry flag to show a key has been found
		RET			; and return.

;---------------------
; Lower screen copying
;---------------------
; This subroutine is called whenever the line in the editing area or
; input workspace is required to be printed to the lower screen.
; It is by calling this routine after any change that the cursor, for
; instance, appears to move to the left.
; Remember the edit line will contain characters and tokens
; e.g. "1000 LET a = 1" is 12 characters.

					;;;$111D
ED_COPY:	CALL	TEMPS		; routine TEMPS sets temporary attributes.
		RES	3,(IY+$02)	; update TV_FLAG - signal no change in mode
		RES	5,(IY+$02)	; update TV_FLAG - signal don't clear lower screen.
		LD	HL,(SPOSNL)	; fetch SPOSNL
		PUSH	HL		; and save on stack.
		LD	HL,(ERR_SP)	; fetch ERR_SP
		PUSH	HL		; and save also
		LD	HL,ED_FULL	; address: ED_FULL
		PUSH	HL		; is pushed as the error routine
		LD	(ERR_SP),SP	; and ERR_SP made to point to it.
		LD	HL,(ECHO_E)	; fetch ECHO_E
		PUSH	HL		; and push also
		SCF			; set carry flag to control SET_DE
		CALL	SET_DE		; call routine SET_DE
					; if in input DE = WORKSP
					; if in edit  DE = E_LINE
		EX	DE,HL		; start address to HL
		CALL	OUT_LINE2	; routine OUT_LINE2 outputs entire line up to
					; carriage return including initial
					; characterized line number when present.
		EX	DE,HL		; transfer new address to DE
		CALL	OUT_CURS	; routine OUT_CURS considers a terminating cursor.
		LD	HL,(SPOSNL)	; fetch updated SPOSNL
		EX	(SP),HL		; exchange with ECHO_E on stack
		EX	DE,HL		; transfer ECHO_E to DE
		CALL	TEMPS		; routine TEMPS to re-set attributes
					; if altered.

					; the lower screen was not cleared, at the outset, so if deleting then old
					; text from a previous print may follow this line and requires blanking.

					;;;$1150
ED_BLANK:	LD	A,(SPOSNL_HI)	; fetch SPOSNL_HI is current line
		SUB	D		; compare with old
		JR	C,ED_C_DONE	; forward to ED_C_DONE if no blanking

		JR	NZ,ED_SPACES	; forward to ED_SPACES if line has changed

		LD	A,E		; old column to A
		SUB	(IY+$50)	; subtract new in SPOSNL_lo
		JR	NC,ED_C_DONE	; forward to ED_C_DONE if no backfilling.

					;;;$115E
ED_SPACES:	LD	A,$20		; prepare a space.
		PUSH	DE		; save old line/column.
		CALL	PRINT_OUT	; routine PRINT_OUT prints a space over
					; any text from previous print.
					; Note. Since the blanking only occurs when
					; using $09F4 to print to the lower screen,
					; there is no need to vector via a RST 10
					; and we can use this alternate set.
		POP	DE		; restore the old line column.
		JR	ED_BLANK	; back to ED_BLANK until all old text blanked.

;--------
; ED_FULL
;--------
; this is the error routine addressed by ERR_SP. This is not for the out of
; memory situation as we're just printing. The pitch and duration are exactly
; the same as used by ED_ERROR from which this has been augmented. The
; situation is that the lower screen is full and a rasp is given to suggest
; that this is perhaps not the best idea you've had that day.

					;;;$1167
ED_FULL:	LD	D,$00		; prepare to moan.
		LD	E,(IY-$02)	; fetch RASP value.
		LD	HL,$1A90	; set duration.
		CALL	BEEPER		; routine BEEPER.
		LD	(IY+$00),$FF	; clear ERR_NR.
		LD	DE,(SPOSNL)	; fetch SPOSNL.
		JR	ED_C_END	; forward to ED_C_END

					; the exit point from line printing continues here.

					;;;$117C
ED_C_DONE:	POP	DE		; fetch new line/column.
		POP	HL		; fetch the error address.

					; the error path rejoins here.

					;;;$117E
ED_C_END:	POP	HL		; restore the old value of ERR_SP.
		LD	(ERR_SP),HL	; update the system variable ERR_SP
		POP	BC		; old value of SPOSN_L
		PUSH	DE		; save new value
		CALL	CL_SET		; routine CL_SET and PO_STORE
					; update ECHO_E and SPOSN_L from BC
		POP	HL		; restore new value
		LD	(ECHO_E),HL	; and update ECHO_E
		LD	(IY+$26),$00	; make error pointer X_PTR_HI out of bounds
		RET			; return

;------------------------------------------------
; Point to first and last locations of work space
;------------------------------------------------
; These two nested routines ensure that the appropriate pointers are
; selected for the editing area or workspace. The routines that call
; these routines are designed to work on either area.

; this routine is called once
					;;;$1190
SET_HL:		LD	HL,(WORKSP)	; fetch WORKSP to HL.
		DEC	HL		; point to last location of editing area.
		AND	A		; clear carry to limit exit points to first or last.

					; this routine is called with carry set and exits at a conditional return.

					;;;$1195
SET_DE:		LD	DE,(E_LINE)	; fetch E_LINE to DE
		BIT	5,(IY+$37)	; test FLAGX  - Input Mode ?
		RET	Z		; return now if in editing mode

		LD	DE,(WORKSP)	; fetch WORKSP to DE
		RET	C		; return if carry set ( entry = SET_DE)

		LD	HL,(STKBOT)	; fetch STKBOT to HL as well
		RET			; and return  (entry = SET_HL (in input))

;--------------------------------
; Remove floating point from line
;--------------------------------
; When a BASIC LINE or the INPUT BUFFER is parsed any numbers will have
; an invisible chr 14d inserted after them and the 5-byte integer or
; floating point form inserted after that. Similar invisible value holders
; are also created after the numeric and string variables in a DEF FN list.
; This routine removes these 'compiled' numbers from the edit line or
; input workspace.

					;;;$11A7
REMOVE_FP:	LD	A,(HL)		; fetch character
		CP	$0E		; is it the number marker ?
		LD	BC,$0006	; prepare for six bytes
		CALL	Z,RECLAIM_2	; routine RECLAIM_2 reclaims space if $0E
		LD	A,(HL)		; reload next (or same) character
		INC	HL		; and advance address
		CP	$0D		; end of line or input buffer ?
		JR	NZ,REMOVE_FP	; back to REMOVE_FP until entire line done.

		RET			; return


;*********************************
;** Part 6. EXECUTIVE ROUTINES  **
;*********************************

; The memory.
;
; +---------+-----------+------------+--------------+-------------+--
; | BASIC   |  Display  | Attributes | ZX Printer   |    System   | 
; |  ROM    |   File    |    File    |   Buffer     |  Variables  | 
; +---------+-----------+------------+--------------+-------------+--
; ^         ^           ^            ^              ^             ^
; $0000   $4000       $5800        $5B00          $5C00         $5CB6 = CHANS 
;
;
;  --+----------+---+---------+-----------+---+------------+--+---+--
;    | Channel  |$80|  Basic  | Variables |$80| Edit Line  |NL|$80|
;    |   Info   |   | Program |   Area    |   | or Command |  |   |
;  --+----------+---+---------+-----------+---+------------+--+---+--
;    ^              ^         ^               ^                   ^
;  CHANS           PROG      VARS           E_LINE              WORKSP
;
;
;                             ---5-->         <---2---  <--3---
;  --+-------+--+------------+-------+-------+---------+-------+-+---+------+
;    | INPUT |NL| Temporary  | Calc. | Spare | Machine | Gosub |?|$3E| UDGs |
;    | data  |  | Work Space | Stack |       |  Stack  | Stack | |   |      |
;  --+-------+--+------------+-------+-------+---------+-------+-+---+------+
;    ^                       ^       ^       ^                   ^   ^      ^
;  WORKSP                  STKBOT  STKEND   sp               RAMTOP UDG  P_RAMT
;                                                                         

;--------------------
; Handle NEW command
;--------------------
; The NEW command is about to set all RAM below RAMTOP to zero and
; then re-initialize the system. All RAM above RAMTOP should, and will be,
; preserved.
; There is nowhere to store values in RAM or on the stack which becomes
; inoperable. Similarly PUSH and CALL instructions cannot be used to
; store values or section common code. The alternate register set is the only
; place available to store 3 persistent 16-bit system variables.

					;;;$11B7
NEW:		DI			; disable interrupts - machine stack will be cleared.
		LD	A,$FF		; flag coming from NEW.
		LD	DE,(RAMTOP)	; fetch RAMTOP as top value.
		EXX			; switch in alternate set.
		LD	BC,(P_RAMT)	; fetch P_RAMT differs on 16K/48K machines.
		LD	DE,(RASP_PIP)	; fetch RASP/PIP.
		LD	HL,(UDG)	; fetch UDG    differs on 16K/48K machines.
		EXX			; switch back to main set and continue into...

;----------------------------
; Main entry (initialization)
;----------------------------
; This common code tests ram and sets it to zero re-initializing
; all the non-zero system variables and channel information.
; The A register tells if coming from START or NEW

					;;;$11CB
START_NEW:	LD	B,A		; save the flag for later branching.
		LD	A,$07		; select a white border
		OUT	($FE),A		; and set it now.
		LD	A,$3F		; load accumulator with last page in ROM.
		LD	I,A		; set the I register - this remains constant
					; and can't be in range $40 - $7F as 'snow'
					; appears on the screen.
		NOP			; these seem unnecessary.
		NOP
		NOP
		NOP
		NOP
		NOP

;-------------
; Check RAM
;-------------
; Typically a Spectrum will have 16K or 48K of Ram and this code will
; test it all till it finds an unpopulated location or, less likely, a
; faulty location. Usually it stops when it reaches the top $FFFF or
; in the case of NEW the supplied top value. The entire screen turns
; black with sometimes red stripes on black paper visible.

					;;;$11DA
RAM_CHECK:	LD	H,D		; transfer the top value to
		LD	L,E		; the HL register pair.

					;;;$11DC
RAM_FILL:	LD	(HL),$02	; load with 2 - red ink on black paper
		DEC	HL		; next lower
		CP	H		; have we reached ROM - $3F ?
		JR	NZ,RAM_FILL	; back to RAM_FILL if not.

					;;;$11E2
RAM_READ:	AND	A		; clear carry - prepare to subtract
		SBC	HL,DE		; subtract and add back setting
		ADD	HL,DE		; carry when back at start.
		INC	HL		; and increment for next iteration.
		JR	NC,RAM_DONE	; forward to RAM_DONE if we've got back to
					; starting point with no errors.
		DEC	(HL)		; decrement to 1.
		JR	Z,RAM_DONE	; forward to RAM_DONE if faulty.

		DEC	(HL)		; decrement to zero.
		JR	Z,RAM_READ	; back to RAM_READ if zero flag was set.

					;;;$11EF
RAM_DONE:	DEC	HL		; step back to last valid location.
		EXX			; regardless of state, set up possibly
					; stored system variables in case from NEW.
		LD	(P_RAMT),BC	; insert P_RAMT.
		LD	(RASP_PIP),DE	; insert RASP/PIP.
		LD	(UDG),HL	; insert UDG.
		EXX			; switch in main set.
		INC	B		; now test if we arrived here from NEW.
		JR	Z,RAM_SET	; forward to RAM_SET if we did.

					; this section applies to START only.

		LD	(P_RAMT),HL	; set P_RAMT to the highest working RAM address.
		LD	DE,$3EAF	; address of last byte of 'U' bitmap in ROM.
		LD	BC,$00A8	; there are 21 user defined graphics.
		EX	DE,HL		; switch pointers and make the UDGs a
		LDDR			; copy of the standard characters A - U.
		EX	DE,HL		; switch the pointer to HL.
		INC	HL		; update to start of 'A' in RAM.
		LD	(UDG),HL	; make UDG system variable address the first bitmap.
		DEC	HL		; point at RAMTOP again.
		LD	BC,$0040	; set the values of
		LD	(RASP_PIP),BC	; the PIP and RASP system variables.

					; the NEW command path rejoins here.

					;;;$1219
RAM_SET:	LD	(RAMTOP),HL	; set system variable RAMTOP to HL.
		LD	HL,$3C00	; a strange place to set the pointer to the 
		LD	(CHARS),HL	; character set, CHARS - as no printing yet.
		LD	HL,(RAMTOP)	; fetch RAMTOP to HL again as we've lost it.
		LD	(HL),$3E	; top of user ram holds GOSUB end marker
					; an impossible line number - see RETURN.
					; no significance in the number $3E. It has
					; been traditional since the ZX80.
		DEC	HL		; followed by empty byte (not important).
		LD	SP,HL		; set up the machine stack pointer.
		DEC	HL
		DEC	HL
		LD	(ERR_SP),HL	; ERR_SP is where the error pointer is
					; at moment empty - will take address MAIN_4
					; at the call preceding that address,
					; although interrupts and calls will make use
					; of this location in meantime.
		IM	1		; select interrupt mode 1.
		LD	IY,ERR_NR	; set IY to ERR_NR. IY can reach all standard
					; system variables but shadow ROM system
					; variables will be mostly out of range.

		EI			; enable interrupts now that we have a stack.
		LD	HL,$5CB6	; the address of the channels - initially
					; following system variables.
		LD	(CHANS),HL	; set the CHANS system variable.
		LD	DE,INIT_CHAN	; address: INIT_CHAN in ROM.
		LD	BC,$0015	; there are 21 bytes of initial data in ROM.
		EX	DE,HL		; swap the pointers.
		LDIR			; copy the bytes to RAM.
		EX	DE,HL		; swap pointers. HL points to program area.
		DEC	HL		; decrement address.
		LD	(DATADD),HL	; set DATADD to location before program area.
		INC	HL		; increment again.
		LD	(PROG),HL	; set PROG the location where BASIC starts.
		LD	(VARS),HL	; set VARS to same location with a
		LD	(HL),$80	; variables end-marker.
		INC	HL		; advance address.
		LD	(E_LINE),HL	; set E_LINE, where the edit line
					; will be created.
					; Note. it is not strictly necessary to
					; execute the next fifteen bytes of code
					; as this will be done by the call to SET_MIN.

		LD	(HL),$0D	; initially just has a carriage return
		INC	HL		; followed by
		LD	(HL),$80	; an end-marker.
		INC	HL		; address the next location.
		LD	(WORKSP),HL	; set WORKSP - empty workspace.
		LD	(STKBOT),HL	; set STKBOT - bottom of the empty stack.
		LD	(STKEND),HL	; set STKEND to the end of the empty stack.
		LD	A,$38		; the colour system is set to white paper,
					; black ink, no flash or bright.
		LD	(ATTRP_MASKP),A	; set ATTR_P permanent colour attributes.
		LD	(ATTRT_MASKT),A	; set ATTR_T temporary colour attributes.
		LD	(BORDCR),A	; set BORDCR the border colour/lower screen
					; attributes.
		LD	HL,$0523	; The keyboard repeat and delay values
		LD	(REPDEL),HL	; are loaded to REPDEL and REPPER.

		DEC	(IY-$3A)	; set KSTATE_0 to $FF.
		DEC	(IY-$36)	; set KSTATE_4 to $FF.
					; thereby marking both available.
		LD	HL,INIT_STRM	; set source to ROM Address: INIT_STRM
		LD	DE,STRMS_FD	; set destination to system variable STRMS_FD
		LD	BC,$000E	; copy the 14 bytes of initial 7 streams data
		LDIR			; from ROM to RAM.
		SET	1,(IY+$01)	; update FLAGS - signal printer in use.
		CALL	CLEAR_PRB	; call routine CLEAR_PRB to initialize system
					; variables associated with printer.
		LD	(IY+$31),$02	; set DF_SZ the lower screen display size to
					; two lines
		CALL	CLS		; call routine CLS to set up system
					; variables associated with screen and clear
					; the screen and set attributes.
		XOR	A		; clear accumulator so that we can address
		LD	DE,COPYRIGHT - 1; the message table directly.
		CALL	PO_MSG		; routine PO_MSG puts
					; '(c) 1982 Sinclair Research Ltd'
					; at bottom of display.
		SET	5,(IY+$02)	; update TV_FLAG  - signal lower screen will
					; require clearing.
		JR	MAIN_1		; forward to MAIN_1

;--------------------
; Main execution loop
;--------------------

					;;;$12A2
MAIN_EXEC:	LD	(IY+$31),$02	; set DF_SZ lower screen display file size to 2 lines.
		CALL	AUTO_LIST	; routine AUTO_LIST

					;;;$12A9
MAIN_1:		CALL	SET_MIN		; routine SET_MIN clears work areas.

					;;;$12AC
MAIN_2:		LD	A,$00		; select channel 'K' the keyboard
		CALL	CHAN_OPEN	; routine CHAN_OPEN opens it
		CALL	EDITOR		; routine EDITOR is called.
					; Note the above routine is where the Spectrum
					; waits for user-interaction. Perhaps the
					; most common input at this stage is LOAD "".
		CALL	LINE_SCAN	; routine LINE_SCAN scans the input.
		BIT	7,(IY+$00)	; test ERR_NR - will be $FF if syntax is correct.
		JR	NZ,MAIN_3	; forward, if correct, to MAIN_3.

		BIT	4,(IY+$30)	; test FLAGS2 - K channel in use ?
		JR	Z,MAIN_4	; forward to MAIN_4 if not.

		LD	HL,(E_LINE)	; an editing error so address E_LINE.
		CALL	REMOVE_FP	; routine REMOVE_FP removes the hidden floating-point forms.
		LD	(IY+$00),$FF	; system variable ERR_NR is reset to 'OK'.
		JR	MAIN_2		; back to MAIN_2 to allow user to correct.

					; the branch was here if syntax has passed test.

					;;;$12CF
MAIN_3:		LD	HL,(E_LINE)	; fetch the edit line address from E_LINE.
		LD	(CH_ADD),HL	; system variable CH_ADD is set to first
					; character of edit line.
					; Note. the above two instructions are a little
					; inadequate. 
					; They are repeated with a subtle difference 
					; at the start of the next subroutine and are 
					; therefore not required above.
		CALL	E_LINE_NO	; routine E_LINE_NO will fetch any line
					; number to BC if this is a program line.
		LD	A,B		; test if the number of
		OR	C		; the line is non-zero.
		JP	NZ,MAIN_ADD	; jump forward to MAIN_ADD if so to add the 
					; line to the BASIC program.

					; Has the user just pressed the ENTER key ?

		RST	18H		; GET_CHAR gets character addressed by CH_ADD.
		CP	$0D		; is it a carriage return ?
		JR	Z,MAIN_EXEC	; back to MAIN_EXEC if so for an automatic
					; listing.

					; this must be a direct command.

		BIT	0,(IY+$30)	; test FLAGS2 - clear the main screen ?
		CALL	NZ,CL_ALL	; routine CL_ALL, if so, e.g. after listing.
		CALL	CLS_LOWER	; routine CLS_LOWER anyway.
		LD	A,$19		; compute scroll count to 25 minus
		SUB	(IY+$4F)	; value of S_POSN_HI.
		LD	(SCR_CT),A	; update SCR_CT system variable.
		SET	7,(IY+$01)	; update FLAGS - signal running program.
		LD	(IY+$00),$FF	; set ERR_NR to 'OK'.
		LD	(IY+$0A),$01	; set NSPPC to one for first statement.
		CALL	LINE_RUN	; call routine LINE_RUN to run the line.
					; sysvar ERR_SP therefore addresses MAIN_4

					; Examples of direct commands are RUN, CLS, LOAD "", PRINT USR 40000,
					; LPRINT "A"; etc..
					; If a user written machine-code program disables interrupts then it
					; must enable them to pass the next step. We also jumped to here if the
					; keyboard was not being used.

					;;;$1303
MAIN_4:		HALT			; wait for interrupt.
		RES	5,(IY+$01)	; update FLAGS - signal no new key.
		BIT	1,(IY+$30)	; test FLAGS2 - is printer buffer clear ?
		CALL	NZ,COPY_BUFF	; call routine COPY_BUFF if not.
					; Note. the programmer has neglected
					; to set bit 1 of FLAGS first.
		LD	A,(ERR_NR)	; fetch ERR_NR
		INC	A		; increment to give true code.

					; Now deal with a runtime error as opposed to an editing error.
					; However if the error code is now zero then the OK message will be printed.

					;;;$1313
MAIN_G:		PUSH	AF		; save the error number.
		LD	HL,$0000	; prepare to clear some system variables.
		LD	(IY+$37),H	; clear all the bits of FLAGX.
		LD	(IY+$26),H	; blank X_PTR_HI to suppress error marker.
		LD	(DEFADD),HL	; blank DEFADD to signal that no defined
					; function is currently being evaluated.
		LD	HL,$0001	; explicit - inc hl would do.
		LD	(STRMS_00),HL	; ensure STRMS_00 is keyboard.
		CALL	SET_MIN		; routine SET_MIN clears workspace etc.
		RES	5,(IY+$37)	; update FLAGX - signal in EDIT not INPUT mode.
					; Note. all the bits were reset earlier.

		CALL	CLS_LOWER	; call routine CLS_LOWER.
		SET	5,(IY+$02)	; update TV_FLAG - signal lower screen
					; requires clearing.

		POP	AF		; bring back the error number
		LD	B,A		; and make a copy in B.
		CP	$0A		; is it a print-ready digit ?
		JR	C,MAIN_5	; forward to MAIN_5 if so.

		ADD	A,$07		; add ascii offset to letters.

					;;;$133C
MAIN_5:		CALL	OUT_CODE	; call routine OUT_CODE to print the code.
		LD	A,$20		; followed by a space.
		RST	10H		; PRINT_A
		LD	A,B		; fetch stored report code.
		LD	DE,RPT_MESGS	; address: RPT_MESGS.
		CALL	PO_MSG		; call routine PO_MSG to print.
		XOR	A		; clear to directly
		LD	DE,COMMA_SP - 1	; address comma and space message.  
		CALL	PO_MSG		; routine PO_MSG prints them although it would
					; be more succinct to use RST $10.
		LD	BC,(PPC)	; fetch PPC the current line number.
		CALL	OUT_NUM_1	; routine OUT_NUM_1 will print that
		LD	A,$3A		; then a ':'.
		RST	10H		; PRINT_A
		LD	C,(IY+$0D)	; then SUBPPC for statement
		LD	B,$00		; limited to 127
		CALL	OUT_NUM_1	; routine OUT_NUM_1
		CALL	CLEAR_SP	; routine CLEAR_SP clears editing area.
					; which probably contained 'RUN'.
		LD	A,(ERR_NR)	; fetch ERR_NR again
		INC	A		; test for no error originally $FF.
		JR	Z,MAIN_9	; forward to MAIN_9 if no error.

		CP	$09		; is code Report 9 STOP ?
		JR	Z,MAIN_6	; forward to MAIN_6 if so

		CP	$15		; is code Report L Break ?
		JR	NZ,MAIN_7	; forward to MAIN_7 if not

					; Stop or Break was encountered so consider CONTINUE.

					;;;$1373
MAIN_6:		INC	(IY+$0D)	; increment SUBPPC to next statement.

					;;;$1376
MAIN_7:		LD	BC,$0003	; prepare to copy 3 system variables to
		LD	DE,OSPPC	; address OSPPC - statement for CONTINUE.
					; also updating OLDPPC line number below.
		LD	HL,NSPPC	; set source top to NSPPC next statement.
		BIT	7,(HL)		; did BREAK occur before the jump ?
					; e.g. between GO TO and next statement.
		JR	Z,MAIN_8	; skip forward to MAIN_8, if not, as setup
					; is correct.
		ADD	HL,BC		; set source to SUBPPC number of current
					; statement/line which will be repeated.

					;;;$1384
MAIN_8:		LDDR			; copy PPC to OLDPPC and SUBPPC to OSPCC
					; or NSPPC to OLDPPC and NEWPPC to OSPCC

					;;;$1386
MAIN_9:		LD	(IY+$0A),$FF	; update NSPPC - signal 'no jump'.
		RES	3,(IY+$01)	; update FLAGS  - signal use 'K' mode for
					; the first character in the editor and
		JP	MAIN_2		; jump back to MAIN_2.


;-----------------------
; Canned report messages
;-----------------------
; The Error reports with the last byte inverted. The first entry
; is a dummy entry. The last, which begins with $7F, the Spectrum
; character for copyright symbol, is placed here for convenience
; as is the preceding comma and space.
; The report line must accomodate a 4-digit line number and a 3-digit
; statement number which limits the length of the message text to twenty 
; characters.
; e.g.  "B Integer out of range, 1000:127"

								;;;$1391
RPT_MESGS:	DEFB	$80
		DEFB	"O",'K'+$80				; 0
		DEFB	"NEXT without FO",'R'+$80		; 1
		DEFB	"Variable not foun",'d'+$80		; 2
		DEFB	"Subscript wron",'g'+$80		; 3
		DEFB	"Out of memor",'y'+$80			; 4
		DEFB	"Out of scree",'n'+$80			; 5
		DEFB	"Number too bi",'g'+$80			; 6
		DEFB	"RETURN without GOSU",'B'+$80		; 7
		DEFB	"End of fil",'e'+$80			; 8
		DEFB	"STOP statemen",'t'+$80			; 9
		DEFB	"Invalid argumen",'t'+$80		; A
		DEFB	"Integer out of rang",'e'+$80		; B
		DEFB	"Nonsense in BASI",'C'+$80		; C
		DEFB	"BREAK - CONT repeat",'s'+$80		; D
		DEFB	"Out of DAT",'A'+$80			; E
		DEFB	"Invalid file nam",'e'+$80		; F
		DEFB	"No room for lin",'e'+$80		; G
		DEFB	"STOP in INPU",'T'+$80			; H
		DEFB	"FOR without NEX",'T'+$80		; I
		DEFB	"Invalid I/O devic",'e'+$80		; J
		DEFB	"Invalid colou",'r'+$80			; K
		DEFB	"BREAK into progra",'m'+$80		; L
		DEFB	"RAMTOP no goo",'d'+$80			; M
		DEFB	"Statement los",'t'+$80			; N
		DEFB	"Invalid strea",'m'+$80			; O
		DEFB	"FN without DE",'F'+$80			; P
		DEFB	"Parameter erro",'r'+$80		; Q
		DEFB	"Tape loading erro",'r'+$80		; R

								;;;$1537	
COMMA_SP:	DEFB	",",' '+$80				; used in report line.

								;;;$1539
COPYRIGHT:	DEFB	$7F					; copyright
		DEFB	" 1982 Sinclair Research Lt",'d'+$80

;---------
; REPORT_G
;---------
; Note ERR_SP points here during line entry which allows the
; normal 'Out of Memory' report to be augmented to the more
; precise 'No Room for line' report.

					;;;$1555
					; No Room for line
REPORT_G:	LD	A,$10		; i.e. 'G' -$30 -$07
		LD	BC,$0000	; this seems unnecessary.
		JP	MAIN_G		; jump back to MAIN_G

;------------------------------
; Handle addition of BASIC line
;------------------------------
; Note this is not a subroutine but a branch of the main execution loop.
; System variable ERR_SP still points to editing error handler.
; A new line is added to the Basic program at the appropriate place.
; An existing line with same number is deleted first.
; Entering an existing line number deletes that line.
; Entering a non-existent line allows the subsequent line to be edited next.

					;;;$155D
MAIN_ADD:	LD	(E_PPC),BC	; set E_PPC to extracted line number.
		LD	HL,(CH_ADD)	; fetch CH_ADD - points to location after the
					; initial digits (set in E_LINE_NO).
		EX	DE,HL		; save start of BASIC in DE.
		LD	HL,REPORT_G	; Address: REPORT_G
		PUSH	HL		; is pushed on stack and addressed by ERR_SP.
					; the only error that can occur is
					; 'Out of memory'.
		LD	HL,(WORKSP)	; fetch WORKSP - end of line.
		SCF			; prepare for true subtraction.
		SBC	HL,DE		; find length of BASIC and
		PUSH	HL		; save it on stack.
		LD	H,B		; transfer line number
		LD	L,C		; to HL register.
		CALL	LINE_ADDR	; routine LINE_ADDR will see if
					; a line with the same number exists.
		JR	NZ,MAIN_ADD1	; forward if no existing line to MAIN_ADD1.

		CALL	NEXT_ONE	; routine NEXT_ONE finds the existing line.
		CALL	RECLAIM_2	; routine RECLAIM_2 reclaims it.

					;;;$157D
MAIN_ADD1:	POP	BC		; retrieve the length of the new line.
		LD	A,C		; and test if carriage return only
		DEC	A		; i.e. one byte long.
		OR	B		; result would be zero.
		JR	Z,MAIN_ADD2	; forward to MAIN_ADD2 is so.

		PUSH	BC		; save the length again.
		INC	BC		; adjust for inclusion
		INC	BC		; of line number (two bytes)
		INC	BC		; and line length
		INC	BC		; (two bytes).
		DEC	HL		; HL points to location before the destination
		LD	DE,(PROG)	; fetch the address of PROG
		PUSH	DE		; and save it on the stack
		CALL	MAKE_ROOM	; routine MAKE_ROOM creates BC spaces in
					; program area and updates pointers.
		POP	HL		; restore old program pointer.
		LD	(PROG),HL	; and put back in PROG as it may have been
					; altered by the POINTERS routine.
		POP	BC		; retrieve BASIC length
		PUSH	BC		; and save again.
		INC	DE		; points to end of new area.
		LD	HL,(WORKSP)	; set HL to WORKSP - location after edit line.
		DEC	HL		; decrement to address end marker.
		DEC	HL		; decrement to address carriage return.
		LDDR			; copy the Basic line back to initial command.
		LD	HL,(E_PPC)	; fetch E_PPC - line number.
		EX	DE,HL		; swap it to DE, HL points to last of four locations.
		POP	BC		; retrieve length of line.
		LD	(HL),B		; high byte last.
		DEC	HL
		LD	(HL),C		; then low byte of length.
		DEC	HL
		LD	(HL),E		; then low byte of line number.
		DEC	HL
		LD	(HL),D		; then high byte range $0 - $27 (1-9999).

					;;;$15AB
MAIN_ADD2:	POP	AF		; drop the address of Report G
		JP	MAIN_EXEC	; and back to MAIN_EXEC producing a listing
					; and to reset ERR_SP in EDITOR.

;----------------------------
; Initial channel information
;----------------------------
; This initial channel information is copied from ROM to RAM,
; during initialization. It's new location is after the system
; variables and is addressed by the system variable CHANS
; which means that it can slide up and down in memory.
; The table is never searched and the last character which could be anything
; other than a comma provides a convenient resting place for DATADD.

					;;;$15AF
INIT_CHAN:	DEFW	PRINT_OUT	; PRINT_OUT
		DEFW	KEY_INPUT	; KEY_INPUT
		DEFB	$4B		; 'K'
		DEFW	PRINT_OUT	; PRINT_OUT
		DEFW	REPORT_J	; REPORT_J
		DEFB	$53		; 'S'
		DEFW	ADD_CHAR	; ADD_CHAR
		DEFW	REPORT_J	; REPORT_J
		DEFB	$52		; 'R'
		DEFW	PRINT_OUT	; PRINT_OUT
		DEFW	REPORT_J	; REPORT_J
		DEFB	$50		; 'P'

		DEFB	$80		; End Marker

					;;;$15C4
REPORT_J:	RST	08H		; ERROR_1
		DEFB	$12		; Error Report: Invalid I/O device

;--------------------
; Initial stream data
;--------------------
; This is the initial stream data for the seven streams $FD - $03 that is
; copied from ROM to the STRMS system variables area during initialization.
; There are reserved locations there for another 12 streams.
; Each location contains an offset to the second byte of a channel.
; The first byte of a channel can't be used as that would result in an
; offset of zero for some and zero is used to denote that a stream is closed.

					;;;$15C6
INIT_STRM:	DEFB	$01, $00	; stream $FD offset to channel 'K'
		DEFB	$06, $00	; stream $FE offset to channel 'S'
		DEFB	$0B, $00	; stream $FF offset to channel 'R'
		DEFB	$01, $00	; stream $00 offset to channel 'K'
		DEFB	$01, $00	; stream $01 offset to channel 'K'
		DEFB	$06, $00	; stream $02 offset to channel 'S'
		DEFB	$10, $00	; stream $03 offset to channel 'P'

;-----------------------------
; Control for input subroutine
;-----------------------------

					;;;$15D4
WAIT_KEY:	BIT	5,(IY+$02)	; test TV_FLAG - clear lower screen ?
		JR	NZ,WAIT_KEY1	; forward to WAIT_KEY1 if so.

		SET	3,(IY+$02)	; update TV_FLAG - signal reprint the edit
					; line to the lower screen.

					;;;$15DE
WAIT_KEY1:	CALL	INPUT_AD	; routine INPUT_AD is called.
		RET	C		; return with acceptable keys.

		JR	Z,WAIT_KEY1	; back to WAIT_KEY1 if no key is pressed
					; or it has been handled within INPUT_AD.

					; Note. When inputting from the keyboard all characters are returned with
					; above conditions so this path is never taken.

					;;;$15E4
REPORT_8:	RST	08H		; ERROR_1
		DEFB	$07		; Error Report: End of file

;-------------------------------
; Make HL point to input address
;-------------------------------
; This routine fetches the address of the input stream from the current
; channel area using system variable CURCHL.

					;;;$15E6
INPUT_AD:	EXX			; switch in alternate set.
		PUSH	HL		; save HL register
		LD	HL,(CURCHL)	; fetch address of CURCHL - current channel.
		INC	HL		; step over output routine
		INC	HL		; to point to low byte of input routine.
		JR	CALL_SUB	; forward to CALL_SUB.

;--------------------
; Main Output Routine
;--------------------
; The entry point OUT_CODE is called on five occasions to print
; the ascii equivalent of a value 0-9.
;
; PRINT_A_2 is a continuation of the RST 10 to print any character.
; Both print to the current channel and the printing of control codes
; may alter that channel to divert subsequent RST 10 instructions
; to temporary routines. The normal channel is $09F4.

					;;;$15EF
OUT_CODE:	LD	E,$30		; add 48 decimal to give ascii
		ADD	A,E		; character '0' to '9'.

					;;;$15F2
PRINT_A_2:	EXX			; switch in alternate set
		PUSH	HL		; save HL register
		LD	HL,(CURCHL)	; fetch CURCHL the current channel.

					; INPUT_AD rejoins here also.

					;;;$15F7
CALL_SUB:	LD	E,(HL)		; put the low byte in E.
		INC	HL		; advance address.
		LD	D,(HL)		; put the high byte to D.
		EX	DE,HL		; transfer the stream to HL.
		CALL	CALL_JUMP	; use routine CALL_JUMP.
					; in effect CALL (HL).
		POP	HL		; restore saved HL register.
		EXX			; switch back to the main set and
		RET			; return.

;-------------
; Open channel
;-------------
; This subroutine is used by the ROM to open a channel 'K', 'S', 'R' or 'P'.
; This is either for it's own use or in response to a user's request, for
; example, when '#' is encountered with output - PRINT, LIST etc.
; or with input - INPUT, INKEY$ etc.
; it is entered with a system stream $FD - $FF, or a user stream $00 - $0F
; in the accumulator.

					;;;$1601
CHAN_OPEN:	ADD	A,A		; double the stream ($FF will become $FE etc.)
		ADD	A,$16		; add the offset to stream 0 from $5C00
		LD	L,A		; result to L
		LD	H,$5C		; now form the address in STRMS area.
		LD	E,(HL)		; fetch low byte of CHANS offset
		INC	HL		; address next
		LD	D,(HL)		; fetch high byte of offset
		LD	A,D		; test that the stream is open.
		OR	E		; zero if closed.
		JR	NZ,CHAN_OP_1	; forward to CHAN_OP_1 if open.

					;;;$160E
REPORT_OA:	RST	08H		; ERROR_1
		DEFB	$17		; Error Report: Invalid stream

					; continue here if stream was open. Note that the offset is from CHANS
					; to the second byte of the channel.

					;;;$1610
CHAN_OP_1:	DEC	DE		; reduce offset so it points to the channel.
		LD	HL,(CHANS)	; Fetch CHANS the location of the base of
					; the channel information area
		ADD	HL,DE		; and add the offset to address the channel.
					; and continue to set flags.

;------------------
; Set channel flags
;------------------
; This subroutine is used from ED_EDIT, STR$ and READ_IN to reset the
; current channel when it has been temporarily altered.

					;;;$1615
CHAN_FLAG:	LD	(CURCHL),HL	; set CURCHL system variable to the address in HL
		RES	4,(IY+$30)	; update FLAGS2  - signal K channel not in use.
					; Note. provide a default for channel 'R'.
		INC	HL		; advance past
		INC	HL		; output routine.
		INC	HL		; advance past
		INC	HL		; input routine.
		LD	C,(HL)		; pick up the letter.
		LD	HL,CHN_CD_LU	; address: CHN_CD_LU
		CALL	INDEXER		; routine INDEXER finds offset to a
					; flag-setting routine.
		RET	NC		; but if the letter wasn't found in the
					; table just return now. - channel 'R'.
		LD	D,$00		; prepare to add
		LD	E,(HL)		; offset to E
		ADD	HL,DE		; add offset to location of offset to form
					; address of routine

					;;;$L162C
CALL_JUMP:	JP	(HL)		; jump to the routine

					; Footnote. calling any location that holds JP (HL) is the equivalent to
					; a pseudo Z80 instruction CALL (HL). The ROM uses the instruction above.

;---------------------------
; Channel code look-up table
;---------------------------
; This table is used by the routine above to find one of the three
; flag setting routines below it.
; A zero end-marker is required as channel 'R' is not present.

					;;;$162D
CHN_CD_LU:	DEFB	'K', CHAN_K-$-1 ; offset $06 to CHAN_K
		DEFB	'S', CHAN_S-$-1 ; offset $12 to CHAN_S
		DEFB	'P', CHAN_P-$-1 ; offset $1B to CHAN_P

		DEFB	$00		; end marker.

;---------------
; Channel K flag
;---------------
; routine to set flags for lower screen/keyboard channel.

					;;;$1634
CHAN_K:		SET	0,(IY+$02)	; update TV_FLAG  - signal lower screen in use
		RES	5,(IY+$01)	; update FLAGS	- signal no new key
		SET	4,(IY+$30)	; update FLAGS2	- signal K channel in use
		JR	CHAN_S_1	; forward to CHAN_S_1 for indirect exit

;---------------
; Channel S flag
;---------------
; routine to set flags for upper screen channel.

					;;;$1642
CHAN_S:		RES	0,(IY+$02)	; TV_FLAG  - signal main screen in use

					;;;$1646
CHAN_S_1:	RES	1,(IY+$01)	; update FLAGS  - signal printer not in use
		JP	TEMPS		; jump back to TEMPS and exit via that
					; routine after setting temporary attributes.
;---------------
; Channel P flag
;---------------
; This routine sets a flag so that subsequent print related commands
; print to printer or update the relevant system variables.
; This status remains in force until reset by the routine above.

					;;;$164D
CHAN_P:		SET	1,(IY+$01)	; update FLAGS  - signal printer in use
		RET			; return

;------------------------
; Just one space required
;------------------------
; This routine is called once only to create a single space
; in workspace by ADD_CHAR. It is slightly quicker than using a RST $30.
; There are several instances in the calculator where the sequence
; ld bc, 1; rst $30 could be replaced by a call to this routine but it
; only gives a saving of one byte each time.

					;;;$1652
ONE_SPACE:	LD	BC,$0001	; create space for a single character.

;----------
; Make Room
;----------
; This entry point is used to create BC spaces in various areas such as
; program area, variables area, workspace etc..
; The entire free RAM is available to each BASIC statement.
; On entry, HL addresses where the first location is to be created.
; Afterwards, HL will point to the location before this.

					;;;$1655
MAKE_ROOM:	PUSH	HL		; save the address pointer.
		CALL	TEST_ROOM	; routine TEST_ROOM checks if room
					; exists and generates an error if not.
		POP	HL		; restore the address pointer.
		CALL	POINTERS	; routine POINTERS updates the
					; dynamic memory location pointers.
					; DE now holds the old value of STKEND.
		LD	HL,(STKEND)	; fetch new STKEND the top destination.
		EX	DE,HL		; HL now addresses the top of the area to
					; be moved up - old STKEND.
		LDDR			; the program, variables, etc are moved up.
		RET			; return with new area ready to be populated.
					; HL points to location before new area,
					; and DE to last of new locations.

;------------------------------------------------
; Adjust pointers before making or reclaiming room
;------------------------------------------------
; This routine is called by MAKE_ROOM to adjust upwards and by RECLAIM to
; adjust downwards the pointers within dynamic memory.
; The fourteen pointers to dynamic memory, starting with VARS and ending 
; with STKEND, are updated adding BC if they are higher than the position
; in HL.  
; The system variables are in no particular order except that STKEND, the first
; free location after dynamic memory must be the last encountered.

					;;;$1664
POINTERS:	PUSH	AF		; preserve accumulator.
		PUSH	HL		; put pos pointer on stack.
		LD	HL,VARS		; address VARS the first of the
		LD	A,$0E		; fourteen variables to consider.

					;;;$166B
PTR_NEXT:	LD	E,(HL)		; fetch the low byte of the system variable.
		INC	HL		; advance address.
		LD	D,(HL)		; fetch high byte of the system variable.
		EX	(SP),HL		; swap pointer on stack with the variable pointer.
		AND	A		; prepare to subtract.
		SBC	HL,DE		; subtract variable address
		ADD	HL,DE		; and add back
		EX	(SP),HL		; swap pos with system variable pointer
		JR	NC,PTR_DONE	; forward to PTR_DONE if var before pos

		PUSH	DE		; save system variable address.
		EX	DE,HL		; transfer to HL
		ADD	HL,BC		; add the offset
		EX	DE,HL		; back to DE
		LD	(HL),D		; load high byte
		DEC	HL		; move back
		LD	(HL),E		; load low byte
		INC	HL		; advance to high byte
		POP	DE		; restore old system variable address.

					;;;$167F
PTR_DONE:	INC	HL		; address next system variable.
		DEC	A		; decrease counter.
		JR	NZ,PTR_NEXT	; back to PTR_NEXT if more.
		EX	DE,HL		; transfer old value of STKEND to HL.
					; Note. this has always been updated.
		POP	DE		; pop the address of the position.
		POP	AF		; pop preserved accumulator.
		AND	A		; clear carry flag preparing to subtract.
		SBC	HL,DE		; subtract position from old stkend 
		LD	B,H		; to give number of data bytes
		LD	C,L		; to be moved.
		INC	BC		; increment as we also copy byte at old STKEND.
		ADD	HL,DE		; recompute old stkend.
		EX	DE,HL		; transfer to DE.
		RET			; return.

;--------------------
; Collect line number
;--------------------
; This routine extracts a line number, at an address that has previously
; been found using LINE_ADDR, and it is entered at LINE_NO. If it encounters
; the program 'end-marker' then the previous line is used and if that
; should also be unacceptable then zero is used as it must be a direct
; command. The program end-marker is the variables end-marker $80, or
; if variables exist, then the first character of any variable name.

					;;;$168F
LINE_ZERO:	DEFB	$00, $00	; dummy line number used for direct commands

					;;;$1691
LINE_NO_A:	EX	DE,HL		; fetch the previous line to HL and set
		LD	DE,LINE_ZERO	; DE to LINE_ZERO should HL also fail.

					; -> The Entry Point.

					;;;$1695
LINE_NO:	LD	A,(HL)		; fetch the high byte - max $2F
		AND	$C0		; mask off the invalid bits.
		JR	NZ,LINE_NO_A	; to LINE_NO_A if an end-marker.

		LD	D,(HL)		; reload the high byte.
		INC	HL		; advance address.
		LD	E,(HL)		; pick up the low byte.
		RET			; return from here.

;--------------------
; Handle reserve room
;--------------------
; This is a continuation of the restart BC_SPACES

					;;;$169E
RESERVE:	LD	HL,(STKBOT)	; STKBOT first location of calculator stack
		DEC	HL		; make one less than new location
		CALL	MAKE_ROOM	; routine MAKE_ROOM creates the room.
		INC	HL		; address the first new location
		INC	HL		; advance to second
		POP	BC		; restore old WORKSP
		LD	(WORKSP),BC	; system variable WORKSP was perhaps
					; changed by POINTERS routine.
		POP	BC		; restore count for return value.
		EX	DE,HL		; switch. DE = location after first new space
		INC	HL		; HL now location after new space
		RET			; return.

;----------------------------
; Clear various editing areas
;----------------------------
; This routine sets the editing area, workspace and calculator stack
; to their minimum configurations as at initialization and indeed this
; routine could have been relied on to perform that task.
; This routine uses HL only and returns with that register holding
; WORKSP/STKBOT/STKEND though no use is made of this. The routines also
; reset MEM to it's usual place in the systems variable area should it
; have been relocated to a FOR-NEXT variable. The main entry point
; SET_MIN is called at the start of the MAIN_EXEC loop and prior to
; displaying an error.

					;;;$16B0
SET_MIN:	LD	HL,(E_LINE)	; fetch E_LINE
		LD	(HL),$0D	; insert carriage return
		LD	(K_CUR),HL	; make K_CUR keyboard cursor point there.
		INC	HL		; next location
		LD	(HL),$80	; holds end-marker $80
		INC	HL		; next location becomes
		LD	(WORKSP),HL	; start of WORKSP

					; This entry point is used prior to input and prior to the execution,
					; or parsing, of each statement.

					;;;$16BF
SET_WORK:	LD	HL,(WORKSP)	; fetch WORKSP value
		LD	(STKBOT),HL	; and place in STKBOT

					; This entry point is used to move the stack back to it's normal place
					; after temporary relocation during line entry and also from ERROR_3

					;;;$16C5
SET_STK:	LD	HL,(STKBOT)	; fetch STKBOT value 
		LD	(STKEND),HL	; and place in STKEND.
		PUSH	HL		; perhaps an obsolete entry point.
		LD	HL,MEM_0	; normal location of MEM_0
		LD	(MEM),HL	; is restored to system variable MEM.
		POP	HL		; saved value not required.
		RET			; return.

;-------------------
; Reclaim edit-line?
;-------------------
; This seems to be legacy code from the ZX80/ZX81 as it is 
; not used in this ROM.
; That task, in fact, is performed here by the dual-area routine CLEAR_SP.
; This routine is designed to deal with something that is known to be in the
; edit buffer and not workspace.
; On entry, HL must point to the end of the something to be deleted.

					;;;$16D4
REC_EDIT:	LD	DE,(E_LINE)	; fetch start of edit line from E_LINE.
		JP	RECLAIM_1	; jump forward to RECLAIM_1.

;---------------------------
; The Table INDEXING routine
;---------------------------
; This routine is used to search two-byte hash tables for a character
; held in C, returning the address of the following offset byte.
; if it is known that the character is in the table e.g. for priorities,
; then the table requires no zero end-marker. If this is not known at the
; outset then a zero end-marker is required and carry is set to signal
; success.

					;;;$16DB
INDEXER_1:	INC	HL		; address the next pair of values.

					; -> The Entry Point.

					;;;$16DC
INDEXER:	LD	A,(HL)		; fetch the first byte of pair
		AND	A		; is it the end-marker ?
		RET	Z		; return with carry reset if so.

		CP	C		; is it the required character ?
		INC	HL		; address next location.
		JR	NZ,INDEXER_1	; back to INDEXER_1 if no match.

		SCF			; else set the carry flag.
		RET			; return with carry set

;---------------------------------
; The Channel and Streams Routines
;---------------------------------
; A channel is is an input/output route to a hardware device
; and is identified to the system by a single letter e.g. 'K' for
; the keyboard. A channel can have an input and output route
; associated with it in which case it is bi-directional like
; the keyboard. Others like the upper screen 'S' are output
; only and the input routine usually points to a report message.
; Channels 'K' and 'S' are system channels and it would be inappropriate
; to close the associated streams so a mechanism is provided to
; re-attach them. When the re-attachment is no longer required, then
; closing these streams resets them as at initialization.
; The same also would have applied to channel 'R', the RS232 channel
; as that is used by the system. It's input stream seems to have been
; removed and it is not available to the user. However the channel could
; not be removed entirely as its output routine was used by the system.
; As a result of removing this channel, channel 'P', the printer is
; erroneously treated as a system channel.
; Ironically the tape streamer is not accessed through streams and
; channels.
; Early demonstrations of the Spectrum showed a single microdrive being
; controlled by this ROM. Adverts also said that the network and RS232
; were in this ROM. Channels 'M' and 'N' are user channels and have been
; removed successfully if, as seems possible, they existed.

;----------------------
; Handle CLOSE# command
;----------------------
; This command allows streams to be closed after use.
; Any temporary memory areas used by the stream would be reclaimed and
; finally flags set or reset if necessary.

					;;;$16E5
CLOSE:		CALL	STR_DATA	; routine STR_DATA fetches parameter
					; from calculator stack and gets the
					; existing STRMS data pointer address in HL
					; and stream offset from CHANS in BC.

					; Note. this offset could be zero if the
					; stream is already closed. A check for this
					; should occur now and an error should be
					; generated, for example,
					; Report S 'Stream already closed'.

		CALL	CLOSE_2		; routine CLOSE_2 would perform any actions
					; peculiar to that stream without disturbing
					; data pointer to STRMS entry in HL.
		LD	BC,$0000	; the stream is to be blanked.
		LD	DE,$A3E2	; the number of bytes from stream 4, $5C1E, to $10000
		EX	DE,HL		; transfer offset to HL, STRMS data pointer to DE.
		ADD	HL,DE		; add the offset to the data pointer.  
		JR	C,CLOSE_1	; forward to CLOSE_1 if a non-system stream.
					; i.e. higher than 3. 

					; proceed with a negative result.

		LD	BC,INIT_STRM+14	; prepare the address of the byte after
					; the initial stream data in ROM. ($15D4)
		ADD	HL,BC		; index into the data table with negative value.
		LD	C,(HL)		; low byte to C
		INC	HL		; address next.
		LD	B,(HL)		; high byte to B.

					; and for streams 0 - 3 just enter the initial data back into the STRMS entry
					; streams 0 - 2 can't be closed as they are shared by the operating system.
					; -> for streams 4 - 15 then blank the entry.

					;;;$16FC
CLOSE_1:	EX	DE,HL		; address of stream to HL.
		LD	(HL),C		; place zero (or low byte).
		INC	HL		; next address.
		LD	(HL),B		; place zero (or high byte).
		RET			; return.

;-------------------
; CLOSE_2 Subroutine
;-------------------
; There is not much point in coming here.
; The purpose was once to find the offset to a special closing routine,
; in this ROM and within 256 bytes of the close stream look up table that
; would reclaim any buffers associated with a stream. At least one has been
; removed.

					;;;$1701
CLOSE_2:	PUSH	HL		; * save address of stream data pointer
					; in STRMS on the machine stack.
		LD	HL,(CHANS)	; fetch CHANS address to HL
		ADD	HL,BC		; add the offset to address the second
					; byte of the output routine hopefully.
		INC	HL		; step past
		INC	HL		; the input routine.
		INC	HL		; to address channel's letter
		LD	C,(HL)		; pick it up in C.
					; Note. but if stream is already closed we
					; get the value $10 (the byte preceding 'K').
		EX	DE,HL		; save the pointer to the letter in DE.
		LD	HL,CL_STR_LU	; address: CL_STR_LU in ROM.
		CALL	INDEXER		; routine INDEXER uses the code to get 
					; the 8-bit offset from the current point to
					; the address of the closing routine in ROM.
					; Note. it won't find $10 there!
		LD	C,(HL)		; transfer the offset to C.
		LD	B,$00		; prepare to add.
		ADD	HL,BC		; add offset to point to the address of the
					; routine that closes the stream.
					; (and presumably removes any buffers that
					; are associated with it.)
		JP	(HL)		; jump to that routine.

;---------------------------
; CLOSE stream look-up table
;---------------------------
; This table contains an entry for a letter found in the CHANS area.
; followed by an 8-bit displacement, from that byte's address in the
; table to the routine that performs any ancillary actions associated
; with closing the stream of that channel.
; The table doesn't require a zero end-marker as the letter has been
; picked up from a channel that has an open stream.

						;;;$1716
CL_STR_LU:	DEFB	'K', CLOSE_STR-$-1	; offset 5 to CLOSE_STR
		DEFB	'S', CLOSE_STR-$-1	; offset 3 to CLOSE_STR
		DEFB	'P', CLOSE_STR-$-1	; offset 1 to CLOSE_STR


;-------------------------
; Close Stream Subroutines
;-------------------------
; The close stream routines in fact have no ancillary actions to perform
; which is not surprising with regard to 'K' and 'S'.

					;;;$171C			
CLOSE_STR:	POP	HL		; * now just restore the stream data pointer
		RET			; in STRMS and return.

;------------
; Stream data
;------------
; This routine finds the data entry in the STRMS area for the specified
; stream which is passed on the calculator stack. It returns with HL
; pointing to this system variable and BC holding a displacement from
; the CHANS area to the second byte of the stream's channel. If BC holds
; zero, then that signifies that the stream is closed.

					;;;$171E
STR_DATA:	CALL	FIND_INT1	; routine FIND_INT1 fetches parameter to A
		CP	$10		; is it less than 16d ?
		JR	C,STR_DATA1	; skip forward to STR_DATA1 if so.

					;;;$1725
REPORT_OB:	RST	08H		; ERROR_1
		DEFB	$17		; Error Report: Invalid stream

					;;;$1727
STR_DATA1:	ADD	A,$03		; add the offset for 3 system streams.
					; range 00 - 15d becomes 3 - 18d.
		RLCA			; double as there are two bytes per 
					; stream - now 06 - 36d
		LD	HL,STRMS_FD	; address STRMS_FD - the start of the streams
					; data area in system variables.
		LD	C,A		; transfer the low byte to A.
		LD	B,$00		; prepare to add offset.
		ADD	HL,BC		; add to address the data entry in STRMS_FD.

					; the data entry itself contains an offset from CHANS to the address of the
					; stream

		LD	C,(HL)		; low byte of displacement to C.
		INC	HL		; address next.
		LD	B,(HL)		; high byte of displacement to B.
		DEC	HL		; step back to leave HL pointing to STRMS_FD data entry.
		RET			; return with CHANS displacement in BC
					; and address of stream data entry in HL.

;---------------------
; Handle OPEN# command
;---------------------
; Command syntax example: OPEN #5,"s"
; On entry the channel code entry is on the calculator stack with the next
; value containing the stream identifier. They have to swapped.

					;;;$1736
OPEN:		RST	28H		;; FP_CALC	;s,c.
		DEFB	$01		;;EXCHANGE	;c,s.
		DEFB	$38		;;END_CALC

		CALL	STR_DATA	; routine STR_DATA fetches the stream off
					; the stack and returns with the CHANS
					; displacement in BC and HL addressing 
					; the STRMS_FD data entry.
		LD	A,B		; test for zero which
		OR	C		; indicates the stream is closed.
		JR	Z,OPEN_1	; skip forward to OPEN_1 if so.

					; if it is a system channel then it can re-attached.

		EX	DE,HL		; save STRMS_FD address in DE.
		LD	HL,(CHANS)	; fetch CHANS.
		ADD	HL,BC		; add the offset to address the second  byte of the channel.
		INC	HL		; skip over the
		INC	HL		; input routine.
		INC	HL		; and address the letter.
		LD	A,(HL)		; pick up the letter.
		EX	DE,HL		; save letter pointer and bring back the STRMS_FD pointer.
		CP	$4B		; is it 'K' ?
		JR	Z,OPEN_1	; forward to OPEN_1 if so

		CP	$53		; is it 'S' ?
		JR	Z,OPEN_1	; forward to OPEN_1 if so

		CP	$50		; is it 'P' ?
		JR	NZ,REPORT_OB	; back to REPORT_OB if not.
					; to report 'Invalid stream'.

					; continue if one of the upper-case letters was found.
					; and rejoin here from above if stream was closed.

					;;;$1756
OPEN_1:		CALL	OPEN_2		; routine OPEN_2 opens the stream.

					; it now remains to update the STRMS_FD variable.

		LD	(HL),E		; insert or overwrite the low byte.
		INC	HL		; address high byte in STRMS_FD.
		LD	(HL),D		; insert or overwrite the high byte.
		RET			; return.

;------------------
; OPEN_2 Subroutine
;------------------
; There is some point in coming here as, as well as once creating buffers,
; this routine also sets flags.

					;;;$175D
OPEN_2:		PUSH	HL		; * save the STRMS_FD data entry pointer.
		CALL	STK_FETCH	; routine STK_FETCH now fetches the
					; parameters of the channel string.
					; start in DE, length in BC.
		LD	A,B		; test that it is not
		OR	C		; the null string.
		JR	NZ,OPEN_3	; skip forward to OPEN_3 with 1 character
					; or more!

					;;;$1765
REPORT_F:	RST	08H		; ERROR_1
		DEFB	$0E		; Error Report: Invalid file name

					;;;$1767
OPEN_3:		PUSH	BC		; save the length of the string.
		LD	A,(DE)		; pick up the first character.
					; Note. if the second character is used to
					; distinguish between a binary or text
					; channel then it will be simply a matter
					; of setting bit 7 of FLAGX.
		AND	$DF		; make it upper-case.
		LD	C,A		; place it in C.
		LD	HL,OP_STR_LU	; address: OP_STR_LU is loaded.
		CALL	INDEXER		; routine INDEXER will search for letter.
		JR	NC,REPORT_F	; back to REPORT_F if not found
					; 'Invalid filename'

		LD	C,(HL)		; fetch the displacement to opening routine.
		LD	B,$00		; prepare to add.
		ADD	HL,BC		; now form address of opening routine.
		POP	BC		; restore the length of string.
		JP	(HL)		; now jump forward to the relevant routine.

;--------------------------
; OPEN stream look-up table
;--------------------------
; The open stream look-up table consists of matched pairs.
; The channel letter is followed by an 8-bit displacement to the
; associated stream-opening routine in this ROM.
; The table requires a zero end-marker as the letter has been
; provided by the user and not the operating system.

					;;;$177A
OP_STR_LU:	DEFB	'K', OPEN_K-$-1 ; $06 offset to OPEN_K
		DEFB	'S', OPEN_S-$-1 ; $08 offset to OPEN_S
		DEFB	'P', OPEN_P-$-1 ; $0A offset to OPEN_P

		DEFB	$00		; end-marker.

;-----------------------------
; The Stream Opening Routines.
;-----------------------------
; These routines would have opened any buffers associated with the stream
; before jumping forward to to OPEN_END with the displacement value in E
; and perhaps a modified value in BC. The strange pathing does seem to
; provide for flexibility in this respect.
;
; There is no need to open the printer buffer as it is there already
; even if you are still saving up for a ZX Printer or have moved onto
; something bigger. In any case it would have to be created after
; the system variables but apart from that it is a simple task
; and all but one of the ROM routines can handle a buffer in that position.
; (PR_ALL_6 would require an extra 3 bytes of code).
; However it wouldn't be wise to have two streams attached to the ZX Printer
; as you can now, so one assumes that if PR_CC_hi was non-zero then
; the OPEN_P routine would have refused to attach a stream if another
; stream was attached.

; Something of significance is being passed to these ghost routines in the
; second character. Strings 'RB', 'RT' perhaps or a drive/station number.
; The routine would have to deal with that and exit to OPEN_END with BC
; containing $0001 or more likely there would be an exit within the routine.
; Anyway doesn't matter, these routines are long gone.

;------------------
; OPEN_K Subroutine
;------------------
; Open Keyboard stream.

					;;;$1781
OPEN_K:		LD	E,$01		; 01 is offset to second byte of channel 'K'.
		JR	OPEN_END	; forward to OPEN_END

;------------------
; OPEN_S Subroutine
;------------------
; Open Screen stream.

					;;;$1785
OPEN_S:		LD	E,$06		; 06 is offset to 2nd byte of channel 'S'
		JR	OPEN_END	; to OPEN_END

;------------------
; OPEN_P Subroutine
;------------------
; Open Printer stream.

					;;;$1789
OPEN_P:		LD	E,$10		; 16d is offset to 2nd byte of channel 'P'

					;;;$178B
OPEN_END:	DEC	BC		; the stored length of 'K','S','P' or
					; whatever is now tested. ??
		LD	A,B		; test now if initial or residual length
		OR	C		; is one character.
		JR	NZ,REPORT_F	; to REPORT_F 'Invalid file name' if not.

		LD	D,A		; load D with zero to form the displacement
					; in the DE register.
		POP	HL		; * restore the saved STRMS_FD pointer.
		RET			; return to update STRMS_FD entry thereby 
					; signalling stream is open.

;-----------------------------------------
; Handle CAT, ERASE, FORMAT, MOVE commands
;-----------------------------------------
; These just generate an error report as the ROM is 'incomplete'.
;
; Luckily this provides a mechanism for extending these in a shadow ROM
; but without the powerful mechanisms set up in this ROM.
; An instruction fetch on $0008 may page in a peripheral ROM,
; e.g. the Sinclair Interface 1 ROM, to handle these commands.
; However that wasn't the plan.
; Development of this ROM continued for another three months until the cost
; of replacing it and the manual became unfeasible.
; The ultimate power of channels and streams died at birth.

					;;;$1793
CAT_ETC:	JR	REPORT_OB	; to REPORT_OB

;------------------
; Perform AUTO_LIST
;------------------
; This produces an automatic listing in the upper screen.

					;;;$1795
AUTO_LIST:	LD	(LIST_SP),SP	; save stack pointer in LIST_SP
		LD	(IY+$02),$10	; update TV_FLAG set bit 3
		CALL	CL_ALL		; routine CL_ALL.
		SET	0,(IY+$02)	; update TV_FLAG  - signal lower screen in use
		LD	B,(IY+$31)	; fetch DF_SZ to B.
		CALL	CL_LINE		; routine CL_LINE clears lower display preserving B.
		RES	0,(IY+$02)	; update TV_FLAG  - signal main screen in use
		SET	0,(IY+$30)	; update FLAGS2  - signal unnecessary to clear main screen.
		LD	HL,(E_PPC)	; fetch E_PPC current edit line to HL.
		LD	DE,(S_TOP)	; fetch S_TOP to DE, the current top line
					; (initially zero)
		AND	A		; prepare for true subtraction.
		SBC	HL,DE		; subtract and
		ADD	HL,DE		; add back.
		JR	C,AUTO_L_2	; to AUTO_L_2 if S_TOP higher than E_PPC
					; to set S_TOP to E_PPC
		PUSH	DE		; save the top line number.
		CALL	LINE_ADDR	; routine LINE_ADDR gets address of E_PPC.
		LD	DE,$02C0	; prepare known number of characters in
					; the default upper screen.
		EX	DE,HL		; offset to HL, program address to DE.
		SBC	HL,DE		; subtract high value from low to obtain
					; negated result used in addition.
		EX	(SP),HL		; swap result with top line number on stack.
		CALL	LINE_ADDR	; routine LINE_ADDR  gets address of that
					; top line in HL and next line in DE.
		POP	BC		; restore the result to balance stack.

					;;;$17CE
AUTO_L_1:	PUSH	BC		; save the result.
		CALL	NEXT_ONE	; routine NEXT_ONE gets address in HL of
					; line after auto-line (in DE).
		POP	BC		; restore result.
		ADD	HL,BC		; compute back.
		JR	C,AUTO_L_3	; to AUTO_L_3 if line 'should' appear

		EX	DE,HL		; address of next line to HL.
		LD	D,(HL)		; get line
		INC	HL		; number
		LD	E,(HL)		; in DE.
		DEC	HL		; adjust back to start.
		LD	(S_TOP),DE	; update S_TOP.
		JR	AUTO_L_1	; to AUTO_L_1 until estimate reached.

					; the jump was to here if S_TOP was greater than E_PPC

					;;;$17E1
AUTO_L_2:	LD	(S_TOP),HL	; make S_TOP the same as E_PPC.

					; continue here with valid starting point from above or good estimate
					; from computation

					;;;$17E4
AUTO_L_3:	LD	HL,(S_TOP)	; fetch S_TOP line number to HL.
		CALL	LINE_ADDR	; routine LINE_ADDR gets address in HL.
					; address of next in DE.
		JR	Z,AUTO_L_4	; to AUTO_L_4 if line exists.

		EX	DE,HL		; else use address of next line.

					;;;$17ED
AUTO_L_4:	CALL	LIST_ALL	; routine LIST_ALL		  >>>

					; The return will be to here if no scrolling occurred

		RES	4,(IY+$02)	; update TV_FLAG  - signal no auto listing.
		RET			; return.

;-------------
; Handle LLIST
;-------------
; A short form of LIST #3. The listing goes to stream 3 - default printer.

					;;;$17F5
LLIST:		LD	A,$03		; the usual stream for ZX Printer
		JR	LIST_1		; forward to LIST_1

;------------
; Handle LIST
;------------
; List to any stream.
; Note. While a starting line can be specified it is
; not possible to specify an end line.
; Just listing a line makes it the current edit line.

					;;;$17F9
LIST:		LD	A,$02		; default is stream 2 - the upper screen.

					;;;$17FB
LIST_1:		LD	(IY+$02),$00	; the TV_FLAG is initialized.
		CALL	SYNTAX_Z	; routine SYNTAX_Z - checking syntax ?
		CALL	NZ,CHAN_OPEN	; routine CHAN_OPEN if in run-time.
		RST	18H		; GET_CHAR
		CALL	STR_ALTER	; routine STR_ALTER will alter if '#'.
		JR	C,LIST_4	; forward to LIST_4 not a '#' .

		RST	18H		; GET_CHAR
		CP	$3B		; is it ';' ?
		JR	Z,LIST_2	; skip to LIST_2 if so.

		CP	$2C		; is it ',' ?
		JR	NZ,LIST_3	; forward to LIST_3 if neither separator.

					; we have, say,  LIST #15, and a number must follow the separator.

					;;;$1814
LIST_2:		RST	20H		; NEXT_CHAR
		CALL	EXPT_1NUM	; routine EXPT_1NUM
		JR	LIST_5		; forward to LIST_5

					; the branch was here with just LIST #3 etc.

					;;;$181A
LIST_3:		CALL	USE_ZERO	; routine USE_ZERO
		JR	LIST_5		; forward to LIST_5

					; the branch was here with LIST

					;;;$181F
LIST_4:		CALL	FETCH_NUM	; routine FETCH_NUM checks if a number 
					; follows else uses zero.

					;;;$1822
LIST_5:		CALL	CHECK_END	; routine CHECK_END quits if syntax OK >>>
		CALL	FIND_INT2	; routine FIND_INT2 fetches the number
					; from the calculator stack in run-time.
		LD	A,B		; fetch high byte of line number and
		AND	$3F		; make less than $40 so that NEXT_ONE
					; (from LINE_ADDR) doesn't lose context.
					; Note. this is not satisfactory and the typo
					; LIST 20000 will list an entirely different
					; section than LIST 2000. Such typos are not
					; available for checking if they are direct
					; commands.

		LD	H,A		; transfer the modified
		LD	L,C		; line number to HL.
		LD	(E_PPC),HL	; update E_PPC to new line number.
		CALL	LINE_ADDR	; routine LINE_ADDR gets the address of the line.

					; This routine is called from AUTO_LIST

					;;;$1833
LIST_ALL:	LD	E,$01		; signal current line not yet printed

					;;;$1835
LIST_ALL_2:	CALL	OUT_LINE	; routine OUT_LINE outputs a BASIC line
					; using PRINT_OUT and makes an early return
					; when no more lines to print. >>>

		RST	10H		; PRINT_A prints the carriage return (in A)
		BIT	4,(IY+$02)	; test TV_FLAG  - automatic listing ?
		JR	Z,LIST_ALL_2	; back to LIST_ALL_2 if not
					; (loop exit is via OUT_LINE)

					; continue here if an automatic listing required.

		LD	A,(DF_SZ)	; fetch DF_SZ lower display file size.
		SUB	(IY+$4F)	; subtract S_POSN_HI ithe current line number.
		JR	NZ,LIST_ALL_2	; back to LIST_ALL_2 if upper screen not full.
		XOR	E		; A contains zero, E contains one if the
					; current edit line has not been printed
					; or zero if it has (from OUT_LINE).
		RET	Z		; return if the screen is full and the line
					; has been printed.

					; continue with automatic listings if the screen is full and the current
					; edit line is missing. OUT_LINE will scroll automatically.

		PUSH	HL		; save the pointer address.
		PUSH	DE		; save the E flag.
		LD	HL,S_TOP	; fetch S_TOP the rough estimate.
		CALL	LN_FETCH	; routine LN_FETCH updates S_TOP with the number of the next line.
		POP	DE		; restore the E flag.
		POP	HL		; restore the address of the next line.
		JR	LIST_ALL_2	; back to LIST_ALL_2.

;-------------------------
; Print a whole BASIC line
;-------------------------
; This routine prints a whole basic line and it is called
; from LIST_ALL to output the line to current channel
; and from ED_EDIT to 'sprint' the line to the edit buffer.

					;;;$1855
OUT_LINE:	LD	BC,(E_PPC)	; fetch E_PPC the current line which may be
					; unchecked and not exist.
		CALL	CP_LINES	; routine CP_LINES finds match or line after.
		LD	D,$3E		; prepare cursor '>' in D.
		JR	Z,OUT_LINE1	; to OUT_LINE1 if matched or line after.

		LD	DE,$0000	; put zero in D, to suppress line cursor.
		RL	E		; pick up carry in E if line before current
					; leave E zero if same or after.

					;;;$1865
OUT_LINE1:	LD	(IY+$2D),E	; save flag in BREG which is spare.
		LD	A,(HL)		; get high byte of line number.
		CP	$40		; is it too high ($2F is maximum possible) ?
		POP	BC		; drop the return address and
		RET	NC		; make an early return if so >>>

		PUSH	BC		; save return address
		CALL	OUT_NUM_2	; routine OUT_NUM_2 to print addressed number
					; with leading space.
		INC	HL		; skip low number byte.
		INC	HL		; and the two
		INC	HL		; length bytes.
		RES	0,(IY+$01)	; update FLAGS - signal leading space required.
		LD	A,D		; fetch the cursor.
		AND	A		; test for zero.
		JR	Z,OUT_LINE3	; to OUT_LINE3 if zero.

		RST	10H		; PRINT_A prints '>' the current line cursor.

					; this entry point is called from ED_COPY

					;;;$187D
OUT_LINE2:	SET	0,(IY+$01)	; update FLAGS - suppress leading space.

					;;;$1881
OUT_LINE3:	PUSH	DE		; save flag E for a return value.
		EX	DE,HL		; save HL address in DE.
		RES	2,(IY+$30)	; update FLAGS2 - signal NOT in QUOTES.
		LD	HL,FLAGS	; point to FLAGS.
		RES	2,(HL)		; signal 'K' mode. (starts before keyword)
		BIT	5,(IY+$37)	; test FLAGX - input mode ?
		JR	Z,OUT_LINE4	; forward to OUT_LINE4 if not.

		SET	2,(HL)		; signal 'L' mode. (used for input)

					;;;$1894
OUT_LINE4:	LD	HL,(X_PTR)	; fetch X_PTR - possibly the error pointer address.
		AND	A		; clear the carry flag.
		SBC	HL,DE		; test if an error address has been reached.
		JR	NZ,OUT_LINE5	; forward to OUT_LINE5 if not.

		LD	A,$3F		; load A with '?' the error marker.
		CALL	OUT_FLASH	; routine OUT_FLASH to print flashing marker.

					;;;$18A1
OUT_LINE5:	CALL	OUT_CURS	; routine OUT_CURS will print the cursor if
					; this is the right position.
		EX	DE,HL		; restore address pointer to HL.
		LD	A,(HL)		; fetch the addressed character.
		CALL	NUMBER		; routine NUMBER skips a hidden floating 
					; point number if present.
		INC	HL		; now increment the pointer.
		CP	$0D		; is character end-of-line ?
		JR	Z,OUT_LINE6	; to OUT_LINE6, if so, as line is finished.

		EX	DE,HL		; save the pointer in DE.
		CALL	OUT_CHAR	; routine OUT_CHAR to output character/token.
		JR	OUT_LINE4	; back to OUT_LINE4 until entire line is done.

					;;;$18B4
OUT_LINE6:	POP	DE		; bring back the flag E, zero if current
					; line printed else 1 if still to print.
		RET			; return with A holding $0D

;--------------------------
; Check for a number marker
;--------------------------
; this subroutine is called from two processes. while outputting basic lines
; and while searching statements within a basic line.
; during both, this routine will pass over an invisible number indicator
; and the five bytes floating-point number that follows it.
; Note that this causes floating point numbers to be stripped from
; the basic line when it is fetched to the edit buffer by OUT_LINE.
; the number marker also appears after the arguments of a DEF FN statement
; and may mask old 5-byte string parameters.

					;;;$18B6
NUMBER:		CP	$0E		; character fourteen ?
		RET	NZ		; return if not.

		INC	HL		; skip the character
		INC	HL		; and five bytes
		INC	HL		; following.
		INC	HL
		INC	HL
		INC	HL
		LD	A,(HL)		; fetch the following character
		RET			; for return value.

;---------------------------
; Print a flashing character
;---------------------------
; This subroutine is called from OUT_LINE to print a flashing error
; marker '?' or from the next routine to print a flashing cursor e.g. 'L'.
; However, this only gets called from OUT_LINE when printing the edit line
; or the input buffer to the lower screen so a direct call to 09F4 can
; be used, even though out-line outputs to other streams.
; In fact the alternate set is used for the whole routine.

					;;;$18C1
OUT_FLASH:	EXX			; switch in alternate set
		LD	HL,(ATTRT_MASKT); fetch L = ATTR_T, H = MASK-T
		PUSH	HL		; save masks.
		RES	7,H		; reset flash mask bit so active. 
		SET	7,L		; make attribute FLASH.
		LD	(ATTRT_MASKT),HL; resave ATTR_T and MASK-T
		LD	HL,P_FLAG	; address P_FLAG
		LD	D,(HL)		; fetch to D
		PUSH	DE		; and save.
		LD	(HL),$00	; clear inverse, over, ink/paper 9
		CALL	PRINT_OUT	; routine PRINT_OUT outputs character
					; without the need to vector via RST 10.
		POP	HL		; pop P_FLAG to H.
		LD	(IY+$57),H	; and restore system variable P_FLAG.
		POP	HL		; restore temporary masks
		LD	(ATTRT_MASKT),HL; and restore system variables ATTR_T/MASK_T
		EXX			; switch back to main set
		RET			; return

;-----------------
; Print the cursor
;-----------------
; This routine is called before any character is output while outputting
; a basic line or the input buffer. This includes listing to a printer
; or screen, copying a basic line to the edit buffer and printing the
; input buffer or edit buffer to the lower screen. It is only in the
; latter two cases that it has any relevance and in the last case it
; performs another very important function also.

					;;;$18E1
OUT_CURS:	LD	HL,(K_CUR)	; fetch K_CUR the current cursor address
		AND	A		; prepare for true subtraction.
		SBC	HL,DE		; test against pointer address in DE and
		RET	NZ		; return if not at exact position.

					; the value of MODE, maintained by KEY_INPUT, is tested and if non-zero
					; then this value 'E' or 'G' will take precedence.

		LD	A,(MODE)	; fetch MODE  0='KLC', 1='E', 2='G'.
		RLC	A		; double the value and set flags.
		JR	Z,OUT_C_1	; to OUT_C_1 if still zero ('KLC').

		ADD	A,$43		; add 'C' - will become 'E' if originally 1
					; or 'G' if originally 2.
		JR	OUT_C_2		; forward to OUT_C_2 to print.

					; If mode was zero then, while printing a basic line, bit 2 of flags has been
					; set if 'THEN' or ':' was encountered as a main character and reset otherwise.
					; This is now used to determine if the 'K' cursor is to be printed but this
					; transient state is also now transferred permanently to bit 3 of FLAGS
					; to let the interrupt routine know how to decode the next key.

					;;;$18F3
OUT_C_1:	LD	HL,FLAGS	; Address FLAGS
		RES	3,(HL)		; signal 'K' mode initially.
		LD	A,$4B		; prepare letter 'K'.
		BIT	2,(HL)		; test FLAGS - was the
					; previous main character ':' or 'THEN' ?
		JR	Z,OUT_C_2	; forward to OUT_C_2 if so to print.

		SET	3,(HL)		; signal 'L' mode to interrupt routine.
					; Note. transient bit has been made permanent.
		INC	A		; augment from 'K' to 'L'.
		BIT	3,(IY+$30)	; test FLAGS2 - consider caps lock ?
					; which is maintained by KEY_INPUT.
		JR	Z,OUT_C_2	; forward to OUT_C_2 if not set to print.

		LD	A,$43		; alter 'L' to 'C'.

					;;;$1909
OUT_C_2:	PUSH	DE		; save address pointer but OK as OUT_FLASH
					; uses alternate set without RST 10.
		CALL	OUT_FLASH	; routine OUT_FLASH to print.
		POP	DE		; restore and
		RET			; return.

;-----------------------------
; Get line number of next line
;-----------------------------
; These two subroutines are called while editing.
; This entry point is from ED_DOWN with HL addressing E_PPC
; to fetch the next line number.
; Also from AUTO_LIST with HL addressing S_TOP just to update S_TOP
; with the value of the next line number. It gets fetched but is discarded.
; These routines never get called while the editor is being used for input.

					;;;$190F
LN_FETCH:	LD	E,(HL)		; fetch low byte
		INC	HL		; address next
		LD	D,(HL)		; fetch high byte.
		PUSH	HL		; save system variable hi pointer.
		EX	DE,HL		; line number to HL,
		INC	HL		; increment as a starting point.
		CALL	LINE_ADDR	; routine LINE_ADDR gets address in HL.
		CALL	LINE_NO		; routine LINE_NO gets line number in DE.
		POP	HL		; restore system variable hi pointer.

					; This entry point is from the ED_UP with HL addressing E_PPC_HI

					;;;$191C
LN_STORE:	BIT	5,(IY+$37)	; test FLAGX - input mode ?
		RET	NZ		; return if so.
					; Note. above already checked by ED_UP/ED_DOWN.

		LD	(HL),D		; save high byte of line number.
		DEC	HL		; address lower
		LD	(HL),E		; save low byte of line number.
		RET			; return.

;------------------------------------------
; Outputting numbers at start of BASIC line
;------------------------------------------
; This routine entered at OUT_SP_NO is used to compute then output the first
; three digits of a 4-digit basic line printing a space if necessary.
; The line number, or residual part, is held in HL and the BC register
; holds a subtraction value -1000, -100 or -10.
; Note. for example line number 200 -
; space(out_char), 2(out_code), 0(out_char) final number always out-code.

					;;;$1925
OUT_SP_2:	LD	A,E		; will be space if OUT_CODE not yet called.
					; or $FF if spaces are suppressed.
					; else $30 ('0').
					; (from the first instruction at OUT_CODE)
					; this guy is just too clever.
		AND	A		; test bit 7 of A.
		RET	M		; return if $FF, as leading spaces not
					; required. This is set when printing line
					; number and statement in MAIN_5.

		JR	OUT_CHAR	; forward to exit via OUT_CHAR.

					; -> the single entry point.

					;;;$192A
OUT_SP_NO:	XOR	A		; initialize digit to 0

					;;;$192B
OUT_SP_1:	ADD	HL,BC		; add negative number to HL.
		INC	A		; increment digit
		JR	C,OUT_SP_1	; back to OUT_SP_1 until no carry from
					; the addition.
		SBC	HL,BC		; cancel the last addition
		DEC	A		; and decrement the digit.
		JR	Z,OUT_SP_2	; back to OUT_SP_2 if it is zero.

		JP	OUT_CODE	; jump back to exit via OUT_CODE.	->


;--------------------------------------
; Outputting characters in a BASIC line
;--------------------------------------
; This subroutine ...

					;;;$1937
OUT_CHAR:	CALL	NUMERIC		; routine NUMERIC tests if it is a digit ?
		JR	NC,OUT_CH_3	; to OUT_CH_3 to print digit without
					; changing mode. Will be 'K' mode if digits
					; are at beginning of edit line.
		CP	$21		; less than quote character ?
		JR	C,OUT_CH_3	; to OUT_CH_3 to output controls and space.

		RES	2,(IY+$01)	; initialize FLAGS to 'K' mode and leave
					; unchanged if this character would precede a keyword.
		CP	$CB		; is character 'THEN' token ?
		JR	Z,OUT_CH_3	; to OUT_CH_3 to output if so.

		CP	$3A		; is it ':' ?
		JR	NZ,OUT_CH_1	; to OUT_CH_1 if not statement separator
					; to change mode back to 'L'.
		BIT	5,(IY+$37)	; FLAGX  - Input Mode ??
		JR	NZ,OUT_CH_2	; to OUT_CH_2 if in input as no statements.
					; Note. this check should seemingly be at
					; the start. Commands seem inappropriate in
					; INPUT mode and are rejected by the syntax checker anyway.
					; unless INPUT LINE is being used.
		BIT	2,(IY+$30)	; test FLAGS2 - is the ':' within quotes ?
		JR	Z,OUT_CH_3	; to OUT_CH_3 if ':' is outside quoted text.

		JR	OUT_CH_2	; to OUT_CH_2 as ':' is within quotes

					;;;$195A
OUT_CH_1:	CP	$22		; is it quote character '"'  ?
		JR	NZ,OUT_CH_2	; to OUT_CH_2 with others to set 'L' mode.

		PUSH	AF		; save character.
		LD	A,(FLAGS2)	; fetch FLAGS2.
		XOR	$04		; toggle the quotes flag.
		LD	(FLAGS2),A	; update FLAGS2
		POP	AF		; and restore character.

					;;;$1968
OUT_CH_2:	SET	2,(IY+$01)	; update FLAGS - signal L mode if the cursor
					; is next.

					;;;$196C
OUT_CH_3:	RST	10H		; PRINT_A vectors the character to
					; channel 'S', 'K', 'R' or 'P'.
		RET			; return.

;--------------------------------------------
; Get starting address of line, or line after
;--------------------------------------------
; This routine is used often to get the address, in HL, of a basic line
; number supplied in HL, or failing that the address of the following line
; and the address of the previous line in DE.

					;;;$196E
LINE_ADDR:	PUSH	HL		; save line number in HL register
		LD	HL,(PROG)	; fetch start of program from PROG
		LD	D,H		; transfer address to
		LD	E,L		; the DE register pair.

					;;;$1974
LINE_AD_1:	POP	BC		; restore the line number to BC
		CALL	CP_LINES	; routine CP_LINES compares with that addressed by HL
		RET	NC		; return if line has been passed or matched.
					; if NZ, address of previous is in DE
		PUSH	BC		; save the current line number
		CALL	NEXT_ONE	; routine NEXT_ONE finds address of next line number in DE, previous in HL.
		EX	DE,HL		; switch so next in HL
		JR	LINE_AD_1	; back to LINE_AD_1 for another comparison

;---------------------
; Compare line numbers
;---------------------
; This routine compares a line number supplied in BC with an addressed
; line number pointed to by HL.

					;;;$1980
CP_LINES:	LD	A,(HL)		; Load the high byte of line number and
		CP	B		; compare with that of supplied line number.
		RET	NZ		; return if yet to match (carry will be set).

		INC	HL		; address low byte of
		LD	A,(HL)		; number and pick up in A.
		DEC	HL		; step back to first position.
		CP	C		; now compare.
		RET			; zero set if exact match.
					; carry set if yet to match.
					; no carry indicates a match or
					; next available basic line or
					; program end marker.

;--------------------
; Find each statement
;--------------------
; The single entry point EACH_STMT is used to
; 1) To find the D'th statement in a line.
; 2) To find a token in held E.

					;;;$1988
NOT_USED:	INC	HL
		INC	HL
		INC	HL
					; -> entry point.

					;;;$198B
EACH_STMT:	LD	(CH_ADD),HL	; save HL in CH_ADD
		LD	C,$00		; initialize quotes flag

					;;;$1990
EACH_S_1:	DEC	D		; decrease statement count
		RET	Z		; return if zero

		RST	20H		; NEXT_CHAR
		CP	E		; is it the search token ?
		JR	NZ,EACH_S_3	; forward to EACH_S_3 if not

		AND	A		; clear carry
		RET			; return signalling success.

					;;;$1998
EACH_S_2:	INC	HL		; next address
		LD	A,(HL)		; next character

					;;;$199A
EACH_S_3:	CALL	NUMBER		; routine NUMBER skips if number marker
		LD	(CH_ADD),HL	; save in CH_ADD
		CP	$22		; is it quotes '"' ?
		JR	NZ,EACH_S_4	; to EACH_S_4 if not

		DEC	C		; toggle bit 0 of C

					;;;$19A5
EACH_S_4:	CP	$3A		; is it ':'
		JR	Z,EACH_S_5	; to EACH_S_5

		CP	$CB		; 'THEN'
		JR	NZ,EACH_S_6	; to EACH_S_6

					;;;$19AD
EACH_S_5:	BIT	0,C		; is it in quotes
		JR	Z,EACH_S_1	; to EACH_S_1 if not

					;;;$19B1
EACH_S_6:	CP	$0D		; end of line ?
		JR	NZ,EACH_S_2	; to EACH_S_2

		DEC	D		; decrease the statement counter
					; which should be zero else
					; 'Statement Lost'.
		SCF			; set carry flag - not found
		RET			; return

;------------------------------------------------------------------------
; Storage of variables. For full details - see chapter 24.
; ZX Spectrum BASIC Programming by Steven Vickers 1982.
; It is bits 7-5 of the first character of a variable that allow
; the six types to be distinguished. Bits 4-0 are the reduced letter.
; So any variable name is higher that $3F and can be distinguished
; also from the variables area end-marker $80.
;
; 76543210 meaning                               brief outline of format.
; -------- ------------------------              -----------------------
; 010      string variable.                      2 byte length + contents.
; 110      string array.                         2 byte length + contents.
; 100      array of numbers.                     2 byte length + contents.
; 011      simple numeric variable.              5 bytes.
; 101      variable length named numeric.        5 bytes.
; 111      for-next loop variable.               18 bytes.
; 10000000 the variables area end-marker.
;
; Note. any of the above seven will serve as a program end-marker.
;
; -----------------------------------------------------------------------

;-------------
; Get next one
;-------------
; This versatile routine is used to find the address of the next line
; in the program area or the next variable in the variables area.
; The reason one routine is made to handle two apparently unrelated tasks
; is that it can be called indiscriminately when merging a line or a
; variable.

					;;;$19B8
NEXT_ONE:	PUSH	HL		; save the pointer address.
		LD	A,(HL)		; get first byte.
		CP	$40		; compare with upper limit for line numbers.
		JR	C,NEXT_O_3	; forward to NEXT_O_3 if within basic area.

					; the continuation here is for the next variable unless the supplied
					; line number was erroneously over 16383. see RESTORE command.

		BIT	5,A		; is it a string or an array variable ?
		JR	Z,NEXT_O_4	; forward to NEXT_O_4 to compute length.

		ADD	A,A		; test bit 6 for single-character variables.
		JP	M,NEXT_O_1	; forward to NEXT_O_1 if so

		CCF			; clear the carry for long-named variables.
					; it remains set for for-next loop variables.

					;;;$19C7
NEXT_O_1:	LD	BC,$0005	; set BC to 5 for floating point number
		JR	NC,NEXT_O_2	; forward to NEXT_O_2 if not a for/next
					; variable.
		LD	C,$12		; set BC to eighteen locations.
					; value, limit, step, line and statement.

					; now deal with long-named variables

					;;;$19CE
NEXT_O_2:	RLA			; test if character inverted. carry will also
					; be set for single character variables
		INC	HL		; address next location.
		LD	A,(HL)		; and load character.
		JR	NC,NEXT_O_2	; back to NEXT_O_2 if not inverted bit.
					; forward immediately with single character
					; variable names.
		JR	NEXT_O_5	; forward to NEXT_O_5 to add length of
					; floating point number(s etc.).

					; this branch is for line numbers.

					;;;$19D5
NEXT_O_3:	INC	HL		; increment pointer to low byte of line no.

					; strings and arrays rejoin here

					;;;$19D6
NEXT_O_4:	INC	HL		; increment to address the length low byte.
		LD	C,(HL)		; transfer to C and
		INC	HL		; point to high byte of length.
		LD	B,(HL)		; transfer that to B
		INC	HL		; point to start of basic/variable contents.

					; the three types of numeric variables rejoin here

					;;;$19DB
NEXT_O_5:	ADD	HL,BC		; add the length to give address of next line/variable in HL.
		POP	DE		; restore previous address to DE.

;-------------------
; Difference routine
;-------------------
; This routine terminates the above routine and is also called from the
; start of the next routine to calculate the length to reclaim.

					;;;$19DD
DIFFER:		AND	A		; prepare for true subtraction.
		SBC	HL,DE		; subtract the two pointers.
		LD	B,H		; transfer result
		LD	C,L		; to BC register pair.
		ADD	HL,DE		; add back
		EX	DE,HL		; and switch pointers
		RET			; return values are the length of area in BC,
					; low pointer (previous) in HL,
					; high pointer (next) in DE.

;------------------------
; Handle reclaiming space
;------------------------
;

					;;;$19E5
RECLAIM_1:	CALL	DIFFER		; routine DIFFER immediately above

					;;;$19E8
RECLAIM_2:	PUSH	BC
		LD	A,B
		CPL
		LD	B,A
		LD	A,C
		CPL
		LD	C,A
		INC	BC
		CALL	POINTERS	; routine POINTERS
		EX	DE,HL
		POP	HL
		ADD	HL,DE
		PUSH	DE
		LDIR			; copy bytes
		POP	HL
		RET

;-----------------------------------------
; Read line number of line in editing area
;-----------------------------------------
; This routine reads a line number in the editing area returning the number
; in the BC register or zero if no digits exist before commands.
; It is called from LINE_SCAN to check the syntax of the digits.
; It is called from MAIN_3 to extract the line number in preparation for
; inclusion of the line in the BASIC program area.
;
; Interestingly the calculator stack is moved from it's normal place at the
; end of dynamic memory to an adequate area within the system variables area.
; This ensures that in a low memory situation, that valid line numbers can
; be extracted without raising an error and that memory can be reclaimed
; by deleting lines. If the stack was in it's normal place then a situation
; arises whereby the Spectrum becomes locked with no means of reclaiming space.

					;;;$19FB
E_LINE_NO:	LD	HL,(E_LINE)	; load HL from system variable E_LINE.
		DEC	HL		; decrease so that NEXT_CHAR can be used
					; without skipping the first digit.
		LD	(CH_ADD),HL	; store in the system variable CH_ADD.
		RST	20H		; NEXT_CHAR skips any noise and white-space
					; to point exactly at the first digit.
		LD	HL,MEM_0	; use MEM_0 as a temporary calculator stack
					; an overhead of three locations are needed.
		LD	(STKEND),HL	; set new STKEND.
		CALL	INT_TO_FP	; routine INT_TO_FP will read digits till
					; a non-digit found.
		CALL	FP_TO_BC	; routine FP_TO_BC will retrieve number from stack at membot.
		JR	C,E_L_1		; forward to E_L_1 if overflow i.e. > 65535.
					; 'Nonsense in basic'
		LD	HL,$D8F0	; load HL with value -9999
		ADD	HL,BC		; add to line number in BC

					;;;$1A15
E_L_1:		JP	C,REPORT_C	; to REPORT_C 'Nonsense in Basic' if over.
					; Note. As ERR_SP points to ED_ERROR
					; the report is never produced although
					; the RST $08 will update X_PTR leading to
					; the error marker being displayed when
					; the ED_LOOP is reiterated.
					; in fact, since it is immediately
					; cancelled, any report will do.

					; a line in the range 0 - 9999 has been entered.

		JP	SET_STK		; jump back to SET_STK to set the calculator 
					; stack back to it's normal place and exit 
					; from there.

;----------------------------------
; Report and line number outputting
;----------------------------------
; Entry point OUT_NUM_1 is used by the Error Reporting code to print
; the line number and later the statement number held in BC.
; If the statement was part of a direct command then -2 is used as a
; dummy line number so that zero will be printed in the report.
; This routine is also used to print the exponent of E-format numbers.
;
; Entry point OUT_NUM_2 is used from OUT_LINE to output the line number
; addressed by HL with leading spaces if necessary.

					;;;$1A1B
OUT_NUM_1:	PUSH	DE		; save the
		PUSH	HL		; registers.
		XOR	A		; set A to zero.
		BIT	7,B		; is the line number minus two ?
		JR	NZ,OUT_NUM_4	; forward to OUT_NUM_4 if so to print zero 
					; for a direct command.
		LD	H,B		; transfer the
		LD	L,C		; number to HL.
		LD	E,$FF		; signal 'no leading zeros'.
		JR	OUT_NUM_3	; forward to continue at OUT_NUM_3

					; from OUT_LINE - HL addresses line number.

					;;;$1A28
OUT_NUM_2:	PUSH	DE		; save flags
		LD	D,(HL)		; high byte to D
		INC	HL		; address next
		LD	E,(HL)		; low byte to E
		PUSH	HL		; save pointer
		EX	DE,HL		; transfer number to HL
		LD	E,$20		; signal 'output leading spaces'

					;;;$1A30
OUT_NUM_3:	LD	BC,$FC18	; value -1000
		CALL	OUT_SP_NO	; routine OUT_SP_NO outputs space or number
		LD	BC,$FF9C	; value -100
		CALL	OUT_SP_NO	; routine OUT_SP_NO
		LD	C,$F6		; value -10 ( B is still $FF )
		CALL	OUT_SP_NO	; routine OUT_SP_NO
		LD	A,L		; remainder to A.

					;;;$1A42
OUT_NUM_4:	CALL	OUT_CODE	; routine OUT_CODE for final digit.
					; else report code zero wouldn't get printed.
		POP	HL		; restore the
		POP	DE		; registers and
		RET			; return.


;***************************************************
;** Part 7. BASIC LINE AND COMMAND INTERPRETATION **
;***************************************************

;-----------------
; The offset table
;-----------------
; The BASIC interpreter has found a command code $CE - $FF
; which is then reduced to range $00 - $31 and added to the base address
; of this table to give the address of an offset which, when added to
; the offset therein, gives the location in the following parameter table
; where a list of class codes, separators and addresses relevant to the
; command exists.

					;;;$1A48
OFFST_TBL:	DEFB	P_DEF_FN - $	; B1 offset to Address: P_DEF_FN
		DEFB	P_CAT - $	; CB offset to Address: P_CAT
		DEFB	P_FORMAT - $	; BC offset to Address: P_FORMAT
		DEFB	P_MOVE - $	; BF offset to Address: P_MOVE
		DEFB	P_ERASE - $	; C4 offset to Address: P_ERASE
		DEFB	P_OPEN - $	; AF offset to Address: P_OPEN
		DEFB	P_CLOSE - $	; B4 offset to Address: P_CLOSE
		DEFB	P_MERGE - $	; 93 offset to Address: P_MERGE
		DEFB	P_VERIFY - $	; 91 offset to Address: P_VERIFY
		DEFB	P_BEEP - $	; 92 offset to Address: P_BEEP
		DEFB	P_CIRCLE - $	; 95 offset to Address: P_CIRCLE
		DEFB	P_INK - $	; 98 offset to Address: P_INK
		DEFB	P_PAPER - $	; 98 offset to Address: P_PAPER
		DEFB	P_FLASH - $	; 98 offset to Address: P_FLASH
		DEFB	P_BRIGHT - $	; 98 offset to Address: P_BRIGHT
		DEFB	P_INVERSE - $	; 98 offset to Address: P_INVERSE
		DEFB	P_OVER - $	; 98 offset to Address: P_OVER
		DEFB	P_OUT - $	; 98 offset to Address: P_OUT
		DEFB	P_LPRINT - $	; 7F offset to Address: P_LPRINT
		DEFB	P_LLIST - $	; 81 offset to Address: P_LLIST
		DEFB	P_STOP - $	; 2E offset to Address: P_STOP
		DEFB	P_READ - $	; 6C offset to Address: P_READ
		DEFB	P_DATA - $	; 6E offset to Address: P_DATA
		DEFB	P_RESTORE - $	; 70 offset to Address: P_RESTORE
		DEFB	P_NEW - $	; 48 offset to Address: P_NEW
		DEFB	P_BORDER - $	; 94 offset to Address: P_BORDER
		DEFB	P_CONT - $	; 56 offset to Address: P_CONT
		DEFB	P_DIM - $	; 3F offset to Address: P_DIM
		DEFB	P_REM - $	; 41 offset to Address: P_REM
		DEFB	P_FOR - $	; 2B offset to Address: P_FOR
		DEFB	P_GO_TO - $	; 17 offset to Address: P_GO_TO
		DEFB	P_GO_SUB - $	; 1F offset to Address: P_GO_SUB
		DEFB	P_INPUT - $	; 37 offset to Address: P_INPUT
		DEFB	P_LOAD - $	; 77 offset to Address: P_LOAD
		DEFB	P_LIST - $	; 44 offset to Address: P_LIST
		DEFB	P_LET - $	; 0F offset to Address: P_LET
		DEFB	P_PAUSE - $	; 59 offset to Address: P_PAUSE
		DEFB	P_NEXT - $	; 2B offset to Address: P_NEXT
		DEFB	P_POKE - $	; 43 offset to Address: P_POKE
		DEFB	P_PRINT - $	; 2D offset to Address: P_PRINT
		DEFB	P_PLOT - $	; 51 offset to Address: P_PLOT
		DEFB	P_RUN - $	; 3A offset to Address: P_RUN
		DEFB	P_SAVE - $	; 6D offset to Address: P_SAVE
		DEFB	P_RANDOM - $	; 42 offset to Address: P_RANDOM
		DEFB	P_IF - $	; 0D offset to Address: P_IF
		DEFB	P_CLS - $	; 49 offset to Address: P_CLS
		DEFB	P_DRAW - $	; 5C offset to Address: P_DRAW
		DEFB	P_CLEAR - $	; 44 offset to Address: P_CLEAR
		DEFB	P_RETURN - $	; 15 offset to Address: P_RETURN
		DEFB	P_COPY - $	; 5D offset to Address: P_COPY

;--------------------------------
; The parameter or "Syntax" table
;--------------------------------
; For each command there exists a variable list of parameters.
; If the character is greater than a space it is a required separator.
; If less, then it is a command class in the range 00 - 0B.
; Note that classes 00, 03 and 05 will fetch the addresses from this table.
; Some classes e.g. 07 and 0B have the same address in all invocations
; and the command is re-computed from the low-byte of the parameter address.
; Some e.g. 02 are only called once so a call to the command is made from
; within the class routine rather than holding the address within the table.
; Some class routines check syntax entirely and some leave this task for the
; command itself.
; Others for example CIRCLE (x,y,z) check the first part (x,y) using the
; class routine and the final part (,z) within the command.
; The last few commands appear to have been added in a rush but their syntax
; is rather simple e.g. MOVE "M1","M2"

					;;;$1A7A
P_LET:		DEFB	$01		; CLASS_01 - A variable is required.
		DEFB	$3D		; Separator:  '='
		DEFB	$02		; CLASS_02 - An expression, numeric or string, must follow.

					;;;$1A7D
P_GO_TO:	DEFB	$06		; CLASS_06 - A numeric expression must follow.
		DEFB	$00		; CLASS_00 - No further operands.
		DEFW	GO_TO		; Address: $1E67; Address: GO_TO

					;;;$1A81
P_IF:		DEFB	$06		; CLASS_06 - A numeric expression must follow.
		DEFB	$CB		; Separator:  'THEN'
		DEFB	$05		; CLASS_05 - Variable syntax checked by routine.
		DEFW	IF_CMD		; Address: $1CF0; Address: IF

					;;;$1A86
P_GO_SUB:	DEFB	$06		; CLASS_06 - A numeric expression must follow.
		DEFB	$00		; CLASS_00 - No further operands.
		DEFW	GO_SUB		; Address: $1EED; Address: GO_SUB

					;;;$1A8A
P_STOP:		DEFB	$00		; CLASS_00 - No further operands.
		DEFW	STOP		; Address: $1CEE; Address: STOP

					;;;$1A8D
P_RETURN:	DEFB	$00		; CLASS_00 - No further operands.
		DEFW	RETURN		; Address: $1F23; Address: RETURN

					;;;$1A90
P_FOR:		DEFB	$04		; CLASS_04 - A single character variable must follow.
		DEFB	$3D		; Separator:  '='
		DEFB	$06		; CLASS_06 - A numeric expression must follow.
		DEFB	$CC		; Separator:  'TO'
		DEFB	$06		; CLASS_06 - A numeric expression must follow.
		DEFB	$05		; CLASS_05 - Variable syntax checked by routine.
		DEFW	FOR		; Address: $1D03; Address: FOR

					;;;$1A98
P_NEXT:		DEFB	$04		; CLASS_04 - A single character variable must follow.
		DEFB	$00		; CLASS_00 - No further operands.
		DEFW	NEXT		; Address: $1DAB; Address: NEXT

					;;;$1A9C
P_PRINT:	DEFB	$05		; CLASS_05 - Variable syntax checked entirely by routine.
		DEFW	PRINT		; Address: $1FCD; Address: PRINT

					;;;$1A9F
P_INPUT:	DEFB	$05		; CLASS_05 - Variable syntax checked entirely by routine.
		DEFW	INPUT		; Address: $2089; Address: INPUT

					;;;$1AA2
P_DIM:		DEFB	$05		; CLASS_05 - Variable syntax checked entirely by routine.
		DEFW	DIM		; Address: $2C02; Address: DIM

					;;;$1AA5
P_REM:		DEFB	$05		; CLASS_05 - Variable syntax checked entirely by routine.
		DEFW	REM		; Address: $1BB2; Address: REM

					;;;$1AA8
P_NEW:		DEFB	$00		; CLASS_00 - No further operands.
		DEFW	NEW		; Address: $11B7; Address: NEW

					;;;$1AAB
P_RUN:		DEFB	$03		; CLASS_03 - A numeric expression may follow else default to zero.
		DEFW	RUN		; Address: $1EA1; Address: RUN

					;;;$1AAE
P_LIST:		DEFB	$05		; CLASS_05 - Variable syntax checked entirely by routine.
		DEFW	LIST		; Address: $17F9; Address: LIST

					;;;$1AB1
P_POKE:		DEFB	$08		; CLASS_08 - Two comma-separated numeric expressions required.
		DEFB	$00		; CLASS_00 - No further operands.
		DEFW	POKE		; Address: $1E80; Address: POKE

					;;;$1AB5
P_RANDOM:	DEFB	$03		; CLASS_03 - A numeric expression may follow else default to zero.
		DEFW	RANDOMIZE	; Address: $1E4F; Address: RANDOMIZE

					;;;$1AB8
P_CONT:		DEFB	$00		; CLASS_00 - No further operands.
		DEFW	CONTINUE	; Address: $1E5F; Address: CONTINUE

					;;;$1ABB
P_CLEAR:	DEFB	$03		; CLASS_03 - A numeric expression may follow else default to zero.
		DEFW	CLEAR		; Address: $1EAC; Address: CLEAR

					;;;$1ABE
P_CLS:		DEFB	$00		; CLASS_00 - No further operands.
		DEFW	CLS		; Address: $0D6B; Address: CLS

					;;;$1AC1
P_PLOT:		DEFB	$09		; CLASS_09 - Two comma-separated numeric expressions required with optional colour items.
		DEFB	$00		; CLASS_00 - No further operands.
		DEFW	PLOT		; Address: $22DC; Address: PLOT

					;;;$1AC5
P_PAUSE:	DEFB	$06		; CLASS_06 - A numeric expression must follow.
		DEFB	$00		; CLASS_00 - No further operands.
		DEFW	PAUSE		; Address: $1F3A; Address: PAUSE

					;;;$1AC9
P_READ:		DEFB	$05		; CLASS_05 - Variable syntax checked entirely by routine.
		DEFW	READ		; Address: $1DED; Address: READ

					;;;$1ACC
P_DATA:		DEFB	$05		; CLASS_05 - Variable syntax checked entirely by routine.
		DEFW	DATA		; Address: $1E27; Address: DATA

					;;;$1ACF
P_RESTORE:	DEFB	$03		; CLASS_03 - A numeric expression may follow else default to zero.
		DEFW	RESTORE		; Address: $1E42; Address: RESTORE

					;;;$1AD2
P_DRAW:		DEFB	$09		; CLASS_09 - Two comma-separated numeric expressions required with optional colour items.
		DEFB	$05		; CLASS_05 - Variable syntax checked by routine.
		DEFW	DRAW		; Address: $2382; Address: DRAW

					;;;$1AD6
P_COPY:		DEFB	$00		; CLASS_00 - No further operands.
		DEFW	COPY		; Address: $0EAC; Address: COPY

					;;;$1AD9
P_LPRINT:	DEFB	$05		; CLASS_05 - Variable syntax checked entirely by routine.
		DEFW	LPRINT		; Address: $1FC9; Address: LPRINT

					;;;$1ADC
P_LLIST:	DEFB	$05		; CLASS_05 - Variable syntax checked entirely by routine.
		DEFW	LLIST		; Address: $17F5; Address: LLIST

					;;;$1ADF
P_SAVE:		DEFB	$0B		; CLASS_0B - Offset address converted to tape command.

					;;;$L1AE0
P_LOAD:		DEFB	$0B		; CLASS_0B - Offset address converted to tape command.

					;;;$1AE1
P_VERIFY:	DEFB	$0B		; CLASS_0B - Offset address converted to tape command.

					;;;$1AE2
P_MERGE:	DEFB	$0B		; CLASS_0B - Offset address converted to tape command.

					;;;$1AE3
P_BEEP:		DEFB	$08		; CLASS_08 - Two comma-separated numeric expressions required.
		DEFB	$00		; CLASS_00 - No further operands.
		DEFW	BEEP		; Address: $03F8; Address: BEEP

					;;;$1AE7
P_CIRCLE:	DEFB	$09		; CLASS_09 - Two comma-separated numeric expressions required with optional colour items.
		DEFB	$05		; CLASS_05 - Variable syntax checked by routine.
		DEFW	CIRCLE		; Address: $2320; Address: CIRCLE

					;;;$1AEB
P_INK:		DEFB	$07		; CLASS_07 - Offset address is converted to colour code.
					; 

					;;;$1AEC
P_PAPER:	DEFB	$07		; CLASS_07 - Offset address is converted to colour code.

					;;;$1AED
P_FLASH:	DEFB	$07		; CLASS_07 - Offset address is converted to colour code.

					;;;$1AEE
P_BRIGHT:	DEFB	$07		; CLASS_07 - Offset address is converted to colour code.

					;;;$1AEF
P_INVERSE:	DEFB	$07		; CLASS_07 - Offset address is converted to colour code.

					;;;$1AF0
P_OVER:		DEFB	$07		; CLASS_07 - Offset address is converted to colour code.

					;;;$1AF1
P_OUT:		DEFB	$08		; CLASS_08 - Two comma-separated numeric expressions required.
		DEFB	$00		; CLASS_00 - No further operands.
		DEFW	OUT_CMD		; Address: $1E7A; Address: OUT

					;;;$1AF5
P_BORDER:	DEFB	$06		; CLASS_06 - A numeric expression must follow.
		DEFB	$00		; CLASS_00 - No further operands.
		DEFW	BORDER		; Address: $2294; Address: BORDER

					;;;$1AF9
P_DEF_FN:	DEFB	$05		; CLASS_05 - Variable syntax checked entirely by routine.
		DEFW	DEF_FN		; Address: $1F60; Address: DEF_FN

					;;;$1AFC
P_OPEN:		DEFB	$06		; CLASS_06 - A numeric expression must follow.
		DEFB	$2C		; Separator:  ','		see Footnote *
		DEFB	$0A		; CLASS_0A - A string expression must follow.
		DEFB	$00		; CLASS_00 - No further operands.
		DEFW	OPEN		; Address: $1736; Address: OPEN

					;;;$1B02
P_CLOSE:	DEFB	$06		; CLASS_06 - A numeric expression must follow.
		DEFB	$00		; CLASS_00 - No further operands.
		DEFW	CLOSE		; Address: $16E5; Address: CLOSE

					;;;$1B06
P_FORMAT:	DEFB	$0A		; CLASS_0A - A string expression must follow.
		DEFB	$00		; CLASS_00 - No further operands.
		DEFW	CAT_ETC		; Address: $1793; Address: CAT_ETC

					;;;$1B0A
P_MOVE:		DEFB	$0A		; CLASS_0A - A string expression must follow.
		DEFB	$2C		; Separator:  ','
		DEFB	$0A		; CLASS_0A - A string expression must follow.
		DEFB	$00		; CLASS_00 - No further operands.
		DEFW	CAT_ETC		; Address: $1793; Address: CAT_ETC

					;;;$1B10
P_ERASE:	DEFB	$0A		; CLASS_0A - A string expression must follow.
		DEFB	$00		; CLASS_00 - No further operands.
		DEFW	CAT_ETC		; Address: $1793; Address: CAT_ETC

					;;;$1B14
P_CAT:		DEFB	$00		; CLASS_00 - No further operands.
		DEFW	CAT_ETC		; Address: $1793; Address: CAT_ETC

					; * Note that a comma is required as a separator with the OPEN command
					; but the Interface 1 programmers relaxed this allowing ';' as an
					; alternative for their channels creating a confusing mixture of
					; allowable syntax as it is this ROM which opens or re-opens the
					; normal channels.

;--------------------------------
; Main parser (BASIC interpreter)
;--------------------------------
; This routine is called once from MAIN_2 when the Basic line is to
; be entered or re-entered into the Program area and the syntax
; requires checking.

					;;;$1B17
LINE_SCAN:	RES	7,(IY+$01)	; update FLAGS - signal checking syntax
		CALL	E_LINE_NO	; routine E_LINE_NO		>>
					; fetches the line number if in range.
		XOR	A		; clear the accumulator.
		LD	(SUBPPC),A	; set statement number SUBPPC to zero.
		DEC	A		; set accumulator to $FF.
		LD	(ERR_NR),A	; set ERR_NR to 'OK' - 1.
		JR	STMT_L_1	; forward to continue at STMT_L_1.

;---------------
; Statement loop
;---------------

					;;;$1B28
STMT_LOOP:	RST	20H		; NEXT_CHAR

					; -> the entry point from above or LINE_RUN
					;;;$1B29
STMT_L_1:	CALL	SET_WORK	; routine SET_WORK clears workspace etc.
		INC	(IY+$0D)	; increment statement number SUBPPC
		JP	M,REPORT_C	; to REPORT_C to raise
					; 'Nonsense in basic' if over 127.
		RST	18H		; GET_CHAR
		LD	B,$00		; set B to zero for later indexing.
					; early so any other reason ???
		CP	$0D		; is character carriage return ?
					; i.e. an empty statement.
		JR	Z,LINE_END	; forward to LINE_END if so.

		CP	$3A		; is it statement end marker ':' ?
					; i.e. another type of empty statement.
		JR	Z,STMT_LOOP	; back to STMT_LOOP if so.

		LD	HL,STMT_RET	; address: STMT_RET
		PUSH	HL		; is now pushed as a return address
		LD	C,A		; transfer the current character to C.

					; advance CH_ADD to a position after command and test if it is a command.

		RST	20H		; NEXT_CHAR to advance pointer
		LD	A,C		; restore current character
		SUB	$CE		; subtract 'DEF FN' - first command
		JP	C,REPORT_C	; jump to REPORT_C if less than a command raising
					; 'Nonsense in basic'
		LD	C,A		; put the valid command code back in C.
					; register B is zero.
		LD	HL,OFFST_TBL	; address: OFFST_TBL
		ADD	HL,BC		; index into table with one of 50 commands.
		LD	C,(HL)		; pick up displacement to syntax table entry.
		ADD	HL,BC		; add to address the relevant entry.
		JR	GET_PARAM	; forward to continue at GET_PARAM

;-----------------------
; The main scanning loop
;-----------------------
; not documented properly

					;;;$1B52
SCAN_LOOP:	LD	HL,(T_ADDR)	; fetch temporary address from T_ADDR
					; during subsequent loops.

					; -> the initial entry point with HL addressing start of syntax table entry.

					;;;$1B55
GET_PARAM:	LD	A,(HL)		; pick up the parameter.
		INC	HL		; address next one.
		LD	(T_ADDR),HL	; save pointer in system variable T_ADDR
		LD	BC,SCAN_LOOP	; address: SCAN_LOOP
		PUSH	BC		; is now pushed on stack as looping address.
		LD	C,A		; store parameter in C.
		CP	$20		; is it greater than ' '  ?
		JR	NC,SEPARATOR	; forward to SEPARATOR to check that correct
					; separator appears in statement if so.
		LD	HL,CLASS_TBL	; address: CLASS_TBL.
		LD	B,$00		; prepare to index into the class table.
		ADD	HL,BC		; index to find displacement to routine.
		LD	C,(HL)		; displacement to BC
		ADD	HL,BC		; add to address the CLASS routine.
		PUSH	HL		; push the address on the stack.
		RST	18H		; GET_CHAR - HL points to place in statement.
		DEC	B		; reset the zero flag - the initial state
					; for all class routines.
		RET			; and make an indirect jump to routine
					; and then SCAN_LOOP (also on stack).

					; Note. one of the class routines will eventually drop the return address
					; off the stack breaking out of the above seemingly endless loop.

;-----------------
; Verify separator
;-----------------
; This routine is called once to verify that the mandatory separator
; present in the parameter table is also present in the correct
; location following the command. For example, the 'THEN' token after
; the 'IF' token and expression.

					;;;$1B6F
SEPARATOR:	RST	18H		; GET_CHAR
		CP	C		; does it match the character in C ?
		JP	NZ,REPORT_C	; jump forward to REPORT_C if not
					; 'Nonsense in basic'.

		RST	20H		; NEXT_CHAR advance to next character
		RET			; return.

;-------------------------------
; Come here after interpretation
;-------------------------------

					;;;$1B76
STMT_RET:	CALL	BREAK_KEY	; routine BREAK_KEY is tested after every statement.
		JR	C,STMT_R_1	; step forward to STMT_R_1 if not pressed.

					;;;$1B7B
REPORT_L:	RST	08H		; ERROR_1
		DEFB	$14		; Error Report: BREAK into program

					;;;$1B7D
STMT_R_1:	BIT	7,(IY+$0A)	; test NSPPC - will be set if $FF - no jump to be made.
		JR	NZ,STMT_NEXT	; forward to STMT_NEXT if a program line.

		LD	HL,(NEWPPC)	; fetch line number from NEWPPC
		BIT	7,H		; will be set if minus two - direct command(s)
		JR	Z,LINE_NEW	; forward to LINE_NEW if a jump is to be
					; made to a new program line/statement.

;---------------------
; Run a direct command
;---------------------
; A direct command is to be run or, if continuing from above,
; the next statement of a direct command is to be considered.

					;;;$1B8A
LINE_RUN:	LD	HL,$FFFE	; The dummy value minus two
		LD	(PPC),HL	; is set/reset as line number in PPC.
		LD	HL,(WORKSP)	; point to end of line + 1 - WORKSP.
		DEC	HL		; now point to $80 end-marker.
		LD	DE,(E_LINE)	; address the start of line E_LINE.
		DEC	DE		; now location before - for GET_CHAR.
		LD	A,(NSPPC)	; load statement to A from NSPPC.
		JR	NEXT_LINE	; forward to NEXT_LINE.

;-------------------------------
; Find start address of new line
;-------------------------------
; The branch was to here if a jump is to made to a new line number
; and statement.
; That is the previous statement was a GO TO, GO SUB, RUN, RETURN, NEXT etc..

					;;;$1B9E
LINE_NEW:	CALL	LINE_ADDR	; routine LINE_ADDR gets address of line
					; returning zero flag set if line found.
		LD	A,(NSPPC)	; fetch new statement from NSPPC
		JR	Z,LINE_USE	; forward to LINE_USE if line matched.

					; continue as must be a direct command.

		AND	A		; test statement which should be zero
		JR	NZ,REPORT_N	; forward to REPORT_N if not.
					; 'Statement lost'
		LD	B,A		; save statement in B. ?
		LD	A,(HL)		; fetch high byte of line number.
		AND	$C0		; test if using direct command
					; a program line is less than $3F
		LD	A,B		; retrieve statement.
					; (we can assume it is zero).
		JR	Z,LINE_USE	; forward to LINE_USE if was a program line

					; Alternatively a direct statement has finished correctly.

					;;;$1BB0
REPORT_0:	RST	08H		; ERROR_1
		DEFB	$FF		; Error Report: OK

;-------------------
; Handle REM command
;-------------------
; The REM command routine.
; The return address STMT_RET is dropped and the rest of line ignored.

					;;;$1BB2
REM:		POP	BC		; drop return address STMT_RET and
					; continue ignoring rest of line.

;-------------
; End of line?
;-------------

					;;;$1BB3
LINE_END:	CALL	SYNTAX_Z	; routine SYNTAX_Z  (UNSTACK_Z?)
		RET	Z		; return if checking syntax.

		LD	HL,(NXTLIN)	; fetch NXTLIN to HL.
		LD	A,$C0		; test against the
		AND	(HL)		; system limit $3F.
		RET	NZ		; return if more as must be end of program.
					; (or direct command)

		XOR	A		; set statement to zero.

					; and continue to set up the next following line and then consider this new one.

;----------------------
; General line checking
;----------------------
; The branch was here from LINE_NEW if Basic is branching.
; or a continuation from above if dealing with a new sequential line.
; First make statement zero number one leaving others unaffected.

					;;;$1BBF
LINE_USE:	CP	$01		; will set carry if zero.
		ADC	A,$00		; add in any carry.
		LD	D,(HL)		; high byte of line number to D.
		INC	HL		; advance pointer.
		LD	E,(HL)		; low byte of line number to E.
		LD	(PPC),DE	; set system variable PPC.
		INC	HL		; advance pointer.
		LD	E,(HL)		; low byte of line length to E.
		INC	HL		; advance pointer.
		LD	D,(HL)		; high byte of line length to D.
		EX	DE,HL		; swap pointer to DE before
		ADD	HL,DE		; adding to address the end of line.
		INC	HL		; advance to start of next line.

;------------------------------
; Update NEXT LINE but consider
; previous line or edit line.
;------------------------------
; The pointer will be the next line if continuing from above or to
; edit line end-marker ($80) if from LINE_RUN.

					;;;$1BD1
NEXT_LINE:	LD	(NXTLIN),HL	; store pointer in system variable NXTLIN
		EX	DE,HL		; bring back pointer to previous or edit line
		LD	(CH_ADD),HL	; and update CH_ADD with character address.
		LD	D,A		; store statement in D.
		LD	E,$00		; set E to zero to suppress token searching if EACH_STMT is to be called.
		LD	(IY+$0A),$FF	; set statement NSPPC to $FF signalling no jump to be made.
		DEC	D		; decrement and test statement
		LD	(IY+$0D),D	; set SUBPPC to decremented statement number.
		JP	Z,STMT_LOOP	; to STMT_LOOP if result zero as statement is
					; at start of line and address is known.
		INC	D		; else restore statement.
		CALL	EACH_STMT	; routine EACH_STMT finds the D'th statement address as E does not contain a token.
		JR	Z,STMT_NEXT	; forward to STMT_NEXT if address found.

					;;;$1BEC
REPORT_N:	RST	08H		; ERROR_1
		DEFB	$16		; Error Report: Statement lost

;------------------
; End of statement?
;------------------
; This combination of routines is called from 20 places when
; the end of a statement should have been reached and all preceding
; syntax is in order.

					;;;$1BEE
CHECK_END:	CALL	SYNTAX_Z	; routine SYNTAX_Z
		RET	NZ		; return immediately in runtime

		POP	BC		; drop address of calling routine.
		POP	BC		; drop address STMT_RET.
					; and continue to find next statement.

;---------------------
; Go to next statement
;---------------------
; Acceptable characters at this point are carriage return and ':'.
; If so go to next statement which in the first case will be on next line.

					;;;$1BF4
STMT_NEXT:	RST	18H		; GET_CHAR - ignoring white space etc.
		CP	$0D		; is it carriage return ?
		JR	Z,LINE_END	; back to LINE_END if so.

		CP	$3A		; is it ':' ?
		JP	Z,STMT_LOOP	; jump back to STMT_LOOP to consider
					; further statements
		JP	REPORT_C	; jump to REPORT_C with any other character
					; 'Nonsense in BASIC'.

; Note. the two-byte sequence 'rst 08; defb $0b' could replace the above jp.

;--------------------
; Command class table
;--------------------

					;;;$1C01
CLASS_TBL:	DEFB	CLASS_00 - $	; 0F offset to Address: CLASS_00
		DEFB	CLASS_01 - $	; 1D offset to Address: CLASS_01
		DEFB	CLASS_02 - $	; 4B offset to Address: CLASS_02
		DEFB	CLASS_03 - $	; 09 offset to Address: CLASS_03
		DEFB	CLASS_04 - $	; 67 offset to Address: CLASS_04
		DEFB	CLASS_05 - $	; 0B offset to Address: CLASS_05
		DEFB	CLASS_06 - $	; 7B offset to Address: CLASS_06
		DEFB	CLASS_07 - $	; 8E offset to Address: CLASS_07
		DEFB	CLASS_08 - $	; 71 offset to Address: CLASS_08
		DEFB	CLASS_09 - $	; B4 offset to Address: CLASS_09
		DEFB	CLASS_0A - $	; 81 offset to Address: CLASS_0A
		DEFB	CLASS_0B - $	; CF offset to Address: CLASS_0B


;-------------------------------
; Command classes 00, 03, and 05
;-------------------------------
; CLASS_03 e.g RUN or RUN 200		;  optional operand
; CLASS_00 e.g CONTINUE			;  no operand
; CLASS_05 e.g PRINT			;  variable syntax checked by routine

					;;;$1C0D
CLASS_03:	CALL	FETCH_NUM	; routine FETCH_NUM

					;;;$1C10
CLASS_00:	CP	A		; reset zero flag.

					; if entering here then all class routines are entered with zero reset.

					;;;$1C11
CLASS_05:	POP	BC		; drop address SCAN_LOOP.
		CALL	Z,CHECK_END	; if zero set then call routine CHECK_END >>>
					; as should be no further characters.
		EX	DE,HL		; save HL to DE.
		LD	HL,(T_ADDR)	; fetch T_ADDR
		LD	C,(HL)		; fetch low byte of routine
		INC	HL		; address next.
		LD	B,(HL)		; fetch high byte of routine.
		EX	DE,HL		; restore HL from DE
		PUSH	BC		; push the address
		RET			; and make an indirect jump to the command.

;-------------------------------
; Command classes 01, 02, and 04
;-------------------------------
; CLASS_01  e.g LET A = 2*3		; a variable is reqd

; This class routine is also called from INPUT and READ to find the
; destination variable for an assignment.

					;;;$1C1F
CLASS_01:	CALL	LOOK_VARS	; routine LOOK_VARS returns carry set if not
					; found in runtime.

;-----------------------
; Variable in assignment
;-----------------------

					;;;$1C22
VAR_A_1:	LD	(IY+$37),$00	; set FLAGX to zero
		JR	NC,VAR_A_2	; forward to VAR_A_2 if found or checking syntax.

		SET	1,(IY+$37)	; FLAGX  - Signal a new variable
		JR	NZ,VAR_A_3	; to VAR_A_3 if not assigning to an array
					; e.g. LET a$(3,3) = "X"

					;;;$1C2E
REPORT_2:	RST	08H		; ERROR_1
		DEFB	$01		; Error Report: Variable not found

					;;;$1C30
VAR_A_2:	CALL	Z,STK_VAR		; routine STK_VAR considers a subscript/slice
		BIT	6,(IY+$01)	; test FLAGS  - Numeric or string result ?
		JR	NZ,VAR_A_3	; to VAR_A_3 if numeric

		XOR	A		; default to array/slice - to be retained.
		CALL	SYNTAX_Z	; routine SYNTAX_Z
		CALL	NZ,STK_FETCH	; routine STK_FETCH is called in runtime
					; may overwrite A with 1.
		LD	HL,FLAGX	; address system variable FLAGX
		OR	(HL)		; set bit 0 if simple variable to be reclaimed
		LD	(HL),A		; update FLAGX
		EX	DE,HL		; start of string/subscript to DE

					;;;$1C46
VAR_A_3:	LD	(STRLEN),BC	; update STRLEN
		LD	(DEST),HL	; and DEST of assigned string.
		RET			; return.

; ---------------------------
; CLASS_02 e.g. LET a = 1 + 1		; an expression must follow

					;;;$1C4E
CLASS_02:	POP	BC		; drop return address SCAN_LOOP
		CALL	VAL_FET_1	; routine VAL_FET_1 is called to check
					; expression and assign result in runtime
		CALL	CHECK_END	; routine CHECK_END checks nothing else
					; is present in statement.
		RET			; return

;--------------
; Fetch a value
;--------------

					;;;$1C56
VAL_FET_1:	LD	A,(FLAGS)	; initial FLAGS to A

					;;;$LC59
VAL_FET_2:	PUSH	AF		; save A briefly
		CALL	SCANNING	; routine SCANNING evaluates expression.
		POP	AF		; restore A
		LD	D,(IY+$01)	; post-SCANNING FLAGS to D
		XOR	D		; xor the two sets of flags
		AND	$40		; pick up bit 6 of xored FLAGS should be zero
		JR	NZ,REPORT_C	; forward to REPORT_C if not zero
					; 'Nonsense in Basic' - results don't agree.
		BIT	7,D		; test FLAGS - is syntax being checked ?
		JP	NZ,LET		; jump forward to LET to make the assignment
					; in runtime.
		RET			; but return from here if checking syntax.

;-------------------
; Command CLASS_--04
;-------------------
; CLASS_04 e.g. FOR i			; a single character variable must follow

					;;;$1C6C
CLASS_04:	CALL	LOOK_VARS	; routine LOOK_VARS
		PUSH	AF		; preserve flags.
		LD	A,C		; fetch type - should be 011xxxxx
		OR	$9F		; combine with 10011111.
		INC	A		; test if now $FF by incrementing.
		JR	NZ,REPORT_C	; forward to REPORT_C if result not zero.

		POP	AF		; else restore flags.
		JR	VAR_A_1		; back to VAR_A_1


;---------------------------------
; Expect numeric/string expression
;---------------------------------
; This routine is used to get the two coordinates of STRING$, ATTR and POINT.
; It is also called from PRINT_ITEM to get the two numeric expressions that
; follow the AT ( in PRINT AT, INPUT AT).

					;;;$1C79
NEXT_2NUM:	RST	20H		; NEXT_CHAR advance past 'AT' or '('.

; -------------------------
; CLASS_08 e.g POKE 65535,2		; two numeric expressions separated by comma

					;;;$1C7A
CLASS_08:
EXPT_2NUM:	CALL	EXPT_1NUM	; routine EXPT_1NUM is called for first
					; numeric expression
		CP	$2C		; is character ',' ?
		JR	NZ,REPORT_C	; to REPORT_C if not required separator.
					; 'Nonsense in basic'.

		RST	20H		; NEXT_CHAR

; ---------------------------
;  CLASS_06  e.g. GOTO a*1000		; a numeric expression must follow

					;;;$1C82
CLASS_06:
EXPT_1NUM:	CALL	SCANNING	; routine SCANNING
		BIT	6,(IY+$01)	; test FLAGS  - Numeric or string result ?
		RET	NZ		; return if result is numeric.

					;;;$1C8A
REPORT_C:	RST	08H		; ERROR_1
		DEFB	$0B		; Error Report: Nonsense in BASIC

; --------------------------
; CLASS_0A e.g. ERASE "????"		; a string expression must follow.
;					; these only occur in unimplemented commands
;					; although the routine EXPT_EXP is called
;					; from SAVE_ETC

					;;;$1C8C
CLASS_0A:
EXPT_EXP:	CALL	SCANNING	; routine SCANNING
		BIT	6,(IY+$01)	; test FLAGS  - Numeric or string result ?
		RET	Z		; return if string result.

		JR	REPORT_C	; back to REPORT_C if numeric.

;----------------------
; Set permanent colours
; class 07
;----------------------
; CLASS_07 e.g PAPER 6			; a single class for a collection of
;					; similar commands. Clever.
;
; Note. these commands should ensure that current channel is 'S'

					;;;$1C96
CLASS_07:	BIT	7,(IY+$01)	; test FLAGS - checking syntax only ?
		RES	0,(IY+$02)	; TV_FLAG - signal main screen in use
		CALL	NZ,TEMPS	; routine TEMPS is called in runtime.
		POP	AF		; drop return address SCAN_LOOP
		LD	A,(T_ADDR)	; T_ADDR_lo to accumulator.
					; points to '$07' entry + 1
					; e.g. for INK points to $EC now

					; Note if you move alter the syntax table next line may have to be altered.

		SUB	$13		; convert $EB to $D8 ('INK') etc.
					; ( is SUB $13 in standard ROM )
		CALL	CO_TEMP_4	; routine CO_TEMP_4
		CALL	CHECK_END	; routine CHECK_END check that nothing else in statement. 

					; return here in runtime.

		LD	HL,(ATTRT_MASKT); pick up ATTR_T and MASK_T
		LD	(ATTRP_MASKP),HL; and store in ATTR_P and MASK_P
		LD	HL,P_FLAG	; point to P_FLAG.
		LD	A,(HL)		; pick up in A
		RLCA			; rotate to left
		XOR	(HL)		; combine with HL
		AND	$AA		; 10101010
		XOR	(HL)		; only permanent bits affected
		LD	(HL),A		; reload into P_FLAG.
		RET			; return.

;-----------------
; Command CLASS 09
;-----------------
; e.g. PLOT PAPER 0; 128,88		; two coordinates preceded by optional
;					; embedded colour items.
;
; Note. this command should ensure that current channel is 'S'.

					;;;$1CBE
CLASS_09:	CALL	SYNTAX_Z	; routine SYNTAX_Z
		JR	Z,CL_09_1	; forward to CL_09_1 if checking syntax.

		RES	0,(IY+$02)	; update TV_FLAG - signal main screen in use
		CALL	TEMPS		; routine TEMPS is called.
		LD	HL,MASK_T	; point to MASK_T
		LD	A,(HL)		; fetch mask to accumulator.
		OR	$F8		; or with 11111000 paper/bright/flash 8
		LD	(HL),A		; mask back to MASK_T system variable.
		RES	6,(IY+$57)	; reset P_FLAG  - signal NOT PAPER 9 ?
		RST	18H		; GET_CHAR

					;;;$1CD6
CL_09_1:	CALL	CO_TEMP_2	; routine CO_TEMP_2 deals with embedded colour items.
		JR	EXPT_2NUM	; exit via EXPT_2NUM to check for x,y.

;-----------------
; Command CLASS 0B
;-----------------
; Again a single class for four commands.
; This command just jumps back to SAVE_ETC to handle the four tape commands.
; The routine itself works out which command has called it by examining the
; address in T_ADDR_lo. Note therefore that the syntax table has to be
; located where these and other sequential command addresses are not split
; over a page boundary.

					;;;$1CDB
CLASS_0B:	JP	SAVE_ETC	; jump way back to SAVE_ETC

;---------------
; Fetch a number
;---------------
; This routine is called from CLASS_03 when a command may be followed by
; an optional numeric expression e.g. RUN. If the end of statement has
; been reached then zero is used as the default.
; Also called from LIST_4.

					;;;$1CDE
FETCH_NUM:	CP	$0D		; is character a carriage return ?
		JR	Z,USE_ZERO	; forward to USE_ZERO if so

		CP	$3A		; is it ':' ?
		JR	NZ,EXPT_1NUM	; forward to EXPT_1NUM if not.
					; else continue and use zero.

;-----------------
; Use zero routine
;-----------------
; This routine is called four times to place the value zero on the
; calculator stack as a default value in runtime.

					;;;$1CE6
USE_ZERO:	CALL	SYNTAX_Z	; routine SYNTAX_Z  (UNSTACK_Z?)
		RET	Z		;

		RST	28H		;; FP_CALC
		DEFB	$A0		;;STK_ZERO	;0.
		DEFB	$38		;;END_CALC

		RET			; return.

;--------------------
; Handle STOP command
;--------------------
; Command Syntax: STOP
; One of the shortest and least used commands. As with 'OK' not an error.

					;;;$1CEE
STOP:		RST	08H		; ERROR_1
		DEFB	$08		; Error Report: STOP statement

;------------------
; Handle IF command
;------------------
; e.g. IF score>100 THEN PRINT "You Win"
; The parser has already checked the expression the result of which is on
; the calculator stack. The presence of the 'THEN' separator has also been
; checked and CH-ADD points to the command after THEN.

					;;;$1CF0
IF_CMD:		POP	BC		; drop return address - STMT_RET
		CALL	SYNTAX_Z	; routine SYNTAX_Z
		JR	Z,IF_1		; forward to IF_1 if checking syntax
					; to check syntax of PRINT "You Win"
		RST	28H		;; FP_CALC	score>100 (1=TRUE 0=FALSE)
		DEFB	$02		;;DELETE
		DEFB	$38		;;END_CALC

		EX	DE,HL		; make HL point to deleted value
		CALL	TEST_ZERO	; routine TEST_ZERO
		JP	C,LINE_END	; jump to LINE_END if FALSE (0)

					;;;$1D00
IF_1:	JP	STMT_L_1		; to STMT_L_1, if true (1) to execute command
					; after 'THEN' token.

;-------------------
; Handle FOR command
;-------------------
; e.g. FOR i = 0 TO 1 STEP 0.1
; Using the syntax tables, the parser has already checked for a start and
; limit value and also for the intervening separator.
; the two values v,l are on the calculator stack.
; CLASS_04 has also checked the variable and the name is in STRLEN_lo.
; The routine begins by checking for an optional STEP.

					;;;$1D03
FOR:		CP	$CD		; is there a 'STEP' ?
		JR	NZ,F_USE_1	; to F_USE_1 if not to use 1 as default.

		RST	20H		; NEXT_CHAR
		CALL	EXPT_1NUM	; routine EXPT_1NUM
		CALL	CHECK_END	; routine CHECK_END
		JR	F_REORDER	; to F_REORDER

					;;;$1D10
F_USE_1:	CALL	CHECK_END	; routine CHECK_END
		RST	28H		;; FP_CALC	v,l.
		DEFB	$A1		;;STK_ONE	v,l,1=s.
		DEFB	$38		;;END_CALC

					;;;$1D16
F_REORDER:	RST	28H		;; FP_CALC	v,l,s.
		DEFB	$C0		;;st-mem-0	v,l,s.
		DEFB	$02		;;DELETE	v,l.
		DEFB	$01		;;EXCHANGE	l,v.
		DEFB	$E0		;;get-mem-0	l,v,s.
		DEFB	$01		;;EXCHANGE	l,s,v.
		DEFB	$38		;;END_CALC

		CALL	LET		; routine LET assigns the initial value v to
					; the variable altering type if necessary.
		LD	(MEM),HL	; The system variable MEM is made to point to
					; the variable instead of it's normal location MEMBOT
		DEC	HL		; point to single-character name
		LD	A,(HL)		; fetch name
		SET	7,(HL)		; set bit 7 at location
		LD	BC,$0006	; add six to HL
		ADD	HL,BC		; to address where limit should be.
		RLCA			; test bit 7 of original name.
		JR	C,F_L_S		; forward to F_L_S if already a FOR/NEXT
					; variable
		LD	C,$0D		; otherwise an additional 13 bytes are needed.
					; 5 for each value, two for line number and
					; 1 byte for looping statement.
		CALL	MAKE_ROOM	; routine MAKE_ROOM creates them.
		INC	HL		; make HL address limit.

					;;;$1D34
F_L_S:		PUSH	HL		; save position.

		RST	28H		;; FP_CALC		l,s.
		DEFB	$02		;;DELETE		l.
		DEFB	$02		;;DELETE		.
		DEFB	$38		;;END_CALC
					; DE points to STKEND,		l.

		POP	HL		; restore variable position
		EX	DE,HL		; swap pointers
		LD	C,$0A		; ten bytes to move
		LDIR			; Copy 'deleted' values to variable.
		LD	HL,(PPC)	; Load with current line number from PPC
		EX	DE,HL		; exchange pointers.
		LD	(HL),E		; save the looping line
		INC	HL		; in the next
		LD	(HL),D		; two locations.
		LD	D,(IY+$0D)	; fetch statement from SUBPPC system variable.
		INC	D		; increment statement.
		INC	HL		; and pointer
		LD	(HL),D		; and store the looping statement.					;
		CALL	NEXT_LOOP	; routine NEXT_LOOP considers an initial
		RET	NC		; iteration. Return to STMT_RET if a loop is
					; possible to execute next statement.

					; no loop is possible so execution continues after the matching 'NEXT'

		LD	B,(IY+$38)	; get single-character name from STRLEN_lo
		LD	HL,(PPC)	; get the current line from PPC
		LD	(NEWPPC),HL	; and store it in NEWPPC
		LD	A,(SUBPPC)	; fetch current statement from SUBPPC
		NEG			; Negate as counter decrements from zero
					; initially and we are in the middle of a line.
		LD	D,A		; Store result in D.
		LD	HL,(CH_ADD)	; get current address from CH_ADD
		LD	E,$F3		; search will be for token 'NEXT'

					;;;$1D64
F_LOOP:		PUSH	BC		; save variable name.
		LD	BC,(NXTLIN)	; fetch NXTLIN
		CALL	LOOK_PROG	; routine LOOK_PROG searches for 'NEXT' token.
		LD	(NXTLIN),BC	; update NXTLIN
		POP	BC		; and fetch the letter
		JR	C,REPORT_I	; forward to REPORT_I if the end of program
					; was reached by LOOK_PROG.
					; 'FOR without NEXT'

		RST	20H		; NEXT_CHAR fetches character after NEXT
		OR	$20		; ensure it is upper-case.
		CP	B		; compare with FOR variable name
		JR	Z,F_FOUND	; forward to F_FOUND if it matches.

					; but if no match i.e. nested FOR/NEXT loops then continue search.

		RST	20H		; NEXT_CHAR
		JR	F_LOOP		; back to F_LOOP

					;;;$1D7C
F_FOUND:	RST	20H		; NEXT_CHAR
		LD	A,$01		; subtract the negated counter from 1
		SUB	D		; to give the statement after the NEXT
		LD	(NSPPC),A	; set system variable NSPPC
		RET			; return to STMT_RET to branch to new
					; line and statement. ->

					;;;$1D84
REPORT_I:	RST	08H		; ERROR_1
		DEFB	$11		; Error Report: FOR without NEXT

;----------
; LOOK_PROG
;----------
; Find DATA, DEF FN or NEXT.
; This routine searches the program area for one of the above three keywords.
; On entry, HL points to start of search area.
; The token is in E, and D holds a statement count, decremented from zero.

					;;;$1D86
LOOK_PROG:	LD	A,(HL)		; fetch current character
		CP	$3A		; is it ':' a statement separator ?
		JR	Z,LOOK_P_2	; forward to LOOK_P_2 if so.

					; The starting point was PROG - 1 or the end of a line.

					;;;$1D8B
LOOK_P_1:	INC	HL		; increment pointer to address
		LD	A,(HL)		; the high byte of line number
		AND	$C0		; test for program end marker $80 or a variable
		SCF			; Set Carry Flag
		RET	NZ		; return with carry set if at end
					; of program.		->
		LD	B,(HL)		; high byte of line number to B
		INC	HL
		LD	C,(HL)		; low byte to C.
		LD	(NEWPPC),BC	; set system variable NEWPPC.
		INC	HL
		LD	C,(HL)		; low byte of line length to C.
		INC	HL
		LD	B,(HL)		; high byte to B.
		PUSH	HL		; save address
		ADD	HL,BC		; add length to position.
		LD	B,H		; and save result
		LD	C,L		; in BC.
		POP	HL		; restore address.
		LD	D,$00		; initialize statement counter to zero.

					;;;$1DA3
LOOK_P_2:	PUSH	BC		; save address of next line
		CALL	EACH_STMT	; routine EACH_STMT searches current line.
		POP	BC		; restore address.
		RET	NC		; return if match was found. ->

		JR	LOOK_P_1	; back to LOOK_P_1 for next line.

;--------------------
; Handle NEXT command
;--------------------
; e.g. NEXT i
; The parameter tables have already evaluated the presence of a variable

					;;;$1DAB
NEXT:		BIT	1,(IY+$37)	; test FLAGX - handling a new variable ?
		JP	NZ,REPORT_2	; jump back to REPORT_2 if so
					; 'Variable not found'

					; now test if found variable is a simple variable uninitialized by a FOR.

		LD	HL,(DEST)	; load address of variable from DEST
		BIT	7,(HL)		; is it correct type ?
		JR	Z,REPORT_1	; forward to REPORT_1 if not
					; 'NEXT without FOR'

		INC	HL		; step past variable name
		LD	(MEM),HL	; and set MEM to point to three 5-byte values
					; value, limit, step.

		RST	28H		;; FP_CALC	add step and re-store
		DEFB	$E0		;;get-mem-0	v.
		DEFB	$E2		;;get-mem-2	v,s.
		DEFB	$0F		;;ADDITION	v+s.
		DEFB	$C0		;;st-mem-0	v+s.
		DEFB	$02		;;DELETE	.
		DEFB	$38		;;END_CALC

		CALL	NEXT_LOOP	; routine NEXT_LOOP tests against limit.
		RET	C		; return if no more iterations possible.

		LD	HL,(MEM)	; find start of variable contents from MEM.
		LD	DE,$000F	; add 3*5 to
		ADD	HL,DE		; address the looping line number
		LD	E,(HL)		; low byte to E
		INC	HL
		LD	D,(HL)		; high byte to D
		INC	HL		; address looping statement
		LD	H,(HL)		; and store in H
		EX	DE,HL		; swap registers
		JP	GO_TO_2		; exit via GO_TO_2 to execute another loop.

					;;;$1DD8
REPORT_1:	RST	08H		; ERROR_1
		DEFB	$00		; Error Report: NEXT without FOR


;------------------
; Perform NEXT loop
;------------------
; This routine is called from the FOR command to test for an initial
; iteration and from the NEXT command to test for all subsequent iterations.
; the system variable MEM addresses the variable's contents which, in the
; latter case, have had the step, possibly negative, added to the value.

					;;;$1DDA
NEXT_LOOP:	RST	28H		;; FP_CALC
		DEFB	$E1		;;get-mem-1		l.
		DEFB	$E0		;;get-mem-0		l,v.
		DEFB	$E2		;;get-mem-2		l,v,s.
		DEFB	$36		;;LESS_0		l,v,(1/0) negative step ?
		DEFB	$00		;;JUMP_TRUE		l,v.(1/0)

		DEFB	$02		;;to NEXT_1 if step negative

		DEFB	$01		;;EXCHANGE		v,l.

					;;;$1DE2
NEXT_1:		DEFB	$03		;;SUBTRACT		l-v OR v-l.
		DEFB	$37		;;GREATER_0		(1/0)
		DEFB	$00		;;JUMP_TRUE		.

		DEFB	$04		;;to NEXT_2 if no more iterations.

		DEFB	$38		;;END_CALC		.

		AND	A		; clear carry flag signalling another loop.
		RET			; return

					;;;$1DE9
NEXT_2:		DEFB	$38		;;END_CALC		.

		SCF			; set carry flag signalling looping exhausted.
		RET			; return


;--------------------
; Handle READ command
;--------------------
; e.g. READ a, b$, c$(1000 TO 3000)
; A list of comma-separated variables is assigned from a list of
; comma-separated expressions.
; As it moves along the first list, the character address CH_ADD is stored
; in X_PTR while CH_ADD is used to read the second list.

					;;;$1DEC
READ_3:		RST	20H		; NEXT_CHAR

					; -> Entry point.
					;;;$1DED
READ:		CALL	CLASS_01	; routine CLASS_01 checks variable.
		CALL	SYNTAX_Z	; routine SYNTAX_Z
		JR	Z,READ_2	; forward to READ_2 if checking syntax

		RST	18H		; GET_CHAR
		LD	(X_PTR),HL	; save character position in X_PTR.
		LD	HL,(DATADD)	; load HL with Data Address DATADD, which is
					; the start of the program or the address
					; after the last expression that was read or
					; the address of the line number of the 
					; last RESTORE command.
		LD	A,(HL)		; fetch character
		CP	$2C		; is it a comma ?
		JR	Z,READ_1	; forward to READ_1 if so.

					; else all data in this statement has been read so look for next DATA token

		LD	E,$E4		; token 'DATA'
		CALL	LOOK_PROG	; routine LOOK_PROG
		JR	NC,READ_1	; forward to READ_1 if DATA found

					; else report the error.

					;;;$1E08
REPORT_E:	RST	08H		; ERROR_1
		DEFB	$0D		; Error Report: Out of DATA

					;;;$1E0A
READ_1:		CALL	TEMP_PTR1	; routine TEMP_PTR1 advances updating CH_ADD with new DATADD position.
		CALL	VAL_FET_1	; routine VAL_FET_1 assigns value to variable
					; checking type match and adjusting CH_ADD.
		RST	18H		; GET_CHAR fetches adjusted character position
		LD	(DATADD),HL	; store back in DATADD
		LD	HL,(X_PTR)	; fetch X_PTR  the original READ CH_ADD
		LD	(IY+$26),$00	; now nullify X_PTR_HI
		CALL	TEMP_PTR2	; routine TEMP_PTR2 restores READ CH_ADD

					;;;$1E1E
READ_2:		RST	18H		; GET_CHAR
		CP	$2C		; is it ',' indicating more variables to read ?
		JR	Z,READ_3	; back to READ_3 if so

		CALL	CHECK_END	; routine CHECK_END
		RET			; return from here in runtime to STMT_RET.

;--------------------
; Handle DATA command
;--------------------
; In runtime this 'command' is passed by but the syntax is checked when such
; a statement is found while parsing a line.
; e.g. DATA 1, 2, "text", score-1, a$(location, room, object), FN r(49),
;		wages - tax, TRUE, The meaning of life

					;;;$1E27
DATA:		CALL	SYNTAX_Z	; routine SYNTAX_Z to check status
		JR	NZ,DATA_2	; forward to DATA_2 if in runtime

					;;;$1E2C
DATA_1:		CALL	SCANNING	; routine SCANNING to check syntax of expression
		CP	$2C		; is it a comma ?
		CALL	NZ,CHECK_END	; routine CHECK_END checks that statement
					; is complete. Will make an early exit if
					; so. >>>
		RST	20H		; NEXT_CHAR
		JR	DATA_1		; back to DATA_1

					;;;$1E37
DATA_2:		LD	A,$E4		; set token to 'DATA' and continue into
					; the the PASS_BY routine.


;-----------------------------------
; Check statement for DATA or DEF FN
;-----------------------------------
; This routine is used to backtrack to a command token and then
; forward to the next statement in runtime.

					;;;$1E39
PASS_BY:	LD	B,A		; Give BC enough space to find token.
		CPDR			; Compare decrement and repeat. (Only use).
					; Work backwards till keyword is found which
					; is start of statement before any quotes.
					; HL points to location before keyword.
		LD	DE,$0200	; count 1+1 statements, dummy value in E to
					; inhibit searching for a token.
		JP	EACH_STMT	; to EACH_STMT to find next statement

;------------------------------------------------------------------------
; A General Note on Invalid Line Numbers.
; =======================================
; One of the revolutionary concepts of Sinclair Basic was that it supported
; virtual line numbers. That is the destination of a GO TO, RESTORE etc. need
; not exist. It could be a point before or after an actual line number.
; Zero suffices for a before but the after should logically be infinity.
; Since the maximum actual line limit is 9999 then the system limit, 16383
; when variables kick in, would serve fine as a virtual end point.
; However, ironically, only the LOAD command gets it right. It will not
; autostart a program that has been saved with a line higher than 16383.
; All the other commands deal with the limit unsatisfactorily.
; LIST, RUN, GO TO, GO SUB and RESTORE have problems and the latter may
; crash the machine when supplied with an inappropriate virtual line number.
; This is puzzling as very careful consideration must have been given to
; this point when the new variable types were allocated their masks and also
; when the routine NEXT-ONE was successfully re-written to reflect this.
; An enigma.
;--------------------------------------------------------------------------

;-----------------------
; Handle RESTORE command
;-----------------------
; The restore command sets the system variable for the data address to
; point to the location before the supplied line number or first line
; thereafter.
; This alters the position where subsequent READ commands look for data.
; Note. If supplied with inappropriate high numbers the system may crash
; in the LINE-ADDR routine as it will pass the program/variables end-marker
; and then lose control of what it is looking for - variable or line number.
; - observation, Steven Vickers, 1984, Pitman.

					;;;$1E42
RESTORE:	CALL	FIND_INT2	; routine FIND_INT2 puts integer in BC.
					; Note. B should be checked against limit $3F
					; and an error generated if higher.

					; this entry point is used from RUN command with BC holding zero

					;;;$1E45
REST_RUN:	LD	H,B		; transfer the line
		LD	L,C		; number to the HL register.
		CALL	LINE_ADDR	; routine LINE_ADDR to fetch the address.
		DEC	HL		; point to the location before the line.
		LD	(DATADD),HL	; update system variable DATADD.
		RET			; return to STMT_RET (or RUN)

;-------------------------
; Handle RANDOMIZE command
;-------------------------
; This command sets the SEED for the RND function to a fixed value.
; With the parameter zero, a random start point is used depending on
; how long the computer has been switched on.

					;;;$1E4F
RANDOMIZE:	CALL	FIND_INT2	; routine FIND_INT2 puts parameter in BC.
		LD	A,B		; test this
		OR	C		; for zero.
		JR	NZ,RAND_1	; forward to RAND_1 if not zero.

		LD	BC,(FRAMES1)	; use the lower two bytes at FRAMES1.

					;;;$1E5A
RAND_1:		LD	(SEED),BC	; place in SEED system variable.
		RET			; return to STMT_RET

;------------------------
; Handle CONTINUE command
;------------------------
; The CONTINUE command transfers the OLD (but incremented) values of
; line number and statement to the equivalent "NEW VALUE" system variables
; by using the last part of GO TO and exits indirectly to STMT_RET.

					;;;$1E5F
CONTINUE:	LD	HL,(OLDPPC)	; fetch OLDPPC line number.
		LD	D,(IY+$36)	; fetch OSPPC statement.
		JR	GO_TO_2		; forward to GO_TO_2

;---------------------
; Handle GO TO command
;---------------------
; The GO TO command routine is also called by GO SUB and RUN routines
; to evaluate the parameters of both commands.
; It updates the system variables used to fetch the next line/statement.
; It is at STMT_RET that the actual change in control takes place.
; Unlike some BASICs the line number need not exist.
; Note. the high byte of the line number is incorrectly compared with $F0
; instead of $3F. This leads to commands with operands greater than 32767
; being considered as having been run from the editing area and the
; error report 'Statement Lost' is given instead of 'OK'.
; - Steven Vickers, 1984.

					;;;$1E67
GO_TO:		CALL	FIND_INT2	; routine FIND_INT2 puts operand in BC
		LD	H,B		; transfer line
		LD	L,C		; number to HL.
		LD	D,$00		; set statement to 0 - first.
		LD	A,H		; compare high byte only
		CP	$F0		; to $F0 i.e. 61439 in full.
		JR	NC,REPORT_BB	; forward to REPORT_BB if above.

					; This call entry point is used to update the system variables e.g. by RETURN.

					;;;$1E73
GO_TO_2:	LD	(NEWPPC),HL	; save line number in NEWPPC
		LD	(IY+$0A),D	; and statement in NSPPC
		RET			; to STMT_RET (or GO_SUB command)

;-------------------
; Handle OUT command
;-------------------
; Syntax has been checked and the two comma-separated values are on the
; calculator stack.

					;;;$1E7A
OUT_CMD:	CALL	TWO_PARAM	; routine TWO_PARAM fetches values to BC and A.
		OUT	(C),A		; perform the operation.
		RET			; return to STMT_RET.

;--------------------
; Handle POKE command
;--------------------
; This routine alters a single byte in the 64K address space.
; Happily no check is made as to whether ROM or RAM is addressed.
; Sinclair Basic requires no poking of system variables.

					;;;$1E80
POKE:		CALL	TWO_PARAM	; routine TWO_PARAM fetches values to BC and A.
		LD	(BC),A		; load memory location with A.
		RET			; return to STMT_RET.

;--------------------------------------------
; Fetch two  parameters from calculator stack
;--------------------------------------------
; This routine fetches a byte and word from the calculator stack
; producing an error if either is out of range.

					;;;$1E85
TWO_PARAM:	CALL	FP_TO_A		; routine FP_TO_A
		JR	C,REPORT_BB	; forward to REPORT_BB if overflow occurred

		JR	Z,TWO_P_1	; forward to TWO_P_1 if positive

		NEG			; negative numbers are made positive

					;;;$1E8E
TWO_P_1:	PUSH	AF		; save the value
		CALL	FIND_INT2	; routine FIND_INT2 gets integer to BC
		POP	AF		; restore the value
		RET			; return

;--------------
; Find integers
;--------------
; The first of these routines fetches a 8-bit integer (range 0-255) from the
; calculator stack to the accumulator and is used for colours, streams,
; durations and coordinates.
; The second routine fetches 16-bit integers to the BC register pair 
; and is used to fetch command and function arguments involving line numbers
; or memory addresses and also array subscripts and tab arguments.
; ->

					;;;$1E94
FIND_INT1:	CALL	FP_TO_A		; routine FP_TO_A
		JR	FIND_I_1	; forward to FIND_I_1 for common exit routine.

					; ->

					;;;$1E99
FIND_INT2:	CALL	FP_TO_BC	; routine FP_TO_BC

					;;;$1E9C
FIND_I_1:	JR	C,REPORT_BB	; to REPORT_BB with overflow.

		RET	Z		; return if positive.


					;;;$1E9F
REPORT_BB:	RST	08H		; ERROR_1
		DEFB	$0A		; Error Report: Integer out of range

;-------------------
; Handle RUN command
;-------------------
; This command runs a program starting at an optional line.
; It performs a 'RESTORE 0' then CLEAR

					;;;$1EA1
RUN:		CALL	GO_TO		; routine GO_TO puts line number in system variables.
		LD	BC,$0000	; prepare to set DATADD to first line.
		CALL	REST_RUN	; routine REST_RUN does the 'restore'.
					; Note BC still holds zero.
		JR	CLEAR_RUN	; forward to CLEAR_RUN to clear variables
					; without disturbing RAMTOP and
					; exit indirectly to STMT_RET

;---------------------
; Handle CLEAR command
;---------------------
; This command reclaims the space used by the variables.
; It also clears the screen and the GO SUB stack.
; With an integer expression, it sets the uppermost memory
; address within the BASIC system.
; "Contrary to the manual, CLEAR doesn't execute a RESTORE" -
; Steven Vickers, Pitman Pocket Guide to the Spectrum, 1984.

					;;;$1EAC
CLEAR:		CALL	FIND_INT2	; routine FIND_INT2 fetches to BC.

					;;;$1EAF
CLEAR_RUN:	LD	A,B		; test for
		OR	C		; zero.
		JR	NZ,CLEAR_1	; skip to CLEAR_1 if not zero.

		LD	BC,(RAMTOP)	; use the existing value of RAMTOP if zero.

					;;;$1EB7
CLEAR_1:	PUSH	BC		; save ramtop value.
		LD	DE,(VARS)	; fetch VARS
		LD	HL,(E_LINE)	; fetch E_LINE
		DEC	HL		; adjust to point at variables end-marker.
		CALL	RECLAIM_1	; routine RECLAIM_1 reclaims the space used by the variables.
		CALL	CLS		; routine CLS to clear screen.
		LD	HL,(STKEND)	; fetch STKEND the start of free memory.
		LD	DE,$0032	; allow for another 50 bytes.
		ADD	HL,DE		; add the overhead to HL.
		POP	DE		; restore the ramtop value.
		SBC	HL,DE		; if HL is greater than the value then jump
		JR	NC,REPORT_M	; forward to REPORT_M
					; 'RAMTOP no good'
		LD	HL,(P_RAMT)	; now P_RAMT ($7FFF on 16K RAM machine)
		AND	A		; exact this time.
		SBC	HL,DE		; new ramtop must be lower or the same.
		JR	NC,CLEAR_2	; skip to CLEAR_2 if in actual RAM.

					;;;$1EDA
REPORT_M:	RST	08H		; ERROR_1
		DEFB	$15		; Error Report: RAMTOP no good

					;;;$1EDC
CLEAR_2:	EX	DE,HL		; transfer ramtop value to HL.
		LD	(RAMTOP),HL	; update system variable RAMTOP.
		POP	DE		; pop the return address STMT_RET.
		POP	BC		; pop the Error Address.
		LD	(HL),$3E	; now put the GO SUB end-marker at RAMTOP.
		DEC	HL		; leave a location beneath it.
		LD	SP,HL		; initialize the machine stack pointer.
		PUSH	BC		; push the error address.
		LD	(ERR_SP),SP	; make ERR_SP point to location.
		EX	DE,HL		; put STMT_RET in HL.
		JP	(HL)		; and go there directly.

;----------------------
; Handle GO SUB command
;----------------------
; The GO SUB command diverts Basic control to a new line number
; in a very similar manner to GO TO but
; the current line number and current statement + 1
; are placed on the GO SUB stack as a RETURN point.

					;;;$1EED
GO_SUB:		POP	DE		; drop the address STMT_RET
		LD	H,(IY+$0D)	; fetch statement from SUBPPC and
		INC	H		; increment it
		EX	(SP),HL		; swap - error address to HL,
					; H (statement) at top of stack,
					; L (unimportant) beneath.
		INC	SP		; adjust to overwrite unimportant byte
		LD	BC,(PPC)	; fetch the current line number from PPC
		PUSH	BC		; and PUSH onto GO SUB stack.
					; the empty machine-stack can be rebuilt
		PUSH	HL		; push the error address.
		LD	(ERR_SP),SP	; make system variable ERR_SP point to it.
		PUSH	DE		; push the address STMT_RET.
		CALL	GO_TO		; call routine GO_TO to update the system
					; variables NEWPPC and NSPPC.
					; then make an indirect exit to STMT_RET via
		LD	BC,$0014	; a 20-byte overhead memory check.

;-----------------------
; Check available memory
;-----------------------
; This routine is used on many occasions when extending a dynamic area
; upwards or the GO SUB stack downwards.

					;;;$1F05
TEST_ROOM:	LD	HL,(STKEND)	; fetch STKEND
		ADD	HL,BC		; add the supplied test value
		JR	C,REPORT_4	; forward to REPORT_4 if over $FFFF

		EX	DE,HL		; was less so transfer to DE
		LD	HL,$0050	; test against another 80 bytes
		ADD	HL,DE		; anyway
		JR	C,REPORT_4	; forward to REPORT_4 if this passes $FFFF

		SBC	HL,SP		; if less than the machine stack pointer
		RET	C		; then return - OK.

					;;;$1F15
REPORT_4:	LD	L,$03		; prepare 'Out of Memory' 
		JP	ERROR_3		; jump back to ERROR_3 at $0055
					; Note. this error can't be trapped at $0008

;------------
; Free memory
;------------
; This routine is not used by the ROM but allows users to evaluate
; approximate free memory with PRINT 65536 - USR 7962.

					;;$1F1A
FREE_MEM:	LD	BC,$0000	; allow no overhead.
		CALL	TEST_ROOM	; routine TEST_ROOM.
		LD	B,H		; transfer the result
		LD	C,L		; to BC register.
		RET			; USR function returns value of BC.

;----------------------
; Handle RETURN command
;----------------------
; As with any command, there are two values on the
; machine stack at the time it is invoked.
; The machine stack is below the GOSUB stack
; Both grow downwards, the machine stack by two bytes,
; the gosub stack by 3 bytes. Highest is statement byte
; then a two-byte line number.

					;;;$1F23
RETURN:		POP	BC		; drop the address STMT_RET.
		POP	HL		; now the error address.
		POP	DE		; now a possible basic return line.
		LD	A,D		; the high byte $00 - $27 is 
		CP	$3E		; compared with the traditional end-marker $3E.
		JR	Z,REPORT_7	; forward to REPORT_7 with a match.
					; 'RETURN without GOSUB'

					; It was not the end-marker so a single statement byte remains at the base of 
					; the calculator stack. It can't be popped off.

		DEC	SP		; adjust stack pointer to create room for two  bytes.
		EX	(SP),HL		; statement to H, error address to base of
					; new machine stack.
		EX	DE,HL		; statement to D,  basic line number to HL.
		LD	(ERR_SP),SP	; adjust ERR_SP to point to new stack pointer
		PUSH	BC		; now re-stack the address STMT_RET
		JP	GO_TO_2		; to GO_TO_2 to update statement and line
					; system variables and exit indirectly to the
					; address just pushed on stack.

					;;;$1F36
REPORT_7:	PUSH	DE		; replace the end-marker.
		PUSH	HL		; now restore the error address
					; as required in a few clock cycles.
		RST	08H		; ERROR_1
		DEFB	$06		; Error Report: RETURN without GOSUB

;---------------------
; Handle PAUSE command
;---------------------
; The pause command takes as it's parameter the number of interrupts
; for which to wait. PAUSE 50 pauses for about a second.
; PAUSE 0 pauses indefinitely.
; Both forms can be finished by pressing a key.

					;;;$1F3A
PAUSE:	CALL	FIND_INT2		; routine FIND_INT2 puts value in BC

					;;;$1F3D
PAUSE_1:	HALT			; wait for interrupt.
		DEC	BC		; decrease counter.
		LD	A,B		; test if
		OR	C		; result is zero.
		JR	Z,PAUSE_END	; forward to PAUSE_END if so.

		LD	A,B		; test if
		AND	C		; now $FFFF
		INC	A		; that is, initially zero.
		JR	NZ,PAUSE_2	; skip forward to PAUSE_2 if not.

		INC	BC		; restore counter to zero.

					;;;$1F49
PAUSE_2:	BIT	5,(IY+$01)	; test FLAGS - has a new key been pressed ?
		JR	Z,PAUSE_1	; back to PAUSE_1 if not.

					;;;$1F4F
PAUSE_END:	RES	5,(IY+$01)	; update FLAGS - signal no new key
		RET			; and return.

;--------------------
; Check for BREAK key
;--------------------
; This routine is called from COPY_LINE, when interrupts are disabled,
; to test if BREAK (SHIFT - SPACE) is being pressed.
; It is also called at STMT_RET after every statement.

					;;;$1F54
BREAK_KEY:	LD	A,$7F		; Input address: $7FFE
		IN	A,($FE)		; read lower right keys
		RRA			; rotate bit 0 - SPACE
		RET	C		; return if not reset

		LD	A,$FE		; Input address: $FEFE
		IN	A,($FE)		; read lower left keys
		RRA			; rotate bit 0 - SHIFT
		RET			; carry will be set if not pressed.
					; return with no carry if both keys pressed.

;----------------------
; Handle DEF FN command
;----------------------
; e.g DEF FN r$(a$,a) = a$(a TO )
; this 'command' is ignored in runtime but has it's syntax checked
; during line-entry.

					;;;$1F60
DEF_FN:		CALL	SYNTAX_Z	; routine SYNTAX_Z
		JR	Z,DEF_FN_1	; forward to DEF_FN_1 if parsing

		LD	A,$CE		; else load A with 'DEF FN' and
		JP	PASS_BY		; jump back to PASS_BY

					; continue here if checking syntax.

					;;;$1F6A
DEF_FN_1:	SET	6,(IY+$01)	; set FLAGS  - Assume numeric result
		CALL	ALPHA		; call routine ALPHA
		JR	NC,DEF_FN_4	; if not then to DEF_FN_4 to jump to
					; 'Nonsense in Basic'
		RST	20H		; NEXT_CHAR
		CP	$24		; is it '$' ?
		JR	NZ,DEF_FN_2	; to DEF_FN_2 if not as numeric.

		RES	6,(IY+$01)	; set FLAGS  - Signal string result
		RST	20H		; get NEXT_CHAR

					;;;$1F7D
DEF_FN_2:	CP	$28		; is it '(' ?
		JR	NZ,DEF_FN_7	; to DEF_FN_7 'Nonsense in Basic'

		RST	20H		; NEXT_CHAR
		CP	$29		; is it ')' ?
		JR	Z,DEF_FN_6	; to DEF_FN_6 if null argument

					;;;$1F86
DEF_FN_3:	CALL	ALPHA		; routine ALPHA checks that it is the expected  alphabetic character.

					;;;$1F89
DEF_FN_4:	JP	NC,REPORT_C	; to REPORT_C  if not
					; 'Nonsense in Basic'.

		EX	DE,HL		; save pointer in DE
		RST	20H		; NEXT_CHAR re-initializes HL from CH_ADD and advances.
		CP	$24		; '$' ? is it a string argument.
		JR	NZ,DEF_FN_5	; forward to DEF_FN_5 if not.

		EX	DE,HL		; save pointer to '$' in DE

		RST	20H		; NEXT_CHAR re-initializes HL and advances

					;;;$1F94
DEF_FN_5:	EX	DE,HL		; bring back pointer.
		LD	BC,$0006	; the function requires six hidden bytes for
					; each parameter passed.
					; The first byte will be $0E
					; then 5-byte numeric value
					; or 5-byte string pointer.
		CALL	MAKE_ROOM	; routine MAKE_ROOM creates space in program area.
		INC	HL		; adjust HL (set by LDDR)
		INC	HL		; to point to first location.
		LD	(HL),$0E	; insert the 'hidden' marker.

					; Note. these invisible storage locations hold nothing meaningful for the
					; moment. They will be used every time the corresponding function is
					; evaluated in runtime.
					; Now consider the following character fetched earlier.

		CP	$2C		; is it ',' ? (more than one parameter)
		JR	NZ,DEF_FN_6	; to DEF_FN_6 if not

		RST	20H		; else NEXT_CHAR
		JR	DEF_FN_3	; and back to DEF_FN_3

					;;;$1FA6
DEF_FN_6:	CP	$29		; should close with a ')'
		JR	NZ,DEF_FN_7	; to DEF_FN_7 if not
					; 'Nonsense in Basic'
		RST	20H		; get NEXT_CHAR
		CP	$3D		; is it '=' ?
		JR	NZ,DEF_FN_7	; to DEF_FN_7 if not 'Nonsense...'

		RST	20H		; address NEXT_CHAR
		LD	A,(FLAGS)	; get FLAGS which has been set above
		PUSH	AF		; and save while
		CALL	SCANNING	; routine SCANNING checks syntax of expression and sets flags also
		POP	AF		; restore previous flags
		XOR	(IY+$01)	; xor with FLAGS - bit 6 should be same,  therefore will be reset. 
		AND	$40		; isolate bit 6.

					;;;$1FBD
DEF_FN_7:	JP	NZ,REPORT_C	; jump back to REPORT_C if the expected result is not the same.
					; 'Nonsense in Basic'
		CALL	CHECK_END	; routine CHECK_END will return early if
					; at end of statement and move onto next
					; else produce error report. >>>
					; There will be no return to here.

;--------------------------------
; Returning early from subroutine
;--------------------------------
; All routines are capable of being run in two modes - syntax checking mode
; and runtime mode.
; This routine is called often to allow a routine to return early
; if checking syntax.

					;;;$1FC3
UNSTACK_Z:	CALL	SYNTAX_Z	; routine SYNTAX_Z sets zero flag if syntax is being checked.
		POP	HL		; drop the return address.
		RET	Z		; return to previous call in chain if checking syntax.

		JP	(HL)		; jump to return address as Basic program is
					; actually running.

;----------------------
; Handle LPRINT command
;----------------------
; A simple form of 'PRINT #3' although it can output to 16 streams.
; Probably for compatibility with other basics particularly ZX81 Basic.
; An extra UDG might have been better.

					;;;$1FC9
LPRINT:		LD	A,$03		; the printer channel
		JR	PRINT_1		; forward to PRINT_1

;----------------------
; Handle PRINT commands
;----------------------
; The Spectrum's main stream output command.
; The default stream is stream 2 which is normally the upper screen
; of the computer. However the stream can be altered in range 0 - 15.

					;;;$1FCD
PRINT:		LD	A,$02		; the stream for the upper screen.

					; The LPRINT command joins here.

					;;;$1FCF
PRINT_1:	CALL	SYNTAX_Z	; routine SYNTAX_Z checks if program running
		CALL	NZ,CHAN_OPEN	; routine CHAN_OPEN if so
		CALL	TEMPS		; routine TEMPS sets temporary colours.
		CALL	PRINT_2		; routine PRINT_2 - the actual item
		CALL	CHECK_END	; routine CHECK_END gives error if not at end of statement
		RET			; and return >>>

					; this subroutine is called from above
					; and also from INPUT.

					;;;$1FDF
PRINT_2:	RST	18H		; GET_CHAR gets printable character
		CALL	PR_END_Z	; routine PR_END_Z checks if more printing
		JR	Z,PRINT_4	; to PRINT_4 if not	e.g. just 'PRINT :'

					; This tight loop deals with combinations of positional controls and
					; print items. An early return can be made from within the loop
					; if the end of a print sequence is reached.

					;;;$1FE5
PRINT_3:	CALL	PR_POSN_1	; routine PR_POSN_1 returns zero if more
					; but returns early at this point if
					; at end of statement!
		JR	Z,PRINT_3	; to PRINT_3 if consecutive positioners

		CALL	PR_ITEM_1	; routine PR_ITEM_1 deals with strings etc.
		CALL	PR_POSN_1	; routine PR_POSN_1 for more position codes
		JR	Z,PRINT_3	; loop back to PRINT_3 if so

					;;;$1FF2
PRINT_4:	CP	$29		; return now if this is ')' from input-item.
					; (see INPUT.)
		RET	Z		; or continue and print carriage return in
					; runtime

;----------------------
; Print carriage return
;----------------------
; This routine which continues from above prints a carriage return
; in run-time. It is also called once from PRINT_POSN.

					;;;$1FF5
PRINT_CR:	CALL	UNSTACK_Z	; routine UNSTACK_Z
		LD	A,$0D		; prepare a carriage return
		RST	10H		; PRINT_A
		RET			; return

;------------
; Print items
;------------
; This routine deals with print items as in
; PRINT AT 10,0;"The value of A is ";a
; It returns once a single item has been dealt with as it is part
; of a tight loop that considers sequences of positional and print items

					;;;$1FFC
PR_ITEM_1:	RST	18H		; GET_CHAR
		CP	$AC		; is character 'AT' ?
		JR	NZ,PR_ITEM_2	; forward to PR_ITEM_2 if not.

		CALL	NEXT_2NUM	; routine NEXT_2NUM  check for two comma 
					; separated numbers placing them on the 
					; calculator stack in runtime. 
		CALL	UNSTACK_Z	; routine UNSTACK_Z quits if checking syntax.
		CALL	STK_TO_BC	; routine STK_TO_BC get the numbers in B and C.
		LD	A,$16		; prepare the 'at' control.
		JR	PR_AT_TAB	; forward to PR_AT_TAB to print the sequence.

					;;;$200E
PR_ITEM_2:	CP	$AD		; is character 'TAB' ?
		JR	NZ,PR_ITEM_3	; to PR_ITEM_3 if not

		RST	20H		; NEXT_CHAR to address next character
		CALL	EXPT_1NUM	; routine EXPT_1NUM
		CALL	UNSTACK_Z	; routine UNSTACK_Z quits if checking syntax.
		CALL	FIND_INT2	; routine FIND_INT2 puts integer in BC.
		LD	A,$17		; prepare the 'tab' control.

					;;;$201E
PR_AT_TAB:	RST	10H		; PRINT_A outputs the control
		LD	A,C		; first value to A
		RST	10H		; PRINT_A outputs it.
		LD	A,B		; second value
		RST	10H		; PRINT_A
		RET			; return - item finished >>>

					; Now consider paper 2; #2; a$

					;;;$2024
PR_ITEM_3:	CALL	CO_TEMP_3	; routine CO_TEMP_3 will print any colour
		RET	NC		; items - return if success.

		CALL	STR_ALTER	; routine STR_ALTER considers new stream
		RET	NC		; return if altered.

		CALL	SCANNING	; routine SCANNING now to evaluate expression
		CALL	UNSTACK_Z	; routine UNSTACK_Z if not runtime.
		BIT	6,(IY+$01)	; test FLAGS  - Numeric or string result ?
		CALL	Z,STK_FETCH	; routine STK_FETCH if string.
					; note no flags affected.
		JP	NZ,PRINT_FP	; to PRINT_FP to print if numeric >>>

					; It was a string expression - start in DE, length in BC
					; Now enter a loop to print it

					;;;$203C
PR_STRING:	LD	A,B		; this tests if the
		OR	C		; length is zero and sets flag accordingly.
		DEC	BC		; this doesn't but decrements counter.
		RET	Z		; return if zero.

		LD	A,(DE)		; fetch character.
		INC	DE		; address next location.
		RST	10H		; PRINT_A.
		JR	PR_STRING	; loop back to PR_STRING.

;----------------
; End of printing
;----------------
; This subroutine returns zero if no further printing is required
; in the current statement.
; The first terminator is found in escaped input items only,
; the others in print_items.

					;;;$2045
PR_END_Z:	CP	$29		; is character a ')' ?
		RET	Z		; return if so - e.g. INPUT (p$); a$

					;;;$2048
PR_ST_END:	CP	$0D		; is it a carriage return ?
		RET	Z		; return also -	 e.g. PRINT a

		CP	$3A		; is character a ':' ?
		RET			; return - zero flag will be set if so.
					;		 e.g. PRINT a :

;---------------
; Print position
;---------------
; This routine considers a single positional character ';', ',', '''

					;;;$204E
PR_POSN_1:	RST	18H		; GET_CHAR
		CP	$3B		; is it ';' ?		
					; i.e. print from last position.
		JR	Z,PR_POSN_3	; forward to PR_POSN_3 if so.
					; i.e. do nothing.
		CP	$2C		; is it ',' ?
					; i.e. print at next tabstop.
		JR	NZ,PR_POSN_2	; forward to PR_POSN_2 if anything else.

		CALL	SYNTAX_Z	; routine SYNTAX_Z
		JR	Z,PR_POSN_3	; forward to PR_POSN_3 if checking syntax.

		LD	A,$06		; prepare the 'comma' control character.
		RST	10H		; PRINT_A  outputs to current channel in run-time.
		JR	PR_POSN_3	; skip to PR_POSN_3.

					; check for newline.

					;;;$2061
PR_POSN_2:	CP	$27		; is character a "'" ? (newline)
		RET	NZ		; return if no match		>>>

		CALL	PRINT_CR	; routine PRINT_CR outputs a carriage return in runtime only.

					;;;$2067
PR_POSN_3:	RST	20H		; NEXT_CHAR to A.
		CALL	PR_END_Z	; routine PR_END_Z checks if at end.
		JR	NZ,PR_POSN_4	; to PR_POSN_4 if not.

		POP	BC		; drop return address if at end.

					;;;$206E
PR_POSN_4:	CP	A		; reset the zero flag.
		RET			; and return to loop or quit.

;-------------
; Alter stream
;-------------
; This routine is called from PRINT ITEMS above, and also LIST as in
; LIST #15

					;;;$2070
STR_ALTER:	CP	$23		; is character '#' ?
		SCF			; set carry flag.
		RET	NZ		; return if no match.

		RST	20H		; NEXT_CHAR
		CALL	EXPT_1NUM	; routine EXPT_1NUM gets stream number
		AND	A		; prepare to exit early with carry reset
		CALL	UNSTACK_Z	; routine UNSTACK_Z exits early if parsing
		CALL	FIND_INT1	; routine FIND_INT1 gets number off stack
		CP	$10		; must be range 0 - 15 decimal.
		JP	NC,REPORT_OA	; jump back to REPORT_OA if not
					; 'Invalid stream'.
		CALL	CHAN_OPEN	; routine CHAN_OPEN
		AND	A		; clear carry - signal item dealt with.
		RET			; return

;---------------------
; Handle INPUT command
;---------------------
; This command
;

					;;;$2089
INPUT:		CALL	SYNTAX_Z	; routine SYNTAX_Z to check if in runtime.
		JR	Z,INPUT_1	; forward to INPUT_1 if checking syntax.

		LD	A,$01		; select channel 'K' the keyboard for input.
		CALL	CHAN_OPEN	; routine CHAN_OPEN opens it.
		CALL	CLS_LOWER	; routine CLS_LOWER clears the lower screen.

					;;;$2096
INPUT_1:	LD	(IY+$02),$01	; set TV_FLAG - signal lower screen in use and clear the other bits.
		CALL	IN_ITEM_1	; routine IN_ITEM_1 to handle the input.
		CALL	CHECK_END	; routine CHECK_END will make an early exit  if checking syntax. >>>

					; keyboard input has been made and it remains to adjust the upper
					; screen in case the lower two lines have been extended upwards.

		LD	BC,(S_POSN)	; fetch S_POSN current line/column of the upper screen.
		LD	A,(DF_SZ)	; fetch DF_SZ the display file size of the lower screen.
		CP	B		; test that lower screen does not overlap
		JR	C,INPUT_2	; forward to INPUT_2 if not.

					; the two screens overlap so adjust upper screen.

		LD	C,$21		; set column of upper screen to leftmost.
		LD	B,A		; and line to one above lower screen.
					; continue forward to update upper screen
					; print position.

					;;;$20AD
INPUT_2:	LD	(S_POSN),BC	; set S_POSN update upper screen line/column.
		LD	A,$19		; subtract from twenty five
		SUB	B		; the new line number.
		LD	(SCR_CT),A	; and place result in SCR_CT - scroll count.
		RES	0,(IY+$02)	; update TV_FLAG - signal main screen in use.
		CALL	CL_SET		; routine CL_SET sets the print position
					; system variables for the upper screen.
		JP	CLS_LOWER	; jump back to CLS_LOWER and make
					; an indirect exit >>.

;----------------------
; INPUT ITEM subroutine
;----------------------
; This subroutine deals with the input items and print items.
; from  the current input channel.
; It is only called from the above INPUT routine but was obviously
; once called from somewhere else in another context.

					;;;$20C1
IN_ITEM_1:	CALL	PR_POSN_1	; routine PR_POSN_1 deals with a single
					; position item at each call.
		JR	Z,IN_ITEM_1	; back to IN_ITEM_1 until no more in a sequence.

		CP	$28		; is character '(' ?
		JR	NZ,IN_ITEM_2	; forward to IN_ITEM_2 if not.

					; any variables within braces will be treated as part, or all, of the prompt
					; instead of being used as destination variables.

		RST	20H		; NEXT_CHAR
		CALL	PRINT_2		; routine PRINT_2 to output the dynamic prompt.
		RST	18H		; GET_CHAR
		CP	$29		; is character a matching ')' ?
		JP	NZ,REPORT_C	; jump back to REPORT_C if not.
					; 'Nonsense in basic'.
		RST	20H		; NEXT_CHAR
		JP	IN_NEXT_2	; forward to IN_NEXT_2

					;;;$20D8
IN_ITEM_2:	CP	$CA		; is the character the token 'LINE' ?
		JR	NZ,IN_ITEM_3	; forward to IN_ITEM_3 if not.

		RST	20H		; NEXT_CHAR - variable must come next.
		CALL	CLASS_01	; routine CLASS_01 returns destination
					; address of variable to be assigned.
					; or generates an error if no variable
					; at this position.

		SET	7,(IY+$37)	; update FLAGX  - signal handling INPUT LINE
		BIT	6,(IY+$01)	; test FLAGS  - numeric or string result ?
		JP	NZ,REPORT_C	; jump back to REPORT_C if not string
					; 'Nonsense in basic'.

		JR	IN_PROMPT	; forward to IN_PROMPT to set up workspace.

					; the jump was here for other variables.

					;;;$20ED
IN_ITEM_3:	CALL	ALPHA		; routine ALPHA checks if character is
					; a suitable variable name.
		JP	NC,IN_NEXT_1	; forward to IN_NEXT_1 if not

		CALL	CLASS_01	; routine CLASS_01 returns destination
					; address of variable to be assigned.
		RES	7,(IY+$37)	; update FLAGX  - signal not INPUT LINE.

					;;;$20FA
IN_PROMPT:	CALL	SYNTAX_Z	; routine SYNTAX_Z
		JP	Z,IN_NEXT_2	; forward to IN_NEXT_2 if checking syntax.

		CALL	SET_WORK	; routine SET_WORK clears workspace.
		LD	HL,FLAGX	; point to system variable FLAGX
		RES	6,(HL)		; signal string result.
		SET	5,(HL)		; signal in Input Mode for editor.
		LD	BC,$0001	; initialize space required to one for
					; the carriage return.
		BIT	7,(HL)		; test FLAGX - INPUT LINE in use ?
		JR	NZ,IN_PR_2	; forward to IN_PR_2 if so as that is  all the space that is required.

		LD	A,(FLAGS)	; load accumulator from FLAGS
		AND	$40		; mask to test BIT 6 of FLAGS and clear the other bits in A.
					; numeric result expected ?
		JR	NZ,IN_PR_1	; forward to IN_PR_1 if so

		LD	C,$03		; increase space to three bytes for the pair of surrounding quotes.

					;;;$211A
IN_PR_1:	OR	(HL)		; if numeric result, set bit 6 of FLAGX.
		LD	(HL),A		; and update system variable

					;;;$211C
IN_PR_2:	RST	30H		; BC_SPACES opens 1 or 3 bytes in workspace
		LD	(HL),$0D	; insert carriage return at last new location.
		LD	A,C		; fetch the length, one or three.
		RRCA			; lose bit 0.
		RRCA			; test if quotes required.
		JR	NC,IN_PR_3	; forward to IN_PR_3 if not.

		LD	A,$22		; load the '"' character
		LD	(DE),A		; place quote in first new location at DE.
		DEC	HL		; decrease HL - from carriage return.
		LD	(HL),A		; and place a quote in second location.

					;;;$2129
IN_PR_3:	LD	(K_CUR),HL	; set keyboard cursor K_CUR to HL
		BIT	7,(IY+$37)	; test FLAGX  - is this INPUT LINE ??
		JR	NZ,IN_VAR_3	; forward to IN_VAR_3 if so as input will
					; be accepted without checking it's syntax.
		LD	HL,(CH_ADD)	; fetch CH_ADD
		PUSH	HL		; and save on stack.
		LD	HL,(ERR_SP)	; fetch ERR_SP
		PUSH	HL		; and save on stack

					;;;$213A
IN_VAR_1:	LD	HL,IN_VAR_1	; address: IN_VAR_1 - this address
		PUSH	HL		; is saved on stack to handle errors.
		BIT	4,(IY+$30)	; test FLAGS2  - is K channel in use ?
		JR	Z,IN_VAR_2	; forward to IN_VAR_2 if not using the keyboard for input. (??)

		LD	(ERR_SP),SP	; set ERR_SP to point to IN_VAR_1 on stack.

					;;;$2148
IN_VAR_2:	LD	HL,(WORKSP)	; set HL to WORKSP - start of workspace.
		CALL	REMOVE_FP	; routine REMOVE_FP removes floating point
					; forms when looping in error condition.
		LD	(IY+$00),$FF	; set ERR_NR to 'OK' cancelling the error.
					; but X_PTR causes flashing error marker
					; to be displayed at each call to the editor.
		CALL	EDITOR		; routine EDITOR allows input to be entered
					; or corrected if this is second time around.

					; if we pass to next then there are no system errors

		RES	7,(IY+$01)	; update FLAGS  - signal checking syntax
		CALL	IN_ASSIGN	; routine IN_ASSIGN checks syntax using
					; the VAL_FET_2 and powerful SCANNING routines.
					; any syntax error and it's back to IN_VAR_1.
					; but with the flashing error marker showing
					; where the error is.
					; Note. the syntax of string input has to be
					; checked as the user may have removed the
					; bounding quotes or escaped them as with
					; "hat" + "stand" for example.
					; proceed if syntax passed.

		JR	IN_VAR_4	; jump forward to IN_VAR_4

					; the jump was to here when using INPUT LINE.

					;;;$215E
IN_VAR_3:	CALL	EDITOR		; routine EDITOR is called for input

					; when ENTER received rejoin other route but with no syntax check.

					; INPUT and INPUT LINE converge here.

					;;;$2161
IN_VAR_4:	LD	(IY+$22),$00	; set K_CUR_hi to a low value so that the cursor
					; no longer appears in the input line.
		CALL	IN_CHAN_K	; routine IN_CHAN_K tests if the keyboard
					; is being used for input.
		JR	NZ,IN_VAR_5	; forward to IN_VAR_5 if using another input channel.

					; continue here if using the keyboard.

		CALL	ED_COPY		; routine ED_COPY overprints the edit line
					; to the lower screen. The only visible
					; affect is that the cursor disappears.
					; if you're inputting more than one item in
					; a statement then that becomes apparent.
		LD	BC,(ECHO_E)	; fetch line and column from ECHO_E
		CALL	CL_SET		; routine CL_SET sets S-POSNL to those values.

					; if using another input channel rejoin here.

					;;;$2174
IN_VAR_5:	LD	HL,FLAGX	; point HL to FLAGX
		RES	5,(HL)		; signal not in input mode
		BIT	7,(HL)		; is this INPUT LINE ?
		RES	7,(HL)		; cancel the bit anyway.
		JR	NZ,IN_VAR_6	; forward to IN_VAR_6 if INPUT LINE.

		POP	HL		; drop the looping address
		POP	HL		; drop the the address of previous error handler.
		LD	(ERR_SP),HL	; set ERR_SP to point to it.
		POP	HL		; drop original CH_ADD which points to INPUT command in BASIC line.
		LD	(X_PTR),HL	; save in X_PTR while input is assigned.
		SET	7,(IY+$01)	; update FLAGS - Signal running program
		CALL	IN_ASSIGN	; routine IN_ASSIGN is called again
					; this time the variable will be assigned
					; the input value without error.
					; Note. the previous example now
					; becomes "hatstand"
		LD	HL,(X_PTR)	; fetch stored CH_ADD value from X_PTR.
		LD	(IY+$26),$00	; set X_PTR_HI so that no longer relevant.
		LD	(CH_ADD),HL	; put restored value back in CH_ADD
		JR	IN_NEXT_2	; forward to IN_NEXT_2 to see if anything
					; more in the INPUT list.

					; the jump was to here with INPUT LINE only

					;;;$219B
IN_VAR_6:	LD	HL,(STKBOT)	; STKBOT points to the end of the input.
		LD	DE,(WORKSP)	; WORKSP points to the beginning.
		SCF			; prepare for true subtraction.
		SBC	HL,DE		; subtract to get length
		LD	B,H		; transfer it to
		LD	C,L		; the BC register pair.
		CALL	STK_STO_D	; routine STK_STO_D stores parameters on
					; the calculator stack.
		CALL	LET		; routine LET assigns it to destination.
		JR	IN_NEXT_2	; forward to IN_NEXT_2 as print items
					; not allowed with INPUT LINE.
					; Note. that "hat" + "stand" will, for
					; example, be unchanged as also would
					; 'PRINT "Iris was here"'.

					; the jump was to here when ALPHA found more items while looking for
					; a variable name.

					;;;$21AF
IN_NEXT_1:	CALL	PR_ITEM_1	; routine PR_ITEM_1 considers further items.

					;;;$21B2
IN_NEXT_2:	CALL	PR_POSN_1	; routine PR_POSN_1 handles a position item.
		JP	Z,IN_ITEM_1	; jump back to IN_ITEM_1 if the zero flag
					; indicates more items are present.

		RET			; return.

;----------------------------
; INPUT ASSIGNMENT Subroutine
;----------------------------
; This subroutine is called twice from the INPUT command when normal
; keyboard input is assigned. On the first occasion syntax is checked
; using SCANNING. The final call with the syntax flag reset is to make
; the assignment.

					;;;$21B9
IN_ASSIGN:	LD	HL,(WORKSP)	; fetch WORKSP start of input
		LD	(CH_ADD),HL	; set CH_ADD to first character
		RST	18H		; GET_CHAR ignoring leading white-space.
		CP	$E2		; is it 'STOP'
		JR	Z,IN_STOP	; forward to IN_STOP if so.

		LD	A,(FLAGX)	; load accumulator from FLAGX
		CALL	VAL_FET_2	; routine VAL_FET_2 makes assignment
					; or goes through the motions if checking
					; syntax. SCANNING is used.
		RST	18H		; GET_CHAR
		CP	$0D		; is it carriage return ?
		RET	Z		; return if so
					; either syntax is OK
					; or assignment has been made.

					; if another character was found then raise an error.
					; User doesn't see report but the flashing error marker
					; appears in the lower screen.

					;;;$21CE
REPORT_CB:	RST	08H		; ERROR_1
		DEFB	$0B		; Error Report: Nonsense in BASIC

					;;;$21D0
IN_STOP:	CALL	SYNTAX_Z	; routine SYNTAX_Z (UNSTACK_Z?)
		RET	Z		; return if checking syntax
					; as user wouldn't see error report.
					; but generate visible error report
					; on second invocation.

					;;;$21D4
REPORT_H:	RST	08H		; ERROR_1
		DEFB	$10		; Error Report: STOP in INPUT

;-------------------
; Test for channel K
;-------------------
; This subroutine is called once from the keyboard
; INPUT command to check if the input routine in
; use is the one for the keyboard.

					;;;$21D6
IN_CHAN_K:	LD	HL,(CURCHL)	; fetch address of current channel CURCHL
		INC	HL
		INC	HL		; advance past
		INC	HL		; input and
		INC	HL		; output streams
		LD	A,(HL)		; fetch the channel identifier.
		CP	$4B		; test for 'K'
		RET			; return with zero set if keyboard is use.

;---------------------
; Colour Item Routines
;---------------------
;
; These routines have 3 entry points -
; 1) CO_TEMP_2 to handle a series of embedded Graphic colour items.
; 2) CO_TEMP_3 to handle a single embedded print colour item.
; 3) CO_TEMP_4 to handle a colour command such as FLASH 1
;
; "Due to a bug, if you bring in a peripheral channel and later use a colour
;  statement, colour controls will be sent to it by mistake." - Steven Vickers
;  Pitman Pocket Guide, 1984.
;
; To be fair, this only applies if the last channel was other than 'K', 'S'
; or 'P', which are all that are supported by this ROM, but if that last
; channel was a microdrive file, network channel etc. then
; PAPER 6; CLS will not turn the screen yellow and
; CIRCLE INK 2; 128,88,50 will not draw a red circle.
;
; This bug does not apply to embedded PRINT items as it is quite permissible
; to mix stream altering commands and colour items.
; The fix therefore would be to ensure that CLASS_07 and CLASS_09 make
; PRINT_OUT the current channel when not checking syntax.
; -----------------------------------------------------------------

					;;;$21E1
CO_TEMP_1:	RST	20H		; NEXT_CHAR

					; -> Entry point from CLASS_09. Embedded Graphic colour items.
					; e.g. PLOT INK 2; PAPER 8; 128,88
					; Loops till all colour items output, finally addressing the coordinates.

					;;;$21E2
CO_TEMP_2:	CALL	CO_TEMP_3	; routine CO_TEMP_3 to output colour control.
		RET	C		; return if nothing more to output. ->

		RST	18H		; GET_CHAR
		CP	$2C		; is it ',' separator ?
		JR	Z,CO_TEMP_1	; back if so to CO_TEMP_1

		CP	$3B		; is it ';' separator ?
		JR	Z,CO_TEMP_1	; back to CO_TEMP_1 for more.

		JP	REPORT_C	; to REPORT_C (REPORT_CB is within range)
					; 'Nonsense in Basic'

; -------------------
; CO_TEMP_3
; -------------------
; -> this routine evaluates and outputs a colour control and parameter.
; It is called from above and also from PR_ITEM_3 to handle a single embedded
; print item e.g. PRINT PAPER 6; "Hi". In the latter case, the looping for
; multiple items is within the PR-ITEM routine.
; It is quite permissible to send these to any stream.

					;;;$21F2
CO_TEMP_3:	CP	$D9		; is it 'INK' ?
		RET	C		; return if less.

		CP	$DF		; compare with 'OUT'
		CCF			; Complement Carry Flag
		RET	C		; return if greater than 'OVER', $DE.

		PUSH	AF		; save the colour token.
		RST	20H		; address NEXT_CHAR
		POP	AF		; restore token and continue.

					; -> this entry point used by CLASS_07. e.g. the command PAPER 6.

					;;;$21FC
CO_TEMP_4:	SUB	$C9		; reduce to control character $10 (INK) thru $15 (OVER).
		PUSH	AF		; save control.
		CALL	EXPT_1NUM	; routine EXPT_1NUM stacks addressed
					; parameter on calculator stack.
		POP	AF		; restore control.
		AND	A		; clear carry
		CALL	UNSTACK_Z	; routine UNSTACK_Z returns if checking syntax.
		PUSH	AF		; save again
		CALL	FIND_INT1	; routine FIND_INT1 fetches parameter to A.
		LD	D,A		; transfer now to D
		POP	AF		; restore control.
		RST	10H		; PRINT_A outputs the control to current channel.
		LD	A,D		; transfer parameter to A.
		RST	10H		; PRINT_A outputs parameter.
		RET			; return. ->

; -------------------------------------------------------------------------
;
;         {fl}{br}{   paper   }{  ink    }    The temporary colour attributes
;          ___ ___ ___ ___ ___ ___ ___ ___    system variable.
; ATTR_T  |   |   |   |   |   |   |   |   |
;         |   |   |   |   |   |   |   |   |
; 23695   |___|___|___|___|___|___|___|___|
;           7   6   5   4   3   2   1   0
;
;
;         {fl}{br}{   paper   }{  ink    }    The temporary mask used for
;          ___ ___ ___ ___ ___ ___ ___ ___    transparent colours. Any bit
; MASK_T  |   |   |   |   |   |   |   |   |   that is 1 shows that the
;         |   |   |   |   |   |   |   |   |   corresponding attribute is
; 23696   |___|___|___|___|___|___|___|___|   taken not from ATTR-T but from
;           7   6   5   4   3   2   1   0     what is already on the screen.
;
;
;         {paper9 }{ ink9 }{ inv1 }{ over1}   The print flags. Even bits are
;          ___ ___ ___ ___ ___ ___ ___ ___    temporary flags. The odd bits
; P_FLAG  |   |   |   |   |   |   |   |   |   are the permanent flags.
;         | p | t | p | t | p | t | p | t |
; 23697   |___|___|___|___|___|___|___|___|
;           7   6   5   4   3   2   1   0
;
; -----------------------------------------------------------------------


; ------------------------------------
;  The colour system variable handler.
; ------------------------------------
; This is an exit branch from PO_1_OPER, PO_2_OPER
; A holds control $10 (INK) to $15 (OVER)
; D holds parameter 0-9 for ink/paper 0,1 or 8 for bright/flash,
; 0 or 1 for over/inverse.

					;;;$2211
CO_TEMP_5:	SUB	$11		; reduce range $FF-$04
		ADC	A,$00		; add in carry if INK
		JR	Z,CO_TEMP_7	; forward to CO_TEMP_7 with INK and PAPER.

		SUB	$02		; reduce range $FF-$02
		ADC	A,$00		; add carry if FLASH
		JR	Z,CO_TEMP_C	; forward to CO_TEMP_C with FLASH and BRIGHT.

		CP	$01		; is it 'INVERSE' ?
		LD	A,D		; fetch parameter for INVERSE/OVER
		LD	B,$01		; prepare OVER mask setting bit 0.
		JR	NZ,CO_TEMP_6	; forward to CO_TEMP_6 if OVER

		RLCA			; shift bit 0
		RLCA			; to bit 2
		LD	B,$04		; set bit 2 of mask for inverse.

					;;;$2228
CO_TEMP_6:	LD	C,A		; save the A
		LD	A,D		; re-fetch parameter
		CP	$02		; is it less than 2
		JR	NC,REPORT_K	; to REPORT_K if not 0 or 1.
					; 'Invalid colour'.
		LD	A,C		; restore A
		LD	HL,P_FLAG	; address system variable P_FLAG
		JR	CO_CHANGE	; forward to exit via routine CO_CHANGE

					; the branch was here with INK/PAPER and carry set for INK.

					;;;$2234
CO_TEMP_7:	LD	A,D		; fetch parameter
		LD	B,$07		; set ink mask 00000111
		JR	C,CO_TEMP_8	; forward to CO_TEMP_8 with INK

		RLCA			; shift bits 0-2
		RLCA			; to
		RLCA			; bits 3-5
		LD	B,$38		; set paper mask 00111000

					; both paper and ink rejoin here

					;;;$223E
CO_TEMP_8:	LD	C,A		; value to C
		LD	A,D		; fetch parameter
		CP	$0A		; is it less than 10d ?
		JR	C,CO_TEMP_9	; forward to CO_TEMP_9 if so.

					; ink 10 etc. is not allowed.

					;;;$2244
REPORT_K:	RST	08H		; ERROR_1
		DEFB	$13		; Error Report: Invalid colour

					;;;$2246
CO_TEMP_9:	LD	HL,ATTRT_MASKT	; address system variable ATTR_T initially.
		CP	$08		; compare with 8
		JR	C,CO_TEMP_B	; forward to CO_TEMP_B with 0-7.

		LD	A,(HL)		; fetch temporary attribute as no change.
		JR	Z,CO_TEMP_A	; forward to CO_TEMP_A with INK/PAPER 8

					; it is either ink 9 or paper 9 (contrasting)

		OR	B		; or with mask to make white
		CPL			; make black and change other to dark
		AND	$24		; 00100100
		JR	Z,CO_TEMP_A	; forward to CO_TEMP_A if black and
					; originally light.
		LD	A,B		; else just use the mask (white)

					;;;$2257
CO_TEMP_A:	LD	C,A		; save A in C

					;;;$2258
CO_TEMP_B:	LD	A,C		; load colour to A
		CALL	CO_CHANGE	; routine CO_CHANGE addressing ATTR-T
		LD	A,$07		; put 7 in accumulator
		CP	D		; compare with parameter
		SBC	A,A		; $00 if 0-7, $FF if 8
		CALL	CO_CHANGE	; routine CO_CHANGE addressing MASK-T
					; mask returned in A.

					; now consider P-FLAG.

		RLCA			; 01110000 or 00001110
		RLCA			; 11100000 or 00011100
		AND	$50		; 01000000 or 00010000  (AND 01010000)
		LD	B,A		; transfer to mask
		LD	A,$08		; load A with 8
		CP	D		; compare with parameter
		SBC	A,A		; $FF if was 9,  $00 if 0-8
					; continue while addressing P-FLAG
					; setting bit 4 if ink 9
					; setting bit 6 if paper 9

;------------------------
; Handle change of colour
;------------------------
; This routine addresses a system variable ATTR_T, MASK_T or P-FLAG in HL.
; colour value in A, mask in B.

					;;;$226C
CO_CHANGE:	XOR	(HL)		; impress bits specified
		AND	B		; by mask
		XOR	(HL)		; on system variable.
		LD	(HL),A		; update system variable.
		INC	HL		; address next location.
		LD	A,B		; put current value of mask in A
		RET			; return.

					; the branch was here with flash and bright

					;;;$2273
CO_TEMP_C:	SBC	A,A		; set zero flag for bright.
		LD	A,D		; fetch original parameter 0,1 or 8
		RRCA			; rotate bit 0 to bit 7
		LD	B,$80		; mask for flash 10000000
		JR	NZ,CO_TEMP_D	; forward to CO_TEMP_D if flash

		RRCA			; rotate bit 7 to bit 6
		LD	B,$40		; mask for bright 01000000

					;;;$227D
CO_TEMP_D:	LD	C,A		; store value in C
		LD	A,D		; fetch parameter
		CP	$08		; compare with 8
		JR	Z,CO_TEMP_E	; forward to CO_TEMP_E if 8

		CP	$02		; test if 0 or 1
		JR	NC,REPORT_K	; back to REPORT_K if not
					; 'Invalid colour'

					;;;$2287
CO_TEMP_E:	LD	A,C		; value to A
		LD	HL,ATTRT_MASKT	; address ATTR_T
		CALL	CO_CHANGE	; routine CO_CHANGE addressing ATTR_T
		LD	A,C		; fetch value
		RRCA			; for flash8/bright8 complete
		RRCA			; rotations to put set bit in
		RRCA			; bit 7 (flash) bit 6 (bright)
		JR	CO_CHANGE	; back to CO_CHANGE addressing MASK_T
					; and indirect return.

;----------------------
; Handle BORDER command
;----------------------
; Command syntax example: BORDER 7
; This command routine sets the border to one of the eight colours.
; The colours used for the lower screen are based on this.

					;;;$2294
BORDER:		CALL	FIND_INT1	; routine FIND_INT1
		CP	$08		; must be in range 0 (black) to 7 (white)
		JR	NC,REPORT_K	; back to REPORT_K if not
					; 'Invalid colour'.
		OUT	($FE),A		; outputting to port effects an immediate
					; change.
		RLCA			; shift the colour to
		RLCA			; the paper bits setting the
		RLCA			; ink colour black.
		BIT	5,A		; is the number light coloured ?
					; i.e. in the range green to white.
		JR	NZ,BORDER_1	; skip to BORDER_1 if so

		XOR	$07		; make the ink white.

					;;;$22A6
BORDER_1:	LD	(BORDCR),A	; update BORDCR with new paper/ink
		RET			; return.

;------------------
; Get pixel address
;------------------

					;;;$22AA
PIXEL_ADD:	LD	A,$AF		; load with 175 decimal.
		SUB	B		; subtract the y value.
		JP	C,REPORT_BC	; jump forward to REPORT_BC if greater.
					; 'Integer out of range'

					; the high byte is derived from Y only.
					; the first 3 bits are always 010
					; the next 2 bits denote in which third of the screen the byte is.
					; the last 3 bits denote in which of the 8 scan lines within a third
					; the byte is located. There are 24 discrete values.


		LD	B,A		; the line number from top of screen to B.
		AND	A		; clear carry (already clear)
		RRA			;			0xxxxxxx
		SCF			; set carry flag
		RRA			;			10xxxxxx
		AND	A		; clear carry flag
		RRA			;			010xxxxx
		XOR	B
		AND	$F8		; keep the top 5 bits	11111000
		XOR	B		;			010xxbbb
		LD	H,A		; transfer high byte to H.

					; the low byte is derived from both X and Y.

		LD	A,C		; the x value 0-255.
		RLCA
		RLCA
		RLCA
		XOR	B		; the y value
		AND	$C7		; apply mask		11000111
		XOR	B		; restore unmasked bits	xxyyyxxx
		RLCA			; rotate to		xyyyxxxx
		RLCA			; required position.	yyyxxxxx
		LD	L,A		; low byte to L.

					; finally form the pixel position in A.

		LD	A,C		; x value to A
		AND	$07		; mod 8
		RET			; return

;-----------------
; Point Subroutine
;-----------------
; The point subroutine is called from S_POINT via the scanning functions
; table.

					;;;$22CB
POINT_SUB:	CALL	STK_TO_BC	; routine STK_TO_BC
		CALL	PIXEL_ADD	; routine PIXEL_ADD finds address of pixel.
		LD	B,A		; pixel position to B, 0-7.
		INC	B		; increment to give rotation count 1-8.
		LD	A,(HL)		; fetch byte from screen.

					;;;$22D4
POINT_LP:	RLCA			; rotate and loop back
		DJNZ	POINT_LP	; to POINT_LP until pixel at right.
		AND	$01		; test to give zero or one.
		JP	STACK_A		; jump forward to STACK_A to save result.

;--------------------
; Handle PLOT command
;--------------------
; Command Syntax example: PLOT 128,88

					;;;$22DC
PLOT:		CALL	STK_TO_BC	; routine STK_TO_BC
		CALL	PLOT_SUB	; routine PLOT_SUB
		JP	TEMPS		; to TEMPS

; -------------------
; The Plot subroutine
; -------------------
; A screen byte holds 8 pixels so it is necessary to rotate a mask
; into the correct position to leave the other 7 pixels unaffected.
; However all 64 pixels in the character cell take any embedded colour items.
; A pixel can be reset (inverse 1), toggled (over 1), or set ( with inverse
; and over switches off). With both switches on, the byte is simply put
; back on the screen though the colours may change.

					;;;$22E5
PLOT_SUB:	LD	(COORDS),BC	; store new x/y values in COORDS
		CALL	PIXEL_ADD	; routine PIXEL_ADD gets address in HL,
					; count from left 0-7 in B.
		LD	B,A		; transfer count to B.
		INC	B		; increase 1-8.
		LD	A,$FE		; 11111110 in A.

					;;;$22F0
PLOT_LOOP:	RRCA			; rotate mask.
		DJNZ	PLOT_LOOP	; to PLOT_LOOP until B circular rotations.
		LD	B,A		; load mask to B
		LD	A,(HL)		; fetch screen byte to A
		LD	C,(IY+$57)	; P_FLAG to C
		BIT	0,C		; is it to be OVER 1 ?
		JR	NZ,PL_TST_IN	; forward to PL_TST_IN if so.

					; was over 0

		AND	B		; combine with mask to blank pixel.

					;;;$22FD
PL_TST_IN:	BIT	2,C		; is it inverse 1 ?
		JR	NZ,PLOT_END	; to PLOT_END if so.

		XOR	B		; switch the pixel
		CPL			; restore other 7 bits

					;;;$2303
PLOT_END:	LD	(HL),A		; load byte to the screen.
		JP	PO_ATTR		; exit to PO_ATTR to set colours for cell.

;-------------------------------
; Put two numbers in BC register
;-------------------------------

					;;;$2307
STK_TO_BC:	CALL	STK_TO_A	; routine STK_TO_A
		LD	B,A
		PUSH	BC
		CALL	STK_TO_A	; routine STK_TO_A
		LD	E,C
		POP	BC
		LD	D,C
		LD	C,A
		RET

;------------------------
; Put stack in A register
;------------------------
; This routine puts the last value on the calculator stack into the accumulator
; deleting the last value.

					;;;$2314
STK_TO_A:	CALL	FP_TO_A		; routine FP_TO_A compresses last value into
					; accumulator. e.g. PI would become 3. 
					; zero flag set if positive.
		JP	C,REPORT_BC	; jump forward to REPORT_BC if >= 255.5.

		LD	C,$01		; prepare a positive sign byte.
		RET	Z		; return if FP_TO_BC indicated positive.

		LD	C,$FF		; prepare negative sign byte and
		RET			; return.


;----------------------
; Handle CIRCLE command
;----------------------
;
; syntax has been partly checked using the class for draw command.

					;;;$2320
CIRCLE:		RST	18H		; GET_CHAR
		CP	$2C		; is it required comma ?
		JP	NZ,REPORT_C	; jump to REPORT_C if not

		RST	20H		; NEXT_CHAR
		CALL	EXPT_1NUM	; routine EXPT_1NUM fetches radius
		CALL	CHECK_END	; routine CHECK_END will return here if
					; nothing follows command.
		RST	28H		;; FP_CALC
		DEFB	$2A		;;ABS		; make radius positive
		DEFB	$3D		;;RE_STACK	; in full floating point form
		DEFB	$38		;;END_CALC

		LD	A,(HL)		; fetch first floating point byte
		CP	$81		; compare to one
		JR	NC,C_R_GRE_1	; forward to C_R_GRE_1 if circle radius
					; is greater than one.
		RST	28H		;; FP_CALC
		DEFB	$02		;;DELETE	; delete the radius from stack.
		DEFB	$38		;;END_CALC

		JR	PLOT		; to PLOT to just plot x,y.


					;;;$233B
C_R_GRE_1:	RST	28H		;; FP_CALC	; x, y, r
		DEFB	$A3		;;STK_PI_2	; x, y, r, pi/2.
		DEFB	$38		;;END_CALC

		LD	(HL),$83			; x, y, r, 2*PI
		RST	28H		;; FP_CALC
		DEFB	$C5		;;st-mem-5	; store 2*PI in mem-5
		DEFB	$02		;;DELETE	; x, y, z.
		DEFB	$38		;;END_CALC

		CALL	CD_PRMS1	; routine CD_PRMS1
		PUSH	BC
		RST	28H		;; FP_CALC
		DEFB	$31		;;DUPLICATE
		DEFB	$E1		;;get-mem-1
		DEFB	$04		;;MULTIPLY
		DEFB	$38		;;END_CALC

		LD	A,(HL)
		CP	$80
		JR	NC,C_ARC_GE1	; to C_ARC_GE1

		RST	28H		;; FP_CALC
		DEFB	$02		;;DELETE
		DEFB	$02		;;DELETE
		DEFB	$38		;;END_CALC

		POP	BC
		JP	PLOT		; to PLOT


					;;;$235A
C_ARC_GE1:	RST	28H		;; FP_CALC
		DEFB	$C2		;;st-mem-2
		DEFB	$01		;;EXCHANGE
		DEFB	$C0		;;st-mem-0
		DEFB	$02		;;DELETE
		DEFB	$03		;;SUBTRACT
		DEFB	$01		;;EXCHANGE
		DEFB	$E0		;;get-mem-0
		DEFB	$0F		;;ADDITION
		DEFB	$C0		;;st-mem-0
		DEFB	$01		;;EXCHANGE
		DEFB	$31		;;DUPLICATE
		DEFB	$E0		;;get-mem-0
		DEFB	$01		;;EXCHANGE
		DEFB	$31		;;DUPLICATE
		DEFB	$E0		;;get-mem-0
		DEFB	$A0		;;STK_ZERO
		DEFB	$C1		;;st-mem-1
		DEFB	$02		;;DELETE
		DEFB	$38		;;END_CALC

		INC	(IY+$62)	; MEM-2-1st
		CALL	FIND_INT1	; routine FIND_INT1
		LD	L,A
		PUSH	HL
		CALL	FIND_INT1	; routine FIND_INT1
		POP	HL
		LD	H,A
		LD	(COORDS),HL	; COORDS
		POP	BC
		JP	DRW_STEPS	; to DRW_STEPS


;--------------------
; Handle DRAW command
;--------------------

					;;;$2382
DRAW:		RST	18H		; GET_CHAR
		CP	$2C
		JR	Z,DR_3_PRMS	; to DR_3_PRMS

		CALL	CHECK_END	; routine CHECK_END
		JP	LINE_DRAW	; to LINE_DRAW


					;;;$238D
DR_3_PRMS:	RST	20H		; NEXT_CHAR
		CALL	EXPT_1NUM	; routine EXPT_1NUM
		CALL	CHECK_END	; routine CHECK_END

		RST	28H		;; FP_CALC
		DEFB	$C5		;;st-mem-5
		DEFB	$A2		;;STK_HALF
		DEFB	$04		;;MULTIPLY
		DEFB	$1F		;;SIN_
		DEFB	$31		;;DUPLICATE
		DEFB	$30		;;NOT
		DEFB	$30		;;NOT
		DEFB	$00		;;JUMP_TRUE

		DEFB	$06		;;to DR_SIN_NZ

		DEFB	$02		;;DELETE
		DEFB	$38		;;END_CALC

		JP	LINE_DRAW	; to LINE_DRAW

					;;;$23A3
DR_SIN_NZ:	DEFB	$C0		;;st-mem-0
		DEFB	$02		;;DELETE
		DEFB	$C1		;;st-mem-1
		DEFB	$02		;;DELETE
		DEFB	$31		;;DUPLICATE
		DEFB	$2A		;;ABS
		DEFB	$E1		;;get-mem-1
		DEFB	$01		;;EXCHANGE
		DEFB	$E1		;;get-mem-1
		DEFB	$2A		;;ABS
		DEFB	$0F		;;ADDITION
		DEFB	$E0		;;get-mem-0
		DEFB	$05		;;DIVISION
		DEFB	$2A		;;ABS
		DEFB	$E0		;;get-mem-0
		DEFB	$01		;;EXCHANGE
		DEFB	$3D		;;RE_STACK
		DEFB	$38		;;END_CALC

		LD	A,(HL)
		CP	$81
		JR	NC,DR_PRMS	; to DR_PRMS

		RST	28H		;; FP_CALC
		DEFB	$02		;;DELETE
		DEFB	$02		;;DELETE
		DEFB	$38		;;END_CALC

		JP	LINE_DRAW	; to LINE_DRAW

					;;;$23C1
DR_PRMS:	CALL	CD_PRMS1	; routine CD_PRMS1
		PUSH	BC		;
		RST	28H		;; FP_CALC
		DEFB	$02		;;DELETE
		DEFB	$E1		;;get-mem-1
		DEFB	$01		;;EXCHANGE
		DEFB	$05		;;DIVISION
		DEFB	$C1		;;st-mem-1
		DEFB	$02		;;DELETE
		DEFB	$01		;;EXCHANGE
		DEFB	$31		;;DUPLICATE
		DEFB	$E1		;;get-mem-1
		DEFB	$04		;;MULTIPLY
		DEFB	$C2		;;st-mem-2
		DEFB	$02		;;DELETE
		DEFB	$01		;;EXCHANGE
		DEFB	$31		;;DUPLICATE
		DEFB	$E1		;;get-mem-1
		DEFB	$04		;;MULTIPLY
		DEFB	$E2		;;get-mem-2
		DEFB	$E5		;;get-mem-5
		DEFB	$E0		;;get-mem-0
		DEFB	$03		;;SUBTRACT
		DEFB	$A2		;;STK_HALF
		DEFB	$04		;;MULTIPLY
		DEFB	$31		;;DUPLICATE
		DEFB	$1F		;;SIN_
		DEFB	$C5		;;st-mem-5
		DEFB	$02		;;DELETE
		DEFB	$20		;;COS_
		DEFB	$C0		;;st-mem-0
		DEFB	$02		;;DELETE
		DEFB	$C2		;;st-mem-2
		DEFB	$02		;;DELETE
		DEFB	$C1		;;st-mem-1
		DEFB	$E5		;;get-mem-5
		DEFB	$04		;;MULTIPLY
		DEFB	$E0		;;get-mem-0
		DEFB	$E2		;;get-mem-2
		DEFB	$04		;;MULTIPLY
		DEFB	$0F		;;ADDITION
		DEFB	$E1		;;get-mem-1
		DEFB	$01		;;EXCHANGE
		DEFB	$C1		;;st-mem-1
		DEFB	$02		;;DELETE
		DEFB	$E0		;;get-mem-0
		DEFB	$04		;;MULTIPLY
		DEFB	$E2		;;get-mem-2
		DEFB	$E5		;;get-mem-5
		DEFB	$04		;;MULTIPLY
		DEFB	$03		;;SUBTRACT
		DEFB	$C2		;;st-mem-2
		DEFB	$2A		;;ABS
		DEFB	$E1		;;get-mem-1
		DEFB	$2A		;;ABS
		DEFB	$0F		;;ADDITION
		DEFB	$02		;;DELETE
		DEFB	$38		;;END_CALC

		LD	A,(DE)
		CP	$81
		POP	BC
		JP	C,LINE_DRAW	; to LINE_DRAW

		PUSH	BC
		RST	28H		;; FP_CALC
		DEFB	$01		;;EXCHANGE
		DEFB	$38		;;END_CALC

		LD	A,(COORDS)	; COORDS-x
		CALL	STACK_A		; routine STACK_A
		RST	28H		;; FP_CALC
		DEFB	$C0		;;st-mem-0
		DEFB	$0F		;;ADDITION
		DEFB	$01		;;EXCHANGE
		DEFB	$38		;;END_CALC

		LD	A,(COORDS_Y)	; COORDS_Y
		CALL	STACK_A		; routine STACK_A
		RST	28H		;; FP_CALC
		DEFB	$C5		;;st-mem-5
		DEFB	$0F		;;ADDITION
		DEFB	$E0		;;get-mem-0
		DEFB	$E5		;;get-mem-5
		DEFB	$38		;;END_CALC

		POP	BC

					;;;$2420
DRW_STEPS:	DEC	B
		JR	Z,ARC_END	; to ARC_END

		JR	ARC_START	; to ARC_START

					;;;$2425
ARC_LOOP:	RST	28H		;; FP_CALC
		DEFB	$E1		;;get-mem-1
		DEFB	$31		;;DUPLICATE
		DEFB	$E3		;;get-mem-3
		DEFB	$04		;;MULTIPLY
		DEFB	$E2		;;get-mem-2
		DEFB	$E4		;;get-mem-4
		DEFB	$04		;;MULTIPLY
		DEFB	$03		;;SUBTRACT
		DEFB	$C1		;;st-mem-1
		DEFB	$02		;;DELETE
		DEFB	$E4		;;get-mem-4
		DEFB	$04		;;MULTIPLY
		DEFB	$E2		;;get-mem-2
		DEFB	$E3		;;get-mem-3
		DEFB	$04		;;MULTIPLY
		DEFB	$0F		;;ADDITION
		DEFB	$C2		;;st-mem-2
		DEFB	$02		;;DELETE
		DEFB	$38		;;END_CALC

					;;;$2439
ARC_START:	PUSH	BC
		RST	28H		;; FP_CALC
		DEFB	$C0		;;st-mem-0
		DEFB	$02		;;DELETE
		DEFB	$E1		;;get-mem-1
		DEFB	$0F		;;ADDITION
		DEFB	$31		;;DUPLICATE
		DEFB	$38		;;END_CALC

		LD	A,(COORDS)	; COORDS-x
		CALL	STACK_A		; routine STACK_A
		RST	28H		;; FP_CALC
		DEFB	$03		;;SUBTRACT
		DEFB	$E0		;;get-mem-0
		DEFB	$E2		;;get-mem-2
		DEFB	$0F		;;ADDITION
		DEFB	$C0		;;st-mem-0
		DEFB	$01		;;EXCHANGE
		DEFB	$E0		;;get-mem-0
		DEFB	$38		;;END_CALC

		LD	A,(COORDS_Y)	; COORDS_Y
		CALL	STACK_A		; routine STACK_A
		RST	28H		;; FP_CALC
		DEFB	$03		;;SUBTRACT
		DEFB	$38		;;END_CALC

		CALL	DRAW_LINE	; routine DRAW_LINE
		POP	BC
		DJNZ	ARC_LOOP	; to ARC_LOOP

					;;;$245F
ARC_END:	RST	28H		;; FP_CALC
		DEFB	$02		;;DELETE
		DEFB	$02		;;DELETE
		DEFB	$01		;;EXCHANGE
		DEFB	$38		;;END_CALC

		LD	A,(COORDS)	; COORDS-x
		CALL	STACK_A		; routine STACK_A
		RST	28H		;; FP_CALC
		DEFB	$03		;;SUBTRACT
		DEFB	$01		;;EXCHANGE
		DEFB	$38		;;END_CALC

		LD	A,(COORDS_Y)	; COORDS_Y
		CALL	STACK_A		; routine STACK_A
		RST	28H		;; FP_CALC
		DEFB	$03		;;SUBTRACT
		DEFB	$38		;;END_CALC

					;;;$2477
LINE_DRAW:	CALL	DRAW_LINE	; routine DRAW_LINE
		JP	TEMPS		; to TEMPS

;-------------------
; Initial parameters
;-------------------

					;;;$247D
CD_PRMS1:	RST	28H		;; FP_CALC
		DEFB	$31		;;DUPLICATE
		DEFB	$28		;;SQR
		DEFB	$34		;;STK_DATA
		DEFB	$32		;;Exponent: $82, Bytes: 1
		DEFB	$00		;;(+00,+00,+00)
		DEFB	$01		;;EXCHANGE
		DEFB	$05		;;DIVISION
		DEFB	$E5		;;get-mem-5
		DEFB	$01		;;EXCHANGE
		DEFB	$05		;;DIVISION
		DEFB	$2A		;;ABS
		DEFB	$38		;;END_CALC

		CALL	FP_TO_A		; routine FP_TO_A
		JR	C,USE_252	; to USE_252

		AND	$FC
		ADD	A,$04
		JR	NC,DRAW_SAVE	; to DRAW_SAVE

					;;;$2495
USE_252:	LD	A,$FC

					;;;$2497
DRAW_SAVE:	PUSH	AF
		CALL	STACK_A		; routine STACK_A
		RST	28H		;; FP_CALC
		DEFB	$E5		;;get-mem-5
		DEFB	$01		;;EXCHANGE
		DEFB	$05		;;DIVISION
		DEFB	$31		;;DUPLICATE
		DEFB	$1F		;;SIN_
		DEFB	$C4		;;st-mem-4
		DEFB	$02		;;DELETE
		DEFB	$31		;;DUPLICATE
		DEFB	$A2		;;STK_HALF
		DEFB	$04		;;MULTIPLY
		DEFB	$1F		;;SIN_
		DEFB	$C1		;;st-mem-1
		DEFB	$01		;;EXCHANGE
		DEFB	$C0		;;st-mem-0
		DEFB	$02		;;DELETE
		DEFB	$31		;;DUPLICATE
		DEFB	$04		;;MULTIPLY
		DEFB	$31		;;DUPLICATE
		DEFB	$0F		;;ADDITION
		DEFB	$A1		;;STK_ONE
		DEFB	$03		;;SUBTRACT
		DEFB	$1B		;;NEGATE
		DEFB	$C3		;;st-mem-3
		DEFB	$02		;;DELETE
		DEFB	$38		;;END_CALC

		POP	BC
		RET

;-------------
; Line drawing
;-------------

					;;;$24B7
DRAW_LINE:	CALL	STK_TO_BC	; routine STK_TO_BC
		LD	A,C
		CP	B
		JR	NC,DL_X_GE_Y	; to DL_X_GE_Y

		LD	L,C
		PUSH	DE
		XOR	A
		LD	E,A
		JR	DL_LARGER	; to DL_LARGER

					;;;$24C4
DL_X_GE_Y:	OR	C
		RET	Z

		LD	L,B
		LD	B,C
		PUSH	DE
		LD	D,$00

					;;;$24CB
DL_LARGER:	LD	H,B
		LD	A,B
		RRA

					;;;$24CE
D_L_LOOP:	ADD	A,L		;
		JR	C,D_L_DIAG	; to D_L_DIAG

		CP	H		;
		JR	C,D_L_HR_VT	; to D_L_HR_VT

					;;;$24D4
D_L_DIAG:	SUB	H
		LD	C,A
		EXX
		POP	BC
		PUSH	BC
		JR	D_L_STEP	; to D_L_STEP

					;;;$24DB
D_L_HR_VT:	LD	C,A
		PUSH	DE
		EXX
		POP	BC

					;;;$24DF
D_L_STEP:	LD	HL,(COORDS)
		LD	A,B
		ADD	A,H
		LD	B,A
		LD	A,C
		INC	A
		ADD	A,L
		JR	C,D_L_RANGE	; to D_L_RANGE

		JR	Z,REPORT_BC	; to REPORT_BC

					;;;$24EC
D_L_PLOT:	DEC	A
		LD	C,A
		CALL	PLOT_SUB	; routine PLOT_SUB
		EXX
		LD	A,C
		DJNZ	D_L_LOOP	; to D_L_LOOP
		POP	DE
		RET

					;;;$24F7
D_L_RANGE:	JR	Z,D_L_PLOT	; to D_L_PLOT

					;;;$24F9
REPORT_BC:	RST	08H		; ERROR_1
		DEFB	$0A		; Error Report: Integer out of range

;***********************************
;** Part 8. EXPRESSION EVALUATION **
;***********************************
;
; It is a this stage of the ROM that the Spectrum ceases altogether to be
; just a colourful novelty. One remarkable feature is that in all previous
; commands when the Spectrum is expecting a number or a string then an
; expression of the same type can be substituted ad infinitum.
; This is the routine that evaluates that expression.
; This is what causes 2 + 2 to give the answer 4.
; That is quite easy to understand. However you don't have to make it much
; more complex to start a remarkable juggling act.
; e.g. PRINT 2 * (VAL "2+2" + TAN 3)
; In fact, provided there is enough free RAM, the Spectrum can evaluate
; an expression of unlimited complexity.
; Apart from a couple of minor glitches, which you can now correct, the
; system is remarkably robust.

;----------------------------------
; Scan expression or sub-expression
;----------------------------------

					;;;$24FB
SCANNING:	RST	18H		; GET_CHAR
		LD	B,$00		; priority marker zero is pushed on stack
					; to signify end of expression when it is  popped off again.
		PUSH	BC		; put in on stack.
					; and proceed to consider the first character
					; of the expression.

					;;;$24FF
S_LOOP_1:	LD	C,A		; store the character while a look up is done.
		LD	HL,SCAN_FUNC	; Address: SCAN_FUNC
		CALL	INDEXER		; routine INDEXER is called to see if it is
					; part of a limited range '+', '(', 'ATTR' etc.
		LD	A,C		; fetch the character back
		JP	NC,S_ALPHNUM	; jump forward to S_ALPHNUM if not in primary
					; operators and functions to consider in the
					; first instance a digit or a variable and
					; then anything else.			>>>
		LD	B,$00		; but here if it was found in table so
		LD	C,(HL)		; fetch offset from table and make B zero.
		ADD	HL,BC		; add the offset to position found
		JP	(HL)		; and jump to the routine e.g. S_BIN
					; making an indirect exit from there.

;--------------------------------------------------------------------------
; The four service subroutines for routines in the scannings function table
;--------------------------------------------------------------------------
; PRINT """Hooray!"" he cried."

					;;;$250F
S_QUOTE_S:	CALL	CH_ADD_1	; routine CH_ADD_1 points to next character
					; and fetches that character.
		INC	BC		; increase length counter.
		CP	$0D		; is it carriage return ?
					; inside a quote.
		JP	Z,REPORT_C	; jump back to REPORT_C if so.
					; 'Nonsense in basic'.
		CP	$22		; is it a quote '"' ?
		JR	NZ,S_QUOTE_S	; back to S_QUOTE_S if not for more.

		CALL	CH_ADD_1	; routine CH_ADD_1
		CP	$22		; compare with possible adjacent quote
		RET			; return. with zero set if two together.

					; This subroutine is used to get two coordinate expressions for the three
					; functions SCREEN$, ATTR and POINT that have two fixed parameters and
					; therefore require surrounding braces.

					;;;$2522
S_2_COORD:	RST	20H		; NEXT_CHAR
		CP	$28		; is it the opening '(' ?
		JR	NZ,S_RPORT_C	; forward to S_RPORT_C if not
					; 'Nonsense in Basic'.
		CALL	NEXT_2NUM	; routine NEXT_2NUM gets two comma-separated
					; numeric expressions. Note. this could cause
					; many more recursive calls to SCANNING but
					; the parent function will be evaluated fully
					; before rejoining the main juggling act.
		RST	18H		; GET_CHAR
		CP	$29		; is it the closing ')' ?

					;; S_RPORT_C
S_RPORT_C:	JP	NZ,REPORT_C	; jump back to REPORT_C if not.
					; 'Nonsense in Basic'.

;-------------
; Check syntax
;-------------
; This routine is called on a number of occasions to check if syntax is being
; checked or if the program is being run. To test the flag inline would use
; four bytes of code, but a call instruction only uses 3 bytes of code.

					;;;$2530
SYNTAX_Z:	BIT	7,(IY+$01)	; test FLAGS  - checking syntax only ?
		RET			; return.

;-----------------
; Scanning SCREEN$
;-----------------
; This function returns the code of a bit-mapped character at screen
; position at line C, column B. It is unable to detect the mosaic characters
; which are not bit-mapped but detects the ascii 32 - 127 range.
; The bit-mapped UDGs are ignored which is curious as it requires only a
; few extra bytes of code. As usual, anything to do with CHARS is weird.
; If no match is found a null string is returned.
; No actual check on ranges is performed - that's up to the Basic programmer.
; No real harm can come from SCREEN$(255,255) although the Basic manual
; says that invalid values will be trapped.
; Interestingly, in the Pitman pocket guide, 1984, Vickers says that the
; range checking will be performed. 

					;;;$2535
S_SCRN_S:	CALL	STK_TO_BC	; routine STK_TO_BC.
		LD	HL,(CHARS)	; fetch address of CHARS.
		LD	DE,$0100	; fetch offset to CHR$ 32
		ADD	HL,DE		; and find start of bitmaps.
					; Note. not inc h. ??
		LD	A,C		; transfer line to A.
		RRCA			; multiply
		RRCA			; by
		RRCA			; thirty-two.
		AND	$E0		; and with 11100000
		XOR	B		; combine with column $00 - $1F
		LD	E,A		; to give the low byte of top line
		LD	A,C		; column to A range 00000000 to 00011111
		AND	$18		; and with 00011000
		XOR	$40		; xor with 01000000 (high byte screen start)
		LD	D,A		; register DE now holds start address of cell.
		LD	B,$60		; there are 96 characters in ascii set.

					;;;$254F
S_SCRN_LP:	PUSH	BC		; save count
		PUSH	DE		; save screen start address
		PUSH	HL		; save bitmap start
		LD	A,(DE)		; first byte of screen to A
		XOR	(HL)		; xor with corresponding character byte
		JR	Z,S_SC_MTCH	; forward to S_SC_MTCH if they match
					; if inverse result would be $FF
					; if any other then mismatch
		INC	A		; set to $00 if inverse
		JR	NZ,S_SCR_NXT	; forward to S_SCR_NXT if a mismatch

		DEC	A		; restore $FF

					; a match has been found so seven more to test.

					;;;$255A
S_SC_MTCH:	LD	C,A		; load C with inverse mask $00 or $FF
		LD	B,$07		; count seven more bytes

					;;;$255D
S_SC_ROWS:	INC	D		; increment screen address.
		INC	HL		; increment bitmap address.
		LD	A,(DE)		; byte to A
		XOR	(HL)		; will give $00 or $FF (inverse)
		XOR	C		; xor with inverse mask
		JR	NZ,S_SCR_NXT	; forward to S_SCR_NXT if no match.

		DJNZ	S_SC_ROWS	; back to S_SC_ROWS until all eight matched.

					; continue if a match of all eight bytes was found

		POP	BC		; discard the
		POP	BC		; saved
		POP	BC		; pointers
		LD	A,$80		; the endpoint of character set
		SUB	B		; subtract the counter
					; to give the code 32-127
		LD	BC,$0001	; make one space in workspace.
		RST	30H		; BC_SPACES creates the space sliding
					; the calculator stack upwards.
		LD	(DE),A		; start is addressed by DE, so insert code
		JR	S_SCR_STO	; forward to S_SCR_STO

					; the jump was here if no match and more bitmaps to test.

					;;;$2573
S_SCR_NXT:	POP	HL		; restore the last bitmap start
		LD	DE,$0008	; and prepare to add 8.
		ADD	HL,DE		; now addresses next character bitmap.
		POP	DE		; restore screen address
		POP	BC		; and character counter in B
		DJNZ	S_SCRN_LP	; back to S_SCRN_LP if more characters.
		LD	C,B		; B is now zero, so BC now zero.

					;;;$257D
S_SCR_STO:	JP	STK_STO_D	; to STK_STO_D to store the string in
					; workspace or a string with zero length.
					; (value of DE doesn't matter in last case)

					; Note. this exit seems correct but the general-purpose routine S_STRING
					; that calls this one will also stack any of it's string results so this
					; leads to a double storing of the result in this case.
					; The instruction at S_SCR_STO should just be a RET.
					; credit Stephen Kelly and others, 1982.

;--------------
; Scanning ATTR
;--------------
; This function subroutine returns the attributes of a screen location -
; a numeric result.
; Again it's up to the Basic programmer to supply valid values of line/column.

					;;;$2580
S_ATTR_S:	CALL	STK_TO_BC	; routine STK_TO_BC fetches line to C, and column to B.
		LD	A,C		; line to A $00 - $17	(max 00010111)
		RRCA			; rotate
		RRCA			; bits
		RRCA			; left.
		LD	C,A		; store in C as an intermediate value.
		AND	$E0		; pick up bits 11100000 ( was 00011100 )
		XOR	B		; combine with column $00 - $1F
		LD	L,A		; low byte now correct.
		LD	A,C		; bring back intermediate result from C
		AND	$03		; mask to give correct third of
					; screen $00 - $02
		XOR	$58		; combine with base address.
		LD	H,A		; high byte correct.
		LD	A,(HL)		; pick up the colour attribute.
		JP	STACK_A		; forward to STACK_A to store result
					; and make an indirect exit.

;------------------------
; Scanning function table
;------------------------
; This table is used by INDEXER routine to find the offsets to
; four operators and eight functions. e.g. $A8 is the token 'FN'.
; This table is used in the first instance for the first character of an
; expression or by a recursive call to SCANNING for the first character of
; any sub-expression. It eliminates functions that have no argument or
; functions that can have more than one argument and therefore require
; braces. By eliminating and dealing with these now it can later take a
; simplistic approach to all other functions and assume that they have
; one argument.
; Similarly by eliminating BIN and '.' now it is later able to assume that
; all numbers begin with a digit and that the presence of a number or
; variable can be detected by a call to ALPHANUM.
; By default all expressions are positive and the spurious '+' is eliminated
; now as in print +2. This should not be confused with the operator '+'.
; Note. this does allow a degree of nonsense to be accepted as in
; PRINT +"3 is the greatest.".
; An acquired programming skill is the ability to include brackets where
; they are not necessary.
; A bracket at the start of a sub-expression may be spurious or necessary
; to denote that the contained expression is to be evaluated as an entity.
; In either case this is dealt with by recursive calls to SCANNING.
; An expression that begins with a quote requires special treatment.

						;;;$2596
SCAN_FUNC:	DEFB	$22, S_QUOTE-$-1	; $1C offset to S_QUOTE
		DEFB	'(', S_BRACKET-$-1	; $4F offset to S_BRACKET
		DEFB	'.', S_DECIMAL-$-1	; $F2 offset to S_DECIMAL
		DEFB	'+', S_U_PLUS-$-1	; $12 offset to S_U_PLUS
		DEFB	$A8, S_FN-$-1		; $56 offset to S_FN
		DEFB	$A5, S_RND-$-1		; $57 offset to S_RND
		DEFB	$A7, S_PI-$-1		; $84 offset to S_PI
		DEFB	$A6, S_INKEY-$-1	; $8F offset to S_INKEY
		DEFB	$C4, S_BIN-$-1		; $E6 offset to S_BIN
		DEFB	$AA, S_SCREEN-$-1	; $BF offset to S_SCREEN
		DEFB	$AB, S_ATTR-$-1		; $C7 offset to S_ATTR
		DEFB	$A9, S_POINT-$-1	; $CE offset to S_POINT

		DEFB	$00			; zero end marker

;---------------------------
; Scanning function routines
;---------------------------
; These are the 11 subroutines accessed by the above table.
; S_BIN and S_DECIMAL are the same
; The 1-byte offset limits their location to within 255 bytes of their
; entry in the table.

					; ->
					;;;$25AF
S_U_PLUS:	RST	20H		; NEXT_CHAR just ignore
		JP	S_LOOP_1	; to S_LOOP_1

					; ->
					;;;$25B3
S_QUOTE:	RST	18H		; GET_CHAR
		INC	HL		; address next character (first in quotes)
		PUSH	HL		; save start of quoted text.
		LD	BC,$0000	; initialize length of string to zero.
		CALL	S_QUOTE_S	; routine S_QUOTE_S
		JR	NZ,S_Q_PRMS	; forward to S_Q_PRMS if

					;;;$25BE
S_Q_AGAIN:	CALL	S_QUOTE_S	; routine S_QUOTE_S copies string until a
					; quote is encountered
		JR	Z,S_Q_AGAIN	; back to S_Q_AGAIN if two quotes WERE
					; together.

					; but if just an isolated quote then that terminates the string.

		CALL	SYNTAX_Z	; routine SYNTAX_Z
		JR	Z,S_Q_PRMS	; forward to S_Q_PRMS if checking syntax.


		RST	30H		; BC_SPACES creates the space for true
					; copy of string in workspace.
		POP	HL		; re-fetch start of quoted text.
		PUSH	DE		; save start in workspace.

					;;;$25CB
S_Q_COPY:	LD	A,(HL)		; fetch a character from source.
		INC	HL		; advance source address.
		LD	(DE),A		; place in destination.
		INC	DE		; advance destination address.
		CP	$22		; was it a '"' just copied ?
		JR	NZ,S_Q_COPY	; back to S_Q_COPY to copy more if not

		LD	A,(HL)		; fetch adjacent character from source.
		INC	HL		; advance source address.
		CP	$22		; is this '"' ? - i.e. two quotes together ?
		JR	Z,S_Q_COPY	; to S_Q_COPY if so including just one of the
					; pair of quotes.

					; proceed when terminating quote encountered.

					;;;$25D9
S_Q_PRMS:	DEC	BC		; decrease count by 1.
		POP	DE		; restore start of string in workspace.

					;;;$25DB
S_STRING:	LD	HL,FLAGS	; Address FLAGS system variable.
		RES	6,(HL)		; signal string result.
		BIT	7,(HL)		; is syntax being checked.
		CALL	NZ,STK_STO_D	; routine STK_STO_D is called in runtime.
		JP	S_CONT_2	; jump forward to S_CONT_2		===>

					; ->
					;;;$25E8
S_BRACKET:	RST	20H		; NEXT_CHAR
		CALL	SCANNING	; routine SCANNING is called recursively.
		CP	$29		; is it the closing ')' ?
		JP	NZ,REPORT_C	; jump back to REPORT_C if not
					; 'Nonsense in basic'

		RST	20H		; NEXT_CHAR
		JP	S_CONT_2	; jump forward to S_CONT_2		===>
					; ->
					;;$25F5
S_FN:		JP	S_FN_SBRN	; jump forward to S_FN_SBRN.

					; ->
					;;;$25F8
S_RND:		CALL	SYNTAX_Z	; routine SYNTAX_Z
		JR	Z,S_RND_END	; forward to S_RND_END if checking syntax.

		LD	BC,(SEED)	; fetch system variable SEED
		CALL	STACK_BC	; routine STACK_BC places on calculator stack
		RST	28H		;; FP_CALC		;s.
		DEFB	$A1		;;STK_ONE		;s,1.
		DEFB	$0F		;;ADDITION		;s+1.
		DEFB	$34		;;STK_DATA		;
		DEFB	$37		;;Exponent: $87,
					;;Bytes: 1
		DEFB	$16		;;(+00,+00,+00)		;s+1,75.
		DEFB	$04		;;MULTIPLY		;(s+1)*75 = v
		DEFB	$34		;;STK_DATA		;v.
		DEFB	$80		;;Bytes: 3
		DEFB	$41		;;Exponent $91
		DEFB	$00,$00,$80	;;(+00)			;v,65537.
		DEFB	$32		;;N_MOD_M		;remainder,result.
		DEFB	$02		;;DELETE		;remainder.
		DEFB	$A1		;;STK_ONE		;remainder,1.
		DEFB	$03		;;SUBTRACT		;remainder - 1. = rnd
		DEFB	$31		;;DUPLICATE		;rnd,rnd.
		DEFB	$38		;;END_CALC

		CALL	FP_TO_BC	; routine FP_TO_BC
		LD	(SEED),BC	; store in SEED for next starting point.
		LD	A,(HL)		; fetch exponent
		AND	A		; is it zero ?
		JR	Z,S_RND_END	; forward if so to S_RND_END

		SUB	$10		; reduce exponent by 2^16
		LD	(HL),A		; place back

					;;;$2625
S_RND_END:	JR	S_PI_END	; forward to S_PI_END

					; the number PI 3.14159...

					; ->
					;;;$2627
S_PI:		CALL	SYNTAX_Z	; routine SYNTAX_Z
		JR	Z,S_PI_END	; to S_PI_END if checking syntax.

		RST	28H		;; FP_CALC
		DEFB	$A3		;;STK_PI_2				pi/2.
		DEFB	$38		;;END_CALC

		INC	(HL)		; increment the exponent leaving pi
					; on the calculator stack.

					;;;$2630
S_PI_END:	RST	20H		; NEXT_CHAR
		JP	S_NUMERIC	; jump forward to S_NUMERIC

					; ->
					;;;$2634
S_INKEY:	LD	BC,$105A	; priority $10, operation code $1A ('READ_IN')
					; +$40 for string result, numeric operand.
					; set this up now in case we need to use the calculator.
		RST	20H		; NEXT_CHAR
		CP	$23		; '#' ?
		JP	Z,S_PUSH_PO	; to S_PUSH_PO if so to use the calculator
					; single operation
					; to read from network/RS232 etc. .

					; else read a key from the keyboard.

		LD	HL,FLAGS	; fetch FLAGS
		RES	6,(HL)		; signal string result.
		BIT	7,(HL)		; checking syntax ?
		JR	Z,S_INK_EN	; forward to S_INK_EN if so

		CALL	KEY_SCAN	; routine KEY_SCAN key in E, shift in D.
		LD	C,$00		; the length of an empty string
		JR	NZ,S_IK_STK	; to S_IK_STK to store empty string if no key returned.

		CALL	K_TEST		; routine K_TEST get main code in A
		JR	NC,S_IK_STK	; to S_IK_STK to stack null string if invalid

		DEC	D		; D is expected to be FLAGS so set bit 3 $FF
					; 'L' Mode so no keywords.
		LD	E,A		; main key to A
					; C is MODE 0 'KLC' from above still.
		CALL	K_DECODE	; routine K_DECODE
		PUSH	AF		; save the code
		LD	BC,$0001	; make room for one character
		RST	30H		; BC_SPACES
		POP	AF		; bring the code back
		LD	(DE),A		; put the key in workspace
		LD	C,$01		; set C length to one

					;;;$2660
S_IK_STK:	LD	B,$00		; set high byte of length to zero
		CALL	STK_STO_D	; routine STK_STO_D

					;;;$2665
S_INK_EN:	JP	S_CONT_2	; to S_CONT_2		===>

					; ->
					;;;$2668
S_SCREEN:	CALL	S_2_COORD	; routine S_2_COORD
		CALL	NZ,S_SCRN_S	; routine S_SCRN_S
		RST	20H		; NEXT_CHAR
		JP	S_STRING	; forward to S_STRING to stack result

					; ->
					;;;$2672
S_ATTR:		CALL	S_2_COORD	; routine S_2_COORD
		CALL	NZ,S_ATTR_S	; routine S_ATTR_S
		RST	20H		; NEXT_CHAR
		JR	S_NUMERIC	; forward to S_NUMERIC

					; ->
					;;;$267B
S_POINT:	CALL	S_2_COORD	; routine S_2_COORD
		CALL	NZ,POINT_SUB	; routine POINT_SUB
		RST	20H		; NEXT_CHAR
		JR	S_NUMERIC	; forward to S_NUMERIC

					; ==> The branch was here if not in table.

					;;;$2684
S_ALPHNUM:	CALL	ALPHANUM	; routine ALPHANUM checks if variable or
					; a digit.
		JR	NC,S_NEGATE	; forward to S_NEGATE if not to consider
					; a '-' character then functions.
		CP	$41		; compare 'A'
		JR	NC,S_LETTER	; forward to S_LETTER if alpha	->
					; else must have been numeric so continue
					; into that routine.

					; This important routine is called during runtime and from LINE_SCAN
					; when a BASIC line is checked for syntax. It is this routine that
					; inserts, during syntax checking, the invisible floating point numbers
					; after the numeric expression. During runtime it just picks these
					; numbers up. It also handles BIN format numbers.

					; ->
					;;;$268D
S_DECIMAL:
S_BIN:		CALL	SYNTAX_Z	; routine SYNTAX_Z
		JR	NZ,S_STK_DEC	; to S_STK_DEC in runtime

					; this route is taken when checking syntax.

		CALL	DEC_TO_FP	; routine DEC_TO_FP to evaluate number
		RST	18H		; GET_CHAR to fetch HL
		LD	BC,$0006	; six locations required
		CALL	MAKE_ROOM	; routine MAKE_ROOM
		INC	HL		; to first new location
		LD	(HL),$0E	; insert number marker
		INC	HL		; address next
		EX	DE,HL		; make DE destination.
		LD	HL,(STKEND)	; STKEND points to end of stack.
		LD	C,$05		; result is five locations lower
		AND	A		; prepare for true subtraction
		SBC	HL,BC		; point to start of value.
		LD	(STKEND),HL	; update STKEND as we are taking number.
		LDIR			; Copy five bytes to program location
		EX	DE,HL		; transfer pointer to HL
		DEC	HL		; adjust
		CALL	TEMP_PTR1	; routine TEMP_PTR1 sets CH-ADD
		JR	S_NUMERIC	; to S_NUMERIC to record nature of result

					; branch here in runtime.

					;;;$26B5
S_STK_DEC:	RST	18H		; GET_CHAR positions HL at digit.

					;;;$26B6
S_SD_SKIP:	INC	HL		; advance pointer
		LD	A,(HL)		; until we find
		CP	$0E		; chr 14d - the number indicator
		JR	NZ,S_SD_SKIP	; to S_SD_SKIP until a match it has to be here.

		INC	HL		; point to first byte of number
		CALL	STACK_NUM	; routine STACK_NUM stacks it
		LD	(CH_ADD),HL	; update system variable CH_ADD

					;;;$26C3
S_NUMERIC:	SET	6,(IY+$01)	; update FLAGS  - Signal numeric result
		JR	S_CONT_1	; forward to S_CONT_1			===>
					; actually S_CONT_2 is destination but why
					; waste a byte on a jump when a JR will do.
					; actually a JR S_CONT_2 can be used. Rats.

					; end of functions accessed from scanning functions table.

;---------------------------
; Scanning variable routines
;---------------------------

					;;;$26C9
S_LETTER:	CALL	LOOK_VARS	; routine LOOK_VARS
		JP	C,REPORT_2	; jump back to REPORT_2 if not found
					; 'Variable not found'
					; but a variable is always 'found' if syntax
					; is being checked.

		CALL	Z,STK_VAR	; routine STK_VAR considers a subscript/slice
		LD	A,(FLAGS)	; fetch FLAGS value
		CP	$C0		; compare 11000000
		JR	C,S_CONT_1	; step forward to S_CONT_1 if string	===>

		INC	HL		; advance pointer
		CALL	STACK_NUM	; routine STACK_NUM

					;;;$26DD
S_CONT_1:	JR	S_CONT_2	; forward to S_CONT_2			===>

					;-----------------------------------------
					; -> the scanning branch was here if not alphanumeric.
					; All the remaining functions will be evaluated by a single call to the
					; calculator. The correct priority for the operation has to be placed in
					; the B register and the operation code, calculator literal in the C register.
					; the operation code has bit 7 set if result is numeric and bit 6 is
					; set if operand is numeric. so
					; $C0 = numeric result, numeric operand.	e.g. 'SIN'
					; $80 = numeric result, string operand.		e.g. 'CODE'
					; $40 = string result, numeric operand.		e.g. 'STR$'
					; $00 = string result, string operand.		e.g. 'VAL$'

					;;;$26DF
S_NEGATE:	LD	BC,$09DB	; prepare priority 09, operation code $C0 + 
					; 'NEGATE' ($1B) - bits 6 and 7 set for numeric
					; result and numeric operand.

		CP	$2D		; is it '-' ?
		JR	Z,S_PUSH_PO	; forward if so to S_PUSH_PO

		LD	BC,$1018	; prepare priority $10, operation code 'VAL$' -
					; bits 6 and 7 reset for string result and  string operand.
		CP	$AE		; is it 'VAL$' ?
		JR	Z,S_PUSH_PO	; forward if so to S_PUSH_PO

		SUB	$AF		; subtract token 'CODE' value to reduce
					; functions 'CODE' to 'NOT' although the
					; upper range is, as yet, unchecked.
					; valid range would be $00 - $14.
		JP	C,REPORT_C	; jump back to REPORT_C with anything else
					; 'Nonsense in Basic'
		LD	BC,$04F0	; prepare priority $04, operation $C0 + 
					; 'not' ($30)
		CP	$14		; is it 'NOT'
		JR	Z,S_PUSH_PO	; forward to S_PUSH_PO if so

		JP	NC,REPORT_C	; to REPORT_C if higher
					; 'Nonsense in Basic'
		LD	B,$10		; priority $10 for all the rest
		ADD	A,$DC		; make range $DC - $EF
					; $C0 + 'CODE'($1C) thru 'CHR$' ($2F)
		LD	C,A		; transfer 'function' to C
		CP	$DF		; is it 'SIN' ?
		JR	NC,S_NO_TO	; forward to S_NO_TO  with 'SIN' through
					; 'CHR$' as operand is numeric.

					; all the rest 'COS' through 'CHR$' give a numeric result except 'STR$'
					; and 'CHR$'.

		RES	6,C		; signal string operand for 'CODE', 'VAL' and
					; 'LEN'.

					;;;$2707
S_NO_TO:	CP	$EE		; compare 'STR$'
		JR	C,S_PUSH_PO	; forward to S_PUSH_PO if lower as result
					; is numeric.
		RES	7,C		; reset bit 7 of op code for 'STR$', 'CHR$'
					; as result is string.

					; >> This is where they were all headed for.

					;;;$270D
S_PUSH_PO:	PUSH	BC		; push the priority and calculator operation code.
		RST	20H		; NEXT_CHAR
		JP	S_LOOP_1	; jump back to S_LOOP_1 to go round the loop
					; again with the next character.

					; ===>  there were many branches forward to here

					;;;$2712
S_CONT_2:	RST	18H		; GET_CHAR

					;;;$2713
S_CONT_3:	CP	$28		; is it '(' ?
		JR	NZ,S_OPERTR	; forward to S_OPERTR if not	>

		BIT	6,(IY+$01)	; test FLAGS - numeric or string result ?
		JR	NZ,S_LOOP	; forward to S_LOOP if numeric to evaluate  >

					; if a string preceded '(' then slice it.

		CALL	SLICING		; routine SLICING
		RST	20H		; NEXT_CHAR
		JR	S_CONT_3	; back to S_CONT_3


					; the branch was here when possibility of an operator '(' has been excluded.

					;;;$2723
S_OPERTR:	LD	B,$00		; prepare to add
		LD	C,A		; possible operator to C
		LD	HL,TBL_OF_OPS	; Address: TBL_OF_OPS
		CALL	INDEXER		; routine INDEXER
		JR	NC,S_LOOP	; forward to S_LOOP if not in table

					; but if found in table the priority has to be looked up.

		LD	C,(HL)		; operation code to C ( B is still zero )
		LD	HL,TBL_PRIORS-$C3 ; $26ED is base of table
		ADD	HL,BC		; index into table.
		LD	B,(HL)		; priority to B.

;-------------------
; Scanning main loop
;-------------------
; the juggling act

					;;;$2734
S_LOOP:		POP	DE		; fetch last priority and operation
		LD	A,D		; priority to A
		CP	B		; compare with this one
		JR	C,S_TIGHTER	; forward to S_TIGHTER to execute the
					; last operation before this one as it has
					; higher priority.

					; the last priority was greater or equal this one.

		AND	A		; if it is zero then so is this
		JP	Z,GET_CHAR	; jump to exit via GET_CHAR pointing at
					; next character.
					; This may be the character after the
					; expression or, if exiting a recursive call,
					; the next part of the expression to be
					; evaluated.
		PUSH	BC		; save current priority/operation
					; as it has lower precedence than the one
					; now in DE.

					; the 'USR' function is special in that it is overloaded to give two types
					; of result.

		LD	HL,FLAGS	; address FLAGS
		LD	A,E		; new operation to A register
		CP	$ED		; is it $C0 + 'USR_NO' ($2D)  ?
		JR	NZ,S_STK_LST	; forward to S_STK_LST if not

		BIT	6,(HL)		; string result expected ?
					; (from the lower priority operand we've
					; just pushed on stack )
		JR	NZ,S_STK_LST	; forward to S_STK_LST if numeric
					; as operand bits match.
		LD	E,$99		; reset bit 6 and substitute $19 'USR-$'
					; for string operand.

					;;;$274C
S_STK_LST:	PUSH	DE		; now stack this priority/operation
		CALL	SYNTAX_Z	; routine SYNTAX_Z
		JR	Z,S_SYNTEST	; forward to S_SYNTEST if checking syntax.

		LD	A,E		; fetch the operation code
		AND	$3F		; mask off the result/operand bits to leave a calculator literal.
		LD	B,A		; transfer to B register

					; now use the calculator to perform the single operation - operand is on
					; the calculator stack.
					; Note. although the calculator is performing a single operation most
					; functions e.g. TAN are written using other functions and literals and
					; these in turn are written using further strings of calculator literals so
					; another level of magical recursion joins the juggling act for a while
					; as the calculator too is calling itself.

		RST	28H		;; FP_CALC
		DEFB	$3B		;;FP_CALC_2

					;;;$2758
		DEFB	$38		;;END_CALC

		JR	S_RUNTEST	; forward to S_RUNTEST

					; the branch was here if checking syntax only. 

					;;;$275B
S_SYNTEST:	LD	A,E		; fetch the operation code to accumulator
		XOR	(IY+$01)	; compare with bits of FLAGS
		AND	$40		; bit 6 will be zero now if operand
					; matched expected result.

					;;;$2761
S_RPORT_C2:	JP	NZ,REPORT_C	; to REPORT_C if mismatch
					; 'Nonsense in Basic'
					; else continue to set flags for next

					; the branch is to here in runtime after a successful operation.

					;;;$2764
S_RUNTEST:	POP	DE		; fetch the last operation from stack
		LD	HL,FLAGS	; address FLAGS
		SET	6,(HL)		; set default to numeric result in FLAGS
		BIT	7,E		; test the operational result
		JR	NZ,S_LOOPEND	; forward to S_LOOPEND if numeric

		RES	6,(HL)		; reset bit 6 of FLAGS to show string result.

					;;;$2770
S_LOOPEND:	POP	BC		; fetch the previous priority/operation
		JR	S_LOOP		; back to S_LOOP to perform these

					; the branch was here when a stacked priority/operator had higher priority
					; than the current one.

					;;;$2773
S_TIGHTER:	PUSH	DE		; save high priority op on stack again
		LD	A,C		; fetch lower priority operation code
		BIT	6,(IY+$01)	; test FLAGS - Numeric or string result ?
		JR	NZ,S_NEXT	; forward to S_NEXT if numeric result

					; if this is lower priority yet has string then must be a comparison.
					; Since these can only be evaluated in context and were defaulted to
					; numeric in operator look up they must be changed to string equivalents.

		AND	$3F		; mask to give true calculator literal
		ADD	A,$08		; augment numeric literals to string
					; equivalents.
					; 'NO_AND_NO' => 'STR_AND_NO'
					; 'NO_L_EQL'  => 'STR_L_EQL'
					; 'NO_GR_EQL' => 'STR_GR_EQL'
					; 'NOS_NEQL'  => 'STRS_NEQL'
					; 'NO_GRTR'   => 'STR_GRTR'
					; 'NO_LESS'   => 'STR_LESS'
					; 'NOS_EQL'   => 'STRS_EQL'
					; 'ADDITION'  => 'STRS_ADD'
		LD	C,A		; put modified comparison operator back
		CP	$10		; is it now 'STR_AND_NO' ?
		JR	NZ,S_NOT_AND	; forward to S_NOT_AND  if not.

		SET	6,C		; set numeric operand bit
		JR	S_NEXT		; forward to S_NEXT

					;;;$2788
S_NOT_AND:	JR	C,S_RPORT_C2	; back to S_RPORT_C2 if less
					; 'Nonsense in basic'.
					; e.g. a$ * b$
		CP	$17		; is it 'STRS_ADD' ?
		JR	Z,S_NEXT	; forward to to S_NEXT if so
					; (bit 6 and 7 are reset)
		SET	7,C		; set numeric (Boolean) result for all others

					;;;$2790
S_NEXT:		PUSH	BC		; now save this priority/operation on stack
		RST	20H		; NEXT_CHAR
		JP	S_LOOP_1	; jump back to S_LOOP_1

;-------------------
; Table of operators
;-------------------
; This table is used to look up the calculator literals associated with
; the operator character. The thirteen calculator operations $03 - $0F
; have bits 6 and 7 set to signify a numeric result.
; Some of these codes and bits may be altered later if the context suggests
; a string comparison or operation.
; that is '+', '=', '>', '<', '<=', '>=' or '<>'.

					;;;$2795
TBL_OF_OPS:	DEFB	'+', $CF	;	$C0 + 'ADDITION'
		DEFB	'-', $C3	;	$C0 + 'SUBTRACT'
		DEFB	'*', $C4	;	$C0 + 'MULTIPLY'
		DEFB	'/', $C5	;	$C0 + 'DIVISION'
		DEFB	'^', $C6	;	$C0 + 'TO_POWER'
		DEFB	'=', $CE	;	$C0 + 'NOS_EQL'
		DEFB	'>', $CC	;	$C0 + 'NO_GRTR'
		DEFB	'<', $CD	;	$C0 + 'NO_LESS'
		DEFB	$C7, $C9	; '<='	$C0 + 'NO_L_EQL'
		DEFB	$C8, $CA	; '>='	$C0 + 'NO_GR_EQL'
		DEFB	$C9, $CB	; '<>'	$C0 + 'NOS_NEQL'
		DEFB	$C5, $C7	; 'OR'	$C0 + 'OR'
		DEFB	$C6, $C8	; 'AND' $C0 + 'NO_AND_NO'

		DEFB	$00		; zero end-marker.


;--------------------
; Table of priorities
;--------------------
; This table is indexed with the operation code obtained from the above
; table $C3 - $CF to obtain the priority for the respective operation.

					;;;$27B0
TBL_PRIORS:	DEFB	$06		; '-'	opcode $C3
		DEFB	$08		; '*'	opcode $C4
		DEFB	$08		; '/'	opcode $C5
		DEFB	$0A		; '^'	opcode $C6
		DEFB	$02		; 'OR'  opcode $C7
		DEFB	$03		; 'AND' opcode $C8
		DEFB	$05		; '<='  opcode $C9
		DEFB	$05		; '>='  opcode $CA
		DEFB	$05		; '<>'  opcode $CB
		DEFB	$05		; '>'	opcode $CC
		DEFB	$05		; '<'	opcode $CD
		DEFB	$05		; '='	opcode $CE
		DEFB	$06		; '+'	opcode $CF

;-----------------------
; Scanning function (FN)
;-----------------------
; This routine deals with user-defined functions.
; The definition can be anywhere in the program area but these are best
; placed near the start of the program as we shall see.
; The evaluation process is quite complex as the Spectrum has to parse two
; statements at the same time. Syntax of both has been checked previously
; and hidden locations have been created immediately after each argument
; of the DEF FN statement. Each of the arguments of the FN function is
; evaluated by SCANNING and placed in the hidden locations. Then the
; expression to the right of the DEF FN '=' is evaluated by SCANNING and for
; any variables encountered, a search is made in the DEF FN variable list
; in the program area before searching in the normal variables area.
;
; Recursion is not allowed: i.e. the definition of a function should not use
; the same function, either directly or indirectly ( through another function).
; You'll normally get error 4, ('Out of memory'), although sometimes the sytem
; will crash. - Vickers, Pitman 1984.
;
; As the definition is just an expression, there would seem to be no means
; of breaking out of such recursion.
; However, by the clever use of string expressions and VAL, such recursion is
; possible.
; e.g. DEF FN a(n) = VAL "n+FN a(n-1)+0" ((n<1) * 10 + 1 TO )
; will evaluate the full 11-character expression for all values where n is
; greater than zero but just the 11th character, "0", when n drops to zero
; thereby ending the recursion producing the correct result.
; Recursive string functions are possible using VAL$ instead of VAL and the
; null string as the final addend.
; - from a turn of the century newsgroup discussion initiated by Mike Wynne.

					;;;$27BD
S_FN_SBRN:	CALL	SYNTAX_Z	; routine SYNTAX_Z
		JR	NZ,SF_RUN	; forward to SF_RUN in runtime

		RST	20H		; NEXT_CHAR
		CALL	ALPHA		; routine ALPHA check for letters A-Z a-z
		JP	NC,REPORT_C	; jump back to REPORT_C if not
					; 'Nonsense in Basic'
		RST	20H		; NEXT_CHAR
		CP	$24		; is it '$' ?
		PUSH	AF		; save character and flags
		JR	NZ,SF_BRKT_1	; forward to SF_BRKT_1 with numeric function

		RST	20H		; NEXT_CHAR

					;;;$27D0
SF_BRKT_1:	CP	$28		; is '(' ?
		JR	NZ,SF_RPRT_C	; forward to SF_RPRT_C if not
					; 'Nonsense in Basic'
		RST	20H		; NEXT_CHAR
		CP	$29		; is it ')' ?
		JR	Z,SF_FLAG_6	; forward to SF_FLAG_6 if no arguments.

					;;;$27D9
SF_ARGMTS:	CALL	SCANNING	; routine SCANNING checks each argument
					; which may be an expression.
		RST	18H		; GET_CHAR
		CP	$2C		; is it a ',' ?
		JR	NZ,SF_BRKT_2	; forward if not to SF_BRKT_2 to test bracket

		RST	20H		; NEXT_CHAR if a comma was found
		JR	SF_ARGMTS	; back to SF_ARGMTS to parse all arguments.

					;;;$27E4
SF_BRKT_2:	CP	$29		; is character the closing ')' ?

					;;;$27E6
SF_RPRT_C:	JP	NZ,REPORT_C	; jump to REPORT_C
					; 'Nonsense in Basic'

					; at this point any optional arguments have had their syntax checked.

					;;;$27E9
SF_FLAG_6:	RST	20H		; NEXT_CHAR
		LD	HL,FLAGS	; address system variable FLAGS
		RES	6,(HL)		; signal string result
		POP	AF		; restore test against '$'.
		JR	Z,SF_SYN_EN	; forward to SF_SYN_EN if string function.

		SET	6,(HL)		; signal numeric result

					;;;$27F4
SF_SYN_EN:	JP	S_CONT_2	; jump back to S_CONT_2 to continue scanning.

					; the branch was here in runtime.

					;;;$27F7
SF_RUN:		RST	20H		; NEXT_CHAR fetches name
		AND	$DF		; AND 11101111 - reset bit 5 - upper-case.
		LD	B,A		; save in B
		RST	20H		; NEXT_CHAR
		SUB	$24		; subtract '$'
		LD	C,A		; save result in C
		JR	NZ,SF_ARGMT1	; forward if not '$' to SF_ARGMT1

		RST	20H		; NEXT_CHAR advances to bracket

					;;;$2802
SF_ARGMT1:	RST	20H		; NEXT_CHAR advances to start of argument
		PUSH	HL		; save address
		LD	HL,(PROG)	; fetch start of program area from PROG
		DEC	HL		; the search starting point is the previous
					; location.

					;;;$2808
SF_FND_DF:	LD	DE,$00CE	; search is for token 'DEF FN' in E, statement count in D.
		PUSH	BC		; save C the string test, and B the letter.
		CALL	LOOK_PROG	; routine LOOK_PROG will search for token.
		POP	BC		; restore BC.
		JR	NC,SF_CP_DEF	; forward to SF_CP_DEF if a match was found.

					;;;$2812
REPORT_P:	RST	08H		; ERROR_1
		DEFB	$18		; Error Report: FN without DEF

					;;;$2814
SF_CP_DEF:	PUSH	HL		; save address of DEF FN
		CALL	FN_SKPOVR	; routine FN_SKPOVR skips over white-space etc.
					; without disturbing CH-ADD.
		AND	$DF		; make fetched character upper-case.
		CP	B		; compare with FN name
		JR	NZ,SF_NOT_FD	; forward to SF_NOT_FD if no match.

					; the letters match so test the type.

		CALL	FN_SKPOVR	; routine FN_SKPOVR skips white-space
		SUB	$24		; subtract '$' from fetched character
		CP	C		; compare with saved result of same operation on FN name.
		JR	Z,SF_VALUES	; forward to SF_VALUES with a match.

					; the letters matched but one was string and the other numeric.

					;;;$2825
SF_NOT_FD:	POP	HL		; restore search point.
		DEC	HL		; make location before
		LD	DE,$0200	; the search is to be for the end of the
					; current definition - 2 statements forward.
		PUSH	BC		; save the letter/type
		CALL	EACH_STMT	; routine EACH_STMT steps past rejected definition.
		POP	BC		; restore letter/type
		JR	SF_FND_DF	; back to SF_FND_DF to continue search

					; Success!
					; the branch was here with matching letter and numeric/string type.

					;;;$2831
SF_VALUES:	AND	A		; test A ( will be zero if string '$' - '$' )
		CALL	Z,FN_SKPOVR	; routine FN_SKPOVR advances HL past '$'.
		POP	DE		; discard pointer to 'DEF FN'.
		POP	DE		; restore pointer to first FN argument.
		LD	(CH_ADD),DE	; save in CH_ADD
		CALL	FN_SKPOVR	; routine FN_SKPOVR advances HL past '('
		PUSH	HL		; save start address in DEF FN  ***
		CP	$29		; is character a ')' ?
		JR	Z,SF_R_BR_2	; forward to SF_R_BR_2 if no arguments.

					;;;$2843
SF_ARG_LP:	INC	HL		; point to next character.
		LD	A,(HL)		; fetch it.
		CP	$0E		; is it the number marker
		LD	D,$40		; signal numeric in D.
		JR	Z,SF_ARG_VL	; forward to SF_ARG_VL if numeric.

		DEC	HL		; back to letter
		CALL	FN_SKPOVR	; routine FN_SKPOVR skips any white-space
		INC	HL		; advance past the expected '$' to the 'hidden' marker.
		LD	D,$00		; signal string.

					;;;$2852
SF_ARG_VL:	INC	HL		; now address first of 5-byte location.
		PUSH	HL		; save address in DEF FN statement
		PUSH	DE		; save D - result type
		CALL	SCANNING	; routine SCANNING evaluates expression in
					; the FN statement setting FLAGS and leaving
					; result as last value on calculator stack.
		POP	AF		; restore saved result type to A
		XOR	(IY+$01)	; xor with FLAGS
		AND	$40		; and with 01000000 to test bit 6
		JR	NZ,REPORT_Q	; forward to REPORT_Q if type mismatch.
					; 'Parameter error'
		POP	HL		; pop the start address in DEF FN statement
		EX	DE,HL		; transfer to DE ?? pop straight into de ?
		LD	HL,(STKEND)	; set HL to STKEND location after value
		LD	BC,$0005	; five bytes to move
		SBC	HL,BC		; decrease HL by 5 to point to start.
		LD	(STKEND),HL	; set STKEND 'removing' value from stack.
		LDIR			; copy value into DEF FN statement
		EX	DE,HL		; set HL to location after value in DEF FN
		DEC	HL		; step back one
		CALL	FN_SKPOVR	; routine FN_SKPOVR gets next valid character
		CP	$29		; is it ')' end of arguments ?
		JR	Z,SF_R_BR_2	; forward to SF_R_BR_2 if so.

					; a comma separator has been encountered in the DEF FN argument list.

		PUSH	HL		; save position in DEF FN statement
		RST	18H		; GET_CHAR from FN statement
		CP	$2C		; is it ',' ?
		JR	NZ,REPORT_Q	; forward to REPORT_Q if not
					; 'Parameter error'
		RST	20H		; NEXT_CHAR in FN statement advances to next
					; argument.
		POP	HL		; restore DEF FN pointer
		CALL	FN_SKPOVR	; routine FN_SKPOVR advances to corresponding
					; argument.
		JR	SF_ARG_LP	; back to SF_ARG_LP looping until all
					; arguments are passed into the DEF FN
					; hidden locations.

					; the branch was here when all arguments passed.

					;;;$2885
SF_R_BR_2:	PUSH	HL		; save location of ')' in DEF FN
		RST	18H		; GET_CHAR gets next character in FN
		CP	$29		; is it a ')' also ?
		JR	Z,SF_VALUE	; forward to SF_VALUE if so.

					;;;$288B
REPORT_Q:	RST	08H		; ERROR_1
		DEFB	$19		; Error Report: Parameter error

					;;;$288D
SF_VALUE:	POP	DE		; location of ')' in DEF FN to DE.
		EX	DE,HL		; now to HL, FN ')' pointer to DE.
		LD	(CH_ADD),HL	; initialize CH_ADD to this value.

					; At this point the start of the DEF FN argument list is on the machine stack.
					; We also have to consider that this defined function may form part of the
					; definition of another defined function (though not itself).
					; As this defined function may be part of a hierarchy of defined functions
					; currently being evaluated by recursive calls to SCANNING, then we have to
					; preserve the original value of DEFADD and not assume that it is zero.

		LD	HL,(DEFADD)	; get original DEFADD address
		EX	(SP),HL		; swap with DEF FN address on stack ***
		LD	(DEFADD),HL	; set DEFADD to point to this argument list
					; during scanning.
		PUSH	DE		; save FN ')' pointer.
		RST	20H		; NEXT_CHAR advances past ')' in define
		RST	20H		; NEXT_CHAR advances past '=' to expression
		CALL	SCANNING	; routine SCANNING evaluates but searches
					; initially for variables at DEFADD
		POP	HL		; pop the FN ')' pointer
		LD	(CH_ADD),HL	; set CH_ADD to this
		POP	HL		; pop the original DEFADD value
		LD	(DEFADD),HL	; and re-insert into DEFADD system variable.

		RST	20H		; NEXT_CHAR advances to character after ')'
		JP	S_CONT_2	; to S_CONT_2 - to continue current
					; invocation of scanning

;---------------------
; Used to parse DEF FN
;---------------------
; e.g. DEF FN     s $ ( x )     =  b     $ (  TO  x  ) : REM exaggerated
;
; This routine is used 10 times to advance along a DEF FN statement
; skipping spaces and colour control codes. It is similar to NEXT-CHAR
; which is, at the same time, used to skip along the corresponding FN function
; except the latter has to deal with AT and TAB characters in string
; expressions. These cannot occur in a program area so this routine is
; simpler as both colour controls and their parameters are less than space.

					;;;$28AB
FN_SKPOVR:	INC	HL		; increase pointer
		LD	A,(HL)		; fetch addressed character
		CP	$21		; compare with space + 1
		JR	C,FN_SKPOVR	; back to FN_SKPOVR if less

		RET			; return pointing to a valid character.

;----------
; LOOK_VARS
;----------

					;;;$28B2
LOOK_VARS:	SET	6,(IY+$01)	; update FLAGS - presume numeric result
		RST	18H		; GET_CHAR
		CALL	ALPHA		; routine ALPHA tests for A-Za-z
		JP	NC,REPORT_C	; jump to REPORT_C if not.
					; 'Nonsense in basic'
		PUSH	HL		; save pointer to first letter	^1
		AND	$1F		; mask lower bits, 1 - 26 decimal	000xxxxx
		LD	C,A		; store in C.
		RST	20H		; NEXT_CHAR
		PUSH	HL		; save pointer to second character	^2
		CP	$28		; is it '(' - an array ?
		JR	Z,V_RUN_SYN	; forward to V_RUN_SYN if so.

		SET	6,C		; set 6 signalling string if solitary	010
		CP	$24		; is character a '$' ?
		JR	Z,V_STR_VAR	; forward to V_STR_VAR

		SET	5,C		; signal numeric			011
		CALL	ALPHANUM	; routine ALPHANUM sets carry if second
					; character is alphanumeric.
		JR	NC,V_TEST_FN	; forward to V_TEST_FN if just one character


					; it is more than one character but re-test current character so that 6 reset
					; Note. this is a rare lack of elegance. Bit 6 could be reset once before
					; entering the loop. Another puzzle is that this loop renders the similar
					; loop at V_PASS redundant.

					;;;$28D4
V_CHAR:		CALL	ALPHANUM	; routine ALPHANUM
		JR	NC,V_RUN_SYN	; to V_RUN_SYN when no more

		RES	6,C		; make long named type			001
		RST	20H		; NEXT_CHAR
		JR	V_CHAR		; loop back to V_CHAR

					;;;$28DE
V_STR_VAR:	RST	20H		; NEXT_CHAR advances past '$'
		RES	6,(IY+$01)	; update FLAGS - signal string result.

					;;;$28E3
V_TEST_FN:	LD	A,($5C0C)	; load A with DEFADD_hi
		AND	A		; and test for zero.
		JR	Z,V_RUN_SYN	; forward to V_RUN_SYN if a defined function
					; is not being evaluated.
		CALL	SYNTAX_Z	; routine SYNTAX_Z
		JP	NZ,STK_F_ARG	; branch to STK_F_ARG in runtime and then
					; back to this point if no variable found.

					;;;$28EF
V_RUN_SYN:	LD	B,C		; save flags in B
		CALL	SYNTAX_Z	; routine SYNTAX_Z
		JR	NZ,V_RUN	; to V_RUN to look for the variable in runtime

					; if checking syntax the letter is not returned

		LD	A,C		; copy letter/flags to A
		AND	$E0		; and with 11100000 to get rid of the letter
		SET	7,A		; use spare bit to signal checking syntax.
		LD	C,A		; and transfer to C.
		JR	V_SYNTAX	; forward to V_SYNTAX

					; but in runtime search for the variable.

					;;;$28FD
V_RUN:		LD	HL,(VARS)	; set HL to start of variables from VARS

					;;;$2900
V_EACH:		LD	A,(HL)		; get first character
		AND	$7F		; and with 01111111
					; ignoring bit 7 which distinguishes
					; arrays or for/next variables.
		JR	Z,V_80_BYTE	; to V_80_BYTE if zero as must be 10000000
					; the variables end-marker.
		CP	C		; compare with supplied value.
		JR	NZ,V_NEXT	; forward to V_NEXT if no match.

		RLA			; destructively test
		ADD	A,A		; bits 5 and 6 of A
					; jumping if bit 5 reset or 6 set
		JP	P,V_FOUND_2	; to V_FOUND_2  strings and arrays

		JR	C,V_FOUND_2	; to V_FOUND_2  simple and for next

					; leaving long name variables.

		POP	DE		; pop pointer to 2nd. char
		PUSH	DE		; save it again
		PUSH	HL		; save variable first character pointer

					;;;$2912
V_MATCHES:	INC	HL		; address next character in vars area

					;;;$2913
V_SPACES:	LD	A,(DE)		; pick up letter from prog area
		INC	DE		; and advance address
		CP	$20		; is it a space
		JR	Z,V_SPACES	; back to V_SPACES until non-space

		OR	$20		; convert to range 1 - 26.
		CP	(HL)		; compare with addressed variables character
		JR	Z,V_MATCHES	; loop back to V_MATCHES if a match on an
					; intermediate letter.
		OR	$80		; now set bit 7 as last character of long
					; names are inverted.
		CP	(HL)		; compare again
		JR	NZ,V_GET_PTR	; forward to V_GET_PTR if no match

					; but if they match check that this is also last letter in prog area

		LD	A,(DE)		; fetch next character
		CALL	ALPHANUM	; routine ALPHANUM sets carry if not alphanum
		JR	NC,V_FOUND_1	; forward to V_FOUND_1 with a full match.

					;;;$2929
V_GET_PTR:	POP	HL		; pop saved pointer to char 1

					;;;$292A
V_NEXT:		PUSH	BC		; save flags
		CALL	NEXT_ONE	; routine NEXT_ONE gets next variable in DE
		EX	DE,HL		; transfer to HL.
		POP	BC		; restore the flags
		JR	V_EACH		; loop back to V_EACH
					; to compare each variable

					;;;$2932
V_80_BYTE:	SET	7,B		; will signal not found

					; the branch was here when checking syntax

					;;;$2934
V_SYNTAX:	POP	DE		; discard the pointer to 2nd. character  v2
					; in basic line/workspace.
		RST	18H		; GET_CHAR gets character after variable name.
		CP	$28		; is it '(' ?
		JR	Z,V_PASS	; forward to V_PASS
					; Note. could go straight to V_END ?
		SET	5,B		; signal not an array
		JR	V_END		; forward to V_END

					; the jump was here when a long name matched and HL pointing to last character
					; in variables area.

					;;;$293E
V_FOUND_1:	POP	DE		; discard pointer to first var letter

					; the jump was here with all other matches HL points to first var char.

					;;;$293F
V_FOUND_2:	POP	DE		; discard pointer to 2nd prog char	v2
		POP	DE		; drop pointer to 1st prog char		v1
		PUSH	HL		; save pointer to last char in vars
		RST	18H		; GET_CHAR

					;;;$2943
V_PASS:		CALL	ALPHANUM	; routine ALPHANUM
		JR	NC,V_END	; forward to V_END if not

					; but it never will be as we advanced past long-named variables earlier.

		RST	20H		; NEXT_CHAR
		JR	V_PASS		; back to V_PASS

					;;;$294B
V_END:		POP	HL		; pop the pointer to first character in basic line/workspace.
		RL	B		; rotate the B register, left bit 7 to carry	
		BIT	6,B		; test the array indicator bit.
		RET			; return

;------------------------
; Stack function argument
;------------------------
; This branch is taken from LOOK_VARS when a defined function is currently
; being evaluated.
; Scanning is evaluating the expression after the '=' and the variable
; found could be in the argument list to the left of the '=' or in the
; normal place after the program. Preference will be given to the former.
; The variable name to be matched is in C.

					;;;$2951
STK_F_ARG:	LD	HL,(DEFADD)	; set HL to DEFADD
		LD	A,(HL)		; load the first character
		CP	$29		; is it ')' ?
		JP	Z,V_RUN_SYN	; back to V_RUN_SYN, if so, as no arguments.

					; but proceed to search argument list of defined function first if not empty.

					;;;$295A
SFA_LOOP:	LD	A,(HL)		; fetch character again.
		OR	$60		; or with 01100000 presume a simple variable.
		LD	B,A		; save result in B.
		INC	HL		; address next location.
		LD	A,(HL)		; pick up byte.
		CP	$0E		; is it the number marker ?
		JR	Z,SFA_CP_VR	; forward to SFA_CP_VR if so.

					; it was a string. White-space may be present but syntax has been checked.

		DEC	HL		; point back to letter.
		CALL	FN_SKPOVR	; routine FN_SKPOVR skips to the '$'
		INC	HL		; now address the hidden marker.
		RES	5,B		; signal a string variable.

					;;;$296B
SFA_CP_VR:	LD	A,B		; transfer found variable letter to A.
		CP	C		; compare with expected.
		JR	Z,SFA_MATCH	; forward to SFA_MATCH with a match.

		INC	HL		; step
		INC	HL		; past
		INC	HL		; the
		INC	HL		; five
		INC	HL		; bytes.
		CALL	FN_SKPOVR	; routine FN_SKPOVR skips to next character
		CP	$29		; is it ')' ?
		JP	Z,V_RUN_SYN	; jump back if so to V_RUN_SYN to look in
					; normal variables area.
		CALL	FN_SKPOVR	; routine FN_SKPOVR skips past the ','
					; all syntax has been checked and these
					; things can be taken as read.
		JR	SFA_LOOP	; back to SFA_LOOP while there are more
					; arguments.

					;;;$2981
SFA_MATCH:	BIT	5,C		; test if numeric
		JR	NZ,SFA_END	; to SFA_END if so as will be stacked
					; by scanning
		INC	HL		; point to start of string descriptor
		LD	DE,(STKEND)	; set DE to STKEND
		CALL	MOVE_FP		; routine MOVE_FP puts parameters on stack.
		EX	DE,HL		; new free location to HL.
		LD	(STKEND),HL	; use it to set STKEND system variable.

					;;;$2991
SFA_END:	POP	DE		; discard
		POP	DE		; pointers.
		XOR	A		; clear carry flag.
		INC	A		; and zero flag.
		RET			; return.

;-------------------------
; Stack variable component
;-------------------------
; This is called to evaluate a complex structure that has been found, in
; runtime, by LOOK_VARS in the variables area.
; In this case HL points to the initial letter, bits 7-5
; of which indicate the type of variable.
; 010 - simple string, 110 - string array, 100 - array of numbers.
;
; It is called from CLASS_01 when assigning to a string or array including
; a slice.
; It is called from SCANNING to isolate the required part of the structure.
;
; An important part of the runtime process is to check that the number of
; dimensions of the variable match the number of subscripts supplied in the
; basic line.
;
; If checking syntax,
; the B register, which counts dimensions is set to zero (256) to allow
; the loop to continue till all subscripts are checked. While doing this it
; is reading dimension sizes from some arbitrary area of memory. Although
; these are meaningless it is of no concern as the limit is never checked by
; int-exp during syntax checking.
;
; The routine is also called from the syntax path of DIM command to check the
; syntax of both string and numeric arrays definitions except that bit 6 of C
; is reset so both are checked as numeric arrays. This ruse avoids a terminal
; slice being accepted as part of the DIM command.
; All that is being checked is that there are a valid set of comma-separated
; expressions before a terminal ')', although, as above, it will still go
; through the motions of checking dummy dimension sizes.

					;;;$2996
STK_VAR:	XOR	A		; clear A
		LD	B,A		; and B, the syntax dimension counter (256)
		BIT	7,C		; checking syntax ?
		JR	NZ,SV_COUNT	; forward to SV_COUNT if so.

					; runtime evaluation.

		BIT	7,(HL)		; will be reset if a simple string.
		JR	NZ,SV_ARRAYS	; forward to SV_ARRAYS otherwise

		INC	A		; set A to 1, simple string.

					;;;$29A1
SV_SIMPLE:	INC	HL		; address length low
		LD	C,(HL)		; place in C
		INC	HL		; address length high
		LD	B,(HL)		; place in B
		INC	HL		; address start of string
		EX	DE,HL		; DE = start now.
		CALL	STK_STO_D	; routine STK_STO_D stacks string parameters
					; DE start in variables area,
					; BC length, A=1 simple string

					; the only thing now is to consider if a slice is required.

		RST	18H		; GET_CHAR puts character at CH_ADD in A
		JP	SV_SLICE_EX	; jump forward to SV_SLICE_EX to test for '('

					; the branch was here with string and numeric arrays in runtime.

					;;;$29AE
SV_ARRAYS:	INC	HL		; step past
		INC	HL		; the total length
		INC	HL		; to address Number of dimensions.
		LD	B,(HL)		; transfer to B overwriting zero.
		BIT	6,C		; a numeric array ?
		JR	Z,SV_PTR	; forward to SV_PTR with numeric arrays

		DEC	B		; ignore the final element of a string array
					; the fixed string size.
		JR	Z,SV_SIMPLE	; back to SV_SIMPLE if result is zero as has
					; been created with DIM a$(10) for instance
					; and can be treated as a simple string.

					; proceed with multi-dimensioned string arrays in runtime.

		EX	DE,HL		; save pointer to dimensions in DE
		RST	18H		; GET_CHAR looks at the Basic line
		CP	$28		; is character '(' ?
		JR	NZ,REPORT_3	; to REPORT_3 if not
					; 'Subscript wrong'
		EX	DE,HL		; dimensions pointer to HL to synchronize
					; with next instruction.

					; runtime numeric arrays path rejoins here.

					;;;$29C0
SV_PTR:		EX	DE,HL		; save dimension pointer in DE
		JR	SV_COUNT	; forward to SV_COUNT with true no of dims 
					; in B. As there is no initial comma the 
					; loop is entered at the midpoint.

					; the dimension counting loop which is entered at mid-point.

					;;;$29C3
SV_COMMA:	PUSH	HL		; save counter
		RST	18H		; GET_CHAR
		POP	HL		; pop counter
		CP	$2C		; is character ',' ?
		JR	Z,SV_LOOP	; forward to SV_LOOP if so

					; in runtime the variable definition indicates a comma should appear here

		BIT	7,C		; checking syntax ?
		JR	Z,REPORT_3	; forward to REPORT_3 if not
					; 'Subscript error'

					; proceed if checking syntax of an array?

		BIT	6,C		; array of strings
		JR	NZ,SV_CLOSE	; forward to SV_CLOSE if so

					; an array of numbers.

		CP	$29		; is character ')' ?
		JR	NZ,SV_RPT_C	; forward to SV_RPT_C if not
					; 'Nonsense in basic'
		RST	20H		; NEXT_CHAR moves CH-ADD past the statement
		RET			; return ->

					; the branch was here with an array of strings.

					;;;$29D8
SV_CLOSE:	CP	$29		; as above ')' could follow the expression
		JR	Z,SV_DIM	; forward to SV_DIM if so

		CP	$CC		; is it 'TO' ?
		JR	NZ,SV_RPT_C	; to SV_RPT_C with anything else
					; 'Nonsense in basic'

					; now backtrack CH_ADD to set up for slicing routine.
					; Note. in a basic line we can safely backtrack to a colour parameter.

					;;;$29E0
SV_CH_ADD:	RST	18H		; GET_CHAR
		DEC	HL		; backtrack HL
		LD	(CH_ADD),HL	; to set CH_ADD up for slicing routine
		JR	SV_SLICE	; forward to SV_SLICE and make a return
					; when all slicing complete.

					; -> the mid-point entry point of the loop

					;;;$29E7
SV_COUNT:	LD	HL,$0000	; initialize data pointer to zero.


					;;;$29EA
SV_LOOP:	PUSH	HL		; save the data pointer.
		RST	20H		; NEXT_CHAR in Basic area points to an expression.
		POP	HL		; restore the data pointer.
		LD	A,C		; transfer name/type to A.
		CP	$C0		; is it 11000000 ?
					; Note. the letter component is absent if
					; syntax checking.
		JR	NZ,SV_MULT	; forward to SV_MULT if not an array of
					; strings.

					; proceed to check string arrays during syntax.

		RST	18H		; GET_CHAR
		CP	$29		; ')'  end of subscripts ?
		JR	Z,SV_DIM		; forward to SV_DIM to consider further slice

		CP	$CC		; is it 'TO' ?
		JR	Z,SV_CH_ADD	; back to SV_CH_ADD to consider a slice.
					; (no need to repeat GET_CHAR at SV_CH_ADD)

					; if neither, then an expression is required so rejoin runtime loop ??
					; registers HL and DE only point to somewhere meaningful in runtime so 
					; comments apply to that situation.

					;;;$29FB
SV_MULT:	PUSH	BC		; save dimension number.
		PUSH	HL		; push data pointer/rubbish.
					; DE points to current dimension.
		CALL	DE_DE_1		; routine DE_DE_1 gets next dimension in DE
					; and HL points to it.
		EX	(SP),HL		; dim pointer to stack, data pointer to HL (*)
		EX	DE,HL		; data pointer to DE, dim size to HL.
		CALL	INT_EXP1	; routine INT_EXP1 checks integer expression
					; and gets result in BC in runtime.
		JR	C,REPORT_3	; to REPORT_3 if > HL
					; 'Subscript out of range'
		DEC	BC		; adjust returned result from 1-x to 0-x
		CALL	GET_HL_DE	; routine GET_HL_DE multiplies data pointer by dimension size.
		ADD	HL,BC		; add the integer returned by expression.
		POP	DE		; pop the dimension pointer.			***
		POP	BC		; pop dimension counter.
		DJNZ	SV_COMMA	; back to SV_COMMA if more dimensions
					; Note. during syntax checking, unless there
					; are more than 256 subscripts, the branch
					; back to SV_COMMA is always taken.
		BIT	7,C		; are we checking syntax ?
					; then we've got a joker here.

					;;;$2A12
SV_RPT_C:	JR	NZ,SL_RPT_C	; forward to SL_RPT_C if so
					; 'Nonsense in Basic'
					; more than 256 subscripts in Basic line.

					; but in runtime the number of subscripts are at least the same as dims

		PUSH	HL		; save data pointer.
		BIT	6,C		; is it a string array ?
		JR	NZ,SV_ELEM	; forward to SV_ELEM if so.

					; a runtime numeric array subscript.

		LD	B,D		; register DE has advanced past all dimensions
		LD	C,E		; and points to start of data in variable.
					; transfer it to BC.
		RST	18H		; GET_CHAR checks Basic line
		CP	$29		; must be a ')' ?
		JR	Z,SV_NUMBER	; skip to SV_NUMBER if so

					; else more subscripts in Basic line than the variable definition.

					;;;$2A20
REPORT_3:	RST	08H		; ERROR_1
		DEFB	$02		; Error Report: Subscript wrong

					; continue if subscripts matched the numeric array.

					;;;$2A22
SV_NUMBER:	RST	20H		; NEXT_CHAR moves CH_ADD to next statement - finished parsing.
		POP	HL		; pop the data pointer.
		LD	DE,$0005	; each numeric element is 5 bytes.
		CALL	GET_HL_DE	; routine GET_HL_DE multiplies.
		ADD	HL,BC		; now add to start of data in the variable.
		RET			; return with HL pointing at the numeric
					; array subscript.			->

					; the branch was here for string subscripts when the number of subscripts
					; in the basic line was one less than in variable definition.

					;;;$2A2C
SV_ELEM:	CALL	DE_DE_1		; routine DE_DE_1 gets final dimension
					; the length of strings in this array.
		EX	(SP),HL		; start pointer to stack, data pointer to HL.
		CALL	GET_HL_DE	; routine GET_HL_DE multiplies by element size.
		POP	BC		; the start of data pointer is added
		ADD	HL,BC		; in - now points to location before.
		INC	HL		; point to start of required string.
		LD	B,D		; transfer the length (final dimension size)
		LD	C,E		; from DE to BC.
		EX	DE,HL		; put start in DE.
		CALL	STK_ST_0	; routine STK_ST_0 stores the string parameters
					; with A=0 - a slice or subscript.

					; now check that there were no more subscripts in the Basic line.

		RST	18H		; GET_CHAR
		CP	$29		; is it ')' ?
		JR	Z,SV_DIM	; forward to SV_DIM to consider a separate
					; subscript or/and a slice.
		CP	$2C		; a comma is allowed if the final subscript
					; is to be sliced e.g a$(2,3,4 TO 6).
		JR	NZ,REPORT_3	; to REPORT_3 with anything else
					; 'Subscript error'

					;;;$2A45
SV_SLICE:	CALL	SLICING		; routine SLICING slices the string.
					; but a slice of a simple string can itself be sliced.

					;;;$2A48
SV_DIM:		RST	20H		; NEXT_CHAR

					;;;$2A49
SV_SLICE_EX:	CP	$28		; is character '(' ?
		JR	Z,SV_SLICE	; loop back if so to SV_SLICE

		RES	6,(IY+$01)	; update FLAGS  - Signal string result
		RET			; and return.

; The above section deals with the flexible syntax allowed.
; DIM a$(3,3,10) can be considered as two dimensional array of ten-character
; strings or a 3-dimensional array of characters.
; a$(1,1) will return a 10-character string as will a$(1,1,1 TO 10)
; a$(1,1,1) will return a single character.
; a$(1,1) (1 TO 6) is the same as a$(1,1,1 TO 6)
; A slice can itself be sliced ad infinitum
; b$ () () () () () () (2 TO 10) (2 TO 9) (3) is the same as b$(5)


;--------------------------
; Handle slicing of strings
;--------------------------
; The syntax of string slicing is very natural and it is as well to reflect
; on the permutations possible.
; a$() and a$( TO ) indicate the entire string although just a$ would do
; and would avoid coming here.
; h$(16) indicates the single character at position 16.
; a$( TO 32) indicates the first 32 characters.
; a$(257 TO) indicates all except the first 256 characters.
; a$(19000 TO 19999) indicates the thousand characters at position 19000.
; Also a$(9 TO 5) returns a null string not an error.
; This enables a$(2 TO) to return a null string if the passed string is
; of length zero or 1.
; A string expression in brackets can be sliced. e.g. (STR$ PI) (3 TO )
; We arrived here from SCANNING with CH-ADD pointing to the initial '('
; or from above.

					;;;$2A52
SLICING:	CALL	SYNTAX_Z	; routine SYNTAX_Z
		CALL	NZ,STK_FETCH	; routine STK_FETCH fetches parameters of
					; string at runtime, start in DE, length 
					; in BC. This could be an array subscript.
		RST	20H		; NEXT_CHAR
		CP	$29		; is it ')' ?	e.g. a$()
		JR	Z,SL_STORE	; forward to SL_STORE to store entire string.

		PUSH	DE		; else save start address of string
		XOR	A		; clear accumulator to use as a running flag.
		PUSH	AF		; and save on stack before any branching.
		PUSH	BC		; save length of string to be sliced.
		LD	DE,$0001	; default the start point to position 1.
		RST	18H		; GET_CHAR
		POP	HL		; pop length to HL as default end point
					; and limit.
		CP	$CC		; is it 'TO' ?	e.g. a$( TO 10000)
		JR	Z,SL_SECOND	; to SL_SECOND to evaluate second parameter.

		POP	AF		; pop the running flag.
		CALL	INT_EXP2	; routine INT_EXP2 fetches first parameter.
		PUSH	AF		; save flag (will be $FF if parameter>limit)
		LD	D,B		; transfer the start
		LD	E,C		; to DE overwriting 0001.
		PUSH	HL		; save original length.
		RST	18H		; GET_CHAR
		POP	HL		; pop the limit length.
		CP	$CC		; is it 'TO' after a start ?
		JR	Z,SL_SECOND	; to SL_SECOND to evaluate second parameter

		CP	$29		; is it ')' ?	e.g. a$(365)

					;;;$2A7A
SL_RPT_C:	JP	NZ,REPORT_C	; jump to REPORT_C with anything else
					; 'Nonsense in basic'
		LD	H,D		; copy start
		LD	L,E		; to end - just a one character slice.
		JR	SL_DEFINE	; forward to SL_DEFINE.

					;;;$2A81
SL_SECOND:	PUSH	HL		; save limit length.
		RST	20H		; NEXT_CHAR
		POP	HL		; pop the length.
		CP	$29		; is character ')' ?		e.g a$(7 TO )
		JR	Z,SL_DEFINE	; to SL_DEFINE using length as end point.

		POP	AF		; else restore flag.
		CALL	INT_EXP2	; routine INT_EXP2 gets second expression.
		PUSH	AF		; save the running flag.
		RST	18H		; GET_CHAR
		LD	H,B		; transfer second parameter
		LD	L,C		; to HL.		e.g. a$(42 to 99)
		CP	$29		; is character a ')' ?
		JR	NZ,SL_RPT_C	; to SL_RPT_C if not
					; 'Nonsense in basic'

					; we now have start in DE and an end in HL.

					;;;$2A94
SL_DEFINE:	POP	AF		; pop the running flag.
		EX	(SP),HL		; put end point on stack, start address to HL
		ADD	HL,DE		; add address of string to the start point.
		DEC	HL		; point to first character of slice.
		EX	(SP),HL		; start address to stack, end point to HL (*)
		AND	A		; prepare to subtract.
		SBC	HL,DE		; subtract start point from end point.
		LD	BC,$0000	; default the length result to zero.
		JR	C,SL_OVER	; forward to SL_OVER if start > end.

		INC	HL		; increment the length for inclusive byte.
		AND	A		; now test the running flag.
		JP	M,REPORT_3	; jump back to REPORT_3 if $FF.
					; 'Subscript out of range'
		LD	B,H		; transfer the length
		LD	C,L		; to BC.

					;;;$2AA8
SL_OVER:	POP	DE		; restore start address from machine stack ***
		RES	6,(IY+$01)	; update FLAGS - signal string result for
					; syntax.

					;;;$2AAD
SL_STORE:	CALL	SYNTAX_Z	; routine SYNTAX_Z  (UNSTACK_Z?)
		RET	Z		; return if checking syntax.
					; but continue to store the string in runtime.

					; ------------------------------------
					; other than from above, this routine is called from STK_VAR to stack
					; a known string array element.
					; ------------------------------------

					;;;$2AB1
STK_ST_0:	XOR	A		; clear to signal a sliced string or element.

					; -------------------------
					; this routine is called from CHR$, scrn$ etc. to store a simple string result.
					; --------------------------

					;;;$2AB2
STK_STO_D:	RES	6,(IY+$01)	; update FLAGS - signal string result.
					; and continue to store parameters of string.

;----------------------------------------
; Pass five registers to calculator stack
;----------------------------------------
; This subroutine puts five registers on the calculator stack.

					;;;$2AB6
STK_STORE:	PUSH	BC		; save two registers
		CALL	TEST_5_SP	; routine TEST_5_SP checks room and puts 5 in BC.
		POP	BC		; fetch the saved registers.
		LD	HL,(STKEND)	; make HL point to first empty location STKEND
		LD	(HL),A		; place the 5 registers.
		INC	HL
		LD	(HL),E
		INC	HL
		LD	(HL),D
		INC	HL
		LD	(HL),C
		INC	HL
		LD	(HL),B
		INC	HL
		LD	(STKEND),HL	; update system variable STKEND.
		RET			; and return.

;--------------------------------------------
; Return result of evaluating next expression
;--------------------------------------------
; This clever routine is used to check and evaluate an integer expression
; which is returned in BC, setting A to $FF, if greater than a limit supplied
; in HL. It is used to check array subscripts, parameters of a string slice
; and the arguments of the DIM command. In the latter case, the limit check
; is not required and H is set to $FF. When checking optional string slice
; parameters, it is entered at the second entry point so as not to disturb
; the running flag A, which may be $00 or $FF from a previous invocation.

					;;;$2ACC
INT_EXP1:	XOR	A		; set result flag to zero.

					; -> The entry point is here if A is used as a running flag.

					;;;$2ACD
INT_EXP2:	PUSH	DE		; preserve DE register throughout.
		PUSH	HL		; save the supplied limit.
		PUSH	AF		; save the flag.
		CALL	EXPT_1NUM	; routine EXPT_1NUM evaluates expression
					; at CH_ADD returning if numeric result,
					; with value on calculator stack.
		POP	AF		; pop the flag.
		CALL	SYNTAX_Z	; routine SYNTAX_Z
		JR	Z,I_RESTORE	; forward to I_RESTORE if checking syntax so
					; avoiding a comparison with supplied limit.
		PUSH	AF		; save the flag.
		CALL	FIND_INT2	; routine FIND_INT2 fetches value from
					; calculator stack to BC producing an error if too high.
		POP	DE		; pop the flag to D.
		LD	A,B		; test value for zero and reject
		OR	C		; as arrays and strings begin at 1.
		SCF			; set carry flag.
		JR	Z,I_CARRY	; forward to I_CARRY if zero.

		POP	HL		; restore the limit.
		PUSH	HL		; and save.
		AND	A		; prepare to subtract.
		SBC	HL,BC		; subtract value from limit.

					;;;$2AE8
I_CARRY:	LD	A,D		; move flag to accumulator $00 or $FF.
		SBC	A,$00		; will set to $FF if carry set.

					;;;$2AEB
I_RESTORE:	POP	HL		; restore the limit.
		POP	DE		; and DE register.
		RET			; return.


;------------------------
; LD DE,(DE+1) Subroutine
;------------------------
; This routine just loads the DE register with the contents of the two
; locations following the location addressed by DE.
; It is used to step along the 16-bit dimension sizes in array definitions.
; Note. Such code is made into subroutines to make programs easier to
; write and it would use less space to include the five instructions in-line.
; However, there are so many exchanges going on at the places this is invoked
; that to implement it in-line would make the code hard to follow.
; It probably had a zipier label though as the intention is to simplify the
; program.

					;;;$2AEE
DE_DE_1:	EX	DE,HL
		INC	HL
		LD	E,(HL)
		INC	HL
		LD	D,(HL)
		RET

;--------------------
; HL=HL*DE Subroutine
;--------------------
; This routine calls the mathematical routine to multiply HL by DE in runtime.
; It is called from STK_VAR and from DIM. In the latter case syntax is not
; being checked so the entry point could have been at the second CALL
; instruction to save a few clock-cycles.

					;;;$2AF4
GET_HL_DE:	CALL	SYNTAX_Z	; routine SYNTAX_Z.
		RET	Z		; return if checking syntax.

		CALL	HL_HL_DE	; routine HL_HL_DE.
		JP	C,REPORT_4	; jump back to REPORT_4 if over 65535.

		RET			; else return with 16-bit result in HL.

;-------------------
; Handle LET command
;-------------------
; Sinclair Basic adheres to the ANSI-79 standard and a LET is required in
; assignments e.g. LET a = 1  :	LET h$ = "hat"
; Long names may contain spaces but not colour controls (when assigned).
; a substring can appear to the left of the equals sign.

; An earlier mathematician Lewis Carroll may have been pleased that
; 10 LET Babies cannot manage crocodiles = Babies are illogical AND
;	Nobody is despised who can manage a crocodile AND Illogical persons
;	are despised
; does not give the 'Nonsense..' error if the three variables exist.
; I digress.

					;;;$2AFF
LET:		LD	HL,(DEST)	; fetch system variable DEST to HL.
		BIT	1,(IY+$37)	; test FLAGX - handling a new variable ?
		JR	Z,L_EXISTS	; forward to L_EXISTS if not.

					; continue for a new variable. DEST points to start in Basic line.
					; from the CLASS routines.

		LD	BC,$0005	; assume numeric and assign an initial 5 bytes

					;;;$2B0B
L_EACH_CH:	INC	BC		; increase byte count for each relevant
					; character

					;;;$2B0C
L_NO_SP:	INC	HL		; increase pointer.
		LD	A,(HL)		; fetch character.
		CP	$20		; is it a space ?
		JR	Z,L_NO_SP	; back to L_NO_SP is so.

		JR	NC,L_TEST_CH	; forward to L_TEST_CH if higher.

		CP	$10		; is it $00 - $0F ?
		JR	C,L_SPACES	; forward to L_SPACES if so.

		CP	$16		; is it $16 - $1F ?
		JR	NC,L_SPACES	; forward to L_SPACES if so.

					; it was $10 - $15  so step over a colour code.

		INC	HL		; increase pointer.
		JR	L_NO_SP		; loop back to L_NO_SP.

					; the branch was here if higher than space

					;;;$2B1F
L_TEST_CH:	CALL	ALPHANUM	; routine ALPHANUM sets carry if alphanumeric
		JR	C,L_EACH_CH	; loop back to L_EACH_CH for more if so.

		CP	$24		; is it '$' ?
		JP	Z,L_NEW		; jump forward if so, to L_NEW
					; with a new string.

					;;;$2B29
L_SPACES:	LD	A,C		; save length lo in A.
		LD	HL,(E_LINE)	; fetch E_LINE to HL.
		DEC	HL		; point to location before, the variables end-marker.
		CALL	MAKE_ROOM	; routine MAKE_ROOM creates BC spaces
					; for name and numeric value.
		INC	HL		; advance to first new location.
		INC	HL		; then to second.
		EX	DE,HL		; set DE to second location.
		PUSH	DE		; save this pointer.
		LD	HL,(DEST)	; reload HL with DEST.
		DEC	DE		; point to first.
		SUB	$06		; subtract six from length_lo.
		LD	B,A		; save count in B.
		JR	Z,L_SINGLE	; forward to L_SINGLE if it was just one character.

					; HL points to start of variable name after 'LET' in Basic line.

					;;;$2B3E
L_CHAR:		INC	HL		; increase pointer.
		LD	A,(HL)		; pick up character.
		CP	$21		; is it space or higher ?
		JR	C,L_CHAR	; back to L_CHAR with space and less.

		OR	$20		; make variable lower-case.
		INC	DE		; increase destination pointer.
		LD	(DE),A		; and load to edit line.
		DJNZ	L_CHAR		; loop back to L_CHAR until B is zero.
		OR	$80		; invert the last character.
		LD	(DE),A		; and overwrite that in edit line.

					; now consider first character which has bit 6 set

		LD	A,$C0		; set A 11000000 is xor mask for a long name.
					; %101	is xor/or  result

					; single character numerics rejoin here with %00000000 in mask.
					; %011	will be xor/or result

					;;;$2B4F
L_SINGLE:	LD	HL,(DEST)	; fetch DEST - HL addresses first character.
		XOR	(HL)		; apply variable type indicator mask (above).
		OR	$20		; make lowercase - set bit 5.
		POP	HL		; restore pointer to 2nd character.
		CALL	L_FIRST		; routine L_FIRST puts A in first character.
					; and returns with HL holding
					; new E_LINE-1  the $80 vars end-marker.

					;;;$2B59
L_NUMERIC:	PUSH	HL		; save the pointer.

					; the value of variable is deleted but remains after calculator stack.

		RST	28H		;; FP_CALC
		DEFB	$02		;;DELETE	; delete variable value
		DEFB	$38		;;END_CALC

					; DE (STKEND) points to start of value.

		POP	HL		; restore the pointer.
		LD	BC,$0005	; start of number is five bytes before.
		AND	A		; prepare for true subtraction.
		SBC	HL,BC		; HL points to start of value.
		JR	L_ENTER		; forward to L_ENTER  ==>


					; the jump was to here if the variable already existed.

					;;;$2B66
L_EXISTS:	BIT	6,(IY+$01)	; test FLAGS - numeric or string result ?
		JR	Z,L_DELETE	; skip forward to L_DELETE	-*->
					; if string result.

					; A numeric variable could be simple or an array element.
					; They are treated the same and the old value is overwritten.

		LD	DE,$0006	; six bytes forward points to loc past value.
		ADD	HL,DE		; add to start of number.
		JR	L_NUMERIC	; back to L_NUMERIC to overwrite value.

					; -*-> the branch was here if a string existed.

					;;;$2B72
L_DELETE:	LD	HL,(DEST)	; fetch DEST to HL.
					; (still set from first instruction)
		LD	BC,(STRLEN)	; fetch STRLEN to BC.
		BIT	0,(IY+$37)	; test FLAGX - handling a complete simple string ?
		JR	NZ,L_ADD	; forward to L_ADD if so.

					; must be a string array or a slice in workspace.
					; Note. LET a$(3 TO 6) = h$	will assign "hat " if h$ = "hat"
					; and	"hats" if h$ = "hatstand".

					; This is known as Procrustian lengthening and shortening after a
					; character Procrustes in Greek legend who made travellers sleep in his bed,
					; cutting off their feet or stretching them so they fitted the bed perfectly.
					; The bloke was hatstand and slain by Theseus.

		LD	A,B		; test if length
		OR	C		; is zero and
		RET	Z		; return if so.

		PUSH	HL		; save pointer to start.
		RST	30H		; BC_SPACES creates room.
		PUSH	DE		; save pointer to first new location.
		PUSH	BC		; and length		(*)
		LD	D,H		; set DE to point to last location.
		LD	E,L
		INC	HL		; set HL to next location.
		LD	(HL),$20	; place a space there.
		LDDR			; copy bytes filling with spaces.
		PUSH	HL		; save pointer to start.
		CALL	STK_FETCH	; routine STK_FETCH start to DE, length to BC.
		POP	HL		; restore the pointer.
		EX	(SP),HL		; (*) length to HL, pointer to stack.
		AND	A		; prepare for true subtraction.
		SBC	HL,BC		; subtract old length from new.
		ADD	HL,BC		; and add back.
		JR	NC,L_LENGTH	; forward if it fits to L_LENGTH.

		LD	B,H		; otherwise set
		LD	C,L		; length to old length.
					; "hatstand" becomes "hats"

					;;;$2B9B
L_LENGTH:	EX	(SP),HL		; (*) length to stack, pointer to HL.
		EX	DE,HL		; pointer to DE, start of string to HL.
		LD	A,B		; is the length zero ?
		OR	C		;
		JR	Z,L_IN_W_S	; forward to L_IN_W_S if so
					; leaving prepared spaces.
		LDIR			; else copy bytes overwriting some spaces.

					;;;$2BA3
L_IN_W_S:	POP	BC		; pop the new length.  (*)
		POP	DE		; pop pointer to new area.
		POP	HL		; pop pointer to variable in assignment.
					; and continue copying from workspace
					; to variables area.

					; ==> branch here from  L_NUMERIC

					;;;$2BA6
L_ENTER:	EX	DE,HL		; exchange pointers HL=STKEND DE=end of vars.
		LD	A,B		; test the length
		OR	C		; and make a 
		RET	Z		; return if zero (strings only).

		PUSH	DE		; save start of destination.
		LDIR			; copy bytes.
		POP	HL		; address the start.
		RET			; and return.

					; the branch was here from L_DELETE if an existing simple string.
					; register HL addresses start of string in variables area.

					;;;$2BAF
L_ADD:		DEC	HL		; point to high byte of length.
		DEC	HL		; to low byte.
		DEC	HL		; to letter.
		LD	A,(HL)		; fetch masked letter to A.
		PUSH	HL		; save the pointer on stack.
		PUSH	BC		; save new length.
		CALL	L_STRING	; routine L_STRING adds new string at end
					; of variables area.
					; if no room we still have old one.
		POP	BC		; restore length.
		POP	HL		; restore start.
		INC	BC		; increase
		INC	BC		; length by three
		INC	BC		; to include character and length bytes.
		JP	RECLAIM_2	; jump to indirect exit via RECLAIM_2
					; deleting old version and adjusting pointers.

					; the jump was here with a new string variable.

					;;;$2BC0
L_NEW:		LD	A,$DF		; indicator mask %11011111 for
					;		 %010xxxxx will be result
		LD	HL,(DEST)	; address DEST first character.
		AND	(HL)		; combine mask with character.

					;;;$2BC6
L_STRING:	PUSH	AF		; save first character and mask.
		CALL	STK_FETCH	; routine STK_FETCH fetches parameters of the string.
		EX	DE,HL		; transfer start to HL.
		ADD	HL,BC		; add to length.
		PUSH	BC		; save the length.
		DEC	HL		; point to end of string.
		LD	(DEST),HL	; save pointer in DEST.
					; (updated by POINTERS if in workspace)
		INC	BC		; extra byte for letter.
		INC	BC		; two bytes
		INC	BC		; for the length of string.
		LD	HL,(E_LINE)	; address E_LINE.
		DEC	HL		; now end of VARS area.
		CALL	MAKE_ROOM	; routine MAKE_ROOM makes room for string.
					; updating pointers including DEST.
		LD	HL,(DEST)	; pick up pointer to end of string from DEST.
		POP	BC		; restore length from stack.
		PUSH	BC		; and save again on stack.
		INC	BC		; add a byte.
		LDDR			; copy bytes from end to start.
		EX	DE,HL		; HL addresses length low
		INC	HL		; increase to address high byte
		POP	BC		; restore length to BC
		LD	(HL),B		; insert high byte
		DEC	HL		; address low byte location
		LD	(HL),C		; insert that byte
		POP	AF		; restore character and mask

					;;;$2BEA
L_FIRST:	DEC	HL		; address variable name
		LD	(HL),A		; and insert character.
		LD	HL,(E_LINE)	; load HL with E_LINE.
		DEC	HL		; now end of VARS area.
		RET			; return

;-------------------------------------
; Get last value from calculator stack
;-------------------------------------

					;;;$2BF1
STK_FETCH:	LD	HL,(STKEND)	; STKEND
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
		LD	(STKEND),HL	; STKEND
		RET

;-------------------
; Handle DIM command
;-------------------
; e.g. DIM a(2,3,4,7): DIM a$(32) : DIM b$(300,2,768) : DIM c$(20000)
; the only limit to dimensions is memory so, for example,
; DIM a(2,2,2,2,2,2,2,2,2,2,2,2,2) is possible and creates a multi-
; dimensional array of zeros. String arrays are initialized to spaces.
; It is not possible to erase an array, but it can be re-dimensioned to
; a minimal size of 1, after use, to free up memory.

					;;;$2C02
DIM:		CALL	LOOK_VARS	; routine LOOK_VARS

					;;;$2C05
D_RPORT_C:	JP	NZ,REPORT_C	; jump to REPORT_C if a long-name variable.
					; DIM lottery numbers(49) doesn't work.

		CALL	SYNTAX_Z	; routine SYNTAX_Z
		JR	NZ,D_RUN	; forward to D_RUN in runtime.

		RES	6,C		; signal 'numeric' array even if string as
					; this simplifies the syntax checking.
		CALL	STK_VAR		; routine STK_VAR checks syntax.
		CALL	CHECK_END	; routine CHECK_END performs early exit ->

					; the branch was here in runtime.

					;;;$2C15
D_RUN:		JR	C,D_LETTER	; skip to D_LETTER if variable did not exist.
					; else reclaim the old one.
		PUSH	BC		; save type in C.
		CALL	NEXT_ONE	; routine NEXT_ONE find following variable
					; or position of $80 end-marker.
		CALL	RECLAIM_2	; routine RECLAIM_2 reclaims the  space between.
		POP	BC		; pop the type.

					;;;$2C1F
D_LETTER:	SET	7,C		; signal array.
		LD	B,$00		; initialize dimensions to zero and
		PUSH	BC		; save with the type.
		LD	HL,$0001	; make elements one character presuming string
		BIT	6,C		; is it a string ?
		JR	NZ,D_SIZE	; forward to D_SIZE if so.

		LD	L,$05		; make elements 5 bytes as is numeric.

					;;;$2C2D
D_SIZE:		EX	DE,HL		; save the element size in DE.

					; now enter a loop to parse each of the integers in the list.

					;;;$2C2E
D_NO_LOOP:	RST	20H		; NEXT_CHAR
		LD	H,$FF		; disable limit check by setting HL high
		CALL	INT_EXP1	; routine INT_EXP1
		JP	C,REPORT_3	; to REPORT_3 if > 65280 and then some
					; 'Subscript out of range'
		POP	HL		; pop dimension counter, array type
		PUSH	BC		; save dimension size			***
		INC	H		; increment the dimension counter
		PUSH	HL		; save the dimension counter
		LD	H,B		; transfer size
		LD	L,C		; to HL
		CALL	GET_HL_DE	; routine GET_HL_DE multiplies dimension by
					; running total of size required initially
					; 1 or 5.
		EX	DE,HL		; save running total in DE
		RST	18H		; GET_CHAR
		CP	$2C		; is it ',' ?
		JR	Z,D_NO_LOOP	; loop back to D_NO_LOOP until all dimensions
					; have been considered

					; when loop complete continue.

		CP	$29		; is it ')' ?
		JR	NZ,D_RPORT_C	; to D_RPORT_C with anything else
					; 'Nonsense in basic'


		RST	20H		; NEXT_CHAR advances to next statement/CR
		POP	BC		; pop dimension counter/type
		LD	A,C		; type to A

					; now calculate space required for array variable

		LD	L,B		; dimensions to L since these require 16 bits
					; then this value will be doubled
		LD	H,$00		; set high byte to zero

					; another four bytes are required for letter(1), total length(2), number of
					; dimensions(1) but since we have yet to double allow for two

		INC	HL		; increment
		INC	HL		; increment
		ADD	HL,HL		; now double giving 4 + dimensions * 2
		ADD	HL,DE		; add to space required for array contents
		JP	C,REPORT_4	; to REPORT_4 if > 65535
					; 'Out of memory'
		PUSH	DE		; save data space
		PUSH	BC		; save dimensions/type
		PUSH	HL		; save total space
		LD	B,H		; total space
		LD	C,L		; to BC
		LD	HL,(E_LINE)	; address E_LINE - first location after variables area
		DEC	HL		; point to location before - the $80 end-marker
		CALL	MAKE_ROOM	; routine MAKE_ROOM creates the space if memory is available.
		INC	HL		; point to first new location and
		LD	(HL),A		; store letter/type
		POP	BC		; pop total space
		DEC	BC		; exclude name
		DEC	BC		; exclude the 16-bit
		DEC	BC		; counter itself
		INC	HL		; point to next location the 16-bit counter
		LD	(HL),C		; insert low byte
		INC	HL		; address next
		LD	(HL),B		; insert high byte
		POP	BC		; pop the number of dimensions.
		LD	A,B		; dimensions to A
		INC	HL		; address next
		LD	(HL),A		; and insert "No. of dims"
		LD	H,D		; transfer DE space + 1 from MAKE_ROOM
		LD	L,E		; to HL
		DEC	DE		; set DE to next location down.
		LD	(HL),$00	; presume numeric and insert a zero
		BIT	6,C		; test bit 6 of C. numeric or string ?
		JR	Z,DIM_CLEAR	; skip to DIM_CLEAR if numeric

		LD	(HL),$20	; place a space character in HL

					;;;$2C7C
DIM_CLEAR:	POP	BC		; pop the data length
		LDDR			; LDDR sets to zeros or spaces

					; The number of dimensions is still in A.
					; A loop is now entered to insert the size of each dimension that was pushed
					; during the D_NO_LOOP working downwards from position before start of data.

					;;;$2C7F
DIM_SIZES:	POP	BC		; pop a dimension size			***
		LD	(HL),B		; insert high byte at position
		DEC	HL		; next location down
		LD	(HL),C		; insert low byte
		DEC	HL		; next location down
		DEC	A		; decrement dimension counter
		JR	NZ,DIM_SIZES	; back to DIM_SIZES until all done.

		RET			; return.

;------------------------------
; Check whether digit or letter
;------------------------------
; This routine checks that the character in A is alphanumeric
; returning with carry set if so.

					;;;$2C88
ALPHANUM:	CALL	NUMERIC		; routine NUMERIC will reset carry if so.
		CCF			; Complement Carry Flag
		RET	C		; Return if numeric else continue into next routine.

					; This routine checks that the character in A is alphabetic

					;;;$2C8D
ALPHA:		CP	$41		; less than 'A' ?
		CCF			; Complement Carry Flag
		RET	NC		; return if so

		CP	$5B		; less than 'Z'+1 ?
		RET	C		; is within first range

		CP	$61		; less than 'a' ?
		CCF			; Complement Carry Flag
		RET	NC		; return if so.

		CP	$7B		; less than 'z'+1 ?
		RET			; carry set if within a-z.

;--------------------------
; Decimal to floating point
;--------------------------
; This routine finds the floating point number represented by an expression
; beginning with BIN, '.' or a digit.
; Note that BIN need not have any '0's or '1's after it.
; BIN is really just a notational symbol and not a function.

					;;;$2C9B
DEC_TO_FP:	CP	$C4		; 'BIN' token ?
		JR	NZ,NOT_BIN	; to NOT_BIN if not

		LD	DE,$0000	; initialize 16 bit buffer register.

					;;;$2CA2
BIN_DIGIT:	RST	20H		; NEXT_CHAR
		SUB	$31		; '1'
		ADC	A,$00		; will be zero if '1' or '0'
					; carry will be set if was '0'
		JR	NZ,BIN_END	; forward to BIN_END if result not zero

		EX	DE,HL		; buffer to HL
		CCF			; Carry now set if originally '1'
		ADC	HL,HL		; shift the carry into HL
		JP	C,REPORT_6	; to REPORT_6 if overflow - too many digits
					; after first '1'. There can be an unlimited
					; number of leading zeros.
					; 'Number too big' - raise an error
		EX	DE,HL		; save the buffer
		JR	BIN_DIGIT	; back to BIN_DIGIT for more digits

					;;;$2CB3
BIN_END:	LD	B,D		; transfer 16 bit buffer
		LD	C,E		; to BC register pair.
		JP	STACK_BC	; to STACK_BC to put on calculator stack

					; continue here with .1,  42, 3.14, 5., 2.3 E -4

					;;;$2CB8
NOT_BIN:	CP	$2E		; '.' - leading decimal point ?
		JR	Z,DECIMAL	; skip to DECIMAL if so.

		CALL	INT_TO_FP	; routine INT_TO_FP to evaluate all digits
					; This number 'x' is placed on stack.
		CP	$2E		; '.' - mid decimal point ?
		JR	NZ,E_FORMAT	; to E_FORMAT if not to consider that format

		RST	20H		; NEXT_CHAR
		CALL	NUMERIC		; routine NUMERIC returns carry reset if 0-9
		JR	C,E_FORMAT	; to E_FORMAT if not a digit e.g. '1.'

		JR	DEC_STO_1	; to DEC_STO_1 to add the decimal part to 'x'

					; a leading decimal point has been found in a number.

					;;;$2CCB
DECIMAL:	RST	20H		; NEXT_CHAR
		CALL	NUMERIC		; routine NUMERIC will reset carry if digit

					;;;$2CCF
DEC_RPT_C:	JP	C,REPORT_C	; to REPORT_C if just a '.'
					; raise 'Nonsense in Basic'

					; since there is no leading zero put one on the calculator stack.

		RST	28H		;; FP_CALC
		DEFB	$A0		;;STK_ZERO  	; 0.
		DEFB	$38		;;END_CALC

					; If rejoining from earlier there will be a value 'x' on stack.
					; If continuing from above the value zero.
					; Now store 1 in mem-0.
					; Note. At each pass of the digit loop this will be divided by ten.

					;;;$2CD5
DEC_STO_1:	RST	28H		;; FP_CALC
		DEFB	$A1		;;STK_ONE	;x or 0,1.
		DEFB	$C0		;;st-mem-0	;x or 0,1.
		DEFB	$02		;;DELETE	;x or 0.
		DEFB	$38		;;END_CALC

					;;;$2CDA
NXT_DGT_1:	RST	18H		; GET_CHAR
		CALL	STK_DIGIT	; routine STK_DIGIT stacks single digit 'd'
		JR	C,E_FORMAT	; exit to E_FORMAT when digits exhausted  >

		RST	28H		;; FP_CALC	;x or 0,d.	first pass.
		DEFB	$E0		;;get-mem-0	;x or 0,d,1.
		DEFB	$A4		;;STK_TEN	;x or 0,d,1,10.
		DEFB	$05		;;DIVISION	;x or 0,d,1/10.
		DEFB	$C0		;;st-mem-0	;x or 0,d,1/10.
		DEFB	$04		;;MULTIPLY	;x or 0,d/10.
		DEFB	$0F		;;ADDITION	;x or 0 + d/10.
		DEFB	$38		;;END_CALC	last value.

		RST	20H		; NEXT_CHAR  moves to next character
		JR	NXT_DGT_1	; back to NXT_DGT_1

					; although only the first pass is shown it can be seen that at each pass
					; the new less significant digit is multiplied by an increasingly smaller
					; factor (1/100, 1/1000, 1/10000 ... ) before being added to the previous
					; last value to form a new last value.

					; Finally see if an exponent has been input.

					;;;$2CEB
E_FORMAT:	CP	$45		; is character 'E' ?
		JR	Z,SIGN_FLAG	; to SIGN_FLAG if so

		CP	$65		; 'e' is acceptable as well.
		RET	NZ		; return as no exponent.

					;;;$2CF2
SIGN_FLAG:	LD	B,$FF		; initialize temporary sign byte to $FF
		RST	20H		; NEXT_CHAR
		CP	$2B		; is character '+' ?
		JR	Z,SIGN_DONE	; to SIGN_DONE

		CP	$2D		; is character '-' ?
		JR	NZ,ST_E_PART	; to ST_E_PART as no sign

		INC	B		; set sign to zero

					; now consider digits of exponent.
					; Note. incidentally this is the only occasion in Spectrum Basic when an
					; expression may not be used when a number is expected.

					;;;$2CFE
SIGN_DONE:	RST	20H		; NEXT_CHAR

					;;;$2CFF
ST_E_PART:	CALL	NUMERIC		; routine NUMERIC
		JR	C,DEC_RPT_C	; to DEC_RPT_C if not
					; raise 'Nonsense in Basic'.
		PUSH	BC		; save sign (in B)
		CALL	INT_TO_FP	; routine INT_TO_FP places exponent on stack
		CALL	FP_TO_A		; routine FP_TO_A  transfers it to A
		POP	BC		; restore sign
		JP	C,REPORT_6	; to REPORT_6 if overflow (over 255)
					; raise 'Number too big'.
		AND	A		; set flags
		JP	M,REPORT_6	; to REPORT_6 if over '127'.
					; raise 'Number too big'.
					; 127 is still way too high and it is
					; impossible to enter an exponent greater
					; than 39 from the keyboard. The error gets
					; raised later in E_TO_FP so two different
					; error messages depending how high A is.
		INC	B		; $FF to $00 or $00 to $01 - expendable now.
		JR	Z,E_FP_JUMP	; forward to E_FP_JUMP if exponent positive

		NEG			; Negate the exponent.

					;;;$2D18
E_FP_JUMP:	JP	E_TO_FP		; jump forward to E_TO_FP to assign to
					; last value x on stack x * 10 to power A
					; a relative jump would have done.

;----------------------
; Check for valid digit
;----------------------
; This routine checks that the ascii character in A is numeric
; returning with carry reset if so.

					;;;$2D1B
NUMERIC:	CP	$30		; '0'
		RET	C		; return if less than zero character.

		CP	$3A		; The upper test is '9'
		CCF			; Complement Carry Flag
		RET			; Return - carry clear if character '0' - '9'

;------------
; Stack Digit
;------------
; This subroutine is called from INT_TO_FP and DEC_TO_FP to stack a digit
; on the calculator stack.

					;;;$2D22
STK_DIGIT:	CALL	NUMERIC		; routine NUMERIC
		RET	C		; return if not numeric character

		SUB	$30		; convert from ascii to digit

;------------------
; Stack accumulator
;------------------

					;;;$2D28
STACK_A:	LD	C,A		; transfer to C
		LD	B,$00		; and make B zero

;-----------------------
; Stack BC register pair
;-----------------------

					;;;$2D2B
STACK_BC:	LD	IY,ERR_NR	; re-initialize ERR_NR
		XOR	A		; clear to signal small integer
		LD	E,A		; place in E for sign
		LD	D,C		; LSB to D
		LD	C,B		; MSB to C
		LD	B,A		; last byte not used
		CALL	STK_STORE	; routine STK_STORE
		RST	28H		;; FP_CALC
		DEFB	$38		;;END_CALC  make HL = STKEND-5

		AND	A		; clear carry
		RET			; before returning

;--------------------------
; Integer to floating point
;--------------------------
; This routine places one or more digits found in a basic line
; on the calculator stack multiplying the previous value by ten each time
; before adding in the new digit to form a last value on calculator stack.

					;;;$2D3B
INT_TO_FP:	PUSH	AF		; save first character
		RST	28H		;; FP_CALC
		DEFB	$A0		;;STK_ZERO	; v=0. initial value
		DEFB	$38		;;END_CALC

		POP	AF		; fetch first character back.

					;;;$2D40
NXT_DGT_2:	CALL	STK_DIGIT	; routine STK_DIGIT puts 0-9 on stack
		RET	C		; will return when character is not numeric >

		RST	28H		;; FP_CALC	; v, d.
		DEFB	$01		;;EXCHANGE	; d, v.
		DEFB	$A4		;;STK_TEN	; d, v, 10.
		DEFB	$04		;;MULTIPLY	; d, v*10.
		DEFB	$0F		;;ADDITION	; d + v*10 = newvalue
		DEFB	$38		;;END_CALC	; v.

		CALL	CH_ADD_1	; routine CH_ADD_1 get next character
		JR	NXT_DGT_2	; back to NXT_DGT_2 to process as a digit


;*********************************
;** Part 9. ARITHMETIC ROUTINES **
;*********************************

;---------------------------
; E-format to floating point
;---------------------------
; This subroutine is used by the PRINT_FP routine and the decimal to FP
; routines to stack a number expressed in exponent format.
; Note. Though not used by the ROM as such, it has also been set up as
; a unary calculator literal but this will not work as the accumulator
; is not available from within the calculator.

; on entry there is a value x on the calculator stack and an exponent of ten
; in A.	The required value is x + 10 ^ A

					;;;$2D4F
E_TO_FP:	RLCA			; this will set the		x.
		RRCA			; carry if bit 7 is set
		JR	NC,E_SAVE	; to E_SAVE  if positive.

		CPL			; make negative positive
		INC	A		; without altering carry.

					;;;$2D55
E_SAVE:		PUSH	AF		; save positive exp and sign in carry
		LD	HL,MEM_0	; address MEM_0
		CALL	FP_0_1		; routine FP_0_1
					; places an integer zero, if no carry,
					; else a one in mem-0 as a sign flag
		RST	28H		;; FP_CALC
		DEFB	$A4		;;STK_TEN		x, 10.
		DEFB	$38		;;END_CALC

		POP	AF		; pop the exponent.

					; now enter a loop

					;;;$2D60
E_LOOP:		SRL	A		; 0>76543210>C
		JR	NC,E_TST_END	; forward to E_TST_END if no bit

		PUSH	AF		; save shifted exponent.
		RST	28H		;; FP_CALC
		DEFB	$C1		;;st-mem-1		x, 10.
		DEFB	$E0		;;get-mem-0		x, 10, (0/1).
		DEFB	$00		;;JUMP_TRUE

		DEFB	$04		;;to E_DIVSN

		DEFB	$04		;;MULTIPLY		x*10.
		DEFB	$33		;;jump

		DEFB	$02		;;to E_FETCH

					;;;$2D6D
E_DIVSN:	DEFB	$05		;;DIVISION		x/10.

					;;;$2D6E
E_FETCH:	DEFB	$E1		;;get-mem-1		x/10 or x*10, 10.
		DEFB	$38		;;END_CALC		new x, 10.

		POP	AF		; restore shifted exponent

					; the loop branched to here with no carry

					;;;$2D71
E_TST_END:	JR	Z,E_END		; forward to E_END  if A emptied of bits
		PUSH	AF		; re-save shifted exponent
		RST	28H		;; FP_CALC
		DEFB	$31		;;DUPLICATE		new x, 10, 10.
		DEFB	$04		;;MULTIPLY		new x, 100.
		DEFB	$38		;;END_CALC

		POP	AF		; restore shifted exponent
		JR	E_LOOP		; back to E_LOOP  until all bits done.

					; although only the first pass is shown it can be seen that for each set bit
					; representing a power of two, x is multiplied or divided by the
					; corresponding power of ten.

					;;;$2D7B
E_END:		RST	28H		;; FP_CALC		final x, factor.
		DEFB	$02		;;DELETE		final x.
		DEFB	$38		;;END_CALC		x.

		RET			; return

;--------------
; Fetch integer
;--------------
; This routine is called by the mathematical routines - FP_TO_BC, PRINT_FP,
; MULTIPLY, RE_STACK and NEGATE to fetch an integer from address HL.
; HL points to the stack or a location in MEM and no deletion occurs.
; If the number is negative then a similar process to that used in INT_STORE
; is used to restore the twos complement number to normal in DE and a sign
; in C.

					;;;$2D7F
INT_FETCH:	INC	HL		; skip zero indicator.
		LD	C,(HL)		; fetch sign to C
		INC	HL		; address low byte
		LD	A,(HL)		; fetch to A
		XOR	C		; two's complement
		SUB	C
		LD	E,A		; place in E
		INC	HL		; address high byte
		LD	A,(HL)		; fetch to A
		ADC	A,C		; two's complement
		XOR	C
		LD	D,A		; place in D
		RET			; return

;-------------------------
; Store a positive integer
;-------------------------
; This entry point is not used in this ROM but would
; store any integer as positive.

					;;;$2D8C
P_INT_STO:	LD	C,$00		; make sign byte positive and continue

;--------------
; Store integer
;--------------
; this routine stores an integer in DE at address HL.
; It is called from MULTIPLY, TRUNCATE, NEGATE and SGN.
; The sign byte $00 +ve or $FF -ve is in C.
; If negative, the number is stored in 2's complement form so that it is
; ready to be added.

					;;;$2D8E
INT_STORE:	PUSH	HL		; preserve HL
		LD	(HL),$00	; first byte zero shows integer not exponent
		INC	HL
		LD	(HL),C		; then store the sign byte
		INC	HL
					; e.g.             +1             -1
		LD	A,E		; fetch low byte   00000001       00000001
		XOR	C		; xor sign         00000000   or  11111111
					; gives            00000001   or  11111110
		SUB	C		; sub sign         00000000   or  11111111
					; gives            00000001>0 or  11111111>C
		LD	(HL),A		; store 2's complement.
		INC	HL
		LD	A,D		; high byte        00000000       00000000
		ADC	A,C		; sign             00000000<0     11111111<C
					; gives            00000000   or  00000000
		XOR	C		; xor sign         00000000       11111111
		LD	(HL),A		; store 2's complement.
		INC	HL
		LD	(HL),$00	; last byte always zero for integers.
					; is not used and need not be looked at when
					; testing for zero but comes into play should
					; an integer be converted to fp.
		POP	HL		; restore HL
		RET			; return.


;------------------------------
; Floating point to BC register
;------------------------------
; This routine gets a floating point number e.g. 127.4 from the calculator
; stack to the BC register.

					;;;$2DA2
FP_TO_BC:	RST	28H		;; FP_CALC		set HL to
		DEFB	$38		;;END_CALC		point to last value.

		LD	A,(HL)		; get first of 5 bytes
		AND	A		; and test
		JR	Z,FP_DELETE	; forward to FP_DELETE if an integer

					; The value is first rounded up and then converted to integer.

		RST	28H		;; FP_CAL		x.
		DEFB	$A2		;;STK_HALF		x. 1/2.
		DEFB	$0F		;;ADDITION		x + 1/2.
		DEFB	$27		;;INT			int(x + .5)
		DEFB	$38		;;END_CALC

					; now delete but leave HL pointing at integer

					;;;$2DAD
FP_DELETE:	RST	28H		;; FP_CALC
		DEFB	$02		;;DELETE
		DEFB	$38		;;END_CALC

		PUSH	HL		; save pointer.
		PUSH	DE		; and STKEND.
		EX	DE,HL		; make HL point to exponent/zero indicator
		LD	B,(HL)		; indicator to B
		CALL	INT_FETCH	; routine INT_FETCH
					; gets int in DE sign byte to C
					; but meaningless values if a large integer
		XOR	A		; clear A
		SUB	B		; subtract indicator byte setting carry
					; if not a small integer.
		BIT	7,C		; test a bit of the sign byte setting zero
					; if positive.
		LD	B,D		; transfer int
		LD	C,E		; to BC
		LD	A,E		; low byte to A as a useful return value.
		POP	DE		; pop STKEND
		POP	HL		; and pointer to last value
		RET			; return
					; if carry is set then the number was too big.

;-------------
; LOG(2&A)
;-------------
; This routine is used when printing floating point numbers to

					;;;$2DC1
LOG_2_A:	LD	D,A
		RLA
		SBC	A,A
		LD	E,A
		LD	C,A
		XOR	A
		LD	B,A
		CALL	STK_STORE	; routine STK_STORE
		RST	28H		;; FP_CALC
		DEFB	$34		;;STK_DATA
		DEFB	$EF		;;Exponent: $7F, Bytes: 4
		DEFB	$1A,$20,$9A,$85
		DEFB	$04		;;MULTIPLY
		DEFB	$27		;;INT
		DEFB	$38		;;END_CALC

;--------------------
; Floating point to A
;--------------------
; this routine collects a floating point number from the stack into the
; accumulator returning carry set if not in range 0 - 255.
; Not all the calling routines raise an error with overflow so no attempt
; is made to produce an error report here.

					;;;$2DD5
FP_TO_A:	CALL	FP_TO_BC	; routine FP_TO_BC returns with C in A also.
		RET	C		; return with carry set if > 65535, overflow

		PUSH	AF		; save the value and flags
		DEC	B		; and test that
		INC	B		; the high byte is zero.
		JR	Z,FP_A_END	; forward  FP_A_END if zero

					; else there has been 8-bit overflow

		POP	AF		; retrieve the value
		SCF			; set carry flag to show overflow
		RET			; and return.

					;;;$2DE1
FP_A_END:	POP	AF		; restore value and success flag and
		RET			; return.


;------------------------------
; Print a floating point number
;------------------------------
; Not a trivial task.
; Begin by considering whether to print a leading sign for negative numbers.

					;;;$2DE3
PRINT_FP:	RST	28H		;; FP_CALC
		DEFB	$31		;;DUPLICATE
		DEFB	$36		;;LESS_0
		DEFB	$00		;;JUMP_TRUE

		DEFB	$0B		;;to PF_NEGTVE

		DEFB	$31		;;DUPLICATE
		DEFB	$37		;;GREATER_0
		DEFB	$00		;;JUMP_TRUE

		DEFB	$0D		;;to PF_POSTVE

					; must be zero itself

		DEFB	$02		;;DELETE
		DEFB	$38		;;END_CALC

		LD	A,$30		; prepare the character '0'
		RST	10H		; PRINT_A
		RET			; return.		->

					;;;$2DF2
PF_NEGTVE:	DEFB	$2A		;;ABS
		DEFB	$38		;;END_CALC

		LD	A,$2D		; the character '-'
		RST	10H		; PRINT_A

					; and continue to print the now positive number.

		RST	28H		;; FP_CALC

					;;;$2DF8
PF_POSTVE:	DEFB	$A0		;;STK_ZERO	x,0.	begin by
		DEFB	$C3		;;st-mem-3	x,0.	clearing a temporary
		DEFB	$C4		;;st-mem-4	x,0.	output buffer to
		DEFB	$C5		;;st-mem-5	x,0.	fifteen zeros.
		DEFB	$02		;;DELETE	x.
		DEFB	$38		;;END_CALC	x.

		EXX			; in case called from 'STR$' then save the
		PUSH	HL		; pointer to whatever comes after
		EXX			; STR$ as H'L' will be used.

					; now enter a loop?

					;;;$2E01
PF_LOOP:	RST	28H		;; FP_CALC
		DEFB	$31		;;DUPLICATE	x,x.
		DEFB	$27		;;INT		x,int x.
		DEFB	$C2		;;st-mem-2	x,int x.
		DEFB	$03		;;SUBTRACT	x-int x.	fractional part.
		DEFB	$E2		;;get-mem-2	x-int x, int x.
		DEFB	$01		;;EXCHANGE	int x, x-int x.
		DEFB	$C2		;;st-mem-2	int x, x-int x.
		DEFB	$02		;;DELETE	int x.
		DEFB	$38		;;END_CALC	int x.
					;
					; mem-2 holds the fractional part.

					; HL points to last value int x

		LD	A,(HL)		; fetch exponent of int x.
		AND	A		; test
		JR	NZ,PF_LARGE	; forward to PF_LARGE if a large integer
					; > 65535

					; continue with small positive integer components in range 0 - 65535 
					; if original number was say .999 then this integer component is zero. 

		CALL	INT_FETCH	; routine INT_FETCH gets x in DE
					; (but x is not deleted)
		LD	B,$10		; set B, bit counter, to 16d
		LD	A,D		; test if
		AND	A		; high byte is zero
		JR	NZ,PF_SAVE	; forward to PF_SAVE if 16-bit integer.

					; and continue with integer in range 0 - 255.

		OR	E		; test the low byte for zero
					; i.e. originally just point something or other.
		JR	Z,PF_SMALL	; forward if so to PF_SMALL  

		LD	D,E		; transfer E to D
		LD	B,$08		; and reduce the bit counter to 8.

					;;;$2E1E
PF_SAVE:	PUSH	DE		; save the part before decimal point.
		EXX
		POP	DE		; and pop in into D'E'
		EXX
		JR	PF_BITS		; forward to PF_BITS

					; the branch was here when 'int x' was found to be zero as in say 0.5.
					; The zero has been fetched from the calculator stack but not deleted and
					; this should occur now. This omission leaves the stack unbalanced and while
					; that causes no problems with a simple PRINT statement, it will if STR$ is
					; being used in an expression e.g. "2" + STR$ 0.5 gives the result "0.5"
					; instead of the expected result "20.5".
					; credit Tony Stratton, 1982.
					; A DEFB 02 delete is required immediately on using the calculator.

					;;;$2E24
PF_SMALL:	RST	28H		;; FP_CALC	int x = 0.
L2E25:		DEFB	$E2		;;get-mem-2	int x = 0, x-int x.
		DEFB	$38		;;END_CALC

		LD	A,(HL)		; fetch exponent of positive fractional number
		SUB	$7E		; subtract 
		CALL	LOG_2_A		; routine LOG_2_A calculates leading digits.
		LD	D,A		; transfer count to D
		LD	A,(MEM_5_1)	; fetch total digits - MEM_5 2nd byte
		SUB	D
		LD	(MEM_5_1),A	; store MEM_5 2nd byte
		LD	A,D
		CALL	E_TO_FP		; routine E_TO_FP
		RST	28H		;; FP_CALC
		DEFB	$31		;;DUPLICATE
		DEFB	$27		;;INT
		DEFB	$C1		;;st-mem-1
		DEFB	$03		;;SUBTRACT
		DEFB	$E1		;;get-mem-1
		DEFB	$38		;;END_CALC

		CALL	FP_TO_A		; routine FP_TO_A
		PUSH	HL		; save HL
		LD	(MEM_3),A	; MEM_3 1st byte
		DEC	A
		RLA
		SBC	A,A
		INC	A
		LD	HL,MEM_5_0	; address MEM_5 leading digit counter
		LD	(HL),A		; store counter
		INC	HL		; address MEM_5 2nd byte - total digits
		ADD	A,(HL)		; add counter to contents
		LD	(HL),A		; and store updated value
		POP	HL		; restore HL
		JP	PF_FRACTN	; jump forward to PF_FRACTN

					; Note. while it would be pedantic to comment on every occasion a JP
					; instruction could be replaced with a JR instruction, this applies to the
					; above, which is useful if you wish to correct the unbalanced stack error
					; by inserting a 'DEFB 02 delete' at L2E25, and maintain main addresses.

					; the branch was here with a large positive integer > 65535 e.g. 123456789
					; the accumulator holds the exponent.

					;;;$2E56
PF_LARGE:	SUB	$80		; make exponent positive
		CP	$1C		; compare to 28
		JR	C,PF_MEDIUM	; to PF_MEDIUM if integer <= 2^27

		CALL	LOG_2_A		; routine LOG_2_A
		SUB	$07
		LD	B,A
		LD	HL,MEM_5_1	; address MEM_5_1 the leading digits counter.
		ADD	A,(HL)		; add A to contents
		LD	(HL),A		; store updated value.
		LD	A,B
		NEG			; negate
		CALL	E_TO_FP		; routine E_TO_FP
		JR	PF_LOOP		; back to PF_LOOP

					;;;$2E6F
PF_MEDIUM:	EX	DE,HL
		CALL	FETCH_TWO	; routine FETCH_TWO
		EXX
		SET	7,D
		LD	A,L
		EXX
		SUB	$80
		LD	B,A

					; the branch was here to handle bits in DE with 8 or 16 in B  if small int
					; and integer in D'E', 6 nibbles will accommodate 065535 but routine does
					; 32-bit numbers as well from above

					;;;$2E7B
PF_BITS:	SLA	E		;  C<xxxxxxxx<0
		RL	D		;  C<xxxxxxxx<C
		EXX
		RL	E		;  C<xxxxxxxx<C
		RL	D		;  C<xxxxxxxx<C
		EXX
		LD	HL,MEM_4_4	; set HL to MEM_4 5th last byte of buffer
		LD	C,$05		; set byte count to 5 - 10 nibbles

					;;;$2E8A
PF_BYTES:	LD	A,(HL)		; fetch 0 or prev value
		ADC	A,A		; shift left add in carry	C<xxxxxxxx<C
		DAA			; Decimal Adjust Accumulator.
					; if greater than 9 then the left hand
					; nibble is incremented. If greater than
					; 99 then adjusted and carry set.
					; so if we'd built up 7 and a carry came in
					;	0000 0111 < C
					;	0000 1111
					; daa	1 0101  which is 15 in BCD
		LD	(HL),A		; put back
		DEC	HL		; work down thru mem 4
		DEC	C		; decrease the 5 counter.
		JR	NZ,PF_BYTES	; back to PF_BYTES until the ten nibbles rolled

		DJNZ	PF_BITS		; back to PF_BITS until 8 or 16 (or 32) done

					; at most 9 digits for 32-bit number will have been loaded with digits
					; each of the 9 nibbles in mem 4 is placed into ten bytes in mem-3 and mem 4
					; unless the nibble is zero as the buffer is already zero.
					; ( or in the case of mem-5 will become zero as a result of RLD instruction )

		XOR	A		; clear to accept
		LD	HL,MEM_4	; address MEM_4 byte destination.
		LD	DE,MEM_3	; address MEM_3 nibble source.
		LD	B,$09		; the count is 9 (not ten) as the first 
					; nibble is known to be blank.
		RLD			; shift RH nibble to left in (HL)
					;	A		(HL)
					; 0000 0000 < 0000 3210
					; 0000 0000	3210 0000
					; A picks up the blank nibble
		LD	C,$FF		; set a flag to indicate when a significant
					; digit has been encountered.

					;;;$2EA1
PF_DIGITS:	RLD			; pick up leftmost nibble from (HL)
					;    A           (HL)
					; 0000 0000 < 7654 3210
					; 0000 7654   3210 0000
		JR	NZ,PF_INSERT	; to PF_INSERT if non-zero value picked up.

		DEC	C		; test
		INC	C		; flag
		JR	NZ,PF_TEST_2	; skip forward to PF_TEST_2 if flag still $FF
					; indicating this is a leading zero.

					; but if the zero is a significant digit e.g. 10 then include in digit totals.
					; the path for non-zero digits rejoins here.

					;;;$2EA9
PF_INSERT:	LD	(DE),A		; insert digit at destination
		INC	DE		; increase the destination pointer
		INC	(IY+$71)	; increment MEM_5 1st  digit counter
		INC	(IY+$72)	; increment MEM_5 2nd  leading digit counter
		LD	C,$00		; set flag to zero indicating that any 
					; subsequent zeros are significant and not leading.

					;;;$L2EB3
PF_TEST_2:	BIT	0,B		; test if the nibble count is even
		JR	Z,PF_ALL_9	; skip to PF_ALL_9 if so to deal with the other nibble in the same byte

		INC	HL		; point to next source byte if not

					;;;$2EB8
PF_ALL_9:	DJNZ	PF_DIGITS	; decrement the nibble count, back to PF_DIGITS
					; if all nine not done.

					; For 8-bit integers there will be at most 3 digits.
					; For 16-bit integers there will be at most 5 digits. 
					; but for larger integers there could be nine leading digits.
					; if nine digits complete then the last one is rounded up as the number will
					; be printed using E-format notation
		LD	A,(MEM_5_0)	; fetch digit count from MEM_5 1st
		SUB	$09		; subtract 9 - max possible
		JR	C,PF_MORE	; forward if less to PF_MORE

		DEC	(IY+$71)	; decrement digit counter MEM_5 1st to 8
		LD	A,$04		; load A with the value 4.
		CP	(IY+$6F)	; compare with MEM_4 4th - the ninth digit
		JR	PF_ROUND	; forward to PF_ROUND
					; to consider rounding.

 					; now delete int x from calculator stack and fetch fractional part.

					;;;$2ECB
PF_MORE:	RST	28H		;; FP_CALC	int x.
		DEFB	$02		;;DELETE	.
		DEFB	$E2		;;get-mem-2	x - int x = f.
		DEFB	$38		;;end-calca	f.

					;;;$2ECF
PF_FRACTN:	EX	DE,HL
		CALL	FETCH_TWO	; routine FETCH_TWO
		EXX
		LD	A,$80
		SUB	L
		LD	L,$00
		SET	7,D
		EXX
		CALL	SHIFT_FP	; routine SHIFT_FP

					;;;$2EDF
PF_FRN_LP:	LD	A,(IY+$71)	; MEM_5 1st
		CP	$08
		JR	C,PF_FR_DGT	; to PF_FR_DGT

		EXX
		RL	D
		EXX
		JR	PF_ROUND	; to PF_ROUND

					;;;$2EEC
PF_FR_DGT:	LD	BC,$0200

					;;;$2EEF
PF_FR_EXX:	LD	A,E
		CALL	CA_10_A_C	; routine CA_10_A_C
		LD	E,A
		LD	A,D
		CALL	CA_10_A_C	; routine CA_10_A_C
		LD	D,A
		PUSH	BC
		EXX
		POP	BC
		DJNZ	PF_FR_EXX	; to PF_FR_EXX
		LD	HL,MEM_3	; MEM-3
		LD	A,C
		LD	C,(IY+$71)	; MEM_5 1st
		ADD	HL,BC
		LD	(HL),A
		INC	(IY+$71)	; MEM_5 1st
		JR	PF_FRN_LP	; to PF_FRN_LP


					; 1) with 9 digits but 8 in MEM_5_1 and A holding 4, carry set if rounding up.
					; e.g. 
					;	999999999 is printed as 1E+9
					;	100000001 is printed as 1E+8
					;	100000009 is printed as 1.0000001E+8

					;;;$2F0C
PF_ROUND:	PUSH	AF		; save A and flags
		LD	HL,MEM_3	; address MEM_3 start of digits
		LD	C,(IY+$71)	; MEM_5 1st No. of digits to C
		LD	B,$00		; prepare to add
		ADD	HL,BC		; address last digit + 1
		LD	B,C		; No. of digits to B counter
		POP	AF		; restore A and carry flag from comparison.

					;;;$2F18
PF_RND_LP:	DEC	HL		; address digit at rounding position.
		LD	A,(HL)		; fetch it
		ADC	A,$00		; add carry from the comparison
		LD	(HL),A		; put back result even if $0A.
		AND	A		; test A
		JR	Z,PF_R_BACK	; skip to PF_R_BACK if ZERO?

		CP	$0A		; compare to 'ten' - overflow
		CCF			; complement carry flag so that set if ten.
		JR	NC,PF_COUNT	; forward to PF_COUNT with 1 - 9.

					;;;$2F25
PF_R_BACK:	DJNZ	PF_RND_LP	; loop back to PF_RND_LP

					; if B counts down to zero then we've rounded right back as in 999999995.
					; and the first 8 locations all hold $0A.


		LD	(HL),$01	; load first location with digit 1.
		INC	B		; make B hold 1 also.
					; could save an instruction byte here.
		INC	(IY+$72)	; make MEM-5-2nd hold 1.
					; and proceed to initialize total digits to 1.

					;;;$2F2D
PF_COUNT:	LD	(IY+$71),B	; MEM_5 1st

					; now balance the calculator stack by deleting  it

		RST	28H		;; FP_CALC
		DEFB	$02		;;DELETE
		DEFB	$38		;;END_CALC

					; note if used from STR$ then other values may be on the calculator stack.
					; we can also restore the next literal pointer from it's position on the
					; machine stack.

		EXX
		POP	HL		; restore next literal pointer.
		EXX
		LD	BC,(MEM_5_0)	; set C to MEM_5 1st digit counter.
					; set B to MEM_5 2nd leading digit counter.
		LD	HL,MEM_3	; set HL to start of digits at MEM_3
		LD	A,B
		CP	$09
		JR	C,PF_NOT_E	; to PF_NOT_E

		CP	$FC		;
		JR	C,PF_E_FRMT	; to PF_E_FRMT

					;;;$2F46
PF_NOT_E:	AND	A		; test for zero leading digits as in .123
		CALL	Z,OUT_CODE	; routine OUT_CODE prints a zero e.g. 0.123

					;;;$2F4A
PF_E_SBRN:	XOR	A
		SUB	B
		JP	M,PF_OUT_LP	; skip forward to PF_OUT_LP if originally +ve

		LD	B,A		; else negative count now +ve
		JR	PF_DC_OUT	; forward to PF_DC_OUT	->

					;;;$2F52
PF_OUT_LP:	LD	A,C		; fetch total digit count
		AND	A		; test for zero
		JR	Z,PF_OUT_DT	; forward to PF_OUT_DT if so

		LD	A,(HL)		; fetch digit
		INC	HL		; address next digit
		DEC	C		; decrease total digit counter

					;;;$2F59
PF_OUT_DT:	CALL	OUT_CODE	; routine OUT_CODE outputs it.
		DJNZ	PF_OUT_LP	; loop back to PF_OUT_LP until B leading digits output.

					;;;$2F5E
PF_DC_OUT:	LD	A,C		; fetch total digits and
		AND	A		; test if also zero
		RET	Z		; return if so			-->

		INC	B		; increment B
		LD	A,$2E		; prepare the character '.'

					;;;$L2F64
PF_DEC_0:	RST	10H		; PRINT_A outputs the character '.' or '0'
		LD	A,$30		; prepare the character '0'
					; (for cases like .000012345678)
		DJNZ	PF_DEC_0	; loop back to PF_DEC_0 for B times.
		LD	B,C		; load B with now trailing digit counter.
		JR	PF_OUT_LP	; back to PF_OUT_LP

					; the branch was here for E-format printing e.g 123456789 => 1.2345679e+8

					;;;$2F6C
PF_E_FRMT:	LD	D,B		; counter to D
		DEC	D		; decrement
		LD	B,$01		; load B with 1.
		CALL	PF_E_SBRN	; routine PF_E_SBRN above
		LD	A,$45		; prepare character 'e'
		RST	10H		; PRINT_A
		LD	C,D		; exponent to C
		LD	A,C		; and to A
		AND	A		; test exponent
		JP	P,PF_E_POS	; to PF_E_POS if positive

		NEG			; negate
		LD	C,A		; positive exponent to C
		LD	A,$2D		; prepare character '-'
		JR	PF_E_SIGN	; skip to PF_E_SIGN

					;;;$2F83
PF_E_POS:	LD	A,$2B		; prepare character '+'

					;;;$2F85
PF_E_SIGN:	RST	10H		; PRINT_A outputs the sign
		LD	B,$00		; make the high byte zero.
		JP	OUT_NUM_1	; exit via OUT_NUM_1 to print exponent in BC

;-------------------------------
; Handle printing floating point
;-------------------------------
; This subroutine is called twice from above when printing floating-point
; numbers. It returns 10*A +C in registers C and A

					;;;$2F8B
					; CA-10*A+C
CA_10_A_C:	PUSH	DE		; preserve DE.
		LD	L,A		; transfer A to L
		LD	H,$00		; zero high byte.
		LD	E,L		; copy HL
		LD	D,H		; to DE.
		ADD	HL,HL		; double (*2)
		ADD	HL,HL		; double (*4)
		ADD	HL,DE		; add DE (*5)
		ADD	HL,HL		; double (*10)
		LD	E,C		; copy C to E	(D is 0)
		ADD	HL,DE		; and add to give required result.
		LD	C,H		; transfer to
		LD	A,L		; destination registers.
		POP	DE		; restore DE
		RET			; return with result.

;---------------
; Prepare to add
;---------------
; This routine is called twice by addition to prepare the two numbers. The
; exponent is picked up in A and the location made zero. Then the sign bit
; is tested before being set to the implied state. Negative numbers are twos
; complemented.

					;;;$2F9B
PREP_ADD:	LD	A,(HL)		; pick up exponent
		LD	(HL),$00	; make location zero
		AND	A		; test if number is zero
		RET	Z		; return if so

		INC	HL		; address mantissa
		BIT	7,(HL)		; test the sign bit
		SET	7,(HL)		; set it to implied state
		DEC	HL		; point to exponent
		RET	Z		; return if positive number.

		PUSH	BC		; preserve BC
		LD	BC,$0005	; length of number
		ADD	HL,BC		; point HL past end
		LD	B,C		; set B to 5 counter
		LD	C,A		; store exponent in C
		SCF			; set carry flag

					;;;$2FAF
NEG_BYTE:	DEC	HL		; work from LSB to MSB
		LD	A,(HL)		; fetch byte
		CPL			; complement
		ADC	A,$00		; add in initial carry or from prev operation
		LD	(HL),A		; put back
		DJNZ	NEG_BYTE	; loop to NEG_BYTE till all 5 done
		LD	A,C		; stored exponent to A
		POP	BC		; restore original BC
		RET			; return

;------------------
; Fetch two numbers
;------------------
; This routine is called twice when printing floating point numbers and also
; to fetch two numbers by the addition, multiply and division routines.
; HL addresses the first number, DE addresses the second number.
; For arithmetic only, A holds the sign of the result which is stored in
; the second location. 

					;;;$2FBA
FETCH_TWO:	PUSH	HL		; save pointer to first number, result if math.
		PUSH	AF		; save result sign.
		LD	C,(HL)
		INC	HL
		LD	B,(HL)
		LD	(HL),A		; store the sign at correct location in 
					; destination 5 bytes for arithmetic only.
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
		POP	AF		; restore possible result sign.
		POP	HL		; and pointer to possible result.
		RET			; return.

;----------------------------------
; Shift floating point number right
;----------------------------------

					;;;$2FDD
SHIFT_FP:	AND	A
		RET	Z

		CP	$21
		JR	NC,ADDEND_0	; to ADDEND_0

		PUSH	BC
		LD	B,A

					;;;$2FE5
ONE_SHIFT:	EXX
		SRA	L
		RR	D
		RR	E
		EXX
		RR	D
		RR	E
		DJNZ	ONE_SHIFT	; to ONE_SHIFT
		POP	BC
		RET	NC

		CALL	ADD_BACK	; routine ADD_BACK
		RET	NZ

					;;;$2FF9
ADDEND_0:	EXX
		XOR	A

					;;;$2FFB
ZEROS_4_5:	LD	L,$00
		LD	D,A
		LD	E,L
		EXX
		LD	DE,$0000
		RET

;-------------------
; Add back any carry
;-------------------

					;;;$3004
ADD_BACK:	INC	E
		RET	NZ

		INC	D
		RET	NZ

		EXX
		INC	E
		JR	NZ,ALL_ADDED	; to ALL_ADDED

		INC	D

					;;;$300D
ALL_ADDED:	EXX
		RET

;-------------------------
; Handle subtraction ($03)
;-------------------------
; Subtraction is done by switching the sign byte/bit of the second number
; which may be integer of floating point and continuing into addition.

					;;;$300F
SUBTRACT:	EX	DE,HL		; address second number with HL
		CALL	NEGATE		; routine NEGATE switches sign
		EX	DE,HL		; address first number again
					; and continue.

;----------------------
; Handle addition ($0F)
;----------------------
; HL points to first number, DE to second.
; If they are both integers, then go for the easy route.

					;; ADDITION
ADDITION:	LD	A,(DE)		; fetch first byte of second
		OR	(HL)		; combine with first byte of first
		JR	NZ,FULL_ADDN	; forward to FULL_ADDN if at least one was
					; in floating point form.

					; continue if both were small integers.

		PUSH	DE		; save pointer to lowest number for result.
		INC	HL		; address sign byte and
		PUSH	HL		; push the pointer.
		INC	HL		; address low byte
		LD	E,(HL)		; to E
		INC	HL		; address high byte
		LD	D,(HL)		; to D
		INC	HL		; address unused byte
		INC	HL		; address known zero indicator of 1st number
		INC	HL		; address sign byte
		LD	A,(HL)		; sign to A, $00 or $FF
		INC	HL		; address low byte
		LD	C,(HL)		; to C
		INC	HL		; address high byte
		LD	B,(HL)		; to B
		POP	HL		; pop result sign pointer
		EX	DE,HL		; integer to HL
		ADD	HL,BC		; add to the other one in BC
					; setting carry if overflow.
		EX	DE,HL		; save result in DE bringing back sign pointer
		ADC	A,(HL)		; if pos/pos A=01 with overflow else 00
					; if neg/neg A=FF with overflow else FE
					; if mixture A=00 with overflow else FF
		RRCA			; bit 0 to (C)
		ADC	A,$00		; both acceptable signs now zero
		JR	NZ,ADDN_OFLW	; forward to ADDN_OFLW if not

		SBC	A,A		; restore a negative result sign
		LD	(HL),A
		INC	HL
		LD	(HL),E
		INC	HL
		LD	(HL),D
		DEC	HL
		DEC	HL
		DEC	HL
		POP	DE		; STKEND
		RET

					;;;$303C
ADDN_OFLW:	DEC	HL
		POP	DE

					;;;$303E
FULL_ADDN:	CALL	RE_ST_TWO	; routine RE_ST_TWO
		EXX
		PUSH	HL
		EXX
		PUSH	DE
		PUSH	HL
		CALL	PREP_ADD	; routine PREP_ADD
		LD	B,A
		EX	DE,HL
		CALL	PREP_ADD	; routine PREP_ADD
		LD	C,A
		CP	B
		JR	NC,SHIFT_LEN	; to SHIFT_LEN

		LD	A,B
		LD	B,C
		EX	DE,HL

					;;;$3055
SHIFT_LEN:	PUSH	AF
		SUB	B
		CALL	FETCH_TWO	; routine FETCH_TWO
		CALL	SHIFT_FP	; routine SHIFT_FP
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
		JR	NC,TEST_NEG	; to TEST_NEG

		LD	A,$01
		CALL	SHIFT_FP	; routine SHIFT_FP
		INC	(HL)
		JR	Z,ADD_REP_6	; to ADD_REP_6

					;;;$307C
TEST_NEG:	EXX
		LD	A,L
		AND	$80
		EXX
		INC	HL
		LD	(HL),A
		DEC	HL
		JR	Z,GO_NC_MLT	; to GO_NC_MLT

		LD	A,E
		NEG			; Negate
		CCF			; Complement Carry Flag
		LD	E,A
		LD	A,D
		CPL
		ADC	A,$00
		LD	D,A
		EXX
		LD	A,E
		CPL
		ADC	A,$00
		LD	E,A
		LD	A,D
		CPL
		ADC	A,$00
		JR	NC,END_COMPL	; to END_COMPL

		RRA
		EXX
		INC	(HL)

					;;;$309F
ADD_REP_6:	JP	Z,REPORT_6	; to REPORT_6

		EXX

					;;;$30A3
END_COMPL:	LD	D,A
		EXX

					;;;$30A5
GO_NC_MLT:	XOR	A
		JP	TEST_NORM	; to TEST_NORM

;------------------------------
; Used in 16 bit multiplication
;------------------------------
; This routine is used, in the first instance, by the multiply calculator
; literal to perform an integer multiplication in preference to
; 32-bit multiplication to which it will resort if this overflows.
;
; It is also used by STK_VAR to calculate array subscripts and by DIM to
; calculate the space required for multi-dimensional arrays.

					;;;$30A9
					;; HL-HL*DE
HL_HL_DE:	PUSH	BC		; preserve BC throughout
		LD	B,$10		; set B to 16
		LD	A,H		; save H in A high byte
		LD	C,L		; save L in C low byte
		LD	HL,$0000	; initialize result to zero

					; now enter a loop.

					;;;$30B1
HL_LOOP:	ADD	HL,HL		; double result
		JR	C,HL_END	; to HL_END if overflow

		RL	C		; shift AC left into carry
		RLA			;
		JR	NC,HL_AGAIN	; to HL_AGAIN to skip addition if no carry

		ADD	HL,DE		; add in DE
		JR	C,HL_END	; to HL_END if overflow

					;;;$30BC
HL_AGAIN:	DJNZ	HL_LOOP		; back to HL_LOOP for all 16 bits

					;;;$30BE
HL_END:		POP	BC		; restore preserved BC
		RET			; return with carry reset if successful
					; and result in HL.

;------------------------------
; Prepare to multiply or divide
;------------------------------
; This routine is called in succession from multiply and divide to prepare
; two mantissas by setting the leftmost bit that is used for the sign.
; On the first call A holds zero and picks up the sign bit. On the second
; call the two bits are XORed to form the result sign - minus * minus giving
; plus etc. If either number is zero then this is flagged.
; HL addresses the exponent.

					;;;$30C0
PREP_M_D:	CALL	TEST_ZERO	; routine TEST_ZERO  preserves accumulator.
		RET	C		; return carry set if zero

		INC	HL		; address first byte of mantissa
		XOR	(HL)		; pick up the first or xor with first.
		SET	7,(HL)		; now set to give true 32-bit mantissa
		DEC	HL		; point to exponent
		RET			; return with carry reset

;----------------------------
; Handle multiplication ($04)
;----------------------------

					;;;$30CA
MULTIPLY:	LD	A,(DE)
		OR	(HL)
		JR	NZ,MULT_LONG	; to MULT_LONG

		PUSH	DE
		PUSH	HL
		PUSH	DE
		CALL	INT_FETCH	; routine INT_FETCH
		EX	DE,HL
		EX	(SP),HL
		LD	B,C
		CALL	INT_FETCH	; routine INT_FETCH
		LD	A,B
		XOR	C
		LD	C,A
		POP	HL
		CALL	HL_HL_DE	; routine HL_HL_DE
		EX	DE,HL
		POP	HL
		JR	C,MULT_OFLW	; to MULT_OFLW

		LD	A,D
		OR	E
		JR	NZ,MULT_RSLT	; to MULT_RSLT

		LD	C,A

					;;;$30EA
MULT_RSLT:	CALL	INT_STORE	; routine INT_STORE
		POP	DE
		RET

					;;;$30EF
MULT_OFLW:	POP	DE

					;;;$30F0
MULT_LONG:	CALL	RE_ST_TWO	; routine RE_ST_TWO
		XOR	A
		CALL	PREP_M_D	; routine PREP_M_D
		RET	C

		EXX
		PUSH	HL
		EXX
		PUSH	DE
		EX	DE,HL
		CALL	PREP_M_D	; routine PREP_M_D
		EX	DE,HL
		JR	C,ZERO_RSLT	; to ZERO_RSLT

		PUSH	HL
		CALL	FETCH_TWO	; routine FETCH_TWO
		LD	A,B
		AND	A
		SBC	HL,HL
		EXX
		PUSH	HL
		SBC	HL,HL
		EXX
		LD	B,$21
		JR	STRT_MLT	; to STRT_MLT

					;;;$3114
MLT_LOOP:	JR	NC,NO_ADD	; to NO_ADD

		ADD	HL,DE
		EXX
		ADC	HL,DE
		EXX

					;;;$311B
NO_ADD:		EXX
		RR	H
		RR	L
		EXX
		RR	H
		RR	L

					;;;$3125
STRT_MLT:	EXX
		RR	B
		RR	C
		EXX
		RR	C
		RRA
		DJNZ	MLT_LOOP	; to MLT_LOOP
		EX	DE,HL
		EXX
		EX	DE,HL
		EXX
		POP	BC
		POP	HL
		LD	A,B
		ADD	A,C
		JR	NZ,MAKE_EXPT	; to MAKE_EXPT

		AND	A

					;;;$313B
MAKE_EXPT:	DEC	A
		CCF			; Complement Carry Flag

					;;;$313D
DIVN_EXPT:	RLA
		CCF			; Complement Carry Flag
		RRA
		JP	P,OFLW1_CLR	; to OFLW1_CLR

		JR	NC,REPORT_6	; to REPORT_6

		AND	A

					;;;$3146
OFLW1_CLR:	INC	A		;
		JR	NZ,OFLW2_CLR	; to OFLW2_CLR

		JR	C,OFLW2_CLR	; to OFLW2_CLR

		EXX
		BIT	7,D
		EXX
		JR	NZ,REPORT_6	; to REPORT_6

					;;;$3151
OFLW2_CLR:	LD	(HL),A
		EXX
		LD	A,B
		EXX

					;;;$3155
TEST_NORM:	JR	NC,NORMALISE	; to NORMALISE

		LD	A,(HL)
		AND	A

					;;;$3159
NEAR_ZERO:	LD	A,$80
		JR	Z,SKIP_ZERO	; to SKIP_ZERO

					;;;$315D
ZERO_RSLT:	XOR	A

					;;;$315E
SKIP_ZERO:	EXX
		AND	D
		CALL	ZEROS_4_5	; routine ZEROS_4_5
		RLCA
		LD	(HL),A
		JR	C,OFLOW_CLR	; to OFLOW_CLR

		INC	HL
		LD	(HL),A
		DEC	HL
		JR	OFLOW_CLR	; to OFLOW_CLR

					;;;$316C
NORMALISE:	LD	B,$20

					;;;$316E
SHIFT_ONE:	EXX
		BIT	7,D
		EXX
		JR	NZ,NORML_NOW	; to NORML_NOW

		RLCA
		RL	E
		RL	D
		EXX
		RL	E
		RL	D
		EXX
		DEC	(HL)
		JR	Z,NEAR_ZERO	; to NEAR_ZERO

		DJNZ	SHIFT_ONE	; to SHIFT_ONE
		JR	ZERO_RSLT	; to ZERO_RSLT

					;;;$3186
NORML_NOW:	RLA
		JR	NC,OFLOW_CLR	; to OFLOW_CLR

		CALL	ADD_BACK	; routine ADD_BACK
		JR	NZ,OFLOW_CLR	; to OFLOW_CLR

		EXX
		LD	D,$80
		EXX
		INC	(HL)
		JR	Z,REPORT_6	; to REPORT_6

					;;;$3195
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

					;;;$31AD
REPORT_6:	RST	08H		; ERROR_1
		DEFB	$05		; Error Report: Number too big

;----------------------
; Handle division ($05)
;----------------------

					;;;$31AF
DIVISION:	CALL	RE_ST_TWO	; routine RE_ST_TWO
		EX	DE,HL
		XOR	A
		CALL	PREP_M_D	; routine PREP_M_D
		JR	C,REPORT_6	; to REPORT_6

		EX	DE,HL
		CALL	PREP_M_D	; routine PREP_M_D
		RET	C

		EXX
		PUSH	HL
		EXX
		PUSH	DE
		PUSH	HL
		CALL	FETCH_TWO	; routine FETCH_TWO
		EXX
		PUSH	HL
		LD	H,B
		LD	L,C
		EXX
		LD	H,C
		LD	L,B
		XOR	A
		LD	B,$DF
		JR	DIV_START	; to DIV_START

					;;;$31D2
DIV_LOOP:	RLA
		RL	C
		EXX
		RL	C
		RL	B
		EXX

					;;;$31DB
DIV_34TH:	ADD	HL,HL
		EXX
		ADC	HL,HL
		EXX
		JR	C,SUBN_ONLY	; to SUBN_ONLY

					;;;$31E2
DIV_START:	SBC	HL,DE
		EXX
		SBC	HL,DE
		EXX
		JR	NC,NO_RSTORE	; to NO_RSTORE

		ADD	HL,DE
		EXX
		ADC	HL,DE
		EXX
		AND	A
		JR	COUNT_ONE	; to COUNT_ONE

					;;;$31F2
SUBN_ONLY:	AND	A
		SBC	HL,DE
		EXX
		SBC	HL,DE
		EXX

					;;;$31F9
NO_RSTORE:	SCF			; Set Carry Flag

					;;;$31FA
COUNT_ONE:	INC	B
		JP	M,DIV_LOOP	; to DIV_LOOP

		PUSH	AF
		JR	Z,DIV_START	; to DIV_START

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
		JP	DIVN_EXPT		; to DIVN_EXPT

;--------------------------------------
; Integer truncation towards zero ($3A)
;--------------------------------------

					;;;$3214
TRUNCATE:	LD	A,(HL)	
		AND	A
		RET	Z

		CP	$81
		JR	NC,T_GR_ZERO	; to T_GR_ZERO

		LD	(HL),$00
		LD	A,$20
		JR	NIL_BYTES	; to NIL_BYTES

					;;;$3221
T_GR_ZERO:	CP	$91
		JR	NZ,T_SMALL	; to T_SMALL

		INC	HL
		INC	HL
		INC	HL
		LD	A,$80
		AND	(HL)
		DEC	HL
		OR	(HL)
		DEC	HL
		JR	NZ,T_FIRST	; to T_FIRST

		LD	A,$80
		XOR	(HL)

					;;;$3233
T_FIRST:	DEC	HL
		JR	NZ,T_EXPNENT	; to T_EXPNENT

		LD	(HL),A
		INC	HL
		LD	(HL),$FF
		DEC	HL
		LD	A,$18
		JR	NIL_BYTES	; to NIL_BYTES

					;;;$323F
T_SMALL:	JR	NC,X_LARGE	; to X_LARGE

		PUSH	DE
		CPL
		ADD	A,$91
		INC	HL
		LD	D,(HL)
		INC	HL
		LD	E,(HL)
		DEC	HL
		DEC	HL
		LD	C,$00
		BIT	7,D
		JR	Z,T_NUMERIC	; to T_NUMERIC

		DEC	C

					;;;$3252
T_NUMERIC:	SET	7,D
		LD	B,$08
		SUB	B
		ADD	A,B
		JR	C,T_TEST	; to T_TEST

		LD	E,D
		LD	D,$00
		SUB	B

					;;;$325E
T_TEST:		JR	Z,T_STORE	; to T_STORE

		LD	B,A

					;;;$3261
T_SHIFT:	SRL	D
		RR	E
		DJNZ	T_SHIFT		; to T_SHIFT

					;;;$3267
T_STORE:	CALL	INT_STORE	; routine INT_STORE
		POP	DE
		RET

					;;;$326C
T_EXPNENT:	LD	A,(HL)

					;;;$326D
X_LARGE:	SUB	$A0
		RET	P

		NEG			; Negate

					;;;$3272
NIL_BYTES:	PUSH	DE
		EX	DE,HL
		DEC	HL
		LD	B,A
		SRL	B
		SRL	B
		SRL	B
		JR	Z,BITS_ZERO	; to BITS_ZERO

					;;;$327E
BYTE_ZERO:	LD	(HL),$00
		DEC	HL
		DJNZ	BYTE_ZERO	; to BYTE_ZERO

					;; BITS_ZERO
BITS_ZERO:	AND	$07
		JR	Z,IX_END	; to IX_END

		LD	B,A
		LD	A,$FF

					;;;$328A
LESS_MASK:	SLA	A
		DJNZ	LESS_MASK	; to LESS_MASK
		AND	(HL)
		LD	(HL),A

					;;;$3290
IX_END:		EX	DE,HL
		POP	DE
		RET

; ----------------------------------
; Storage of numbers in 5 byte form.
; ==================================
; Both integers and floating-point numbers can be stored in five bytes.
; Zero is a special case stored as 5 zeros.
; For integers the form is
; Byte 1 - zero,
; Byte 2 - sign byte, $00 +ve, $FF -ve.
; Byte 3 - Low byte of integer.
; Byte 4 - High byte
; Byte 5 - unused but always zero.
;
; it seems unusual to store the low byte first but it is just as easy either
; way. Statistically it just increases the chances of trailing zeros which
; is an advantage elsewhere in saving ROM code.
;
;             zero     sign     low      high    unused
; So +1 is  00000000 00000000 00000001 00000000 00000000
;
; and -1 is 00000000 11111111 11111111 11111111 00000000
;
; much of the arithmetic found in basic lines can be done using numbers
; in this form using the Z80's 16 bit register operation ADD.
; (multiplication is done by a sequence of additions).
;
; Storing -ve integers in two's complement form, means that they are ready for
; addition and you might like to add the numbers above to prove that the
; answer is zero. If, as in this case, the carry is set then that denotes that
; the result is positive. This only applies when the signs don't match.
; With positive numbers a carry denotes the result is out of integer range.
; With negative numbers a carry denotes the result is within range.
; The exception to the last rule is when the result is -65536
;
; Floating point form is an alternative method of storing numbers which can
; be used for integers and larger (or fractional) numbers.
;
; In this form 1 is stored as
;           10000001 00000000 00000000 00000000 00000000
;
; When a small integer is converted to a floating point number the last two
; bytes are always blank so they are omitted in the following steps
;
; first make exponent +1 +16d  (bit 7 of the exponent is set if positive)

; 10010001 00000000 00000001
; 10010000 00000000 00000010 <-  now shift left and decrement exponent
; ...
; 10000010 01000000 00000000 <-  until a 1 abuts the imaginary point
; 10000001 10000000 00000000     to the left of the mantissa.
;
; however since the leftmost bit of the mantissa is always set then it can
; be used to denote the sign of the mantissa and put back when needed by the
; PREP routines which gives
;
; 10000001 00000000 00000000

;------------------------------
; Re-stack two `small' integers
;------------------------------
; This routine is called to re-stack two numbers in full floating point form
; e.g. from MULTIPLY when integer multiplication has overflowed.

					;;;$3293
RE_ST_TWO:	CALL	RESTK_SUB	; routine RESTK_SUB  below and continue
					; into the routine to do the other one.

					;;;$3296
RESTK_SUB:	EX	DE,HL		; swap pointers

;---------------------------------
; Re-stack one number in full form
;---------------------------------
; This routine re-stacks an integer usually on the calculator stack
; in full floating point form.
; HL points to first byte.

					;;;$3297
RE_STACK:	LD	A,(HL)		; Fetch Exponent byte to A
		AND	A		; test it
		RET	NZ		; return if not zero as already in full
					; floating-point form.
		PUSH	DE		; preserve DE.
		CALL	INT_FETCH	; routine INT_FETCH
					; integer to DE, sign to C.

					; HL points to 4th byte.

		XOR	A		; clear accumulator.
		INC	HL		; point to 5th.
		LD	(HL),A		; and blank.
		DEC	HL		; point to 4th.
		LD	(HL),A		; and blank.
		LD	B,$91		; set exponent byte +ve $81
					; and imaginary dec point 16 bits to right
					; of first bit.

					; we could skip to normalize now but it's quicker to avoid
					; normalizing through an empty D.

		LD	A,D		; fetch the high byte D
		AND	A		; is it zero ?
		JR	NZ,RS_NRMLSE	; skip to RS_NRMLSE if not.

		OR	E		; low byte E to A and test for zero
		LD	B,D		; set B exponent to 0
		JR	Z,RS_STORE	; forward to RS_STORE if value is zero.

		LD	D,E		; transfer E to D
		LD	E,B		; set E to 0
		LD	B,$89		; reduce the initial exponent by eight.


					;;;$32B1
RS_NRMLSE:	EX	DE,HL		; integer to HL, addr of 4th byte to DE.

					;;;$32B2
RSTK_LOOP:	DEC	B		; decrease exponent
		ADD	HL,HL		; shift DE left
		JR	NC,RSTK_LOOP	; loop back to RSTK_LOOP
					; until a set bit pops into carry
		RRC	C		; now rotate the sign byte $00 or $FF
					; into carry to give a sign bit
		RR	H		; rotate the sign bit to left of H
		RR	L		; rotate any carry into L
		EX	DE,HL		; address 4th byte, normalized int to DE

					;;;$32BD
RS_STORE:	DEC	HL		; address 3rd byte
		LD	(HL),E		; place E
		DEC	HL		; address 2nd byte
		LD	(HL),D		; place D
		DEC	HL		; address 1st byte
		LD	(HL),B		; store the exponent

		POP	DE		; restore initial DE.
		RET			; return.

;****************************************
;** Part 10. FLOATING-POINT CALCULATOR **
;****************************************

; As a general rule the calculator avoids using the IY register.
; exceptions are VAL, VAL$ and STR$.
; So an assembly language programmer who has disabled interrupts to use
; IY for other purposes can still use the calculator for mathematical
; purposes.


;-------------------
; Table of constants
;-------------------

; used 11 times
					;;;$32C5			00 00 00 00 00
STK_ZERO:	DEFB	$00		;;Bytes: 1
		DEFB	$B0		;;Exponent $00
		DEFB	$00		;;(+00,+00,+00)

; used 19 times
					;;;$32C8			00 00 01 00 00
STK_ONE:	DEFB	$40		;;Bytes: 2
		DEFB	$B0		;;Exponent $00
		DEFB	$00,$01		;;(+00,+00)

; used 9 times
					;;;$32CC			80 00 00 00 00
STK_HALF:	DEFB	$30		;;Exponent: $80, Bytes: 1
		DEFB	$00		;;(+00,+00,+00)

; used 4 times
					;;;$32CE
					;; stk-pi/2			81 49 0F DA A2
STK_PI_2:	DEFB	$F1		;;Exponent: $81, Bytes: 4
		DEFB	$49,$0F,$DA,$A2

; used 3 times
					;;;$32D3			00 00 0A 00 00
STK_TEN:	DEFB	$40		;;Bytes: 2
		DEFB	$B0		;;Exponent $00
		DEFB	$00,$0A		;;(+00,+00)


;-------------------
; Table of addresses
;-------------------
;
; starts with binary operations which have two operands and one result.
; three pseudo binary operations first.

					;;;$32D7
TBL_ADDRS:	DEFW	JUMP_TRUE	; $00 Address: $368F - JUMP_TRUE
		DEFW	EXCHANGE	; $01 Address: $343C - EXCHANGE
		DEFW	DELETE		; $02 Address: $33A1 - DELETE

					; true binary operations.

		DEFW	SUBTRACT	; $03 Address: $300F - SUBTRACT
		DEFW	MULTIPLY	; $04 Address: $30CA - MULTIPLY
		DEFW	DIVISION	; $05 Address: $31AF - DIVISION
		DEFW	TO_POWER	; $06 Address: $3851 - TO_POWER
		DEFW	OR_		; $07 Address: $351B - OR

		DEFW	NO_AND_NO	; $08 Address: $3524 - NO_AND_NO
		DEFW	NO_L_EQL	; $09 Address: $353B - NO_L_EQL
		DEFW	NO_GR_EQL	; $0A Address: $353B - NO_GR_EQL
		DEFW	NOS_NEQL	; $0B Address: $353B - NOS_NEQL
		DEFW	NO_GRTR		; $0C Address: $353B - NO_GRTR
		DEFW	NO_LESS		; $0D Address: $353B - NO_LESS
		DEFW	NOS_EQL		; $0E Address: $353B - NOS_EQL
		DEFW	ADDITION	; $0F Address: $3014 - ADDITION

		DEFW	STR_AND_NO	; $10 Address: $352D - STR_AND_NO
		DEFW	STR_L_EQL	; $11 Address: $353B - STR_L_EQL
		DEFW	STR_GR_EQL	; $12 Address: $353B - STR_GR_EQL
		DEFW	STRS_NEQL	; $13 Address: $353B - STRS_NEQL
		DEFW	STR_GRTR	; $14 Address: $353B - STR_GRTR
		DEFW	STR_LESS	; $15 Address: $353B - STR_LESS
		DEFW	STRS_EQL	; $16 Address: $353B - STRS_EQL
		DEFW	STRS_ADD	; $17 Address: $359C - STRS_ADD

					; unary follow

		DEFW	VALS		; $18 Address: $35DE - VAL$
		DEFW	USR_		; $19 Address: $34BC - USR-$
		DEFW	READ_IN		; $1A Address: $3645 - READ_IN
		DEFW	NEGATE		; $1B Address: $346E - NEGATE

		DEFW	CODE		; $1C Address: $3669 - CODE
		DEFW	VAL		; $1D Address: $35DE - VAL
		DEFW	LEN		; $1E Address: $3674 - LEN
		DEFW	SIN_		; $1F Address: $37B5 - SIN
		DEFW	COS_		; $20 Address: $37AA - COS
		DEFW	TAN		; $21 Address: $37DA - TAN
		DEFW	ASN		; $22 Address: $3833 - ASN
		DEFW	ACS		; $23 Address: $3843 - ACS
		DEFW	ATN		; $24 Address: $37E2 - ATN
		DEFW	LN		; $25 Address: $3713 - LN
		DEFW	EXP		; $26 Address: $36C4 - EXP
		DEFW	INT		; $27 Address: $36AF - INT
		DEFW	SQR		; $28 Address: $384A - SQR
		DEFW	SGN		; $29 Address: $3492 - SGN
		DEFW	@ABS		; $2A Address: $346A - ABS
		DEFW	PEEK		; $2B Address: $34AC - PEEK
		DEFW	IN_		; $2C Address: $34A5 - IN
		DEFW	USR_NO		; $2D Address: $34B3 - USR_NO
		DEFW	STRS		; $2E Address: $361F - STR$
		DEFW	CHRS		; $2F Address: $35C9 - CHR$
		DEFW	NOT_		; $30 Address: $3501 - NOT

					; end of true unary

		DEFW	DUPLICATE	; $31 Address: $33C0 - DUPLICATE
		DEFW	N_MOD_M		; $32 Address: $36A0 - N_MOD_M
		DEFW	JUMP		; $33 Address: $3686 - JUMP
		DEFW	STK_DATA	; $34 Address: $33C6 - STK_DATA
		DEFW	DEC_JR_NZ	; $35 Address: $367A - DEC_JR_NZ
		DEFW	LESS_0		; $36 Address: $3506 - LESS_0
		DEFW	GREATER_0	; $37 Address: $34F9 - GREATER_0
		DEFW	END_CALC	; $38 Address: $369B - END_CALC
		DEFW	GET_ARGT	; $39 Address: $3783 - GET_ARGT
		DEFW	TRUNCATE	; $3A Address: $3214 - TRUNCATE
		DEFW	FP_CALC_2	; $3B Address: $33A2 - FP_CALC_2
		DEFW	E_TO_FP		; $3C Address: $2D4F - E_TO_FP
		DEFW	RE_STACK	; $3D Address: $3297 - RE_STACK

					; the following are just the next available slots for the 128 compound literals
					; which are in range $80 - $FF.

		DEFW	SERIES_XX	; $3E Address: $3449 - SERIES_XX    $80 - $9F.
		DEFW	STK_CONST_XX	; $3F Address: $341B - STK_CONST_XX $A0 - $BF.
		DEFW	ST_MEM_XX	; $40 Address: $342D - ST_MEM_XX    $C0 - $DF.
		DEFW	GET_MEM_XX	; $41 Address: $340F - GET_MEM_XX   $E0 - $FF.

					; Aside: $3E - $7F are therefore unused calculator literals.
					;        $3E - $7B would be available for expansion.

;---------------
; The Calculator
;---------------

					;;;$335B
CALCULATE:	CALL	STK_PNTRS	; routine STK_PNTRS is called to set up the
					; calculator stack pointers for a default
					; unary operation. HL = last value on stack.
					; DE = STKEND first location after stack.

					; the calculate routine is called at this point by the series generator...

					;;;$335E
GEN_ENT_1:	LD	A,B		; fetch the Z80 B register to A
		LD	(BREG),A	; and store value in system variable BREG.
					; this will be the counter for DEC_JR_NZ
					; or if used from FP_CALC2 the calculator
					; instruction.

					; ... and again later at this point

					;;;$3362
GEN_ENT_2:	EXX			; switch sets
		EX	(SP),HL		; and store the address of next instruction,
					; the return address, in H'L'.
					; If this is a recursive call the the H'L'
					; of the previous invocation goes on stack.
					; c.f. END_CALC.
		EXX			; switch back to main set

					; this is the re-entry looping point when handling a string of literals.

					;;;$3365
RE_ENTRY:	LD	(STKEND),DE	; save end of stack in system variable STKEND
		EXX			; switch to alt
		LD	A,(HL)		; get next literal
		INC	HL		; increase pointer'

					; single operation jumps back to here

					;;;$336C
SCAN_ENT:	PUSH	HL		; save pointer on stack
		AND	A		; now test the literal
		JP	P,FIRST_3D	; forward to FIRST_3D if in range $00 - $3D
					; anything with bit 7 set will be one of
					; 128 compound literals.

					; compound literals have the following format.
					; bit 7 set indicates compound.
					; bits 6-5 the subgroup 0-3.
					; bits 4-0 the embedded parameter $00 - $1F.
					; The subgroup 0-3 needs to be manipulated to form the next available four
					; address places after the simple literals in the address table.

		LD	D,A		; save literal in D
		AND	$60		; and with 01100000 to isolate subgroup
		RRCA			; rotate bits
		RRCA			; 4 places to right
		RRCA			; not five as we need offset * 2
		RRCA			; 00000xx0
		ADD	A,$7C		; add ($3E * 2) to give correct offset.
					; alter above if you add more literals.
		LD	L,A		; store in L for later indexing.
		LD	A,D		; bring back compound literal
		AND	$1F		; use mask to isolate parameter bits
		JR	ENT_TABLE	; forward to ENT_TABLE

					; the branch was here with simple literals.

					;;;$3380
FIRST_3D:	CP	$18		; compare with first unary operations.
		JR	NC,DOUBLE_A	; to DOUBLE_A with unary operations

					; it is binary so adjust pointers.

		EXX
		LD	BC,$FFFB	; the value -5
		LD	D,H		; transfer HL, the last value, to DE.
		LD	E,L
		ADD	HL,BC		; subtract 5 making HL point to second  value.
		EXX

					;;;$338C
DOUBLE_A:	RLCA			; double the literal
		LD	L,A		; and store in L for indexing

					;;;$338E
ENT_TABLE:	LD	DE,TBL_ADDRS	; Address: TBL_ADDRS
		LD	H,$00		; prepare to index
		ADD	HL,DE		; add to get address of routine
		LD	E,(HL)		; low byte to E
		INC	HL
		LD	D,(HL)		; high byte to D
		LD	HL,RE_ENTRY	; Address: RE_ENTRY
		EX	(SP),HL		; goes to stack
		PUSH	DE		; now address of routine
		EXX			; main set
					; avoid using IY register.
		LD	BC,(STKEND_HI)	; STKEND_hi
					; nothing much goes to C but BREG to B
					; and continue into next ret instruction
					; which has a dual identity


;--------------------
; Handle delete ($02)
;--------------------
; A simple return but when used as a calculator literal this
; deletes the last value from the calculator stack.
; On entry, as always with binary operations,
; HL=first number, DE=second number
; On exit, HL=result, DE=stkend.
; So nothing to do

					;;;$33A1
DELETE:		RET			; return - indirect jump if from above.

;-----------------------
; Single operation ($3B)
;-----------------------
; this single operation is used, in the first instance, to evaluate most
; of the mathematical and string functions found in Basic expressions.

					;;;$33A2
FP_CALC_2:	POP	AF		; drop return address.
		LD	A,(BREG)	; load accumulator from system variable BREG
					; value will be literal eg. 'TAN'
		EXX			; switch to alt
		JR	SCAN_ENT	; back to SCAN_ENT
					; next literal will be END_CALC at $2758

;-----------------
; Test five-spaces
;-----------------
; This routine is called from MOVE_FP, STK_CONST and STK_STORE to
; test that there is enough space between the calculator stack and the
; machine stack for another five-byte value. It returns with BC holding
; the value 5 ready for any subsequent LDIR.

					;;;$33A9
TEST_5_SP:	PUSH	DE		; save
		PUSH	HL		; registers
		LD	BC,$0005	; an overhead of five bytes
		CALL	TEST_ROOM	; routine TEST_ROOM tests free RAM raising an error if not.
		POP	HL		; else restore
		POP	DE		; registers.
		RET			; return with BC set at 5.

;-------------
; Stack number
;-------------
; This routine is called to stack a hidden floating point number found in
; a Basic line. It is also called to stack a numeric variable value, and
; from BEEP, to stack an entry in the semi-tone table. It is not part of the
; calculator suite of routines.
; On entry HL points to the number to be stacked.

					;;;$33B4
STACK_NUM:	LD	DE,(STKEND)	; load destination from STKEND system variable.
		CALL	MOVE_FP		; routine MOVE_FP puts on calculator stack with a memory check.
		LD	(STKEND),DE	; set STKEND to next free location.
		RET			; return.

;-----------------------------------
; Move a floating point number ($31)
;-----------------------------------
; This simple routine is a 5-byte LDIR instruction
; that incorporates a memory check.
; When used as a calculator literal it duplicates the last value on the
; calculator stack.
; Unary so on entry HL points to last value, DE to stkend

					;;;$33C0
DUPLICATE:
MOVE_FP:	CALL	TEST_5_SP	; routine TEST_5_SP test free memory and sets BC to 5.
		LDIR			; copy the five bytes.
		RET			; return with DE addressing new STKEND
					; and HL addressing new last value.

;---------------------
; Stack literals ($34)
;---------------------
; When a calculator subroutine needs to put a value on the calculator
; stack that is not a regular constant this routine is called with a
; variable number of following data bytes that convey to the routine
; the integer or floating point form as succinctly as is possible.

					;;;$33C6
STK_DATA:	LD	H,D		; transfer STKEND
		LD	L,E		; to HL for result.

					;;;$33C8
STK_CONST:	CALL	TEST_5_SP	; routine TEST_5_SP tests that room exists
					; and sets BC to $05.
		EXX			; switch to alternate set
		PUSH	HL		; save the pointer to next literal on stack
		EXX			; switch back to main set
		EX	(SP),HL		; pointer to HL, destination to stack.
		PUSH	BC		; save BC - value 5 from test room ??.
		LD	A,(HL)		; fetch the byte following 'STK_DATA'
		AND	$C0		; isolate bits 7 and 6
		RLCA			; rotate
		RLCA			; to bits 1 and 0  range $00 - $03.
		LD	C,A		; transfer to C
		INC	C		; and increment to give number of bytes
					; to read. $01 - $04
		LD	A,(HL)		; reload the first byte
		AND	$3F		; mask off to give possible exponent.
		JR	NZ,FORM_EXP	; forward to FORM_EXP if it was possible to
					; include the exponent.

					; else byte is just a byte count and exponent comes next.

		INC	HL		; address next byte and
		LD	A,(HL)		; pick up the exponent ( - $50).

					;;;$33DE
FORM_EXP:	ADD	A,$50		; now add $50 to form actual exponent
		LD	(DE),A		; and load into first destination byte.
		LD	A,$05		; load accumulator with $05 and
		SUB	C		; subtract C to give count of trailing zeros plus one.
		INC	HL		; increment source
		INC	DE		; increment destination
		LD	B,$00		; prepare to copy
		LDIR			; copy C bytes
		POP	BC		; restore 5 counter to BC ??.
		EX	(SP),HL		; put HL on stack as next literal pointer
					; and the stack value - result pointer - to HL.
		EXX			; switch to alternate set.
		POP	HL		; restore next literal pointer from stack to H'L'.
		EXX			; switch back to main set.
		LD	B,A		; zero count to B
		XOR	A		; clear accumulator

					;;;$33F1
STK_ZEROS:	DEC	B		; decrement B counter
		RET	Z		; return if zero.		>>
					; DE points to new STKEND
					; HL to new number.

		LD	(DE),A		; else load zero to destination
		INC	DE		; increase destination
		JR	STK_ZEROS	; loop back to STK_ZEROS until done.

;---------------
; Skip constants
;---------------
; This routine traverses variable-length entries in the table of constants,
; stacking intermediate, unwanted constants onto a dummy calculator stack,
; in the first five bytes of ROM.

					;;;$33F7
SKIP_CONS:	AND	A		; test if initially zero.

					;;;$33F8
SKIP_NEXT:	RET	Z		; return if zero.		>>

		PUSH	AF		; save count.
		PUSH	DE		; and normal STKEND
		LD	DE,$0000	; dummy value for STKEND at start of ROM
					; Note. not a fault but this has to be
					; moved elsewhere when running in RAM.
					; e.g. with Expandor Systems 'Soft Rom'.
		CALL	STK_CONST	; routine STK_CONST works through variable length records.
		POP	DE		; restore real STKEND
		POP	AF		; restore count
		DEC	A		; decrease
		JR	SKIP_NEXT	; loop back to SKIP_NEXT

;----------------
; Memory location
;----------------
; This routine, when supplied with a base address in HL and an index in A
; will calculate the address of the A'th entry, where each entry occupies
; five bytes. It is used for reading the semi-tone table and addressing
; floating-point numbers in the calculator's memory area.

					;;;$3406
LOC_MEM:	LD	C,A		; store the original number $00-$1F.
		RLCA			; double.
		RLCA			; quadruple.
		ADD	A,C		; now add original to multiply by five.
		LD	C,A		; place the result in C.
		LD	B,$00		; set B to 0.
		ADD	HL,BC		; add to form address of start of number in HL.
		RET			; return.

;--------------------------------
; Get from memory area ($E0 etc.)
;--------------------------------
; Literals $E0 to $FF
; A holds $00-$1F offset.
; The calculator stack increases by 5 bytes.

					;;;$340F
GET_MEM_XX:	PUSH	DE		; save STKEND
		LD	HL,(MEM)	; MEM is base address of the memory cells.
		CALL	LOC_MEM		; routine LOC_MEM so that HL = first byte
		CALL	MOVE_FP		; routine MOVE_FP moves 5 bytes with memory check.
					; DE now points to new STKEND.
		POP	HL		; original STKEND is now RESULT pointer.
		RET			; return.

;----------------------------
; Stack a constant ($A0 etc.)
;----------------------------
; This routine allows a one-byte instruction to stack up to 32 constants
; held in short form in a table of constants. In fact only 5 constants are
; required. On entry the A register holds the literal ANDed with 1F.
; It isn't very efficient and it would have been better to hold the
; numbers in full, five byte form and stack them in a similar manner
; to that used for semi-tone table values.

					;;;$341B
STK_CONST_XX:	LD	H,D		; save STKEND - required for result
		LD	L,E
		EXX			; swap
		PUSH	HL		; save pointer to next literal
		LD	HL,STK_ZERO	; Address: STK_ZERO - start of table of constants
		EXX
		CALL	SKIP_CONS	; routine SKIP_CONS
		CALL	STK_CONST	; routine STK_CONST
		EXX
		POP	HL		; restore pointer to next literal.
		EXX
		RET			; return.

;----------------------------------
; Store in a memory area ($C0 etc.)
;----------------------------------
; Offsets $C0 to $DF
; Although 32 memory storage locations can be addressed, only six
; $C0 to $C5 are required by the ROM and only the thirty bytes (6*5)
; required for these are allocated. Spectrum programmers who wish to
; use the floating point routines from assembly language may wish to
; alter the system variable MEM to point to 160 bytes of RAM to have 
; use the full range available.
; A holds derived offset $00-$1F.
; Unary so on entry HL points to last value, DE to STKEND.

					;;;$342D
ST_MEM_XX:	PUSH	HL		; save the result pointer.
		EX	DE,HL		; transfer to DE.
		LD	HL,(MEM)	; fetch MEM the base of memory area.
		CALL	LOC_MEM		; routine LOC_MEM sets HL to the destination.
		EX	DE,HL		; swap - HL is start, DE is destination.
		CALL	MOVE_FP		; routine MOVE_FP.
					; note. a short ld bc,5; ldir
					; the embedded memory check is not required
					; so these instructions would be faster.
		EX	DE,HL		; DE = STKEND
		POP	HL		; restore original result pointer
		RET			; return.

;-------------------------------------
; Swap first number with second number
;-------------------------------------
; This routine exchanges the last two values on the calculator stack
; On entry, as always with binary operations,
; HL=first number, DE=second number
; On exit, HL=result, DE=stkend.

					;;;$343C
EXCHANGE:	LD	B,$05		; there are five bytes to be swapped

					; start of loop.

					;;;$343E
SWAP_BYTE:	LD	A,(DE)		; each byte of second
		LD	C,(HL)		; each byte of first
		EX	DE,HL		; swap pointers
		LD	(DE),A		; store each byte of first
		LD	(HL),C		; store each byte of second
		INC	HL		; advance both
		INC	DE		; pointers.
		DJNZ	SWAP_BYTE	; loop back to SWAP_BYTE until all 5 done.
		EX	DE,HL		; even up the exchanges
					; so that DE addresses STKEND.
		RET			; return.

;----------------------------
; Series generator ($86 etc.)
;----------------------------
; The Spectrum uses Chebyshev polynomials to generate approximations for
; SIN, ATN, LN and EXP. These are named after the Russian mathematician
; Pafnuty Chebyshev, born in 1821, who did much pioneering work on numerical
; series. As far as calculators are concerned, Chebyshev polynomials have an
; advantage over other series, for example the Taylor series, as they can
; reach an approximation in just six iterations for SIN, eight for EXP and
; twelve for LN and ATN. The mechanics of the routine are interesting but
; for full treatment of how these are generated with demonstrations in
; Sinclair Basic see "The Complete Spectrum ROM Disassembly" by Dr Ian Logan
; and Dr Frank O'Hara, published 1983 by Melbourne House.

					;;;$3449
SERIES_XX:	LD	B,A		; parameter $00 - $1F to B counter
		CALL	GEN_ENT_1	; routine GEN_ENT_1 is called.
					; A recursive call to a special entry point
					; in the calculator that puts the B register
					; in the system variable BREG. The return
					; address is the next location and where
					; the calculator will expect it's first
					; instruction - now pointed to by HL'.
					; The previous pointer to the series of
					; five-byte numbers goes on the machine stack.

					; The initialization phase.

		DEFB	$31		;;DUPLICATE	x,x
		DEFB	$0F		;;ADDITION	x+x
		DEFB	$C0		;;st-mem-0	x+x
		DEFB	$02		;;DELETE	.
		DEFB	$A0		;;STK_ZERO	0
		DEFB	$C2		;;st-mem-2	0

					; a loop is now entered to perform the algebraic calculation for each of
					; the numbers in the series

					;; G_LOOP
G_LOOP:		DEFB	$31		;;DUPLICATE	v,v.
		DEFB	$E0		;;get-mem-0	v,v,x+2
		DEFB	$04		;;MULTIPLY	v,v*x+2
		DEFB	$E2		;;get-mem-2	v,v*x+2,v
		DEFB	$C1		;;st-mem-1
		DEFB	$03		;;SUBTRACT
		DEFB	$38		;;END_CALC

					; the previous pointer is fetched from the machine stack to H'L' where it
					; addresses one of the numbers of the series following the series literal.

		CALL	STK_DATA	; routine STK_DATA is called directly to
					; push a value and advance H'L'.
		CALL	GEN_ENT_2	; routine GEN_ENT_2 recursively re-enters
					; the calculator without disturbing
					; system variable BREG
					; H'L' value goes on the machine stack and is
					; then loaded as usual with the next address.

		DEFB	$0F		;;ADDITION
		DEFB	$01		;;EXCHANGE
		DEFB	$C2		;;st-mem-2
		DEFB	$02		;;DELETE

		DEFB	$35		;;DEC_JR_NZ
		DEFB	$EE		;;back to G_LOOP

					; when the counted loop is complete the final subtraction yields the result
					; for example SIN X.

		DEFB	$E1		;;get-mem-1
		DEFB	$03		;;SUBTRACT
		DEFB	$38		;;END_CALC

		RET			; return with H'L' pointing to location
					; after last number in series.

;-------------------------
; Absolute magnitude ($2A)
;-------------------------
; This calculator literal finds the absolute value of the last value,
; integer or floating point, on calculator stack.

					;;;$346A
ABS:		LD	B,$FF		; signal abs
		JR	NEG_TEST	; forward to NEG_TEST

;-------------------------
; Handle unary minus ($1B)
;-------------------------
; Unary so on entry HL points to last value, DE to STKEND.

					;;;$346E
NEGATE:		CALL	TEST_ZERO	; call routine TEST_ZERO and
		RET	C		; return if so leaving zero unchanged.

		LD	B,$00		; signal negate required before joining
					; common code.

					;;;$3474
NEG_TEST:	LD	A,(HL)		; load first byte and 
		AND	A		; test for zero
		JR	Z,INT_CASE	; forward to INT_CASE if a small integer

					; for floating point numbers a single bit denotes the sign.

		INC	HL		; address the first byte of mantissa.
		LD	A,B		; action flag $FF=abs, $00=neg.
		AND	$80		; now		$80	$00
		OR	(HL)		; sets bit 7 for abs
		RLA			; sets carry for abs and if number negative
		CCF			; complement carry flag
		RRA			; and rotate back in altering sign
		LD	(HL),A		; put the altered adjusted number back
		DEC	HL		; HL points to result
		RET			; return with DE unchanged

					; for integer numbers an entire byte denotes the sign.

					;;;$3483
INT_CASE:	PUSH	DE		; save STKEND.
		PUSH	HL		; save pointer to the last value/result.
		CALL	INT_FETCH	; routine INT_FETCH puts integer in DE and the sign in C.
		POP	HL		; restore the result pointer.
		LD	A,B		; $FF=abs, $00=neg
		OR	C		; $FF for abs, no change neg
		CPL			; $00 for abs, switched for neg
		LD	C,A		; transfer result to sign byte.
		CALL	INT_STORE	; routine INT_STORE to re-write the integer.
		POP	DE		; restore STKEND.
		RET			; return.

;-------------
; Signum ($29)
;-------------
; This routine replaces the last value on the calculator stack,
; which may be in floating point or integer form, with the integer values
; zero if zero, with one if positive and  with -minus one if negative.

					;;;$3492
SGN:		CALL	TEST_ZERO	; call routine TEST_ZERO and
		RET	C		; exit if so as no change is required.
		PUSH	DE		; save pointer to STKEND.
		LD	DE,$0001	; the result will be 1.
		INC	HL		; skip over the exponent.
		RL	(HL)		; rotate the sign bit into the carry flag.
		DEC	HL		; step back to point to the result.
		SBC	A,A		; byte will be $FF if negative, $00 if positive.
		LD	C,A		; store the sign byte in the C register.
		CALL	INT_STORE	; routine INT_STORE to overwrite the last value with 0001 and sign.
		POP	DE		; restore STKEND.
		RET			; return.

;-------------------------
; Handle IN function ($2C)
;-------------------------
; This function reads a byte from an input port.

					;;;$34A5
IN_:		CALL	FIND_INT2	; routine FIND_INT2 puts port address in BC.
					; all 16 bits are put on the address line.
		IN	A,(C)		; read the port.
		JR	IN_PK_STK	; exit to STACK_A (via IN_PK_STK to save a byte 
					; of instruction code).

;--------------------------
; Handle PEEK function ($2B)
;--------------------------
; This function returns the contents of a memory address.
; The entire address space can be peeked including the ROM.

					;;;$34AC
PEEK:		CALL	FIND_INT2	; routine FIND_INT2 puts address in BC.
		LD	A,(BC)		; load contents into A register.

					;;;$34B0
IN_PK_STK:	JP	STACK_A		; exit via STACK_A to put value on the 
					; calculator stack.

;-----------------
; USR number ($2D)
;-----------------
; The USR function followed by a number 0-65535 is the method by which
; the Spectrum invokes machine code programs. This function returns the
; contents of the BC register pair.
; Note. that STACK_BC re-initializes the IY register if a user-written
; program has altered it.

					;; USR_NO
USR_NO:		CALL	FIND_INT2	; routine FIND_INT2 to fetch the supplied address into BC.
		LD	HL,STACK_BC	; address: STACK_BC is
		PUSH	HL		; pushed onto the machine stack.
		PUSH	BC		; then the address of the machine code routine.
		RET			; make an indirect jump to the routine
					; and, hopefully, to STACK_BC also.

;-----------------
; USR string ($19)
;-----------------
; The user function with a one-character string argument, calculates the
; address of the User Defined Graphic character that is in the string.
; As an alternative, the ascii equivalent, upper or lower case,
; may be supplied. This provides a user-friendly method of redefining
; the 21 User Definable Graphics e.g.
; POKE USR "a", BIN 10000000 will put a dot in the top left corner of the
; character 144.
; Note. the curious double check on the range. With 26 UDGs the first check
; only is necessary. With anything less the second check only is required.
; It is highly likely that the first check was written by Steven Vickers.

					;;;$34BC
USR_:		CALL	STK_FETCH	; routine STK_FETCH fetches the string parameters.
		DEC	BC		; decrease BC by
		LD	A,B		; one to test
		OR	C		; the length.
		JR	NZ,REPORT_A	; to REPORT_A if not a single character.

		LD	A,(DE)		; fetch the character
		CALL	ALPHA		; routine ALPHA sets carry if 'A-Z' or 'a-z'.
		JR	C,USR_RANGE	; forward to USR_RANGE if ascii.

		SUB	$90		; make udgs range 0-20d
		JR	C,REPORT_A	; to REPORT_A if too low. e.g. usr " ".

		CP	$15		; Note. this test is not necessary.
		JR	NC,REPORT_A	; to REPORT_A if higher than 20.

		INC	A		; make range 1-21d to match LSBs of ascii

					;;;$34D3
USR_RANGE:	DEC	A		; make range of bits 0-4 start at zero
		ADD	A,A		; multiply by eight
		ADD	A,A		; and lose any set bits
		ADD	A,A		; range now 0 - 25*8
		CP	$A8		; compare to 21*8
		JR	NC,REPORT_A	; to REPORT_A if originally higher 
					; than 'U','u' or graphics U.
		LD	BC,(UDG)	; fetch the UDG system variable value.
		ADD	A,C		; add the offset to character
		LD	C,A		; and store back in register C.
		JR	NC,USR_STACK	; forward to USR_STACK if no overflow.

		INC	B		; increment high byte.

					;;;$34E4
USR_STACK:	JP	STACK_BC	; jump back and exit via STACK_BC to store

					;;;$34E7
REPORT_A:	RST	08H		; ERROR_1
		DEFB	$09		; Error Report: Invalid argument

;--------------
; Test for zero
;--------------
; Test if top value on calculator stack is zero.
; The carry flag is set if the last value is zero but no registers are altered.
; All five bytes will be zero but first four only need be tested.
; On entry HL points to the exponent the first byte of the value.

					;;;$34E9
TEST_ZERO:	PUSH	HL		; preserve HL which is used to address.
		PUSH	BC		; preserve BC which is used as a store.
		LD	B,A		; preserve A in B.
		LD	A,(HL)		; load first byte to accumulator
		INC	HL		; advance.
		OR	(HL)		; OR with second byte and clear carry.
		INC	HL		; advance.
		OR	(HL)		; OR with third byte.
		INC	HL		; advance.
		OR	(HL)		; OR with fourth byte.
		LD	A,B		; restore A without affecting flags.
		POP	BC		; restore the saved
		POP	HL		; registers.
		RET	NZ		; return if not zero and with carry reset.

		SCF			; set the carry flag.
		RET			; return with carry set if zero.

;------------------------
; Greater than zero ($37)
;------------------------
; Test if the last value on the calculator stack is greater than zero.
; This routine is also called directly from the end-tests of the comparison 
; routine.

					;;;$34F9
GREATER_0:	CALL	TEST_ZERO	; routine TEST_ZERO
		RET	C		; return if was zero as this
					; is also the Boolean 'false' value.
		LD	A,$FF		; prepare XOR mask for sign bit
		JR	SIGN_TO_C	; forward to SIGN_TO_C
					; to put sign in carry
					; (carry will become set if sign is positive)
					; and then overwrite location with 1 or 0 
					; as appropriate.

;--------------------------
; Handle NOT operator ($30)
;--------------------------
; This overwrites the last value with 1 if it was zero else with zero
; if it was any other value.
;
; e.g NOT 0 returns 1, NOT 1 returns 0, NOT -3 returns 0.
;
; The subroutine is also called directly from the end-tests of the comparison
; operator.

					;;;$3501
NOT_:		CALL	TEST_ZERO	; routine TEST_ZERO sets carry if zero
		JR	FP_0_1		; to FP_0_1 to overwrite operand with
					; 1 if carry is set else to overwrite with zero.

;---------------------
; Less than zero ($36)
;---------------------
; Destructively test if last value on calculator stack is less than zero.
; Bit 7 of second byte will be set if so.

					;;;$3506
LESS_0:		XOR	A		; set xor mask to zero
					; (carry will become set if sign is negative).

					; transfer sign of mantissa to Carry Flag.

					;;;$3507
SIGN_TO_C:	INC	HL		; address 2nd byte.
		XOR	(HL)		; bit 7 of HL will be set if number is negative.
		DEC	HL		; address 1st byte again.
		RLCA			; rotate bit 7 of A to carry.

;------------
; Zero or one
;------------
; This routine places an integer value zero or one at the addressed location
; of calculator stack or MEM area. The value one is written if carry is set on 
; entry else zero.

					;;;$350B
					;; FP-0/1
FP_0_1:		PUSH	HL		; save pointer to the first byte
		LD	A,$00		; load accumulator with zero - without disturbing flags.
		LD	(HL),A		; zero to first byte
		INC	HL		; address next
		LD	(HL),A		; zero to 2nd byte
		INC	HL		; address low byte of integer
		RLA			; carry to bit 0 of A
		LD	(HL),A		; load one or zero to low byte.
		RRA			; restore zero to accumulator.
		INC	HL		; address high byte of integer.
		LD	(HL),A		; put a zero there.
		INC	HL		; address fifth byte.
		LD	(HL),A		; put a zero there.
		POP	HL		; restore pointer to the first byte.
		RET			; return.

;-------------------------
; Handle OR operator ($07)
;-------------------------
; The Boolean OR operator. eg. X OR Y
; The result is zero if both values are zero else a non-zero value.
;
; e.g.	 0 OR 0  returns 0.
;	-3 OR 0  returns -3.
;	 0 OR -3 returns 1.
;	-3 OR 2  returns 1.
;
; A binary operation.
; On entry HL points to first operand (X) and DE to second operand (Y).

					;;;$351B
OR_:		EX	DE,HL		; make HL point to second number
		CALL	TEST_ZERO	; routine TEST_ZERO
		EX	DE,HL		; restore pointers
		RET	C		; return if result was zero - first operand, 
					; now the last value, is the result.
		SCF			; set carry flag
		JR	FP_0_1		; back to FP_0_1 to overwrite the first operand
					; with the value 1.


;-------------------------------
; Handle number AND number ($08)
;-------------------------------
; The Boolean AND operator.
;
; e.g.	-3 AND 2  returns -3.
;	-3 AND 0  returns 0.
;	 0 AND -2 returns 0.
;	 0 AND 0  returns 0.
;
; Compare with OR routine above.

					;;;$3524
NO_AND_NO:	EX	DE,HL		; make HL address second operand.
		CALL	TEST_ZERO	; routine TEST_ZERO sets carry if zero.
		EX	DE,HL		; restore pointers.
		RET	NC		; return if second non-zero, first is result.

		AND	A		; else clear carry.
		JR	FP_0_1		; back to FP_0_1 to overwrite first operand
					; with zero for return value.

;-------------------------------
; Handle string AND number ($10)
;-------------------------------
; e.g. "You Win" AND score>99 will return the string if condition is true
; or the null string if false.

					;;;$352D
STR_AND_NO:	EX	DE,HL		; make HL point to the number.
		CALL	TEST_ZERO	; routine TEST_ZERO.
		EX	DE,HL		; restore pointers. 
		RET	NC		; return if number was not zero - the string is the result.

					; if the number was zero (false) then the null string must be returned by
					; altering the length of the string on the calculator stack to zero.

		PUSH	DE		; save pointer to the now obsolete number 
					; (which will become the new STKEND)
		DEC	DE		; point to the 5th byte of string descriptor.
		XOR	A		; clear the accumulator.
		LD	(DE),A		; place zero in high byte of length.
		DEC	DE		; address low byte of length.
		LD	(DE),A		; place zero there - now the null string.
		POP	DE		; restore pointer - new STKEND.
		RET			; return.

;------------------------------------
; Perform comparison ($09-$0E, $11-$16)
;------------------------------------
; True binary operations.
;
; A single entry point is used to evaluate six numeric and six string
; comparisons. On entry, the calculator literal is in the B register and
; the two numeric values, or the two string parameters, are on the 
; calculator stack.
; The individual bits of the literal are manipulated to group similar
; operations although the SUB 8 instruction does nothing useful and merely
; alters the string test bit.
; Numbers are compared by subtracting one from the other, strings are 
; compared by comparing every character until a mismatch, or the end of one
; or both, is reached.
;
; Numeric Comparisons.
; --------------------
; The 'x>y' example is the easiest as it employs straight-thru logic.
; Number y is subtracted from x and the result tested for GREATER_0 yielding
; a final value 1 (true) or 0 (false). 
; For 'x<y' the same logic is used but the two values are first swapped on the
; calculator stack. 
; For 'x=y' NOT is applied to the subtraction result yielding true if the
; difference was zero and false with anything else. 
; The first three numeric comparisons are just the opposite of the last three
; so the same processing steps are used and then a final NOT is applied.
;
; literal    Test   No  sub 8       ExOrNot  1st RRCA  exch sub  ?   End-Tests
; =========  ====   == ======== === ======== ========  ==== ===  =  === === ===
; NO_L_EQL   x<=y   09 00000001 dec 00000000 00000000  ---- x-y  ?  --- >0? NOT
; NO_GR_EQL  x>=y   0A 00000010 dec 00000001 10000000c swap y-x  ?  --- >0? NOT
; NOS_NEQL   x<>y   0B 00000011 dec 00000010 00000001  ---- x-y  ?  NOT --- NOT
; NO_GRTR    x>y    0C 00000100  -  00000100 00000010  ---- x-y  ?  --- >0? ---
; NO_LESS    x<y    0D 00000101  -  00000101 10000010c swap y-x  ?  --- >0? ---
; NOS_EQL    x=y    0E 00000110  -  00000110 00000011  ---- x-y  ?  NOT --- ---
;
;                                                           comp -> C/F
;                                                           ====    ===
; STR_L_EQL  x$<=y$ 11 00001001 dec 00001000 00000100  ---- x$y$ 0  !or >0? NOT
; STR_GR_EQL x$>=y$ 12 00001010 dec 00001001 10000100c swap y$x$ 0  !or >0? NOT
; STRS_NEQL  x$<>y$ 13 00001011 dec 00001010 00000101  ---- x$y$ 0  !or >0? NOT
; STR_GRTR   x$>y$  14 00001100  -  00001100 00000110  ---- x$y$ 0  !or >0? ---
; STR_LESS   x$<y$  15 00001101  -  00001101 10000110c swap y$x$ 0  !or >0? ---
; STRS_EQL   x$=y$  16 00001110  -  00001110 00000111  ---- x$y$ 0  !or >0? ---
;
; String comparisons are a little different in that the eql/neql carry flag
; from the 2nd RRCA is, as before, fed into the first of the end tests but
; along the way it gets modified by the comparison process. The result on the
; stack always starts off as zero and the carry fed in determines if NOT is 
; applied to it. So the only time the GREATER_0 test is applied is if the
; stack holds zero which is not very efficient as the test will always yield
; zero. The most likely explanation is that there were once separate end tests
; for numbers and strings.

					;;;$353B
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
STRS_EQL:

		LD	A,B		; transfer literal to accumulator.
		SUB	$08		; subtract eight - which is not useful. 
		BIT	2,A		; isolate '>', '<', '='.
		JR	NZ,EX_OR_NOT	; skip to EX_OR_NOT with these.

		DEC	A		; else make $00-$02, $08-$0A to match bits 0-2.

					;;;$3543
EX_OR_NOT:	RRCA			; the first RRCA sets carry for a swap. 
		JR	NC,NU_OR_STR	; forward to NU_OR_STR with other 8 cases

					; for the other 4 cases the two values on the calculator stack are exchanged.

		PUSH	AF		; save A and carry.
		PUSH	HL		; save HL - pointer to first operand.
					; (DE points to second operand).
		CALL	EXCHANGE	; routine EXCHANGE swaps the two values.
					; (HL = second operand, DE = STKEND)
		POP	DE		; DE = first operand
		EX	DE,HL		; as we were.
		POP	AF		; restore A and carry.

					; Note. it would be better if the 2nd RRCA preceded the string test.
					; It would save two duplicate bytes and if we also got rid of that sub 8 
					; at the beginning we wouldn't have to alter which bit we test.

					;;;$354E
NU_OR_STR:	BIT	2,A		; test if a string comparison.
		JR	NZ,STRINGS	; forward to STRINGS if so.

					; continue with numeric comparisons.

		RRCA			; 2nd RRCA causes eql/neql to set carry.
		PUSH	AF		; save A and carry
		CALL	SUBTRACT	; routine SUBTRACT leaves result on stack.
		JR	END_TESTS	; forward to END_TESTS

					;;;$3559
STRINGS:	RRCA			; 2nd RRCA causes eql/neql to set carry.
		PUSH	AF		; save A and carry.
		CALL	STK_FETCH	; routine STK_FETCH gets 2nd string params
		PUSH	DE		; save start2 *.
		PUSH	BC		; and the length.
		CALL	STK_FETCH	; routine STK_FETCH gets 1st string 
					; parameters - start in DE, length in BC.
		POP	HL		; restore length of second to HL.

					; A loop is now entered to compare, by subtraction, each corresponding character
					; of the strings. For each successful match, the pointers are incremented and 
					; the lengths decreased and the branch taken back to here. If both string 
					; remainders become null at the same time, then an exact match exists.

					;;;$3564
BYTE_COMP:	LD	A,H		; test if the second string
		OR	L		; is the null string and hold flags.
		EX	(SP),HL		; put length2 on stack, bring start2 to HL *.
		LD	A,B		; hi byte of length1 to A
		JR	NZ,SEC_PLUS	; forward to SEC_PLUS if second not null.

		OR	C		; test length of first string.

					;;;$356B
SECND_LOW:	POP	BC		; pop the second length off stack.
		JR	Z,BOTH_NULL	; forward to BOTH_NULL if first string is also
					; of zero length.

					; the true condition - first is longer than second (SECND-LESS)

		POP	AF		; restore carry (set if eql/neql)
		CCF			; complement carry flag.
					; Note. equality becomes false.
					; Inequality is true. By swapping or applying
					; a terminal 'not', all comparisons have been
					; manipulated so that this is success path. 
		JR	STR_TEST	; forward to leave via STR_TEST

					; the branch was here with a match

					;;;$3572
BOTH_NULL:	POP	AF		; restore carry - set for eql/neql
		JR	STR_TEST	; forward to STR_TEST
  
					; the branch was here when 2nd string not null and low byte of first is yet
					; to be tested.

					;;;$3575
SEC_PLUS:	OR	C		; test the length of first string.
		JR	Z,FRST_LESS	; forward to FRST_LESS if length is zero.

					; both strings have at least one character left.

		LD	A,(DE)		; fetch character of first string. 
		SUB	(HL)		; subtract with that of 2nd string.
		JR	C,FRST_LESS	; forward to FRST_LESS if carry set

		JR	NZ,SECND_LOW	; back to SECND_LOW and then STR_TEST
					; if not exact match.

		DEC	BC		; decrease length of 1st string.
		INC	DE		; increment 1st string pointer.
		INC	HL		; increment 2nd string pointer.
		EX	(SP),HL		; swap with length on stack
		DEC	HL		; decrement 2nd string length
		JR	BYTE_COMP	; back to BYTE_COMP

					; the false condition.

					;;;$3585
FRST_LESS:	POP	BC		; discard length
		POP	AF		; pop A
		AND	A		; clear the carry for false result.

					; exact match and x$>y$ rejoin here

					;;;$3588
STR_TEST:	PUSH	AF		; save A and carry
		RST	28H		;; FP_CALC
		DEFB	$A0		;;STK_ZERO	an initial false value.
		DEFB	$38		;;END_CALC

					; both numeric and string paths converge here.

					;;;$358C
END_TESTS:	POP	AF		; pop carry  - will be set if eql/neql
		PUSH	AF		; save it again.
		CALL	C,NOT_		; routine NOT sets true(1) if equal(0)
					; or, for strings, applies true result.
		POP	AF		; pop carry and
		PUSH	AF		; save A
		CALL	NC,GREATER_0	; routine GREATER_0 tests numeric subtraction 
					; result but also needlessly tests the string 
					; value for zero - it must be.
		POP	AF		; pop A 
		RRCA			; the third RRCA - test for '<=', '>=' or '<>'.
		CALL	NC,NOT_		; apply a terminal NOT if so.
		RET			; return.

;---------------------------
; String concatenation ($17)
;---------------------------
; This literal combines two strings into one e.g. LET a$ = b$ + c$
; The two parameters of the two strings to be combined are on the stack.

					;;;$359C
STRS_ADD:	CALL	STK_FETCH	; routine STK_FETCH fetches string parameters
					; and deletes calculator stack entry.
		PUSH	DE		; save start address.
		PUSH	BC		; and length.
		CALL	STK_FETCH	; routine STK_FETCH for first string
		POP	HL		; re-fetch first length
		PUSH	HL		; and save again
		PUSH	DE		; save start of second string
		PUSH	BC		; and it's length.
		ADD	HL,BC		; add the two lengths.
		LD	B,H		; transfer to BC
		LD	C,L		; and create
		RST	30H		; BC_SPACES in workspace.
					; DE points to start of space.
		CALL	STK_STO_D	; routine STK_STO_D stores parameters
					; of new string updating STKEND.
		POP	BC		; length of first
		POP	HL		; address of start
		LD	A,B		; test for
		OR	C		; zero length.
		JR	Z,OTHER_STR	; to OTHER_STR if null string

		LDIR			; copy string to workspace.

					;;;$35B7
OTHER_STR:	POP	BC		; now second length
		POP	HL		; and start of string
		LD	A,B		; test this one
		OR	C		; for zero length
		JR	Z,STK_PNTRS	; skip forward to STK_PNTRS if so as complete.

		LDIR			; else copy the bytes.
					; and continue into next routine which
					; sets the calculator stack pointers.

;---------------------
; Check stack pointers
;---------------------
; Register DE is set to STKEND and HL, the result pointer, is set to five 
; locations below this.
; This routine is used when it is inconvenient to save these values at the
; time the calculator stack is manipulated due to other activity on the 
; machine stack.
; This routine is also used to terminate the VAL and READ_IN  routines for
; the same reason and to initialize the calculator stack at the start of
; the CALCULATE routine.

					;;;$35BF
STK_PNTRS:	LD	HL,(STKEND)	; fetch STKEND value from system variable.
		LD	DE,$FFFB	; the value -5
		PUSH	HL		; push STKEND value.
		ADD	HL,DE		; subtract 5 from HL.
		POP	DE		; pop STKEND to DE.
		RET			; return.

;------------------
; Handle CHR$ ($2F)
;------------------
; This function returns a single character string that is a result of 
; converting a number in the range 0-255 to a string e.g. CHR$ 65 = "A".

					;;;$35C9
CHRS:		CALL	FP_TO_A		; routine FP_TO_A puts the number in A.
		JR	C,REPORT_BD	; forward to REPORT_BD if overflow
		JR	NZ,REPORT_BD	; forward to REPORT_BD if negative

		PUSH	AF		; save the argument.
		LD	BC,$0001	; one space required.
		RST	30H		; BC_SPACES makes DE point to start
		POP	AF		; restore the number.
		LD	(DE),A		; and store in workspace
		CALL	STK_STO_D	; routine STK_STO_D stacks descriptor.
		EX	DE,HL		; make HL point to result and DE to STKEND.
		RET			; return.

					;;;$35DC
REPORT_BD:	RST	08H		; ERROR_1
		DEFB	$0A		; Error Report: Integer out of range

;-------------------------------
; Handle VAL and VAL$ ($1D, $18)
;-------------------------------
; VAL treats the characters in a string as a numeric expression.
;	e.g. VAL "2.3" = 2.3, VAL "2+4" = 6, VAL ("2" + "4") = 24.
; VAL$ treats the characters in a string as a string expression.
;	e.g. VAL$ (z$+"(2)") = a$(2) if z$ happens to be "a$".

					;;;$35DE
VAL:
VALS:
		LD	HL,(CH_ADD)	; fetch value of system variable CH_ADD
		PUSH	HL		; and save on the machine stack.
		LD	A,B		; fetch the literal $1D or $18.
		ADD	A,$E3		; add $E3 to form $00 (setting carry) or $FB.
		SBC	A,A		; now form $FF bit 6 = numeric result
					; or $00 bit 6 = string result.
		PUSH	AF		; save this mask on the stack
		CALL	STK_FETCH	; routine STK_FETCH fetches the string operand
					; from calculator stack.
		PUSH	DE		; save the address of the start of the string.
		INC	BC		; increment the length for a carriage return.
		RST	30H		; BC_SPACES creates the space in workspace.
		POP	HL		; restore start of string to HL.
		LD	(CH_ADD),DE	; load CH_ADD with start DE in workspace.
		PUSH	DE		; save the start in workspace
		LDIR			; copy string from program or variables or
					; workspace to the workspace area.
		EX	DE,HL		; end of string + 1 to HL
		DEC	HL		; decrement HL to point to end of new area.
		LD	(HL),$0D	; insert a carriage return at end.
		RES	7,(IY+$01)	; update FLAGS  - signal checking syntax.
		CALL	SCANNING	; routine SCANNING evaluates string
					; expression and result.
		RST	18H		; GET_CHAR fetches next character.
		CP	$0D		; is it the expected carriage return ?
		JR	NZ,V_RPORT_C	; forward to V_RPORT_C if not
					; 'Nonsense in Basic'.
		POP	HL		; restore start of string in workspace.
		POP	AF		; restore expected result flag (bit 6).
		XOR	(IY+$01)	; xor with FLAGS now updated by SCANNING.
		AND	$40		; test bit 6 - should be zero if result types match.

					;;;$360C
V_RPORT_C:	JP	NZ,REPORT_C	; jump back to REPORT_C with a result mismatch.
		LD	(CH_ADD),HL	; set CH_ADD to the start of the string again.
		SET	7,(IY+$01)	; update FLAGS  - signal running program.
		CALL	SCANNING	; routine SCANNING evaluates the string
					; in full leaving result on calculator stack.
		POP	HL		; restore saved character address in program.
		LD	(CH_ADD),HL	; and reset the system variable CH_ADD.
		JR	STK_PNTRS	; back to exit via STK_PNTRS.
					; resetting the calculator stack pointers
					; HL and DE from STKEND as it wasn't possible 
					; to preserve them during this routine.

;------------------
; Handle STR$ ($2E)
;------------------

					;;;$361F
STRS:		LD	BC,$0001	; create an initial byte in workspace
		RST	30H		; using BC_SPACES restart.
		LD	(K_CUR),HL	; set system variable K_CUR to new location.
		PUSH	HL		; and save start on machine stack also.
		LD	HL,(CURCHL)	; fetch value of system variable CURCHL
		PUSH	HL		; and save that too.
		LD	A,$FF		; select system channel 'R'.
		CALL	CHAN_OPEN	; routine CHAN_OPEN opens it.
		CALL	PRINT_FP	; routine PRINT_FP outputs the number to
					; workspace updating K-CUR.
		POP	HL		; restore current channel.
		CALL	CHAN_FLAG	; routine CHAN_FLAG resets flags.
		POP	DE		; fetch saved start of string to DE.
		LD	HL,(K_CUR)	; load HL with end of string from K_CUR.
		AND	A		; prepare for true subtraction.
		SBC	HL,DE		; subtract start from end to give length.
		LD	B,H		; transfer the length to
		LD	C,L		; the BC register pair.
		CALL	STK_STO_D	; routine STK_STO_D stores string parameters
					; on the calculator stack.
		EX	DE,HL		; HL = last value, DE = STKEND.
		RET			; return.

;--------------
; Read-in ($1A)
;--------------
; This is the calculator literal used by the INKEY$ function when a '#'
; is encountered after the keyword.
; INKEY$ # does not interact correctly with the keyboard, #0 or #1, and
; it's uses are for other channels.

					;;;$3645
READ_IN:	CALL	FIND_INT1	; routine FIND_INT1 fetches stream to A
		CP	$10		; compare with 16 decimal.
		JP	NC,REPORT_BB	; jump to REPORT_BB if not in range 0 - 15.
					; 'Integer out of range'
					; (REPORT_BD is within range)
		LD	HL,(CURCHL)	; fetch current channel CURCHL
		PUSH	HL		; save it
		CALL	CHAN_OPEN	; routine CHAN_OPEN opens channel
		CALL	INPUT_AD	; routine INPUT_AD - the channel must have an
					; input stream or else error here from stream stub.
		LD	BC,$0000	; initialize length of string to zero
		JR	NC,R_I_STORE	; forward to R_I_STORE if no key detected.
		INC	C		; increase length to one.
		RST	30H		; BC_SPACES creates space for one character in workspace.
		LD	(DE),A		; the character is inserted.

					;;;$365F
R_I_STORE:	CALL	STK_STO_D	; routine STK_STO_D stacks the string parameters.
		POP	HL		; restore current channel address
		CALL	CHAN_FLAG	; routine CHAN_FLAG resets current channel
					; system variable and flags.
		JP	STK_PNTRS	; jump back to STK_PNTRS

;------------------
; Handle CODE ($1C)
;------------------
; Returns the ascii code of a character or first character of a string
; e.g. CODE "Aardvark" = 65, CODE "" = 0.

					;;;$3669
CODE:	CALL	STK_FETCH		; routine STK_FETCH to fetch and delete the
					; string parameters.
					; DE points to the start, BC holds the length.
		LD	A,B		; test length
		OR	C		; of the string.
		JR	Z,STK_CODE	; skip to STK_CODE with zero if the null string.

		LD	A,(DE)		; else fetch the first character.

					;;;$3671
STK_CODE:	JP	STACK_A		; jump back to STACK_A (with memory check)

;-----------------
; Handle LEN ($1E)
;-----------------
; Returns the length of a string.
; In Sinclair Basic strings can be more than twenty thousand characters long
; so a sixteen-bit register is required to store the length

					;;;$3674
LEN:		CALL	STK_FETCH	; routine STK_FETCH to fetch and delete the
					; string parameters from the calculator stack.
					; register BC now holds the length of string.
		JP	STACK_BC	; jump back to STACK_BC to save result on the
					; calculator stack (with memory check).

;---------------------------
; Decrease the counter ($35)
;---------------------------
; The calculator has an instruction that decrements a single-byte
; pseudo-register and makes consequential relative jumps just like
; the Z80's DJNZ instruction.

					;;;$367A
DEC_JR_NZ:	EXX			; switch in set that addresses code
		PUSH	HL		; save pointer to offset byte
		LD	HL,BREG		; address BREG in system variables
		DEC	(HL)		; decrement it
		POP	HL		; restore pointer
		JR	NZ,JUMP_2	; to JUMP_2 if not zero

		INC	HL		; step past the jump length.
		EXX			; switch in the main set.
		RET			; return.

					; Note. as a general rule the calculator avoids using the IY register
					; otherwise the cumbersome 4 instructions in the middle could be replaced by
					; dec (iy+$2d) - three bytes instead of six.

;-----------
; Jump ($33)
;-----------
; This enables the calculator to perform relative jumps just like
; the Z80 chip's JR instruction

					;;;$3686
JUMP:		EXX			;switch in pointer set

					;;;$3687
JUMP_2:		LD	E,(HL)		; the jump byte 0-127 forward, 128-255 back.
		LD	A,E		; transfer to accumulator.
		RLA			; if backward jump, carry is set.
		SBC	A,A		; will be $FF if backward or $00 if forward.
		LD	D,A		; transfer to high byte.
		ADD	HL,DE		; advance calculator pointer forward or back.
		EXX			; switch back.
		RET			; return.

;-------------------
; Jump on true ($00)
;-------------------
; This enables the calculator to perform conditional relative jumps
; dependent on whether the last test gave a true result

					;;;$368F
JUMP_TRUE:	INC	DE		; collect the 
		INC	DE		; third byte
		LD	A,(DE)		; of the test
		DEC	DE		; result and
		DEC	DE		; backtrack.
		AND	A		; is result 0 or 1 ? 
		JR	NZ,JUMP		; back to JUMP if true (1).

		EXX			; else switch in the pointer set.
		INC	HL		; step past the jump length.
		EXX			; switch in the main set.
		RET			; return.

;-------------------------
; End of calculation ($38)
;-------------------------
; The END_CALC literal terminates a mini-program written in the Spectrum's
; internal language.

					;;;$369B
END_CALC:	POP	AF		; drop the calculator return address RE_ENTRY
		EXX			; switch to the other set.
		EX	(SP),HL		; transfer H'L' to machine stack for the
					; return address.
					; when exiting recursion then the previous
					; pointer is transferred to H'L'.
		EXX			; back to main set.
		RET			; return.


;-------------
; Modulus ($32)
;-------------

					;;;$36A0
N_MOD_M:	RST	28H		;; FP_CALC	17, 3.
		DEFB	$C0		;;st-mem-0	17, 3.
		DEFB	$02		;;DELETE	17.
		DEFB	$31		;;DUPLICATE	17, 17.
		DEFB	$E0		;;get-mem-0	17, 17, 3.
		DEFB	$05		;;DIVISION	17, 17/3.
		DEFB	$27		;;INT		17, 5.
		DEFB	$E0		;;get-mem-0	17, 5, 3.
		DEFB	$01		;;EXCHANGE	17, 3, 5.
		DEFB	$C0		;;st-mem-0	17, 3, 5.
		DEFB	$04		;;MULTIPLY	17, 15.
		DEFB	$03		;;SUBTRACT	2.
		DEFB	$E0		;;get-mem-0	2, 5.
		DEFB	$38		;;END_CALC	2, 5.

		RET			; return.


;-----------------
; Handle INT ($27)
;-----------------
; This function returns the integer of x, which is just the same as truncate
; for positive numbers. The truncate literal truncates negative numbers
; upwards so that -3.4 gives -3 whereas the Basic INT function has to
; truncate negative numbers down so that INT -3.4 is 4.
; It is best to work through using +-3.4 as examples.

					;;;$36AF
INT:		RST	28H		;; FP_CALC		x.	(= 3.4 or -3.4).
		DEFB	$31		;;DUPLICATE		x, x.
		DEFB	$36		;;LESS_0		x, (1/0)
		DEFB	$00		;;JUMP_TRUE		x, (1/0)
		DEFB	$04		;;to X_NEG
		DEFB	$3A		;;TRUNCATE		trunc 3.4 = 3.
		DEFB	$38		;;END_CALC		3.

		RET			; return with + int x on stack.

					;;;$36B7
X_NEG:		DEFB	$31		;;DUPLICATE		-3.4, -3.4.
		DEFB	$3A		;;TRUNCATE		-3.4, -3.
		DEFB	$C0		;;st-mem-0		-3.4, -3.
		DEFB	$03		;;SUBTRACT		-.4
		DEFB	$E0		;;get-mem-0		-.4, -3.
		DEFB	$01		;;EXCHANGE		-3, -.4.
		DEFB	$30		;;NOT			-3, (0).
		DEFB	$00		;;JUMP_TRUE		-3.
		DEFB	$03		;;to EXIT		-3.
		DEFB	$A1		;;STK_ONE		-3, 1.
		DEFB	$03		;;SUBTRACT		-4.

					;;;$36C2
EXIT:		DEFB	$38		;;END_CALC		-4.

		RET			; return.

;-----------------
; Exponential ($26)
;-----------------

					;;;$36C4
EXP:		RST	28H		;; FP_CALC
		DEFB	$3D		;;RE_STACK
		DEFB	$34		;;STK_DATA
		DEFB	$F1		;;Exponent: $81, Bytes: 4
		DEFB	$38,$AA,$3B,$29 ;;
		DEFB	$04		;;MULTIPLY
		DEFB	$31		;;DUPLICATE
		DEFB	$27		;;INT
		DEFB	$C3		;;st-mem-3
		DEFB	$03		;;SUBTRACT
		DEFB	$31		;;DUPLICATE
		DEFB	$0F		;;ADDITION
		DEFB	$A1		;;STK_ONE
		DEFB	$03		;;SUBTRACT
		DEFB	$88		;;series-08
		DEFB	$13		;;Exponent: $63, Bytes: 1
		DEFB	$36		;;(+00,+00,+00)
		DEFB	$58		;;Exponent: $68, Bytes: 2
		DEFB	$65,$66		;;(+00,+00)
		DEFB	$9D		;;Exponent: $6D, Bytes: 3
		DEFB	$78,$65,$40	;;(+00)
		DEFB	$A2		;;Exponent: $72, Bytes: 3
		DEFB	$60,$32,$C9	;;(+00)
		DEFB	$E7		;;Exponent: $77, Bytes: 4
		DEFB	$21,$F7,$AF,$24 ;;
		DEFB	$EB		;;Exponent: $7B, Bytes: 4
		DEFB	$2F,$B0,$B0,$14 ;;
		DEFB	$EE		;;Exponent: $7E, Bytes: 4
		DEFB	$7E,$BB,$94,$58 ;;
		DEFB	$F1		;;Exponent: $81, Bytes: 4
		DEFB	$3A,$7E,$F8,$CF ;;
		DEFB	$E3		;;get-mem-3
		DEFB	$38		;;END_CALC

		CALL	FP_TO_A		; routine FP_TO_A
		JR	NZ,N_NEGTV	; to N_NEGTV

		JR	C,REPORT_6B	; to REPORT_6B

		ADD	A,(HL)		;
		JR	NC,RESULT_OK	; to RESULT_OK

					;;;$3703
REPORT_6B:	RST	08H		; ERROR_1
		DEFB	$05		; Error Report: Number too big

					;; N_NEGTV
N_NEGTV:	JR	C,RSLT_ZERO	; to RSLT_ZERO

		SUB	(HL)
		JR	NC,RSLT_ZERO	; to RSLT_ZERO

		NEG			; Negate

					;;;$370C
RESULT_OK:	LD	(HL),A
		RET			; return.

					;;;$370E
RSLT_ZERO:	RST	28H		;; FP_CALC
		DEFB	$02		;;DELETE
		DEFB	$A0		;;STK_ZERO
		DEFB	$38		;;END_CALC

		RET			; return.


;------------------------
; Natural logarithm ($25)
;------------------------

					;;;$3713
LN:		RST	28H		;; FP_CALC
		DEFB	$3D		;;RE_STACK
		DEFB	$31		;;DUPLICATE
		DEFB	$37		;;GREATER_0
		DEFB	$00		;;JUMP_TRUE
		DEFB	$04		;;to VALID
		DEFB	$38		;;END_CALC

					;;;$371A
REPORT_AB:	RST	08H		; ERROR_1
		DEFB	$09		; Error Report: Invalid argument

					;;;$371C
VALID:		DEFB	$A0		;;STK_ZERO
		DEFB	$02		;;DELETE
		DEFB	$38		;;END_CALC

		LD	A,(HL)	
		LD	(HL),$80
		CALL	STACK_A		; routine STACK_A
		RST	28H		;; FP_CALC
		DEFB	$34		;;STK_DATA
		DEFB	$38		;;Exponent: $88, Bytes: 1
		DEFB	$00		;;(+00,+00,+00)
		DEFB	$03		;;SUBTRACT
		DEFB	$01		;;EXCHANGE
		DEFB	$31		;;DUPLICATE
		DEFB	$34		;;STK_DATA
		DEFB	$F0		;;Exponent: $80, Bytes: 4
		DEFB	$4C,$CC,$CC,$CD ;;
		DEFB	$03		;;SUBTRACT
		DEFB	$37		;;GREATER_0
		DEFB	$00		;;JUMP_TRUE
		DEFB	$08		;;to GRE_8
		DEFB	$01		;;EXCHANGE
		DEFB	$A1		;;STK_ONE
		DEFB	$03		;;SUBTRACT
		DEFB	$01		;;EXCHANGE
		DEFB	$38		;;END_CALC

		INC	(HL)
		RST	28H		;; FP_CALC

					;;;$373D
GRE_8:		DEFB	$01		;;EXCHANGE
		DEFB	$34		;;STK_DATA
		DEFB	$F0		;;Exponent: $80, Bytes: 4
		DEFB	$31,$72,$17,$F8 ;;
		DEFB	$04		;;MULTIPLY
		DEFB	$01		;;EXCHANGE
		DEFB	$A2		;;STK_HALF
		DEFB	$03		;;SUBTRACT
		DEFB	$A2		;;STK_HALF
		DEFB	$03		;;SUBTRACT
		DEFB	$31		;;DUPLICATE
		DEFB	$34		;;STK_DATA
		DEFB	$32		;;Exponent: $82, Bytes: 1
		DEFB	$20		;;(+00,+00,+00)
		DEFB	$04		;;MULTIPLY
		DEFB	$A2		;;STK_HALF
		DEFB	$03		;;SUBTRACT
		DEFB	$8C		;;series-0C
		DEFB	$11		;;Exponent: $61, Bytes: 1
		DEFB	$AC		;;(+00,+00,+00)
		DEFB	$14		;;Exponent: $64, Bytes: 1
		DEFB	$09		;;(+00,+00,+00)
		DEFB	$56		;;Exponent: $66, Bytes: 2
		DEFB	$DA,$A5		;;(+00,+00)
		DEFB	$59		;;Exponent: $69, Bytes: 2
		DEFB	$30,$C5		;;(+00,+00)
		DEFB	$5C		;;Exponent: $6C, Bytes: 2
		DEFB	$90,$AA		;;(+00,+00)
		DEFB	$9E		;;Exponent: $6E, Bytes: 3
		DEFB	$70,$6F,$61	;;(+00)
		DEFB	$A1		;;Exponent: $71, Bytes: 3
		DEFB	$CB,$DA,$96	;;(+00)
		DEFB	$A4		;;Exponent: $74, Bytes: 3
		DEFB	$31,$9F,$B4	;;(+00)
		DEFB	$E7		;;Exponent: $77, Bytes: 4
		DEFB	$A0,$FE,$5C,$FC ;;
		DEFB	$EA		;;Exponent: $7A, Bytes: 4
		DEFB	$1B,$43,$CA,$36 ;;
		DEFB	$ED		;;Exponent: $7D, Bytes: 4
		DEFB	$A7,$9C,$7E,$5E ;;
		DEFB	$F0		;;Exponent: $80, Bytes: 4
		DEFB	$6E,$23,$80,$93 ;;
		DEFB	$04		;;MULTIPLY
		DEFB	$0F		;;ADDITION
		DEFB	$38		;;END_CALC

		RET			; return.

;----------------------
; Reduce argument ($39)
;----------------------

					;;;$3783
GET_ARGT:	RST	28H		;; FP_CALC
		DEFB	$3D		;;RE_STACK
		DEFB	$34		;;STK_DATA
		DEFB	$EE		;;Exponent: $7E, Bytes: 4
		DEFB	$22,$F9,$83,$6E
		DEFB	$04		;;MULTIPLY
		DEFB	$31		;;DUPLICATE
		DEFB	$A2		;;STK_HALF
		DEFB	$0F		;;ADDITION
		DEFB	$27		;;INT
		DEFB	$03		;;SUBTRACT
		DEFB	$31		;;DUPLICATE
		DEFB	$0F		;;ADDITION
		DEFB	$31		;;DUPLICATE
		DEFB	$0F		;;ADDITION
		DEFB	$31		;;DUPLICATE
		DEFB	$2A		;;ABS
		DEFB	$A1		;;STK_ONE
		DEFB	$03		;;SUBTRACT
		DEFB	$31		;;DUPLICATE
		DEFB	$37		;;GREATER_0
		DEFB	$C0		;;st-mem-0
		DEFB	$00		;;JUMP_TRUE
		DEFB	$04		;;to ZPLUS
		DEFB	$02		;;DELETE
		DEFB	$38		;;END_CALC

		RET			; return.

					;;;$37A1
ZPLUS:		DEFB	$A1		;;STK_ONE
		DEFB	$03		;;SUBTRACT
		DEFB	$01		;;EXCHANGE
		DEFB	$36		;;LESS_0
		DEFB	$00		;;JUMP_TRUE
		DEFB	$02		;;to YNEG
		DEFB	$1B		;;NEGATE

					;;;$37A8
YNEG:		DEFB	$38		;;END_CALC

		RET			; return.

;--------------------
; Handle cosine ($20)
;--------------------

					;;;$37AA
COS_:		RST	28H		;; FP_CALC
		DEFB	$39		;;GET_ARGT
		DEFB	$2A		;;ABS
		DEFB	$A1		;;STK_ONE
		DEFB	$03		;;SUBTRACT
		DEFB	$E0		;;get-mem-0
		DEFB	$00		;;JUMP_TRUE
		DEFB	$06		;;fwd to C_ENT
		DEFB	$1B		;;NEGATE
		DEFB	$33		;;jump
		DEFB	$03		;;fwd to C_ENT

;------------------
; Handle sine ($1F)
;------------------

					;;;$37B5
SIN_:		RST	28H		;; FP_CALC
		DEFB	$39		;;GET_ARGT

					;;;$37B7
C_ENT:		DEFB	$31		;;DUPLICATE
		DEFB	$31		;;DUPLICATE
		DEFB	$04		;;MULTIPLY
		DEFB	$31		;;DUPLICATE
		DEFB	$0F		;;ADDITION
		DEFB	$A1		;;STK_ONE
		DEFB	$03		;;SUBTRACT
		DEFB	$86		;;series-06
		DEFB	$14		;;Exponent: $64, Bytes: 1
		DEFB	$E6		;;(+00,+00,+00)
		DEFB	$5C		;;Exponent: $6C, Bytes: 2
		DEFB	$1F,$0B		;;(+00,+00)
		DEFB	$A3		;;Exponent: $73, Bytes: 3
		DEFB	$8F,$38,$EE	;;(+00)
		DEFB	$E9		;;Exponent: $79, Bytes: 4
		DEFB	$15,$63,$BB,$23 ;;
		DEFB	$EE		;;Exponent: $7E, Bytes: 4
		DEFB	$92,$0D,$CD,$ED ;;
		DEFB	$F1		;;Exponent: $81, Bytes: 4
		DEFB	$23,$5D,$1B,$EA ;;
		DEFB	$04		;;MULTIPLY
		DEFB	$38		;;END_CALC

		RET			; return.


;---------------------
; Handle tangent ($21)
;---------------------
; Evaluates tangent x as sin x/cos x.

					;;;$37DA
TAN:		RST	28H		;; FP_CALC	x.
		DEFB	$31		;;DUPLICATE	x, x.
		DEFB	$1F		;;SIN_		x, sin x.
		DEFB	$01		;;EXCHANGE	sin x, x.
		DEFB	$20		;;COS_		sin x, cos x.
		DEFB	$05		;;DIVISION	sin x/cos x (= tan x).
		DEFB	$38		;;END_CALC	tan x.

		RET			; return.

;-------------------
; Handle arctan ($24)
;-------------------
; the inverse tangent function with the result in radians.

					;;;$37E2
ATN:		CALL	RE_STACK	; routine RE_STACK
		LD	A,(HL)
		CP	$81
		JR	C,SMALL		; to SMALL

		RST	28H		;; FP_CALC
		DEFB	$A1		;;STK_ONE
		DEFB	$1B		;;NEGATE
		DEFB	$01		;;EXCHANGE
		DEFB	$05		;;DIVISION
		DEFB	$31		;;DUPLICATE
		DEFB	$36		;;LESS_0
		DEFB	$A3		;;STK_PI_2
		DEFB	$01		;;EXCHANGE
		DEFB	$00		;;JUMP_TRUE
		DEFB	$06		;;to CASES
		DEFB	$1B		;;NEGATE
		DEFB	$33		;;jump
		DEFB	$03		;;to CASES

					;;;$37F8
SMALL:		RST	28H		;; FP_CALC
		DEFB	$A0		;;STK_ZERO

					;;;$37FA
CASES:		DEFB	$01		;;EXCHANGE
		DEFB	$31		;;DUPLICATE
		DEFB	$31		;;DUPLICATE
		DEFB	$04		;;MULTIPLY
		DEFB	$31		;;DUPLICATE
		DEFB	$0F		;;ADDITION
		DEFB	$A1		;;STK_ONE
		DEFB	$03		;;SUBTRACT
		DEFB	$8C		;;series-0C
		DEFB	$10		;;Exponent: $60, Bytes: 1
		DEFB	$B2		;;(+00,+00,+00)
		DEFB	$13		;;Exponent: $63, Bytes: 1
		DEFB	$0E		;;(+00,+00,+00)
		DEFB	$55		;;Exponent: $65, Bytes: 2
		DEFB	$E4,$8D		;;(+00,+00)
		DEFB	$58		;;Exponent: $68, Bytes: 2
		DEFB	$39,$BC		;;(+00,+00)
		DEFB	$5B		;;Exponent: $6B, Bytes: 2
		DEFB	$98,$FD		;;(+00,+00)
		DEFB	$9E		;;Exponent: $6E, Bytes: 3
		DEFB	$00,$36,$75	;;(+00)
		DEFB	$A0		;;Exponent: $70, Bytes: 3
		DEFB	$DB,$E8,$B4	;;(+00)
		DEFB	$63		;;Exponent: $73, Bytes: 2
		DEFB	$42,$C4		;;(+00,+00)
		DEFB	$E6		;;Exponent: $76, Bytes: 4
		DEFB	$B5,$09,$36,$BE ;;
		DEFB	$E9		;;Exponent: $79, Bytes: 4
		DEFB	$36,$73,$1B,$5D ;;
		DEFB	$EC		;;Exponent: $7C, Bytes: 4
		DEFB	$D8,$DE,$63,$BE ;;
		DEFB	$F0		;;Exponent: $80, Bytes: 4
		DEFB	$61,$A1,$B3,$0C ;;
		DEFB	$04		;;MULTIPLY
		DEFB	$0F		;;ADDITION
		DEFB	$38		;;END_CALC

		RET			; return.


;--------------------
; Handle arcsin ($22)
;--------------------
; the inverse sine function with result in radians.
; Error A unless the argument is between -1 and +1.

					;;;$3833
ASN:		RST	28H		;; FP_CALC
		DEFB	$31		;;DUPLICATE
		DEFB	$31		;;DUPLICATE
		DEFB	$04		;;MULTIPLY
		DEFB	$A1		;;STK_ONE
		DEFB	$03		;;SUBTRACT
		DEFB	$1B		;;NEGATE
		DEFB	$28		;;SQR
		DEFB	$A1		;;STK_ONE
		DEFB	$0F		;;ADDITION
		DEFB	$05		;;DIVISION
		DEFB	$24		;;ATN
		DEFB	$31		;;DUPLICATE
		DEFB	$0F		;;ADDITION
		DEFB	$38		;;END_CALC

		RET			; return.


;--------------------
; Handle arccos ($23)
;--------------------
; the inverse cosine function with the result in radians. 
; Error A unless the argument is between -1 and +1.

					;;;$3843
ACS:		RST	28H		;; FP_CALC
		DEFB	$22		;;ASN
		DEFB	$A3		;;STK_PI_2
		DEFB	$03		;;SUBTRACT
		DEFB	$1B		;;NEGATE
		DEFB	$38		;;END_CALC

		RET			; return.


;-------------------------
; Handle square root ($28)
;-------------------------
; This routine is remarkable only in it's brevity - 7 bytes.
; It wasn't written here but in the ZX81 where the programmers had to squeeze
; a bulky operating sytem into an 8K ROM. it simply calculates 
;

					;;;$384A
SQR:		RST	28H		;; FP_CALC
		DEFB	$31		;;DUPLICATE
		DEFB	$30		;;NOT
		DEFB	$00		;;JUMP_TRUE
		DEFB	$1E		;;to LAST
		DEFB	$A2		;;STK_HALF
		DEFB	$38		;;END_CALC


;-------------------------
; Handle exponential ($06)
;-------------------------

					;;;$3851
TO_POWER:	RST	28H		;; FP_CALC
		DEFB	$01		;;EXCHANGE
		DEFB	$31		;;DUPLICATE
		DEFB	$30		;;NOT
		DEFB	$00		;;JUMP_TRUE
		DEFB	$07		;;to XISO
		DEFB	$25		;;LN
		DEFB	$04		;;MULTIPLY
		DEFB	$38		;;END_CALC

		JP	EXP		; to EXP

					;;;$385D
XISO:		DEFB	$02		;;DELETE
		DEFB	$31		;;DUPLICATE
		DEFB	$30		;;NOT
		DEFB	$00		;;JUMP_TRUE
		DEFB	$09		;;to ONE
		DEFB	$A0		;;STK_ZERO
		DEFB	$01		;;EXCHANGE
		DEFB	$37		;;GREATER_0
		DEFB	$00		;;JUMP_TRUE
		DEFB	$06		;;to LAST
		DEFB	$A1		;;STK_ONE
		DEFB	$01		;;EXCHANGE
		DEFB	$05		;;DIVISION

					;;;$386A
ONE:		DEFB	$02		;;DELETE
		DEFB	$A1		;;STK_ONE

					;;;$386C
LAST:		DEFB	$38		;;END_CALC

		RET			; return

;----------------
; Spare Locations
;----------------

					;;;$386E
SPARE:		DEFB	$FF, $FF
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;
		DEFB	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF;

;--------------
; Character set
;--------------

					;;;$3D00
CHAR_SET:	DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
; Character: !
		DEFB	%00000000
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00000000
		DEFB	%00010000
		DEFB	%00000000
; Character: "
		DEFB	%00000000
		DEFB	%00100100
		DEFB	%00100100
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
; Character: #
		DEFB	%00000000
		DEFB	%00100100
		DEFB	%01111110
		DEFB	%00100100
		DEFB	%00100100
		DEFB	%01111110
		DEFB	%00100100
		DEFB	%00000000
; Character: $
		DEFB	%00000000
		DEFB	%00001000
		DEFB	%00111110
		DEFB	%00101000
		DEFB	%00111110
		DEFB	%00001010
		DEFB	%00111110
		DEFB	%00001000
; Character: %
		DEFB	%00000000
		DEFB	%01100010
		DEFB	%01100100
		DEFB	%00001000
		DEFB	%00010000
		DEFB	%00100110
		DEFB	%01000110
		DEFB	%00000000
; Character: &
		DEFB	%00000000
		DEFB	%00010000
		DEFB	%00101000
		DEFB	%00010000
		DEFB	%00101010
		DEFB	%01000100
		DEFB	%00111010
		DEFB	%00000000
; Character: '
		DEFB	%00000000
		DEFB	%00001000
		DEFB	%00010000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
; Character: (
		DEFB	%00000000
		DEFB	%00000100
		DEFB	%00001000
		DEFB	%00001000
		DEFB	%00001000
		DEFB	%00001000
		DEFB	%00000100
		DEFB	%00000000
; Character: )
		DEFB	%00000000
		DEFB	%00100000
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00100000
		DEFB	%00000000
; Character: *
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00010100
		DEFB	%00001000
		DEFB	%00111110
		DEFB	%00001000
		DEFB	%00010100
		DEFB	%00000000
; Character: +
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00001000
		DEFB	%00001000
		DEFB	%00111110
		DEFB	%00001000
		DEFB	%00001000
		DEFB	%00000000
; Character: ,
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00001000
		DEFB	%00001000
		DEFB	%00010000
; Character: -
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00111110
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
; Character: .
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00011000
		DEFB	%00011000
		DEFB	%00000000
; Character: /
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000010
		DEFB	%00000100
		DEFB	%00001000
		DEFB	%00010000
		DEFB	%00100000
		DEFB	%00000000
; Character: 0
		DEFB	%00000000
		DEFB	%00111100
		DEFB	%01000110
		DEFB	%01001010
		DEFB	%01010010
		DEFB	%01100010
		DEFB	%00111100
		DEFB	%00000000
; Character: 1
		DEFB	%00000000
		DEFB	%00011000
		DEFB	%00101000
		DEFB	%00001000
		DEFB	%00001000
		DEFB	%00001000
		DEFB	%00111110
		DEFB	%00000000
; Character: 2
		DEFB	%00000000
		DEFB	%00111100
		DEFB	%01000010
		DEFB	%00000010
		DEFB	%00111100
		DEFB	%01000000
		DEFB	%01111110
		DEFB	%00000000
; Character: 3
		DEFB	%00000000
		DEFB	%00111100
		DEFB	%01000010
		DEFB	%00001100
		DEFB	%00000010
		DEFB	%01000010
		DEFB	%00111100
		DEFB	%00000000
; Character: 4
		DEFB	%00000000
		DEFB	%00001000
		DEFB	%00011000
		DEFB	%00101000
		DEFB	%01001000
		DEFB	%01111110
		DEFB	%00001000
		DEFB	%00000000
; Character: 5
		DEFB	%00000000
		DEFB	%01111110
		DEFB	%01000000
		DEFB	%01111100
		DEFB	%00000010
		DEFB	%01000010
		DEFB	%00111100
		DEFB	%00000000
; Character: 6
		DEFB	%00000000
		DEFB	%00111100
		DEFB	%01000000
		DEFB	%01111100
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%00111100
		DEFB	%00000000
; Character: 7
		DEFB	%00000000
		DEFB	%01111110
		DEFB	%00000010
		DEFB	%00000100
		DEFB	%00001000
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00000000
; Character: 8
		DEFB	%00000000
		DEFB	%00111100
		DEFB	%01000010
		DEFB	%00111100
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%00111100
		DEFB	%00000000
; Character: 9
		DEFB	%00000000
		DEFB	%00111100
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%00111110
		DEFB	%00000010
		DEFB	%00111100
		DEFB	%00000000
; Character: :
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00010000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00010000
		DEFB	%00000000
; Character: ;
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00010000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00100000
; Character: <
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000100
		DEFB	%00001000
		DEFB	%00010000
		DEFB	%00001000
		DEFB	%00000100
		DEFB	%00000000
; Character: =
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00111110
		DEFB	%00000000
		DEFB	%00111110
		DEFB	%00000000
		DEFB	%00000000
; Character: >
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00010000
		DEFB	%00001000
		DEFB	%00000100
		DEFB	%00001000
		DEFB	%00010000
		DEFB	%00000000
; Character: ?
		DEFB	%00000000
		DEFB	%00111100
		DEFB	%01000010
		DEFB	%00000100
		DEFB	%00001000
		DEFB	%00000000
		DEFB	%00001000
		DEFB	%00000000
; Character: @
		DEFB	%00000000
		DEFB	%00111100
		DEFB	%01001010
		DEFB	%01010110
		DEFB	%01011110
		DEFB	%01000000
		DEFB	%00111100
		DEFB	%00000000
; Character: A
		DEFB	%00000000
		DEFB	%00111100
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%01111110
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%00000000
; Character: B
		DEFB	%00000000
		DEFB	%01111100
		DEFB	%01000010
		DEFB	%01111100
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%01111100
		DEFB	%00000000
; Character: C
		DEFB	%00000000
		DEFB	%00111100
		DEFB	%01000010
		DEFB	%01000000
		DEFB	%01000000
		DEFB	%01000010
		DEFB	%00111100
		DEFB	%00000000
; Character: D
		DEFB	%00000000
		DEFB	%01111000
		DEFB	%01000100
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%01000100
		DEFB	%01111000
		DEFB	%00000000
; Character: E
		DEFB	%00000000
		DEFB	%01111110
		DEFB	%01000000
		DEFB	%01111100
		DEFB	%01000000
		DEFB	%01000000
		DEFB	%01111110
		DEFB	%00000000
; Character: F
		DEFB	%00000000
		DEFB	%01111110
		DEFB	%01000000
		DEFB	%01111100
		DEFB	%01000000
		DEFB	%01000000
		DEFB	%01000000
		DEFB	%00000000
; Character: G
		DEFB	%00000000
		DEFB	%00111100
		DEFB	%01000010
		DEFB	%01000000
		DEFB	%01001110
		DEFB	%01000010
		DEFB	%00111100
		DEFB	%00000000
; Character: H
		DEFB	%00000000
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%01111110
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%00000000
; Character: I
		DEFB	%00000000
		DEFB	%00111110
		DEFB	%00001000
		DEFB	%00001000
		DEFB	%00001000
		DEFB	%00001000
		DEFB	%00111110
		DEFB	%00000000
; Character: J
		DEFB	%00000000
		DEFB	%00000010
		DEFB	%00000010
		DEFB	%00000010
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%00111100
		DEFB	%00000000
; Character: K
		DEFB	%00000000
		DEFB	%01000100
		DEFB	%01001000
		DEFB	%01110000
		DEFB	%01001000
		DEFB	%01000100
		DEFB	%01000010
		DEFB	%00000000
; Character: L
		DEFB	%00000000
		DEFB	%01000000
		DEFB	%01000000
		DEFB	%01000000
		DEFB	%01000000
		DEFB	%01000000
		DEFB	%01111110
		DEFB	%00000000
; Character: M
		DEFB	%00000000
		DEFB	%01000010
		DEFB	%01100110
		DEFB	%01011010
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%00000000
; Character: N
		DEFB	%00000000
		DEFB	%01000010
		DEFB	%01100010
		DEFB	%01010010
		DEFB	%01001010
		DEFB	%01000110
		DEFB	%01000010
		DEFB	%00000000
; Character: O
		DEFB	%00000000
		DEFB	%00111100
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%00111100
		DEFB	%00000000
; Character: P
		DEFB	%00000000
		DEFB	%01111100
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%01111100
		DEFB	%01000000
		DEFB	%01000000
		DEFB	%00000000
; Character: Q
		DEFB	%00000000
		DEFB	%00111100
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%01010010
		DEFB	%01001010
		DEFB	%00111100
		DEFB	%00000000
; Character: R
		DEFB	%00000000
		DEFB	%01111100
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%01111100
		DEFB	%01000100
		DEFB	%01000010
		DEFB	%00000000
; Character: S
		DEFB	%00000000
		DEFB	%00111100
		DEFB	%01000000
		DEFB	%00111100
		DEFB	%00000010
		DEFB	%01000010
		DEFB	%00111100
		DEFB	%00000000
; Character: T
		DEFB	%00000000
		DEFB	%11111110
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00000000
; Character: U
		DEFB	%00000000
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%00111100
		DEFB	%00000000
; Character: V
		DEFB	%00000000
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%00100100
		DEFB	%00011000
		DEFB	%00000000
; Character: W
		DEFB	%00000000
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%01000010
		DEFB	%01011010
		DEFB	%00100100
		DEFB	%00000000
; Character: X
		DEFB	%00000000
		DEFB	%01000010
		DEFB	%00100100
		DEFB	%00011000
		DEFB	%00011000
		DEFB	%00100100
		DEFB	%01000010
		DEFB	%00000000
; Character: Y
		DEFB	%00000000
		DEFB	%10000010
		DEFB	%01000100
		DEFB	%00101000
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00000000
; Character: Z
		DEFB	%00000000
		DEFB	%01111110
		DEFB	%00000100
		DEFB	%00001000
		DEFB	%00010000
		DEFB	%00100000
		DEFB	%01111110
		DEFB	%00000000
; Character: [
		DEFB	%00000000
		DEFB	%00001110
		DEFB	%00001000
		DEFB	%00001000
		DEFB	%00001000
		DEFB	%00001000
		DEFB	%00001110
		DEFB	%00000000
; Character: \
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%01000000
		DEFB	%00100000
		DEFB	%00010000
		DEFB	%00001000
		DEFB	%00000100
		DEFB	%00000000
; Character: ]
		DEFB	%00000000
		DEFB	%01110000
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%01110000
		DEFB	%00000000
; Character: ^
		DEFB	%00000000
		DEFB	%00010000
		DEFB	%00111000
		DEFB	%01010100
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00000000
; Character: _
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%11111111
; Character: Pound
		DEFB	%00000000
		DEFB	%00011100
		DEFB	%00100010
		DEFB	%01111000
		DEFB	%00100000
		DEFB	%00100000
		DEFB	%01111110
		DEFB	%00000000
; Character: a
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00111000
		DEFB	%00000100
		DEFB	%00111100
		DEFB	%01000100
		DEFB	%00111100
		DEFB	%00000000
; Character: b
		DEFB	%00000000
		DEFB	%00100000
		DEFB	%00100000
		DEFB	%00111100
		DEFB	%00100010
		DEFB	%00100010
		DEFB	%00111100
		DEFB	%00000000
; Character: c
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00011100
		DEFB	%00100000
		DEFB	%00100000
		DEFB	%00100000
		DEFB	%00011100
		DEFB	%00000000
; Character: d
		DEFB	%00000000
		DEFB	%00000100
		DEFB	%00000100
		DEFB	%00111100
		DEFB	%01000100
		DEFB	%01000100
		DEFB	%00111100
		DEFB	%00000000
; Character: e
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00111000
		DEFB	%01000100
		DEFB	%01111000
		DEFB	%01000000
		DEFB	%00111100
		DEFB	%00000000
; Character: f
		DEFB	%00000000
		DEFB	%00001100
		DEFB	%00010000
		DEFB	%00011000
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00000000
; Character: g
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00111100
		DEFB	%01000100
		DEFB	%01000100
		DEFB	%00111100
		DEFB	%00000100
		DEFB	%00111000
; Character: h
		DEFB	%00000000
		DEFB	%01000000
		DEFB	%01000000
		DEFB	%01111000
		DEFB	%01000100
		DEFB	%01000100
		DEFB	%01000100
		DEFB	%00000000
; Character: i
		DEFB	%00000000
		DEFB	%00010000
		DEFB	%00000000
		DEFB	%00110000
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00111000
		DEFB	%00000000
; Character: j
		DEFB	%00000000
		DEFB	%00000100
		DEFB	%00000000
		DEFB	%00000100
		DEFB	%00000100
		DEFB	%00000100
		DEFB	%00100100
		DEFB	%00011000
; Character: k
		DEFB	%00000000
		DEFB	%00100000
		DEFB	%00101000
		DEFB	%00110000
		DEFB	%00110000
		DEFB	%00101000
		DEFB	%00100100
		DEFB	%00000000
; Character: l
		DEFB	%00000000
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00001100
		DEFB	%00000000
; Character: m
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%01101000
		DEFB	%01010100
		DEFB	%01010100
		DEFB	%01010100
		DEFB	%01010100
		DEFB	%00000000
; Character: n
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%01111000
		DEFB	%01000100
		DEFB	%01000100
		DEFB	%01000100
		DEFB	%01000100
		DEFB	%00000000
; Character: o
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00111000
		DEFB	%01000100
		DEFB	%01000100
		DEFB	%01000100
		DEFB	%00111000
		DEFB	%00000000
; Character: p
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%01111000
		DEFB	%01000100
		DEFB	%01000100
		DEFB	%01111000
		DEFB	%01000000
		DEFB	%01000000
; Character: q
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00111100
		DEFB	%01000100
		DEFB	%01000100
		DEFB	%00111100
		DEFB	%00000100
		DEFB	%00000110
; Character: r
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00011100
		DEFB	%00100000
		DEFB	%00100000
		DEFB	%00100000
		DEFB	%00100000
		DEFB	%00000000
; Character: s
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00111000
		DEFB	%01000000
		DEFB	%00111000
		DEFB	%00000100
		DEFB	%01111000
		DEFB	%00000000
; Character: t
		DEFB	%00000000
		DEFB	%00010000
		DEFB	%00111000
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%00001100
		DEFB	%00000000
; Character: u
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%01000100
		DEFB	%01000100
		DEFB	%01000100
		DEFB	%01000100
		DEFB	%00111000
		DEFB	%00000000
; Character: v
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%01000100
		DEFB	%01000100
		DEFB	%00101000
		DEFB	%00101000
		DEFB	%00010000
		DEFB	%00000000
; Character: w
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%01000100
		DEFB	%01010100
		DEFB	%01010100
		DEFB	%01010100
		DEFB	%00101000
		DEFB	%00000000
; Character: x
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%01000100
		DEFB	%00101000
		DEFB	%00010000
		DEFB	%00101000
		DEFB	%01000100
		DEFB	%00000000
; Character: y
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%01000100
		DEFB	%01000100
		DEFB	%01000100
		DEFB	%00111100
		DEFB	%00000100
		DEFB	%00111000
; Character: z
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%01111100
		DEFB	%00001000
		DEFB	%00010000
		DEFB	%00100000
		DEFB	%01111100
		DEFB	%00000000
; Character: {
		DEFB	%00000000
		DEFB	%00001110
		DEFB	%00001000
		DEFB	%00110000
		DEFB	%00001000
		DEFB	%00001000
		DEFB	%00001110
		DEFB	%00000000
; Character: |
		DEFB	%00000000
		DEFB	%00001000
		DEFB	%00001000
		DEFB	%00001000
		DEFB	%00001000
		DEFB	%00001000
		DEFB	%00001000
		DEFB	%00000000
; Character: }
		DEFB	%00000000
		DEFB	%01110000
		DEFB	%00010000
		DEFB	%00001100
		DEFB	%00010000
		DEFB	%00010000
		DEFB	%01110000
		DEFB	%00000000
; Character: ~
		DEFB	%00000000
		DEFB	%00010100
		DEFB	%00101000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
		DEFB	%00000000
; Character: Copyright
		DEFB	%00111100
		DEFB	%01000010
		DEFB	%10011001
		DEFB	%10100001
		DEFB	%10100001
		DEFB	%10011001
		DEFB	%01000010
		DEFB	%00111100
