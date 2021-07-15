; same as Issue144 main test, but in --longptr mode, where the arguments outside of the $0000..$FFFF range are legal

	org	#4000
	disp #10000-this+zac
zac
	nop
this
	ENT
	org	#4000+this-zac
	disp	#0000
	nop
	ENT

	; valid in --longptr mode
	ORG -1
long1
	DISP -2
long2
	nop
	ENT
