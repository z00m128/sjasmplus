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
	enum Z80Reg { Z80_B = 0, Z80_C, Z80_D, Z80_E, Z80_H, Z80_L, Z80_A = 7, Z80_I, Z80_R, Z80_F, Z80_BC = 0x10, Z80_DE = 0x20, Z80_HL = 0x30, Z80_IXH, Z80_IXL, Z80_IYH, Z80_IYL, Z80_SP = 0x40, Z80_AF = 0x50, Z80_IX = 0xdd, Z80_IY = 0xfd, Z80_UNK = -1 };
	enum Z80Cond { Z80C_C, Z80C_M, Z80C_NC, Z80C_NZ, Z80C_P, Z80C_PE, Z80C_PO, Z80C_Z, Z80C_UNK };

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
		if (GetLocalLabelValue(p, ad)) {
			return 1;
		}
		if (ParseExpression(p, ad)) {
			return 1;
		}
		Error("Operand expected", 0, CATCHALL);
		return 0;
	}

	Z80Cond getz80cond(char*& p) {
		char* pp = p;
		SkipBlanks(p);
		switch (*(p++)) {
		case 'n':
			switch (*(p++)) {
			case 'z':
				if (!islabchar(*p)) {
					return Z80C_NZ;
				} break;
			case 'c':
				if (!islabchar(*p)) {
					return Z80C_NC;
				} break;
			case 's':
				if (!islabchar(*p)) {
					return Z80C_P;
				} break;
			default:
				break;
			}
			break;
		case 'N':
			switch (*(p++)) {
			case 'Z':
				if (!islabchar(*p)) {
					return Z80C_NZ;
				} break;
			case 'C':
				if (!islabchar(*p)) {
					return Z80C_NC;
				} break;
			case 'S':
				if (!islabchar(*p)) {
					return Z80C_P;
				} break;
			default:
				break;
			}
			break;
		case 'z':
		case 'Z':
			if (!islabchar(*p)) {
				return Z80C_Z;
			} break;
		case 'c':
		case 'C':
			if (!islabchar(*p)) {
				return Z80C_C;
			} break;
		case 'm':
		case 'M':
		case 's':
		case 'S':
			if (!islabchar(*p)) {
				return Z80C_M;
			} break;
		case 'p':
			if (!islabchar(*p)) {
				return Z80C_P;
			}
			switch (*(p++)) {
			case 'e':
				if (!islabchar(*p)) {
					return Z80C_PE;
				} break;
			case 'o':
				if (!islabchar(*p)) {
					return Z80C_PO;
				} break;
			default:
				break;
			}
			break;
		case 'P':
			if (!islabchar(*p)) {
				return Z80C_P;
			}
			switch (*(p++)) {
			case 'E':
				if (!islabchar(*p)) {
					return Z80C_PE;
				} break;
			case 'O':
				if (!islabchar(*p)) {
					return Z80C_PO;
				} break;
			default:
				break;
			}
			break;
		default:
			break;
		}
		p = pp;
		return Z80C_UNK;
	}

	/* modified */
	Z80Reg GetRegister(char*& p) {
		char* pp = p;
		SkipBlanks(p);
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
			/* (begin add) */
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
			/* (end add) */
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
			/* (begin add) */
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
			/* (end add) */
		case 'l':
			/* (begin add) */
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
			/* (end add) */
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
			/* (begin add) */
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
			/* (end add) */
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
			/* (begin add) */
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
			/* (end add) */
		case 'L':
			/* (begin add) */
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
			/* (end add) */
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

	/* modified */
	void OpCode_ADC() {
		Z80Reg reg;
		int e[4];
		do {
			/* added */
			e[0] = e[1] = e[2] = e[3] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_HL:
				if (!comma(lp)) {
					Error("[ADC] Comma expected", 0); break;
				}
				switch (GetRegister(lp)) {
				case Z80_BC:
					e[0] = 0xed; e[1] = 0x4a; break;
				case Z80_DE:
					e[0] = 0xed; e[1] = 0x5a; break;
				case Z80_HL:
					e[0] = 0xed; e[1] = 0x6a; break;
				case Z80_SP:
					e[0] = 0xed; e[1] = 0x7a; break;
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
					reg = Z80_UNK;
					if (oparen(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							break;
						}
					} else if (oparen(lp, '(')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							--lp;
						}
					}
					switch (reg) {
					case Z80_HL:
						if (cparen(lp)) {
							e[0] = 0x8e;
						}
						break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x8e; e[2] = z80GetIDxoffset(lp);
						if (cparen(lp)) {
							e[0] = reg;
						}
						break;
					default:
						e[0] = 0xce; e[1] = GetByte(lp); break;
					}
				}
			}
			EmitBytes(e);
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	/* modified */
	void OpCode_ADD() {
		Z80Reg reg;
		int e[4];
		do {
			/* added */
			e[0] = e[1] = e[2] = e[3] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_HL:
				if (!comma(lp)) {
					Error("[ADD] Comma expected", 0); break;
				}
				switch (GetRegister(lp)) {
				case Z80_BC:
					e[0] = 0x09; break;
				case Z80_DE:
					e[0] = 0x19; break;
				case Z80_HL:
					e[0] = 0x29; break;
				case Z80_SP:
					e[0] = 0x39; break;
				default:
					;
				}
				break;
			case Z80_IX:
				if (!comma(lp)) {
					Error("[ADD] Comma expected", 0); break;
				}
				switch (GetRegister(lp)) {
				case Z80_BC:
					e[0] = 0xdd; e[1] = 0x09; break;
				case Z80_DE:
					e[0] = 0xdd; e[1] = 0x19; break;
				case Z80_IX:
					e[0] = 0xdd; e[1] = 0x29; break;
				case Z80_SP:
					e[0] = 0xdd; e[1] = 0x39; break;
				default:
					;
				}
				break;
			case Z80_IY:
				if (!comma(lp)) {
					Error("[ADD] Comma expected", 0); break;
				}
				switch (GetRegister(lp)) {
				case Z80_BC:
					e[0] = 0xfd; e[1] = 0x09; break;
				case Z80_DE:
					e[0] = 0xfd; e[1] = 0x19; break;
				case Z80_IY:
					e[0] = 0xfd; e[1] = 0x29; break;
				case Z80_SP:
					e[0] = 0xfd; e[1] = 0x39; break;
				default:
					;
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
					reg = Z80_UNK;
					if (oparen(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							break;
						}
					} else if (oparen(lp, '(')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							--lp;
						}
					}
					switch (reg) {
					case Z80_HL:
						if (cparen(lp)) {
							e[0] = 0x86;
						}
						break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x86; e[2] = z80GetIDxoffset(lp);
						if (cparen(lp)) {
							e[0] = reg;
						}
						break;
					default:
						e[0] = 0xc6; e[1] = GetByte(lp); break;
					}
				}
			}
			EmitBytes(e);
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	/* modified */
	void OpCode_AND() {
		Z80Reg reg;
		int e[4];
		do {
			/* added */
			e[0] = e[1] = e[2] = e[3] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_A:
				/*if (!comma(lp)) { e[0]=0xa7; break; }
							reg=GetRegister(lp);*/
				e[0] = 0xa7; break; /* added */
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
					reg = Z80_UNK;
					if (oparen(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							break;
						}
					} else if (oparen(lp, '(')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							--lp;
						}
					}
					switch (reg) {
					case Z80_HL:
						if (cparen(lp)) {
							e[0] = 0xa6;
						}
						break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0xa6; e[2] = z80GetIDxoffset(lp);
						if (cparen(lp)) {
							e[0] = reg;
						}
						break;
					default:
						e[0] = 0xe6; e[1] = GetByte(lp); break;
					}
				}
			}
			EmitBytes(e);
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	/* modified */
	void OpCode_BIT() {
		Z80Reg reg;
		int e[5], bit;
		do {
			/* added */
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
				if (!oparen(lp, '[') && !oparen(lp, '(')) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					if (cparen(lp)) {
						e[0] = 0xcb;
					}
					e[1] = 8 * bit + 0x46; break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 8 * bit + 0x46;
					if (cparen(lp)) {
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
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	/* modified */
	void OpCode_CALL() {
		aint callad;
		int e[4], b;
		do {
			/* added */
			e[0] = e[1] = e[2] = e[3] = -1;
			switch (getz80cond(lp)) {
			case Z80C_C:
				if (comma(lp)) {
					e[0] = 0xdc;
				} break;
			case Z80C_M:
				if (comma(lp)) {
					e[0] = 0xfc;
				} break;
			case Z80C_NC:
				if (comma(lp)) {
					e[0] = 0xd4;
				} break;
			case Z80C_NZ:
				if (comma(lp)) {
					e[0] = 0xc4;
				} break;
			case Z80C_P:
				if (comma(lp)) {
					e[0] = 0xf4;
				} break;
			case Z80C_PE:
				if (comma(lp)) {
					e[0] = 0xec;
				} break;
			case Z80C_PO:
				if (comma(lp)) {
					e[0] = 0xe4;
				} break;
			case Z80C_Z:
				if (comma(lp)) {
					e[0] = 0xcc;
				} break;
			default:
				e[0] = 0xcd; break;
			}
			if (!(GetAddress(lp, callad))) {
				callad = 0;
			}
			b = (signed) callad;
			e[1] = callad & 255; e[2] = (callad >> 8) & 255;
			if (b > 65535) {
				Error("[CALL] Bytes lost", 0);
			}
			EmitBytes(e);
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	void OpCode_CCF() {
		EmitByte(0x3f);
	}

	/* modified */
	void OpCode_CP() {
		Z80Reg reg;
		int e[4];
		do {
			/* added */
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
					reg = Z80_UNK;
					if (oparen(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							break;
						}
					} else if (oparen(lp, '(')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							--lp;
						}
					}
					switch (reg) {
					case Z80_HL:
						if (cparen(lp)) {
							e[0] = 0xbe;
						}
						break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0xbe; e[2] = z80GetIDxoffset(lp);
						if (cparen(lp)) {
							e[0] = reg;
						}
						break;
					default:
						e[0] = 0xfe; e[1] = GetByte(lp); break;
					}
				}
			}
			EmitBytes(e);
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
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

	/* modified */
	void OpCode_DEC() {
		Z80Reg reg;
		int e[4];
		do {
			/* added */
			e[0] = e[1] = e[2] = e[3] = -1;
			switch (GetRegister(lp)) {
			case Z80_A:
				e[0] = 0x3d; break;
			case Z80_B:
				e[0] = 0x05; break;
			case Z80_BC:
				e[0] = 0x0b; break;
			case Z80_C:
				e[0] = 0x0d; break;
			case Z80_D:
				e[0] = 0x15; break;
			case Z80_DE:
				e[0] = 0x1b; break;
			case Z80_E:
				e[0] = 0x1d; break;
			case Z80_H:
				e[0] = 0x25; break;
			case Z80_HL:
				e[0] = 0x2b; break;
			case Z80_IX:
				e[0] = 0xdd; e[1] = 0x2b; break;
			case Z80_IY:
				e[0] = 0xfd; e[1] = 0x2b; break;
			case Z80_L:
				e[0] = 0x2d; break;
			case Z80_SP:
				e[0] = 0x3b; break;
			case Z80_IXH:
				e[0] = 0xdd; e[1] = 0x25; break;
			case Z80_IXL:
				e[0] = 0xdd; e[1] = 0x2d; break;
			case Z80_IYH:
				e[0] = 0xfd; e[1] = 0x25; break;
			case Z80_IYL:
				e[0] = 0xfd; e[1] = 0x2d; break;
			default:
				if (!oparen(lp, '[') && !oparen(lp, '(')) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					if (cparen(lp)) {
						e[0] = 0x35;
					} break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0x35; e[2] = z80GetIDxoffset(lp);
					if (cparen(lp)) {
						e[0] = reg;
					}
					break;
				default:
					;
				}
			}
			EmitBytes(e);
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	void OpCode_DI() {
		EmitByte(0xf3);
	}

	/* modified */
	void OpCode_DJNZ() {
		int jmp;
		aint nad;
		int e[3];
		do {
			/* added */
			e[0] = e[1] = e[2] = -1;
			if (!GetAddress(lp, nad)) {
				nad = CurAddress + 2;
			}
			jmp = nad - CurAddress - 2;
			if (jmp < -128 || jmp > 127) {
				char el[LINEMAX];
				SPRINTF1(el, LINEMAX, "[DJNZ] Target out of range (%i)", jmp);
				Error(el, 0); jmp = 0;
			}
			e[0] = 0x10; e[1] = jmp < 0 ? 256 + jmp : jmp;
			EmitBytes(e);
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
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
				Error("[EX] Comma expected", 0); break;
			}
			if (GetRegister(lp) != Z80_HL) {
				break;
			}
			e[0] = 0xeb;
			break;
		case Z80_HL:
			if (!comma(lp)) {
				Error("[EX] Comma expected", 0); break;
			}
			if (GetRegister(lp) != Z80_DE) {
				break;
			}
			e[0] = 0xeb;
			break;
		default:
			if (!oparen(lp, '[') && !oparen(lp, '(')) {
				break;
			}
			if (GetRegister(lp) != Z80_SP) {
				break;
			}
			if (!cparen(lp)) {
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

	/* added */
	void OpCode_EXA() {
		EmitByte(0x08);
	}

	/* added */
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
		int e[3];
		e[0] = 0xed; e[2] = -1;
		switch (GetByte(lp)) {
		case 0:
			e[1] = 0x46; break;
		case 1:
			e[1] = 0x56; break;
		case 2:
			e[1] = 0x5e; break;
		default:
			e[0] = -1;
		}
		EmitBytes(e);
	}

	/* modified */
	void OpCode_IN() {
		Z80Reg reg;
		int e[3];
		do {
			/* added */
			e[0] = e[1] = e[2] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_A:
				if (!comma(lp)) {
					break;
				}
				if (!oparen(lp, '[') && !oparen(lp, '(')) {
					break;
				}
				if (GetRegister(lp) == Z80_C) {
					e[1] = 0x78; if (cparen(lp)) {
								 	e[0] = 0xed;
								 }
				} else {
					e[1] = GetByte(lp); if (cparen(lp)) {
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
				if (!oparen(lp, '[') && !oparen(lp, '(')) {
					break;
				}
				if (GetRegister(lp) != Z80_C) {
					break;
				}
				if (cparen(lp)) {
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
				if (!oparen(lp, '[') && !oparen(lp, '(')) {
					break;
				}
				if (GetRegister(lp) != Z80_C) {
					break;
				}
				if (cparen(lp)) {
					e[0] = 0xed;
				}
				e[1] = 0x70;
			}
			EmitBytes(e);
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	/* modified */
	void OpCode_INC() {
		Z80Reg reg;
		int e[4];
		do {
			/* added */
			e[0] = e[1] = e[2] = e[3] = -1;
			switch (GetRegister(lp)) {
			case Z80_A:
				e[0] = 0x3c; break;
			case Z80_B:
				e[0] = 0x04; break;
			case Z80_BC:
				e[0] = 0x03; break;
			case Z80_C:
				e[0] = 0x0c; break;
			case Z80_D:
				e[0] = 0x14; break;
			case Z80_DE:
				e[0] = 0x13; break;
			case Z80_E:
				e[0] = 0x1c; break;
			case Z80_H:
				e[0] = 0x24; break;
			case Z80_HL:
				e[0] = 0x23; break;
			case Z80_IX:
				e[0] = 0xdd; e[1] = 0x23; break;
			case Z80_IY:
				e[0] = 0xfd; e[1] = 0x23; break;
			case Z80_L:
				e[0] = 0x2c; break;
			case Z80_SP:
				e[0] = 0x33; break;
			case Z80_IXH:
				e[0] = 0xdd; e[1] = 0x24; break;
			case Z80_IXL:
				e[0] = 0xdd; e[1] = 0x2c; break;
			case Z80_IYH:
				e[0] = 0xfd; e[1] = 0x24; break;
			case Z80_IYL:
				e[0] = 0xfd; e[1] = 0x2c; break;
			default:
				if (!oparen(lp, '[') && !oparen(lp, '(')) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					if (cparen(lp)) {
						e[0] = 0x34;
					} break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0x34; e[2] = z80GetIDxoffset(lp);
					if (cparen(lp)) {
						e[0] = reg;
					}
					break;
				default:
					;
				}
			}
			EmitBytes(e);
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
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

	/* modified */
	void OpCode_JP() {
		Z80Reg reg;
		int haakjes = 0;
		aint jpad;
		int e[4],b,k = 0;
		do {
			/* added */
			e[0] = e[1] = e[2] = e[3] = -1;
			switch (getz80cond(lp)) {
			case Z80C_C:
				if (comma(lp)) {
					e[0] = 0xda;
				} break;
			case Z80C_M:
				if (comma(lp)) {
					e[0] = 0xfa;
				} break;
			case Z80C_NC:
				if (comma(lp)) {
					e[0] = 0xd2;
				} break;
			case Z80C_NZ:
				if (comma(lp)) {
					e[0] = 0xc2;
				} break;
			case Z80C_P:
				if (comma(lp)) {
					e[0] = 0xf2;
				} break;
			case Z80C_PE:
				if (comma(lp)) {
					e[0] = 0xea;
				} break;
			case Z80C_PO:
				if (comma(lp)) {
					e[0] = 0xe2;
				} break;
			case Z80C_Z:
				if (comma(lp)) {
					e[0] = 0xca;
				} break;
			default:
				reg = Z80_UNK;
				if (oparen(lp, '[')) {
					if ((reg = GetRegister(lp)) == Z80_UNK) {
						break;
					}
					haakjes = 1;
				} else if (oparen(lp, '(')) {
					if ((reg = GetRegister(lp)) == Z80_UNK) {
						--lp;
					} else {
						haakjes = 1;
					}
				}
				if (reg == Z80_UNK) {
					reg = GetRegister(lp);
				}
				switch (reg) {
				case Z80_HL:
					if (haakjes && !cparen(lp)) {
						break;
					} e[0] = 0xe9; k = 1; break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xe9; if (haakjes && !cparen(lp)) {
								 	break;
								 } e[0] = reg; k = 1; break;
				default:
					e[0] = 0xc3;
				}
			}
			if (!k) {
				if (!(GetAddress(lp, jpad))) {
					jpad = 0;
				}
				b = (signed) jpad;
				e[1] = jpad & 255; e[2] = (jpad >> 8) & 255;
				if (b > 65535) {
					Error("[JP] Bytes lost", 0);
				}
			}
			EmitBytes(e);
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	/* modified */
	void OpCode_JR() {
		aint jrad=0;
		int e[4], jmp=0;
		do {
			/* added */
			e[0] = e[1] = e[2] = e[3] = -1;
			switch (getz80cond(lp)) {
			case Z80C_C:
				if (comma(lp)) {
					e[0] = 0x38;
				} break;
			case Z80C_NC:
				if (comma(lp)) {
					e[0] = 0x30;
				} break;
			case Z80C_NZ:
				if (comma(lp)) {
					e[0] = 0x20;
				} break;
			case Z80C_Z:
				if (comma(lp)) {
					e[0] = 0x28;
				} break;
			case Z80C_M:
			case Z80C_P:
			case Z80C_PE:
			case Z80C_PO:
				Error("[JR] Illegal condition", 0); break;
			default:
				e[0] = 0x18; break;
			}
			/*if (CurAddress == 47030) {
				_COUT "JUST BREAKPOINT" _ENDL;
			}*/
			if (!(GetAddress(lp, jrad))) {
				jrad = CurAddress + 2;
			}
			jmp = jrad - CurAddress - 2;
			if (jmp < -128 || jmp > 127) {
				char el[LINEMAX];
				/*if (pass == LASTPASS) {
					_COUT "AAAAAAA:" _CMDL jmp _CMDL " " _CMDL jrad _CMDL " " _CMDL CurAddress _ENDL;
				}*/
				SPRINTF1(el, LINEMAX, "[JR] Target out of range (%i)", jmp);
				Error(el, 0, LASTPASS);
				jmp = 0;
			}
			e[1] = jmp < 0 ? 256 + jmp : jmp;
			EmitBytes(e);
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	/* modified */
	void OpCode_LD() {
		Z80Reg reg;
		int e[7], beginhaakje;
		aint b;
		char* olp;

		do {
			/* added */
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
					if (oparen(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							b = GetWord(lp); e[1] = b & 255; e[2] = (b >> 8) & 255; if (cparen(lp)) {
																						e[0] = 0x3a;
																					} break;
						}
					} else {
						if (oparen(lp, '(')) {
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
						if (cparen(lp)) {
							e[0] = 0x0a;
						} break;
					case Z80_DE:
						if (cparen(lp)) {
							e[0] = 0x1a;
						} break;
					case Z80_HL:
						if (cparen(lp)) {
							e[0] = 0x7e;
						} break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x7e; e[2] = z80GetIDxoffset(lp); if (cparen(lp)) {
																 	e[0] = reg;
																 } break;
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
					if (oparen(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							break;
						}
					} else if (oparen(lp, '(')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							--lp; e[0] = 0x06; e[1] = GetByte(lp); break;
						}
					} else {
						e[0] = 0x06; e[1] = GetByte(lp); break;
					}
					switch (reg) {
					case Z80_HL:
						if (cparen(lp)) {
							e[0] = 0x46;
						} break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x46; e[2] = z80GetIDxoffset(lp); if (cparen(lp)) {
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
					if (oparen(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							break;
						}
					} else if (oparen(lp, '(')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							--lp; e[0] = 0x0e; e[1] = GetByte(lp); break;
						}
					} else {
						e[0] = 0x0e; e[1] = GetByte(lp); break;
					}
					switch (reg) {
					case Z80_HL:
						if (cparen(lp)) {
							e[0] = 0x4e;
						} break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x4e; e[2] = z80GetIDxoffset(lp); if (cparen(lp)) {
																 	e[0] = reg;
																 } break;
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
					if (oparen(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							break;
						}
					} else if (oparen(lp, '(')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							--lp; e[0] = 0x16; e[1] = GetByte(lp); break;
						}
					} else {
						e[0] = 0x16; e[1] = GetByte(lp); break;
					}
					switch (reg) {
					case Z80_HL:
						if (cparen(lp)) {
							e[0] = 0x56;
						} break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x56; e[2] = z80GetIDxoffset(lp); if (cparen(lp)) {
																 	e[0] = reg;
																 } break;
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
					if (oparen(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							break;
						}
					} else if (oparen(lp, '(')) {
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
						if (cparen(lp)) {
							e[0] = 0x5e;
						} break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x5e;
						e[2] = z80GetIDxoffset(lp);
						if (cparen(lp)) {
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
					if (oparen(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							break;
						}
					} else if (oparen(lp, '(')) {
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
						if (cparen(lp)) {
							e[0] = 0x66;
						}
						break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x66; e[2] = z80GetIDxoffset(lp);
						if (cparen(lp)) {
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
					if (oparen(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							break;
						}
					} else if (oparen(lp, '(')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							--lp; e[0] = 0x2e; e[1] = GetByte(lp); break;
						}
					} else {
						e[0] = 0x2e; e[1] = GetByte(lp); break;
					}
					switch (reg) {
					case Z80_HL:
						if (cparen(lp)) {
							e[0] = 0x6e;
						} break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x6e; e[2] = z80GetIDxoffset(lp); if (cparen(lp)) {
																 	e[0] = reg;
																 } break;
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
					if (oparen(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							b = GetWord(lp); e[1] = 0x4b; e[2] = b & 255; e[3] = (b >> 8) & 255; if (cparen(lp)) {
																								 	e[0] = 0xed;
																								 } break;
						}
					} else {
						if (oparen(lp, '(')) {
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
						if (cparen(lp)) {
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
						if (cparen(lp)) {
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
					if (oparen(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							b = GetWord(lp); e[1] = 0x5b; e[2] = b & 255; e[3] = (b >> 8) & 255;
							if (cparen(lp)) {
								e[0] = 0xed;
							} break;
						}
					} else {
						if (oparen(lp, '(')) {
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
						if (cparen(lp)) {
							e[0] = 0x5e;
						} e[1] = 0x23; e[2] = 0x56; e[3] = 0x2b; break;
					case Z80_IX:
					case Z80_IY:
						ASSERT_FAKE_INSTRUCTIONS(break);
						if ((b = z80GetIDxoffset(lp)) == 127) {
							// _COUT "E2 " _CMDL b _ENDL;
							Error("Offset out of range2", 0);
						} 
						if (cparen(lp)) {
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
					if (oparen(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							b = GetWord(lp); e[1] = b & 255; e[2] = (b >> 8) & 255; if (cparen(lp)) {
																						e[0] = 0x2a;
																					} break;
						}
					} else {
						if (oparen(lp, '(')) {
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
						if (cparen(lp)) {
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
					if (oparen(lp, '(') || oparen(lp, '[')) {
						b = GetWord(lp); e[1] = 0x7b; e[2] = b & 255; e[3] = (b >> 8) & 255; if (cparen(lp)) {
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
					if (oparen(lp, '[')) {
						b = GetWord(lp); e[1] = 0x2a; e[2] = b & 255; e[3] = (b >> 8) & 255; if (cparen(lp)) {
																							 	e[0] = 0xdd;
																							 } break;
					}
					if (beginhaakje = oparen(lp, '(')) {
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
					if (oparen(lp, '[')) {
						b = GetWord(lp); e[1] = 0x2a; e[2] = b & 255; e[3] = (b >> 8) & 255; if (cparen(lp)) {
																							 	e[0] = 0xfd;
																							 } break;
					}
					if (beginhaakje = oparen(lp, '(')) {
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
				if (!oparen(lp, '(') && !oparen(lp, '[')) {
					break;
				}
				switch (GetRegister(lp)) {
				case Z80_BC:
					if (!cparen(lp)) {
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
					if (!cparen(lp)) {
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
					if (!cparen(lp)) {
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
					if (!cparen(lp)) {
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
					if (!cparen(lp)) {
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
					if (!cparen(lp)) {
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
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	/* modified */
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
			/* modified */
			e[0] = e[1] = e[2] = e[3] = e[4] = e[5] = e[6] = -1;
			//if (Options::FakeInstructions) {
				switch (reg = GetRegister(lp)) {
				case Z80_A:
					if (!comma(lp)) {
						break;
					}
					if (!oparen(lp, '[') && !oparen(lp, '(')) {
						break;
					}
					switch (reg = GetRegister(lp)) {
					case Z80_BC:
						if (cparen(lp)) {
							e[0] = 0x0a;
						} e[1] = 0x0b; break;
					case Z80_DE:
						if (cparen(lp)) {
							e[0] = 0x1a;
						} e[1] = 0x1b; break;
					case Z80_HL:
						if (cparen(lp)) {
							e[0] = 0x7e;
						}
						e[1] = 0x2b;
						break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x7e; e[2] = z80GetIDxoffset(lp);
						if (cparen(lp)) {
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
					if (!oparen(lp, '[') && !oparen(lp, '(')) {
						break;
					}
					switch (reg2 = GetRegister(lp)) {
					case Z80_HL:
						if (cparen(lp)) {
							e[0] = 0x46 + reg * 8;
						} e[1] = 0x2b; break;
					case Z80_IX:
					case Z80_IY:
						e[2] = z80GetIDxoffset(lp); if (cparen(lp)) {
														e[0] = e[3] = reg2;
													} e[1] = 0x46 + reg * 8; e[4] = 0x2b; break;
					default:
						break;
					}
					break;
				default:
					if (oparen(lp, '[') || oparen(lp, '(')) {
						reg = GetRegister(lp);
						if (reg == Z80_IX || reg == Z80_IY) {
							b = z80GetIDxoffset(lp);
						}
						if (!cparen(lp) || !comma(lp)) {
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
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	void OpCode_LDDR() {
		int e[3];
		e[0] = 0xed;
		e[1] = 0xb8;
		e[2] = -1;
		EmitBytes(e);
	}

	/* modified */
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
			/* modified */
			e[0] = e[1] = e[2] = e[3] = e[4] = e[5] = e[6] = e[10] = -1;
			
				switch (reg = GetRegister(lp)) {
				case Z80_A:
					if (!comma(lp)) {
						break;
					}
					if (!oparen(lp, '[') && !oparen(lp, '(')) {
						break;
					}
					switch (reg = GetRegister(lp)) {
					case Z80_BC:
						if (cparen(lp)) {
							e[0] = 0x0a;
						} e[1] = 0x03; break;
					case Z80_DE:
						if (cparen(lp)) {
							e[0] = 0x1a;
						} e[1] = 0x13; break;
					case Z80_HL:
						if (cparen(lp)) {
							e[0] = 0x7e;
						} e[1] = 0x23; break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x7e; e[2] = z80GetIDxoffset(lp); if (cparen(lp)) {
															 		e[0] = e[3] = reg;
																 } e[4] = 0x23; break;
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
					if (!oparen(lp, '[') && !oparen(lp, '(')) {
						break;
					}
					switch (reg2 = GetRegister(lp)) {
					case Z80_HL:
						if (cparen(lp)) {
							e[0] = 0x46 + reg * 8;
						} e[1] = 0x23; break;
					case Z80_IX:
					case Z80_IY:
						e[2] = z80GetIDxoffset(lp); if (cparen(lp)) {
														e[0] = e[3] = reg2;
													} e[1] = 0x46 + reg * 8; e[4] = 0x23; break;
					default:
						break;
					}
					break;
				case Z80_BC:
					if (!comma(lp)) {
						break;
					}
					if (!oparen(lp, '[') && !oparen(lp, '(')) {
						break;
					}
					switch (reg = GetRegister(lp)) {
					case Z80_HL:
						if (cparen(lp)) {
							e[0] = 0x4e;
						} e[1] = e[3] = 0x23; e[2] = 0x46; break;
					case Z80_IX:
					case Z80_IY:
						e[2] = e[7] = z80GetIDxoffset(lp); if (cparen(lp)) {
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
					if (!oparen(lp, '[') && !oparen(lp, '(')) {
						break;
					}
					switch (reg = GetRegister(lp)) {
					case Z80_HL:
						if (cparen(lp)) {
							e[0] = 0x5e;
						} e[1] = e[3] = 0x23; e[2] = 0x56; break;
					case Z80_IX:
					case Z80_IY:
						e[2] = e[7] = z80GetIDxoffset(lp); if (cparen(lp)) {
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
					if (!oparen(lp, '[') && !oparen(lp, '(')) {
						break;
					}
					switch (reg = GetRegister(lp)) {
					case Z80_IX:
					case Z80_IY:
						e[2] = e[7] = z80GetIDxoffset(lp); if (cparen(lp)) {
													   		e[0] = e[3] = e[5] = e[8] = reg;
														   }
						e[1] = 0x6e; e[6] = 0x66; e[4] = e[9] = 0x23; break;
					default:
						break;
					}
					break;
				default:
					if (oparen(lp, '[') || oparen(lp, '(')) {
						reg = GetRegister(lp);
						if (reg == Z80_IX || reg == Z80_IY) {
							b = z80GetIDxoffset(lp);
						}
						if (!cparen(lp) || !comma(lp)) {
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
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	void OpCode_LDIR() {
		int e[3];
		e[0] = 0xed;
		e[1] = 0xb0;
		e[2] = -1;
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
		int e[3];
		e[0] = 0xed;
		e[1] = 0x44;
		e[2] = -1;
		EmitBytes(e);
	}

	void OpCode_NOP() {
		EmitByte(0x0);
	}

	/* modified */
	void OpCode_OR() {
		Z80Reg reg;
		int e[4];
		do {
			/* added */
			e[0] = e[1] = e[2] = e[3] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_A:
				/*if (!comma(lp)) { e[0]=0xb7; break; }
							reg=GetRegister(lp);*/
				e[0] = 0xb7; break; /* added */
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
					reg = Z80_UNK;
					if (oparen(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							break;
						}
					} else if (oparen(lp, '(')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							--lp;
						}
					}
					switch (reg) {
					case Z80_HL:
						if (cparen(lp)) {
							e[0] = 0xb6;
						}
						break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0xb6; e[2] = z80GetIDxoffset(lp);
						if (cparen(lp)) {
							e[0] = reg;
						}
						break;
					default:
						e[0] = 0xf6; e[1] = GetByte(lp); break;
					}
				}
			}
			EmitBytes(e);
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	void OpCode_OTDR() {
		int e[3];
		e[0] = 0xed;
		e[1] = 0xbb;
		e[2] = -1;
		EmitBytes(e);
	}

	void OpCode_OTIR() {
		int e[3];
		e[0] = 0xed;
		e[1] = 0xb3;
		e[2] = -1;
		EmitBytes(e);
	}

	/* modified */
	void OpCode_OUT() {
		Z80Reg reg;
		int e[3];
		do {
			/* added */
			e[0] = e[1] = e[2] = -1;
			if (oparen(lp, '[') || oparen(lp, '(')) {
				if (GetRegister(lp) == Z80_C) {
					if (cparen(lp)) {
						if (comma(lp)) {
							switch (reg = GetRegister(lp)) {
							case Z80_A:
								e[0] = 0xed; e[1] = 0x79; break;
							case Z80_B:
								e[0] = 0xed; e[1] = 0x41; break;
							case Z80_C:
								e[0] = 0xed; e[1] = 0x49; break;
							case Z80_D:
								e[0] = 0xed; e[1] = 0x51; break;
							case Z80_E:
								e[0] = 0xed; e[1] = 0x59; break;
							case Z80_H:
								e[0] = 0xed; e[1] = 0x61; break;
							case Z80_L:
								e[0] = 0xed; e[1] = 0x69; break;
							default:
								if (!GetByte(lp)) {
									e[0] = 0xed;
								} e[1] = 0x71; break;
							}
						}
					}
				} else {
					e[1] = GetByte(lp);
					if (cparen(lp)) {
						if (comma(lp)) {
							if (GetRegister(lp) == Z80_A) {
								e[0] = 0xd3;
							}
						}
					}
				}
			}
			EmitBytes(e);
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	void OpCode_OUTD() {
		int e[3];
		e[0] = 0xed;
		e[1] = 0xab;
		e[2] = -1;
		EmitBytes(e);
	}

	void OpCode_OUTI() {
		int e[3];
		e[0] = 0xed;
		e[1] = 0xa3;
		e[2] = -1;
		EmitBytes(e);
	}

	/* added */
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

	/* modified. old version of this procedure is pizPOPreverse() */
	void OpCode_POP() {
		int e[30],t = 0,c = 1;
		do {
			switch (GetRegister(lp)) {
			case Z80_AF:
				e[t++] = 0xf1; break;
			case Z80_BC:
				e[t++] = 0xc1; break;
			case Z80_DE:
				e[t++] = 0xd1; break;
			case Z80_HL:
				e[t++] = 0xe1; break;
			case Z80_IX:
				e[t++] = 0xdd; e[t++] = 0xe1; break;
			case Z80_IY:
				e[t++] = 0xfd; e[t++] = 0xe1; break;
			default:
				c = 0; break;
			}
			if (!comma(lp) || t > 27) {
				c = 0;
			}
		} while (c);
		e[t] = -1;
		EmitBytes(e);
	}

	void OpCode_PUSH() {
		int e[30],t = 0,c = 1;
		do {
			switch (GetRegister(lp)) {
			case Z80_AF:
				e[t++] = 0xf5; break;
			case Z80_BC:
				e[t++] = 0xc5; break;
			case Z80_DE:
				e[t++] = 0xd5; break;
			case Z80_HL:
				e[t++] = 0xe5; break;
			case Z80_IX:
				e[t++] = 0xdd; e[t++] = 0xe5; break;
			case Z80_IY:
				e[t++] = 0xfd; e[t++] = 0xe5; break;
			default:
				c = 0; break;
			}
			if (!comma(lp) || t > 27) {
				c = 0;
			}
		} while (c);
		e[t] = -1;
		EmitBytes(e);
	}

	/* modified */
	void OpCode_RES() {
		Z80Reg reg;
		int e[5], bit;
		do {
			/* added */
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
				if (!oparen(lp, '[') && !oparen(lp, '(')) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					if (cparen(lp)) {
						e[0] = 0xcb;
					}
					e[1] = 8 * bit + 0x86; break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 8 * bit + 0x86;
					if (cparen(lp)) {
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
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	/* modified */
	void OpCode_RET() {
		int e;
		do {
			/* added */
			switch (getz80cond(lp)) {
			case Z80C_C:
				e = 0xd8; break;
			case Z80C_M:
				e = 0xf8; break;
			case Z80C_NC:
				e = 0xd0; break;
			case Z80C_NZ:
				e = 0xc0; break;
			case Z80C_P:
				e = 0xf0; break;
			case Z80C_PE:
				e = 0xe8; break;
			case Z80C_PO:
				e = 0xe0; break;
			case Z80C_Z:
				e = 0xc8; break;
			default:
				e = 0xc9; break;
			}
			EmitByte(e);
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	void OpCode_RETI() {
		int e[3];
		e[0] = 0xed;
		e[1] = 0x4d;
		e[2] = -1;
		EmitBytes(e);
	}

	void OpCode_RETN() {
		int e[3];
		e[0] = 0xed;
		e[1] = 0x45;
		e[2] = -1;
		EmitBytes(e);
	}

	/* modified */
	void OpCode_RL() {
		Z80Reg reg;
		int e[5];
		do {
			/* added */
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
				if (!oparen(lp, '[') && !oparen(lp, '(')) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					if (cparen(lp)) {
						e[0] = 0xcb;
					} 
					e[1] = 0x16; break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 0x16;
					if (cparen(lp)) {
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
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	void OpCode_RLA() {
		EmitByte(0x17);
	}

	/* modified */
	void OpCode_RLC() {
		Z80Reg reg;
		int e[5];
		do {
			/* added */
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
				if (!oparen(lp, '[') && !oparen(lp, '(')) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					if (cparen(lp)) {
						e[0] = 0xcb;
					} 
					e[1] = 0x6; break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 0x6;
					if (cparen(lp)) {
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
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	void OpCode_RLCA() {
		EmitByte(0x7);
	}

	void OpCode_RLD() {
		int e[3];
		e[0] = 0xed;
		e[1] = 0x6f;
		e[2] = -1;
		EmitBytes(e);
	}

	/* modified */
	void OpCode_RR() {
		Z80Reg reg;
		int e[5];
		do {
			/* added */
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
				if (!oparen(lp, '[') && !oparen(lp, '(')) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					if (cparen(lp)) {
						e[0] = 0xcb;
					} 
					e[1] = 0x1e; break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 0x1e;
					if (cparen(lp)) {
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
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	void OpCode_RRA() {
		EmitByte(0x1f);
	}

	/* modified */
	void OpCode_RRC() {
		Z80Reg reg;
		int e[5];
		do {
			/* added */
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
				if (!oparen(lp, '[') && !oparen(lp, '(')) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					if (cparen(lp)) {
						e[0] = 0xcb;
					} 
					e[1] = 0xe; break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 0xe;
					if (cparen(lp)) {
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
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	void OpCode_RRCA() {
		EmitByte(0xf);
	}

	void OpCode_RRD() {
		int e[3];
		e[0] = 0xed;
		e[1] = 0x67;
		e[2] = -1;
		EmitBytes(e);
	}

	/* modified */
	void OpCode_RST() {
		int e;
		do {
			/* added */
			switch (GetByte(lp)) {
			case 0x00:
				e = 0xc7; break;
			case 0x08:
				e = 0xcf; break;
			case 0x10:
				e = 0xd7; break;
			case 0x18:
				e = 0xdf; break;
			case 0x20:
				e = 0xe7; break;
			case 0x28:
				e = 0xef; break;
			case 0x30:
				e = 0xf7; break;
			case 0x38:
				e = 0xff; break;
			default:
				Error("[RST] Illegal operand", line); *lp = 0; return;
			}
			EmitByte(e);
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	/* modified */
	void OpCode_SBC() {
		Z80Reg reg;
		int e[4];
		do {
			/* added */
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
					reg = Z80_UNK;
					if (oparen(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							break;
						}
					} else if (oparen(lp, '(')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							--lp;
						}
					}
					switch (reg) {
					case Z80_HL:
						if (cparen(lp)) {
							e[0] = 0x9e;
						}
						break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x9e; e[2] = z80GetIDxoffset(lp);
						if (cparen(lp)) {
							e[0] = reg;
						}
						break;
					default:
						e[0] = 0xde; e[1] = GetByte(lp); break;
					}
				}
			}
			EmitBytes(e);
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	void OpCode_SCF() {
		EmitByte(0x37);
	}

	/* modified */
	void OpCode_SET() {
		Z80Reg reg;
		int e[5], bit;
		do {
			/* added */
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
				if (!oparen(lp, '[') && !oparen(lp, '(')) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					if (cparen(lp)) {
						e[0] = 0xcb;
					}
					e[1] = 8 * bit + 0xc6; break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 8 * bit + 0xc6;
					if (cparen(lp)) {
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
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	/* modified */
	void OpCode_SLA() {
		Z80Reg reg;
		int e[5];
		do {
			/* added */
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
				if (!oparen(lp, '[') && !oparen(lp, '(')) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					if (cparen(lp)) {
						e[0] = 0xcb;
					} 
					e[1] = 0x26; break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 0x26;
					if (cparen(lp)) {
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
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	/* modified */
	void OpCode_SLL() {
		Z80Reg reg;
		int e[5];
		do {
			/* modified */
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
				if (!oparen(lp, '[') && !oparen(lp, '(')) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					if (cparen(lp)) {
						e[0] = 0xcb;
					} 
					e[1] = 0x36; break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 0x36;
					if (cparen(lp)) {
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
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	/* modified */
	void OpCode_SRA() {
		Z80Reg reg;
		int e[5];
		do {
			/* added */
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
				if (!oparen(lp, '[') && !oparen(lp, '(')) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					if (cparen(lp)) {
						e[0] = 0xcb;
					} 
					e[1] = 0x2e; break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 0x2e;
					if (cparen(lp)) {
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
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	/* modified */
	void OpCode_SRL() {
		Z80Reg reg;
		int e[5];
		do {
			/* added */
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
				if (!oparen(lp, '[') && !oparen(lp, '(')) {
					break;
				}
				switch (reg = GetRegister(lp)) {
				case Z80_HL:
					if (cparen(lp)) {
						e[0] = 0xcb;
					} 
					e[1] = 0x3e; break;
				case Z80_IX:
				case Z80_IY:
					e[1] = 0xcb; e[2] = z80GetIDxoffset(lp); e[3] = 0x3e;
					if (cparen(lp)) {
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
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	/* modified */
	void OpCode_SUB() {
		Z80Reg reg;
		int e[4];
		do {
			/* added */
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
				}
				break;
			case Z80_A:
				/*if (!comma(lp)) { e[0]=0x97; break; }
							reg=GetRegister(lp);*/
				e[0] = 0x97; break; /* added */
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
					reg = Z80_UNK;
					if (oparen(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							break;
						}
					} else if (oparen(lp, '(')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							--lp;
						}
					}
					switch (reg) {
					case Z80_HL:
						if (cparen(lp)) {
							e[0] = 0x96;
						}
						break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0x96; e[2] = z80GetIDxoffset(lp);
						if (cparen(lp)) {
							e[0] = reg;
						}
						break;
					default:
						e[0] = 0xd6; e[1] = GetByte(lp); break;
					}
				}
			}
			EmitBytes(e);
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	/* modified */
	void OpCode_XOR() {
		Z80Reg reg;
		int e[4];
		do {
			/* added */
			e[0] = e[1] = e[2] = e[3] = -1;
			switch (reg = GetRegister(lp)) {
			case Z80_A:
				/*if (!comma(lp)) { e[0]=0xaf; break; }
							reg=GetRegister(lp);*/
				e[0] = 0xaf; break; /* added */
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
					reg = Z80_UNK;
					if (oparen(lp, '[')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							break;
						}
					} else if (oparen(lp, '(')) {
						if ((reg = GetRegister(lp)) == Z80_UNK) {
							--lp;
						}
					}
					switch (reg) {
					case Z80_HL:
						if (cparen(lp)) {
							e[0] = 0xae;
						}
						break;
					case Z80_IX:
					case Z80_IY:
						e[1] = 0xae; e[2] = z80GetIDxoffset(lp);
						if (cparen(lp)) {
							e[0] = reg;
						}
						break;
					default:
						e[0] = 0xee; e[1] = GetByte(lp); break;
					}
				}
			}
			EmitBytes(e);
			/* (begin add) */
			if (*lp && comma(lp)) {
				continue;
			} else {
				break;
			}
		} while ('o');
		/* (end add) */
	}

	/* modified */
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
		OpCodeTable.Insert("exa", OpCode_EXA); /* added */
		OpCodeTable.Insert("exd", OpCode_EXD); /* added */
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
	}
} // eof namespace Z80

void InitCPU() {
	Z80::Init();
	InsertDirectives();
}
//eof z80.cpp
