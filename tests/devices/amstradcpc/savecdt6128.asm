    DEVICE AMSTRADCPC6128
    ORG     0x1200

CPC_PAGE_1 MACRO page
    ld b,$74
    ld a,page
    or %11000000
    ld c,a
    out (c),c
ENDM

CPC_SET_PEN0_AND_BORDER MACRO
    ld b,$7F

    ld c,$00    ; penr=0
    out (c),c

    ld c,a
    out (c),c

    ld c,$10    
    out (c),c

    ld c,a
    out (c),c
ENDM

start:
    di
    im 1

    ld b,$7F
	ld c,%100'011'01 ; disable ROMS
	out (c),c

    ; sync to frame
    call cpc_sync_frame

    ; Install interrupt handler
    ld a,$C3	;; Z80 JP instruction
    ld hl,int1	;; first function to call
    ld ($0038),a	;; write JP instruction
    ld ($0039),hl	;; write address

    ei

    ld b,$7F
    ld c,$00    ; penr=0
    out (c),c

.loop:
    nop

    jr .loop

; interrupt setup based on example: http://cpctech.cpc-live.com/source/hwint.asm
cpc_sync_frame:
    di
    im 1
    ;; wait vsync (loop passes if VSYNC signal is high = in vsync)
    ld b,$F5
.wait1:
    in a,(c)
    rra
    jr nc,.wait1
;; wait for end of vsync (loop passes when VSYNC signal is low = out of vsync)
.wait2:
    in a,(c)
    rra
    jr c,.wait2
;; now wait again for start (because we know we found the end, if we wait for VSYNC to be active
;; we know it will be the start)
.wait3:
    in a,(c)
    rra
    jr nc,.wait3
    ret

;; this is synchronised to happen 2 HSYNCs after VSYNC
int1:
    di
    push hl
    ld hl,int2				;; we handle int2 next
    ld ($0039),hl			;; set new interrupt vector address
    pop hl
    ei
    reti

;;--------------------------------------------------------------------------------------------


int2:
    di
    push hl
    ld hl,int3				;; we handle int3 next
    ld ($0039),hl			;; set new interrupt vector address

    push bc
    push af
    CPC_PAGE_1 4
    ld a,($4000)
    CPC_SET_PEN0_AND_BORDER
    pop af
    pop bc

    pop hl
    ei
    reti

;;--------------------------------------------------------------------------------------------


int3:
    di
    push hl
    ld hl,int4				;; we handle int4 next
    ld ($0039),hl			;; set new interrupt vector address

    push bc
    push af
    CPC_PAGE_1 5
    ld a,($4000)
    CPC_SET_PEN0_AND_BORDER
    pop af
    pop bc

    pop hl
    ei
    reti

;;--------------------------------------------------------------------------------------------


int4:
    di
    push hl
    ld hl,int5				;; we handle int5 next
    ld ($0039),hl			;; set new interrupt vector address

    push bc
    push af
    CPC_PAGE_1 6
    ld a,($4000)
    CPC_SET_PEN0_AND_BORDER
    pop af
    pop bc

    pop hl
    ei
    reti

;;--------------------------------------------------------------------------------------------

int5:
    di
    push hl
    ld hl,int6				;; we handle int6 next
    ld ($0039),hl			;; set new interrupt vector address

    push bc
    push af
    CPC_PAGE_1 7
    ld a,($4000)
    CPC_SET_PEN0_AND_BORDER
    pop af
    pop bc

    pop hl
    ei
    reti

;;--------------------------------------------------------------------------------------------

int6:
    di
    push hl
    ld hl,int1				;; we loop back to int1 next
    ld ($0039),hl			;; set new interrupt vector address

    push bc
    push af
    ld b,$74
    ld c,%11000000
    out (c),c

    ld a,$54
    CPC_SET_PEN0_AND_BORDER
    pop af
    pop bc

    pop hl
    ei
    reti

; test-screen graphics definition to expand in macro later
test_scr:
    .dg ----####-####---####----
    .dg ---#-----#---#-#--------
    .dg ---#-----#---#-#--------
    .dg ---#-----####--#--------
    .dg ---#-----#-----#--------
    .dg ---#-----#-----#--------
    .dg ----####-#------####----

    SLOT 1 : PAGE 4
    ORG $4000
    .ds $40, $4D

    SLOT 1 : PAGE 5
    ORG $4000
    .ds $40, $53

    SLOT 1 : PAGE 6
    ORG $4000
    .ds $40, $5A

    SLOT 1 : PAGE 7
    ORG $4000
    .ds $40, $4C

; define temporary label in all passes to avoid error in pass3 when it is first time used in IF block
dither_fill = 0

; "draw" into VRAM 8x8 dithered block
DITHER_BLOCK_8x8 MACRO adr?, fill?
        ORG adr?-$800+2         ; one line above to make filler-loop simpler
dither_fill = low(((fill?) << 1) | ((fill?) >> 7)) ; swap odd/even pixels by rotating each nibble
        IF ((dither_fill>>4)^dither_fill)&1
dither_fill = dither_fill ^ $11
        ENDIF
        DUP 4                   ; fill four times two rows of pixels
            ORG $+$800-2 : .ds 2, fill?
            ORG $+$800-2 : .ds 2, dither_fill
        EDUP
    ENDM

; "draws" into VRAM 24x7 logo defined by test_scr, drawing it with 8x8 dithered blocks of pixels
    DEFARRAY colors $05, $0F, $5F, $FF, $FA, $F0, $50
gfx_def = test_scr
color_i = 0
first_tile_adr = $C010 + 7*$50
    DUP 7   ; 7 rows
tile_adr = first_tile_adr
        DUP 3   ; 3 bytes of bitmap data
gfx = {b gfx_def}
gfx_def = gfx_def + 1
            DUP 8   ; 8 bits of bitmap data, draw block per bit
                IF $80 & gfx : DITHER_BLOCK_8x8 tile_adr, colors[color_i] : ENDIF
gfx = gfx << 1
tile_adr = tile_adr + 2
            EDUP
        EDUP
first_tile_adr = first_tile_adr + $50
color_i = color_i + 1
    EDUP

; save the full snapshot in .CDT format (w/loader)
	SAVECDT FULL "savecdt6128.cdt", start, 1, 0, 0, 26, 6, 24
