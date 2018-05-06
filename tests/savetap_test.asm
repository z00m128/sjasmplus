		device	zxspectrum48

		EMPTYTAP "output.tap"

	module bas

line10:		byte	0, 10
		word	.len
.cmds		; BORDER NOT PI:
		byte	$E7, $C3, $A7, ':'
		; PAPER NOT PI:
		byte	$DA, $C3, $A7, ':'
		; INK VAL "7":
		byte	$D9, $B0, '"7":'
		; CLEAR VAL "32767"
		byte	$FD, $B0, '"32767"', $0D
.len = $ - .cmds

line20:		byte	0, 20
		word	.len
.cmds		; POKE VAL "23739",CODE "o":
		byte	$F4, $B0, '"23739",', $AF, '"o":'
		; LOAD ""SCREEN$: LOAD ""CODE
		byte	$EF, '""', $AA, ':', $EF, '""', $AF, $0D
.len = $ - .cmds

line30:		byte	0, 30
		word	.len
.cmds		; RANDOMIZE USR VAL "32768"
		byte	$F9, $C0, $B0, '"32768"', $0D
.len = $ - .cmds

total = $ - line10
	endmodule

; store BASIC header
		savetap	"output.tap",BASIC, "tstSAVETAP", bas.total, 10
; store BASIC block
		savetap "output.tap",BLOCK, bas.line10, bas.total


		org	$4000
screen:
	rept 12
		block	256,$AA
		block	256,$55
	endm
	rept 24
		byte	$07, $06, $06, $16, $05, $05, $0D, $04, $04, $14, $03, $03, $11, $02, $02, $29
		byte	$29, $02, $02, $11, $03, $03, $14, $04, $04, $0D, $05, $05, $16, $06, $06, $07
	endm
.len = $ - screen

; store SCREEN$ header
		savetap	"output.tap",CODE, "intro", screen.len, screen
; store SCREEN$ block
		savetap "output.tap",BLOCK, screen, screen.len


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

; store CODE header
		savetap	"output.tap",CODE, "demo", demo.len, demo
; store CODE block
		savetap "output.tap",BLOCK, demo, demo.len
