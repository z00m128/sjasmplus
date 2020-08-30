	MODULE TestModule

		jp	klLDI64	; creates full-module undefined symbol in the table (`TestModule.klLDI64`)

@klLDI64:	nop		; defines global `klLDI64` (will overshadow the `TestModule.klLDI64`)

cmCOPY:		ex	de, hl  ; defines regular module-label `TestModule.cmCOPY`

    ; the double klLDI64 confuses here expression evaluator (bug)
    ; to report forward reference warning (in sjasmplus 1.17.0)
	IF	high cmCOPY > high klLDI64 : ENDIF

	ENDMODULE
