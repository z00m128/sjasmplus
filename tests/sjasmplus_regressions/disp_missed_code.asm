        device zxspectrum128

        org #7ff1
start
        disp #1eb4

        ld a,77h
        out (3),a
wdn     in a,(4)
        rla
        jr c,wdn
        ret

wdy	in a,(4)
	rla
	jr nc,wdy
	ret


	di
	ld (#1234),sp
        ld a,77h
        out (3),a
        ld a,77h
        out (3),a
        ld a,77h
        out (3),a
        ld a,77h
        out (3),a
	db ' hello! '

	ent

len equ $-start

        savebin "disp_missed_code.bin",start,len
