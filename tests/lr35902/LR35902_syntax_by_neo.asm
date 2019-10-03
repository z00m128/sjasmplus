;; Sharp LR35902 - various syntax variants provided by NEO SPECTRUMAN
;; https://zx-pk.ru/threads/30314-sjasmplus-ot-z00m.html?p=1028186&viewfull=1#post1028186
;; Syntax examples are from IDA (disassembler), bgb (emulator) and GameBoy CPU Manual
;; also cross-checked with http://www.pastraiser.com/cpu/gameboy/gameboy_opcodes.html

;; 10 errors are expected! These syntax variants are *NOT* compatible with sjasmplus:
; 4x "($FF00+c)" to emit `ld a,(c)` or `ld (c),a`; use "(c)" or "[c]" without $FF00 constant
; 4x "HLI"/"HLD" as "HL+"/"HL-"; use HL+/HL- (or LDI/LDD with HL only)
; "ld hl,[sp+n]"; use logical syntax `ld hl,sp+rel8`, it's not accessing memory
; "ldhl" alias; same as above, use the `ld hl,sp+rel8` syntax

;; these are intentionally left out. don't expect sjasmplus to support any of these.
; reasons: either the syntax is atrocious like "ld hl,[sp+0]" or the extra syntax adds
; too much complexity and/or possible accidental collisions, like "hli" label, etc.

; in the end the sjasmplus is 100% compatible with IDA disassembler syntax and supports
; at least one variant from CPU Manual (if not all of them).
; Only bgb compatibility is not 100%, and sources from bgb may need syntax fixing.

n:      OPT --syntax=ab         ; "a" = multiarg is ",," to support "sub a,n" syntax
nn:                             ; "b" = "(expr.)" is legit only for memory access

