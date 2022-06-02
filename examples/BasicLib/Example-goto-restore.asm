;; Example of using BasicLib.asm
;;
;;     Using line numbers
;;
;; =============================

	INCLUDE	BasicLib.asm

	LINE
	db	cls,':'
	db	restore : NUM restore_line
	LEND

jump_here = line_number

	LINE : db read,'s$'		: LEND
	LINE : db print,'s$;'		: LEND
	LINE : db goto : NUM jump_here	: LEND

restore_line = line_number

	LINE : db data,'"Hello ","world ","!"' : LEND


;; Generated basic:
;;
;;   10 CLS : RESTORE 50
;;   20 READ s$
;;   30 PRINT s$;
;;   40 GO TO 20
;;   50 DATA "Hello ","world ","!"
