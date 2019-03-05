	MACRO filler x1, x2, y1, y2
		ld	hl,y1*2
		add	hl,sp
		ld	sp,hl

		REPT (y2 - y1)
			ld	de,x1
			pop	hl
			add	hl,de

			REPT (x2 - x1)
				ld	(hl),a
				inc	l
			ENDR

			ld	(hl),a
		ENDR
	ENDM

	OUTPUT "rept_var.bin"
	filler 10, 13, 30, 33