;			:IDA		:bgb		:GBCPUman.pdf
  defb $06,0		:ld b,0		:ld b,$00	:LD B,n
  defb $0E,0		:ld c,0		:ld c,$00	:LD C,n
  defb $16,0		:ld d,0		:ld d,$00	:LD D,n
  defb $1E,0		:ld e,0		:ld e,$00	:LD E,n
  defb $26,0		:ld h,0		:ld h,$00	:LD H,n
  defb $2E,0		:ld l,0		:ld l,$00	:LD L,n
  defb $36,0		:ld [hl],0	:ld [hl],$00	:LD (HL),n
  defb $3E,0		:ld a,0		:ld a,$00	:LD A,n

  defb $40		:ld b,b		:ld b,b		:LD B,B
  defb $41		:ld b,c		:ld b,c		:LD B,C
  defb $42		:ld b,d		:ld b,d		:LD B,D
  defb $43		:ld b,e		:ld b,e		:LD B,E
  defb $44		:ld b,h		:ld b,h		:LD B,H
  defb $45		:ld b,l		:ld b,l		:LD B,L
  defb $46 		:ld b,[hl]	:ld b,[hl]	:LD B,(HL)
  defb $47		:ld b,a		:ld b,a		:LD B,A

  defb $48		:ld c,b		:ld c,b		:LD C,B
  defb $49		:ld c,c		:ld c,c		:LD C,C
  defb $4A		:ld c,d		:ld c,d		:LD C,D
  defb $4B		:ld c,e		:ld c,e		:LD C,E
  defb $4C		:ld c,h		:ld c,h		:LD C,H
  defb $4D		:ld c,l		:ld c,l		:LD C,L
  defb $4E 		:ld c,[hl]	:ld c,[hl]	:LD C,(HL)
  defb $4F		:ld c,a		:ld c,a		:LD C,A

  defb $50		:ld d,b		:ld d,b		:LD D,B
  defb $51		:ld d,c		:ld d,c		:LD D,C
  defb $52		:ld d,d		:ld d,d		:LD D,D
  defb $53		:ld d,e		:ld d,e		:LD D,E
  defb $54		:ld d,h		:ld d,h		:LD D,H
  defb $55		:ld d,l		:ld d,l		:LD D,L
  defb $56 		:ld d,[hl]	:ld d,[hl]	:LD D,(HL)
  defb $57		:ld d,a		:ld d,a		:LD D,A

  defb $58		:ld e,b		:ld e,b		:LD E,B
  defb $59		:ld e,c		:ld e,c		:LD E,C
  defb $5A		:ld e,d		:ld e,d		:LD E,D
  defb $5B		:ld e,e		:ld e,e		:LD E,E
  defb $5C		:ld e,h		:ld e,h		:LD E,H
  defb $5D		:ld e,l		:ld e,l		:LD E,L
  defb $5E 		:ld e,[hl]	:ld e,[hl]	:LD E,(HL)
  defb $5F		:ld e,a		:ld e,a		:LD E,A

  defb $60		:ld h,b		:ld h,b		:LD H,B
  defb $61		:ld h,c		:ld h,c		:LD H,C
  defb $62		:ld h,d		:ld h,d		:LD H,D
  defb $63		:ld h,e		:ld h,e		:LD H,E
  defb $64		:ld h,h		:ld h,h		:LD H,H
  defb $65		:ld h,l		:ld h,l		:LD H,L
  defb $66 		:ld h,[hl]	:ld h,[hl]	:LD H,(HL)
  defb $67		:ld h,a		:ld h,a		:LD H,A

  defb $68		:ld l,b		:ld l,b		:LD L,B
  defb $69		:ld l,c		:ld l,c		:LD L,C
  defb $6A		:ld l,d		:ld l,d		:LD L,D
  defb $6B		:ld l,e		:ld l,e		:LD L,E
  defb $6C		:ld l,h		:ld l,h		:LD L,H
  defb $6D		:ld l,l		:ld l,l		:LD L,L
  defb $6E		:ld l,[hl]	:ld l,[hl]	:LD L,(HL)
  defb $6F		:ld l,a		:ld l,a		:LD L,A

  defb $70		:ld [hl],b	:ld [hl],b	:LD (HL),B
  defb $71		:ld [hl],c	:ld [hl],c	:LD (HL),C
  defb $72		:ld [hl],d	:ld [hl],d	:LD (HL),D
  defb $73		:ld [hl],e	:ld [hl],e	:LD (HL),E
  defb $74		:ld [hl],h	:ld [hl],h	:LD (HL),H
  defb $75		:ld [hl],l	:ld [hl],l	:LD (HL),L
  defb $76		:halt		:halt		:HALT
  defb $77		:ld [hl],a	:ld [hl],a	:LD (HL),A

  defb $78		:ld a,b		:ld a,b		:LD A,B
  defb $79		:ld a,c		:ld a,c		:LD A,C
  defb $7A		:ld a,d		:ld a,d		:LD A,D
  defb $7B		:ld a,e		:ld a,e		:LD A,E
  defb $7C		:ld a,h		:ld a,h		:LD A,H
  defb $7D		:ld a,l		:ld a,l		:LD A,L
  defb $7E 		:ld a,[hl]	:ld a,[hl]	:LD A,(HL)
  defb $7F		:ld a,a		:ld a,a		:LD A,A

  defb $0A 		:ld a,[bc]	:ld a,[bc]	:LD A,(BC)
  defb $1A 		:ld a,[de]	:ld a,[de]	:LD A,(DE)

  defb $02		:ld [bc],a	:ld [bc],a	:LD (BC),A
  defb $12		:ld [de],a	:ld [de],a	:LD (DE),A

  defb $F0,0		:ld a,[$FF00]	:ldh a,[$FF00] 	:LDH A,(n) : LD A,($FF00+n)
  defb $E0,0		:ld [$FF00],a	:ldh [$FF00],a	:LDH (n),A : LD ($FF00+n),A
  ; syntax "ld a,($ff00+c)" is not accepted by sjasmplus, only "(c)" argument works: 2x error
  defb $F2		:ld a,[c]	:ld a,[$ff00+c]	:LD A,(C) : LD A,($FF00+C)
  ; syntax "ld ($ff00+c),a" is not accepted by sjasmplus, only "(c)" argument works: 2x error
  defb $E2		:ld [c], a	:ld [$ff00+c],a	:ld (C),A : LD ($FF00+C),A

  defb $FA,0,0		:ld a,[0]	:ld a,[$0000]	:LD A,(nn)
  defb $EA,0,0		:ld [0],a	:ld [$0000],a	:LD (nn),A

  ; syntax with HLI and HLD is not accepted by sjasmplus: 4x error
  defb $22		:ldi [hl],a	:ldi [hl],a	:LD (HLI),A : LDI (HL),A : LD (HL+),A
  defb $32		:ldd [hl],a	:ldd [hl],a	:LD (HLD),A : LDD (HL),A : LD (HL-),A
  defb $2A		:ldi a,[hl]	:ldi a,[hl]	:LD A,(HLI) : LDI A,(HL) : LD A,(HL+)
  defb $3A		:ldd a,[hl]	:ldd a,[hl]	:LD A,(HLD) : LDD A,(HL) : LD A,(HL-)

  defb $01,0,0		:ld bc,0	:ld bc,$0000	:LD BC,nn
  defb $11,0,0		:ld de,0	:ld de,$0000	:LD DE,nn
  defb $21,0,0		:ld hl,0	:ld hl,$0000	:LD HL,nn
  defb $31,0,0		:ld sp,0	:ld sp,$0000	:LD SP,nn

  defb $F9		:ld sp,hl	:ld sp,hl	:LD SP,HL

  ; syntax "ld hl,[sp+$00]" and "LDHL" is not accepted by sjasmplus: 2x error
  defb $F8,0		:ld hl,sp+0	:ld hl,[sp+$00]	:LD HL,SP+n : LDHL SP,n

  defb $08,0,0		:ld [0],sp	:ld [$0000],sp	:LD (nn),SP

  defb $F5		:push af	:push af	:PUSH AF
  defb $C5		:push bc	:push bc	:PUSH BC
  defb $D5		:push de	:push de	:PUSH DE
  defb $E5		:push hl	:push hl	:PUSH HL

  defb $F1		:pop af		:pop af		:POP AF
  defb $C1		:pop bc		:pop bc		:POP BC
  defb $D1		:pop de		:pop de		:POP DE
  defb $E1		:pop hl		:pop hl		:POP HL

  defb $80		:add a,b	:add b		:ADD A,B
  defb $81		:add a,c	:add c		:ADD A,C
  defb $82		:add a,d	:add d		:ADD A,D
  defb $83		:add a,e	:add e		:ADD A,E
  defb $84		:add a,h	:add h		:ADD A,H
  defb $85		:add a,l	:add l		:ADD A,L
  defb $86		:add a,[hl]	:add [hl]	:ADD A,(HL)
  defb $87		:add a,a	:add a		:ADD A,A

  defb $88		:adc a,b	:adc b		:ADC A,B
  defb $89		:adc a,c	:adc c		:ADC A,C
  defb $8A		:adc a,d	:adc d		:ADC A,D
  defb $8B		:adc a,e	:adc e		:ADC A,E
  defb $8C		:adc a,h	:adc h		:ADC A,H
  defb $8D		:adc a,l	:adc l		:ADC A,L
  defb $8E		:adc a,[hl]	:adc [hl]	:ADC A,(HL)
  defb $8F		:adc a,a	:adc a		:ADC A,A

  defb $90		:sub b		:sub b		:SUB B
  defb $91		:sub c		:sub c		:SUB C
  defb $92		:sub d		:sub d		:SUB D
  defb $93		:sub e		:sub e		:SUB E
  defb $94		:sub h		:sub h		:SUB H
  defb $95		:sub l		:sub l		:SUB L
  defb $96		:sub [hl]	:sub [hl]	:SUB (HL)
  defb $97		:sub a		:sub a		:SUB A

  defb $98		:sbc a,b	:sbc b		:SBC A,B
  defb $99		:sbc a,c	:sbc c		:SBC A,C
  defb $9A		:sbc a,d	:sbc d		:SBC A,D
  defb $9B		:sbc a,e	:sbc e		:SBC A,E
  defb $9C		:sbc a,h	:sbc h		:SBC A,H
  defb $9D		:sbc a,l	:sbc l		:SBC A,L
  defb $9E		:sbc a,[hl]	:sbc [hl]	:SBC A,(HL)
  defb $9F		:sbc a,a	:sbc a		:SBC A,A

  defb $A0		:and b		:and b		:AND B
  defb $A1		:and c		:and c		:AND C
  defb $A2		:and d		:and d		:AND D
  defb $A3		:and e		:and e		:AND E
  defb $A4		:and h		:and h		:AND H
  defb $A5		:and l		:and l		:AND L
  defb $A6		:and [hl]	:and [hl]	:AND (HL)
  defb $A7		:and a		:and a		:AND A

  defb $B0		:or b		:or b		:OR B
  defb $B1		:or c		:or c		:OR C
  defb $B2		:or d		:or d		:OR D
  defb $B3		:or e		:or e		:OR E
  defb $B4		:or h		:or h		:OR H
  defb $B5		:or l		:or l		:OR L
  defb $B6		:or [hl]	:or [hl]	:OR (HL)
  defb $B7		:or a		:or a		:OR A

  defb $A8		:xor b		:xor b		:XOR B
  defb $A9		:xor c		:xor c		:XOR C
  defb $AA		:xor d		:xor d		:XOR D
  defb $AB		:xor e		:xor e		:XOR E
  defb $AC		:xor h		:xor h		:XOR H
  defb $AD		:xor l		:xor l		:XOR L
  defb $AE		:xor [hl]	:xor [hl]	:XOR (HL)
  defb $AF		:xor a		:xor a		:XOR A

  defb $B8		:cp b		:cp b		:CP B
  defb $B9		:cp c		:cp c		:CP C
  defb $BA		:cp d		:cp d		:CP D
  defb $BB		:cp e		:cp e		:CP E
  defb $BC		:cp h		:cp h		:CP H
  defb $BD		:cp l		:cp l		:CP L
  defb $BE		:cp [hl]	:cp [hl]	:CP (HL)
  defb $BF		:cp a		:cp a		:CP A

  defb $04		:inc b		:inc b		:INC B
  defb $0C		:inc c		:inc c		:INC C
  defb $14		:inc d		:inc d		:INC D
  defb $1C		:inc e		:inc e		:INC E
  defb $24		:inc h		:inc h		:INC H
  defb $2C		:inc l		:inc l		:INC L
  defb $34		:inc [hl]	:inc [hl]	:INC (HL)
  defb $3C		:inc a		:inc a		:INC A

  defb $05		:dec b		:dec b		:DEC B
  defb $0D		:dec c		:dec c		:DEC C
  defb $15		:dec d		:dec d		:DEC D
  defb $1D		:dec e		:dec e		:DEC E
  defb $25		:dec h		:dec h		:DEC H
  defb $2D		:dec l		:dec l		:DEC L
  defb $35		:dec [hl]	:dec [hl]	:DEC (HL)
  defb $3D		:dec a		:dec a		:DEC A

  ; the sub/and/xor/or/cp needs "--syntax=a" in sjasmplus for "a," recognition like this
  ; by default the sjasmplus understands "a," as multi-arg: "sub a,0" = "sub a : sub 0" (!)
  defb $C6,0		:add a,0	:add a,$00	:ADD A,n
  defb $CE,0		:adc a,0	:adc a,$00	:ADC A,n
  defb $D6,0		:sub 0		:sub a,$00	:SUB n         ; "sub a,*" needs `--syntax=a` in sjasmplus
  defb $DE,0		:sbc a,0	:sbc a,$00	:SBC A,n
  defb $E6,0		:and 0		:and a,$00	:AND n         ; "and a,*" needs `--syntax=a` in sjasmplus
  defb $EE,0		:xor 0		:xor a,$00	:XOR n         ; "xor a,*" needs `--syntax=a` in sjasmplus
  defb $F6,0		:or 0		:or a,$00	:OR n          ; "or a,*" needs `--syntax=a` in sjasmplus
  defb $FE,0		:cp 0		:cp a,$00	:CP n          ; "cp a,*" needs `--syntax=a` in sjasmplus

  defb $09		:add hl,bc	:add hl,bc	:ADD HL,BC
  defb $19		:add hl,de	:add hl,de	:ADD HL,DE
  defb $29		:add hl,hl	:add hl,hl	:ADD HL,HL
  defb $39		:add hl,sp	:add hl,sp	:ADD HL,SP

  defb $E8,0		:add sp,0	:add sp,$00	:ADD SP,n

  defb $03		:inc bc		:inc bc		:INC BC
  defb $13		:inc de		:inc de		:INC DE
  defb $23		:inc hl		:inc hl		:INC HL
  defb $33		:inc sp		:inc sp		:INC SP

  defb $0B		:dec bc		:dec bc		:DEC BC
  defb $1B		:dec de		:dec de		:DEC DE
  defb $2B		:dec hl		:dec hl		:DEC HL
  defb $3B		:dec sp		:dec sp		:DEC SP

  defb $CB,$30		:swap b		:swap b		:SWAP B
  defb $CB,$31		:swap c		:swap c		:SWAP C
  defb $CB,$32		:swap d		:swap d		:SWAP D
  defb $CB,$33		:swap e		:swap e		:SWAP E
  defb $CB,$34		:swap h		:swap h		:SWAP H
  defb $CB,$35		:swap l		:swap l		:SWAP L
  defb $CB,$36		:swap [hl]	:swap [hl]	:SWAP (HL)
  defb $CB,$37		:swap a		:swap a		:SWAP A

  defb $27 		:daa		:daa		:DAA
  defb $2F		:cpl		:cpl		:CPL
  defb $3F		:ccf		:ccf		:CCF
  defb $37 		:scf		:scf		:SCF

  defb $00		:nop		:nop		:NOP

  defb $10,$00		:stop		:stop		:STOP
  defb $F3		:di		:di		:DI
  defb $FB		:ei		:ei		:EI

  defb $07		:rlca		:rlca 		:RLCA
  defb $17		:rla		:rla  		:RLA
  defb $0F		:rrca		:rrca 		:RRCA
  defb $1F		:rra		:rra  		:RRA

  defb $CB,$00		:rlc b		:rlc b		:RLC B
  defb $CB,$01		:rlc c		:rlc c		:RLC C
  defb $CB,$02		:rlc d		:rlc d		:RLC D
  defb $CB,$03		:rlc e		:rlc e		:RLC E
  defb $CB,$04		:rlc h		:rlc h		:RLC H
  defb $CB,$05		:rlc l		:rlc l		:RLC L
  defb $CB,$06		:rlc [hl]	:rlc [hl]	:RLC (HL)
  defb $CB,$07		:rlc a		:rlc a		:RLC A

  defb $CB,$10		:rl b		:rl b		:RL B
  defb $CB,$11		:rl c		:rl c		:RL C
  defb $CB,$12		:rl d		:rl d		:RL D
  defb $CB,$13		:rl e		:rl e		:RL E
  defb $CB,$14		:rl h		:rl h		:RL H
  defb $CB,$15		:rl l		:rl l		:RL L
  defb $CB,$16		:rl [hl]	:rl [hl]	:RL (HL)
  defb $CB,$17		:rl a		:rl a		:RL A

  defb $CB,$08		:rrc b		:rrc b		:RRC B
  defb $CB,$09		:rrc c		:rrc c		:RRC C
  defb $CB,$0A		:rrc d		:rrc d		:RRC D
  defb $CB,$0B		:rrc e		:rrc e		:RRC E
  defb $CB,$0C		:rrc h		:rrc h		:RRC H
  defb $CB,$0D		:rrc l		:rrc l		:RRC L
  defb $CB,$0E		:rrc [hl]	:rrc [hl]	:RRC (HL)
  defb $CB,$0F		:rrc a		:rrc a		:RRC A

  defb $CB,$18		:rr b		:rr b		:RR B
  defb $CB,$19		:rr c		:rr c		:RR C
  defb $CB,$1A		:rr d		:rr d		:RR D
  defb $CB,$1B		:rr e		:rr e		:RR E
  defb $CB,$1C		:rr h		:rr h		:RR H
  defb $CB,$1D		:rr l		:rr l		:RR L
  defb $CB,$1E		:rr [hl]	:rr [hl]	:RR (HL)
  defb $CB,$1F		:rr a		:rr a		:RR A

  defb $CB,$20		:sla b		:sla b		:SLA B
  defb $CB,$21		:sla c		:sla c		:SLA C
  defb $CB,$22		:sla d		:sla d		:SLA D
  defb $CB,$23		:sla e		:sla e		:SLA E
  defb $CB,$24		:sla h		:sla h		:SLA H
  defb $CB,$25		:sla l		:sla l		:SLA L
  defb $CB,$26		:sla [hl]	:sla [hl]	:SLA (HL)
  defb $CB,$27		:sla a		:sla a		:SLA A

  defb $CB,$28		:sra b		:sra b		:SRA B
  defb $CB,$29		:sra c		:sra c		:SRA C
  defb $CB,$2A		:sra d		:sra d		:SRA D
  defb $CB,$2B		:sra e		:sra e		:SRA E
  defb $CB,$2C		:sra h		:sra h		:SRA H
  defb $CB,$2D		:sra l		:sra l		:SRA L
  defb $CB,$2E		:sra [hl]	:sra [hl]	:SRA (HL)
  defb $CB,$2F		:sra a		:sra a		:SRA A

  defb $CB,$38		:srl b		:srl b		:SRL B
  defb $CB,$39		:srl c		:srl c		:SRL C
  defb $CB,$3A		:srl d		:srl d		:SRL D
  defb $CB,$3B		:srl e		:srl e		:SRL E
  defb $CB,$3C		:srl h		:srl h		:SRL H
  defb $CB,$3D		:srl l		:srl l		:SRL L
  defb $CB,$3E		:srl [hl]	:srl [hl]	:SRL (HL)
  defb $CB,$3F		:srl a		:srl a		:SRL A

  defb $CB,$40		:bit 0,b	:bit 0,b	:BIT 0,B
  defb $CB,$41		:bit 0,c	:bit 0,c	:BIT 0,C
  defb $CB,$42		:bit 0,d	:bit 0,d	:BIT 0,D
  defb $CB,$43		:bit 0,e	:bit 0,e	:BIT 0,E
  defb $CB,$44		:bit 0,h	:bit 0,h	:BIT 0,H
  defb $CB,$45		:bit 0,l	:bit 0,l	:BIT 0,L
  defb $CB,$46		:bit 0,[hl]	:bit 0,[hl]	:BIT 0,(HL)
  defb $CB,$47		:bit 0,a	:bit 0,a	:BIT 0,A

  defb $CB,$40+$08	:bit 1,b	:bit 1,b	:BIT 1,B
  defb $CB,$41+$08	:bit 1,c	:bit 1,c	:BIT 1,C
  defb $CB,$42+$08	:bit 1,d	:bit 1,d	:BIT 1,D
  defb $CB,$43+$08	:bit 1,e	:bit 1,e	:BIT 1,E
  defb $CB,$44+$08	:bit 1,h	:bit 1,h	:BIT 1,H
  defb $CB,$45+$08	:bit 1,l	:bit 1,l	:BIT 1,L
  defb $CB,$46+$08	:bit 1,[hl]	:bit 1,[hl]	:BIT 1,(HL)
  defb $CB,$47+$08	:bit 1,a	:bit 1,a	:BIT 1,A

  defb $CB,$40+$10	:bit 2,b	:bit 2,b	:BIT 2,B
  defb $CB,$41+$10	:bit 2,c	:bit 2,c	:BIT 2,C
  defb $CB,$42+$10	:bit 2,d	:bit 2,d	:BIT 2,D
  defb $CB,$43+$10	:bit 2,e	:bit 2,e	:BIT 2,E
  defb $CB,$44+$10	:bit 2,h	:bit 2,h	:BIT 2,H
  defb $CB,$45+$10	:bit 2,l	:bit 2,l	:BIT 2,L
  defb $CB,$46+$10	:bit 2,[hl]	:bit 2,[hl]	:BIT 2,(HL)
  defb $CB,$47+$10	:bit 2,a	:bit 2,a	:BIT 2,A

  defb $CB,$40+$18	:bit 3,b	:bit 3,b	:BIT 3,B
  defb $CB,$41+$18	:bit 3,c	:bit 3,c	:BIT 3,C
  defb $CB,$42+$18	:bit 3,d	:bit 3,d	:BIT 3,D
  defb $CB,$43+$18	:bit 3,e	:bit 3,e	:BIT 3,E
  defb $CB,$44+$18	:bit 3,h	:bit 3,h	:BIT 3,H
  defb $CB,$45+$18	:bit 3,l	:bit 3,l	:BIT 3,L
  defb $CB,$46+$18	:bit 3,[hl]	:bit 3,[hl]	:BIT 3,(HL)
  defb $CB,$47+$18	:bit 3,a	:bit 3,a	:BIT 3,A

  defb $CB,$40+$20	:bit 4,b	:bit 4,b	:BIT 4,B
  defb $CB,$41+$20	:bit 4,c	:bit 4,c	:BIT 4,C
  defb $CB,$42+$20	:bit 4,d	:bit 4,d	:BIT 4,D
  defb $CB,$43+$20	:bit 4,e	:bit 4,e	:BIT 4,E
  defb $CB,$44+$20	:bit 4,h	:bit 4,h	:BIT 4,H
  defb $CB,$45+$20	:bit 4,l	:bit 4,l	:BIT 4,L
  defb $CB,$46+$20	:bit 4,[hl]	:bit 4,[hl]	:BIT 4,(HL)
  defb $CB,$47+$20	:bit 4,a	:bit 4,a	:BIT 4,A

  defb $CB,$40+$28	:bit 5,b	:bit 5,b	:BIT 5,B
  defb $CB,$41+$28	:bit 5,c	:bit 5,c	:BIT 5,C
  defb $CB,$42+$28	:bit 5,d	:bit 5,d	:BIT 5,D
  defb $CB,$43+$28	:bit 5,e	:bit 5,e	:BIT 5,E
  defb $CB,$44+$28	:bit 5,h	:bit 5,h	:BIT 5,H
  defb $CB,$45+$28	:bit 5,l	:bit 5,l	:BIT 5,L
  defb $CB,$46+$28	:bit 5,[hl]	:bit 5,[hl]	:BIT 5,(HL)
  defb $CB,$47+$28	:bit 5,a	:bit 5,a	:BIT 5,A

  defb $CB,$40+$30	:bit 6,b	:bit 6,b	:BIT 6,B
  defb $CB,$41+$30	:bit 6,c	:bit 6,c	:BIT 6,C
  defb $CB,$42+$30	:bit 6,d	:bit 6,d	:BIT 6,D
  defb $CB,$43+$30	:bit 6,e	:bit 6,e	:BIT 6,E
  defb $CB,$44+$30	:bit 6,h	:bit 6,h	:BIT 6,H
  defb $CB,$45+$30	:bit 6,l	:bit 6,l	:BIT 6,L
  defb $CB,$46+$30	:bit 6,[hl]	:bit 6,[hl]	:BIT 6,(HL)
  defb $CB,$47+$30	:bit 6,a	:bit 6,a	:BIT 6,A

  defb $CB,$40+$38	:bit 7,b	:bit 7,b	:BIT 7,B
  defb $CB,$41+$38	:bit 7,c	:bit 7,c	:BIT 7,C
  defb $CB,$42+$38	:bit 7,d	:bit 7,d	:BIT 7,D
  defb $CB,$43+$38	:bit 7,e	:bit 7,e	:BIT 7,E
  defb $CB,$44+$38	:bit 7,h	:bit 7,h	:BIT 7,H
  defb $CB,$45+$38	:bit 7,l	:bit 7,l	:BIT 7,L
  defb $CB,$46+$38	:bit 7,[hl]	:bit 7,[hl]	:BIT 7,(HL)
  defb $CB,$47+$38	:bit 7,a	:bit 7,a	:BIT 7,A

  defb $CB,$C0		:set 0,b	:set 0,b	:SET 0,B
  defb $CB,$C1		:set 0,c	:set 0,c	:SET 0,C
  defb $CB,$C2		:set 0,d	:set 0,d	:SET 0,D
  defb $CB,$C3		:set 0,e	:set 0,e	:SET 0,E
  defb $CB,$C4		:set 0,h	:set 0,h	:SET 0,H
  defb $CB,$C5		:set 0,l	:set 0,l	:SET 0,L
  defb $CB,$C6		:set 0,[hl]	:set 0,[hl]	:SET 0,(HL)
  defb $CB,$C7		:set 0,a	:set 0,a	:SET 0,A

  defb $CB,$C0+$08	:set 1,b	:set 1,b	:SET 1,B
  defb $CB,$C1+$08	:set 1,c	:set 1,c	:SET 1,C
  defb $CB,$C2+$08	:set 1,d	:set 1,d	:SET 1,D
  defb $CB,$C3+$08	:set 1,e	:set 1,e	:SET 1,E
  defb $CB,$C4+$08	:set 1,h	:set 1,h	:SET 1,H
  defb $CB,$C5+$08	:set 1,l	:set 1,l	:SET 1,L
  defb $CB,$C6+$08	:set 1,[hl]	:set 1,[hl]	:SET 1,(HL)
  defb $CB,$C7+$08	:set 1,a	:set 1,a	:SET 1,A

  defb $CB,$C0+$10	:set 2,b	:set 2,b	:SET 2,B
  defb $CB,$C1+$10	:set 2,c	:set 2,c	:SET 2,C
  defb $CB,$C2+$10	:set 2,d	:set 2,d	:SET 2,D
  defb $CB,$C3+$10	:set 2,e	:set 2,e	:SET 2,E
  defb $CB,$C4+$10	:set 2,h	:set 2,h	:SET 2,H
  defb $CB,$C5+$10	:set 2,l	:set 2,l	:SET 2,L
  defb $CB,$C6+$10	:set 2,[hl]	:set 2,[hl]	:SET 2,(HL)
  defb $CB,$C7+$10	:set 2,a	:set 2,a	:SET 2,A

  defb $CB,$C0+$18	:set 3,b	:set 3,b	:SET 3,B
  defb $CB,$C1+$18	:set 3,c	:set 3,c	:SET 3,C
  defb $CB,$C2+$18	:set 3,d	:set 3,d	:SET 3,D
  defb $CB,$C3+$18	:set 3,e	:set 3,e	:SET 3,E
  defb $CB,$C4+$18	:set 3,h	:set 3,h	:SET 3,H
  defb $CB,$C5+$18	:set 3,l	:set 3,l	:SET 3,L
  defb $CB,$C6+$18	:set 3,[hl]	:set 3,[hl]	:SET 3,(HL)
  defb $CB,$C7+$18	:set 3,a	:set 3,a	:SET 3,A

  defb $CB,$C0+$20	:set 4,b	:set 4,b	:SET 4,B
  defb $CB,$C1+$20	:set 4,c	:set 4,c	:SET 4,C
  defb $CB,$C2+$20	:set 4,d	:set 4,d	:SET 4,D
  defb $CB,$C3+$20	:set 4,e	:set 4,e	:SET 4,E
  defb $CB,$C4+$20	:set 4,h	:set 4,h	:SET 4,H
  defb $CB,$C5+$20	:set 4,l	:set 4,l	:SET 4,L
  defb $CB,$C6+$20	:set 4,[hl]	:set 4,[hl]	:SET 4,(HL)
  defb $CB,$C7+$20	:set 4,a	:set 4,a	:SET 4,A

  defb $CB,$C0+$28	:set 5,b	:set 5,b	:SET 5,B
  defb $CB,$C1+$28	:set 5,c	:set 5,c	:SET 5,C
  defb $CB,$C2+$28	:set 5,d	:set 5,d	:SET 5,D
  defb $CB,$C3+$28	:set 5,e	:set 5,e	:SET 5,E
  defb $CB,$C4+$28	:set 5,h	:set 5,h	:SET 5,H
  defb $CB,$C5+$28	:set 5,l	:set 5,l	:SET 5,L
  defb $CB,$C6+$28	:set 5,[hl]	:set 5,[hl]	:SET 5,(HL)
  defb $CB,$C7+$28	:set 5,a	:set 5,a	:SET 5,A

  defb $CB,$C0+$30	:set 6,b	:set 6,b	:SET 6,B
  defb $CB,$C1+$30	:set 6,c	:set 6,c	:SET 6,C
  defb $CB,$C2+$30	:set 6,d	:set 6,d	:SET 6,D
  defb $CB,$C3+$30	:set 6,e	:set 6,e	:SET 6,E
  defb $CB,$C4+$30	:set 6,h	:set 6,h	:SET 6,H
  defb $CB,$C5+$30	:set 6,l	:set 6,l	:SET 6,L
  defb $CB,$C6+$30	:set 6,[hl]	:set 6,[hl]	:SET 6,(HL)
  defb $CB,$C7+$30	:set 6,a	:set 6,a	:SET 6,A

  defb $CB,$C0+$38	:set 7,b	:set 7,b	:SET 7,B
  defb $CB,$C1+$38	:set 7,c	:set 7,c	:SET 7,C
  defb $CB,$C2+$38	:set 7,d	:set 7,d	:SET 7,D
  defb $CB,$C3+$38	:set 7,e	:set 7,e	:SET 7,E
  defb $CB,$C4+$38	:set 7,h	:set 7,h	:SET 7,H
  defb $CB,$C5+$38	:set 7,l	:set 7,l	:SET 7,L
  defb $CB,$C6+$38	:set 7,[hl]	:set 7,[hl]	:SET 7,(HL)
  defb $CB,$C7+$38	:set 7,a	:set 7,a	:SET 7,A

  defb $CB,$80		:res 0,b	:res 0,b	:RES 0,B
  defb $CB,$81		:res 0,c	:res 0,c	:RES 0,C
  defb $CB,$82		:res 0,d	:res 0,d	:RES 0,D
  defb $CB,$83		:res 0,e	:res 0,e	:RES 0,E
  defb $CB,$84		:res 0,h	:res 0,h	:RES 0,H
  defb $CB,$85		:res 0,l	:res 0,l	:RES 0,L
  defb $CB,$86		:res 0,[hl]	:res 0,[hl]	:RES 0,(HL)
  defb $CB,$87		:res 0,a	:res 0,a	:RES 0,A

  defb $CB,$80+$08	:res 1,b	:res 1,b	:RES 1,B
  defb $CB,$81+$08	:res 1,c	:res 1,c	:RES 1,C
  defb $CB,$82+$08	:res 1,d	:res 1,d	:RES 1,D
  defb $CB,$83+$08	:res 1,e	:res 1,e	:RES 1,E
  defb $CB,$84+$08	:res 1,h	:res 1,h	:RES 1,H
  defb $CB,$85+$08	:res 1,l	:res 1,l	:RES 1,L
  defb $CB,$86+$08	:res 1,[hl]	:res 1,[hl]	:RES 1,(HL)
  defb $CB,$87+$08	:res 1,a	:res 1,a	:RES 1,A

  defb $CB,$80+$10	:res 2,b	:res 2,b	:RES 2,B
  defb $CB,$81+$10	:res 2,c	:res 2,c	:RES 2,C
  defb $CB,$82+$10	:res 2,d	:res 2,d	:RES 2,D
  defb $CB,$83+$10	:res 2,e	:res 2,e	:RES 2,E
  defb $CB,$84+$10	:res 2,h	:res 2,h	:RES 2,H
  defb $CB,$85+$10	:res 2,l	:res 2,l	:RES 2,L
  defb $CB,$86+$10	:res 2,[hl]	:res 2,[hl]	:RES 2,(HL)
  defb $CB,$87+$10	:res 2,a	:res 2,a	:RES 2,A

  defb $CB,$80+$18	:res 3,b	:res 3,b	:RES 3,B
  defb $CB,$81+$18	:res 3,c	:res 3,c	:RES 3,C
  defb $CB,$82+$18	:res 3,d	:res 3,d	:RES 3,D
  defb $CB,$83+$18	:res 3,e	:res 3,e	:RES 3,E
  defb $CB,$84+$18	:res 3,h	:res 3,h	:RES 3,H
  defb $CB,$85+$18	:res 3,l	:res 3,l	:RES 3,L
  defb $CB,$86+$18	:res 3,[hl]	:res 3,[hl]	:RES 3,(HL)
  defb $CB,$87+$18	:res 3,a	:res 3,a	:RES 3,A

  defb $CB,$80+$20	:res 4,b	:res 4,b	:RES 4,B
  defb $CB,$81+$20	:res 4,c	:res 4,c	:RES 4,C
  defb $CB,$82+$20	:res 4,d	:res 4,d	:RES 4,D
  defb $CB,$83+$20	:res 4,e	:res 4,e	:RES 4,E
  defb $CB,$84+$20	:res 4,h	:res 4,h	:RES 4,H
  defb $CB,$85+$20	:res 4,l	:res 4,l	:RES 4,L
  defb $CB,$86+$20	:res 4,[hl]	:res 4,[hl]	:RES 4,(HL)
  defb $CB,$87+$20	:res 4,a	:res 4,a	:RES 4,A

  defb $CB,$80+$28	:res 5,b	:res 5,b	:RES 5,B
  defb $CB,$81+$28	:res 5,c	:res 5,c	:RES 5,C
  defb $CB,$82+$28	:res 5,d	:res 5,d	:RES 5,D
  defb $CB,$83+$28	:res 5,e	:res 5,e	:RES 5,E
  defb $CB,$84+$28	:res 5,h	:res 5,h	:RES 5,H
  defb $CB,$85+$28	:res 5,l	:res 5,l	:RES 5,L
  defb $CB,$86+$28	:res 5,[hl]	:res 5,[hl]	:RES 5,(HL)
  defb $CB,$87+$28	:res 5,a	:res 5,a	:RES 5,A

  defb $CB,$80+$30	:res 6,b	:res 6,b	:RES 6,B
  defb $CB,$81+$30	:res 6,c	:res 6,c	:RES 6,C
  defb $CB,$82+$30	:res 6,d	:res 6,d	:RES 6,D
  defb $CB,$83+$30	:res 6,e	:res 6,e	:RES 6,E
  defb $CB,$84+$30	:res 6,h	:res 6,h	:RES 6,H
  defb $CB,$85+$30	:res 6,l	:res 6,l	:RES 6,L
  defb $CB,$86+$30	:res 6,[hl]	:res 6,[hl]	:RES 6,(HL)
  defb $CB,$87+$30	:res 6,a	:res 6,a	:RES 6,A

  defb $CB,$80+$38	:res 7,b	:res 7,b	:RES 7,B
  defb $CB,$81+$38	:res 7,c	:res 7,c	:RES 7,C
  defb $CB,$82+$38	:res 7,d	:res 7,d	:RES 7,D
  defb $CB,$83+$38	:res 7,e	:res 7,e	:RES 7,E
  defb $CB,$84+$38	:res 7,h	:res 7,h	:RES 7,H
  defb $CB,$85+$38	:res 7,l	:res 7,l	:RES 7,L
  defb $CB,$86+$38	:res 7,[hl]	:res 7,[hl]	:RES 7,(HL)
  defb $CB,$87+$38	:res 7,a	:res 7,a	:RES 7,A

  defb $C3,0,0		:jp 0		:jp $0000	:JP nn

  defb $C2,0,0		:jp nz,0	:jp nz,$0000	:JP NZ,nn
  defb $CA,0,0		:jp z,0		:jp z,$0000	:JP Z,nn
  defb $D2,0,0		:jp nc,0	:jp nc,$0000	:JP NC,nn
  defb $DA,0,0		:jp c,0		:jp c,$0000	:JP C,nn

  defb $E9		:jp [hl]	:jp [hl]	:JP (HL)

  defb $18,0		:jr $+2		:jr $+2		:JR $+2

  defb $20,0		:jr nz,$+2	:jr nz,$+2	:JR NZ,$+2  ; was literal "n", but needs "$+2" for tests
  defb $28,0		:jr z,$+2	:jr z,$+2	:JR Z,$+2
  defb $30,0		:jr nc,$+2	:jr nc,$+2	:JR NC,$+2
  defb $38,0		:jr c,$+2	:jr c,$+2	:JR C,$+2

  defb $CD,0,0		:call 0		:call $0000	:CALL nn

  defb $C4,0,0		:call nz,0	:call nz,$0000	:CALL NZ,nn
  defb $CC,0,0		:call z,0	:call z,$0000	:CALL Z,nn
  defb $D4,0,0		:call nc,0	:call nc,$0000	:CALL NC,nn
  defb $DC,0,0		:call c,0	:call c,$0000	:CALL C,nn

  defb $C7		:rst 0		:rst $00	:RST 00H
  defb $CF		:rst 8		:rst $08	:RST 08H
  defb $D7		:rst $10	:rst $10	:RST 10H
  defb $DF		:rst $18	:rst $18	:RST 18H
  defb $E7		:rst $20	:rst $20	:RST 20H
  defb $EF		:rst $28	:rst $28	:RST 28H
  defb $F7		:rst $30	:rst $30	:RST 30H
  defb $FF		:rst $38	:rst $38	:RST 38H

  defb $C9		:ret		:ret		:RET

  defb $C0		:ret nz		:ret nz		:RET NZ
  defb $C8		:ret z		:ret z		:RET Z
  defb $D0		:ret nc		:ret nc		:RET NC
  defb $D8		:ret c		:ret c		:RET C

  defb $D9		:reti		:reti		:RETI
