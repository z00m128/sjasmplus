	macro filler x1, x2, y1, y2
		if y1 >= 100
			ld	hl,y1*2
			add	hl,sp
			ld	sp,hl
		endif

		dup (y2 - y1)
			if x1 >= 100
				ld	de,x1
			endif

			pop	hl

			if x1 >= 100
				add	hl,de
			endif

			dup (x2 - x1)
				ld	(hl),a
				inc	l
			edup

			ld	(hl),a
		edup
	endm

	OUTPUT "if_in_dup.bin"

	filler 10, 13, 30, 33

	filler 110, 113, 130, 133
