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
		LR35902_MEM_HL_I = 0x22, LR35902_MEM_HL_D = 0x32,
		Z80_IX = 0xdd, Z80_IY = 0xfd, Z80_MEM_IX = Z80_IX|(Z80_MEM_HL<<8), Z80_MEM_IY = Z80_IY|(Z80_MEM_HL<<8),
		Z80_IXH = Z80_IX|(Z80_H<<8), Z80_IXL = Z80_IX|(Z80_L<<8),
		Z80_IYH = Z80_IY|(Z80_H<<8), Z80_IYL = Z80_IY|(Z80_L<<8), Z80_UNK = -1 };
	enum Z80Cond {	// also used to calculate instruction opcode, so do not edit values
		Z80C_NZ = 0x00, Z80C_Z  = 0x08, Z80C_NC = 0x10, Z80C_C = 0x18,
		Z80C_PO = 0x20, Z80C_PE = 0x28, Z80C_P  = 0x30, Z80C_M = 0x38, Z80C_UNK };

	static CFunctionTable OpCodeTable;

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

	static byte GetByte(char*& p, bool signedCheck = false) {
		aint val;
		if (!ParseExpression(p, val)) {
			Error("Operand expected", nullptr, IF_FIRST); return 0;
		}
		if (signedCheck) check8o(val);
		else check8(val);
		return val & 255;
	}

	static byte GetByteNoMem(char*& p, bool signedCheck = false) {
		if (0 == Options::syx.MemoryBrackets) return GetByte(p, signedCheck); // legacy behaviour => don't care
		aint val; char* const oldP = p;
		switch (ParseExpressionMemAccess(p, val)) {
		case 1:					// valid constant (not a memory access) => return value
			if (signedCheck) check8o(val);
			else check8(val);
			return val & 255;
		case 2:					// valid memory access => report error
			Error("Illegal instruction (can't access memory)", oldP);
			return 0;
		default:				// parsing failed, report syntax error
			Error("Operand expected", oldP, IF_FIRST);
			return 0;
		}
	}

	static word GetWord(char*& p) {
		aint val;
		if (!ParseExpression(p, val)) {
			Error("Operand expected", nullptr, IF_FIRST); return 0;
		}
		check16(val);
		return val & 65535;
	}

	static word GetWordNoMem(char*& p) {
		if (0 == Options::syx.MemoryBrackets) return GetWord(p); // legacy behaviour => don't care
		aint val; char* const oldP = p;
		switch (ParseExpressionMemAccess(p, val)) {
		case 1:					// valid constant (not a memory access) => return value
			check16(val);
			return val & 65535;
		case 2:					// valid memory access => report error
			Error("Illegal instruction (can't access memory)", oldP);
			return 0;
		default:				// parsing failed, report syntax error
			Error("Operand expected", oldP, IF_FIRST);
			return 0;
		}
	}

	static byte z80GetIDxoffset(char*& p) {
		aint val;
		char* pp = p;
		SkipBlanks(pp);
		if (')' == *pp || ']' == *pp) return 0;
		if (!ParseExpression(p, val)) {
			Error("Operand expected", nullptr, IF_FIRST); return 0;
		}
		check8o(val);
		return val & 255;
	}

	static int GetAddress(char*& p, aint& ad) {
		if (GetLocalLabelValue(p, ad) || ParseExpression(p, ad)) return 1;
		Error("Operand expected", nullptr, IF_FIRST);
		return (ad = 0);	// set "ad" to zero and return zero
	}

	static Z80Cond getz80cond_Z80(char*& p) {
		if (SkipBlanks(p)) return Z80C_UNK;	// EOL detected
		char * const pp = p;
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

	static Z80Cond getz80cond(char*& p) {
		if (!Options::IsLR35902) return getz80cond_Z80(p);
		// Sharp LR35902 has only nz|z|nc|c condition variants of ret|jp|jr|call
		char * const pp = p;
		Z80Cond cc = getz80cond_Z80(p);
		switch (cc) {
		case Z80C_NZ:	case Z80C_Z:
		case Z80C_NC:	case Z80C_C:
			return cc;
		default:
			p = pp;			// restore source ptr
			return Z80C_UNK;
		}
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

	static int GetRegister_lastIxyD = 0;	//z80GetIDxoffset(lp)

	// fast lookup table for single letters 'a'..'r' ('gjkmnopq' will produce Z80_UNK instantly)
	static Z80Reg r8[] {
		// a   b      c      d      e      f      g        h      i      j        k        l
		Z80_A, Z80_B, Z80_C, Z80_D, Z80_E, Z80_F, Z80_UNK, Z80_H, Z80_I, Z80_UNK, Z80_UNK, Z80_L,
		// m     n        o        p        q        r
		Z80_UNK, Z80_UNK, Z80_UNK, Z80_UNK, Z80_UNK, Z80_R
	};

	static Z80Reg GetRegister(char*& p) {
		const bool nonZ80CPU = Options::IsI8080 || Options::IsLR35902;
		char* pp = p;
		SkipBlanks(p);
		// adjust the single letter look-up-table by current options (CPU modes and syntax modes)
		r8['m'-'a'] = Options::syx.Is_M_Memory ? Z80_MEM_HL : Z80_UNK;	// extra alias "M" for "(HL)" enabled?
		r8['i'-'a'] = nonZ80CPU ? Z80_UNK : Z80_I;	// i8080/LR35902 doesn't have I
		r8['r'-'a'] = nonZ80CPU ? Z80_UNK : Z80_R;	// i8080/LR35902 doesn't have R
		char oneLetter = p[0] | 0x20;		// force it lowercase, in case it's ASCII letter
		if ('a' <= oneLetter && oneLetter <= 'r' && !islabchar(p[1])) {
			const Z80Reg lutResult = r8[oneLetter - 'a'];
			if (Z80_UNK == lutResult) p = pp;	// not a register, restore "p"
			else ++p;	// reg8 found, advance pointer
			return lutResult;
		}
		// high/low operators can be used on register pair
		if (cmphstr(p, "high")) {
			const Z80Reg reg = GetRegister(p);
			if (Z80_UNK == reg) {
				p = pp;
				return Z80_UNK;
			}
			return GetRegister_r16High(reg);
		}
		if (cmphstr(p, "low")) {
			const Z80Reg reg = GetRegister(p);
			if (Z80_UNK == reg) {
				p = pp;
				return Z80_UNK;
			}
			return GetRegister_r16Low(reg);
		}
		// remaining two+ letter registers
		char memClose = 0;
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
			if (nonZ80CPU) break;
			if (GetRegister_pair(p, 'x')) return Z80_IXH;
			if (GetRegister_pair(p, 'y')) return Z80_IYH;
			break;
		case 'i':
			if (nonZ80CPU) break;
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
			if (nonZ80CPU) break;
			if (GetRegister_pair(p, 'h')) return Z80_IXH;
			if (GetRegister_pair(p, 'l')) return Z80_IXL;
			break;
		case 'y':
			if (nonZ80CPU) break;
			if (GetRegister_pair(p, 'h')) return Z80_IYH;
			if (GetRegister_pair(p, 'l')) return Z80_IYL;
			break;
		case 'l':
			if (nonZ80CPU) break;
			if (GetRegister_pair(p, 'x')) return Z80_IXL;
			if (GetRegister_pair(p, 'y')) return Z80_IYL;
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
			if (nonZ80CPU) break;
			if (GetRegister_pair(p, 'X')) return Z80_IXH;
			if (GetRegister_pair(p, 'Y')) return Z80_IYH;
			break;
		case 'I':
			if (nonZ80CPU) break;
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
			if (nonZ80CPU) break;
			if (GetRegister_pair(p, 'H')) return Z80_IXH;
			if (GetRegister_pair(p, 'L')) return Z80_IXL;
			break;
		case 'Y':
			if (nonZ80CPU) break;
			if (GetRegister_pair(p, 'H')) return Z80_IYH;
			if (GetRegister_pair(p, 'L')) return Z80_IYL;
			break;
		case 'L':
			if (nonZ80CPU) break;
			if (GetRegister_pair(p, 'X')) return Z80_IXL;
			if (GetRegister_pair(p, 'Y')) return Z80_IYL;
			break;
		case 'S':
			if (GetRegister_pair(p, 'P')) return Z80_SP;
			break;
		case '(': memClose = (2 != Options::syx.MemoryBrackets) ? ')' : 0;	break;
		case '[': memClose = ']'; break;
		default:	break;
		}
		if (memClose) {
			Z80Reg memReg = GetRegister(p);
			if (Options::IsLR35902 && Z80_HL == memReg) {
				if ('+' == *p) {
					memReg = LR35902_MEM_HL_I;
					++p;
				} else if ('-' == *p) {
					memReg = LR35902_MEM_HL_D;
					++p;
				}
			}
			if (Z80_IX == memReg || Z80_IY == memReg) GetRegister_lastIxyD = z80GetIDxoffset(p);
			SkipBlanks(p);
			if (memClose == *p++) {
				switch (memReg) {
				case Z80_HL:	return Z80_MEM_HL;
				case Z80_IX:	return Z80_MEM_IX;
				case Z80_IY:	return Z80_MEM_IY;
				case LR35902_MEM_HL_I:
				case LR35902_MEM_HL_D:
					return memReg;
				default: 		break;
				}
			}
		}
		p = pp;
		return Z80_UNK;
	}

	static bool CommonAluOpcode(const int opcodeBase, int* e, bool hasNonRegA = false, bool nonMultiArgComma = true) {
		Z80Reg reg;
		char* oldLp = lp;
		switch (reg = GetRegister(lp)) {
		case Z80_BC:	case Z80_DE:	case Z80_HL:	case Z80_IX:	case Z80_IY:
			if (hasNonRegA) lp = oldLp;	// try to parse it one more time if non-A variants exist
			return !hasNonRegA;			// invalid first register if only "A" is allowed
		case Z80_SP:
			if (Options::IsLR35902) lp = oldLp;
			return !Options::IsLR35902;	// LR35902 has "add sp,r8"
		case Z80_AF:	case Z80_I:		case Z80_R:		case Z80_F:
		case LR35902_MEM_HL_I:	case LR35902_MEM_HL_D:
			return true;				// invalid first register
		case Z80_A:		// deal with optional shortened/prolonged form "add a" vs "and a,a", etc..
			if (nonMultiArgComma) {	// "AND|SUB|... a,b" is possible only when multi-arg is not-comma
				if (nonMaComma(lp)) reg = GetRegister(lp);
			} else {
				if (comma(lp)) reg = GetRegister(lp);
			}
		default:
			// with optional "a," dealt with, do the argument recognition and machine code emitting
			switch (reg) {
			case Z80_IXH: case Z80_IXL: case Z80_IYH: case Z80_IYL: case Z80_MEM_IX: case Z80_MEM_IY:
				*e++ = reg&0xFF;		// add prefix
				reg = Z80Reg(reg>>8);	// convert reg into H, L or MEM_HL and continue
				if (Z80_MEM_HL == reg) e[1] = GetRegister_lastIxyD;	// add "+d" byte for (ixy+d)
			case Z80_B: case Z80_C: case Z80_D: case Z80_E:
			case Z80_H: case Z80_L: case Z80_MEM_HL: case Z80_A:
				e[0] = opcodeBase + reg;
				return true;			// successfully assembled
			case Z80_UNK:
				e[0] = opcodeBase + 0x46; e[1] = GetByteNoMem(lp);	// imm8 variants
				return true;
			default:
				break;
			}
		}
		return true;
	}

	// returns "Z80_A" when successfully finished, otherwise returns result of "GetRegister(lp)"
	static Z80Reg OpCode_CbFamily(const int baseOpcode, int* e, bool canHaveDstRegForIxy = true) {
		Z80Reg reg;
		switch (reg = GetRegister(lp)) {
		case Z80_B: case Z80_C: case Z80_D: case Z80_E:
		case Z80_H: case Z80_L: case Z80_MEM_HL: case Z80_A:
			e[0] = 0xcb; e[1] = baseOpcode + reg;
			return Z80_A;
		case Z80_MEM_IX: case Z80_MEM_IY:
			e[0] = reg&0xFF; e[1] = 0xcb; e[2] = GetRegister_lastIxyD; e[3] = baseOpcode + (reg>>8);
			if (canHaveDstRegForIxy && comma(lp)) {
				switch (reg = GetRegister(lp)) {
				case Z80_B: case Z80_C: case Z80_D: case Z80_E: case Z80_H: case Z80_L: case Z80_A:
					e[3] = baseOpcode + reg;
					break;
				default:
					Error("Illegal destination register", line);
				}
			}
			return Z80_A;
		default: break;
		}
		return reg;
	}

	static void OpCode_ADC() {
		const bool nonZ80CPU = Options::IsI8080 || Options::IsLR35902;
		Z80Reg reg;
		do {
			int e[] { -1, -1, -1, -1 };
			if (!CommonAluOpcode(0x88, e, true, false)) {	// handle common 8-bit variants
				if ((!nonZ80CPU) && (Z80_HL == GetRegister(lp))) {
					if (!comma(lp)) {
						Error("[ADC] Comma expected");
					} else {
						switch (reg = GetRegister(lp)) {
						case Z80_BC:	case Z80_DE:	case Z80_HL:	case Z80_SP:
							e[0] = 0xed; e[1] = 0x4a + reg - Z80_BC; break;
						default: break;
						}
					}
				}
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_ADD() {
		Z80Reg reg, reg2;
		do {
			int e[] { -1, -1, -1, -1, -1 };
			if (!CommonAluOpcode(0x80, e, true, false)) {	// handle common 8-bit variants
				// add hl|ixy|bc|de|sp,... variants
				reg = GetRegister(lp);	if (Z80_UNK == reg) break;
				if (!comma(lp)) {
					Error("[ADD] Comma expected");
					break;
				}
				reg2 = GetRegister(lp);
				switch (reg) {
				case Z80_HL:
					switch (reg2) {
					case Z80_BC:	case Z80_DE:	case Z80_HL:	case Z80_SP:
						e[0] = 0x09 + reg2 - Z80_BC; break;
					case Z80_A:
						if(!Options::syx.IsNextEnabled) break;
						e[0] = 0xED; e[1] = 0x31; break;
					default:
						if(!Options::syx.IsNextEnabled) break;
						word b = GetWordNoMem(lp);
						e[0] = 0xED; e[1] = 0x34 ;
						e[2] = b & 255; e[3] = (b >> 8);
						break;
					}
					break;
				case Z80_IX:
				case Z80_IY:
					switch (reg2) {
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
				case Z80_DE:
				case Z80_BC:
					if (!Options::syx.IsNextEnabled) break;   // DE|BC is valid first operand only for Z80N
					if (Z80_A == reg2) {
						e[0] = 0xED; e[1] = 0x32 + (Z80_BC == reg);
					} else if (Z80_UNK == reg2) {
						word b = GetWordNoMem(lp);
						e[0] = 0xED; e[1] = 0x35 + (Z80_BC == reg);
						e[2] = b & 255; e[3] = (b >> 8);
					}
					break;
				case Z80_SP:			// Sharp LR35902 "add sp,r8"
					if (!Options::IsLR35902 || Z80_UNK != reg2) break;
					e[0] = 0xE8;
					e[1] = GetByteNoMem(lp, true);
					break;
				default:	break;		// unreachable (already validated by `CommonAluOpcode` call)
				}
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_AND() {
		do {
			int e[] { -1, -1, -1, -1};
			CommonAluOpcode(0xa0, e);
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_BIT() {
		do {
			int e[] { -1, -1, -1, -1, -1 };
			byte bit = GetByteNoMem(lp);
			if (comma(lp) && bit <= 7) OpCode_CbFamily(8 * bit + 0x40, e, false);
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_Next_BREAK() {	// this is fake instruction for CSpect emulator, not for real Z80N
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
		int e[] { -1, -1, -1 };
		// verify the operands are "de,b" (only valid ones)
		if (Z80_DE == GetRegister(lp) && comma(lp) && Z80_B == GetRegister(lp)) {
			e[0]=0xED;
			e[1]=mainOpcode;
		} else {
			Error("Z80N barrel shifts exist only with \"DE,B\" arguments", bp, SUPPRESS);
		}
		EmitBytes(e);
	}

	static void OpCode_Next_BRLC() {
		OpCode_Z80N_BarrelShifts(0x2C);
	}

	static void OpCode_Next_BSLA() {
		OpCode_Z80N_BarrelShifts(0x28);
	}

	static void OpCode_Next_BSRA() {
		OpCode_Z80N_BarrelShifts(0x29);
	}

	static void OpCode_Next_BSRF() {
		OpCode_Z80N_BarrelShifts(0x2B);
	}

	static void OpCode_Next_BSRL() {
		OpCode_Z80N_BarrelShifts(0x2A);
	}

	static void OpCode_CALL() {
		do {
			int e[] { -1, -1, -1, -1 };
			Z80Cond cc = getz80cond(lp);
			if (Z80C_UNK == cc) {
				e[0] = 0xcd;
			} else if (comma(lp)) {
				e[0] = 0xC4 + cc;
			} else {
				Error("[CALL cc] Comma expected", bp);
			}
			// UNK != cc + no-comma leaves e[0] == -1 (invalid instruction)
			aint callad;
			GetAddress(lp, callad);
			check16(callad);
			e[1] = callad & 255; e[2] = (callad >> 8) & 255;
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_CCF() {
		EmitByte(0x3f);
	}

	static void OpCode_CP() {
		do {
			int e[] { -1, -1, -1, -1};
			CommonAluOpcode(0xb8, e);
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_CPD() {
		EmitByte(0xED);
		EmitByte(0xA9);
	}

	static void OpCode_CPDR() {
		EmitByte(0xED);
		EmitByte(0xB9);
	}

	static void OpCode_CPI() {
		EmitByte(0xED);
		EmitByte(0xA1);
	}

	static void OpCode_CPIR() {
		EmitByte(0xED);
		EmitByte(0xB1);
	}

	static void OpCode_CPL() {
		EmitByte(0x2f);
	}

	static void OpCode_DAA() {
		EmitByte(0x27);
	}

	static void OpCode_DecInc(const int base8bOpcode, const int base16bOpcode, int* e) {
		Z80Reg reg;
		switch (reg = GetRegister(lp)) {
		case Z80_MEM_IX: case Z80_MEM_IY:
			e[2] = GetRegister_lastIxyD;	// set up the +d byte and fallthrough for other bytes
		case Z80_IXH: case Z80_IXL: case Z80_IYH: case Z80_IYL:
			*e++ = reg&0xFF;	reg = Z80Reg(reg>>8);
		case Z80_B: case Z80_C: case Z80_D: case Z80_E:
		case Z80_H: case Z80_L: case Z80_MEM_HL: case Z80_A:
			*e++ = base8bOpcode + 8 * reg;
			break;
		case Z80_IX: case Z80_IY:
			*e++ = reg;	reg = Z80_HL;
		case Z80_BC: case Z80_DE: case Z80_HL: case Z80_SP:
			*e++ = base16bOpcode + reg - Z80_BC;
			break;
		default:
			break;
		}
	}

	static void OpCode_DEC() {
		do {
			int e[] { -1, -1, -1, -1 };
			OpCode_DecInc(0x05, 0x0B, e);
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_DI() {
		EmitByte(0xf3);
	}

	static void OpCode_DJNZ() {
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
			e[0] = 0x10; e[1] = jmp & 0xFF;
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_EI() {
		EmitByte(0xfb);
	}

	static void OpCode_EX() {
		int e[] { -1, -1, -1, -1 };
		Z80Reg reg = GetRegister(lp);
		switch (reg) {
		case Z80_AF:
			if (Options::IsI8080) break;
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

	static void OpCode_EXA() {
		EmitByte(0x08);
	}

	static void OpCode_EXD() {
		EmitByte(0xeb);
	}

	static void OpCode_Next_EXIT() {	// this is fake instruction for CSpect emulator, not for real Z80N
		if (Options::syx.IsNextEnabled < 2) {
			Error("[EXIT] fake instruction \"exit\" must be specifically enabled by --zxnext=cspect option");
			return;
		}
		EmitByte(0xDD);
		EmitByte(0x00);
	}

	static void OpCode_EXX() {
		EmitByte(0xd9);
	}

	static void OpCode_HALT() {
		EmitByte(0x76);
	}

	static void OpCode_IM() {
		int e[] { -1, -1, -1 }, machineCode[] { 0x46, 0x56, 0x5e };
		byte mode = GetByteNoMem(lp);
		if (mode <= 2) {
			e[0] = 0xed;
			e[1] = machineCode[mode];
		}
		EmitBytes(e);
	}

	static void OpCode_IN() {
		do {
			int e[] { -1, -1, -1 };
			Z80Reg reg = GetRegister(lp);
			if (Z80_UNK == reg || comma(lp)) {
				if (Z80_UNK == reg) reg = Z80_F;	// if there was no register, it may be "IN (C)"
				if ((!Options::IsI8080) && NeedIoC()) {
					e[0] = 0xed;
					switch (reg) {
						case Z80_B: case Z80_C: case Z80_D: case Z80_E: case Z80_H: case Z80_L: case Z80_A:
							e[1] = 0x40 + reg*8;	// regular IN reg,(C)
							break;
						case Z80_F:
							e[1] = 0x70;			// unofficial IN F,(C)
							break;
						default:
							e[0] = -1;				// invalid combination
							break;
					}
				} else {
					e[1] = GetByte(lp);
					if (Z80_A == reg) e[0] = 0xdb;	// IN A,(n)
				}
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_INC() {
		do {
			int e[] { -1, -1, -1, -1 };
			OpCode_DecInc(0x04, 0x03, e);
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_IND() {
		EmitByte(0xED);
		EmitByte(0xAA);
	}

	static void OpCode_INDR() {
		EmitByte(0xED);
		EmitByte(0xBA);
	}

	static void OpCode_INI() {
		EmitByte(0xED);
		EmitByte(0xA2);
	}

	static void OpCode_INIR() {
		EmitByte(0xED);
		EmitByte(0xB2);
	}

	static void OpCode_INF() {
		EmitByte(0xED);
		EmitByte(0x70);
	}

	static void OpCode_JP() {
		do {
			int e[] { -1, -1, -1, -1 };
			Z80Reg reg = Z80_UNK;
			Z80Cond cc = getz80cond(lp);
			if (Z80C_UNK == cc) {	// no condition, check for: jp (hl),... and Z80N jp (c)
				char* expLp = lp;
				if (Options::syx.IsNextEnabled && NeedIoC()) {
					e[0] = 0xED; e[1] = 0x98;	// only "(C)" form with parentheses is legal syntax for Z80N "jp (C)"
					reg = Z80_C;	// suppress "jp imm16" parser
				} else {
					EBracketType bt = OpenBracket(lp);
					switch (reg = GetRegister(lp)) {
					case Z80_HL: case Z80_IX: case Z80_IY:
						if (BT_NONE != bt && !CloseBracket(lp)) break;	// check [optional] brackets
						e[0] = reg;
						e[Z80_IX <= reg] = 0xe9;	// e[1] for IX/IY, e[0] overwritten for HL/MEM_HL
						break;
					case Z80_MEM_HL: case Z80_MEM_IX: case Z80_MEM_IY:	// MEM_xx was handled manually, should NOT happen
						reg = Z80_UNK;				// try to treat it like expression in following code
					case Z80_UNK:
						if (BT_SQUARE == bt) break;	// "[" has no chance, report it
						if (BT_ROUND == bt) lp = expLp;	// give "(" another chance to evaluate as expression
						e[0] = 0xc3;				// jp imm16
						break;
					default:						// any other register is illegal
						break;
					}
				}
			} else {	// if (Z80C_UNK == cc)
				if (comma(lp)) e[0] = 0xC2 + cc;	// jp cc,imm16
				else Error("[JP cc] Comma expected", bp);
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

	static void OpCode_JR() {
		do {
			int e[] { -1, -1, -1, -1 };
			Z80Cond cc = getz80cond(lp);
			if (Z80C_UNK == cc) e[0] = 0x18;
			else if (cc <= Z80C_C) {
				if (comma(lp)) e[0] = 0x20 + cc;
				else Error("[JR cc] Comma expected", bp);
			} else {
				Error("[JR] Illegal condition", bp);
				SkipToEol(lp);
				break;
			}
			aint jrad=0;
			if (GetAddress(lp, jrad)) jrad -= CurAddress + 2;
			if (jrad < -128 || jrad > 127) {
				char el[LINEMAX];
				SPRINTF1(el, LINEMAX, "[JR] Target out of range (%+i)", jrad);
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
		case Z80_IXH:	case Z80_IXL:	case Z80_IYH:	case Z80_IYL:	case Z80_MEM_IX:	case Z80_MEM_IY:
			prefix1 = r1&0xFF;
			r1 = Z80Reg(r1>>8);
		case Z80_I:		case Z80_R:		case Z80_A:		case Z80_MEM_HL:
		case Z80_B:		case Z80_C:		case Z80_D:		case Z80_E:		case Z80_H:		case Z80_L:
		case LR35902_MEM_HL_I:	case LR35902_MEM_HL_D:
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
		case Z80_MEM_IX:	case Z80_MEM_IY:
			prefix2 = r2&0xFF;
			r2 = Z80Reg(r2>>8);			// ,(ixy+d) has same logic as ,(hl) => fallthrough
		case Z80_MEM_HL:
			if (Z80_MEM_HL == r1 || prefix1) return true;	// (hl),(hl) is invalid, ixy,(hl) too
			if (Z80_BC == r1 || Z80_DE == r1 || (Z80_HL == r1 && prefix2)) {
				lp = olp;
				return false;	// ld bc|de,(hl) is possible fake ins., ld hl,(ixy) is possible fake
			}
		case Z80_A:
		case Z80_B:		case Z80_C:		case Z80_D:		case Z80_E:		case Z80_H:		case Z80_L:
			if (!eightBit) return true; // invalid combination
			if (LR35902_MEM_HL_I == r1 || LR35902_MEM_HL_D == r1) {
				if (Z80_A == r2) *e = r1;	// `ld (hl+),a` or `ld (hl-),a`
				return true;
			}
			break;
		case Z80_IY:	case Z80_IX:
			prefix2 = r2;
			r2 = Z80_HL;
		case Z80_BC:	case Z80_DE:
			if (!eightBit) break;		// ld r16, r16 -> resolve it
			if (Z80_MEM_HL == r1) lp = olp;	// ld (hl),bc|de are possible fake instructions
			return (Z80_MEM_HL != r1);	// other 8b vs 16b are invalid combinations
		case Z80_HL:
			if (Z80_MEM_HL == r1 && prefix1) {
				lp = olp;
				return false;			// ld (ixy),hl is possible fake instruction
			}
			if (!eightBit) break;		// ld r16, r16 -> resolve it
		case Z80_SP:
			if (Options::IsLR35902 && Z80_HL == r1) {
				lp = olp;
				return false;			// LR35902 has "ld hl,sp+r8" syntax = check!
			}
			return true;				// no other "ld r,SP" is valid (on other CPUs)
		case Z80_AF: case Z80_F:
			return true;				// no simple "ld r,AF|F" (all invalid)
		case LR35902_MEM_HL_I:	case LR35902_MEM_HL_D:
			if (Z80_A == r1) *e = r2 + 0x08;
			return true;
		case Z80_UNK:		// source is not simple register
			lp = olp;
			return false;
		}
		//// r1 and r2 are now H/L/HL/MEM_HL for IXH/IXL/../IX/IY/MEM_IXY (only prefix1/prefix2 holds IXY info)
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
		if (prefix1|prefix2) {					// any non-zero prefix is relevant here
			if (Z80_MEM_HL == r1 || Z80_MEM_HL == r2) e[2] = GetRegister_lastIxyD;	// "+d" byte
			*e++ = prefix1|prefix2;
		}
		*e++ = r2 + r1*8 + 0x40;
		return true;
	}

	static void LD_LR35902(int *e, const Z80Reg r2, const aint a16) {
		// ld (a16),a|sp cases
		e[1] = a16 & 255;			// in any valid case this is correct
		if (Z80_A == r2 && 0xFF00 <= a16 && a16 <= 0xFFFF) {	// "ldh a,(a8)" auto-magic detection
			e[0] = 0xE0;
			return;
		}
		e[2] = (a16 >> 8) & 255;	// in any remaining valid case this is correct
		if (Z80_SP == r2) e[0] = 0x08;
		else if (Z80_A == r2) e[0] = 0xEA;
	}

	static void OpCode_LD() {
		aint b;
		EBracketType bt;
		do {
			int e[] { -1, -1, -1, -1, -1, -1, -1 }, pemaRes;
			Z80Reg reg2 = Z80_UNK, reg1 = GetRegister(lp);
			// resolve all register to register cases or fixed memory literals
			// "(hl)|(ixy+d)|(hl+)|(hl-)" (but not other memory or constant)
			if (Z80_UNK != reg1 && LD_simple_r_r(e, reg1)) {
				EmitBytes(e);
				continue;
			}
			// memory, constant, fake instruction or syntax error is involved
			// (!!! comma is already parsed for all destination=register cases)
			switch (reg1) {
			case Z80_A:
				if (BT_NONE != (bt = OpenBracket(lp))) {
					reg2 = GetRegister(lp);
					if ((Z80_BC == reg2 || Z80_DE == reg2) && CloseBracket(lp)) e[0] = reg2-6;
					else if (Z80_C == reg2 && Options::IsLR35902 && CloseBracket(lp)) {
						e[0] = 0xF2;	// Sharp LR35902 `ld a,(c)` (targetting [$ff00+c])
					}
					if (Z80_UNK != reg2) break;	//"(register": emit instruction || bug
					// give non-register another chance to parse as value expression
					--lp;
				}
				switch (ParseExpressionMemAccess(lp, b)) {
					// LD a,imm8
					case 1: check8(b); e[0] = 0x06 + 8*reg1; e[1] = b & 255; break;
					// LD a,(mem8)
					case 2:
						check16(b);
						if (Options::IsLR35902) {
							if (0xFF00 <= b && b <= 0xFFFF) {
								e[0] = 0xF0; e[1] = b & 255;
							} else {
								e[0] = 0xFA; e[1] = b & 255; e[2] = (b >> 8) & 255;
							}
							break;
						}
						e[0] = 0x3a; e[1] = b & 255; e[2] = (b >> 8) & 255;
						if (BT_ROUND == bt) checkLowMemory(e[2], e[1]);
						break;
				}
				break;

			case Z80_B: case Z80_C: case Z80_D: case Z80_E: case Z80_H: case Z80_L:
				e[0] = 0x06 + 8*reg1; e[1] = GetByteNoMem(lp);
				break;

			case Z80_MEM_HL:
				switch (reg2 = GetRegister(lp)) {
				case Z80_BC: case Z80_DE:
					if (Options::noFakes()) break;
					e[0] = 0x70 + GetRegister_r16Low(reg2); e[1] = 0x23;
					e[2] = 0x70 + GetRegister_r16High(reg2); e[3] = 0x2b; break;
				case Z80_UNK:
					e[0] = 0x36; e[1] = GetByteNoMem(lp); break;
				default:
					break;
				}
				break;

			case Z80_MEM_IX: case Z80_MEM_IY:
				e[2] = GetRegister_lastIxyD;
				switch (reg2 = GetRegister(lp)) {
				case Z80_BC: case Z80_DE: case Z80_HL:
					if (Options::noFakes()) break;		//fake LD (ixy+#),r16
					if (e[2] == 127) Error("Offset out of range", nullptr, IF_FIRST);
					e[0] = e[3] = reg1&0xFF; e[1] = 0x70+GetRegister_r16Low(reg2);
					e[4] = 0x70+GetRegister_r16High(reg2); e[5] = e[2] + 1;
					break;
				case Z80_UNK:
					e[0] = reg1&0xFF; e[1] = 0x36; e[3] = GetByteNoMem(lp);	// LD (ixy+#),imm8
				default:
					break;
				}
				break;

			case Z80_IXH: case Z80_IXL: case Z80_IYH: case Z80_IYL:
				e[0] = reg1&0xFF; e[1] = 0x06 + 8*(reg1>>8); e[2] = GetByteNoMem(lp);
				break;

			case Z80_BC: case Z80_DE: case Z80_HL: case Z80_SP:
				switch (reg2 = GetRegister(lp)) {
				case Z80_MEM_HL:	// invalid combinations filtered already by LD_simple_r_r
					if (Options::noFakes()) break;
					e[0] = reg1+0x3e; e[1] = 0x23; e[2] = reg1+0x36; e[3] = 0x2b;
					break;
				case Z80_MEM_IX: case Z80_MEM_IY:	// invalid combinations NOT filtered -> validate
					if (Z80_SP == reg1 || Options::noFakes()) break;
					e[1] = reg1+0x3e; e[4] = reg1+0x36; e[2] = GetRegister_lastIxyD; e[5] = e[2]+1;
					if (e[2] == 127) Error("Offset out of range", nullptr, IF_FIRST);
					else e[0] = e[3] = reg2&0xFF;
					break;
				case Z80_SP:
					if (Options::IsLR35902 && Z80_HL == reg1) {		// "ld hl,sp+r8" syntax = "F8 r8"
						b = 0;
						// "sp" must be followed by + or - (or nothing: "ld hl,sp" = +0)
						if (!SkipBlanks(lp) && ',' != *lp ) {		// comma is probably multi-arg
							if ('+' != *lp && '-' != *lp) {
								Error("[LD] `ld hl,sp+r8` expects + or - after sp, found", lp);
								break;
							}
							b = GetByteNoMem(lp, true);
						}
						e[0] = 0xF8;
						e[1] = b;
					}
					break;
				default:
					break;
				}
				if (Z80_UNK != reg2) break;	//"(register": emit instruction || bug
				switch (ParseExpressionMemAccess(lp, b)) {
					// ld bc|de|hl|sp,imm16
					case 1: check16(b); e[0] = reg1-0x0F; e[1] = b & 255; e[2] = (b >> 8) & 255; break;
					// LD r16,(mem16)
					case 2:
						if (Options::IsLR35902) break;	// no "ld r16,(a16)" instruction on LR35902
						check16(b);
						if (Z80_HL == reg1) {		// ld hl,(mem16)
							e[0] = 0x2a; e[1] = b & 255; e[2] = (b >> 8) & 255;
						} else {					// ld bc|de|sp,(mem16)
							if (Options::IsI8080) break;
							e[0] = 0xed; e[1] = reg1+0x3b; e[2] = b & 255; e[3] = (b >> 8) & 255;
						}
						if (')' == lp[-1]) checkLowMemory(b>>8, b);
				}
				break;

			case Z80_IX:
			case Z80_IY:
				if (0 < (pemaRes = ParseExpressionMemAccess(lp, b))) {
					e[0] = reg1; e[1] = (1 == pemaRes) ? 0x21 : 0x2a;	// ld ix|iy,imm16  ||  ld ix|iy,(mem16)
					check16(b); e[2] = b & 255; e[3] = (b >> 8) & 255;
					if ((2 == pemaRes) && ')' == lp[-1]) checkLowMemory(e[3], e[2]);
				}
				break;

			case Z80_UNK:
				if (BT_NONE == OpenBracket(lp)) break;
				reg1 = GetRegister(lp);
				if (Z80_UNK == reg1) b = GetWord(lp);
				if (!CloseBracket(lp) || !comma(lp)) break;
				reg2 = GetRegister(lp);
				switch (reg1) {
				case Z80_C:
					if (Options::IsLR35902 && Z80_A == reg2) {	// Sharp LR35902 `ld (c),a` (targetting [$ff00+c])
						e[0] = 0xE2;
					}
					break;
				case Z80_BC:
				case Z80_DE:
					if (Z80_A == reg2) e[0] = reg1-14;	// LD (bc|de),a
					break;
				case Z80_UNK:
					if (Options::IsLR35902) {	// Sharp LR35902 has quite different opcodes for these
						LD_LR35902(e, reg2, b);
						break;
					}
					// Standard Z80 and i8080 opcodes for ld (nn),reg
					switch (reg2) {
					case Z80_A:		// LD (nnnn),a|hl
					case Z80_HL:
						e[0] = (Z80_A == reg2) ? 0x32 : 0x22; e[1] = b & 255; e[2] = (b >> 8) & 255; break;
					case Z80_BC:	// LD (nnnn),bc|de|sp
					case Z80_DE:
					case Z80_SP:
						if (Options::IsI8080) break;
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

	static void OpCode_LR35902_LDD() {
		// ldd (hl),a = ld (hl-),a = 0x32
		// ldd a,(hl) = ld a,(hl-) = 0x3A
		do {
			int e[] { -1, -1 };
			const Z80Reg r1 = GetRegister(lp);
			const bool comma_ok = comma(lp);
			const Z80Reg r2 = comma_ok ? GetRegister(lp) : Z80_UNK;
			if (Z80_MEM_HL == r1 && Z80_A == r2) e[0] = 0x32;
			if (Z80_A == r1 && Z80_MEM_HL == r2) e[0] = 0x3A;
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_LDD() {
		if (Options::noFakes(false)) {
			EmitByte(0xED);
			EmitByte(0xA8);
			return;
		}

		// only when fakes are enabled (but they may be silent/warning enabled, so extra checks needed)
		do {
			int e[] { -1, -1, -1, -1, -1, -1, -1};
			Z80Reg reg2 = Z80_UNK, reg = GetRegister(lp);
			switch (reg) {
			case Z80_A:
				if (!comma(lp)) break;
				if (BT_NONE == OpenBracket(lp)) break;
				Options::noFakes();		// to display warning if "-f"
				switch (reg = GetRegister(lp)) {
				case Z80_BC:	// 0x0A 0x0B
				case Z80_DE:	// 0x1A 0x1B
					e[1] = reg-5; if (CloseBracket(lp)) e[0] = reg-6;
					break;
				case Z80_HL:	// 0x7E	0x2B
					e[1] = 0x2b; if (CloseBracket(lp)) e[0] = 0x7e;
					break;
				case Z80_IX: case Z80_IY:
					e[1] = 0x7e; e[2] = z80GetIDxoffset(lp); e[4] = 0x2b;
					if (CloseBracket(lp)) e[0] = e[3] = reg;
					break;
				default:
					break;
				}
				break;
			case Z80_B: case Z80_C: case Z80_D: case Z80_E: case Z80_H: case Z80_L:
				if (!comma(lp)) break;
				switch (reg2 = GetRegister(lp)) {
				case Z80_MEM_HL:
					Options::noFakes();		// to display warning if "-f"
					e[0] = 0x46 + reg * 8; e[1] = 0x2b;
					break;
				case Z80_MEM_IX: case Z80_MEM_IY:
					Options::noFakes();		// to display warning if "-f"
					e[0] = e[3] = reg2&0xFF; e[1] = 0x46 + reg * 8; e[2] = GetRegister_lastIxyD; e[4] = 0x2b;
					break;
				default:
					break;
				}
				break;
			case Z80_MEM_HL:
				if (!comma(lp)) break;
				switch (reg = GetRegister(lp)) {
				case Z80_A: case Z80_B: case Z80_C: case Z80_D: case Z80_E: case Z80_H: case Z80_L:
					Options::noFakes();		// to display warning if "-f"
					e[0] = 0x70 + reg; e[1] = 0x2b; break;
				case Z80_UNK:
					Options::noFakes();		// to display warning if "-f"
					e[0] = 0x36; e[1] = GetByteNoMem(lp); e[2] = 0x2b; break;
				default:
					break;
				}
				break;
			case Z80_MEM_IX: case Z80_MEM_IY:
				if (!comma(lp)) break;
				switch (reg2 = GetRegister(lp)) {
				case Z80_A: case Z80_B: case Z80_C: case Z80_D: case Z80_E: case Z80_H: case Z80_L:
					Options::noFakes();		// to display warning if "-f"
					e[0] = e[3] = reg&0xFF; e[2] = GetRegister_lastIxyD; e[1] = 0x70 + reg2; e[4] = 0x2b; break;
				case Z80_UNK:
					Options::noFakes();		// to display warning if "-f"
					e[0] = e[4] = reg&0xFF; e[1] = 0x36; e[2] = GetRegister_lastIxyD; e[3] = GetByteNoMem(lp); e[5] = 0x2b; break;
				default:
					break;
				}
				break;
			default:
				if (BT_NONE != OpenBracket(lp)) {
					reg = GetRegister(lp);
					if (!CloseBracket(lp) || !comma(lp)) break;
					if ((Z80_BC != reg && Z80_DE != reg) || Z80_A != GetRegister(lp)) break;
					Options::noFakes();		// to display warning if "-f"
					e[0] = reg - 14; e[1] = reg - 5;	// LDD (bc|de),a
				} else {
					e[0] = 0xed; e[1] = 0xa8;			// regular LDD
				}
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_LDDR() {
		EmitByte(0xED);
		EmitByte(0xB8);
	}

	static void OpCode_Next_LDDRX() {
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
		EmitByte(0xED);
		EmitByte(0xBC);
	}

	static void OpCode_Next_LDDX() {
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
		EmitByte(0xED);
		EmitByte(0xAC);
	}

	static void OpCode_LR35902_LDH() {
		// ldh (a8),a = ld ($FF00+a8),a = "E0 a8"
		// ldh a,(a8) = ld a,($FF00+a8) = "F0 a8"
		do {
			int e[] { -1, -1, -1 }, pemaRes = 0;
			aint a8 = -1;
			// parse two arguments, expected are "a,(n)" or "(n),a", others will fail in some stage
			const Z80Reg r1 = GetRegister(lp);
			if (Z80_UNK == r1) pemaRes = ParseExpressionMemAccess(lp, a8);
			const bool comma_ok = (Z80_A == r1 || 0 < pemaRes) && comma(lp);
			const Z80Reg r2 = comma_ok ? GetRegister(lp) : Z80_F;	// "F" as fail (UNK is legit result)
			if (Z80_UNK == r2 && Z80_A == r1) pemaRes = ParseExpressionMemAccess(lp, a8);
			else if (Z80_A != r2) pemaRes = 0;
			// here pemaRes must be non-zero when valid combination was parsed
			switch (pemaRes) {
				case 0:		// syntax error, or wrong registers combined with "ldh"
				case 1:		// immediate is also error, should have been memory
					Error("[LDH] only valid combinations: `ldh a,(a8)` or `ldh (a8),a`", lp, SUPPRESS);
					break;
				case 2:
					if (0xFF00 <= a8 && a8 <= 0xFFFF) a8 -= 0xFF00;	// normalize a8 if "ldh a,($FFxx)" was used
					check8(a8);
					e[0] = (Z80_A == r2) ? 0xE0 : 0xF0;
					e[1] = a8 & 0xFF;
					break;
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_LR35902_LDI() {
		// ldi (hl),a = ld (hl+),a = 0x22
		// ldi a,(hl) = ld a,(hl+) = 0x2A
		do {
			int e[] { -1, -1 };
			const Z80Reg r1 = GetRegister(lp);
			const bool comma_ok = comma(lp);
			const Z80Reg r2 = comma_ok ? GetRegister(lp) : Z80_UNK;
			if (Z80_MEM_HL == r1 && Z80_A == r2) e[0] = 0x22;
			if (Z80_A == r1 && Z80_MEM_HL == r2) e[0] = 0x2A;
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_LDI() {
		if (Options::noFakes(false)) {
			EmitByte(0xED);
			EmitByte(0xA0);
			return;
		}

		// only when fakes are enabled (but they may be silent/warning enabled, so extra checks needed)
		do {
			int e[] { -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 };
			Z80Reg reg2 = Z80_UNK, reg = GetRegister(lp);
			switch (reg) {
			case Z80_A:
				if (!comma(lp)) break;
				if (BT_NONE == OpenBracket(lp)) break;
				Options::noFakes();		// to display warning if "-f"
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
			case Z80_B: case Z80_C: case Z80_D: case Z80_E: case Z80_H: case Z80_L:
				if (!comma(lp)) break;
				if (BT_NONE == OpenBracket(lp)) break;
				Options::noFakes();		// to display warning if "-f"
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
			case Z80_BC: case Z80_DE: case Z80_HL:
				if (!comma(lp)) break;
				switch (reg2 = GetRegister(lp)) {
				case Z80_MEM_HL:
					if (Z80_HL == reg) break;
					Options::noFakes();		// to display warning if "-f"
					e[0] = 0x3e + reg; e[1] = e[3] = 0x23; e[2] = 0x36 + reg;
					break;
				case Z80_MEM_IX: case Z80_MEM_IY:
					Options::noFakes();		// to display warning if "-f"
					e[2] = e[7] = GetRegister_lastIxyD;
					e[0] = e[3] = e[5] = e[8] = reg2&0xFF;
					e[1] = 0x3e + reg; e[6] = 0x36 + reg; e[4] = e[9] = 0x23;
					break;
				default:
					break;
				}
				break;
			case Z80_MEM_HL:
				if (!comma(lp)) break;
				switch (reg = GetRegister(lp)) {
				case Z80_A: case Z80_B: case Z80_C: case Z80_D: case Z80_E: case Z80_H: case Z80_L:
					Options::noFakes();		// to display warning if "-f"
					e[0] = 0x70 + reg; e[1] = 0x23; break;
				case Z80_BC: case Z80_DE:
					Options::noFakes();		// to display warning if "-f"
					e[0] = 0x70 + GetRegister_r16Low(reg); e[2] = 0x70 + GetRegister_r16High(reg);
					e[1] = e[3] = 0x23; break;
				case Z80_UNK:
					Options::noFakes();		// to display warning if "-f"
					e[0] = 0x36; e[1] = GetByteNoMem(lp); e[2] = 0x23; break;
				default:
					break;
				}
				break;
			case Z80_MEM_IX: case Z80_MEM_IY:
				if (!comma(lp)) break;
				switch (reg2 = GetRegister(lp)) {
				case Z80_A: case Z80_B: case Z80_C: case Z80_D: case Z80_E: case Z80_H: case Z80_L:
					Options::noFakes();		// to display warning if "-f"
					e[0] = e[3] = reg&0xFF; e[2] = GetRegister_lastIxyD; e[1] = 0x70 + reg2; e[4] = 0x23; break;
				case Z80_BC: case Z80_DE: case Z80_HL:
					Options::noFakes();		// to display warning if "-f"
					e[0] = e[3] = e[5] = e[8] = reg&0xFF; e[4] = e[9] = 0x23; e[2] = e[7] = GetRegister_lastIxyD;
					e[1] = 0x70 + GetRegister_r16Low(reg2); e[6] = 0x70 + GetRegister_r16High(reg2); break;
				case Z80_UNK:
					Options::noFakes();		// to display warning if "-f"
					e[0] = e[4] = reg&0xFF; e[1] = 0x36; e[2] = GetRegister_lastIxyD; e[3] = GetByteNoMem(lp); e[5] = 0x23; break;
				default:
					break;
				}
				break;
			default:
				if (BT_NONE != OpenBracket(lp)) {
					reg = GetRegister(lp);
					if (!CloseBracket(lp) || !comma(lp)) break;
					if ((Z80_BC != reg && Z80_DE != reg) || Z80_A != GetRegister(lp)) break;
					Options::noFakes();
					e[0] = reg - 14; e[1] = reg - 13;	// LDI (bc|de),a
				} else {
					e[0] = 0xed; e[1] = 0xa0;			// regular LDI
				}
			}

			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_LDIR() {
		EmitByte(0xED);
		EmitByte(0xB0);
	}

// LDIRSCALE is now very unlikely to happen, there's ~1% chance it may be introduced within the cased-Next release
// 	static void OpCode_Next_LDIRSCALE() {
// 		if (Options::syx.IsNextEnabled < 1) {
// 			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
// 			return;
// 		}
// 		EmitByte(0xED);
// 		EmitByte(0xB6);
// 	}

	static void OpCode_Next_LDIRX() {
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
		EmitByte(0xED);
		EmitByte(0xB4);
	}

	static void OpCode_Next_LDIX() {
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
		EmitByte(0xED);
		EmitByte(0xA4);
	}

	static void OpCode_Next_LDPIRX() {
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
		EmitByte(0xED);
		EmitByte(0xB7);
	}

	static void OpCode_Next_LDWS() {
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
		EmitByte(0xED);
		EmitByte(0xA5);
	}

	static void OpCode_Next_MIRROR() {
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

	static void OpCode_Next_MUL() {
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

	static void OpCode_MULUB() {
		Z80Reg reg;
		int e[3];
		e[0] = e[1] = e[2] = -1;
		if ((reg = GetRegister(lp)) == Z80_A && comma(lp)) {
			reg = GetRegister(lp);
		}
		switch (reg) {
		case Z80_B:
			e[0] = 0xed; e[1] = 0xc1; break;
		case Z80_C:
			e[0] = 0xed; e[1] = 0xc9; break;
		case Z80_D:
			e[0] = 0xed; e[1] = 0xd1; break;
		case Z80_E:
			e[0] = 0xed; e[1] = 0xd9; break;
		default:
			;
		}
		EmitBytes(e);
	}

	static void OpCode_MULUW() {
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

	static void OpCode_NEG() {
		EmitByte(0xED);
		EmitByte(0x44);
	}

	static void OpCode_Next_NEXTREG() {
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
			e[2] = GetByteNoMem(lp);
			if (!comma(lp)) {
				Error("[NEXTREG] Comma expected"); break;
			}
			switch (reg = GetRegister(lp)) {
				case Z80_A:
					e[0] = 0xED; e[1] = 0x92;
					break;
				case Z80_UNK:
					e[0] = 0xED; e[1] = 0x91;
					e[3] = GetByteNoMem(lp);
					break;
				default:
					break;
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_NOP() {
		EmitByte(0x0);
	}

	static void OpCode_OR() {
		do {
			int e[] { -1, -1, -1, -1};
			CommonAluOpcode(0xb0, e);
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_OTDR() {
		EmitByte(0xED);
		EmitByte(0xBB);
	}

	static void OpCode_OTIR() {
		EmitByte(0xED);
		EmitByte(0xB3);
	}

	static void OpCode_OUT() {
		Z80Reg reg;
		do {
			int e[] { -1, -1, -1 };
			if ((!Options::IsI8080) && NeedIoC()) {
				if (comma(lp)) {
					switch (reg = GetRegister(lp)) {
					case Z80_B: case Z80_C: case Z80_D: case Z80_E: case Z80_H: case Z80_L: case Z80_A:
						e[0] = 0xed; e[1] = 0x41 + 8 * reg; break;
					case Z80_UNK:
						if (0 == GetByteNoMem(lp)) e[0] = 0xed;	// out (c),0
						e[1] = 0x71; break;
					default:
						break;
					}
				}
			} else {
				e[1] = GetByte(lp);		// out ($n),a
				if (comma(lp) && GetRegister(lp) == Z80_A) e[0] = 0xd3;
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_OUTD() {
		EmitByte(0xED);
		EmitByte(0xAB);
	}

	static void OpCode_OUTI() {
		EmitByte(0xED);
		EmitByte(0xA3);
	}

	static void OpCode_Next_OUTINB() {
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
		EmitByte(0xED);
		EmitByte(0x90);
	}

	static void OpCode_Next_PIXELAD() {
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
		char *oldLp = lp;
		if (Z80_HL != GetRegister(lp)) lp = oldLp;		// "eat" explicit HL argument
		EmitByte(0xED);
		EmitByte(0x94);
	}

	static void OpCode_Next_PIXELDN() {
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
		char *oldLp = lp;
		if (Z80_HL != GetRegister(lp)) lp = oldLp;		// "eat" explicit HL argument
		EmitByte(0xED);
		EmitByte(0x93);
	}

	static void OpCode_POPreverse() {
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

	static void OpCode_POPnormal() {
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

	static void OpCode_POP() {
		if (Options::syx.IsReversePOP) OpCode_POPreverse();
		else OpCode_POPnormal();
	}

	static void OpCode_PUSH() {
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
				word imm16 = GetWordNoMem(lp);
				e[0] = 0xED; e[1] = 0x8A;
				e[2] = (imm16 >> 8);  // push opcode is big-endian!
				e[3] = imm16 & 255;
			}
			default:
				break;
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_RES() {
		do {
			int e[] { -1, -1, -1, -1, -1 };
			byte bit = GetByteNoMem(lp);
			if (comma(lp) && bit <= 7) OpCode_CbFamily(8 * bit + 0x80, e);
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_RET() {
		Z80Cond cc = getz80cond(lp);
		if (Z80C_UNK == cc) EmitByte(0xc9);
		else 				EmitByte(0xc0 + cc);
		// multi-argument was intetionally removed by Ped7g (explain in issue why you want *that*?)
	}

	static void OpCode_RETI() {
		EmitByte(0xED);
		EmitByte(0x4D);
	}

	static void OpCode_RETN() {
		EmitByte(0xED);
		EmitByte(0x45);
	}

	static void OpCode_RL() {
		Z80Reg reg;
		do {
			int e[] { -1, -1, -1, -1, -1 };
			switch (reg = OpCode_CbFamily(0x10, e)) {
			case Z80_A:		break;			// fully processed by the helper function
			case Z80_BC:	case Z80_DE:	case Z80_HL:
				if (Options::noFakes()) break;
				e[0] = e[2] = 0xcb;
				e[1] = 0x10 + GetRegister_r16Low(reg);
				e[3] = 0x10 + GetRegister_r16High(reg);
				break;
			default:		break;
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_RLA() {
		EmitByte(0x17);
	}

	static void OpCode_RLC() {
		do {
			int e[] { -1, -1, -1, -1, -1 };
			OpCode_CbFamily(0x00, e);
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_RLCA() {
		EmitByte(0x7);
	}

	static void OpCode_RLD() {
		EmitByte(0xED);
		EmitByte(0x6F);
	}

	static void OpCode_RR() {
		Z80Reg reg;
		do {
			int e[] { -1, -1, -1, -1, -1 };
			switch (reg = OpCode_CbFamily(0x18, e)) {
			case Z80_A:		break;			// fully processed by the helper function
			case Z80_BC:	case Z80_DE:	case Z80_HL:
				if (Options::noFakes()) break;
				e[0] = e[2] = 0xcb;
				e[1] = 0x18 + GetRegister_r16High(reg);
				e[3] = 0x18 + GetRegister_r16Low(reg);
				break;
			default:		break;
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_RRA() {
		EmitByte(0x1f);
	}

	static void OpCode_RRC() {
		do {
			int e[] { -1, -1, -1, -1, -1 };
			OpCode_CbFamily(0x08, e);
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_RRCA() {
		EmitByte(0xf);
	}

	static void OpCode_RRD() {
		EmitByte(0xED);
		EmitByte(0x67);
	}

	static void OpCode_RST() {
		do {
			byte e = GetByteNoMem(lp);
			if (e&(~0x38)) {	// some bit is set which should be not
				Error("[RST] Illegal operand", line); SkipToEol(lp);
				return;
			} else {			// e == { $00, $08, $10, $18, $20, $28, $30, $38 }
				EmitByte(0xC7 + e);
			}
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_SBC() {
		const bool nonZ80CPU = Options::IsI8080 || Options::IsLR35902;
		Z80Reg reg;
		do {
			int e[] { -1, -1, -1, -1 };
			if (!CommonAluOpcode(0x98, e, true, false)) {	// handle common 8-bit variants
				if ((!nonZ80CPU) && (Z80_HL == GetRegister(lp))) {
					if (!comma(lp)) {
						Error("[SBC] Comma expected");
					} else {
						switch (reg = GetRegister(lp)) {
						case Z80_BC: case Z80_DE: case Z80_HL: case Z80_SP:
							e[0] = 0xed; e[1] = 0x32 + reg; break;
						default: break;
						}
					}
				}
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_SCF() {
		EmitByte(0x37);
	}

	static void OpCode_SET() {
		do {
			int e[] { -1, -1, -1, -1, -1 };
			byte bit = GetByteNoMem(lp);
			if (comma(lp) && bit <= 7) OpCode_CbFamily(8 * bit + 0xc0, e);
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_Next_SETAE() {
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
		EmitByte(0xED);
		EmitByte(0x95);
	}

	static void OpCode_SLA() {
		Z80Reg reg;
		do {
			int e[] { -1, -1, -1, -1, -1 };
			switch (reg = OpCode_CbFamily(0x20, e)) {
			case Z80_A:		break;			// fully processed by the helper function
			case Z80_HL:
				if (Options::noFakes()) break;
				e[0] = 0x29; break;
			case Z80_BC:	case Z80_DE:
				if (Options::noFakes()) break;
				e[0] = e[2] = 0xcb;
				e[1] = 0x20 + GetRegister_r16Low(reg);
				e[3] = 0x10 + GetRegister_r16High(reg);
				break;
			default:		break;
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_SLL() {
		Z80Reg reg;
		do {
			int e[] { -1, -1, -1, -1, -1 };
			switch (reg = OpCode_CbFamily(0x30, e)) {
			case Z80_A:		break;			// fully processed by the helper function
			case Z80_BC:	case Z80_DE:	case Z80_HL:
				if (Options::noFakes()) break;
				e[0] = e[2] = 0xcb;
				e[1] = 0x30 + GetRegister_r16Low(reg);
				e[3] = 0x10 + GetRegister_r16High(reg);
				break;
			default:		break;
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_SRA() {
		Z80Reg reg;
		do {
			int e[] { -1, -1, -1, -1, -1 };
			switch (reg = OpCode_CbFamily(0x28, e)) {
			case Z80_A:		break;			// fully processed by the helper function
			case Z80_BC:	case Z80_DE:	case Z80_HL:
				if (Options::noFakes()) break;
				e[0] = e[2] = 0xcb;
				e[1] = 0x28 + GetRegister_r16High(reg);
				e[3] = 0x18 + GetRegister_r16Low(reg);
				break;
			default:		break;
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_SRL() {
		Z80Reg reg;
		do {
			int e[] { -1, -1, -1, -1, -1 };
			switch (reg = OpCode_CbFamily(0x38, e)) {
			case Z80_A:		break;			// fully processed by the helper function
			case Z80_BC:	case Z80_DE:	case Z80_HL:
				if (Options::noFakes()) break;
				e[0] = e[2] = 0xcb;
				e[1] = 0x38 + GetRegister_r16High(reg);
				e[3] = 0x18 + GetRegister_r16Low(reg);
				break;
			default:		break;
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	static void OpCode_LR35902_STOP() {	// syntax: STOP [byte_value = 0] = opcode "10 byte_value"
		EmitByte(0x10);
		if (SkipBlanks(lp)) {		// is optional byte provided? (if not, default value is zero)
			EmitByte(0x00);
		} else {
			EmitByte(GetByteNoMem(lp));
		}
	}

	static void OpCode_SUB() {
		Z80Reg reg;
		do {
			int e[] { -1, -1, -1, -1 };
			if (!CommonAluOpcode(0x90, e, true, true)) {	// handle common 8-bit variants
				if ((!Options::IsI8080) && (Z80_HL == GetRegister(lp))) {
					if (!comma(lp)) {
						Error("[SUB] Comma expected");
					} else {
						switch (reg = GetRegister(lp)) {
						case Z80_BC: case Z80_DE: case Z80_HL: case Z80_SP:
							if (Options::noFakes()) break;
							e[0] = 0xb7; e[1] = 0xed; e[2] = 0x32+reg; break;
						default: break;
						}
					}
				}
			}
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	//Swaps the high and low nibbles of the accumulator.
	static void OpCode_Next_SWAPNIB() {
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

	static void OpCode_Next_TEST() {
		if (Options::syx.IsNextEnabled < 1) {
			Error("Z80N instructions are currently disabled", bp, SUPPRESS);
			return;
		}
		int e[] { 0xED, 0x27, GetByteNoMem(lp), -1 };
		EmitBytes(e);
	}

	static void OpCode_XOR() {
		do {
			int e[] { -1, -1, -1, -1};
			CommonAluOpcode(0xa8, e);
			EmitBytes(e);
		} while (Options::syx.MultiArg(lp));
	}

	void Init() {
		// Z80, i8080 and LR35902 shared instructions first
		OpCodeTable.Insert("adc", OpCode_ADC);
		OpCodeTable.Insert("add", OpCode_ADD);
		OpCodeTable.Insert("and", OpCode_AND);
		OpCodeTable.Insert("call", OpCode_CALL);
		OpCodeTable.Insert("ccf", OpCode_CCF);
		OpCodeTable.Insert("cp", OpCode_CP);
		OpCodeTable.Insert("cpl", OpCode_CPL);
		OpCodeTable.Insert("daa", OpCode_DAA);
		OpCodeTable.Insert("dec", OpCode_DEC);
		OpCodeTable.Insert("di", OpCode_DI);
		OpCodeTable.Insert("ei", OpCode_EI);
		if (!Options::IsLR35902) OpCodeTable.Insert("ex", OpCode_EX);
		OpCodeTable.Insert("exd", OpCode_EXD);
		OpCodeTable.Insert("halt", OpCode_HALT);
		if (!Options::IsLR35902) OpCodeTable.Insert("in", OpCode_IN);
		OpCodeTable.Insert("inc", OpCode_INC);
		OpCodeTable.Insert("jp", OpCode_JP);
		OpCodeTable.Insert("ld", OpCode_LD);
		OpCodeTable.Insert("nop", OpCode_NOP);
		OpCodeTable.Insert("or", OpCode_OR);
		if (!Options::IsLR35902) OpCodeTable.Insert("out", OpCode_OUT);
		OpCodeTable.Insert("pop", OpCode_POP);
		OpCodeTable.Insert("push", OpCode_PUSH);
		OpCodeTable.Insert("ret", OpCode_RET);
		OpCodeTable.Insert("rla", OpCode_RLA);
		OpCodeTable.Insert("rlca", OpCode_RLCA);
		OpCodeTable.Insert("rra", OpCode_RRA);
		OpCodeTable.Insert("rrca", OpCode_RRCA);
		OpCodeTable.Insert("rst", OpCode_RST);
		OpCodeTable.Insert("sbc", OpCode_SBC);
		OpCodeTable.Insert("scf", OpCode_SCF);
		OpCodeTable.Insert("sub", OpCode_SUB);
		OpCodeTable.Insert("xor", OpCode_XOR);

		if (Options::IsI8080) return;	// all i8080 instructions defined

		// Z80 and LR35902 shared instructions
		OpCodeTable.Insert("bit", OpCode_BIT);
		OpCodeTable.Insert("jr", OpCode_JR);
		OpCodeTable.Insert("res", OpCode_RES);
		OpCodeTable.Insert("rl", OpCode_RL);
		OpCodeTable.Insert("rlc", OpCode_RLC);
		OpCodeTable.Insert("rr", OpCode_RR);
		OpCodeTable.Insert("rrc", OpCode_RRC);
		OpCodeTable.Insert("set", OpCode_SET);
		OpCodeTable.Insert("sla", OpCode_SLA);
		OpCodeTable.Insert("sra", OpCode_SRA);
		OpCodeTable.Insert("srl", OpCode_SRL);

		if (Options::IsLR35902) {
			//INIT LR35902 extras
			OpCodeTable.Insert("ldd", OpCode_LR35902_LDD);
			OpCodeTable.Insert("ldh", OpCode_LR35902_LDH);
			OpCodeTable.Insert("ldi", OpCode_LR35902_LDI);
			OpCodeTable.Insert("reti", OpCode_EXX);		// RETI has same opcode as EXX on Z80
 			OpCodeTable.Insert("stop", OpCode_LR35902_STOP);
			OpCodeTable.Insert("swap", OpCode_SLL);		// SWAP has same opcodes as SLI on Z80
			return;						// all LR35902 instructions defined
		}

		// Z80 instructions
		OpCodeTable.Insert("cpd", OpCode_CPD);
		OpCodeTable.Insert("cpdr", OpCode_CPDR);
		OpCodeTable.Insert("cpi", OpCode_CPI);
		OpCodeTable.Insert("cpir", OpCode_CPIR);
		OpCodeTable.Insert("djnz", OpCode_DJNZ);
		OpCodeTable.Insert("exa", OpCode_EXA);
		OpCodeTable.Insert("exx", OpCode_EXX);
		OpCodeTable.Insert("im", OpCode_IM);
		OpCodeTable.Insert("ind", OpCode_IND);
		OpCodeTable.Insert("indr", OpCode_INDR);
		OpCodeTable.Insert("inf", OpCode_INF); // thanks to BREEZE
		OpCodeTable.Insert("ini", OpCode_INI);
		OpCodeTable.Insert("inir", OpCode_INIR);
		OpCodeTable.Insert("ldd", OpCode_LDD);
		OpCodeTable.Insert("lddr", OpCode_LDDR);
		OpCodeTable.Insert("ldi", OpCode_LDI);
		OpCodeTable.Insert("ldir", OpCode_LDIR);
		OpCodeTable.Insert("mulub", OpCode_MULUB);
		OpCodeTable.Insert("muluw", OpCode_MULUW);
		OpCodeTable.Insert("neg", OpCode_NEG);
		OpCodeTable.Insert("otdr", OpCode_OTDR);
		OpCodeTable.Insert("otir", OpCode_OTIR);
		OpCodeTable.Insert("outd", OpCode_OUTD);
		OpCodeTable.Insert("outi", OpCode_OUTI);
		OpCodeTable.Insert("reti", OpCode_RETI);
		OpCodeTable.Insert("retn", OpCode_RETN);
		OpCodeTable.Insert("rld", OpCode_RLD);
		OpCodeTable.Insert("rrd", OpCode_RRD);
		OpCodeTable.Insert("sli", OpCode_SLL);
		OpCodeTable.Insert("sll", OpCode_SLL);

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
