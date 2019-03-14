;Transient BIOS v1.4, (c)2003 Zilogator
;export from MRS09 by Busy 01/2018
;sjasmplus adaptation by z00m 01/2018
;
;flasher
;	org	#5b00,0
;	di
;	call	8187
;	ld	a,#83
;	out	(#e3),a
;	ld	hl,#6000
;	ld	de,#2000
;	ld	bc,#2000
;	ldir
;	ld	a,#40
;	out	(#e3),a
;	ei
;	ret
;
;flash	di
;	call	8187
;	ld	a,#83
;	out	(#e3),a
;	ld	hl,#00
;	ld	de,#6000
;	ld	bc,#2000
;fla	ld	a,(de)
;	inc	de
;	ld	(hl),a
;	push	bc
;	ld	b,0
;flt	cp	(hl)
;	jr	z,flb
;	djnz	flt
;	pop	bc
;flr	xor	a
;	out	(#e3),a
;	ei
;	ret
;flb	pop	bc
;	inc	hl
;	dec	bc
;	ld	a,b
;	or	c
;	jr	nz,fla
;	jr	flr
;
;TBIOS starts here

	device	zxspectrum48

	org	#0000
p0000	di
p0000r	xor	a
	ld	sp,#4000
	jp	logoex

	org	#0008
p0008	ld	hl,(#5c5d)
p0008r	call	click
	push	hl
	ld	hl,p0008r
cont	ex	(sp),hl
	jp	offret

	org	#001f
l001f	ei
	ret

	org	#0038
p0038	db	24
p0038r	push	hl
	ld	hl,p0038r
	jr	cont

	org	#004d
l004d	push	af
	ld	a,(#2022)
	and	a
	call	z,click
	jr	z,ncnt
	push	hl
	ld	hl,(#2020)
	inc	hl
	ld	(#2020),hl
	pop	hl
ncnt	pop	af
	ret

	org	#0066
p0066	db	24
p0066r	push	hl
	push	de
	push	bc
	ld	a,#fd
	in	a,(#fe)
	push	af
	bit	3,a
	call	z,dset
	pop	af
	rra
	jr	c,nalt
	ld	a,167
	ld	(#8000+adispl),a
nalt	rra
	jr	c,nbck
	ld	bc,#7ffd
	ld	a,23
	out	(c),a
	xor	a
	ld	(#8001+sdispl),a
	im	1
	inc	a
nbck	rra
	call	nc,ident
	ld	a,#fe
	in	a,(#fe)
	rra
	push	af
	call	nc,rsect
	pop	af
	bit	3,a
	call	z,video
	ld	a,#7f
	in	a,(#fe)
	rra
	jr	c,ntest
	xor	a
	out	(#e3),a
	ld	sp,#4000
tlop	call	ramt
	ld	a,b
	or	c
	jp	z,0
	jr	tlop
ntest	rra
	push	af
	call	nc,wsect
	pop	af
	push	af
	and	2
	call	z,tread
	pop	af
	and	4
	call	z,begs
	ld	a,#fb
	in	a,(#fe)
	and	16
	call	z,taps
	pop	bc
	pop	de
	pop	hl
	pop	af
	jp	offrtn

click	push	bc
	push	af
	ld	a,8
	ld	c,#aa
ppp1	ld	b,32
pppo	push	bc
	xor	#10
	out	(#fe),a
	ld	b,c
del3	djnz	del3
	pop	bc
	djnz	pppo
	rlc	c
	jr	c,ppp1
	pop	af
	pop	bc
	ret

cls	ld	hl,#5aff
	ld	a,#47
clrscr	ld	(hl),a
	dec	hl
	bit	3,h
	jr	nz,clratr
	xor	a
clratr	bit	5,h
	jr	z,clrscr
	ret

logoex	out	(#fe),a
	out	(#e3),a
	ld	(#2014),a
	ld	a,#3f
	ld	i,a
	call	cls
	ld	hl,#1ff6
	ld	de,20404
	call	lea
	dec	hl
	ld	de,23030
	call	lea
	dec	hl
	ld	de,8639
	call	lea
	call	click
	dec	hl
	ld	de,20479
	im	1
	ei
	ld	a,#7f
	in	a,(#fe)
	and	16
	jr	nz,nb
	call	lea
	dec	hl
	ld	de,23039
	call	lea
	ld	b,0
lp	halt
	djnz	lp
nb	ld	de,#f000
	ld	hl,txtho
	call	twa
	ld	b,100
waitpx	halt
	ld	a,#7f
	in	a,(#fe)
	and	#1f
	cp	#1d
	jr	z,atest
ssc	djnz	waitpx
	di
rescon	ld	bc,#1ffd
	ld	a,#04
	out	(c),a
	ld	b,#7f
	ld	a,#10
	out	(c),a
	xor	a
	out	(#e3),a
	ld	(#2022),a
	ld	b,a
	ld	sp,#3d00
	ld	hl,#ffff
fillff	push	hl
	djnz	fillff
	ld	hl,p0000r
	jp	offjph

atest	ld	de,#4000
atc	ld	a,#fd
	in	a,(#fe)
	and	#1f
	cp	#1e
	jr	nz,ssc
	dec	de
	ld	a,d
	or	e
	jr	nz,atc
	di
	call	click
wfr	call	cls
	in	a,(#fe)
	cpl
	and	31
	jr	nz,wfr
	call	click
	ld	hl,txtmt
	ld	de,#00
	call	twa
	ld	de,#2000
	ld	hl,#2014
	ld	(hl),a
	ld	a,3
	out	(#e3),a
	xor	(hl)
	ld	(hl),a
	cp	(hl)
	jr	z,okblik
	xor	a
	out	(#e3),a
	ld	hl,txtnp
	call	twa
	jr	btcont
okblik	ld	a,#80
	out	(#e3),a
	ld	(#2022),a
	ld	hl,txthn
	call	twa
	call	waitk
	call	twa
	ld	hl,0
	ld	(#2020),hl
	ld	bc,50255
blik	call	offret
	dec	bc
	inc	b
	djnz	blik
	rst	#38
	di
	xor	a
	out	(#e3),a
	push	de
	call	cnp
	pop	de
	ld	hl,#200f
	call	twa
	ld	hl,txtrn
	call	twa
btcont	ld	hl,txtht
	ld	de,#4000
	call	twa
	ld	hl,#6000
	push	hl
	ld	hl,#c000
	ld	a,#9a
	out	(#7f),a
	ld	a,1
	out	(#7f),a
	ld	c,(hl)
	inc	c
	xor	a
	out	(#7f),a
	ld	(hl),c
	inc	a
	out	(#7f),a
	ld	a,(hl)
	cp	c
	jr	z,no80
	ld	hl,txt80
	call	twa
	pop	de
	ld	hl,txtab
	ld	bc,#8000
	ld	a,#80
	call	testcn
	out	(#7f),a
	jr	cont48
no80	ld	bc,#7ffd
	xor	a
	out	(c),a
	ld	a,(hl)
	inc	a
	ex	af,af
	ld	a,1
	out	(c),a
	ex	af,af
	ld	(hl),a
	ex	af,af
	dec	a
	out	(c),a
	ex	af,af
	cp	(hl)
	jr	z,no128
for128	ld	hl,txt128
	call	twa
	pop	de
	ld	a,8
tlp	dec	a
	cp	3
	jr	nz,nolf
	ld	de,#8000
nolf	ld	bc,#7ffd
	out	(c),a
	ld	hl,txtpg
	push	af
	add	a,"0"
	ld	(#2013),a
	call	twa
	ld	hl,#2013
	ld	bc,#c000
	ld	a,#40
	call	testcn
	pop	af
	and	a
	jr	nz,tlp
	jr	hostfn
no128	ld	hl,txt48
	call	twa
	pop	de
cont48	ld	hl,txtpm
	ld	bc,#8000
	ld	a,#80
	call	testcn
	ld	de,#8000
	ld	bc,#4000
	ld	a,#40
	ld	hl,txtvr
	call	testcn
hostfn	ld	hl,txtmm
	ld	de,#a000
	call	twa
	ld	a,3
	out	(#e3),a
	ld	hl,#2000
	xor	(hl)
	ld	(hl),a
	cp	(hl)
	ld	hl,txtai
	jr	nz,maprai
	ld	hl,0
	ld	de,#2000
	ld	b,d
	ld	c,e
	ldir
	ld	hl,txtin
maprai	ld	a,#40
	out	(#e3),a
	ld	de,#c000
	call	twa
	ld	de,#e000
	call	twa
	ld	hl,stepxc
	ld	de,#5b00
	ld	bc,txtho-stepxc
	ldir
	ld	hl,#5b00+rdispl
	ld	(#5b01+t1),hl
	ld	(#5b01+t2),hl
	ld	(#5b01+t3),hl
	ld	hl,#5b00+wdispl
	ld	(#5b01+t4),hl
	ld	(#5b01+t5),hl
	ld	(#5b01+t6),hl
	ld	(#5b01+t7),hl
	ld	de,#0800
	ld	a,"0"
dramt	push	af
	ld	(#2013),a
	ld	hl,txtdp
	call	twa
	ld	hl,#2013
	ld	bc,#2000
	ld	a,#20
	call	testcn
	pop	af
	inc	a
	cp	"4"
	jr	c,dramt
	ld	hl,txtee
	ld	de,#2800
	call	twa
	ld	de,#4800
	call	twa
	call	waitk
	ld	bc,#00
	ld	a,#20
	call	testcn
	ld	de,#6800
	ld	hl,txtdd
	call	twa
	ld	de,#8800
	ld	a,160
ddl	out	(#bb),a
	push	af
	push	hl
	ld	hl,txtdl
	call	twa
	pop	hl
	call	twa
	ld	a,#ec
	call	waitid
	jr	nz,nohd
	ld	hl,txthd
	ld	bc,proghd
	jr	dfou
nohd	ld	a,#a1
	call	waitid
	jr	nz,nocd
	ld	hl,txtcd
	ld	bc,prognl
dfou	push	bc
	call	twa
	ld	bc,#a3
	ld	hl,#2200
	inir
	inir
	ld	hl,progcd
	call	prgint
	pop	hl
	call	prgint
	jr	endl
nocd	ld	hl,txtno
	call	twa
endl	pop	af
	ld	hl,txtsl
	ld	de,#5000
	add	a,16
	cp	192
	jp	c,ddl
	call	waitk
	jp	rescon

xchvr	push	hl
	push	bc
	push	de
	ld	hl,#4000
	ld	de,#2200
	ld	bc,6912
	jr	nc,nchan
	ex	de,hl
nchan	ldir
	pop	de
	pop	bc
	pop	hl
	ret

testcn	push	bc
	push	af
	call	twa
	pop	bc
	pop	hl
	ld	c,0
	push	de
	ld	a,b
	cp	#20
	jr	z,outst
	xor	#40
	call	z,xchvr
	push	af
	call	stepxc
	pop	af
	scf
	call	z,xchvr
retto	ld	(#2020),bc
	call	cnp
	pop	de
	ld	hl,#200e
	ld	(hl)," "
	call	twa
	ld	hl,txbok
	jp	twa
outst	ld	(#5bfe),sp
	ld	sp,#5bfe
	ld	de,#5c00
	push	hl
	push	bc
	ld	a,(#2013)
	add	a,#80-"0"
	jp	#5b00+xdispl

prgint	ld	a,(hl)
	inc	hl
	cp	#ff
	ret	nc
	cp	#fe
	jr	nc,appen
	and	a
	ld	e,a
	jr	nz,appen
	ld	a,32
	add	a,d
	jr	nc,ldda
	add	a,8
ldda	ld	d,a
appen	call	twa
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	inc	hl
	push	bc
	ld	b,(hl)
	inc	hl
	or	(hl)
	inc	hl
	ex	(sp),hl
	jr	nz,numb
typp	ld	a,(hl)
	inc	hl
	ld	(#2013),a
	ld	a,(hl)
	inc	hl
	ld	(#2012),a
	push	hl
	ld	hl,#2012
	push	bc
	call	twa
	pop	bc
	pop	hl
	djnz	typp
	jr	pophlc
numb	ld	c,a
	push	de
	ex	de,hl
	call	cna
	pop	de
	ld	a,"0"
	ld	b,19
loops	inc	l
	cp	(hl)
	jr	nz,typit
	djnz	loops
typit	call	twa
pophlc	pop	hl
	jr	prgint

waitid	ei
	out	(#bf),a
	ld	b,250
waitil	in	a,(#bf)
	xor	#48
	and	#c8
	jr	z,waitrt
	halt
	djnz	waitil
waitrt	di
	ret

waitk	push	af
wk	xor	a
wtd	in	a,(#fe)
	cpl
	and	31
	jr	z,wtd
	pop	af
	ret

	org	#0580
ramt	ld	hl,16384
	ld	bc,#c000
stepxc	push	bc
	push	hl
wrtzrr	xor	a
wrtzer	call	wflash
	jr	nz,bugx
	dec	bc
	ld	a,b
	or	c
	jr	nz,wrtzrr
	pop	hl
	pop	bc
	push	bc
	push	hl
lokzer	xor	a
	or	(hl)
	jr	nz,bugx
	dec	a
wrtffs	call	wflash
	jr	nz,bugx
	dec	bc
	ld	a,b
	or	c
	jr	nz,lokzer
	pop	hl
	pop	bc
	push	bc
	push	hl
	ld	d,a
fillx	ld	a,(hl)
	inc	a
	jr	nz,bugx
filly	call	prand
wrtpos	call	wflash
	jr	z,donex
bugx	pop	hl
bugy	pop	bc
	xor	a
	ld	c,a
	ld	b,a
	ret
donex	dec	bc
	ld	a,b
	or	c
	jr	nz,fillx
	pop	hl
	pop	bc
	ld	d,a
	push	bc
	push	hl
checkx	call	prand
	cp	(hl)
	jr	nz,bugx
	cpl
wrtcpl	call	wflash
	jr	nz,bugx
	dec	bc
	ld	a,b
	or	c
	jr	nz,checkx
	pop	hl
	pop	bc
	ld	d,a
	push	bc
lastck	call	prand
	add	a,(hl)
	inc	a
	jr	nz,bugy
	inc	hl
	dec	bc
	ld	a,b
	or	c
	jr	nz,lastck
	pop	bc
	ret

prand	ld	a,d
	add	a,a
	add	a,a
	add	a,d
	inc	a
	ld	d,a
	xor	b
	ret

wflash	ld	(hl),a
	push	bc
	ld	b,0
rchck	cp	(hl)
	jr	z,retw
	djnz	rchck
retw	pop	bc
	inc	hl
	ret

ramts	out	(#e3),a
	ldir
	pop	bc
	pop	hl
	push	hl
	push	bc
	call	#5b00
	pop	de
	pop	hl
	push	bc
	ld	bc,#5c00
putbg	ld	a,(bc)
	call	#5b00+wdispl
	inc	bc
	dec	de
	ld	a,d
	or	e
	jr	nz,putbg
	pop	bc
	ld	sp,(#5bfe)
	out	(#e3),a
	jp	retto

txtho	db	"Transient BIOS v"
	db	"1.4 ",#7F," Zilogator "
	db	"2003 - Hold SS+A"
	db	" to run autotest"
	db	0
txthn	db	"Hold NMI, press "
	db	"key: "
	db	0
txtie	db	"Making 50000 "
	db	"edges, "
	db	0
txtrn	db	" done, "
	db	"release NMI"
	db	0
txtmt	db	"CLOCKING LOGIC "
	db	"TEST: "
	db	0
txtnp	db	"Skipped, turn off"
	db	" MAPRAM mode to "
	db	"get it work"
	db	0
txbok	db	" OK  "
	db	0
txtht	db	"HOST RAM TEST "
	db	"["
	db	0
txt48	db	"48KB]:"
	db	0
txt80	db	"80KB]:"
	db	0
txt128	db	"128KB]:"
	db	0
txtab	db	"Auxiliary 32k"
	db	0
txtpm	db	"Main 32k"
	db	0
txtvr	db	"Videoram 16k"
	db	0
txtpg	db	"Page"
	db	0
txtmm	db	"MAPRAM MODE TEST:"
	db	0
txtai	db	"Already "
txtin	db	"OK, installed"
	db	0
txtdm	db	"DIVIDE RAM TEST:"
	db	0
txtdp	db	"Bank"
	db	0
txtee	db	"DIVIDE EEPROM "
	db	"TEST:"
	db	0
txtrm	db	"Open EPROM jumper"
	db	" for testing, "
	db	"press key: "
	db	0
txtep	db	"Eeprom"
	db	0
txtdd	db	"DETECTING AT-IDE"
	db	" AND ATAPI "
	db	"DEVICES:"
	db	0
txtma	db	"0 [MASTER]: "
	db	0
txtdl	db	"DEVICE "
	db	0
txtsl	db	"1 [SLAVE]: "
	db	0
txthd	db	"Disk"
	db	0
txtcd	db	"CD-Rom"
	db	0
txtno	db	"None"
	db	0
progcd	db	0
	db	"Model: "
	db	0
	dw	#2236
	db	20
	db	0
	db	49
	db	"Rev: "
	db	0
	dw	#222e
	db	4
	db	0
prognl	db	#ff
proghd	db	0
	db	"SN: "
	db	0
	dw	#2214
	db	10
	db	0
	db	32
	db	"Buffer: "
	db	0
	dw	#222a
	db	2
	db	#80
	db	#fe
	db	" sectors"
	db	0
	dw	#2013
	db	1
	db	0
	db	0
	db	"Current CHS: "
	db	0
	dw	#226d
	db	2
	db	#80
	db	#fe
	db	"/"
	db	0
	dw	#226f
	db	2
	db	#80
	db	#fe
	db	"/"
	db	0
	dw	#2271
	db	2
	db	#80
	db	32
	db	"  Default CHS: "
	db	0
	dw	#2203
	db	2
	db	#80
	db	#fe
	db	"/"
	db	0
	dw	#2207
	db	2
	db	#80
	db	#fe
	db	"/"
	db	0
	dw	#220d
	db	2
	db	#80
	db	0
	db	"Current "
	db	" capacity: "
	db	0
	dw	#2275
	db	4
	db	#80
	db	#fe
	db	" sectors  "
	db	"Multiple "
	db	"sectors: "
	db	0
	dw	#225e
	db	1
	db	#80
	db	0
	db	"LBA addressable"
	db	" sectors: "
	db	0
	dw	#227b
	db	4
	db	#80
	db	#fe
	db	"  Multiple "
	db	"setting: "
	db	0
	dw	#2276
	db	1
	db	80
	db	#ff

lea	xor	a
	ld	b,a
	ld	a,(hl)
	dec	hl
	rra
	ld	c,a
	jr	c,leb
	or	(hl)
	ret	z
	ld	a,15
	and	c
	ld	b,4
lex	srl	c
	djnz	lex
	push	hl
	ld	l,(hl)
	ld	h,a
	add	hl,de
	inc	c
	inc	c
leb	inc	c
	lddr
	jr	c,lea
	pop	hl
	dec	hl
	jr	lea

wsect	ld	b,12
	ld	hl,#4000
	ld	a,(23296)
	and	31
	add	a,160
	out	(187),a
	ld	de,#c040
	call	wait
	ld	a,2
	out	(175),a
	ld	a,0
	out	(179),a
	ld	a,0
	out	(183),a
	ld	a,b
	out	(171),a
	ld	a,#30
	out	(191),a
sector	ld	de,#c848
	call	wait
	push	bc
	ld	bc,#a3
	otir
	otir
	pop	bc
	djnz	sector
	jr	frew

rsect	ld	b,12
	ld	hl,#4000
	ld	a,(23296)
	and	31
	add	a,160
	out	(187),a
	ld	de,#c040
	call	wait
	ld	a,2
	out	(175),a
	ld	a,0
	out	(179),a
	ld	a,0
	out	(183),a
	ld	a,b
	out	(171),a
	ld	a,#20
	out	(191),a
sektor	ld	de,#c848
	call	wait
	push	bc
	ld	bc,#a3
	inir
	inir
	pop	bc
	djnz	sektor
frew	in	a,(191)
	ret

wait	in	a,(191)
	xor	e
	and	d
	ret	z
	xor	a
	in	a,(254)
	and	31
	jr	nz,wait
	ret

twa	xor	a
	ld	b,a
	or	(hl)
	inc	hl
	ret	z
	push	hl
	push	de
	ld	h,4
	rra
	ld	l,a
	ld	c,a
	rla
	xor	e
	add	hl,hl
	add	hl,hl
	add	hl,hl
	sbc	hl,bc
	ld	bc,#800f
	rra
	rr	b
	srl	e
	jr	c,twb
	ld	c,#f0
twb	ex	de,hl
	ld	a,#e0
	and	h
	or	l
	ld	l,a
	ld	a,#18
	and	h
	add	a,#40
	ld	h,a
twc	ld	a,(de)
	bit	7,b
	jr	z,twd
	rrca
	rrca
	rrca
	rrca
twd	xor	(hl)
	and	c
	xor	(hl)
	ld	(hl),a
	inc	h
	inc	de
	sra	b
	jr	nc,twc
	ld	a,c
	cpl
	and	(hl)
	ld	(hl),a
	pop	de
	pop	hl
	inc	e
	jr	twa

cnp	ld	bc,#0280
	ld	de,#2021
cna	ld	hl,#2013
cnc	ld	(hl),"0"
	dec	l
	jr	nz,cnc
cnd	ld	l,#13
	ld	a,(de)
	and	c
	add	a,255
cne	ld	a,(hl)
	adc	a,a
	sub	"0"
	cp	"9"+1
	jr	c,cnf
	sub	#0a
cnf	ccf
	ld	(hl),a
	dec	l
	jr	nz,cne
	srl	c
	jr	nc,cnd
	ld	c,128
	dec	de
	djnz	cnd
	ret

video	ld	hl,#5b80
	and	4
	jr	z,cus
	ld	hl,matrdf
cus	ld	a,#f7
	in	a,(#fe)
	ld	de,16
	ld	b,5
msl	rra
	jr	nc,vva
	add	hl,de
	djnz	msl
vva	xor	a
	out	(#e3),a
	ld	d,#22
	call	gen
	ld	hl,dsc
	ld	de,#2600
	ld	bc,sen-dsc
	ld	a,31
crt	ldir
	ld	hl,sbg
	ld	c,sen-sbg
	dec	a
	jr	nz,crt
	ld	c,lar-sbg
	ldir
	ld	b,32
mla	dec	hl
	dec	hl
	ldi
	ldi
	djnz	mla
	ld	c,gen-lar
	ldir
	ld	a,i
	push	af
	push	ix
	ei
vlp	ld	ix,23296
	inc	(ix+8)
	ld	a,5
	out	(#ab),a
	ld	a,(ix+1)
	ld	e,(ix+5)
	inc	e
	cp	e
	jr	c,sok
	dec	e
	sub	e
	inc	(ix+2)
sok	out	(#af),a
	add	a,5
	ld	(ix+1),a
	ld	a,(ix+2)
	cp	(ix+6)
	jr	c,hok
	xor	a
	inc	(ix+3)
	jr	nz,hok
	inc	(ix+4)
hok	ld	(ix+2),a
	add	a,(ix+0)
	out	(#bb),a
	ld	a,(ix+3)
	out	(#b3),a
	ld	a,(ix+4)
	out	(#b7),a
	ld	de,#c040
	call	wait
	ld	a,#20
	out	(#bf),a
	halt
	ld	de,#c848
	ld	hl,#2800
	ld	b,2
rsx	call	wait
	push	bc
	ld	bc,#a3
	inir
	inir
	pop	bc
	djnz	rsx
	ld	a,(ix+8)
	and	1
	push	af
	add	a,#40
	ld	b,a
	ld	c,#1f
	pop	af
	rlca
	add	a,#22
	ld	h,a
	call	#2600
	ld	a,#fd
	in	a,(#fe)
	and	2
	jr	nz,nhl
	ld	b,(ix+7)
wff	halt
	djnz	wff
nhl	ld	a,#bf
	in	a,(#fe)
	rra
	jp	c,vlp
	pop	ix
	pop	af
	ret	pe
	di
	ret

dsc	ld	de,#c848
	call	wait
	ld	e,c
	ld	d,b
	inc	d
	inc	d
	push	bc
sbg	in	a,(#a3)
	ld	l,a
	ld	a,(hl)
	inc	h
	ld	(bc),a
	ldd
	res	0,h
sen	pop	bc
	ld	a,4
	xor	b
	ld	b,a
	and	4
	jp	nz,#2606
	ld	a,32
	add	a,c
	ld	c,a
	jp	nc,#2606
	push	hl
	push	bc
	ld	a,b
	rra
	rra
	rra
	and	3
	add	a,#28
	ld	h,a
	add	a,#58-#28
	ld	d,a
	ld	l,0
	ld	e,l
	ld	c,l
	ld	b,9
	ldi
lar	djnz	$-64
	pop	bc
	pop	hl
	ld	a,8
	add	a,b
	ld	b,a
	cp	#58
	jp	c,#2600
	in	a,(#bf)
	ret

gen	ld	e,0
	ld	b,#50
ged	push	bc
gec	ld	a,e
	ld	b,#11
geb	push	hl
gea	cp	(hl)
	rl	c
	inc	hl
	sla	b
	jr	nc,gea
	pop	hl
	rlca
	rlca
	rlca
	rlca
	jr	nz,geb
	ld	a,c
	cpl
	ld	(de),a
	inc	e
	jr	nz,gec
	ld	c,4
	add	hl,bc
	pop	bc
	sla	b
	ret	z
	dec	d
	jr	c,ged
	inc	d
	inc	d
	inc	d
	jr	ged

vrcp	ld	hl,#e000
	ld	de,#4000
	ld	bc,6912
	ldir
	ret

dset	push	af
	ld	a,#17
	ld	bc,#7ffd
	out	(c),a
	call	vrcp
	ld	c,ident-servcd
	ld	hl,servcd
	ld	de,#8000
	ldir
	ld	hl,#fff4
	ld	(hl),#c3
	ld	l,#ff
	ld	(hl),#18
	ld	hl,#8000
	ld	(#fff5),hl
	pop	af
	bit	4,a
	jr	nz,nogam
	ld	hl,#e810
	ld	(#8000+ndispl),hl
	ld	hl,#8001+bdispl
	dec	(hl)
	dec	(hl)
	xor	a
	ld	(#8002+ndispl),a
nogam	ld	a,#7f
	in	a,(#fe)
	and	4
	jr	nz,noem
	ld	a,10
	ld	(#8001+cdispl),a
	ld	a,74
	ld	(#8001+bdispl),a
noem	ld	hl,#be00
fllit	ld	(hl),#ff
	inc	l
	jr	nz,fllit
	ld	a,h
	inc	h
	ld	(hl),#ff
	ld	i,a
	im	2
	ret

servcd	push	af
	push	bc
frame	ld	a,#3f
	ld	bc,#7ffd
	and	a
	rra
	exx
	ex	af,af
	push	af
	push	bc
barg	ld	bc,870
wt	dec	bc
	inc	b
	djnz	wt
	jr	nop3
nop1	nop
nop2	nop
nop3	nop
nop4	nop
nop5	nop
	ld	b,192
qew	exx
	ex	af,af
swout	out	(c),a
altplc	ccf
	jr	c,noxor
	xor	8
noxor	jr	nc,conti
	ld	b,#7f
conti	exx
	ex	af,af
carg	ld	c,9
delln	dec	c
	jr	nz,delln
	ld	c,0
nopa	nop
	djnz	qew
	pop	bc
	pop	af
	exx
	ex	af,af
	ccf
	rla
	bit	0,a
	jr	z,stocr
	xor	16
stocr	ld	(#8001+fdispl),a
	pop	bc
	pop	af
	jp	#38

ident	ld	a,#f7
	in	a,(#fe)
	and	2
	ld	a,#a0
	jr	nz,idm
	ld	a,#b0
idm	ld	hl,#5b00
	ld	(hl),a
	out	(#bb),a
	xor	a
	ld	b,4
w	inc	l
	ld	(hl),a
	djnz	w
	ld	de,#c040
	call	wait
	ld	a,#ec
	out	(#bf),a
	ld	de,#c848
	call	wait
	ld	hl,#2200
	ld	bc,#a3
	inir
	inir
	ld	de,#c040
	call	wait
	ld	a,(#220c)
	ld	(23301),a
	out	(#ab),a
	ld	a,(#2206)
	ld	(23302),a
	dec	a
	ld	c,a
	ld	a,(23296)
	or	c
	out	(#bb),a
	ld	de,#c040
	call	wait
	ld	a,#91
	out	(#bf),a
	ld	de,#c040
	call	wait
cnow	jp	click

nrthl	ld	de,(23297)
	ld	bc,(23299)
	ld	a,(23301)
	xor	e
	jr	nz,chsok
	ld	e,a
	inc	d
	ld	a,(23302)
	xor	d
	jr	nz,chsok
	ld	d,a
	inc	bc
chsok	inc	e
	ld	a,(23296)
	or	d
	out	(#bb),a
	push	de
	ld	de,#c040
	call	wait
	pop	de
	inc	a
	out	(#ab),a
	ld	a,e
	out	(#af),a
	ld	a,c
	out	(#b3),a
	ld	a,b
	out	(#b7),a
	ld	a,#20
	out	(#bf),a
	push	bc
	push	de
	ld	de,#c848
	call	wait
	ld	hl,#2400
	ld	bc,#a3
	inir
	inir
	ld	de,#c040
	call	wait
	pop	de
	pop	bc
	ret

pushm	ld	(23297),de
	ld	(23299),bc
	ret

taps	ld	de,taptag
	ld	hl,#2400
	call	begc
	ld	hl,#2618
	ld	(23305),hl
	ret

begs	ld	de,pictag
	ld	hl,#2500
begc	ld	(23305),de
	ld	(23307),hl
begsl	ld	a,(23297)
	and	7
	out	(#fe),a
	xor	a
	in	a,(#fe)
	and	31
	ret	z
	call	nrthl
	push	bc
	push	de
	ld	b,12
	ld	hl,(23307)
	ld	de,(23305)
	call	swrap
	pop	de
	pop	bc
	jr	z,ckey
	call	pushm
	jr	begsl
ckey	xor	a
	out	(#fe),a
	in	a,(#fe)
	cpl
	and	31
	jr	nz,ckey
	jp	click

tread	ld	de,#c000
	call	fets
	ld	de,#e000
	call	fets
	call	vrcp
	jr	ckey

fets	ld	bc,#1b00
nexr	ld	hl,(23305)
pude	push	de
	bit	1,h
	jr	z,noren
	res	1,h
	push	hl
	push	bc
	call	nrthl
	call	pushm
	pop	bc
	pop	hl
noren	ex	de,hl
	ld	hl,-#2600
	add	hl,de
	add	hl,bc
	jr	c,hlpok
	ld	hl,0
hlpok	ex	(sp),hl
	jr	nc,bcok
	push	hl
	ld	hl,#2601
	sbc	hl,de
	ld	b,h
	ld	c,l
	pop	hl
bcok	ex	de,hl
	ldir
	pop	bc
	ld	a,b
	or	c
	jr	nz,pude
	ld	c,25
	add	hl,bc
	ld	(23305),hl
	ret

swrap	push	hl
read	ld	a,(de)
	cp	(hl)
	jr	nz,nosuc
	inc	de
	inc	hl
	djnz	read
nosuc	pop	hl
	ret

pictag	db	"00000001.png"

taptag	db	#13,0,0,3
	db	"DithvIDE"

matrdf	db	#3f,#1f,#2f,#0f
	db	#7f,#5f,#6f,#4f
	db	#bf,#9f,#af,#8f
	db	#ff,#df,#ef,#cf

chess	db	#0f,#cf,#3f,#ff
	db	#8f,#4f,#bf,#7f
	db	#2f,#ef,#1f,#df
	db	#af,#6f,#9f,#5f

matcdf	db	#0f,#4f,#8f,#1f
	db	#bf,#ff,#cf,#5f
	db	#7f,#cf,#df,#9f
	db	#3f,#af,#6f,#2f

matodf	db	#ff,#ef,#df,#cf
	db	#4f,#3f,#2f,#bf
	db	#5f,#0f,#1f,#af
	db	#6f,#7f,#8f,#9f

mattdf	db	#0f,#2f,#5f,#9f
	db	#1f,#4f,#8f,#cf
	db	#3f,#7f,#bf,#ef
	db	#6f,#af,#df,#ff

matzdf	db	#0f,#cf,#4f,#8f
	db	#1f,#df,#5f,#9f
	db	#2f,#ef,#6f,#af
	db	#3f,#ff,#7f,#bf

	org	#04c6
p04c6	ld	hl,#1f80
p04c6r	call	click
	push	hl
	ld	hl,p04c6r
	jp	cont

	org	#0562
p0562	in	a,(#fe)
p0562r	call	click
	push	hl
	ld	hl,p0562r
	jp	cont

	org	#15d0
	incbin	"tbios-logo.bin"

	org	#1ff7
offrtn	retn
offret	ret
offjph	jp	(hl)

adispl	equ	altplc-servcd
sdispl	equ	swout-servcd
rdispl	equ	prand-stepxc
t1	equ	filly-stepxc
t2	equ	checkx-stepxc
t3	equ	lastck-stepxc
wdispl	equ	wflash-stepxc
t4	equ	wrtpos-stepxc
t5	equ	wrtcpl-stepxc
t6	equ	wrtzer-stepxc
t7	equ	wrtffs-stepxc
xdispl	equ	ramts-stepxc
ndispl	equ	nopa-servcd
cdispl	equ	carg-servcd
bdispl	equ	barg-servcd
fdispl	equ	frame-servcd

	savebin "tbiosv14.bin",$0000,$2000

	end
