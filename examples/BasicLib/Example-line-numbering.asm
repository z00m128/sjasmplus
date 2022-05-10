;; Example of using BasicLib.asm
;;
;;     Line numbering control
;;
;; =============================

	INCLUDE	BasicLib.asm

line_number = 0
line_step   = 1

	LINE : db rem,'First line'  : LEND
	LINE : db rem,'Second line' : LEND
	LINE : db rem,'Third line'  : LEND

line_number = 100
line_step   = 20

	LINE : db rem,'Another numbers'	  : LEND
	LINE : db rem,'with another step' : LEND


;; Generated basic:
;;
;;    0 REM First line
;;    1 REM Second line
;;    2 REM Third line
;;  100 REM Another numbers
;;  120 REM with another step
