;; Example of using BasicLib.asm
;;
;;     Machine code in REM
;;
;; Generates tap file with the basic

	INCLUDE	BasicLib.asm

	DEFINE	 tape	"Code-in-REM.tap"
	EMPTYTAP tape


	TAPOUT  tape,0		;; Standart 17-byte file header
	db	0		;; File type
	db	code,in,rem	;; File name
	db	'       '	;; Padding to 10 chars
	dw	basic_length	;; File total length
	dw	10		;; Start basic line
	dw	basic_length	;; Pure basic length
	TAPEND


	TAPOUT	tape		;; File body
	ORG	23755
basic
	LINE
	db	rem
;;;; machine code example begin ;;;;
start	ld	hl,#0000
	ld	de,#4000
	ld	bc,#1B00
	ldir
	ret
;;;; machine code example end ;;;;;;
	LEND

	LINE
	db	rand,usr
	NUM	start
	LEND

basic_length = $-basic

	TAPEND
