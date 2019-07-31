;; This test should be kept identical to "savetap_test.asm" (except syntax error part)
;; But it does use ZX Next device (with 8kiB memory pages), to verify the "real tape"
;; works in such case too (the resulting TAP files must be identical on ZX48 and Next).

		device zxspectrumnext

; BASIC block
	module bas
line10:		db	0, 10
		dw	.len
.cmds		; BORDER NOT PI:
		db	#E7, #C3, #A7, ':'
		; PAPER NOT PI:
		db	#DA, #C3, #A7, ':'
		; INK VAL "7":
		db	#D9, #B0, '"7":'
		; CLEAR VAL "32763" : REM demo-1 address
		db	#FD, #B0, '"32763"', #0D
.len = $ - .cmds

line20:		db	0, 20
		dw	.len
.cmds		; POKE VAL "23739",CODE "o":
		db	#F4, #B0, '"23739",', #AF, '"o":'
		; LOAD ""SCREEN#: LOAD ""CODE
		db	#EF, '""', #AA, ':', #EF, '""', #AF, #0D
.len = $ - .cmds

line30:		db	0, 30
		dw	.len
.cmds		; RANDOMIZE USR VAL "32764" : REM demo address
		db	#F9, #C0, #B0, '"32764"', #0D
.len = $ - .cmds

total = $ - line10
	endmodule


; NUMS block
nums		db	1
		dw	.datalen
.data		db	#82,#49,#0F,#DA,#A2	;; Value 3.1415927
.datalen = $ - .data
.savelen = $ - nums

; CHARS block
chars		db	1
		dw	.datalen
.data		db	"SAVETAP testing character array"
.datalen = $ - .data
.savelen = $ - chars


; SCREEN$ block
		org	#4000
screen:
	dup 12
		block	256,#AA
		block	256,#55
	edup
	dup 24
		db	#07, #06, #06, #16, #05, #05, #0D, #04, #04, #14, #03, #03, #11, #02, #02, #29
		db	#29, #02, #02, #11, #03, #03, #14, #04, #04, #0D, #05, #05, #16, #06, #06, #07
	edup
.len = $ - screen


; CODE block
		org	#7FFC     ; to cross the slot-boundary

demo:		ei
		halt
		djnz	demo
.loop		ei
		halt
		ld	hl,#5801
		ld	de,#5800
		ld	bc,#300
		ld	a,(de)
		ld	(#5B00),a
		ldir
		call	.rnd
		ld	c,a
		and	#0C
		sub	#0B
		jr	nc,.not12
		ld	a,2
.not12		ld	d,a
		call	.rnd
		ld	e,a
		ld	hl,#5800
		add	hl,de
		ld	a,c
		and	#7F
		xor	(hl)
		ld	(hl),a
		jr	.loop

.rnd		ld	a,#29
		ld	b,a
		rrca
		rrca
		rrca
		xor	#1F
		add	a,b
		sbc	a,#FF
		ld	(.rnd+1),a
		ret
.len = $ - demo
        db      "XXXX"

; Clear output tap file
		emptytap "savetap_next.tap"
; Store BASIC
		savetap	"savetap_next.tap",BASIC,"tstSAVETAP", bas.line10, bas.total, 10
; Store SCREEN#
		savetap	"savetap_next.tap",CODE,"intro", screen, screen.len
; Store CODE
		savetap	"savetap_next.tap",CODE,"demo", demo, demo.len
; Store NUMBERS
		savetap "savetap_next.tap",NUMBERS,"n", nums, nums.savelen, 'n'
; Store CHARS
		savetap "savetap_next.tap",CHARS,"t$", chars, chars.savelen, 't'
; Store HEADLESS
		savetap "savetap_next.tap",HEADLESS, (screen + #1800), 32, 66 ; custom flag


; No autostart (#8000 is used)
		savetap	"savetap_next.tap",BASIC,"No start", bas.line10, bas.total
; Default letter ('A' is used)
		savetap "savetap_next.tap",NUMBERS,"n", nums, nums.savelen
; Address + length > #10000 (block to the end of memory will be saved)
		savetap "savetap_next.tap",HEADLESS, #FFFF, 2

; Extra variants of valid commands to exercise all code paths
		savetap	"savetap_next.tap",CODE,"_extra1", demo, 1, 0x8000, 0x1234
