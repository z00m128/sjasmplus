; reported by Busy
	DEVICE	ZXSPECTRUM48
	org	#4000
	disp #10000-this1+zac1
zac1
	nop
this1
	ENT
	org	#4000+this1-zac1
	disp	#0000
	nop
	ENT

	; test the warnings about cropping invalid ORG and DISP arguments
	ORG -1
	DISP -2
	ENT

	; no device mode
	DEVICE NONE

	org	#4000
	disp #10000-this2+zac2
zac2
	nop
this2
	ENT
	org	#4000+this2-zac2
	disp	#0000
	nop
	ENT

	; test the warnings about cropping invalid ORG and DISP arguments
	ORG -1
	DISP -2
	ENT
