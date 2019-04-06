;**********************************
;** ZX SPECTRUM SYSTEM VARIABLES **
;**********************************

KSTATE_0	equ	$5C00	; 23552 ; (IY+$C6) ; Used in reading the keyboard.
KSTATE_4	equ	$5C04	; 23556 ; (IY+$CA)
LASTK		equ	$5C08	; 23560 ; (IY+$CE) ; Stores newly pressed key.
REPDEL		equ	$5C09	; 23561 ; (IY+$CF) ; Time (in 50ths of a second in 60ths of a second in N. America) that a key must be held down before it repeats. This starts off at 35, but you can POKE in other values.
REPPER		equ	$5C0A	; 23562 ; (IY+$D0) ; Delay (in 50ths of a second in 60ths of a second in N. America) between successive repeats of a key held down: initially 5.
DEFADD		equ	$5C0B	; 23563 ; (IY+$D1) ; Address of arguments of user defined function if one is being evaluated; otherwise 0.
KDATA		equ	$5C0D	; 23565 ; (IY+$D3) ; Stores 2nd byte of colour controls entered from keyboard .
TVDATA_LO	equ	$5C0E	; 23566 ; (IY+$D4) ; Stores bytes of colour, AT and TAB controls going to television.
TVDATA_HI	equ	$5C0F	; 23567 ; (IY+$D5)
STRMS_FD	equ	$5C10	; 23568 ; (IY+$D6) ; Addresses of channels attached to streams.
STRMS_00	equ	$5C16	; 23574 ; (IY+$DC)
CHARS		equ	$5C36	; 23606 ; (IY+$FC) ; 256 less than address of character set (which starts with space and carries on to the copyright symbol). Normally in ROM, but you can set up your own in RAM and make CHARS point to it.
RASP_PIP	equ	$5C38	; 23608 ; (IY+$FE) ; Length of warning buzz.
ERR_NR		equ	$5C3A	; 23610 ; (IY+$00) ; 1 less than the report code. Starts off at 255 (for 1) so PEEK 23610 gives 255.
FLAGS		equ	$5C3B	; 23611 ; (IY+$01) ; Various flags to control the BASIC system. See *
TV_FLAG		equ	$5C3C	; 23612 ; (IY+$02) ; Flags associated with the television. See **
ERR_SP		equ	$5C3D	; 23613 ; (IY+$03) ; Address of item on machine stack to be used as error return.
LIST_SP		equ	$5C3F	; 23615 ; (IY+$05) ; Address of return address from automatic listing.
MODE		equ	$5C41	; 23617 ; (IY+$07) ; Specifies K, L, C. E or G cursor.
NEWPPC		equ	$5C42	; 23618 ; (IY+$08) ; Line to be jumped to.
NSPPC		equ	$5C44	; 23620 ; (IY+$0A) ; Statement number in line to be jumped to. Poking first NEWPPC and then NSPPC forces a jump to a specified statement in a line.
PPC		equ	$5C45	; 23621 ; (IY+$0B) ; Line number of statement currently being executed.
SUBPPC		equ	$5C47	; 23623 ; (IY+$0D) ; Number within line of statement being executed.
BORDCR		equ	$5C48	; 23624 ; (IY+$0E) ; Border colour * 8; also contains the attributes normally used for the lower half of the screen.
E_PPC		equ	$5C49	; 23625 ; (IY+$0F) ; Number of current line (with program cursor).
E_PPC_HI	equ	$5C4A	; 23626 ; (IY+$10)
VARS		equ	$5C4B	; 23627 ; (IY+$11) ; Address of variables.
DEST		equ	$5C4D	; 23629 ; (IY+$13) ; Address of variable in assignment.
CHANS		equ	$5C4F	; 23631 ; (IY+$15) ; Address of channel data.
CURCHL		equ	$5C51	; 23633 ; (IY+$17) ; Address of information currently being used for input and output.
PROG		equ	$5C53	; 23635 ; (IY+$19) ; Address of BASIC program.
NXTLIN		equ	$5C55	; 23637 ; (IY+$1B) ; Address of next line in program.
DATADD		equ	$5C57	; 23639 ; (IY+$1D) ; Address of terminator of last DATA item.
E_LINE		equ	$5C59	; 23641 ; (IY+$1F) ; Address of command being typed in.
K_CUR		equ	$5C5B	; 23643 ; (IY+$21) ; Address of cursor.
CH_ADD		equ	$5C5D	; 23645 ; (IY+$23) ; Address of the next character to be interpreted: the character after the argument of PEEK, or the NEWLINE at the end of a POKE statement.
X_PTR		equ	$5C5F	; 23647 ; (IY+$25) ; Address of the character after the ? marker.
WORKSP		equ	$5C61	; 23649 ; (IY+$27) ; Address of temporary work space.
STKBOT		equ	$5C63	; 23651 ; (IY+$29) ; Address of bottom of calculator stack.
STKEND		equ	$5C65	; 23653 ; (IY+$2B) ; Address of start of spare space.
STKEND_HI	equ	$5C66	; 23654 ; (IY+$2C)
BREG		equ	$5C67	; 23655 ; (IY+$2D) ; Calculator's b register.
MEM		equ	$5C68	; 23656 ; (IY+$2E) ; Address of area used for calculator's memory. (Usually MEMBOT, but not always.)
FLAGS2		equ	$5C6A	; 23658 ; (IY+$30) ; More flags. See ***
DF_SZ		equ	$5C6B	; 23659 ; (IY+$31) ; The number of lines (including one blank line) in the lower part of the screen.
S_TOP		equ	$5C6C	; 23660 ; (IY+$32) ; The number of the top program line in automatic listings.
OLDPPC		equ	$5C6E	; 23662 ; (IY+$34) ; Line number to which CONTINUE jumps.
OSPPC		equ	$5C70	; 23664 ; (IY+$36) ; Number within line of statement to which CONTINUE jumps.
FLAGX		equ	$5C71	; 23665 ; (IY+$37) ; Various flags. See ****
STRLEN		equ	$5C72	; 23666 ; (IY+$38) ; Length of string type destination in assignment.
T_ADDR		equ	$5C74	; 23668 ; (IY+$3A) ; Address of next item in syntax table (very unlikely to be useful).
SEED		equ	$5C76	; 23670 ; (IY+$3C) ; The seed for RND. This is the variable that is set by RANDOMIZE.
FRAMES1		equ	$5C78	; 23672 ; (IY+$3E) ; 3 byte (least significant first), frame counter. Incremented every 20ms.
UDG		equ	$5C7B	; 23675 ; (IY+$41) ; Address of 1st user defined graphic You can change this for instance to save space by having fewer user defined graphics.
COORDS		equ	$5C7D	; 23677 ; (IY+$43) ; x-coordinate of last point plotted.
COORDS_Y	equ	$5C7E	; 23678 ; (IY+$44) ; y-coordinate of last point plotted.
PR_CC		equ	$5C80	; 23680 ; (IY+$46) ; Full address of next position for LPRINT to print at (in ZX printer buffer). Legal values $5B00 - $5B1F. [Not used in 128K mode or when certain peripherals are attached]
ECHO_E		equ	$5C82	; 23682 ; (IY+$48) ; 33 column number and 24 line number (in lower half) of end of input buffer.
DF_CC		equ	$5C84	; 23684 ; (IY+$4A) ; Address in display file of PRINT position.
DFCCL		equ	$5C86	; 23686 ; (IY+$4C) ; Like DF_CC for lower part of screen.
S_POSN		equ	$5C88	; 23688 ; (IY+$4E) ; 33 column number for PRINT position
S_POSN_HI	equ	$5C89	; 23689 ; (IY+$4F) ; 24 line number for PRINT position.
SPOSNL		equ	$5C8A	; 23690 ; (IY+$50) ; Like S_POSN for lower part
SPOSNL_HI	equ	$5C8B	; 23691 ; (IY+$51)
SCR_CT		equ	$5C8C	; 23692 ; (IY+$52) ; Counts scrolls: it is always 1 more than the number of scrolls that will be done before stopping with scroll? If you keep poking this with a number bigger than 1 (say 255), the screen will scroll on and on without asking you.
ATTRP_MASKP	equ	$5C8D	; 23693 ; (IY+$53) ; Permanent current colours, etc (as set up by colour statements).
ATTRT_MASKT	equ	$5C8F	; 23695 ; (IY+$55) ; Temporary current colours, etc (as set up by colour items).
MASK_T		equ	$5C90	; 23696 ; (IY+$56) ; Like MASK_P, but temporary.
P_FLAG		equ	$5C91	; 23697 ; (IY+$57) ; More flags.
MEM_0		equ	$5C92	; 23698 ; (IY+$58) ; Calculator's memory area; used to store numbers that cannot conveniently be put on the calculator stack.
MEM_3		equ	$5CA1	; 23713 ; (IY+$67)
MEM_4		equ	$5CA6	; 23718 ; (IY+$6C)
MEM_4_4		equ	$5CAA	; 23722 ; (IY+$70)
MEM_5_0		equ	$5CAB	; 23723 ; (IY+$71)
MEM_5_1		equ	$5CAC	; 23724 ; (IY+$72)
NMIADD		equ	$5CB0	; 23728 ; (IY+$76) ; This is the address of a user supplied NMI address which is read by the standard ROM when a peripheral activates the NMI. Probably intentionally disabled so that the effect is to perform a reset if both locations hold zero, but do nothing if the locations hold a non-zero value. Interface 1's with serial number greater than 87315 will initialize these locations to 0 and 80 to allow the RS232 "T" channel to use a variable line width. 23728 is the current print position and 23729 the width - default 80.
RAMTOP		equ	$5CB2	; 23730 ; (IY+$78) ; Address of last byte of BASIC system area.
P_RAMT		equ	$5CB4	; 23732 ; (IY+$7A) ; Address of last byte of physical RAM.

