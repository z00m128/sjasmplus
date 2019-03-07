/*

  SjASMPlus Z80 Cross Compiler

  Copyright (c) 2004-2008 Aprisobal

  This software is provided 'as-is', without any express or implied warranty.
  In no event will the authors be held liable for any damages arising from the
  use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it freely,
  subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not claim
	 that you wrote the original software. If you use this software in a product,
	 an acknowledgment in the product documentation would be appreciated but is
	 not required.

  2. Altered source versions must be plainly marked as such, and must not be
	 misrepresented as being the original software.

  3. This notice may not be removed or altered from any source distribution.

*/

#include "sjdefs.h"

namespace Z80 {
	enum Z80Reg { Z80_B = 0, Z80_C, Z80_D, Z80_E, Z80_H, Z80_L, Z80_A = 7, Z80_I, Z80_R, Z80_F,
		Z80_BC = 0x10, Z80_DE = 0x20, Z80_HL = 0x30, Z80_IXH, Z80_IXL, Z80_IYH, Z80_IYL,
		Z80_SP = 0x40, Z80_AF = 0x50, Z80_IX = 0xdd, Z80_IY = 0xfd, Z80_UNK = -1 };
	enum Z80Cond {	// also used to calculate instruction opcode, so do not edit values
		Z80C_NZ = 0x00, Z80C_Z  = 0x08, Z80C_NC = 0x10, Z80C_C = 0x18,
		Z80C_PO = 0x20, Z80C_PE = 0x28, Z80C_P  = 0x30, Z80C_M = 0x38, Z80C_UNK };

#define ASSERT_FAKE_INSTRUCTIONS(operation) if (!Options::FakeInstructions) { \
		operation; \
	}
	//char* my_p = lp;
	//SkipBlanks(my_p);
	//Warning("Fake instructions is disabled. The instruction was not compiled", my_p, LASTPASS);

	CFunctionTable OpCodeTable;

	/*char *GetRegister(Z80Reg reg){
		switch (reg) {
			case Z80_B:
				return "BC"
		}
	}*/

	void GetOpCode() {
		char* n;
		bp = lp;
		if (!(n = getinstr(lp))) {
			if (*lp == '#' && *(lp + 1) == '#') {
				lp += 2;
				aint val;
				synerr = 0; if (!ParseExpression(lp, val)) {
								val = 4;
							} synerr = 1;
				AddressOfMAP += ((~AddressOfMAP + 1) & (val - 1));
				return;
			} else {
				Error("Unrecognized instruction", lp, LASTPASS); return;
			}
		}
		if (!OpCodeTable.zoek(n)) {
			Error("Unrecognized instruction", bp, LASTPASS); *lp = 0;
		}
	}

	int GetByte(char*& p) {
		aint val;
		if (!ParseExpression(p, val)) {
			Error("Operand expected", NULL, LASTPASS); return 0;
		}
		check8(val);
		return val & 255;
	}

	int GetWord(char*& p) {
		aint val;
		if (!ParseExpression(p, val)) {
			Error("Operand expected", NULL, LASTPASS); return 0;
		}
		check16(val);
		return val & 65535;
	}

	int z80GetIDxoffset(char*& p) {
		aint val;
		char* pp = p;
		SkipBlanks(pp);
		if (*pp == ')') {
			return 0;
		}
		if (*pp == ']') {
			return 0;
		}
		if (!ParseExpression(p, val)) {
			Error("Operand expected", NULL, LASTPASS); return 0;
		}
		check8o(val);
		return val & 255;
	}

	int GetAddress(char*& p, aint& ad) {
		if (GetLocalLabelValue(p, ad) || ParseExpression(p, ad)) return 1;
		Error("Operand expected", 0, CATCHALL);
		return (ad = 0);
	}

	Z80Cond getz80cond(char*& p) {
		SkipBlanks(p);
		char * const pp = p;
		if (0 == p[0]) return Z80C_UNK;	// EOL detected
		const char p0 = 0x20|p[0];		// lowercase ASCII conversion
		if (!islabchar(p[1])) {			// can be only single letter condition at most
			++p;
			switch (p0) {
				case 'z': return Z80C_Z;
				case 'c': return Z80C_C;
				case 'p': return Z80C_P;
				case 'm': return Z80C_M;
				case 's': return Z80C_M;
			}
			p = pp;
			return Z80C_UNK;
		}
		// ## p0 != 0 && p1 is label character
		if ((p[0]^p[1])&0x20) return Z80C_UNK;	// different case of the letters detected
		if (islabchar(p[2])) return Z80C_UNK;	// p2 is also label character = too many
		const char p1 = 0x20|p[1];		// lowercase ASCII conversion
		p += 2;
		if ('n' == p0) {
			switch (p1) {
				case 'z': return Z80C_NZ;	// nz
				case 'c': return Z80C_NC;	// nc
				case 's': return Z80C_P;	// ns
			}
		} else if ('p' == p0) {
			switch (p1) {
				case 'o': return Z80C_PO;	// po
				case 'e': return Z80C_PE;	// pe
			}
		}
		p = pp;
		return Z80C_UNK;
	}

	Z80Reg GetRegister(char*& p) {
		char* pp = p;
		SkipBlanks(p);
		if(memcmp(p, "high ", 5) == 0 || memcmp(p, "HIGH ", 5) == 0) {
			p += 5;
			switch(GetRegister(p)) {
				case Z80_AF : return Z80_A;
				case Z80_BC : return Z80_B;
				case Z80_DE : return Z80_D;
				case Z80_HL : return Z80_H;
				case Z80_IX : return Z80_IXH;
				case Z80_IY : return Z80_IYH;
				default : p -= 5; return Z80_UNK;
			}
		}
		if(memcmp(p, "low ", 4) == 0 || memcmp(p, "LOW ", 4) == 0) {
			p += 4;
				switch(GetRegister(p)) {
				case Z80_AF : return Z80_F;
				case Z80_BC : return Z80_C;
				case Z80_DE : return Z80_E;
				case Z80_HL : return Z80_L;
				case Z80_IX : return Z80_IXL;
				case Z80_IY : return Z80_IYL;
				default : p -= 4; return Z80_UNK;
			}
		}
		switch (*(p++)) {
		case 'a':
			if (!islabchar(*p)) {
				return Z80_A;
			}
			if (*p == 'f' && !islabchar(*(p + 1))) {
				++p;
				return Z80_AF;
			}
			break;
		case 'b':
			if (!islabchar(*p)) {
				return Z80_B;
			}
			if (*p == 'c' && !islabchar(*(p + 1))) {
				++p;
				return Z80_BC;
			}
			break;
		case 'c':
			if (!islabchar(*p)) {
				return Z80_C;
			}
			break;
		case 'd':
			if (!islabchar(*p)) {
				return Z80_D;
			}
			if (*p == 'e' && !islabchar(*(p + 1))) {
				++p;
				return Z80_DE;
			}
			break;
		case 'e':
			if (!islabchar(*p)) {
				return Z80_E;
			}
			break;
		case 'f':
			if (!islabchar(*p)) {
				return Z80_F;
			}
			break;
		case 'h':
			if (*p == 'x') {
				if (!islabchar(*(p + 1))) {
					++p;
					return Z80_IXH;
				}
			}
			if (*p == 'y') {
				if (!islabchar(*(p + 1))) {
					++p;
					return Z80_IYH;
				}
			}
			if (!islabchar(*p)) {
				return Z80_H;
			}
			if (*p == 'l' && !islabchar(*(p + 1))) {
				++p;
				return Z80_HL;
			}
			break;
		case 'i':
			if (*p == 'x') {
				if (!islabchar(*(p + 1))) {
					++p;
					return Z80_IX;
				}
				if (*(p + 1) == 'h' && !islabchar(*(p + 2))) {
					p += 2;
					return Z80_IXH;
				}
				if (*(p + 1) == 'l' && !islabchar(*(p + 2))) {
					p += 2;
					return Z80_IXL;
				}
			}
			if (*p == 'y') {
				if (!islabchar(*(p + 1))) {
					++p;
					return Z80_IY;
				}
				if (*(p + 1) == 'h' && !islabchar(*(p + 2))) {
					p += 2;
					return Z80_IYH;
				}
				if (*(p + 1) == 'l' && !islabchar(*(p + 2))) {
					p += 2;
					return Z80_IYL;
				}
			}
			if (!islabchar(*p)) {
				return Z80_I;
			}
			break;
		case 'y':
			if (*p == 'h') {
				if (!islabchar(*(p + 1))) {
					++p;
					return Z80_IYH;
				}
			}
			if (*p == 'l') {
				if (!islabchar(*(p + 1))) {
					++p;
					return Z80_IYL;
				}
			}
			break;
		case 'x':
			if (*p == 'h') {
				if (!islabchar(*(p + 1))) {
					++p;
					return Z80_IXH;
				}
			}
			if (*p == 'l') {
				if (!islabchar(*(p + 1))) {
					++p;
					return Z80_IXL;
				}
			}
			break;
		case 'l':
			if (*p == 'x') {
				if (!islabchar(*(p + 1))) {
					++p;
					return Z80_IXL;
				}
			}
			if (*p == 'y') {
				if (!islabchar(*(p + 1))) {
					++p;
					return Z80_IYL;
				}
			}
			if (!islabchar(*p)) {
				return Z80_L;
			}
			break;
		case 'r':
			if (!islabchar(*p)) {
				return Z80_R;
			}
			break;
		case 's':
			if (*p == 'p' && !islabchar(*(p + 1))) {
				++p;
				return Z80_SP;
			}
			break;
		case 'A':
			if (!islabchar(*p)) {
				return Z80_A;
			}
			if (*p == 'F' && !islabchar(*(p + 1))) {
				++p; return Z80_AF;
			}
			break;
		case 'B':
			if (!islabchar(*p)) {
				return Z80_B;
			}
			if (*p == 'C' && !islabchar(*(p + 1))) {
				++p; return Z80_BC;
			}
			break;
		case 'C':
			if (!islabchar(*p)) {
				return Z80_C;
			}
			break;
		case 'D':
			if (!islabchar(*p)) {
				return Z80_D;
			}
			if (*p == 'E' && !islabchar(*(p + 1))) {
				++p; return Z80_DE;
			}
			break;
		case 'E':
			if (!islabchar(*p)) {
				return Z80_E;
			}
			break;
		case 'F':
			if (!islabchar(*p)) {
				return Z80_F;
			}
			break;
		case 'H':
			if (*p == 'X') {
				if (!islabchar(*(p + 1))) {
					++p; return Z80_IXH;
				}
			}
			if (*p == 'Y') {
				if (!islabchar(*(p + 1))) {
					++p; return Z80_IYH;
				}
			}
			if (!islabchar(*p)) {
				return Z80_H;
			}
			if (*p == 'L' && !islabchar(*(p + 1))) {
				++p; return Z80_HL;
			}
			break;
		case 'I':
			if (*p == 'X') {
				if (!islabchar(*(p + 1))) {
					++p; return Z80_IX;
				}
				if (*(p + 1) == 'H' && !islabchar(*(p + 2))) {
					p += 2; return Z80_IXH;
				}
				if (*(p + 1) == 'L' && !islabchar(*(p + 2))) {
					p += 2; return Z80_IXL;
				}
			}
			if (*p == 'Y') {
				if (!islabchar(*(p + 1))) {
					++p; return Z80_IY;
				}
				if (*(p + 1) == 'H' && !islabchar(*(p + 2))) {
					p += 2; return Z80_IYH;
				}
				if (*(p + 1) == 'L' && !islabchar(*(p + 2))) {
					p += 2; return Z80_IYL;
				}
			}
			if (!islabchar(*p)) {
				return Z80_I;
			}
			break;
		case 'Y':
			if (*p == 'H') {
				if (!islabchar(*(p + 1))) {
					++p; return Z80_IYH;
				}
			}
			if (*p == 'L') {
				if (!islabchar(*(p + 1))) {
					++p; return Z80_IYL;
				}
			}
			break;
		case 'X':
			if (*p == 'H') {
				if (!islabchar(*(p + 1))) {
					++p; return Z80_IXH;
				}
			}
			if (*p == 'L') {
				if (!islabchar(*(p + 1))) {
					++p; return Z80_IXL;
				}
			}
			break;
		case 'L':
			if (*p == 'X') {
				if (!islabchar(*(p + 1))) {
					++p; return Z80_IXL;
				}
			}
			if (*p == 'Y') {
				if (!islabchar(*(p + 1))) {
					++p; return Z80_IYL;
				}
			}
			if (!islabchar(*p)) {
				return Z80_L;
			}
			break;
		case 'R':
			if (!islabchar(*p)) {
				return Z80_R;
			}
			break;
		case 'S':
			if (*p == 'P' && !islabchar(*(p + 1))) {
				++p; return Z80_SP;
			}
			break;
		default:
			break;
		}
		p = pp;
		return Z80_UNK;
	}

	void OpCode_ADC() {
		Z80Reg reg, reg2;
		EBracketType bt;
		do {
			int e[] = { -1, -1, -1, -1 };
			switch (reg = GetRegister(lp)) {
			case Z80_HL:
				if (!comma(lp)) {
					Error("[ADC] Comma expected", 0); break;
				}
				switch (reg2 = GetRegister(lp)) {
				case Z80_BC:	case Z80_DE:	case Z80_HL:	case Z80_SP:
					e[0] = 0xed; e[1] = 0x4a + reg2 - Z80_BC; break;
				default:
					;
				}
				break;
			case Z80_A:
				if (!comma(lp)) {
					e[0] = 0x8f; break;
				}
				reg = GetRegister(lp);
			default:
				switch (reg) {
				case Z80_IXH:
					e[0] = 0xdd; e[1] = 0x8c; break;
				case Z80_IXL:
					e[0] = 0xdd; e[1] = 0x8d; break;
				case Z80_IYH:
					e[0] = 0xfd; e[1] = 0x8c; break;
				case Z80_IYL:
					e[0] = 0xfd; e[1] = 0x8d; break;
				case Z80_B:
				case Z80_C:
				case Z80_D:
				case Z80_E:
				case Z80_H:
				case Z80_L:
				case Z80_A:
					e[0] = 0x88 + reg; break;
				case Z80_F:
				case Z80_I:
				case Z80_R:
				case Z80_AF:
				case Z80_BC:
				case Z80_DE:
				case Z80_HL:
				case Z80_SP:
				case Z80_IX:
				case Z80_IY:
					break;
				default:
					if (BT_NONE != (bt = OpenBracket(lp))) {
						switch (reg = GetRegister(lp)) {
						case Z80_HL:
							if (CloseBracket(lp)) e[0] = 0x8e;
							break;
						case Z80_IX:
						case Z80_IY:
							e[1] = 0x8e; e[2] = z80GetIDxoffset(lp);
							if (CloseBracket(lp)) e[0] = reg;
							break;
						default:
							break;
						}
						// give "(something..." another chance to parse as value expression
						if (Z80_UNK == reg && BT_ROUND == bt) --lp;
						else break;		//"(register" or other bracket: emit instruction || bug
					}
					e[0] = 0xce; e[1] = GetByte(lp);
					break;
				}
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_ADD() {
		Z80Reg reg, reg2;
		EBracketType bt;
		do {
			int e[] = { -1, -1, -1, -1, -1 };
			switch (reg = GetRegister(lp)) {
			case Z80_HL:
				if (!comma(lp)) {
					Error("[ADD] Comma expected", 0); break;
				}
				switch (reg2 = GetRegister(lp)) {
				case Z80_BC:	case Z80_DE:	case Z80_HL:	case Z80_SP:
					e[0] = 0x09 + reg2 - Z80_BC; break;
				case Z80_A:
					if(!Options::IsNextEnabled) break;
					e[0] = 0xED; e[1] = 0x31; break;
				default:
					if(!Options::IsNextEnabled) break;
					int b = GetWord(lp);
					e[0] = 0xED; e[1] = 0x34 ;
					e[2] = b & 255; e[3] = (b >> 8) & 255;
					break;
				}
				break;
			case Z80_DE:
			case Z80_BC:
				if (!Options::IsNextEnabled) break;   // DE|BC is valid first operand only for Z80N
				if (!comma(lp)) {
					Error("[ADD] Comma expected", 0); break;
				}
				if (Z80_A == GetRegister(lp)) {
					e[0] = 0xED; e[1] = 0x32 + (Z80_BC == reg);
				} else {
					int b = GetWord(lp);
					e[0] = 0xED; e[1] = 0x35 + (Z80_BC == reg);
					e[2] = b & 255; e[3] = (b >> 8) & 255;
				}
				break;
			case Z80_IX:
			case Z80_IY:
				if (!comma(lp)) {
					Error("[ADD] Comma expected", 0); break;
				}
				switch (reg2 = GetRegister(lp)) {
				case Z80_BC:	case Z80_DE:	case Z80_SP:
					e[0] = reg; e[1] = 0x09 + reg2 - Z80_BC; break;
				case Z80_IX:
				case Z80_IY:
					if (reg != reg2) break;
					e[0] = reg; e[1] = 0x29; break;
				default:
					break;
				}
				break;
			case Z80_A:
				if (!comma(lp)) {
					e[0] = 0x87; break;
				}
				reg = GetRegister(lp);
			default:
				switch (reg) {
				case Z80_IXH:
					e[0] = 0xdd; e[1] = 0x84; break;
				case Z80_IXL:
					e[0] = 0xdd; e[1] = 0x85; break;
				case Z80_IYH:
					e[0] = 0xfd; e[1] = 0x84; break;
				case Z80_IYL:
					e[0] = 0xfd; e[1] = 0x85; break;
				case Z80_B:
				case Z80_C:
				case Z80_D:
				case Z80_E:
				case Z80_H:
				case Z80_L:
				case Z80_A:
					e[0] = 0x80 + reg; break;
				case Z80_F:
				case Z80_I:
				case Z80_R:
				case Z80_AF:
				case Z80_BC:
				case Z80_DE:
				case Z80_HL:
				case Z80_SP:
				case Z80_IX:
				case Z80_IY:
					break;
				default:
					if (BT_NONE != (bt = OpenBracket(lp))) {
						switch (reg = GetRegister(lp)) {
						case Z80_HL:
							if (CloseBracket(lp)) e[0] = 0x86;
							break;
						case Z80_IX:
						case Z80_IY:
							e[1] = 0x86; e[2] = z80GetIDxoffset(lp);
							if (CloseBracket(lp)) e[0] = reg;
							break;
						default:
							break;
						}
						// give "(something..." another chance to parse as value expression
						if (Z80_UNK == reg && BT_ROUND == bt) --lp;
						else break;		//"(register" or other bracket: emit instruction || bug
					}
					e[0] = 0xc6; e[1] = GetByte(lp);
					break;
				}
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_AND() {
		Z80Reg reg;
		EBracketType bt;
		int e[4];
		do {
			e[0] = e[1] = e[2] = e[3] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_A:
				/*if (!comma(lp)) { e[0]=0xa7; break; }
							reg=GetRegister(lp);*/
				e[0] = 0xa7; break;
			default:
				switch (reg) {
				case Z80_IXH:
					e[0] = 0xdd; e[1] = 0xa4; break;
				case Z80_IXL:
					e[0] = 0xdd; e[1] = 0xa5; break;
				case Z80_IYH:
					e[0] = 0xfd; e[1] = 0xa4; break;
				case Z80_IYL:
					e[0] = 0xfd; e[1] = 0xa5; break;
				case Z80_B:
				case Z80_C:
				case Z80_D:
				case Z80_E:
				case Z80_H:
				case Z80_L:
				case Z80_A:
					e[0] = 0xa0 + reg; break;
				case Z80_F:
				case Z80_I:
				case Z80_R:
				case Z80_AF:
				case Z80_BC:
				case Z80_DE:
				case Z80_HL:
				case Z80_SP:
				case Z80_IX:
				case Z80_IY:
					break;
				default:
					if (BT_NONE != (bt = OpenBracket(lp))) {
						switch (reg = GetRegister(lp)) {
						case Z80_HL:
							if (CloseBracket(lp)) e[0] = 0xa6;
							break;
						case Z80_IX:
						case Z80_IY:
							e[1] = 0xa6; e[2] = z80GetIDxoffset(lp);
							if (CloseBracket(lp)) e[0] = reg;
							break;
						default:
							break;
						}
						// give "(something..." another chance to parse as value expression
						if (Z80_UNK == reg && BT_ROUND == bt) --lp;
						else break;		//"(register" or other bracket: emit instruction || bug
					}
					e[0] = 0xe6; e[1] = GetByte(lp);
					break;
				}
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_BIT() {
		Z80Reg reg;
		int e[5], bit;
		do {
			e[0] = e[1] = e[2] = e[3] = e[4] = -1;
			bit = GetByte(lp);
			if (!comma(lp)) {
				bit = -1;
			}
			switch (reg = GetRegister(lp)) {
			case Z80_B:
			case Z80_C:
			case Z80_D:
			case Z80_E:
			case Z80_H:
			case Z80_L:
			case Z80_A:
				e[0] = 0xcb; e[1] = 8 * bit + 0x40 + reg; break;
			default:
				if (!oparenOLD(lp, '[') && !oparenOLD(lp, '(')) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					if (cparenOLD(lp)) {
						e[0] = 0xcb;
					}
					e[1] = 8 * bit + 0x46; break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 8 * bit + 0x46;
					if (cparenOLD(lp)) {
						e[0] = reg;
					}
					break;
				default:
					;
				}
			}
			if (bit < 0 || bit > 7) {
				e[0] = -1;
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	// helper function for BRLC, BSLA, BSRA, BSRF, BSRL, as all need identical operand validation
	static void OpCode_Z80N_BarrelShifts(int mainOpcode) {
		int e[] = { -1, -1, -1 };
		// verify the operands are "de,b" (only valid ones)
		if (Z80_DE == GetRegister(lp) && comma(lp) && Z80_B == GetRegister(lp)) {
			e[0]=0xED;
			e[1]=mainOpcode;
		}
		EmitBytes(e);
	}

	void OpCode_Next_BRLC() {
		OpCode_Z80N_BarrelShifts(0x2C);
	}

	void OpCode_Next_BSLA() {
		OpCode_Z80N_BarrelShifts(0x28);
	}

	void OpCode_Next_BSRA() {
		OpCode_Z80N_BarrelShifts(0x29);
	}

	void OpCode_Next_BSRF() {
		OpCode_Z80N_BarrelShifts(0x2B);
	}

	void OpCode_Next_BSRL() {
		OpCode_Z80N_BarrelShifts(0x2A);
	}

	void OpCode_CALL() {
		do {
			int e[] = { -1, -1, -1, -1 };
			Z80Cond cc = getz80cond(lp);
			if (Z80C_UNK == cc) e[0] = 0xcd;
			else if (comma(lp)) e[0] = 0xC4 + cc;
			// UNK != cc + no-comma leaves e[0] == -1 (invalid instruction)
			aint callad;
			GetAddress(lp, callad);
			check16(callad);
			e[1] = callad & 255; e[2] = (callad >> 8) & 255;
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_CCF() {
		EmitByte(0x3f);
	}

	void OpCode_CP() {
		Z80Reg reg;
		EBracketType bt;
		int e[4];
		do {
			e[0] = e[1] = e[2] = e[3] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_A:
				/*if (!comma(lp)) { e[0]=0xbf; break; }
							reg=GetRegister(lp);*/
				e[0] = 0xbf; break;
			default:
				switch (reg) {
				case Z80_IXH:
					e[0] = 0xdd; e[1] = 0xbc; break;
				case Z80_IXL:
					e[0] = 0xdd; e[1] = 0xbd; break;
				case Z80_IYH:
					e[0] = 0xfd; e[1] = 0xbc; break;
				case Z80_IYL:
					e[0] = 0xfd; e[1] = 0xbd; break;
				case Z80_B:
				case Z80_C:
				case Z80_D:
				case Z80_E:
				case Z80_H:
				case Z80_L:
				case Z80_A:
					e[0] = 0xb8 + reg; break;
				case Z80_F:
				case Z80_I:
				case Z80_R:
				case Z80_AF:
				case Z80_BC:
				case Z80_DE:
				case Z80_HL:
				case Z80_SP:
				case Z80_IX:
				case Z80_IY:
					break;
				default:
					if (BT_NONE != (bt = OpenBracket(lp))) {
						switch (reg = GetRegister(lp)) {
						case Z80_HL:
							if (CloseBracket(lp)) e[0] = 0xbe;
							break;
						case Z80_IX:
						case Z80_IY:
							e[1] = 0xbe; e[2] = z80GetIDxoffset(lp);
							if (CloseBracket(lp)) e[0] = reg;
							break;
						default:
							break;
						}
						// give "(something..." another chance to parse as value expression
						if (Z80_UNK == reg && BT_ROUND == bt) --lp;
						else break;		//"(register" or other bracket: emit instruction || bug
					}
					e[0] = 0xfe; e[1] = GetByte(lp);
				}
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_CPD() {
		int e[3];
		e[0] = 0xed;
		e[1] = 0xa9;
		e[2] = -1;
		EmitBytes(e);
	}

	void OpCode_CPDR() {
		int e[3];
		e[0] = 0xed;
		e[1] = 0xb9;
		e[2] = -1;
		EmitBytes(e);
	}

	void OpCode_CPI() {
		int e[3];
		e[0] = 0xed;
		e[1] = 0xa1;
		e[2] = -1;
		EmitBytes(e);
	}

	void OpCode_CPIR() {
		int e[3];
		e[0] = 0xed;
		e[1] = 0xb1;
		e[2] = -1;
		EmitBytes(e);
	}

	void OpCode_CPL() {
		EmitByte(0x2f);
	}

	void OpCode_DAA() {
		EmitByte(0x27);
	}

	void OpCode_DEC() {
		do {
			Z80Reg reg;
			int e[] = { -1, -1, -1, -1 };
			switch (reg = GetRegister(lp)) {
			case Z80_B: case Z80_C: case Z80_D: case Z80_E: case Z80_H: case Z80_L: case Z80_A:
				e[0] = 0x05 + 8 * reg; break;
			case Z80_BC: case Z80_DE: case Z80_HL: case Z80_SP:
				e[0] = 0x0b + reg - Z80_BC; break;
			case Z80_IX: case Z80_IY:
				e[0] = reg; e[1] = 0x2b; break;
			case Z80_IXH:
				e[0] = 0xdd; e[1] = 0x25; break;
			case Z80_IXL:
				e[0] = 0xdd; e[1] = 0x2d; break;
			case Z80_IYH:
				e[0] = 0xfd; e[1] = 0x25; break;
			case Z80_IYL:
				e[0] = 0xfd; e[1] = 0x2d; break;
			default:
				if (!oparenOLD(lp, '[') && !oparenOLD(lp, '(')) break;
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					if (cparenOLD(lp)) e[0] = 0x35;
					break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0x35; e[2] = z80GetIDxoffset(lp);
					if (cparenOLD(lp)) e[0] = reg;
					break;
				default:
					;
				}
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_DI() {
		EmitByte(0xf3);
	}

	void OpCode_DJNZ() {
		int jmp;
		aint nad;
		int e[3];
		do {
			e[0] = e[1] = e[2] = -1;
			if (!GetAddress(lp, nad)) {
				nad = CurAddress + 2;
			}
			jmp = nad - CurAddress - 2;
			if (jmp < -128 || jmp > 127) {
				char el[LINEMAX];
				SPRINTF1(el, LINEMAX, "[DJNZ] Target out of range (%+i)", jmp);
				Error(el, 0, LASTPASS); jmp = 0;
			}
			e[0] = 0x10; e[1] = jmp < 0 ? 256 + jmp : jmp;
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_EI() {
		EmitByte(0xfb);
	}

	void OpCode_EX() {
		Z80Reg reg;
		int e[4];
		e[0] = e[1] = e[2] = e[3] = -1;
		switch (GetRegister(lp)) {
		case Z80_AF:
			if (comma(lp)) {
				if (GetRegister(lp) == Z80_AF) {
					if (*lp == '\'') {
						++lp;
					}
				} else {
					break;
				}
			}
			e[0] = 0x08;
			break;
		case Z80_DE:
			if (!comma(lp)) {
				Error("[EX] Comma expected", 0);
			} else {
				if (GetRegister(lp) == Z80_HL) e[0] = 0xeb;
			}
			break;
		case Z80_HL:
			if (!comma(lp)) {
				Error("[EX] Comma expected", 0);
			} else {
				if (GetRegister(lp) == Z80_DE) e[0] = 0xeb;
			}
			break;
		default:
			if (!oparenOLD(lp, '[') && !oparenOLD(lp, '(')) {
				break;
			}
			if (GetRegister(lp) != Z80_SP) {
				break;
			}
			if (!cparenOLD(lp)) {
				break;
			}
			if (!comma(lp)) {
				Error("[EX] Comma expected", 0); break;
			}
			switch (reg = GetRegister(lp)) {
			case Z80_HL:
				e[0] = 0xe3; break;
			case Z80_IX:
			case Z80_IY:
				e[0] = reg; e[1] = 0xe3; break;
			default:
				;
			}
		}
		EmitBytes(e);
	}

	void OpCode_EXA() {
		EmitByte(0x08);
	}

	void OpCode_EXD() {
		EmitByte(0xeb);
	}

	void OpCode_EXX() {
		EmitByte(0xd9);
	}

	void OpCode_HALT() {
		EmitByte(0x76);
	}

	void OpCode_IM() {
		int e[] = { -1, -1, -1 }, machineCode[] = { 0x46, 0x56, 0x5e };
		int mode = GetByte(lp);
		if (0 <= mode && mode <= 2) {
			e[0] = 0xed;
			e[1] = machineCode[mode];
		}
		EmitBytes(e);
	}

	void OpCode_IN() {
		Z80Reg reg;
		int e[3];
		do {
			e[0] = e[1] = e[2] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_A:
				if (!comma(lp)) {
					break;
				}
				if (!oparenOLD(lp, '[') && !oparenOLD(lp, '(')) {
					break;
				}
				if (GetRegister(lp) == Z80_C) {
					e[1] = 0x78;
					if (cparenOLD(lp)) {
						e[0] = 0xed;
					}
				} else {
					e[1] = GetByte(lp);
					if (cparenOLD(lp)) {
						e[0] = 0xdb;
					}
				}
				break;
			case Z80_B:
			case Z80_C:
			case Z80_D:
			case Z80_E:
			case Z80_H:
			case Z80_L:
			case Z80_F:
				if (!comma(lp)) {
					break;
				}
				if (!oparenOLD(lp, '[') && !oparenOLD(lp, '(')) {
					break;
				}
				if (GetRegister(lp) != Z80_C) {
					break;
				}
				if (cparenOLD(lp)) {
					e[0] = 0xed;
				}
				switch (reg) {
				case Z80_B:
					e[1] = 0x40; break;
				case Z80_C:
					e[1] = 0x48; break;
				case Z80_D:
					e[1] = 0x50; break;
				case Z80_E:
					e[1] = 0x58; break;
				case Z80_H:
					e[1] = 0x60; break;
				case Z80_L:
					e[1] = 0x68; break;
				case Z80_F:
					e[1] = 0x70; break;
				default:
					;
				}
			default:
				if (!oparenOLD(lp, '[') && !oparenOLD(lp, '(')) {
					break;
				}
				if (GetRegister(lp) != Z80_C) {
					break;
				}
				if (cparenOLD(lp)) {
					e[0] = 0xed;
				}
				e[1] = 0x70;
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_INC() {
		do {
			Z80Reg reg;
			int e[] = { -1, -1, -1, -1 };
			switch (reg = GetRegister(lp)) {
			case Z80_B: case Z80_C: case Z80_D: case Z80_E: case Z80_H: case Z80_L: case Z80_A:
				e[0] = 0x04 + 8 * reg; break;
			case Z80_BC: case Z80_DE: case Z80_HL: case Z80_SP:
				e[0] = 0x03 + reg - Z80_BC; break;
			case Z80_IX: case Z80_IY:
				e[0] = reg; e[1] = 0x23; break;
			case Z80_IXH:
				e[0] = 0xdd; e[1] = 0x24; break;
			case Z80_IXL:
				e[0] = 0xdd; e[1] = 0x2c; break;
			case Z80_IYH:
				e[0] = 0xfd; e[1] = 0x24; break;
			case Z80_IYL:
				e[0] = 0xfd; e[1] = 0x2c; break;
			default:
				if (!oparenOLD(lp, '[') && !oparenOLD(lp, '(')) break;
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					if (cparenOLD(lp)) e[0] = 0x34;
					break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0x34; e[2] = z80GetIDxoffset(lp);
					if (cparenOLD(lp)) e[0] = reg;
					break;
				default:
					;
				}
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_IND() {
		int e[3];
		e[0] = 0xed;
		e[1] = 0xaa;
		e[2] = -1;
		EmitBytes(e);
	}

	void OpCode_INDR() {
		int e[3];
		e[0] = 0xed;
		e[1] = 0xba;
		e[2] = -1;
		EmitBytes(e);
	}

	void OpCode_INI() {
		int e[3];
		e[0] = 0xed;
		e[1] = 0xa2;
		e[2] = -1;
		EmitBytes(e);
	}

	void OpCode_INIR() {
		int e[3];
		e[0] = 0xed;
		e[1] = 0xb2;
		e[2] = -1;
		EmitBytes(e);
	}

	void OpCode_INF() {
		int e[3];
		e[0] = 0xed;
		e[1] = 0x70;
		e[2] = -1;
		EmitBytes(e);
	}

	void OpCode_JP() {
		do {
			int e[] = { -1, -1, -1, -1 };
			Z80Reg reg = Z80_UNK;
			Z80Cond cc = getz80cond(lp);
			if (Z80C_UNK == cc) {	// no condition, check for: jp (hl),... and Z80N jp (c)
				EBracketType bt = OpenBracket(lp);
				switch (reg = GetRegister(lp)) {
				case Z80_C:
					// only "(C)" form with parentheses is legal syntax for Z80N "jp (C)"
					if (BT_ROUND != bt || !CloseBracket(lp) || !Options::IsNextEnabled) break;
					e[0] = 0xED; e[1] = 0x98;
					break;
				case Z80_HL:
				case Z80_IX:
				case Z80_IY:
					if (BT_NONE != bt && !CloseBracket(lp)) break;	// check [optional] brackets
					e[0] = reg;
					e[Z80_HL != reg] = 0xe9;	// e[1] for IX/IY, e[0] for HL
					break;
				case Z80_UNK:
					if (BT_SQUARE == bt) break;	// "[" has no chance, report it
					if (BT_ROUND == bt) --lp;	// give "(" another chance to evaluate as expression
					e[0] = 0xc3;				// jp imm16
					break;
				default:						// any other register is illegal
					break;
				}
			} else {	// if (Z80C_UNK == cc)
				if (comma(lp)) e[0] = 0xC2 + cc;	// jp cc,imm16
			}
			// calculate the imm16 data
			if (Z80_UNK == reg) {
				aint jpad;
				GetAddress(lp, jpad);
				check16(jpad);
				e[1] = jpad & 255; e[2] = (jpad >> 8) & 255;
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_JR() {
		do {
			int e[] = { -1, -1, -1, -1 };
			Z80Cond cc = getz80cond(lp);
			if (Z80C_UNK == cc) e[0] = 0x18;
			else if (cc <= Z80C_C && comma(lp)) e[0] = 0x20 + cc;
			else {
				Error("[JR] Illegal condition", 0);
				break;
			}
			aint jrad=0;
			if (GetAddress(lp, jrad)) jrad -= CurAddress + 2;
			if (jrad < -128 || jrad > 127) {
				char el[LINEMAX];
				SPRINTF1(el, LINEMAX, "[JR] Target out of range (%+li)", jrad);
				Error(el, 0, LASTPASS);
				jrad = 0;
			}
			e[1] = jrad & 0xFF;
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_LD() {
		Z80Reg reg;
		int e[7], beginhaakje;
		aint b;
		char* olp;

		do {
			e[0] = e[1] = e[2] = e[3] = e[4] = e[5] = e[6] = -1;
			switch (GetRegister(lp)) {
			case Z80_F:
			case Z80_AF:
				break;

			case Z80_A:
				if (!comma(lp)) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_F:
				case Z80_BC:
				case Z80_DE:
				case Z80_HL:
				case Z80_SP:
				case Z80_AF:
				case Z80_IX:
				case Z80_IY:
					break;
				case Z80_A:
				case Z80_B:
				case Z80_C:
				case Z80_D:
				case Z80_E:
				case Z80_H:
				case Z80_L:
					e[0] = 0x78 + reg; break;
				case Z80_I:
					e[0] = 0xed; e[1] = 0x57; break;
				case Z80_R:
					e[0] = 0xed; e[1] = 0x5f; break;
				case Z80_IXL:
					e[0] = 0xdd; e[1] = 0x7d; break;
				case Z80_IXH:
					e[0] = 0xdd; e[1] = 0x7c; break;
				case Z80_IYL:
					e[0] = 0xfd; e[1] = 0x7d; break;
				case Z80_IYH:
					e[0] = 0xfd; e[1] = 0x7c; break;
				default:
					if (oparenOLD(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							b = GetWord(lp); e[1] = b & 255; e[2] = (b >> 8) & 255;
							if (cparenOLD(lp)) {
								e[0] = 0x3a;
							} break;
						}
					} else {
						if (oparenOLD(lp, '(')) {
							if ((reg = GetRegister(lp)) == Z80_UNK) {
								olp = --lp;
								if (!ParseExpression(lp, b)) {
									break;
								}
								if (getparen(olp) == lp) {
									check16(b); e[0] = 0x3a; e[1] = b & 255; e[2] = (b >> 8) & 255;
								} else {
									check8(b); e[0] = 0x3e; e[1] = b & 255;
								}
							}
						} else {
							e[0] = 0x3e; e[1] = GetByte(lp); break;
						}
					}
					switch (reg) {
					case Z80_BC:
						if (cparenOLD(lp)) {
							e[0] = 0x0a;
						} break;
					case Z80_DE:
						if (cparenOLD(lp)) {
							e[0] = 0x1a;
						} break;
					case Z80_HL:
						if (cparenOLD(lp)) {
							e[0] = 0x7e;
						} break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x7e; e[2] = z80GetIDxoffset(lp);
						if (cparenOLD(lp)) {
							e[0] = reg;
						}
						break;
					default:
						break;
					}
				}
				break;

			case Z80_B:
				if (!comma(lp)) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_F:
				case Z80_BC:
				case Z80_DE:
				case Z80_HL:
				case Z80_I:
				case Z80_R:
				case Z80_SP:
				case Z80_AF:
				case Z80_IX:
				case Z80_IY:
					break;
				case Z80_A:
				case Z80_B:
				case Z80_C:
				case Z80_D:
				case Z80_E:
				case Z80_H:
				case Z80_L:
					e[0] = 0x40 + reg; break;
				case Z80_IXL:
					e[0] = 0xdd; e[1] = 0x45; break;
				case Z80_IXH:
					e[0] = 0xdd; e[1] = 0x44; break;
				case Z80_IYL:
					e[0] = 0xfd; e[1] = 0x45; break;
				case Z80_IYH:
					e[0] = 0xfd; e[1] = 0x44; break;
				default:
					if (oparenOLD(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							break;
						}
					} else if (oparenOLD(lp, '(')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							--lp; e[0] = 0x06; e[1] = GetByte(lp); break;
						}
					} else {
						e[0] = 0x06; e[1] = GetByte(lp); break;
					}
					switch (reg) {
					case Z80_HL:
						if (cparenOLD(lp)) {
							e[0] = 0x46;
						} break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x46; e[2] = z80GetIDxoffset(lp); if (cparenOLD(lp)) {
																 	e[0] = reg;
																 } break;
					default:
						break;
					}
				}
				break;

			case Z80_C:
				if (!comma(lp)) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_F:
				case Z80_BC:
				case Z80_DE:
				case Z80_HL:
				case Z80_I:
				case Z80_R:
				case Z80_SP:
				case Z80_AF:
				case Z80_IX:
				case Z80_IY:
					break;
				case Z80_A:
				case Z80_B:
				case Z80_C:
				case Z80_D:
				case Z80_E:
				case Z80_H:
				case Z80_L:
					e[0] = 0x48 + reg; break;
				case Z80_IXL:
					e[0] = 0xdd; e[1] = 0x4d; break;
				case Z80_IXH:
					e[0] = 0xdd; e[1] = 0x4c; break;
				case Z80_IYL:
					e[0] = 0xfd; e[1] = 0x4d; break;
				case Z80_IYH:
					e[0] = 0xfd; e[1] = 0x4c; break;
				default:
					if (oparenOLD(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							break;
						}
					} else if (oparenOLD(lp, '(')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							--lp; e[0] = 0x0e; e[1] = GetByte(lp); break;
						}
					} else {
						e[0] = 0x0e; e[1] = GetByte(lp); break;
					}
					switch (reg) {
					case Z80_HL:
						if (cparenOLD(lp)) {
							e[0] = 0x4e;
						} break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x4e; e[2] = z80GetIDxoffset(lp);
						if (cparenOLD(lp)) {
							e[0] = reg;
						}
						break;
					default:
						break;
					}
				}
				break;

			case Z80_D:
				if (!comma(lp)) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_F:
				case Z80_BC:
				case Z80_DE:
				case Z80_HL:
				case Z80_I:
				case Z80_R:
				case Z80_SP:
				case Z80_AF:
				case Z80_IX:
				case Z80_IY:
					break;
				case Z80_A:
				case Z80_B:
				case Z80_C:
				case Z80_D:
				case Z80_E:
				case Z80_H:
				case Z80_L:
					e[0] = 0x50 + reg; break;
				case Z80_IXL:
					e[0] = 0xdd; e[1] = 0x55; break;
				case Z80_IXH:
					e[0] = 0xdd; e[1] = 0x54; break;
				case Z80_IYL:
					e[0] = 0xfd; e[1] = 0x55; break;
				case Z80_IYH:
					e[0] = 0xfd; e[1] = 0x54; break;
				default:
					if (oparenOLD(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							break;
						}
					} else if (oparenOLD(lp, '(')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							--lp; e[0] = 0x16; e[1] = GetByte(lp); break;
						}
					} else {
						e[0] = 0x16; e[1] = GetByte(lp); break;
					}
					switch (reg) {
					case Z80_HL:
						if (cparenOLD(lp)) {
							e[0] = 0x56;
						} break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x56; e[2] = z80GetIDxoffset(lp);
						if (cparenOLD(lp)) {
							e[0] = reg;
						}
						break;
					default:
						break;
					}
				}
				break;

			case Z80_E:
				if (!comma(lp)) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_F:
				case Z80_BC:
				case Z80_DE:
				case Z80_HL:
				case Z80_I:
				case Z80_R:
				case Z80_SP:
				case Z80_AF:
				case Z80_IX:
				case Z80_IY:
					break;
				case Z80_A:
				case Z80_B:
				case Z80_C:
				case Z80_D:
				case Z80_E:
				case Z80_H:
				case Z80_L:
					e[0] = 0x58 + reg;
					break;
				case Z80_IXL:
					e[0] = 0xdd; e[1] = 0x5d;
					break;
				case Z80_IXH:
					e[0] = 0xdd; e[1] = 0x5c;
					break;
				case Z80_IYL:
					e[0] = 0xfd; e[1] = 0x5d;
					break;
				case Z80_IYH:
					e[0] = 0xfd; e[1] = 0x5c;
					break;
				default:
					if (oparenOLD(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							break;
						}
					} else if (oparenOLD(lp, '(')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							--lp;
							e[0] = 0x1e;
							e[1] = GetByte(lp);
							break;
						}
					} else {
						e[0] = 0x1e;
						e[1] = GetByte(lp);
						break;
					}
					switch (reg) {
					case Z80_HL:
						if (cparenOLD(lp)) {
							e[0] = 0x5e;
						} break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x5e;
						e[2] = z80GetIDxoffset(lp);
						if (cparenOLD(lp)) {
							e[0] = reg;
						}
						break;
					default:
						break;
					}
				}
				break;

			case Z80_H:
				if (!comma(lp)) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_F:
				case Z80_BC:
				case Z80_DE:
				case Z80_HL:
				case Z80_I:
				case Z80_R:
				case Z80_SP:
				case Z80_AF:
				case Z80_IX:
				case Z80_IY:
				case Z80_IXL:
				case Z80_IXH:
				case Z80_IYL:
				case Z80_IYH:
					break;
				case Z80_A:
				case Z80_B:
				case Z80_C:
				case Z80_D:
				case Z80_E:
				case Z80_H:
				case Z80_L:
					e[0] = 0x60 + reg;
					break;
				default:
					if (oparenOLD(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							break;
						}
					} else if (oparenOLD(lp, '(')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							--lp; e[0] = 0x26; e[1] = GetByte(lp);
							break;
						}
					} else {
						e[0] = 0x26; e[1] = GetByte(lp);
						break;
					}
					switch (reg) {
					case Z80_HL:
						if (cparenOLD(lp)) {
							e[0] = 0x66;
						}
						break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x66; e[2] = z80GetIDxoffset(lp);
						if (cparenOLD(lp)) {
							e[0] = reg;
						} break;
					default:
						break;
					}
				}
				break;

			case Z80_L:
				if (!comma(lp)) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_F:
				case Z80_BC:
				case Z80_DE:
				case Z80_HL:
				case Z80_I:
				case Z80_R:
				case Z80_SP:
				case Z80_AF:
				case Z80_IX:
				case Z80_IY:
				case Z80_IXL:
				case Z80_IXH:
				case Z80_IYL:
				case Z80_IYH:
					break;
				case Z80_A:
				case Z80_B:
				case Z80_C:
				case Z80_D:
				case Z80_E:
				case Z80_H:
				case Z80_L:
					e[0] = 0x68 + reg; break;
				default:
					if (oparenOLD(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							break;
						}
					} else if (oparenOLD(lp, '(')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							--lp; e[0] = 0x2e; e[1] = GetByte(lp); break;
						}
					} else {
						e[0] = 0x2e; e[1] = GetByte(lp); break;
					}
					switch (reg) {
					case Z80_HL:
						if (cparenOLD(lp)) {
							e[0] = 0x6e;
						} break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x6e; e[2] = z80GetIDxoffset(lp);
						if (cparenOLD(lp)) {
							e[0] = reg;
						}
						break;
					default:
						break;
					}
				}
				break;

			case Z80_I:
				if (!comma(lp)) {
					break;
				}
				if (GetRegister(lp) == Z80_A) {
					e[0] = 0xed;
				}
				e[1] = 0x47; break;
				break;

			case Z80_R:
				if (!comma(lp)) {
					break;
				}
				if (GetRegister(lp) == Z80_A) {
					e[0] = 0xed;
				}
				e[1] = 0x4f; break;
				break;

			case Z80_IXL:
				if (!comma(lp)) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_F:
				case Z80_BC:
				case Z80_DE:
				case Z80_HL:
				case Z80_I:
				case Z80_R:
				case Z80_SP:
				case Z80_AF:
				case Z80_IX:
				case Z80_IY:
				case Z80_H:
				case Z80_L:
				case Z80_IYL:
				case Z80_IYH:
					break;
				case Z80_A:
				case Z80_B:
				case Z80_C:
				case Z80_D:
				case Z80_E:
					e[0] = 0xdd; e[1] = 0x68 + reg; break;
				case Z80_IXL:
					e[0] = 0xdd; e[1] = 0x6d; break;
				case Z80_IXH:
					e[0] = 0xdd; e[1] = 0x6c; break;
				default:
					e[0] = 0xdd; e[1] = 0x2e; e[2] = GetByte(lp); break;
				}
				break;

			case Z80_IXH:
				if (!comma(lp)) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_F:
				case Z80_BC:
				case Z80_DE:
				case Z80_HL:
				case Z80_I:
				case Z80_R:
				case Z80_SP:
				case Z80_AF:
				case Z80_IX:
				case Z80_IY:
				case Z80_H:
				case Z80_L:
				case Z80_IYL:
				case Z80_IYH:
					break;
				case Z80_A:
				case Z80_B:
				case Z80_C:
				case Z80_D:
				case Z80_E:
					e[0] = 0xdd; e[1] = 0x60 + reg; break;
				case Z80_IXL:
					e[0] = 0xdd; e[1] = 0x65; break;
				case Z80_IXH:
					e[0] = 0xdd; e[1] = 0x64; break;
				default:
					e[0] = 0xdd; e[1] = 0x26; e[2] = GetByte(lp); break;
				}
				break;

			case Z80_IYL:
				if (!comma(lp)) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_F:
				case Z80_BC:
				case Z80_DE:
				case Z80_HL:
				case Z80_I:
				case Z80_R:
				case Z80_SP:
				case Z80_AF:
				case Z80_IX:
				case Z80_IY:
				case Z80_H:
				case Z80_L:
				case Z80_IXL:
				case Z80_IXH:
					break;
				case Z80_A:
				case Z80_B:
				case Z80_C:
				case Z80_D:
				case Z80_E:
					e[0] = 0xfd; e[1] = 0x68 + reg; break;
				case Z80_IYL:
					e[0] = 0xfd; e[1] = 0x6d; break;
				case Z80_IYH:
					e[0] = 0xfd; e[1] = 0x6c; break;
				default:
					e[0] = 0xfd; e[1] = 0x2e; e[2] = GetByte(lp); break;
				}
				break;

			case Z80_IYH:
				if (!comma(lp)) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_F:
				case Z80_BC:
				case Z80_DE:
				case Z80_HL:
				case Z80_I:
				case Z80_R:
				case Z80_SP:
				case Z80_AF:
				case Z80_IX:
				case Z80_IY:
				case Z80_H:
				case Z80_L:
				case Z80_IXL:
				case Z80_IXH:
					break;
				case Z80_A:
				case Z80_B:
				case Z80_C:
				case Z80_D:
				case Z80_E:
					e[0] = 0xfd; e[1] = 0x60 + reg; break;
				case Z80_IYL:
					e[0] = 0xfd; e[1] = 0x65; break;
				case Z80_IYH:
					e[0] = 0xfd; e[1] = 0x64; break;
				default:
					e[0] = 0xfd; e[1] = 0x26; e[2] = GetByte(lp); break;
				}
				break;

			case Z80_BC:
				if (!comma(lp)) {
					break;
				}
				switch (GetRegister(lp)) {
				case Z80_BC:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = 0x40; e[1] = 0x49; break;
				case Z80_DE:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = 0x42; e[1] = 0x4b; break;
				case Z80_HL:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = 0x44; e[1] = 0x4d; break;
				case Z80_IX:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = e[2] = 0xdd; e[1] = 0x44; e[3] = 0x4d; break;
				case Z80_IY:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = e[2] = 0xfd; e[1] = 0x44; e[3] = 0x4d; break;
				default:
					if (oparenOLD(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							b = GetWord(lp); e[1] = 0x4b; e[2] = b & 255; e[3] = (b >> 8) & 255;
							if (cparenOLD(lp)) {
								e[0] = 0xed;
							}
							break;
						}
					} else {
						if (oparenOLD(lp, '(')) {
							if ((reg = GetRegister(lp)) == Z80_UNK) {
					  			olp = --lp;
					  			b = GetWord(lp);
								if (getparen(olp) == lp) {
					  				e[0] = 0xed; e[1] = 0x4b; e[2] = b & 255; e[3] = (b >> 8) & 255;
								} else {
					  			  	e[0] = 0x01; e[1] = b & 255; e[2] = (b >> 8) & 255;
								}
							}
						} else {
					  	  	e[0] = 0x01; b = GetWord(lp); e[1] = b & 255; e[2] = (b >> 8) & 255; break;
						}
					}
					switch (reg) {
					case Z80_HL:
						ASSERT_FAKE_INSTRUCTIONS(break);
						if (cparenOLD(lp)) {
							e[0] = 0x4e;
						}
						e[1] = 0x23; e[2] = 0x46; e[3] = 0x2b;
						break;
					case Z80_IX:
					case Z80_IY:
						ASSERT_FAKE_INSTRUCTIONS(break);
						if ((b = z80GetIDxoffset(lp)) == 127) {
							// _COUT "E1 " _CMDL b _ENDL;
							Error("Offset out of range1", 0);
						}
						if (cparenOLD(lp)) {
							e[0] = e[3] = reg;
						} e[1] = 0x4e; e[4] = 0x46; e[2] = b; e[5] = b + 1; break;
					default:
						break;
					}
				}
				break;

			case Z80_DE:
				if (!comma(lp)) {
					break;
				}
				switch (GetRegister(lp)) {
				case Z80_BC:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = 0x50; e[1] = 0x59; break;
				case Z80_DE:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = 0x52; e[1] = 0x5b; break;
				case Z80_HL:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = 0x54; e[1] = 0x5d; break;
				case Z80_IX:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = e[2] = 0xdd; e[1] = 0x54; e[3] = 0x5d; break;
				case Z80_IY:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = e[2] = 0xfd; e[1] = 0x54; e[3] = 0x5d; break;
				default:
					if (oparenOLD(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							b = GetWord(lp); e[1] = 0x5b; e[2] = b & 255; e[3] = (b >> 8) & 255;
							if (cparenOLD(lp)) {
								e[0] = 0xed;
							} break;
						}
					} else {
						if (oparenOLD(lp, '(')) {
							if ((reg = GetRegister(lp)) == Z80_UNK) {
					  			olp = --lp;
					  			b = GetWord(lp);
								if (getparen(olp) == lp) {
					  				e[0] = 0xed; e[1] = 0x5b; e[2] = b & 255; e[3] = (b >> 8) & 255;
								} else {
					  			  	e[0] = 0x11; e[1] = b & 255; e[2] = (b >> 8) & 255;
								}
							}
						} else {
					  	  	e[0] = 0x11; b = GetWord(lp); e[1] = b & 255; e[2] = (b >> 8) & 255; break;
						}
					}
					switch (reg) {
					case Z80_HL:
						ASSERT_FAKE_INSTRUCTIONS(break);
						if (cparenOLD(lp)) {
							e[0] = 0x5e;
						} e[1] = 0x23; e[2] = 0x56; e[3] = 0x2b; break;
					case Z80_IX:
					case Z80_IY:
						ASSERT_FAKE_INSTRUCTIONS(break);
						if ((b = z80GetIDxoffset(lp)) == 127) {
							// _COUT "E2 " _CMDL b _ENDL;
							Error("Offset out of range2", 0);
						}
						if (cparenOLD(lp)) {
							e[0] = e[3] = reg;
						} e[1] = 0x5e; e[4] = 0x56; e[2] = b; e[5] = b + 1; break;
					default:
						break;
					}
				}
				break;

			case Z80_HL:
				if (!comma(lp)) {
					break;
				}
				switch (GetRegister(lp)) {
				case Z80_BC:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = 0x60; e[1] = 0x69; break;
				case Z80_DE:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = 0x62; e[1] = 0x6b; break;
				case Z80_HL:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = 0x64; e[1] = 0x6d; break;
				case Z80_IX:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = 0xdd; e[1] = 0xe5; e[2] = 0xe1; break;
				case Z80_IY:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = 0xfd; e[1] = 0xe5; e[2] = 0xe1; break;
				default:
					if (oparenOLD(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							b = GetWord(lp); e[1] = b & 255; e[2] = (b >> 8) & 255;
							if (cparenOLD(lp)) {
								e[0] = 0x2a;
							}
							break;
						}
					} else {
						if (oparenOLD(lp, '(')) {
							if ((reg = GetRegister(lp)) == Z80_UNK) {
					  			olp = --lp;
					  			b = GetWord(lp);
								if (getparen(olp) == lp) {
					  				e[0] = 0x2a; e[1] = b & 255; e[2] = (b >> 8) & 255;
								} else {
					  			  	e[0] = 0x21; e[1] = b & 255; e[2] = (b >> 8) & 255;
								}
							}
						} else {
					  	  	e[0] = 0x21; b = GetWord(lp); e[1] = b & 255; e[2] = (b >> 8) & 255; break;
						}
					}
					switch (reg) {
					case Z80_IX:
					case Z80_IY:
						ASSERT_FAKE_INSTRUCTIONS(break);
						if ((b = z80GetIDxoffset(lp)) == 127) {
							// _COUT "E3 " _CMDL b _ENDL;
							Error("Offset out of range3", 0);
						}
						if (cparenOLD(lp)) {
							e[0] = e[3] = reg;
						} e[1] = 0x6e; e[4] = 0x66; e[2] = b; e[5] = b + 1; break;
					default:
						break;
					}
				}
				break;

			case Z80_SP:
				if (!comma(lp)) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					e[0] = 0xf9; break;
				case Z80_IX:
				case Z80_IY:
					e[0] = reg; e[1] = 0xf9; break;
				default:
					if (oparenOLD(lp, '(') || oparenOLD(lp, '[')) {
						b = GetWord(lp); e[1] = 0x7b; e[2] = b & 255; e[3] = (b >> 8) & 255;
						if (cparenOLD(lp)) {
							e[0] = 0xed;
						}
					} else {
						b = GetWord(lp); e[0] = 0x31; e[1] = b & 255; e[2] = (b >> 8) & 255;
					}
				}
				break;

			case Z80_IX:
				if (!comma(lp)) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_BC:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = e[2] = 0xdd; e[1] = 0x69; e[3] = 0x60; break;
				case Z80_DE:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = e[2] = 0xdd; e[1] = 0x6b; e[3] = 0x62; break;
				case Z80_HL:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = 0xe5; e[1] = 0xdd; e[2] = 0xe1; break;
				case Z80_IX:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = e[2] = 0xdd; e[1] = 0x6d; e[3] = 0x64; break;
				case Z80_IY:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = 0xfd; e[1] = 0xe5; e[2] = 0xdd; e[3] = 0xe1; break;
				default:
					if (oparenOLD(lp, '[')) {
						b = GetWord(lp); e[1] = 0x2a; e[2] = b & 255; e[3] = (b >> 8) & 255;
						if (cparenOLD(lp)) {
							e[0] = 0xdd;
						} break;
					}
					if ((beginhaakje = oparenOLD(lp, '('))) {
						olp = --lp;
					}
					b = GetWord(lp);
					if (beginhaakje && getparen(olp) == lp) {
						e[0] = 0xdd; e[1] = 0x2a; e[2] = b & 255; e[3] = (b >> 8) & 255;
					} else {
						e[0] = 0xdd; e[1] = 0x21; e[2] = b & 255; e[3] = (b >> 8) & 255;
					}
					break;
				}
				break;

			case Z80_IY:
				if (!comma(lp)) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_BC:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = e[2] = 0xfd; e[1] = 0x69; e[3] = 0x60; break;
				case Z80_DE:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = e[2] = 0xfd; e[1] = 0x6b; e[3] = 0x62; break;
				case Z80_HL:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = 0xe5; e[1] = 0xfd; e[2] = 0xe1; break;
				case Z80_IX:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = 0xdd; e[1] = 0xe5; e[2] = 0xfd; e[3] = 0xe1; break;
				case Z80_IY:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = e[2] = 0xfd; e[1] = 0x6d; e[3] = 0x64; break;
				default:
					if (oparenOLD(lp, '[')) {
						b = GetWord(lp); e[1] = 0x2a; e[2] = b & 255; e[3] = (b >> 8) & 255;
						if (cparenOLD(lp)) {
							e[0] = 0xfd;
						}
						break;
					}
					if ((beginhaakje = oparenOLD(lp, '('))) {
						olp = --lp;
					}
					b = GetWord(lp);
					if (beginhaakje && getparen(olp) == lp) {
						e[0] = 0xfd; e[1] = 0x2a; e[2] = b & 255; e[3] = (b >> 8) & 255;
					} else {
						e[0] = 0xfd; e[1] = 0x21; e[2] = b & 255; e[3] = (b >> 8) & 255;
					}
					break;
				}
				break;

			default:
				if (!oparenOLD(lp, '(') && !oparenOLD(lp, '[')) {
					break;
				}
				switch (GetRegister(lp)) {
				case Z80_BC:
					if (!cparenOLD(lp)) {
						break;
					}
					if (!comma(lp)) {
						break;
					}
					if (GetRegister(lp) != Z80_A) {
						break;
					}
					e[0] = 0x02; break;
				case Z80_DE:
					if (!cparenOLD(lp)) {
						break;
					}
					if (!comma(lp)) {
						break;
					}
					if (GetRegister(lp) != Z80_A) {
						break;
					}
					e[0] = 0x12; break;
				case Z80_HL:
					if (!cparenOLD(lp)) {
						break;
					}
					if (!comma(lp)) {
						break;
					}
					switch (reg = GetRegister(lp)) {
					case Z80_A:
					case Z80_B:
					case Z80_C:
					case Z80_D:
					case Z80_E:
					case Z80_H:
					case Z80_L:
						e[0] = 0x70 + reg; break;
					case Z80_I:
					case Z80_R:
					case Z80_F:
						break;
					case Z80_BC:
						ASSERT_FAKE_INSTRUCTIONS(break);
						e[0] = 0x71; e[1] = 0x23; e[2] = 0x70; e[3] = 0x2b; break;
					case Z80_DE:
						ASSERT_FAKE_INSTRUCTIONS(break);
						e[0] = 0x73; e[1] = 0x23; e[2] = 0x72; e[3] = 0x2b; break;
					case Z80_HL:
					case Z80_IX:
					case Z80_IY:
						break;
					default:
						e[0] = 0x36; e[1] = GetByte(lp);
						break;
					}
					break;
				case Z80_IX:
					e[2] = z80GetIDxoffset(lp);
					if (!cparenOLD(lp)) {
						break;
					}
					if (!comma(lp)) {
						break;
					}
					switch (reg = GetRegister(lp)) {
					case Z80_A:
					case Z80_B:
					case Z80_C:
					case Z80_D:
					case Z80_E:
					case Z80_H:
					case Z80_L:
						e[0] = 0xdd; e[1] = 0x70 + reg; break;
					case Z80_F:
					case Z80_I:
					case Z80_R:
					case Z80_SP:
					case Z80_AF:
					case Z80_IX:
					case Z80_IY:
					case Z80_IXL:
					case Z80_IXH:
					case Z80_IYL:
					case Z80_IYH:
						break;
					case Z80_BC:
						ASSERT_FAKE_INSTRUCTIONS(break);
						if (e[2] == 127) {
							Error("Offset out of range", 0, LASTPASS);
						}
						e[0] = e[3] = 0xdd; e[1] = 0x71; e[4] = 0x70; e[5] = e[2] + 1; break;
					case Z80_DE:
						ASSERT_FAKE_INSTRUCTIONS(break);
						if (e[2] == 127) {
							Error("Offset out of range", 0, LASTPASS);
						}
						e[0] = e[3] = 0xdd; e[1] = 0x73; e[4] = 0x72; e[5] = e[2] + 1; break;
					case Z80_HL:
						ASSERT_FAKE_INSTRUCTIONS(break);
						if (e[2] == 127) {
							Error("Offset out of range", 0, LASTPASS);
						}
						e[0] = e[3] = 0xdd; e[1] = 0x75; e[4] = 0x74; e[5] = e[2] + 1; break;
					default:
						e[0] = 0xdd; e[1] = 0x36; e[3] = GetByte(lp);
						break;
					}
					break;
				case Z80_IY:
					e[2] = z80GetIDxoffset(lp);
					if (!cparenOLD(lp)) {
						break;
					}
					if (!comma(lp)) {
						break;
					}
					switch (reg = GetRegister(lp)) {
					case Z80_A:
					case Z80_B:
					case Z80_C:
					case Z80_D:
					case Z80_E:
					case Z80_H:
					case Z80_L:
						e[0] = 0xfd; e[1] = 0x70 + reg; break;
					case Z80_F:
					case Z80_I:
					case Z80_R:
					case Z80_SP:
					case Z80_AF:
					case Z80_IX:
					case Z80_IY:
					case Z80_IXL:
					case Z80_IXH:
					case Z80_IYL:
					case Z80_IYH:
						break;
					case Z80_BC:
						ASSERT_FAKE_INSTRUCTIONS(break);
						if (e[2] == 127) {
							Error("Offset out of range", 0, LASTPASS);
						}
						e[0] = e[3] = 0xfd; e[1] = 0x71; e[4] = 0x70; e[5] = e[2] + 1; break;
					case Z80_DE:
						ASSERT_FAKE_INSTRUCTIONS(break);
						if (e[2] == 127) {
							Error("Offset out of range", 0, LASTPASS);
						}
						e[0] = e[3] = 0xfd; e[1] = 0x73; e[4] = 0x72; e[5] = e[2] + 1; break;
					case Z80_HL:
						ASSERT_FAKE_INSTRUCTIONS(break);
						if (e[2] == 127) {
							Error("Offset out of range", 0, LASTPASS);
						}
						e[0] = e[3] = 0xfd; e[1] = 0x75; e[4] = 0x74; e[5] = e[2] + 1; break;
					default:
						e[0] = 0xfd; e[1] = 0x36; e[3] = GetByte(lp);
						break;
					}
					break;
				default:
					b = GetWord(lp);
					if (!cparenOLD(lp)) {
						break;
					}
					if (!comma(lp)) {
						break;
					}
					switch (GetRegister(lp)) {
					case Z80_A:
						e[0] = 0x32; e[1] = b & 255; e[2] = (b >> 8) & 255; break;
					case Z80_BC:
						e[0] = 0xed; e[1] = 0x43; e[2] = b & 255; e[3] = (b >> 8) & 255; break;
					case Z80_DE:
						e[0] = 0xed; e[1] = 0x53; e[2] = b & 255; e[3] = (b >> 8) & 255; break;
					case Z80_HL:
						e[0] = 0x22; e[1] = b & 255; e[2] = (b >> 8) & 255; break;
					case Z80_IX:
						e[0] = 0xdd; e[1] = 0x22; e[2] = b & 255; e[3] = (b >> 8) & 255; break;
					case Z80_IY:
						e[0] = 0xfd; e[1] = 0x22; e[2] = b & 255; e[3] = (b >> 8) & 255; break;
					case Z80_SP:
						e[0] = 0xed; e[1] = 0x73; e[2] = b & 255; e[3] = (b >> 8) & 255; break;
					default:
						break;
					}
					break;
				}
				break;
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_LDD() {
		Z80Reg reg, reg2;
		int e[7], b;

		if (!Options::FakeInstructions) {
			e[0] = 0xed;
			e[1] = 0xa8;
			e[2] = -1;
			EmitBytes(e);
			return;
		}

		do {
			e[0] = e[1] = e[2] = e[3] = e[4] = e[5] = e[6] = -1;
			//if (Options::FakeInstructions) {
				switch (reg = GetRegister(lp)) {
				case Z80_A:
					if (!comma(lp)) {
						break;
					}
					if (!oparenOLD(lp, '[') && !oparenOLD(lp, '(')) {
						break;
					}
					switch (reg = GetRegister(lp)) {
					case Z80_BC:
						if (cparenOLD(lp)) {
							e[0] = 0x0a;
						} e[1] = 0x0b; break;
					case Z80_DE:
						if (cparenOLD(lp)) {
							e[0] = 0x1a;
						} e[1] = 0x1b; break;
					case Z80_HL:
						if (cparenOLD(lp)) {
							e[0] = 0x7e;
						}
						e[1] = 0x2b;
						break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x7e; e[2] = z80GetIDxoffset(lp);
						if (cparenOLD(lp)) {
							e[0] = e[3] = reg;
						}
						e[4] = 0x2b;
						break;
					default:
						break;
					}
					break;
				case Z80_B:
				case Z80_C:
				case Z80_D:
				case Z80_E:
				case Z80_H:
				case Z80_L:
					if (!comma(lp)) {
						break;
					}
					if (!oparenOLD(lp, '[') && !oparenOLD(lp, '(')) {
						break;
					}
					switch (reg2 = GetRegister(lp)) {
					case Z80_HL:
						if (cparenOLD(lp)) {
							e[0] = 0x46 + reg * 8;
						} e[1] = 0x2b; break;
					case Z80_IX:
					case Z80_IY:
						e[2] = z80GetIDxoffset(lp);
						if (cparenOLD(lp)) {
							e[0] = e[3] = reg2;
						}
						e[1] = 0x46 + reg * 8; e[4] = 0x2b; break;
					default:
						break;
					}
					break;
				default:
					if (oparenOLD(lp, '[') || oparenOLD(lp, '(')) {
						reg = GetRegister(lp);

						b = 0;

						if (reg == Z80_IX || reg == Z80_IY) {
							b = z80GetIDxoffset(lp);
						}
						if (!cparenOLD(lp) || !comma(lp)) {
							break;
						}
						switch (reg) {
						case Z80_BC:
						case Z80_DE:
							if (GetRegister(lp) == Z80_A) {
								e[0] = reg - 14;
							} e[1] = reg - 5;
							break;
						case Z80_HL:
							switch (reg = GetRegister(lp)) {
							case Z80_A:
							case Z80_B:
							case Z80_C:
							case Z80_D:
							case Z80_E:
							case Z80_H:
							case Z80_L:
								e[0] = 0x70 + reg; e[1] = 0x2b; break;
							case Z80_UNK:
								e[0] = 0x36; e[1] = GetByte(lp); e[2] = 0x2b; break;
							default:
								break;
							}
							break;
						case Z80_IX:
						case Z80_IY:
							switch (reg2 = GetRegister(lp)) {
							case Z80_A:
							case Z80_B:
							case Z80_C:
							case Z80_D:
							case Z80_E:
							case Z80_H:
							case Z80_L:
								e[0] = e[3] = reg; e[2] = b; e[1] = 0x70 + reg2; e[4] = 0x2b; break;
							case Z80_UNK:
								e[0] = e[4] = reg; e[1] = 0x36; e[2] = b; e[3] = GetByte(lp); e[5] = 0x2b; break;
							default:
								break;
							}
							break;
						default:
							break;
						}
					} else {
						e[0] = 0xed;
						e[1] = 0xa8;
						break;
					}
				}
			/*} else {
				e[0] = 0xed;
				e[1] = 0xa8;
			}*/
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_LDDR() {
		EmitByte(0xED);
		EmitByte(0xB8);
	}

	void OpCode_Next_LDDRX() {
		EmitByte(0xED);
		EmitByte(0xBC);
	}

	void OpCode_Next_LDDX() {
		EmitByte(0xED);
		EmitByte(0xAC);
	}

	void OpCode_LDI() {
		Z80Reg reg, reg2;
		int e[11], b;

		if (!Options::FakeInstructions) {
			e[0] = 0xed;
			e[1] = 0xa0;
			e[2] = -1;
			EmitBytes(e);
			return;
		}

		do {
			e[0] = e[1] = e[2] = e[3] = e[4] = e[5] = e[6] = e[10] = -1;

				switch (reg = GetRegister(lp)) {
				case Z80_A:
					if (!comma(lp)) {
						break;
					}
					if (!oparenOLD(lp, '[') && !oparenOLD(lp, '(')) {
						break;
					}
					switch (reg = GetRegister(lp)) {
					case Z80_BC:
						if (cparenOLD(lp)) {
							e[0] = 0x0a;
						}
						e[1] = 0x03; break;
					case Z80_DE:
						if (cparenOLD(lp)) {
							e[0] = 0x1a;
						}
						e[1] = 0x13; break;
					case Z80_HL:
						if (cparenOLD(lp)) {
							e[0] = 0x7e;
						}
						e[1] = 0x23; break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x7e; e[2] = z80GetIDxoffset(lp);
						if (cparenOLD(lp)) {
							e[0] = e[3] = reg;
						}
						e[4] = 0x23; break;
					default:
						break;
					}
					break;
				case Z80_B:
				case Z80_C:
				case Z80_D:
				case Z80_E:
				case Z80_H:
				case Z80_L:
					if (!comma(lp)) {
						break;
					}
					if (!oparenOLD(lp, '[') && !oparenOLD(lp, '(')) {
						break;
					}
					switch (reg2 = GetRegister(lp)) {
					case Z80_HL:
						if (cparenOLD(lp)) {
							e[0] = 0x46 + reg * 8;
						} e[1] = 0x23; break;
					case Z80_IX:
					case Z80_IY:
						e[2] = z80GetIDxoffset(lp);
						if (cparenOLD(lp)) {
							e[0] = e[3] = reg2;
						}
						e[1] = 0x46 + reg * 8; e[4] = 0x23; break;
					default:
						break;
					}
					break;
				case Z80_BC:
					if (!comma(lp)) {
						break;
					}
					if (!oparenOLD(lp, '[') && !oparenOLD(lp, '(')) {
						break;
					}
					switch (reg = GetRegister(lp)) {
					case Z80_HL:
						if (cparenOLD(lp)) {
							e[0] = 0x4e;
						}
						e[1] = e[3] = 0x23; e[2] = 0x46; break;
					case Z80_IX:
					case Z80_IY:
						e[2] = e[7] = z80GetIDxoffset(lp);
						if (cparenOLD(lp)) {
							e[0] = e[3] = e[5] = e[8] = reg;
						}
						e[1] = 0x4e; e[6] = 0x46; e[4] = e[9] = 0x23; break;
					default:
						break;
					}
					break;
				case Z80_DE:
					if (!comma(lp)) {
						break;
					}
					if (!oparenOLD(lp, '[') && !oparenOLD(lp, '(')) {
						break;
					}
					switch (reg = GetRegister(lp)) {
					case Z80_HL:
						if (cparenOLD(lp)) {
							e[0] = 0x5e;
						} e[1] = e[3] = 0x23; e[2] = 0x56; break;
					case Z80_IX:
					case Z80_IY:
						e[2] = e[7] = z80GetIDxoffset(lp);
						if (cparenOLD(lp)) {
							e[0] = e[3] = e[5] = e[8] = reg;
						}
						e[1] = 0x5e; e[6] = 0x56; e[4] = e[9] = 0x23; break;
					default:
						break;
					}
					break;
				case Z80_HL:
					if (!comma(lp)) {
						break;
					}
					if (!oparenOLD(lp, '[') && !oparenOLD(lp, '(')) {
						break;
					}
					switch (reg = GetRegister(lp)) {
					case Z80_IX:
					case Z80_IY:
						e[2] = e[7] = z80GetIDxoffset(lp);
						if (cparenOLD(lp)) {
							e[0] = e[3] = e[5] = e[8] = reg;
						}
						e[1] = 0x6e; e[6] = 0x66; e[4] = e[9] = 0x23; break;
					default:
						break;
					}
					break;
				default:
					if (oparenOLD(lp, '[') || oparenOLD(lp, '(')) {
						reg = GetRegister(lp);
						b = 0;
						if (reg == Z80_IX || reg == Z80_IY) {
							b = z80GetIDxoffset(lp);
						}
						if (!cparenOLD(lp) || !comma(lp)) {
							break;
						}
						switch (reg) {
						case Z80_BC:
						case Z80_DE:
							if (GetRegister(lp) == Z80_A) {
								e[0] = reg - 14;
							} e[1] = reg - 13;
							break;
						case Z80_HL:
							switch (reg = GetRegister(lp)) {
							case Z80_A:
							case Z80_B:
							case Z80_C:
							case Z80_D:
							case Z80_E:
							case Z80_H:
							case Z80_L:
								e[0] = 0x70 + reg; e[1] = 0x23; break;
							case Z80_BC:
								e[0] = 0x71; e[1] = e[3] = 0x23; e[2] = 0x70; break;
							case Z80_DE:
								e[0] = 0x73; e[1] = e[3] = 0x23; e[2] = 0x72; break;
							case Z80_UNK:
								e[0] = 0x36; e[1] = GetByte(lp); e[2] = 0x23; break;
							default:
								break;
							}
							break;
						case Z80_IX:
						case Z80_IY:
							switch (reg2 = GetRegister(lp)) {
							case Z80_A:
							case Z80_B:
							case Z80_C:
							case Z80_D:
							case Z80_E:
							case Z80_H:
							case Z80_L:
								e[0] = e[3] = reg; e[2] = b; e[1] = 0x70 + reg2; e[4] = 0x23; break;
							case Z80_BC:
								e[0] = e[3] = e[5] = e[8] = reg; e[1] = 0x71; e[6] = 0x70; e[4] = e[9] = 0x23; e[2] = e[7] = b; break;
							case Z80_DE:
								e[0] = e[3] = e[5] = e[8] = reg; e[1] = 0x73; e[6] = 0x72; e[4] = e[9] = 0x23; e[2] = e[7] = b; break;
							case Z80_HL:
								e[0] = e[3] = e[5] = e[8] = reg; e[1] = 0x75; e[6] = 0x74; e[4] = e[9] = 0x23; e[2] = e[7] = b; break;
							case Z80_UNK:
								e[0] = e[4] = reg; e[1] = 0x36; e[2] = b; e[3] = GetByte(lp); e[5] = 0x23; break;
							default:
								break;
							}
							break;
						default:
							break;
						}
					} else {
						e[0] = 0xed;
						e[1] = 0xa0;
						break;
					}
				}

			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_LDIR() {
		EmitByte(0xED);
		EmitByte(0xB0);
	}

// LDIRSCALE is now very unlikely to happen, there's ~1% chance it may be introduced within the cased-Next release
// 	void OpCode_Next_LDIRSCALE() {
// 		EmitByte(0xED);
// 		EmitByte(0xB6);
// 	}

	void OpCode_Next_LDIRX() {
		EmitByte(0xED);
		EmitByte(0xB4);
	}

	void OpCode_Next_LDIX() {
		EmitByte(0xED);
		EmitByte(0xA4);
	}

	void OpCode_Next_LDPIRX() {
		EmitByte(0xED);
		EmitByte(0xB7);
	}

	void OpCode_Next_LDWS() {
		EmitByte(0xED);
		EmitByte(0xA5);
	}

	void OpCode_Next_MIRROR() {
		Z80Reg reg = GetRegister(lp);
		if (Z80_UNK != reg && Z80_A != reg) {
			Error("[MIRROR] Illegal operand", lp, CATCHALL);
			return;
		}
		EmitByte(0xED);
		EmitByte(0x24);
	}

	void OpCode_Next_MUL() {
		int e[3];
		e[0] = e[1] = e[2] = -1;
		if (GetRegister(lp)==Z80_D && comma(lp) && GetRegister(lp)==Z80_E){
			e[0]=0xED;
			e[1]=0x30;
		}
		EmitBytes(e);
	}

	void OpCode_MULUB() {
		Z80Reg reg;
		int e[3];
		e[0] = e[1] = e[2] = -1;
		if ((reg = GetRegister(lp)) == Z80_A && comma(lp)) {
			reg = GetRegister(lp);
		}
		switch (reg) {
		case Z80_B:
			e[0] = 0xed; e[1] = 0xc5; break;
		case Z80_C:
			e[0] = 0xed; e[1] = 0xcd; break;
		case Z80_D:
			e[0] = 0xed; e[1] = 0xd5; break;
		case Z80_E:
			e[0] = 0xed; e[1] = 0xdd; break;
		default:
			;
		}
		EmitBytes(e);
	}

	void OpCode_MULUW() {
		Z80Reg reg;
		int e[3];
		e[0] = e[1] = e[2] = -1;
		if ((reg = GetRegister(lp)) == Z80_HL && comma(lp)) {
			reg = GetRegister(lp);
		}
		switch (reg) {
		case Z80_BC:
			e[0] = 0xed; e[1] = 0xc3; break;
		case Z80_SP:
			e[0] = 0xed; e[1] = 0xf3; break;
		default:
			;
		}
		EmitBytes(e);
	}

	void OpCode_NEG() {
		EmitByte(0xED);
		EmitByte(0x44);
	}

	void OpCode_Next_NEXTREG() {
		Z80Reg reg;
		int e[5];
		do {
			e[0] = e[1] = e[2] = e[3] = e[4] = -1;
			// is operand1 register? (to give more precise error message to people using wrong `nextreg a,$nn`)
			reg = GetRegister(lp);
			if (Z80_UNK != reg) {
				Error("[NEXTREG] first operand should be register number", NULL, SUPPRESS); break;
			}
			// this code would be enough to get correct assembling, the test above is "extra"
			e[2] = GetByte(lp);
			if (!comma(lp)) {
				Error("[NEXTREG] Comma expected", NULL); break;
			}
			switch (reg = GetRegister(lp)) {
				case Z80_A:
					e[0] = 0xED; e[1] = 0x92;
					break;
				case Z80_UNK:
					e[0] = 0xED; e[1] = 0x91;
					e[3] = GetByte(lp);
					break;
				default:
					break;
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_NOP() {
		EmitByte(0x0);
	}

	void OpCode_OR() {
		Z80Reg reg;
		EBracketType bt;
		int e[4];
		do {
			e[0] = e[1] = e[2] = e[3] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_A:
				/*if (!comma(lp)) { e[0]=0xb7; break; }
							reg=GetRegister(lp);*/
				e[0] = 0xb7; break;
			default:
				switch (reg) {
				case Z80_IXH:
					e[0] = 0xdd; e[1] = 0xb4; break;
				case Z80_IXL:
					e[0] = 0xdd; e[1] = 0xb5; break;
				case Z80_IYH:
					e[0] = 0xfd; e[1] = 0xb4; break;
				case Z80_IYL:
					e[0] = 0xfd; e[1] = 0xb5; break;
				case Z80_B:
				case Z80_C:
				case Z80_D:
				case Z80_E:
				case Z80_H:
				case Z80_L:
				case Z80_A:
					e[0] = 0xb0 + reg; break;
				case Z80_F:
				case Z80_I:
				case Z80_R:
				case Z80_AF:
				case Z80_BC:
				case Z80_DE:
				case Z80_HL:
				case Z80_SP:
				case Z80_IX:
				case Z80_IY:
					break;
				default:
					if (BT_NONE != (bt = OpenBracket(lp))) {
						switch (reg = GetRegister(lp)) {
						case Z80_HL:
							if (CloseBracket(lp)) e[0] = 0xb6;
							break;
						case Z80_IX:
						case Z80_IY:
							e[1] = 0xb6; e[2] = z80GetIDxoffset(lp);
							if (CloseBracket(lp)) e[0] = reg;
							break;
						default:
							break;
						}
						// give "(something..." another chance to parse as value expression
						if (Z80_UNK == reg && BT_ROUND == bt) --lp;
						else break;		//"(register" or other bracket: emit instruction || bug
					}
					e[0] = 0xf6; e[1] = GetByte(lp);
				}
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_OTDR() {
		EmitByte(0xED);
		EmitByte(0xBB);
	}

	void OpCode_OTIR() {
		EmitByte(0xED);
		EmitByte(0xB3);
	}

	void OpCode_OUT() {
		Z80Reg reg;
		int e[3];
		do {
			e[0] = e[1] = e[2] = -1;
			if (oparenOLD(lp, '[') || oparenOLD(lp, '(')) {
				if (GetRegister(lp) == Z80_C) {
					if (cparenOLD(lp) && comma(lp)) {
						switch (reg = GetRegister(lp)) {
						case Z80_B: case Z80_C: case Z80_D: case Z80_E: case Z80_H: case Z80_L: case Z80_A:
							e[0] = 0xed; e[1] = 0x41 + 8 * reg; break;
						default:
							if (!GetByte(lp)) e[0] = 0xed;	// out (c),0
							e[1] = 0x71; break;
						}
					}
				} else {
					e[1] = GetByte(lp);		// out ($n),a
					if (cparenOLD(lp) && comma(lp) && GetRegister(lp) == Z80_A) e[0] = 0xd3;
				}
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_OUTD() {
		EmitByte(0xED);
		EmitByte(0xAB);
	}

	void OpCode_OUTI() {
		EmitByte(0xED);
		EmitByte(0xA3);
	}

	void OpCode_Next_OUTINB() {
		EmitByte(0xED);
		EmitByte(0x90);
	}

	void OpCode_Next_PIXELAD() {
		EmitByte(0xED);
		EmitByte(0x94);
	}

	void OpCode_Next_PIXELDN() {
		EmitByte(0xED);
		EmitByte(0x93);
	}

	void OpCode_POPreverse() {
		int e[30],t = 29,c = 1;
		e[t] = -1;
		do {
			switch (GetRegister(lp)) {
			case Z80_AF:
				e[--t] = 0xf1; break;
			case Z80_BC:
				e[--t] = 0xc1; break;
			case Z80_DE:
				e[--t] = 0xd1; break;
			case Z80_HL:
				e[--t] = 0xe1; break;
			case Z80_IX:
				e[--t] = 0xe1; e[--t] = 0xdd; break;
			case Z80_IY:
				e[--t] = 0xe1; e[--t] = 0xfd; break;
			default:
				c = 0; break;
			}
			if (!comma(lp) || t < 2) {
				c = 0;
			}
		} while (c);
		EmitBytes(&e[t]);
	}

	void OpCode_POP() {
		Z80Reg reg;
		do {
			int e[5];
			e[0] = e[1] = e[2] = e[3] = e[4] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_AF:
				e[0] = 0xf1; break;
			case Z80_BC:
				e[0] = 0xc1; break;
			case Z80_DE:
				e[0] = 0xd1; break;
			case Z80_HL:
				e[0] = 0xe1; break;
			case Z80_IX:
			case Z80_IY:
				e[0] = reg; e[1] = 0xe1; break;
			default:
				break;
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_PUSH() {
		Z80Reg reg;
		do {
			int e[5];
			e[0] = e[1] = e[2] = e[3] = e[4] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_AF:
				e[0] = 0xf5; break;
			case Z80_BC:
				e[0] = 0xc5; break;
			case Z80_DE:
				e[0] = 0xd5; break;
			case Z80_HL:
				e[0] = 0xe5; break;
			case Z80_IX:
			case Z80_IY:
				e[0] = reg; e[1] = 0xe5; break;
			case Z80_UNK:
			{
				if(!Options::IsNextEnabled) break;
				int imm16 = GetWord(lp);
				e[0] = 0xED; e[1] = 0x8A;
				e[2] = (imm16 >> 8) & 255;  // push opcode is big-endian!
				e[3] = imm16 & 255;
			}
			default:
				break;
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_RES() {
		Z80Reg reg;
		int e[5], bit;
		do {
			e[0] = e[1] = e[2] = e[3] = e[4] = -1;
			bit = GetByte(lp);
			if (!comma(lp)) {
				bit = -1;
			}
			switch (reg = GetRegister(lp)) {
			case Z80_B:
			case Z80_C:
			case Z80_D:
			case Z80_E:
			case Z80_H:
			case Z80_L:
			case Z80_A:
				e[0] = 0xcb; e[1] = 8 * bit + 0x80 + reg ; break;
			default:
				if (!oparenOLD(lp, '[') && !oparenOLD(lp, '(')) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					if (cparenOLD(lp)) {
						e[0] = 0xcb;
					}
					e[1] = 8 * bit + 0x86; break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 8 * bit + 0x86;
					if (cparenOLD(lp)) {
						e[0] = reg;
					}
					if (comma(lp)) {
						switch (reg = GetRegister(lp)) {
						case Z80_B:
						case Z80_C:
						case Z80_D:
						case Z80_E:
						case Z80_H:
						case Z80_L:
						case Z80_A:
							e[3] = 8 * bit + 0x80 + reg;
							break;
						default:
							Error("[RES] Illegal operand", lp, SUPPRESS);
						}
					}
					break;
				default:
					;
				}
			}
			if (bit < 0 || bit > 7) {
				e[0] = -1;
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_RET() {
		Z80Cond cc = getz80cond(lp);
		if (Z80C_UNK == cc) EmitByte(0xc9);
		else 				EmitByte(0xc0 + cc);
		// multi-argument was intetionally removed by Ped7g (explain in issue why you want *that*?)
	}

	void OpCode_RETI() {
		EmitByte(0xED);
		EmitByte(0x4D);
	}

	void OpCode_RETN() {
		EmitByte(0xED);
		EmitByte(0x45);
	}

	void OpCode_RL() {
		Z80Reg reg;
		int e[5];
		do {
			e[0] = e[1] = e[2] = e[3] = e[4] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_B:
			case Z80_C:
			case Z80_D:
			case Z80_E:
			case Z80_H:
			case Z80_L:
			case Z80_A:
				e[0] = 0xcb;
				e[1] = 0x10 + reg;
				break;
			case Z80_BC:
				ASSERT_FAKE_INSTRUCTIONS(break);
				e[0] = e[2] = 0xcb;
				e[1] = 0x11;
				e[3] = 0x10;
				break;
			case Z80_DE:
				ASSERT_FAKE_INSTRUCTIONS(break);
				e[0] = e[2] = 0xcb;
				e[1] = 0x13;
				e[3] = 0x12;
				break;
			case Z80_HL:
				ASSERT_FAKE_INSTRUCTIONS(break);
				e[0] = e[2] = 0xcb;
				e[1] = 0x15;
				e[3] = 0x14;
				break;
			default:
				if (!oparenOLD(lp, '[') && !oparenOLD(lp, '(')) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					if (cparenOLD(lp)) {
						e[0] = 0xcb;
					}
					e[1] = 0x16; break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 0x16;
					if (cparenOLD(lp)) {
						e[0] = reg;
					}
					if (comma(lp)) {
						switch (reg = GetRegister(lp)) {
						case Z80_B:
						case Z80_C:
						case Z80_D:
						case Z80_E:
						case Z80_H:
						case Z80_L:
						case Z80_A:
							e[3] = 0x10 + reg;
							break;
						default:
							Error("[RL] Illegal operand", lp, SUPPRESS);
						}
					}
					break;
				default:
					;
				}
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_RLA() {
		EmitByte(0x17);
	}

	void OpCode_RLC() {
		Z80Reg reg;
		int e[5];
		do {
			e[0] = e[1] = e[2] = e[3] = e[4] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_B:
			case Z80_C:
			case Z80_D:
			case Z80_E:
			case Z80_H:
			case Z80_L:
			case Z80_A:
				e[0] = 0xcb; e[1] = 0x0 + reg ; break;
			default:
				if (!oparenOLD(lp, '[') && !oparenOLD(lp, '(')) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					if (cparenOLD(lp)) {
						e[0] = 0xcb;
					}
					e[1] = 0x6; break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 0x6;
					if (cparenOLD(lp)) {
						e[0] = reg;
					}
					if (comma(lp)) {
						switch (reg = GetRegister(lp)) {
						case Z80_B:
						case Z80_C:
						case Z80_D:
						case Z80_E:
						case Z80_H:
						case Z80_L:
						case Z80_A:
							e[3] = reg;
							break;
						default:
							Error("[RLC] Illegal operand", lp, SUPPRESS);
						}
					}
					break;
				default:
					;
				}
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_RLCA() {
		EmitByte(0x7);
	}

	void OpCode_RLD() {
		EmitByte(0xED);
		EmitByte(0x6F);
	}

	void OpCode_RR() {
		Z80Reg reg;
		int e[5];
		do {
			e[0] = e[1] = e[2] = e[3] = e[4] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_B:
			case Z80_C:
			case Z80_D:
			case Z80_E:
			case Z80_H:
			case Z80_L:
			case Z80_A:
				e[0] = 0xcb; e[1] = 0x18 + reg ; break;
			case Z80_BC:
				ASSERT_FAKE_INSTRUCTIONS(break);
				e[0] = e[2] = 0xcb; e[1] = 0x18; e[3] = 0x19; break;
			case Z80_DE:
				ASSERT_FAKE_INSTRUCTIONS(break);
				e[0] = e[2] = 0xcb; e[1] = 0x1a; e[3] = 0x1b; break;
			case Z80_HL:
				ASSERT_FAKE_INSTRUCTIONS(break);
				e[0] = e[2] = 0xcb; e[1] = 0x1c; e[3] = 0x1d; break;
			default:
				if (!oparenOLD(lp, '[') && !oparenOLD(lp, '(')) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					if (cparenOLD(lp)) {
						e[0] = 0xcb;
					}
					e[1] = 0x1e; break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 0x1e;
					if (cparenOLD(lp)) {
						e[0] = reg;
					}
					if (comma(lp)) {
						switch (reg = GetRegister(lp)) {
						case Z80_B:
						case Z80_C:
						case Z80_D:
						case Z80_E:
						case Z80_H:
						case Z80_L:
						case Z80_A:
							e[3] = 0x18 + reg;
							break;
						default:
							Error("[RR] Illegal operand", lp, SUPPRESS);
						}
					}
					break;
				default:
					;
				}
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_RRA() {
		EmitByte(0x1f);
	}

	void OpCode_RRC() {
		Z80Reg reg;
		int e[5];
		do {
			e[0] = e[1] = e[2] = e[3] = e[4] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_B:
			case Z80_C:
			case Z80_D:
			case Z80_E:
			case Z80_H:
			case Z80_L:
			case Z80_A:
				e[0] = 0xcb; e[1] = 0x8 + reg ; break;
			default:
				if (!oparenOLD(lp, '[') && !oparenOLD(lp, '(')) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					if (cparenOLD(lp)) {
						e[0] = 0xcb;
					}
					e[1] = 0xe; break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 0xe;
					if (cparenOLD(lp)) {
						e[0] = reg;
					}
					if (comma(lp)) {
						switch (reg = GetRegister(lp)) {
						case Z80_B:
						case Z80_C:
						case Z80_D:
						case Z80_E:
						case Z80_H:
						case Z80_L:
						case Z80_A:
							e[3] = 0x8 + reg;
							break;
						default:
							Error("[RRC] Illegal operand", lp, SUPPRESS);
						}
					}
					break;
				default:
					;
				}
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_RRCA() {
		EmitByte(0xf);
	}

	void OpCode_RRD() {
		EmitByte(0xED);
		EmitByte(0x67);
	}

	void OpCode_RST() {
		do {
			int e = GetByte(lp);
			if (e&(~0x38)) {	// some bit is set which should be not
				Error("[RST] Illegal operand", line); *lp = 0; return;
			} else {			// e == { $00, $08, $10, $18, $20, $28, $30, $38 }
				EmitByte(0xC7 + e);
			}
		} while (comma(lp));
	}

	void OpCode_SBC() {
		Z80Reg reg;
		EBracketType bt;
		int e[4];
		do {
			e[0] = e[1] = e[2] = e[3] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_HL:
				if (!comma(lp)) {
					Error("[SBC] Comma expected", 0); break;
				}
				switch (GetRegister(lp)) {
				case Z80_BC:
					e[0] = 0xed; e[1] = 0x42; break;
				case Z80_DE:
					e[0] = 0xed; e[1] = 0x52; break;
				case Z80_HL:
					e[0] = 0xed; e[1] = 0x62; break;
				case Z80_SP:
					e[0] = 0xed; e[1] = 0x72; break;
				default:
					;
				}
				break;
			case Z80_A:
				if (!comma(lp)) {
					e[0] = 0x9f; break;
				}
				reg = GetRegister(lp);
			default:
				switch (reg) {
				case Z80_IXH:
					e[0] = 0xdd; e[1] = 0x9c; break;
				case Z80_IXL:
					e[0] = 0xdd; e[1] = 0x9d; break;
				case Z80_IYH:
					e[0] = 0xfd; e[1] = 0x9c; break;
				case Z80_IYL:
					e[0] = 0xfd; e[1] = 0x9d; break;
				case Z80_B:
				case Z80_C:
				case Z80_D:
				case Z80_E:
				case Z80_H:
				case Z80_L:
				case Z80_A:
					e[0] = 0x98 + reg; break;
				case Z80_F:
				case Z80_I:
				case Z80_R:
				case Z80_AF:
				case Z80_BC:
				case Z80_DE:
				case Z80_HL:
				case Z80_SP:
				case Z80_IX:
				case Z80_IY:
					break;
				default:
					if (BT_NONE != (bt = OpenBracket(lp))) {
						switch (reg = GetRegister(lp)) {
						case Z80_HL:
							if (CloseBracket(lp)) e[0] = 0x9e;
							break;
						case Z80_IX:
						case Z80_IY:
							e[1] = 0x9e; e[2] = z80GetIDxoffset(lp);
							if (CloseBracket(lp)) e[0] = reg;
							break;
						default:
							break;
						}
						// give "(something..." another chance to parse as value expression
						if (Z80_UNK == reg && BT_ROUND == bt) --lp;
						else break;		//"(register" or other bracket: emit instruction || bug
					}
					e[0] = 0xde; e[1] = GetByte(lp);
				}
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_SCF() {
		EmitByte(0x37);
	}

	void OpCode_SET() {
		Z80Reg reg;
		int e[5], bit;
		do {
			e[0] = e[1] = e[2] = e[3] = e[4] = -1;
			bit = GetByte(lp);
			if (!comma(lp)) {
				bit = -1;
			}
			switch (reg = GetRegister(lp)) {
			case Z80_B:
			case Z80_C:
			case Z80_D:
			case Z80_E:
			case Z80_H:
			case Z80_L:
			case Z80_A:
				e[0] = 0xcb; e[1] = 8 * bit + 0xc0 + reg ; break;
			default:
				if (!oparenOLD(lp, '[') && !oparenOLD(lp, '(')) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					if (cparenOLD(lp)) {
						e[0] = 0xcb;
					}
					e[1] = 8 * bit + 0xc6; break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 8 * bit + 0xc6;
					if (cparenOLD(lp)) {
						e[0] = reg;
					}
					if (comma(lp)) {
						switch (reg = GetRegister(lp)) {
						case Z80_B:
						case Z80_C:
						case Z80_D:
						case Z80_E:
						case Z80_H:
						case Z80_L:
						case Z80_A:
							e[3] = 8 * bit + 0xc0 + reg;
							break;
						default:
							Error("[SET] Illegal operand", lp, SUPPRESS);
						}
					}
					break;
				default:
					;
				}
			}
			if (bit < 0 || bit > 7) {
				e[0] = -1;
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_Next_SETAE() {
		EmitByte(0xED);
		EmitByte(0x95);
	}

	void OpCode_SLA() {
		Z80Reg reg;
		int e[5];
		do {
			e[0] = e[1] = e[2] = e[3] = e[4] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_B:
			case Z80_C:
			case Z80_D:
			case Z80_E:
			case Z80_H:
			case Z80_L:
			case Z80_A:
				e[0] = 0xcb; e[1] = 0x20 + reg ; break;
			case Z80_BC:
				ASSERT_FAKE_INSTRUCTIONS(break);
				e[0] = e[2] = 0xcb; e[1] = 0x21; e[3] = 0x10; break;
			case Z80_DE:
				ASSERT_FAKE_INSTRUCTIONS(break);
				e[0] = e[2] = 0xcb; e[1] = 0x23; e[3] = 0x12; break;
			case Z80_HL:
				e[0] = 0x29; break;
			default:
				if (!oparenOLD(lp, '[') && !oparenOLD(lp, '(')) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					if (cparenOLD(lp)) {
						e[0] = 0xcb;
					}
					e[1] = 0x26; break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 0x26;
					if (cparenOLD(lp)) {
						e[0] = reg;
					}
					if (comma(lp)) {
						switch (reg = GetRegister(lp)) {
						case Z80_B:
						case Z80_C:
						case Z80_D:
						case Z80_E:
						case Z80_H:
						case Z80_L:
						case Z80_A:
							e[3] = 0x20 + reg;
							break;
						default:
							Error("[SLA] Illegal operand", lp, SUPPRESS);
						}
					}
					break;
				default:
					;
				}
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_SLL() {
		Z80Reg reg;
		int e[5];
		do {
			e[0] = e[1] = e[2] = e[3] = e[4] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_B:
			case Z80_C:
			case Z80_D:
			case Z80_E:
			case Z80_H:
			case Z80_L:
			case Z80_A:
				e[0] = 0xcb; e[1] = 0x30 + reg ; break;
			case Z80_BC:
				ASSERT_FAKE_INSTRUCTIONS(break);
				e[0] = e[2] = 0xcb; e[1] = 0x31; e[3] = 0x10; break;
			case Z80_DE:
				ASSERT_FAKE_INSTRUCTIONS(break);
				e[0] = e[2] = 0xcb; e[1] = 0x33; e[3] = 0x12; break;
			case Z80_HL:
				ASSERT_FAKE_INSTRUCTIONS(break);
				e[0] = e[2] = 0xcb; e[1] = 0x35; e[3] = 0x14; break;
			default:
				if (!oparenOLD(lp, '[') && !oparenOLD(lp, '(')) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					if (cparenOLD(lp)) {
						e[0] = 0xcb;
					}
					e[1] = 0x36; break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 0x36;
					if (cparenOLD(lp)) {
						e[0] = reg;
					}
					if (comma(lp)) {
						switch (reg = GetRegister(lp)) {
						case Z80_B:
						case Z80_C:
						case Z80_D:
						case Z80_E:
						case Z80_H:
						case Z80_L:
						case Z80_A:
							e[3] = 0x30 + reg;
							break;
						default:
							Error("[SLL] Illegal operand", lp, SUPPRESS);
						}
					}
					break;
				default:
					;
				}
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_SRA() {
		Z80Reg reg;
		int e[5];
		do {
			e[0] = e[1] = e[2] = e[3] = e[4] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_B:
			case Z80_C:
			case Z80_D:
			case Z80_E:
			case Z80_H:
			case Z80_L:
			case Z80_A:
				e[0] = 0xcb; e[1] = 0x28 + reg ; break;
			case Z80_BC:
				ASSERT_FAKE_INSTRUCTIONS(break);
				e[0] = e[2] = 0xcb; e[1] = 0x28; e[3] = 0x19; break;
			case Z80_DE:
				ASSERT_FAKE_INSTRUCTIONS(break);
				e[0] = e[2] = 0xcb; e[1] = 0x2a; e[3] = 0x1b; break;
			case Z80_HL:
				ASSERT_FAKE_INSTRUCTIONS(break);
				e[0] = e[2] = 0xcb; e[1] = 0x2c; e[3] = 0x1d; break;
			default:
				if (!oparenOLD(lp, '[') && !oparenOLD(lp, '(')) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					if (cparenOLD(lp)) {
						e[0] = 0xcb;
					}
					e[1] = 0x2e; break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 0x2e;
					if (cparenOLD(lp)) {
						e[0] = reg;
					}
					if (comma(lp)) {
						switch (reg = GetRegister(lp)) {
						case Z80_B:
						case Z80_C:
						case Z80_D:
						case Z80_E:
						case Z80_H:
						case Z80_L:
						case Z80_A:
							e[3] = 0x28 + reg;
							break;
						default:
							Error("[SRA] Illegal operand", lp, SUPPRESS);
						}
					}
					break;
				default:
					;
				}
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_SRL() {
		Z80Reg reg;
		int e[5];
		do {
			e[0] = e[1] = e[2] = e[3] = e[4] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_B:
			case Z80_C:
			case Z80_D:
			case Z80_E:
			case Z80_H:
			case Z80_L:
			case Z80_A:
				e[0] = 0xcb; e[1] = 0x38 + reg ; break;
			case Z80_BC:
				ASSERT_FAKE_INSTRUCTIONS(break);
				e[0] = e[2] = 0xcb; e[1] = 0x38; e[3] = 0x19; break;
			case Z80_DE:
				ASSERT_FAKE_INSTRUCTIONS(break);
				e[0] = e[2] = 0xcb; e[1] = 0x3a; e[3] = 0x1b; break;
			case Z80_HL:
				ASSERT_FAKE_INSTRUCTIONS(break);
				e[0] = e[2] = 0xcb; e[1] = 0x3c; e[3] = 0x1d; break;
			default:
				if (!oparenOLD(lp, '[') && !oparenOLD(lp, '(')) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					if (cparenOLD(lp)) {
						e[0] = 0xcb;
					}
					e[1] = 0x3e; break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 0x3e;
					if (cparenOLD(lp)) {
						e[0] = reg;
					}
					if (comma(lp)) {
						switch (reg = GetRegister(lp)) {
						case Z80_B:
						case Z80_C:
						case Z80_D:
						case Z80_E:
						case Z80_H:
						case Z80_L:
						case Z80_A:
							e[3] = 0x38 + reg;
							break;
						default:
							Error("[SRL] Illegal operand", lp, SUPPRESS);
						}
					}
					break;
				default:
					;
				}
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	void OpCode_SUB() {
		Z80Reg reg;
		EBracketType bt;
		int e[4];
		do {
			e[0] = e[1] = e[2] = e[3] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_HL:
				if (!needcomma(lp)) {
					break;
				}
				switch (GetRegister(lp)) {
				case Z80_BC:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = 0xb7; e[1] = 0xed; e[2] = 0x42; break;
				case Z80_DE:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = 0xb7; e[1] = 0xed; e[2] = 0x52; break;
				case Z80_HL:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = 0xb7; e[1] = 0xed; e[2] = 0x62; break;
				case Z80_SP:
					ASSERT_FAKE_INSTRUCTIONS(break);
					e[0] = 0xb7; e[1] = 0xed; e[2] = 0x72; break;
				default:;
				}
				break;
			case Z80_A:
				/*if (!comma(lp)) { e[0]=0x97; break; }
							reg=GetRegister(lp);*/
				e[0] = 0x97; break;
			default:
				switch (reg) {
				case Z80_IXH:
					e[0] = 0xdd; e[1] = 0x94; break;
				case Z80_IXL:
					e[0] = 0xdd; e[1] = 0x95; break;
				case Z80_IYH:
					e[0] = 0xfd; e[1] = 0x94; break;
				case Z80_IYL:
					e[0] = 0xfd; e[1] = 0x95; break;
				case Z80_B:
				case Z80_C:
				case Z80_D:
				case Z80_E:
				case Z80_H:
				case Z80_L:
				case Z80_A:
					e[0] = 0x90 + reg; break;
				case Z80_F:
				case Z80_I:
				case Z80_R:
				case Z80_AF:
				case Z80_BC:
				case Z80_DE:
				case Z80_HL:
				case Z80_SP:
				case Z80_IX:
				case Z80_IY:
					break;
				default:
					if (BT_NONE != (bt = OpenBracket(lp))) {
						switch (reg = GetRegister(lp)) {
						case Z80_HL:
							if (CloseBracket(lp)) e[0] = 0x96;
							break;
						case Z80_IX:
						case Z80_IY:
							e[1] = 0x96; e[2] = z80GetIDxoffset(lp);
							if (CloseBracket(lp)) e[0] = reg;
							break;
						default:
							break;
						}
						// give "(something..." another chance to parse as value expression
						if (Z80_UNK == reg && BT_ROUND == bt) --lp;
						else break;		//"(register" or other bracket: emit instruction || bug
					}
					e[0] = 0xd6; e[1] = GetByte(lp);
				}
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	//Swaps the high and low nibbles of the accumulator.
	void OpCode_Next_SWAPNIB() {
		Z80Reg reg = GetRegister(lp);
		if (Z80_UNK != reg && Z80_A != reg) {
			Error("[SWAPNIB] Illegal operand", lp, CATCHALL);
			return;
		}
		EmitByte(0xED);
		EmitByte(0x23);
	}

	void OpCode_Next_TEST() {
		int e[4];
		e[0] = 0xED;
		e[1] = 0x27;
		e[2] = GetByte(lp);
		e[3] = -1;
		EmitBytes(e);
	}

	void OpCode_XOR() {
		Z80Reg reg;
		EBracketType bt;
		int e[4];
		do {
			e[0] = e[1] = e[2] = e[3] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_A:
				/*if (!comma(lp)) { e[0]=0xaf; break; }
							reg=GetRegister(lp);*/
				e[0] = 0xaf; break;
			default:
				switch (reg) {
				case Z80_IXH:
					e[0] = 0xdd; e[1] = 0xac; break;
				case Z80_IXL:
					e[0] = 0xdd; e[1] = 0xad; break;
				case Z80_IYH:
					e[0] = 0xfd; e[1] = 0xac; break;
				case Z80_IYL:
					e[0] = 0xfd; e[1] = 0xad; break;
				case Z80_B:
				case Z80_C:
				case Z80_D:
				case Z80_E:
				case Z80_H:
				case Z80_L:
				case Z80_A:
					e[0] = 0xa8 + reg; break;
				case Z80_F:
				case Z80_I:
				case Z80_R:
				case Z80_AF:
				case Z80_BC:
				case Z80_DE:
				case Z80_HL:
				case Z80_SP:
				case Z80_IX:
				case Z80_IY:
					break;
				default:
					if (BT_NONE != (bt = OpenBracket(lp))) {
						switch (reg = GetRegister(lp)) {
						case Z80_HL:
							if (CloseBracket(lp)) e[0] = 0xae;
							break;
						case Z80_IX:
						case Z80_IY:
							e[1] = 0xae; e[2] = z80GetIDxoffset(lp);
							if (CloseBracket(lp)) e[0] = reg;
							break;
						default:
							break;
						}
						// give "(something..." another chance to parse as value expression
						if (Z80_UNK == reg && BT_ROUND == bt) --lp;
						else break;		//"(register" or other bracket: emit instruction || bug
					}
					e[0] = 0xee; e[1] = GetByte(lp);
					break;
				}
			}
			EmitBytes(e);
		} while (comma(lp));
	}

	void Init() {
		OpCodeTable.Insert("adc", OpCode_ADC);
		OpCodeTable.Insert("add", OpCode_ADD);
		OpCodeTable.Insert("and", OpCode_AND);
		OpCodeTable.Insert("bit", OpCode_BIT);
		OpCodeTable.Insert("call", OpCode_CALL);
		OpCodeTable.Insert("ccf", OpCode_CCF);
		OpCodeTable.Insert("cp", OpCode_CP);
		OpCodeTable.Insert("cpd", OpCode_CPD);
		OpCodeTable.Insert("cpdr", OpCode_CPDR);
		OpCodeTable.Insert("cpi", OpCode_CPI);
		OpCodeTable.Insert("cpir", OpCode_CPIR);
		OpCodeTable.Insert("cpl", OpCode_CPL);
		OpCodeTable.Insert("daa", OpCode_DAA);
		OpCodeTable.Insert("dec", OpCode_DEC);
		OpCodeTable.Insert("di", OpCode_DI);
		OpCodeTable.Insert("djnz", OpCode_DJNZ);
		OpCodeTable.Insert("ei", OpCode_EI);
		OpCodeTable.Insert("ex", OpCode_EX);
		OpCodeTable.Insert("exa", OpCode_EXA);
		OpCodeTable.Insert("exd", OpCode_EXD);
		OpCodeTable.Insert("exx", OpCode_EXX);
		OpCodeTable.Insert("halt", OpCode_HALT);
		OpCodeTable.Insert("im", OpCode_IM);
		OpCodeTable.Insert("in", OpCode_IN);
		OpCodeTable.Insert("inc", OpCode_INC);
		OpCodeTable.Insert("ind", OpCode_IND);
		OpCodeTable.Insert("indr", OpCode_INDR);
		OpCodeTable.Insert("ini", OpCode_INI);
		OpCodeTable.Insert("inir", OpCode_INIR);
		OpCodeTable.Insert("inf", OpCode_INF); // thanks to BREEZE
		OpCodeTable.Insert("jp", OpCode_JP);
		OpCodeTable.Insert("jr", OpCode_JR);
		OpCodeTable.Insert("ld", OpCode_LD);
		OpCodeTable.Insert("ldd", OpCode_LDD);
		OpCodeTable.Insert("lddr", OpCode_LDDR);
		OpCodeTable.Insert("ldi", OpCode_LDI);
		OpCodeTable.Insert("ldir", OpCode_LDIR);
		OpCodeTable.Insert("mulub", OpCode_MULUB);
		OpCodeTable.Insert("muluw", OpCode_MULUW);
		OpCodeTable.Insert("neg", OpCode_NEG);
		OpCodeTable.Insert("nop", OpCode_NOP);
		OpCodeTable.Insert("or", OpCode_OR);
		OpCodeTable.Insert("otdr", OpCode_OTDR);
		OpCodeTable.Insert("otir", OpCode_OTIR);
		OpCodeTable.Insert("out", OpCode_OUT);
		OpCodeTable.Insert("outd", OpCode_OUTD);
		OpCodeTable.Insert("outi", OpCode_OUTI);
		if (Options::IsReversePOP) {
			OpCodeTable.Insert("pop", OpCode_POPreverse);
		} else {
			OpCodeTable.Insert("pop", OpCode_POP);
		}
		OpCodeTable.Insert("push", OpCode_PUSH);
		OpCodeTable.Insert("res", OpCode_RES);
		OpCodeTable.Insert("ret", OpCode_RET);
		OpCodeTable.Insert("reti", OpCode_RETI);
		OpCodeTable.Insert("retn", OpCode_RETN);
		OpCodeTable.Insert("rl", OpCode_RL);
		OpCodeTable.Insert("rla", OpCode_RLA);
		OpCodeTable.Insert("rlc", OpCode_RLC);
		OpCodeTable.Insert("rlca", OpCode_RLCA);
		OpCodeTable.Insert("rld", OpCode_RLD);
		OpCodeTable.Insert("rr", OpCode_RR);
		OpCodeTable.Insert("rra", OpCode_RRA);
		OpCodeTable.Insert("rrc", OpCode_RRC);
		OpCodeTable.Insert("rrca", OpCode_RRCA);
		OpCodeTable.Insert("rrd", OpCode_RRD);
		OpCodeTable.Insert("rst", OpCode_RST);
		OpCodeTable.Insert("sbc", OpCode_SBC);
		OpCodeTable.Insert("scf", OpCode_SCF);
		OpCodeTable.Insert("set", OpCode_SET);
		OpCodeTable.Insert("sla", OpCode_SLA);
		OpCodeTable.Insert("sli", OpCode_SLL);
		OpCodeTable.Insert("sll", OpCode_SLL);
		OpCodeTable.Insert("sra", OpCode_SRA);
		OpCodeTable.Insert("srl", OpCode_SRL);
		OpCodeTable.Insert("sub", OpCode_SUB);
		OpCodeTable.Insert("xor", OpCode_XOR);

		if(!Options::IsNextEnabled) return;

		// Next extended opcodes
		OpCodeTable.Insert("brlc",		OpCode_Next_BRLC);
		OpCodeTable.Insert("bsla",		OpCode_Next_BSLA);
		OpCodeTable.Insert("bsra",		OpCode_Next_BSRA);
		OpCodeTable.Insert("bsrf",		OpCode_Next_BSRF);
		OpCodeTable.Insert("bsrl",		OpCode_Next_BSRL);
		OpCodeTable.Insert("lddrx",		OpCode_Next_LDDRX);
		OpCodeTable.Insert("lddx",		OpCode_Next_LDDX);
		//OpCodeTable.Insert("ldirscale",	OpCode_Next_LDIRSCALE);
		OpCodeTable.Insert("ldirx",		OpCode_Next_LDIRX);
		OpCodeTable.Insert("ldix",		OpCode_Next_LDIX);
		OpCodeTable.Insert("ldpirx",	OpCode_Next_LDPIRX);
		OpCodeTable.Insert("ldws",		OpCode_Next_LDWS);
		OpCodeTable.Insert("mirror",	OpCode_Next_MIRROR);
		OpCodeTable.Insert("mul",		OpCode_Next_MUL);
		OpCodeTable.Insert("nextreg",	OpCode_Next_NEXTREG);
		OpCodeTable.Insert("outinb",	OpCode_Next_OUTINB);
		OpCodeTable.Insert("pixelad",	OpCode_Next_PIXELAD);
		OpCodeTable.Insert("pixeldn",	OpCode_Next_PIXELDN);
		OpCodeTable.Insert("setae",		OpCode_Next_SETAE);
		OpCodeTable.Insert("swapnib",	OpCode_Next_SWAPNIB);
		OpCodeTable.Insert("test",		OpCode_Next_TEST);
	}
} // eof namespace Z80


void InitCPU() {
	Z80::Init();
	InsertDirectives();
}
//eof z80.cpp
