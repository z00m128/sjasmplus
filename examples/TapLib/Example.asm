;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Busy soft ;; 26.11.2018 ;; Priklad pouzitia Tape generating library ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	org	#8000

start	ld	hl,#0000
	ld	de,#4000
	ld	bc,#1B00
	ldir
	ret
length	=	$-start

	include	 TapLib.asm
	MakeTape ZXSPECTRUM48, "Priklad.tap", "Pokus", start, length, start
