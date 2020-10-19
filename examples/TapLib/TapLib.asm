;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Busy soft ;; 26.11.2018 ;; Tape generating library ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Use:
;;
;;   .................
;;   ...your...code...
;;   .................
;;   include "TapLib.asm"
;;   MakeTape <speccy_model>, <tape_file>, <program_name>, <start_address>, <code_length>, <call_address>

	MACRO	MakeTape speccy_model, tape_file, prog_name, start_add, code_len, call_add
	DEVICE	speccy_model

CODE	=	#AF
USR	=	#C0
LOAD	=	#EF
CLEAR	=	#FD
RANDOMIZE =	#F9

	org	#5C00
baszac	db	0,1			;; Line number
	dw	linlen			;; Line length
linzac
	db	CLEAR,'8',#0E,0,0
	dw	start_add-1
	db	0,':'
	db	LOAD,'"'
codnam	ds	10,32
	org	codnam
	db	prog_name
	org	codnam+10
	db	'"',CODE,':'
	db	RANDOMIZE,USR,'8',#0E,0,0
	dw	call_add
	db	0,#0D
linlen	=	$-linzac
baslen	=	$-baszac

	EMPTYTAP tape_file
	SAVETAP  tape_file,BASIC,prog_name,baszac,baslen,1
	SAVETAP  tape_file,CODE,prog_name,start_add,code_len,start_add

	ENDM
