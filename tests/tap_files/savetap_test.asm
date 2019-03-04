		device	zxspectrum48


; BASIC block
	module bas
line10:		db	0, 10
		dw	.len
.cmds		; BORDER NOT PI:
		db	$E7, $C3, $A7, ':'
		; PAPER NOT PI:
		db	$DA, $C3, $A7, ':'
		; INK VAL "7":
		db	$D9, $B0, '"7":'
		; CLEAR VAL "32767"
		db	$FD, $B0, '"32767"', $0D
.len = $ - .cmds

line20:		db	0, 20
		dw	.len
.cmds		; POKE VAL "23739",CODE "o":
		db	$F4, $B0, '"23739",', $AF, '"o":'
		; LOAD ""SCREEN$: LOAD ""CODE
		db	$EF, '""', $AA, ':', $EF, '""', $AF, $0D
.len = $ - .cmds

line30:		db	0, 30
		dw	.len
.cmds		; RANDOMIZE USR VAL "32768"
		db	$F9, $C0, $B0, '"32768"', $0D
.len = $ - .cmds

total = $ - line10
	endmodule


; CHARS block
chars:		db	1
		dw	.datalen
.data:		db	"SAVETAP testing character array"
.datalen = $ - .data

.len = $ - chars


; SCREEN$ block
		org	$4000
screen:
	rept 12
		block	256,$AA
		block	256,$55
	endm
	rept 24
		db	$07, $06, $06, $16, $05, $05, $0D, $04, $04, $14, $03, $03, $11, $02, $02, $29
		db	$29, $02, $02, $11, $03, $03, $14, $04, $04, $0D, $05, $05, $16, $06, $06, $07
	endm
.len = $ - screen


; CODE block
		org	$8000

demo:		ei
		halt
		djnz	demo
.loop		ei
		halt
		ld	hl,$5801
		ld	de,$5800
		ld	bc,$300
		ld	a,(de)
		ld	($5B00),a
		ldir
		call	.rnd
		ld	c,a
		and	$0C
		sub	$0B
		jr	nc,.not12
		ld	a,2
.not12		ld	d,a
		call	.rnd
		ld	e,a
		ld	hl,$5800
		add	hl,de
		ld	a,c
		and	$7F
		xor	(hl)
		ld	(hl),a
		jr	.loop

.rnd		ld	a,$8729
		ld	b,a
		rrca
		rrca
		rrca
		xor	$1F
		add	a,b
		sbc	a,$FF
		ld	(.rnd+1),a
		ret
.len = $ - demo


		emptytap "savetap_test.tap"
; store BASIC
		savetap	"savetap_test.tap",BASIC,"tstSAVETAP", bas.line10, bas.total, 10
; store SCREEN$
		savetap	"savetap_test.tap",CODE,"intro", screen, screen.len
; store CODE
		savetap	"savetap_test.tap",CODE,"demo", demo, demo.len
; store CHARS
		savetap "savetap_test.tap",CHARS,"t$", chars, chars.len, 't'
; store HEADLESS
		savetap "savetap_test.tap",HEADLESS, (screen + $1800), 32, 66 ; custom flag
