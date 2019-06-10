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
	enum Z80Reg { Z80_B = 0, Z80_C, Z80_D, Z80_E, Z80_H, Z80_L, Z80_MEM_HL, Z80_A, Z80_I, Z80_R, Z80_F,
		Z80_BC = 0x10, Z80_DE = 0x20, Z80_HL = 0x30, Z80_SP = 0x40, Z80_AF = 0x50,
		Z80_IX = 0xdd, Z80_IY = 0xfd, Z80_IXH = Z80_IX|(Z80_H<<8), Z80_IXL = Z80_IX|(Z80_L<<8),
		Z80_IYH = Z80_IY|(Z80_H<<8), Z80_IYL = Z80_IY|(Z80_L<<8), Z80_UNK = -1 };
	enum Z80Cond {	// also used to calculate instruction opcode, so do not edit values
		Z80C_NZ = 0x00, Z80C_Z  = 0x08, Z80C_NC = 0x10, Z80C_C = 0x18,
		Z80C_PO = 0x20, Z80C_PE = 0x28, Z80C_P  = 0x30, Z80C_M = 0x38, Z80C_UNK };

	CFunctionTable OpCodeTable;

	void GetOpCode() {
		char* n;
		bp = lp;
		if (!(n = getinstr(lp))) {
			Error("Unrecognized instruction", lp);
			return;
		}
		if (!OpCodeTable.zoek(n)) {
			Error("Unrecognized instruction", bp);
			SkipToEol(lp);
		}
	}

	int GetByte(char*& p) {
		aint val;
		if (!ParseExpression(p, val)) {
			Error("Operand expected"); return 0;
		}
		check8(val);
		return val & 255;
	}

	int GetWord(char*& p) {
		aint val;
		if (!ParseExpression(p, val)) {
			Error("Operand expected"); return 0;
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
			Error("Operand expected"); return 0;
		}
		check8o(val);
		return val & 255;
	}

	int GetAddress(char*& p, aint& ad) {
		if (GetLocalLabelValue(p, ad) || ParseExpression(p, ad)) return 1;
		Error("Operand expected", NULL, IF_FIRST);
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

	static Z80Reg GetRegister_r16High(const Z80Reg r16) {
		switch (r16) {
		case Z80_BC: return Z80_B;
		case Z80_DE: return Z80_D;
		case Z80_HL: return Z80_H;
		case Z80_AF: return Z80_A;
		case Z80_IX: return Z80_IXH;
		case Z80_IY: return Z80_IYH;
		default:
			return Z80_UNK;
		}
	}

	static Z80Reg GetRegister_r16Low(const Z80Reg r16) {
		switch (r16) {
		case Z80_BC: return Z80_C;
		case Z80_DE: return Z80_E;
		case Z80_HL: return Z80_L;
		case Z80_AF: return Z80_F;
		case Z80_IX: return Z80_IXL;
		case Z80_IY: return Z80_IYL;
		default:
			return Z80_UNK;
		}
	}

	static bool GetRegister_pair(char*& p, const char expect) {
		if (expect != p[0] || islabchar(p[1])) return false;
		++p;
		return true;
	}

	static Z80Reg GetRegister(char*& p) {
		char* pp = p;
		SkipBlanks(p);
		// fast lookup table for single letters 'a'..'i' ('g','j','k' will produce Z80_UNK instantly)
		constexpr Z80Reg r8[] = { Z80_A, Z80_B, Z80_C, Z80_D, Z80_E, Z80_F, Z80_UNK, Z80_H, Z80_I, Z80_UNK, Z80_UNK, Z80_L };
		if ('a' <= *p && *p <= 'l' && !islabchar(p[1])) return r8[*p++ - 'a'];
		if ('A' <= *p && *p <= 'L' && !islabchar(p[1])) return r8[*p++ - 'A'];
		// high/low operators can be used on register pair
		if(memcmp(p, "high ", 5) == 0 || memcmp(p, "HIGH ", 5) == 0) {
			p += 5;
			const Z80Reg reg = GetRegister(p);
			if (Z80_UNK == reg) p -= 5;
			return GetRegister_r16High(reg);
		}
		if(memcmp(p, "low ", 4) == 0 || memcmp(p, "LOW ", 4) == 0) {
			p += 4;
			const Z80Reg reg = GetRegister(p);
			if (Z80_UNK == reg) p -= 4;
			return GetRegister_r16Low(reg);
		}
		// remaining "R" register and two+ letter registers
		switch (*(p++)) {
		case 'a':
			if (GetRegister_pair(p, 'f')) return Z80_AF;
			break;
		case 'b':
			if (GetRegister_pair(p, 'c')) return Z80_BC;
			break;
		case 'd':
			if (GetRegister_pair(p, 'e')) return Z80_DE;
			break;
		case 'h':
			if (GetRegister_pair(p, 'l')) return Z80_HL;
			if (GetRegister_pair(p, 'x')) return Z80_IXH;
			if (GetRegister_pair(p, 'y')) return Z80_IYH;
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
			break;
		case 'x':
			if (GetRegister_pair(p, 'h')) return Z80_IXH;
			if (GetRegister_pair(p, 'l')) return Z80_IXL;
			break;
		case 'y':
			if (GetRegister_pair(p, 'h')) return Z80_IYH;
			if (GetRegister_pair(p, 'l')) return Z80_IYL;
			break;
		case 'l':
			if (GetRegister_pair(p, 'x')) return Z80_IXL;
			if (GetRegister_pair(p, 'y')) return Z80_IYL;
			break;
		case 'r':
			if (!islabchar(*p)) return Z80_R;
			break;
		case 's':
			if (GetRegister_pair(p, 'p')) return Z80_SP;
			break;
		case 'A':
			if (GetRegister_pair(p, 'F')) return Z80_AF;
			break;
		case 'B':
			if (GetRegister_pair(p, 'C')) return Z80_BC;
			break;
		case 'D':
			if (GetRegister_pair(p, 'E')) return Z80_DE;
			break;
		case 'H':
			if (GetRegister_pair(p, 'L')) return Z80_HL;
			if (GetRegister_pair(p, 'X')) return Z80_IXH;
			if (GetRegister_pair(p, 'Y')) return Z80_IYH;
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
			break;
		case 'X':
			if (GetRegister_pair(p, 'H')) return Z80_IXH;
			if (GetRegister_pair(p, 'L')) return Z80_IXL;
			break;
		case 'Y':
			if (GetRegister_pair(p, 'H')) return Z80_IYH;
			if (GetRegister_pair(p, 'L')) return Z80_IYL;
			break;
		case 'L':
			if (GetRegister_pair(p, 'X')) return Z80_IXL;
			if (GetRegister_pair(p, 'Y')) return Z80_IYL;
			break;
		case 'R':
			if (!islabchar(*p)) return Z80_R;
			break;
		case 'S':
			if (GetRegister_pair(p, 'P')) return Z80_SP;
			break;
		case '(':
			if (Z80_HL != GetRegister(p)) break;
			SkipBlanks(p);
			if (')' == *p++) return Z80_MEM_HL;
			break;
		case '[':
			if (Z80_HL != GetRegister(p)) break;
			SkipBlanks(p);
			if (']' == *p++) return Z80_MEM_HL;
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
					Error("[ADC] Comma expected"); break;
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
				case Z80_IXH: case Z80_IXL: case Z80_IYH: case Z80_IYL:
					e[0] = reg&0xFF; e[1] = 0x88 + (reg>>8); break;
				case Z80_B: case Z80_C: case Z80_D: case Z80_E:
				case Z80_H: case Z80_L: case Z80_MEM_HL: case Z80_A:
					e[0] = 0x88 + reg; break;
				case Z80_UNK:
					if (BT_NONE != (bt = OpenBracket(lp))) {
						switch (reg = GetRegister(lp)) {
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
				default:
					break;
				}
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	void OpCode_ADD() {
		Z80Reg reg, reg2;
		EBracketType bt;
		do {
			int e[] = { -1, -1, -1, -1, -1 };
			switch (reg = GetRegister(lp)) {
			case Z80_HL:
				if (!comma(lp)) {
					Error("[ADD] Comma expected"); break;
				}
				switch (reg2 = GetRegister(lp)) {
				case Z80_BC:	case Z80_DE:	case Z80_HL:	case Z80_SP:
					e[0] = 0x09 + reg2 - Z80_BC; break;
				case Z80_A:
					if(!Options::syx.IsNextEnabled) break;
					e[0] = 0xED; e[1] = 0x31; break;
				default:
					if(!Options::syx.IsNextEnabled) break;
					int b = GetWord(lp);
					e[0] = 0xED; e[1] = 0x34 ;
					e[2] = b & 255; e[3] = (b >> 8) & 255;
					break;
				}
				break;
			case Z80_DE:
			case Z80_BC:
				if (!Options::syx.IsNextEnabled) break;   // DE|BC is valid first operand only for Z80N
				if (!comma(lp)) {
					Error("[ADD] Comma expected"); break;
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
					Error("[ADD] Comma expected"); break;
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
				case Z80_IXH: case Z80_IXL: case Z80_IYH: case Z80_IYL:
					e[0] = reg&0xFF; e[1] = 0x80 + (reg>>8); break;
				case Z80_B: case Z80_C: case Z80_D: case Z80_E:
				case Z80_H: case Z80_L: case Z80_MEM_HL: case Z80_A:
					e[0] = 0x80 + reg; break;
				case Z80_UNK:
					if (BT_NONE != (bt = OpenBracket(lp))) {
						switch (reg = GetRegister(lp)) {
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
				default:
					break;
				}
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	void OpCode_AND() {
		Z80Reg reg;
		EBracketType bt;
		int e[4];
		do {
			e[0] = e[1] = e[2] = e[3] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_A:
				if (!nonMaComma(lp)) {	// "AND a,b" is possible only when multi-arg is not-comma
					e[0] = 0xa7;
					break;
				}
				reg = GetRegister(lp);
			default:
				switch (reg) {
				case Z80_IXH: case Z80_IXL: case Z80_IYH: case Z80_IYL:
					e[0] = reg&0xFF; e[1] = 0xa0 + (reg>>8); break;
				case Z80_B: case Z80_C: case Z80_D: case Z80_E:
				case Z80_H: case Z80_L: case Z80_MEM_HL: case Z80_A:
					e[0] = 0xa0 + reg; break;
				case Z80_UNK:
					if (BT_NONE != (bt = OpenBracket(lp))) {
						switch (reg = GetRegister(lp)) {
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
				default:
					break;
				}
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
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
			case Z80_B: case Z80_C: case Z80_D: case Z80_E:
			case Z80_H: case Z80_L: case Z80_MEM_HL: case Z80_A:
				e[0] = 0xcb; e[1] = 8 * bit + 0x40 + reg; break;
			default:
				if (BT_NONE == OpenBracket(lp)) break;
				switch (reg = GetRegister(lp)) {
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 8 * bit + 0x46;
					if (CloseBracket(lp)) e[0] = reg;
					break;
				default:
					break;
				}
				break;
			}
			if (bit < 0 || bit > 7) e[0] = -1;
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	void OpCode_Next_BREAK() {	// this is fake instruction for CSpect emulator, not for real Z80N
		if (Options::syx.IsNextEnabled < 2) {
			Error("[BREAK] fake instruction \"break\" must be specifically enabled by --zxnext=cspect option");
			return;
		}
		EmitByte(0xDD);
		EmitByte(0x01);
	}

	// helper function for BRLC, BSLA, BSRA, BSRF, BSRL, as all need identical operand validation
	static void OpCode_Z80N_BarrelShifts(int mainOpcode) {
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
		int e[] = { -1, -1, -1 };
		// verify the operands are "de,b" (only valid ones)
		if (Z80_DE == GetRegister(lp) && comma(lp) && Z80_B == GetRegister(lp)) {
			e[0]=0xED;
			e[1]=mainOpcode;
		} else {
			Error("Z80N barrel shifts exist only with \"DE,B\" arguments", bp, SUPPRESS);
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
		} while (Options::syx.MultiArg(lp));
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
				if (!nonMaComma(lp)) {	// "CP a,b" is possible only when multi-arg is not-comma
					e[0] = 0xbf;
					break;
				}
				reg = GetRegister(lp);
			default:
				switch (reg) {
				case Z80_IXH: case Z80_IXL: case Z80_IYH: case Z80_IYL:
					e[0] = reg&0xFF; e[1] = 0xb8 + (reg>>8); break;
				case Z80_B: case Z80_C: case Z80_D: case Z80_E:
				case Z80_H: case Z80_L: case Z80_MEM_HL: case Z80_A:
					e[0] = 0xb8 + reg; break;
				case Z80_UNK:
					if (BT_NONE != (bt = OpenBracket(lp))) {
						switch (reg = GetRegister(lp)) {
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
					break;
				default:
					break;
				}
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
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
			case Z80_IXH: case Z80_IXL: case Z80_IYH: case Z80_IYL:
				e[0] = reg&0xFF; e[1] = 0x05 + 8*(reg>>8); break;
			case Z80_B: case Z80_C: case Z80_D: case Z80_E:
			case Z80_H: case Z80_L: case Z80_MEM_HL: case Z80_A:
				e[0] = 0x05 + 8 * reg; break;
			case Z80_BC: case Z80_DE: case Z80_HL: case Z80_SP:
				e[0] = 0x0b + reg - Z80_BC; break;
			case Z80_IX: case Z80_IY:
				e[0] = reg; e[1] = 0x2b; break;
			default:
				if (BT_NONE == OpenBracket(lp)) break;
				switch (reg = GetRegister(lp)) {
				case Z80_IX:
				case Z80_IY:
					e[1] = 0x35; e[2] = z80GetIDxoffset(lp);
					if (CloseBracket(lp)) e[0] = reg;
					break;
				default:
					break;
				}
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
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
				Error(el); jmp = 0;
			}
			e[0] = 0x10; e[1] = jmp < 0 ? 256 + jmp : jmp;
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	void OpCode_EI() {
		EmitByte(0xfb);
	}

	void OpCode_EX() {
		int e[] { -1, -1, -1, -1 };
		Z80Reg reg = GetRegister(lp);
		switch (reg) {
		case Z80_AF:
			if (comma(lp)) {
				if (Z80_AF != GetRegister(lp)) break;
				if (*lp == '\'') ++lp;
			}
			e[0] = 0x08;
			break;
		case Z80_DE:
		case Z80_HL:
			if (!comma(lp)) {
				Error("[EX] Comma expected");
			} else {	// check for the other one: DE <-> HL
				if (Z80Reg(reg ^ Z80_DE ^ Z80_HL) == GetRegister(lp)) e[0] = 0xeb;
			}
			break;
		default:
			if (BT_NONE == OpenBracket(lp) || Z80_SP != GetRegister(lp) || !CloseBracket(lp)) break;
			if (!comma(lp)) {
				Error("[EX] Comma expected");
				break;
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

	void OpCode_Next_EXIT() {	// this is fake instruction for CSpect emulator, not for real Z80N
		if (Options::syx.IsNextEnabled < 2) {
			Error("[EXIT] fake instruction \"exit\" must be specifically enabled by --zxnext=cspect option");
			return;
		}
		EmitByte(0xDD);
		EmitByte(0x00);
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
			reg = GetRegister(lp);
			if (Z80_UNK == reg || comma(lp)) {
				if (Z80_UNK == reg) reg = Z80_F;	// if there was no register, it may be "IN (C)"
				if (BT_NONE == OpenBracket(lp)) reg = Z80_UNK;
				if (Z80_C == GetRegister(lp)) {
					e[0] = 0xed;
					switch (reg) {
						case Z80_B:
						case Z80_C:
						case Z80_D:
						case Z80_E:
						case Z80_H:
						case Z80_L:
						case Z80_A:
							e[1] = 0x40 + reg*8;	// regular IN reg,(C)
							break;
						case Z80_F:
							e[1] = 0x70;			// unofficial IN F,(C)
							break;
						default:	e[0] = -1;		// invalid combination
					}
				} else {
					e[1] = GetByte(lp);
					if (Z80_A == reg) e[0] = 0xdb;	// IN A,(n)
				}
				if (!CloseBracket(lp)) e[0] = -1;
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	void OpCode_INC() {
		do {
			Z80Reg reg;
			int e[] = { -1, -1, -1, -1 };
			switch (reg = GetRegister(lp)) {
			case Z80_IXH: case Z80_IXL: case Z80_IYH: case Z80_IYL:
				e[0] = reg&0xFF; e[1] = 0x04 + 8*(reg>>8); break;
			case Z80_B: case Z80_C: case Z80_D: case Z80_E:
			case Z80_H: case Z80_L: case Z80_MEM_HL: case Z80_A:
				e[0] = 0x04 + 8 * reg; break;
			case Z80_BC: case Z80_DE: case Z80_HL: case Z80_SP:
				e[0] = 0x03 + reg - Z80_BC; break;
			case Z80_IX: case Z80_IY:
				e[0] = reg; e[1] = 0x23; break;
			default:
				if (BT_NONE == OpenBracket(lp)) break;
				switch (reg = GetRegister(lp)) {
				case Z80_IX:
				case Z80_IY:
					e[1] = 0x34; e[2] = z80GetIDxoffset(lp);
					if (CloseBracket(lp)) e[0] = reg;
					break;
				default:
					;
				}
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
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
				char* expLp = lp;
				EBracketType bt = OpenBracket(lp);
				switch (reg = GetRegister(lp)) {
				case Z80_C:
					// only "(C)" form with parentheses is legal syntax for Z80N "jp (C)"
					if (BT_ROUND != bt || !CloseBracket(lp) || !Options::syx.IsNextEnabled) break;
					e[0] = 0xED; e[1] = 0x98;
					break;
				case Z80_HL:
				case Z80_IX:
				case Z80_IY:
					if (BT_NONE != bt && !CloseBracket(lp)) break;	// check [optional] brackets
					e[0] = reg;
					e[Z80_IX <= reg] = 0xe9;	// e[1] for IX/IY, e[0] overwritten for HL/MEM_HL
					break;
				case Z80_MEM_HL:				// MEM_HL was handled manually, should NOT happen
					reg = Z80_UNK;				// try to treat it like expression in following code
				case Z80_UNK:
					if (BT_SQUARE == bt) break;	// "[" has no chance, report it
					if (BT_ROUND == bt) lp = expLp;	// give "(" another chance to evaluate as expression
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
		} while (Options::syx.MultiArg(lp));
	}

	void OpCode_JR() {
		do {
			int e[] = { -1, -1, -1, -1 };
			Z80Cond cc = getz80cond(lp);
			if (Z80C_UNK == cc) e[0] = 0x18;
			else if (cc <= Z80C_C && comma(lp)) e[0] = 0x20 + cc;
			else {
				Error("[JR] Illegal condition");
				break;
			}
			aint jrad=0;
			if (GetAddress(lp, jrad)) jrad -= CurAddress + 2;
			if (jrad < -128 || jrad > 127) {
				char el[LINEMAX];
				SPRINTF1(el, LINEMAX, "[JR] Target out of range (%+li)", jrad);
				Error(el);
				jrad = 0;
			}
			e[1] = jrad & 0xFF;
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static bool LD_simple_r_r(int* e, Z80Reg r1) {
		int prefix1 = 0, prefix2 = 0;
		bool eightBit = true;
		switch (r1) {
		case Z80_IXH:	case Z80_IXL:	case Z80_IYH:	case Z80_IYL:
			prefix1 = r1&0xFF;
			r1 = Z80Reg(r1>>8);
		case Z80_I:		case Z80_R:		case Z80_A:		case Z80_MEM_HL:
		case Z80_B:		case Z80_C:		case Z80_D:		case Z80_E:		case Z80_H:		case Z80_L:
			break;
		case Z80_IY:	case Z80_IX:
			prefix1 = r1;
			r1 = Z80_HL;
		case Z80_BC:	case Z80_DE:	case Z80_HL:	case Z80_SP:
			eightBit = false;
			break;
		default:		// destination is not simple valid register
			return false;
		}
		if (!comma(lp)) return true;	// resolved as error
		char* olp = lp;
		Z80Reg r2 = GetRegister(lp);
		switch (r2) {
		case Z80_IXH:	case Z80_IXL:	case Z80_IYH:	case Z80_IYL:
			if (!eightBit || Z80_MEM_HL == r1) return true; // invalid combination
			prefix2 = r2&0xFF;
			r2 = Z80Reg(r2>>8);
			break;
		case Z80_I:		case Z80_R:		// resolve specials early
			if (Z80_A != r1) return true; // invalid combination
			*e++ = 0xED;	*e++ = Z80_I == r2 ? 0x57 : 0x5F;
			return true;
		case Z80_MEM_HL:
			if (Z80_MEM_HL == r1 || prefix1) return true;	// (hl),(hl) is invalid, ixy,(hl) too
			if (Z80_BC == r1 || Z80_DE == r1) {				// ld bc|de,(hl) is possible fake ins.
				lp = olp;
				return false;
			}
		case Z80_A:
		case Z80_B:		case Z80_C:		case Z80_D:		case Z80_E:		case Z80_H:		case Z80_L:
			if (!eightBit) return true; // invalid combination
			break;
		case Z80_IY:	case Z80_IX:
			prefix2 = r2;
			r2 = Z80_HL;
		case Z80_BC:	case Z80_DE:
			if (!eightBit) break;		// ld r16, r16 -> resolve it
			if (Z80_MEM_HL == r1) lp = olp;	// ld (hl),bc|de are possible fake instructions
			return (Z80_MEM_HL != r1);	// other 8b vs 16b are invalid combinations
		case Z80_HL:
			if (!eightBit) break;		// ld r16, r16 -> resolve it
		case Z80_SP:	case Z80_AF: case Z80_F:
			return true;				// no simple "ld r,SP|AF|F" (all invalid)
		case Z80_UNK:		// source is not simple register
			lp = olp;
			return false;
		}
		//// r1 and r2 are now H/L/HL for IXH/IXL/../IX/IY (only prefix1/prefix2 holds IXY info)
		// resolve more specials early
		if (Z80_I == r1 || Z80_R == r1) {	// ld i,a | ld r,a
			if (Z80_A != r2) return true; // invalid combination
			*e++ = 0xED;	*e++ = Z80_I == r1 ? 0x47 : 0x4F;
			return true;
		}
		if (Z80_SP == r1) {					// ld sp,hl|ix|iy
			if (Z80_HL == r2) {
				if (prefix2) *e++ = prefix2;
				*e++ = 0xF9;
			}
			return true;
		}
		if (!eightBit) {					// all possible ld r16,r16 (are fakes)
			if (Options::noFakes()) return true;
			// ld ix,iy | ld iy,ix | ld hl,ixy | ld ixy,hl => push + pop
			if ((prefix1^prefix2) && (r1 == r2)) {
				if (prefix2) *e++ = prefix2;
				*e++ = 0xE5;
				if (prefix1) *e++ = prefix1;
				*e++ = 0xE1;
				return true;
			}
			// remaining standard "ld r16,r16"
			if (prefix2) prefix1 = prefix2;		// any non-zero prefix is relevant here
			if (prefix1) *e++ = prefix1;
			*e++ = GetRegister_r16High(r2) + GetRegister_r16High(r1)*8 + 0x40;
			if (prefix1) *e++ = prefix1;
			*e++ = GetRegister_r16Low(r2) + GetRegister_r16Low(r1)*8 + 0x40;
			return true;
		}
		// only eight bit simple "ld r8,r8" remains, but verify validity of IXY combinations
		if ((prefix1 != prefix2) && (Z80_H == r1 || Z80_L == r1) && (Z80_H == r2 || Z80_L == r2)) {
			return true;	// ld h|l|ixyhl,h|l|ixyhl is valid only when prefix1 == prefix2
		}
		if (prefix1) *e++ = prefix1;	// any non-zero prefix is relevant here
		else if (prefix2) *e++ = prefix2;
		*e++ = r2 + r1*8 + 0x40;
		return true;
	}

	void OpCode_LD() {
		int e[7];
		aint b;
		Z80Reg reg1, reg2;
		EBracketType bt;
		char* olp;

		do {
			reg2 = Z80_UNK;
			olp = nullptr;
			e[0] = e[1] = e[2] = e[3] = e[4] = e[5] = e[6] = -1;
			reg1 = GetRegister(lp);
			// resolve all register to register cases (no memory or constant)
			if (Z80_UNK != reg1 && LD_simple_r_r(e, reg1)) {	//but "(hl)" is sometimes like 8b register = resolved too
				EmitBytes(e);
				continue;
			}
			// memory, constant, fake instruction or syntax error is involved
			// (!!! comma is already parsed for all destination=register cases)
			switch (reg1) {
			case Z80_A:
				if (BT_NONE != (bt = OpenBracket(lp))) {
					switch (reg2 = GetRegister(lp)) {
					case Z80_BC:
					case Z80_DE:
						if (CloseBracket(lp)) e[0] = reg2-6;
						break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x46 + 8*reg1; e[2] = z80GetIDxoffset(lp);
						if (CloseBracket(lp)) e[0] = reg2;
						break;
					default:
						break;
					}
					if (Z80_UNK != reg2) break;	//"(register": emit instruction || bug
					// give non-register another chance to parse as value expression
					if (BT_ROUND == bt) olp = ParenthesesEnd(--lp);	// test-ptr for whole-expression-in-()
				}
				if (!ParseExpression(lp, b)) break;
				if (BT_SQUARE != bt && olp != lp) {	// LD a,imm8
					check8(b); e[0] = 0x06 + 8*reg1; e[1] = b & 255;
				} else {							// LD a,(mem8)
					if (BT_SQUARE == bt && !CloseBracket(lp)) break; // ")" is closed by ParseExpression
					check16(b); e[0] = 0x3a; e[1] = b & 255; e[2] = (b >> 8) & 255;
				}
				break;

			case Z80_B:
			case Z80_C:
			case Z80_D:
			case Z80_E:
			case Z80_H:
			case Z80_L:
				if (BT_NONE != (bt = OpenBracket(lp))) {
					switch (reg2 = GetRegister(lp)) {
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x46 + 8*reg1; e[2] = z80GetIDxoffset(lp);
						if (CloseBracket(lp)) e[0] = reg2;
						break;
					default:
						break;
					}
					// give non-register in "()" another chance to parse as value expression
					if (BT_ROUND == bt && Z80_UNK == reg2) --lp;
					else break;		// everything else is resolved (emit or bug)
				}
				e[0] = 0x06 + 8*reg1; e[1] = GetByte(lp);
				break;

			case Z80_MEM_HL:
				switch (reg2 = GetRegister(lp)) {
				case Z80_BC:
					if (Options::noFakes()) break;
					e[0] = 0x71; e[1] = 0x23; e[2] = 0x70; e[3] = 0x2b; break;
				case Z80_DE:
					if (Options::noFakes()) break;
					e[0] = 0x73; e[1] = 0x23; e[2] = 0x72; e[3] = 0x2b; break;
				case Z80_UNK:
					e[0] = 0x36; e[1] = GetByte(lp); break;
				default:
					break;
				}
				break;

			case Z80_IXH: case Z80_IXL: case Z80_IYH: case Z80_IYL:
				e[0] = reg1&0xFF; e[1] = 0x06 + 8*(reg1>>8); e[2] = GetByte(lp);
				break;

			case Z80_BC: case Z80_DE: case Z80_HL: case Z80_SP:
				if (BT_NONE != (bt = OpenBracket(lp))) {
					switch (reg2 = GetRegister(lp)) {
					case Z80_HL:	// invalid combinations filtered already by LD_simple_r_r
						if (Options::noFakes()) break;
						if (CloseBracket(lp)) e[0] = reg1+0x3e;
						e[1] = 0x23; e[2] = reg1+0x36; e[3] = 0x2b;
						break;
					case Z80_IX:	// invalid combinations NOT filtered -> validate
					case Z80_IY:
						if (Z80_SP == reg1 || Options::noFakes()) break;
						e[1] = reg1+0x3e; e[4] = reg1+0x36; e[2] = z80GetIDxoffset(lp); e[5] = e[2]+1;
						if (e[2] == 127) Error("Offset out of range");
						if (CloseBracket(lp)) e[0] = e[3] = reg2;
						break;
					default:
						break;
					}
					if (Z80_UNK != reg2) break;	//"(register": emit instruction || bug
					// give non-register another chance to parse as value expression
					if (BT_ROUND == bt) olp = ParenthesesEnd(--lp);	// test-ptr for whole-expression-in-()
				}
				b = GetWord(lp);
				if (BT_SQUARE != bt && olp != lp) {	// ld bc|de|hl|sp,imm16
					e[0] = reg1-0x0F; e[1] = b & 255; e[2] = (b >> 8) & 255;
				} else if (Z80_HL == reg1) {		// ld hl,(mem16)
					e[1] = b & 255; e[2] = (b >> 8) & 255;
					if (BT_ROUND == bt || CloseBracket(lp)) e[0] = 0x2a;	// round were closed by GetWord(..)
				} else {							// ld bc|de|sp,(mem16)
					e[1] = reg1+0x3b; e[2] = b & 255; e[3] = (b >> 8) & 255;
					if (BT_ROUND == bt || CloseBracket(lp)) e[0] = 0xed;	// round were closed by GetWord(..)
				}
				break;

			case Z80_IX:
			case Z80_IY:
				bt = OpenBracket(lp);
				if (BT_ROUND == bt) olp = ParenthesesEnd(--lp);	// test-ptr for whole-expression-in-()
				b = GetWord(lp);
				if (BT_SQUARE != bt && olp != lp) {	// ld ix|iy,imm16
					e[0] = reg1; e[1] = 0x21; e[2] = b & 255; e[3] = (b >> 8) & 255;
				} else {							// ld ix|iy,(mem16)
					e[1] = 0x2a; e[2] = b & 255; e[3] = (b >> 8) & 255;
					if (BT_ROUND == bt || CloseBracket(lp)) e[0] = reg1;	// round were closed by GetWord(..)
				}
				break;

			case Z80_UNK:
				if (BT_NONE == OpenBracket(lp)) break;
				reg1 = GetRegister(lp);
				if (Z80_IX == reg1 || Z80_IY == reg1) e[2] = z80GetIDxoffset(lp);
				if (Z80_UNK == reg1) b = GetWord(lp);
				if (!CloseBracket(lp) || !comma(lp)) break;
				reg2 = GetRegister(lp);
				switch (reg1) {
				case Z80_BC:
				case Z80_DE:
					if (Z80_A == reg2) e[0] = reg1-14;	// LD (bc|de),a
					break;
				case Z80_IX:
				case Z80_IY:
					switch (reg2) {
					case Z80_A:
					case Z80_B:
					case Z80_C:
					case Z80_D:
					case Z80_E:
					case Z80_H:
					case Z80_L:
						e[0] = reg1; e[1] = 0x70 + reg2; break;	// LD (ixy+#),r8
					case Z80_BC:
					case Z80_DE:
					case Z80_HL:
						if (Options::noFakes()) break;		//fake LD (ixy+#),r16
						if (e[2] == 127) Error("Offset out of range");
						e[0] = e[3] = reg1; e[1] = 0x70+GetRegister_r16Low(reg2);
						e[4] = 0x70+GetRegister_r16High(reg2); e[5] = e[2] + 1;
						break;
					case Z80_UNK:
						e[0] = reg1; e[1] = 0x36; e[3] = GetByte(lp);	// LD (ixy+#),imm8
						break;
					default:
						break;
					}
					break;
				case Z80_UNK:
					switch (reg2) {
					case Z80_A:		// LD (nnnn),a|hl
					case Z80_HL:
						e[0] = (Z80_A == reg2) ? 0x32 : 0x22; e[1] = b & 255; e[2] = (b >> 8) & 255; break;
					case Z80_BC:	// LD (nnnn),bc|de|sp
					case Z80_DE:
					case Z80_SP:
						e[0] = 0xed; e[1] = 0x33+reg2; e[2] = b & 255; e[3] = (b >> 8) & 255; break;
					case Z80_IX:	// LD (nnnn),ix|iy
					case Z80_IY:
						e[0] = reg2; e[1] = 0x22; e[2] = b & 255; e[3] = (b >> 8) & 255; break;
					default:
						break;
					}
					break;
				default:
					break;
				}
				break;
			default:
				break;
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	void OpCode_LDD() {
		Z80Reg reg, reg2;
		int e[7];

		if (Options::noFakes(false)) {
			e[0] = 0xed;
			e[1] = 0xa8;
			e[2] = -1;
			EmitBytes(e);
			return;
		}

		do {
			e[0] = e[1] = e[2] = e[3] = e[4] = e[5] = e[6] = -1;
				switch (reg = GetRegister(lp)) {
				case Z80_A:
					if (Options::noFakes() || !comma(lp)) break;
					if (BT_NONE == OpenBracket(lp)) break;
					switch (reg = GetRegister(lp)) {
					case Z80_BC:	// 0x0A 0x0B
					case Z80_DE:	// 0x1A 0x1B
						e[1] = reg-5; if (CloseBracket(lp)) e[0] = reg-6;
						break;
					case Z80_HL:	// 0x7E	0x2B
						e[1] = 0x2b; if (CloseBracket(lp)) e[0] = 0x7e;
						break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x7e; e[2] = z80GetIDxoffset(lp); e[4] = 0x2b;
						if (CloseBracket(lp)) e[0] = e[3] = reg;
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
					if (Options::noFakes() || !comma(lp)) break;
					if (BT_NONE == OpenBracket(lp)) break;
					switch (reg2 = GetRegister(lp)) {
					case Z80_HL:
						e[1] = 0x2b; if (CloseBracket(lp)) e[0] = 0x46 + reg * 8;
						break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x46 + reg * 8; e[2] = z80GetIDxoffset(lp); e[4] = 0x2b;
						if (CloseBracket(lp)) e[0] = e[3] = reg2;
						break;
					default:
						break;
					}
					break;
				case Z80_MEM_HL:
					if (Options::noFakes() || !comma(lp)) break;
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
				default:
					if (BT_NONE != OpenBracket(lp)) {
						if (Options::noFakes()) break;
						reg = GetRegister(lp);
						int ixy_delta = (reg == Z80_IX || reg == Z80_IY) ? z80GetIDxoffset(lp) : 0;
						if (!CloseBracket(lp) || !comma(lp)) break;
						switch (reg) {
						case Z80_BC:
						case Z80_DE:
							e[1] = reg - 5; if (GetRegister(lp) == Z80_A) e[0] = reg - 14;
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
								e[0] = e[3] = reg; e[2] = ixy_delta; e[1] = 0x70 + reg2; e[4] = 0x2b; break;
							case Z80_UNK:
								e[0] = e[4] = reg; e[1] = 0x36; e[2] = ixy_delta; e[3] = GetByte(lp); e[5] = 0x2b; break;
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
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	void OpCode_LDDR() {
		EmitByte(0xED);
		EmitByte(0xB8);
	}

	void OpCode_Next_LDDRX() {
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
		EmitByte(0xED);
		EmitByte(0xBC);
	}

	void OpCode_Next_LDDX() {
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
		EmitByte(0xED);
		EmitByte(0xAC);
	}

	void OpCode_LDI() {
		Z80Reg reg, reg2;
		int e[11];

		if (Options::noFakes(false)) {
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
					if (Options::noFakes() || !comma(lp)) break;
					if (BT_NONE == OpenBracket(lp)) break;
					switch (reg = GetRegister(lp)) {
					case Z80_BC:	// 0A 03
					case Z80_DE:	// 1A 13
						if (CloseBracket(lp)) e[0] = reg - Z80_BC + 0x0a;
						e[1] = reg - Z80_BC + 0x03;
						break;
					case Z80_HL:
						e[1] = 0x23; if (CloseBracket(lp)) e[0] = 0x7e;
						break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x7e; e[4] = 0x23; e[2] = z80GetIDxoffset(lp);
						if (CloseBracket(lp)) e[0] = e[3] = reg;
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
					if (Options::noFakes() || !comma(lp)) break;
					if (BT_NONE == OpenBracket(lp)) break;
					switch (reg2 = GetRegister(lp)) {
					case Z80_HL:
						e[1] = 0x23; if (CloseBracket(lp)) e[0] = 0x46 + reg * 8;
						break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x46 + reg * 8; e[4] = 0x23; e[2] = z80GetIDxoffset(lp);
						if (CloseBracket(lp)) e[0] = e[3] = reg2;
						break;
					default:
						break;
					}
					break;
				case Z80_BC:
					if (Options::noFakes() || !comma(lp)) break;
					if (BT_NONE == OpenBracket(lp)) break;
					switch (reg = GetRegister(lp)) {
					case Z80_HL:
						e[1] = e[3] = 0x23; e[2] = 0x46; if (CloseBracket(lp)) e[0] = 0x4e;
						break;
					case Z80_IX:
					case Z80_IY:
						e[2] = e[7] = z80GetIDxoffset(lp);
						if (CloseBracket(lp)) e[0] = e[3] = e[5] = e[8] = reg;
						e[1] = 0x4e; e[6] = 0x46; e[4] = e[9] = 0x23;
						break;
					default:
						break;
					}
					break;
				case Z80_DE:
					if (Options::noFakes() || !comma(lp)) break;
					if (BT_NONE == OpenBracket(lp)) break;
					switch (reg = GetRegister(lp)) {
					case Z80_HL:
						e[1] = e[3] = 0x23; e[2] = 0x56; if (CloseBracket(lp)) e[0] = 0x5e;
						break;
					case Z80_IX:
					case Z80_IY:
						e[2] = e[7] = z80GetIDxoffset(lp);
						if (CloseBracket(lp)) e[0] = e[3] = e[5] = e[8] = reg;
						e[1] = 0x5e; e[6] = 0x56; e[4] = e[9] = 0x23;
						break;
					default:
						break;
					}
					break;
				case Z80_HL:
					if (Options::noFakes() || !comma(lp)) break;
					if (BT_NONE == OpenBracket(lp)) break;
					switch (reg = GetRegister(lp)) {
					case Z80_IX:
					case Z80_IY:
						e[2] = e[7] = z80GetIDxoffset(lp);
						if (!CloseBracket(lp)) break;
						e[0] = e[3] = e[5] = e[8] = reg;
						e[1] = 0x6e; e[6] = 0x66; e[4] = e[9] = 0x23;
						break;
					default:
						break;
					}
					break;
				case Z80_MEM_HL:
					if (Options::noFakes() || !comma(lp)) break;
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
				default:
					if (BT_NONE != OpenBracket(lp)) {
						if (Options::noFakes()) break;
						reg = GetRegister(lp);
						int ixy_delta = (reg == Z80_IX || reg == Z80_IY) ? z80GetIDxoffset(lp) : 0;
						if (!CloseBracket(lp) || !comma(lp)) break;
						switch (reg) {
						case Z80_BC:
						case Z80_DE:
							e[1] = reg - 13; if (GetRegister(lp) == Z80_A) e[0] = reg - 14;
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
								e[0] = e[3] = reg; e[2] = ixy_delta; e[1] = 0x70 + reg2; e[4] = 0x23; break;
							case Z80_BC:
								e[0] = e[3] = e[5] = e[8] = reg; e[1] = 0x71; e[6] = 0x70; e[4] = e[9] = 0x23; e[2] = e[7] = ixy_delta; break;
							case Z80_DE:
								e[0] = e[3] = e[5] = e[8] = reg; e[1] = 0x73; e[6] = 0x72; e[4] = e[9] = 0x23; e[2] = e[7] = ixy_delta; break;
							case Z80_HL:
								e[0] = e[3] = e[5] = e[8] = reg; e[1] = 0x75; e[6] = 0x74; e[4] = e[9] = 0x23; e[2] = e[7] = ixy_delta; break;
							case Z80_UNK:
								e[0] = e[4] = reg; e[1] = 0x36; e[2] = ixy_delta; e[3] = GetByte(lp); e[5] = 0x23; break;
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
		} while (Options::syx.MultiArg(lp));
	}

	void OpCode_LDIR() {
		EmitByte(0xED);
		EmitByte(0xB0);
	}

// LDIRSCALE is now very unlikely to happen, there's ~1% chance it may be introduced within the cased-Next release
// 	void OpCode_Next_LDIRSCALE() {
// 		if (Options::syx.IsNextEnabled < 1) {
// 			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
// 			return;
// 		}
// 		EmitByte(0xED);
// 		EmitByte(0xB6);
// 	}

	void OpCode_Next_LDIRX() {
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
		EmitByte(0xED);
		EmitByte(0xB4);
	}

	void OpCode_Next_LDIX() {
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
		EmitByte(0xED);
		EmitByte(0xA4);
	}

	void OpCode_Next_LDPIRX() {
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
		EmitByte(0xED);
		EmitByte(0xB7);
	}

	void OpCode_Next_LDWS() {
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
		EmitByte(0xED);
		EmitByte(0xA5);
	}

	void OpCode_Next_MIRROR() {
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
		Z80Reg reg = GetRegister(lp);
		if (Z80_UNK != reg && Z80_A != reg) {
			Error("[MIRROR] Illegal operand (can be only register A)", line);
			return;
		}
		EmitByte(0xED);
		EmitByte(0x24);
	}

	void OpCode_Next_MUL() {
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
		int e[3] { -1, -1, -1 };
		Z80Reg r1 = GetRegister(lp);
		if (Z80_UNK == r1 && SkipBlanks(lp) && !Options::noFakes()) {
			r1 = Z80_DE;	// "mul" without arguments is treated as "fake" "mul de"
		}
		// "mul de" and "mul d,e" are both valid syntax options
		if ((Z80_DE==r1) || (Z80_D==r1 && comma(lp) && Z80_E==GetRegister(lp))) {
			e[0]=0xED;
			e[1]=0x30;
		} else {
			Error("Z80N MUL exist only with \"D,E\" arguments", bp, SUPPRESS);
			return;
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
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
		Z80Reg reg;
		int e[5];
		do {
			e[0] = e[1] = e[2] = e[3] = e[4] = -1;
			// is operand1 register? (to give more precise error message to people using wrong `nextreg a,$nn`)
			reg = GetRegister(lp);
			if (Z80_UNK != reg) {
				Error("[NEXTREG] first operand should be register number", line, SUPPRESS); break;
			}
			// this code would be enough to get correct assembling, the test above is "extra"
			e[2] = GetByte(lp);
			if (!comma(lp)) {
				Error("[NEXTREG] Comma expected"); break;
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
		} while (Options::syx.MultiArg(lp));
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
				if (!nonMaComma(lp)) {	// "OR a,b" is possible only when multi-arg is not-comma
					e[0] = 0xb7;
					break;
				}
				reg = GetRegister(lp);
			default:
				switch (reg) {
				case Z80_IXH: case Z80_IXL: case Z80_IYH: case Z80_IYL:
					e[0] = reg&0xFF; e[1] = 0xb0 + (reg>>8); break;
				case Z80_B: case Z80_C: case Z80_D: case Z80_E:
				case Z80_H: case Z80_L: case Z80_MEM_HL: case Z80_A:
					e[0] = 0xb0 + reg; break;
				case Z80_UNK:
					if (BT_NONE != (bt = OpenBracket(lp))) {
						switch (reg = GetRegister(lp)) {
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
					break;
				default:
					break;
				}
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
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
			if (BT_NONE != OpenBracket(lp)) {
				if (GetRegister(lp) == Z80_C) {
					if (CloseBracket(lp) && comma(lp)) {
						switch (reg = GetRegister(lp)) {
						case Z80_B: case Z80_C: case Z80_D: case Z80_E: case Z80_H: case Z80_L: case Z80_A:
							e[0] = 0xed; e[1] = 0x41 + 8 * reg; break;
						case Z80_UNK:
							if (0 == GetByte(lp)) e[0] = 0xed;	// out (c),0
							e[1] = 0x71; break;
						default:
							break;
						}
					}
				} else {
					e[1] = GetByte(lp);		// out ($n),a
					if (CloseBracket(lp) && comma(lp) && GetRegister(lp) == Z80_A) e[0] = 0xd3;
				}
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
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
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
		EmitByte(0xED);
		EmitByte(0x90);
	}

	void OpCode_Next_PIXELAD() {
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
		char *oldLp = lp;
		if (Z80_HL != GetRegister(lp)) lp = oldLp;		// "eat" explicit HL argument
		EmitByte(0xED);
		EmitByte(0x94);
	}

	void OpCode_Next_PIXELDN() {
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
		char *oldLp = lp;
		if (Z80_HL != GetRegister(lp)) lp = oldLp;		// "eat" explicit HL argument
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
		} while (c && 2 <= t && Options::syx.MultiArg(lp));
		EmitBytes(&e[t]);
	}

	void OpCode_POPnormal() {
		Z80Reg reg;
		do {
			int e[3];
			e[0] = e[1] = e[2] = -1;
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
		} while (Options::syx.MultiArg(lp));
	}

	void OpCode_POP() {
		if (Options::syx.IsReversePOP) OpCode_POPreverse();
		else OpCode_POPnormal();
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
				if(!Options::syx.IsNextEnabled) break;
				int imm16 = GetWord(lp);
				e[0] = 0xED; e[1] = 0x8A;
				e[2] = (imm16 >> 8) & 255;  // push opcode is big-endian!
				e[3] = imm16 & 255;
			}
			default:
				break;
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
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
			case Z80_B: case Z80_C: case Z80_D: case Z80_E:
			case Z80_H: case Z80_L: case Z80_MEM_HL: case Z80_A:
				e[0] = 0xcb; e[1] = 8 * bit + 0x80 + reg;
				break;
			default:
				if (BT_NONE == OpenBracket(lp)) break;
				switch (reg = GetRegister(lp)) {
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 8 * bit + 0x86;
					if (CloseBracket(lp)) e[0] = reg;
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
							Error("[RES] Illegal operand", line);
						}
					}
					break;
				default:
					;
				}
			}
			if (bit < 0 || bit > 7) e[0] = -1;
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
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
			case Z80_B: case Z80_C: case Z80_D: case Z80_E:
			case Z80_H: case Z80_L: case Z80_MEM_HL: case Z80_A:
				e[0] = 0xcb;
				e[1] = 0x10 + reg;
				break;
			case Z80_BC:
				if (Options::noFakes()) break;
				e[0] = e[2] = 0xcb;
				e[1] = 0x11;
				e[3] = 0x10;
				break;
			case Z80_DE:
				if (Options::noFakes()) break;
				e[0] = e[2] = 0xcb;
				e[1] = 0x13;
				e[3] = 0x12;
				break;
			case Z80_HL:
				if (Options::noFakes()) break;
				e[0] = e[2] = 0xcb;
				e[1] = 0x15;
				e[3] = 0x14;
				break;
			default:
				if (BT_NONE == OpenBracket(lp)) break;
				switch (reg = GetRegister(lp)) {
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 0x16;
					if (CloseBracket(lp)) e[0] = reg;
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
							Error("[RL] Illegal operand", line);
						}
					}
					break;
				default:
					;
				}
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
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
			case Z80_B: case Z80_C: case Z80_D: case Z80_E:
			case Z80_H: case Z80_L: case Z80_MEM_HL: case Z80_A:
				e[0] = 0xcb; e[1] = 0x0 + reg;
				break;
			default:
				if (BT_NONE == OpenBracket(lp)) break;
				switch (reg = GetRegister(lp)) {
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 0x6;
					if (CloseBracket(lp)) e[0] = reg;
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
							Error("[RLC] Illegal operand", line);
						}
					}
					break;
				default:
					;
				}
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
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
			case Z80_B: case Z80_C: case Z80_D: case Z80_E:
			case Z80_H: case Z80_L: case Z80_MEM_HL: case Z80_A:
				e[0] = 0xcb; e[1] = 0x18 + reg ; break;
			case Z80_BC:
				if (Options::noFakes()) break;
				e[0] = e[2] = 0xcb; e[1] = 0x18; e[3] = 0x19; break;
			case Z80_DE:
				if (Options::noFakes()) break;
				e[0] = e[2] = 0xcb; e[1] = 0x1a; e[3] = 0x1b; break;
			case Z80_HL:
				if (Options::noFakes()) break;
				e[0] = e[2] = 0xcb; e[1] = 0x1c; e[3] = 0x1d; break;
			default:
				if (BT_NONE == OpenBracket(lp)) break;
				switch (reg = GetRegister(lp)) {
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 0x1e;
					if (CloseBracket(lp)) e[0] = reg;
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
							Error("[RR] Illegal operand", line);
						}
					}
					break;
				default:
					;
				}
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
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
			case Z80_B: case Z80_C: case Z80_D: case Z80_E:
			case Z80_H: case Z80_L: case Z80_MEM_HL: case Z80_A:
				e[0] = 0xcb; e[1] = 0x8 + reg ; break;
			default:
				if (BT_NONE == OpenBracket(lp)) break;
				switch (reg = GetRegister(lp)) {
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 0xe;
					if (CloseBracket(lp)) e[0] = reg;
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
							Error("[RRC] Illegal operand", line);
						}
					}
					break;
				default:
					;
				}
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
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
				Error("[RST] Illegal operand", line); SkipToEol(lp);
				return;
			} else {			// e == { $00, $08, $10, $18, $20, $28, $30, $38 }
				EmitByte(0xC7 + e);
			}
		} while (Options::syx.MultiArg(lp));
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
					Error("[SBC] Comma expected"); break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_BC: case Z80_DE: case Z80_HL: case Z80_SP:
					e[0] = 0xed; e[1] = 0x32 + reg; break;
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
				case Z80_IXH: case Z80_IXL: case Z80_IYH: case Z80_IYL:
					e[0] = reg&0xFF; e[1] = 0x98 + (reg>>8); break;
				case Z80_B: case Z80_C: case Z80_D: case Z80_E:
				case Z80_H: case Z80_L: case Z80_MEM_HL: case Z80_A:
					e[0] = 0x98 + reg; break;
				case Z80_UNK:
					if (BT_NONE != (bt = OpenBracket(lp))) {
						switch (reg = GetRegister(lp)) {
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
				default:
					break;
				}
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
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
			case Z80_B: case Z80_C: case Z80_D: case Z80_E:
			case Z80_H: case Z80_L: case Z80_MEM_HL: case Z80_A:
				e[0] = 0xcb; e[1] = 8 * bit + 0xc0 + reg ; break;
			default:
				if (BT_NONE == OpenBracket(lp)) break;
				switch (reg = GetRegister(lp)) {
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 8 * bit + 0xc6;
					if (CloseBracket(lp)) e[0] = reg;
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
							Error("[SET] Illegal operand", line);
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
		} while (Options::syx.MultiArg(lp));
	}

	void OpCode_Next_SETAE() {
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
		EmitByte(0xED);
		EmitByte(0x95);
	}

	void OpCode_SLA() {
		Z80Reg reg;
		int e[5];
		do {
			e[0] = e[1] = e[2] = e[3] = e[4] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_B: case Z80_C: case Z80_D: case Z80_E:
			case Z80_H: case Z80_L: case Z80_MEM_HL: case Z80_A:
				e[0] = 0xcb; e[1] = 0x20 + reg ; break;
			case Z80_BC:
				if (Options::noFakes()) break;
				e[0] = e[2] = 0xcb; e[1] = 0x21; e[3] = 0x10; break;
			case Z80_DE:
				if (Options::noFakes()) break;
				e[0] = e[2] = 0xcb; e[1] = 0x23; e[3] = 0x12; break;
			case Z80_HL:
				if (Options::noFakes()) break;
				e[0] = 0x29; break;
			default:
				if (BT_NONE == OpenBracket(lp)) break;
				switch (reg = GetRegister(lp)) {
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 0x26;
					if (CloseBracket(lp)) e[0] = reg;
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
							Error("[SLA] Illegal operand", line);
						}
					}
					break;
				default:
					;
				}
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	void OpCode_SLL() {
		Z80Reg reg;
		int e[5];
		do {
			e[0] = e[1] = e[2] = e[3] = e[4] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_B: case Z80_C: case Z80_D: case Z80_E:
			case Z80_H: case Z80_L: case Z80_MEM_HL: case Z80_A:
				e[0] = 0xcb; e[1] = 0x30 + reg ; break;
			case Z80_BC:
				if (Options::noFakes()) break;
				e[0] = e[2] = 0xcb; e[1] = 0x31; e[3] = 0x10; break;
			case Z80_DE:
				if (Options::noFakes()) break;
				e[0] = e[2] = 0xcb; e[1] = 0x33; e[3] = 0x12; break;
			case Z80_HL:
				if (Options::noFakes()) break;
				e[0] = e[2] = 0xcb; e[1] = 0x35; e[3] = 0x14; break;
			default:
				if (BT_NONE == OpenBracket(lp)) break;
				switch (reg = GetRegister(lp)) {
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 0x36;
					if (CloseBracket(lp)) e[0] = reg;
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
							Error("[SLL] Illegal operand", line);
						}
					}
					break;
				default:
					;
				}
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	void OpCode_SRA() {
		Z80Reg reg;
		int e[5];
		do {
			e[0] = e[1] = e[2] = e[3] = e[4] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_B: case Z80_C: case Z80_D: case Z80_E:
			case Z80_H: case Z80_L: case Z80_MEM_HL: case Z80_A:
				e[0] = 0xcb; e[1] = 0x28 + reg ; break;
			case Z80_BC:
				if (Options::noFakes()) break;
				e[0] = e[2] = 0xcb; e[1] = 0x28; e[3] = 0x19; break;
			case Z80_DE:
				if (Options::noFakes()) break;
				e[0] = e[2] = 0xcb; e[1] = 0x2a; e[3] = 0x1b; break;
			case Z80_HL:
				if (Options::noFakes()) break;
				e[0] = e[2] = 0xcb; e[1] = 0x2c; e[3] = 0x1d; break;
			default:
				if (BT_NONE == OpenBracket(lp)) break;
				switch (reg = GetRegister(lp)) {
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 0x2e;
					if (CloseBracket(lp)) e[0] = reg;
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
							Error("[SRA] Illegal operand", line);
						}
					}
					break;
				default:
					;
				}
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	void OpCode_SRL() {
		Z80Reg reg;
		int e[5];
		do {
			e[0] = e[1] = e[2] = e[3] = e[4] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_B: case Z80_C: case Z80_D: case Z80_E:
			case Z80_H: case Z80_L: case Z80_MEM_HL: case Z80_A:
				e[0] = 0xcb; e[1] = 0x38 + reg ; break;
			case Z80_BC:
				if (Options::noFakes()) break;
				e[0] = e[2] = 0xcb; e[1] = 0x38; e[3] = 0x19; break;
			case Z80_DE:
				if (Options::noFakes()) break;
				e[0] = e[2] = 0xcb; e[1] = 0x3a; e[3] = 0x1b; break;
			case Z80_HL:
				if (Options::noFakes()) break;
				e[0] = e[2] = 0xcb; e[1] = 0x3c; e[3] = 0x1d; break;
			default:
				if (BT_NONE == OpenBracket(lp)) break;
				switch (reg = GetRegister(lp)) {
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 0x3e;
					if (CloseBracket(lp)) e[0] = reg;
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
							Error("[SRL] Illegal operand", line);
						}
					}
					break;
				default:
					;
				}
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	void OpCode_SUB() {
		Z80Reg reg;
		EBracketType bt;
		int e[4];
		do {
			e[0] = e[1] = e[2] = e[3] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_HL:
				if (!comma(lp)) {
					Error("[SUB] Comma expected"); break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_BC: case Z80_DE: case Z80_HL: case Z80_SP:
					if (Options::noFakes()) break;
					e[0] = 0xb7; e[1] = 0xed; e[2] = 0x32+reg; break;
				default:;
				}
				break;
			case Z80_A:
				if (!nonMaComma(lp)) {	// "SUB a,b" is possible only when multi-arg is not-comma
					e[0] = 0x97;
					break;
				}
				reg = GetRegister(lp);
			default:
				switch (reg) {
				case Z80_IXH: case Z80_IXL: case Z80_IYH: case Z80_IYL:
					e[0] = reg&0xFF; e[1] = 0x90 + (reg>>8); break;
				case Z80_B: case Z80_C: case Z80_D: case Z80_E:
				case Z80_H: case Z80_L: case Z80_MEM_HL: case Z80_A:
					e[0] = 0x90 + reg; break;
				case Z80_UNK:
					if (BT_NONE != (bt = OpenBracket(lp))) {
						switch (reg = GetRegister(lp)) {
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
					break;
				default:
					break;
				}
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	//Swaps the high and low nibbles of the accumulator.
	void OpCode_Next_SWAPNIB() {
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
		Z80Reg reg = GetRegister(lp);
		if (Z80_UNK != reg && Z80_A != reg) {
			Error("[SWAPNIB] Illegal operand (can be only register A)", line);
			return;
		}
		EmitByte(0xED);
		EmitByte(0x23);
	}

	void OpCode_Next_TEST() {
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
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
				if (!nonMaComma(lp)) {	// "XOR a,b" is possible only when multi-arg is not-comma
					e[0] = 0xaf;
					break;
				}
				reg = GetRegister(lp);
			default:
				switch (reg) {
				case Z80_IXH: case Z80_IXL: case Z80_IYH: case Z80_IYL:
					e[0] = reg&0xFF; e[1] = 0xa8 + (reg>>8); break;
				case Z80_B: case Z80_C: case Z80_D: case Z80_E:
				case Z80_H: case Z80_L: case Z80_MEM_HL: case Z80_A:
					e[0] = 0xa8 + reg; break;
				case Z80_UNK:
					if (BT_NONE != (bt = OpenBracket(lp))) {
						switch (reg = GetRegister(lp)) {
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
				default:
					break;
				}
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
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
		OpCodeTable.Insert("pop", OpCode_POP);
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

		InitNextExtensions();
	}

	void InitNextExtensions() {
		static bool nextWasInitialized = false;
		if (!Options::syx.IsNextEnabled || nextWasInitialized) return;
		nextWasInitialized = true;
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
		// CSpect emulator extensions, fake instructions "exit" and "break"
		OpCodeTable.Insert("exit",		OpCode_Next_EXIT);
		OpCodeTable.Insert("break",		OpCode_Next_BREAK);
	}
} // eof namespace Z80


void InitCPU() {
	Z80::Init();
	InsertDirectives();
}
//eof z80.cpp
