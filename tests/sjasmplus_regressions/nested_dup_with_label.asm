	output "nested_dup_with_label.bin"
2	dup 3
1		dup	2
			ld e,b
		edup
		djnz 1b
	edup
	djnz 2b

	; similar code, but with directives at beginning of line enabled
	OPT --dirbol
dup 3
1	dup	2
			ld e,b
edup
	djnz 1b
edup
	djnz 2b
