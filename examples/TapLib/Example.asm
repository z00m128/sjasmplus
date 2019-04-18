;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Busy soft ;; 26.11.2018 ;; Tape generating library usage example    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	DEVICE ZXSPECTRUM48
	org	#8000

start	ld	hl,#0000
	ld	de,#4000
	ld	bc,#1B00
	ldir
	ret
length	=	$-start

	include	 TapLib.asm
	MakeTape "Example.tap", "Example", start, length, start