; *
; FLAGS	equ		$5C3B	; 23611 ; (IY+$01) ; BASIC flags, particular bits meaning:
;						   ; 0 ... 1 = supress leading space for tokens
;						   ; 1 ... 1 = listing to ZX Printer
;						   ; 2 ... 1 = listing in mode 'L', 0 = listing in mode 'K'
;						   ; 3 ... 1 = keyboard mode 'L', 0 = keyboard mode 'K'
;						   ; 4 ... 48k: unused, 128k: 0 = basic48, 1 = basic128
;						   ; 5 ... 1= new key was pressed on
;						   ; 6 ... 1= numeric result of the operation, 0=string result of the operation (SCANN is set)
;						   ; 7 ... 1= syntax checking off, 0=syntax checking on
;
; **
; TV_FLAG	equ	$5C3C	; 23612 ; (IY+$02) ; PRINT routine flags, particular bits meaning:
;						   ; 0 ... 1=lower part of screen
;						   ; 3 ... 1=mode change in EDIT
;						   ; 4 ... 1=Autolist
;						   ; 5 ... 1=screen is clear
;
; ***
; FLAGS2	equ	$5C6A	; 23658 ; (IY+$30) ; BASIC flags, particular bits meaning:
; 						   ; 0 ... 1=screen is clear
;						   ; 1 ... 1=ZX Printeru buffer is not empty
;						   ; 2 ... 1=quotation mode during string processing
;						   ; 3 ... 1=caps lock
;						   ; 4 ... 1=channel 'K'
;						   ; 5 ... 1=new key was pressed on
;						   ; 6 ... unused
;						   ; 7 ... unused
;
; ****
; FLAGX		equ	$5C71	; 23665 ; (IY+$37) ; BASIC flags, particular bits meaning:
; 						   ; 0 ... 1=remove string from variable before new string assign
;						   ; 1 ... 1=create variable at LET, 0=variable already exists
;						   ; 5 ... 1=INPUT mode, 0=EDIT BASIC line
; 						   ; 6 ... 1=numeric variable in INPUT, 0=string variable in INPUT mode
;						   ; 7 ... 1=input line
