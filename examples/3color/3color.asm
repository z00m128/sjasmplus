;original code by Cyberdemon^i8
;decompiled(used IDA Pro) and adapted for SjASMPlus by Aprisobal 
;27.07.2006
		device zxspectrum128
		
		org 8500h
		page 7
		;our image here
image:		inchob "killerbean2.$c"
		;or incbin "KillerBean2.rgb"
		;or incbin "scrshot7.rgb"
.end:
		;our viewer
		org 8200h
; ---------------------------------------------------------------------------
start:		call	GenerateSubs
		ld	(loc_829A+1), sp
		xor	a
		out	(254), a
		halt

loc_820B:
		ld	bc, 7FFDh
		ld	a, 11000b
		out	(c), a
		ld	ix, loc_8219
		jp	loc_829F
; ---------------------------------------------------------------------------

loc_8219:
		ld	ix, loc_8220
		jp	loc_82A2
; ---------------------------------------------------------------------------

loc_8220:
		ld	ix, loc_822D
		ld	sp, 5A00h
		ld	de, 404h
		jp	loc_82A8
; ---------------------------------------------------------------------------

loc_822D:
		ld	sp, 8500h
		halt
		ld	bc, 7FFDh
		ld	a, 10000b
		out	(c), a
		ld	ix, loc_823F
		jp	loc_82A5
; ---------------------------------------------------------------------------

loc_823F:
		ld	ix, loc_824C
		ld	sp, 5B00h
		ld	de, 404h
		jp	loc_82AB
; ---------------------------------------------------------------------------

loc_824C:
		ld	bc, 7FFDh
		ld	a, 11h
		out	(c), a
		ld	ix, loc_825A
		jp	loc_829F
; ---------------------------------------------------------------------------

loc_825A:
		ld	sp, 5A00h
		ld	de, 101h
		ld	ix, loc_8267
		jp	loc_82A8
; ---------------------------------------------------------------------------

loc_8267:
		ld	sp, 8500h
		halt
		ld	sp, 5B00h
		ld	de, 101h
		ld	ix, loc_8278
		jp	loc_82AB
; ---------------------------------------------------------------------------

loc_8278:
		ld	ix, loc_827F
		jp	loc_82A2
; ---------------------------------------------------------------------------

loc_827F:
		ld	ix, loc_8286
		jp	loc_82A5
; ---------------------------------------------------------------------------

loc_8286:
		ld	sp, 8500h
		halt
		xor	a
		in	a, (0FEh)
		cpl
		and	1Fh
		jp	z, loc_820B
		di
		im	1
		ld	a, 3Fh ; '?'
		ld	i, a

loc_829A:
		ld	sp, 0
		ei
		ret
; ---------------------------------------------------------------------------

loc_829F:
		jp	0
; ---------------------------------------------------------------------------

loc_82A2:
		jp	0
; ---------------------------------------------------------------------------

loc_82A5:
		jp	0
; ---------------------------------------------------------------------------

loc_82A8:
		jp	0
; ---------------------------------------------------------------------------

loc_82AB:
		jp	0
; ---------------------------------------------------------------------------
		ei
		ret

; --------------- S U B R O U T I N E ---------------------------------------


GenerateSubs:
		ld	a, 10111b
		call	PageOut
		ld	hl, 0D800h
		ld	bc, 2FFh
		ld	a, 2
		call	IncDE
		ld	hl, 8500h
		ld	de, 1017h
		call	Page
		ld	hl, 0B500h
		ld	de, 1011h
		call	Page
		ld	hl, 9D00h
		ld	de, 1010h
		call	Page
		ld	a, 80h
		ld	i, a
		ld	h, a
		ld	l, 0
		inc	a

