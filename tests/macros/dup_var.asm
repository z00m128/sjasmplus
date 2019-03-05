	MACRO filler x1, x2, y1, y2
		ld	hl,y1*2
		add	hl,sp
		ld	sp,hl

		DUP (y2 - y1)
			ld	de,x1
			pop	hl
			add	hl,de

			DUP (x2 - x1)
				ld	(hl),a
				inc	l
			EDUP

			ld	(hl),a
		EDUP
	ENDM

	OUTPUT "dup_var.bin"
	filler 15, 20, 35, 40
