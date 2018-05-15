;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test source for TAPOUT / TAPEND / OUTPUT / OUTEND ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	DEFINE	tape_file "tapout_test.tap"
	DEFINE	pure_code "tapout_test.bin"

	db	1,1,1,1

	EMPTYTAP tape_file		;; Create empty TAP file
	
	db	2,2,2,2

	TAPOUT	tape_file,0		;; Basic header

	db	0x00			;; Header type = basic
	db	'HelloWorld'		;; File name
	dw	baslen			;; Total length
	dw	1			;; Start line
	dw	baslen			;; Length of pure basic

	TAPEND				;; End of tape block

	db	3,3,3,3

	TAPOUT	tape_file		;; Basic body

CODE	=	0xAF
USR	=	0xC0
LOAD	=	0xEF
RANDOMIZE =	0xF9

basic	db	0,1			;; Line 1
	dw	l1len			;; Length of line 1
line1	db	LOAD,'""',CODE		;; LOAD "" CODE
	db	0x0D			;; End of line 1

l1len	=	$-line1

	db	0,2			;; Line 2
	dw	l2len			;; Length of line 2
line2	db	RANDOMIZE,USR		;; RANDOMIZE USR

	LUA ALLPASS			;; Digits of number
	_pc('db	"' .. tostring(_c("start")) .. '"')
	ENDLUA

	db	0x0E			;; Number follows
	db	0x00,0x00		;; 5 bytes of internal
	dw	start			;; number representation
	db	0x00
	db	0x0D			;; End of line 2

l2len	=	$-line2
baslen	=	$-basic

	TAPEND				;; End of tape block

	db	4,4,4,4

	TAPOUT	tape_file,0		;; Bytes header

	db	0x03			;; Header type = bytes
	db	'HelloWorld'		;; File name
	dw	codlen			;; Total length
	dw	start			;; Start address
	dw	0x8000

	TAPEND				;; End of tape block

	db	5,5,5,5

	TAPOUT	tape_file		;; Bytes body
	OUTPUT	pure_code

	org	0x8000			;; Start address of code

start	ld	a,0x02			;; Channel #2
	call	0x1601			;; is opened
	ld	de,text			;; Address of text
	ld	bc,txtlen		;; Length of text
	jp	0x203C			;; Jump to print text

text	db	13			;; Cursor to next line
	db	19,1			;; BRIGHT 1
	db	18,1			;; FLASH 1
	db	'Hello world !'		;; Text

txtlen	=	$-text
codlen	=	$-start

	OUTEND				;; End of pure data block
	TAPEND				;; End of tape block

	db	6,6,6,6
