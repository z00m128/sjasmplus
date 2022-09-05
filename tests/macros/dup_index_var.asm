	MACRO filler x1, x2, y1, y2
		DUP (y2 - y1), .y
			DUP (x2 - x1), .x
				DB x1 + .x, y1 + .y
			EDUP
		EDUP
		IF .x	; index variable does exist after DUP with last used index (not +1 beyond it!)
			DD 0xA0DED1BA	; but this is not documented and rather shouldn't be used at all
		ENDIF
	ENDM

	filler 3, 5, 10, 12
	filler 100, 101, 200, 201

	DUP 4   ,   idx			; eol comment test
		DB    0x12, idx
	EDUP

main:
	DUP 2   ,   .idx		; eol comment test
		DB    0x23, .idx
	EDUP

	DUP 1   ,   @idx2		; only local label prefix "." is supported for index variable name
		DB    0x34, @idx2
	EDUP

	DUP 1   ,   !idx2		; only local label prefix "." is supported for index variable name
		DB    0x45, idx2
	EDUP

	DUP 1 .idx				; invalid syntax, missing comma
	EDUP

	DUP 1 					; w/o indexVar name, eol comment test
		DB idx, .idx
	EDUP

