;; Example of using BasicLib.asm
;;
;;     Simple basic loader
;;
;; Generates tap file with basic loader
;; with some code to load and execute.

	INCLUDE	BasicLib.asm
	DEVICE	ZXSPECTRUM48
	ORG	23755

line_useval = 1   ;; Last line will be RANDOMIZE USR VAL "32768"

basic
	LINE : db clear,val,'"3e4"'	: LEND
	LINE : db load,'"code"',code	: LEND
	LINE : db rand,usr : NUM start	: LEND
basend

	ORG	#8000

start	ld	hl,#0000	;; Example of
	ld	de,#4000	;; some loaded and
	ld	bc,#1B00	;; executed code
	ldir
	ret
codend

	DEFINE	tape	Simple-loader.tap

	EMPTYTAP tape
	SAVETAP  tape , BASIC , "basic" , basic , basend-basic , 10
	SAVETAP  tape , CODE  , "code"  , start , codend-start
