; new 'macro' test
;
; test1

	macro MyMacro arg0, arg1
		call arg0_f
		call arg0_arg1
		call arg1_arg0
	endm

	MyMacro abc, def

;should be expanded to:
;
;	call abc_f
;	call abc_def
;	call def_abc

;test 2

	macro a0a1 a0, a1
	call a0_a1__yyy
	endm

	macro a1a0 a0, a1
	call a1_a0___yyy
	endm

	macro a1a0a1 a0, a1
	call a1____a0__a1
	endm

	macro a0_a a0
	call a0_
	endm

	macro a0_b a0
	call __a0		
	endm

	macro a0_c a0
	call _a0_		
	endm

	macro a0a1_a a0, a1
	call a0____a1_
	endm

	macro a0a1_b a0, a1
	call a0____yy_a1
	call _my___yyyyy____yy__call
	endm

	a0a1 abc, def
	a1a0 abc, def
	a1a0a1 abc, def
	a0_a abc
	a0_b abc
	a0_c abc
	a0a1_a abc, def
	a0a1_b abc, def

;should be expanded as
;	call abc_def__yyy
;	call def_abc___yyy
;	call def____abc__def
;	call abc_
;	call __abc
;	call _abc_
;	call abc____def_
;	call abc____yy_def
;	call _my___yyyyy____yy__call