loc_82E3:
		ld	(hl), a
		inc	l
		jr	nz, loc_82E3
		inc	h
		ld	(hl), a
		ld	l, a
		ld	h, a
		ld	a, 0C3h
		ld	de, 82AEh
		ld	(hl), a
		inc	l
		ld	(hl), e
		inc	l
		ld	(hl), d
		di
		im	2
		ei
		ld	de, 8500h
		ld	(loc_829F+1), de
		ld	a, 40h
		exx
		ld	hl, 0C000h
		ld	de, 4010h
		ld	bc, 16
		call	sub_833B
		ld	(loc_82A2+1), de
		ld	a, 40h
		exx
		call	sub_833B
		ld	(loc_82A5+1), de
		ld	a, 40h
		exx
		call	sub_833B
		ex	de, hl
		ld	(loc_82A8+1), hl
		ld	b, 80h

loc_8329:
		ld	(hl), 0D5h
		inc	hl
		djnz	loc_8329
		ld	(loc_82AB+1), hl
		ld	b, 80h

loc_8333:
		ld	(hl), 0D5h
		inc	hl
		djnz	loc_8333
		jp	loc_8372
; End of function GenerateSubs


; --------------- S U B R O U T I N E ---------------------------------------


sub_833B:
		ex	af, af'
		push	hl
		push	de
		ld	(loc_83C5+1), hl
		ld	(loc_83D2+1), de
		add	hl, bc
		ex	de, hl
		add	hl, bc
		ex	de, hl
		exx
		ld	hl, 83C5h
		ld	bc, 1Ah
		ldir
		exx
		ld	(loc_83C5+1), hl
		ld	(loc_83D2+1), de
		pop	de
		pop	hl
		exx
		ld	hl, 83C5h
		ld	bc, 1Ah
		ldir
		exx
		call	DownHL
		call	DownDE
		ex	af, af'
		dec	a
		jr	nz, sub_833B
		exx
		ex	de, hl

loc_8372:
		ld	(hl), 0DDh
		inc	hl
		ld	(hl), 0E9h
		inc	hl
		ex	de, hl
		ret
; End of function sub_833B


; --------------- S U B R O U T I N E ---------------------------------------


DownHL:
		inc	h
		ld	a, h
		and	7
		ret	nz
		ld	a, l
		add	a, 20h
		ld	l, a
		ret	c
		ld	a, h
		sub	8
		ld	h, a
		ret
; End of function DownHL


; --------------- S U B R O U T I N E ---------------------------------------


DownDE:
		inc	d
		ld	a, d
		and	7
		ret	nz
		ld	a, e
		add	a, 20h
		ld	e, a
		ret	c
		ld	a, d
		sub	8
		ld	d, a
		ret
; End of function DownDE


; --------------- S U B R O U T I N E ---------------------------------------


PageOut:
		push	bc
		ld	bc, 7FFDh
		out	(c), a
		pop	bc
		ret
; End of function PageOut


; --------------- S U B R O U T I N E ---------------------------------------


IncDE:
		ld	e, l
		ld	d, h
		inc	de
		ld	(hl), a
		ldir
		ret
; End of function IncDE


; --------------- S U B R O U T I N E ---------------------------------------


Page:
		ld	bc, 17FFh
		add	hl, bc
		ld	bc, 7FFDh
		exx
		ld	bc, 1800h
		ld	de, 0D7FFh

loc_83B5:
		exx
		out	(c), d
		ld	a, (hl)
		dec	hl
		out	(c), e
		exx
		ld	(de), a
		dec	de
		dec	bc
		ld	a, b
		or	c
		jr	nz, loc_83B5
		ret
; End of function Page

; ---------------------------------------------------------------------------

loc_83C5:
		ld	sp, 0
		pop	hl
		pop	de
		pop	bc
		pop	af
		exx
		ex	af, af'
		pop	hl
		pop	de
		pop	bc
		pop	af

loc_83D2:
		ld	sp, 0
		push	af
		push	bc
		push	de
		push	hl
		ex	af, af'
		exx
		push	af
		push	bc
		push	de
		push	hl


		savesna "3color.sna",start

		;savebin "3color.bin",$8200,image.end-$8200
