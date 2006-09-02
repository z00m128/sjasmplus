/* 

  SjASMPlus Z80 Cross Compiler

  This is modified sources of SjASM by Aprisobal - aprisobal@tut.by

  Copyright (c) 2006 Sjoerd Mastijn

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

// direct.cpp

#include "sjdefs.h"

CFunctionTable DirectivesTable;
CFunctionTable DirectivesTable_dup;

/* modified */
int ParseDirective(bool bol) {
	char* olp = lp;
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
			return 1;
		} else {
			lp = olp;  return 0;
		}
	}

	if (DirectivesTable.zoek(n, bol)) {
		return 1;
	}
	/* (begin add) */
	else if ((!bol || Options::IsPseudoOpBOF) && *n == '.' && (isdigit((unsigned char) * (n + 1)) || *lp == '(')) {
		aint val;
		if (isdigit((unsigned char) * (n + 1))) {
			++n;
			if (!ParseExpression(n, val)) {
				Error("Syntax error", 0, CATCHALL); lp = olp; return 0;
			}
		} else if (*lp == '(') {
			if (!ParseExpression(lp, val)) {
				Error("Syntax error", 0, CATCHALL); lp = olp; return 0;
			}
		} else {
			lp = olp; return 0;
		}
		if (val < 1) {
			Error(".X must be positive integer", 0, CATCHALL); lp = olp; return 0;
		}

		int olistmacro;	char* ml;
		char* pp = mline; *pp = 0;
		STRCPY(pp, LINEMAX2, " ");

		SkipBlanks(lp);
		if (*lp) {
			STRCAT(pp, LINEMAX2, lp);
			lp += strlen(lp);
		}

		olistmacro = listmacro;
		listmacro = 1;
		ml = STRDUP(line);
		if (ml == NULL) {
			Error("No enough memory!", 0, FATAL);
		}
		do {
			STRCPY(line, LINEMAX, pp); 
			ParseLineSafe();
		} while (--val);
		STRCPY(line, LINEMAX, ml);
		listmacro = olistmacro;
		donotlist = 1; 

		delete[] ml;
		return 1;
	}
	/* (end add) */
	lp = olp;
	return 0;
}

/* added */
int ParseDirective_REPT() {
	char* olp = lp;
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
			return 1;
		} else {
			lp = olp;  return 0;
		}
	}

	if (DirectivesTable_dup.zoek(n)) {
		return 1;
	}
	lp = olp;
	return 0;
}

/* modified */
void dirBYTE() {
	int teller, e[256];
	teller = GetBytes(lp, e, 0, 0);
	if (!teller) {
		Error("BYTE/DEFB/DB with no arguments", 0); return;
	}
	EmitBytes(e);
}

void dirDC() {
	int teller, e[129];
	teller = GetBytes(lp, e, 0, 1);
	if (!teller) {
		Error("DC with no arguments", 0); return;
	}
	EmitBytes(e);
}

void dirDZ() {
	int teller, e[130];
	teller = GetBytes(lp, e, 0, 0);
	if (!teller) {
		Error("DZ with no arguments", 0); return;
	}
	e[teller++] = 0; e[teller] = -1;
	EmitBytes(e);
}

void dirABYTE() {
	aint add;
	int teller = 0,e[129];
	if (ParseExpression(lp, add)) {
		check8(add); add &= 255;
		teller = GetBytes(lp, e, add, 0);
		if (!teller) {
			Error("ABYTE with no arguments", 0); return;
		}
		EmitBytes(e);
	} else {
		Error("[ABYTE] Expression expected", 0);
	}
}

void dirABYTEC() {
	aint add;
	int teller = 0,e[129];
	if (ParseExpression(lp, add)) {
		check8(add); add &= 255;
		teller = GetBytes(lp, e, add, 1);
		if (!teller) {
			Error("ABYTEC with no arguments", 0); return;
		}
		EmitBytes(e);
	} else {
		Error("[ABYTEC] Expression expected", 0);
	}
}

void dirABYTEZ() {
	aint add;
	int teller = 0,e[129];
	if (ParseExpression(lp, add)) {
		check8(add); add &= 255;
		teller = GetBytes(lp, e, add, 0);
		if (!teller) {
			Error("ABYTEZ with no arguments", 0); return;
		}
		e[teller++] = 0; e[teller] = -1;
		EmitBytes(e);
	} else {
		Error("[ABYTEZ] Expression expected", 0);
	}
}

void dirWORD() {
	aint val;
	int teller = 0,e[129];
	SkipBlanks();
	while (*lp) {
		if (ParseExpression(lp, val)) {
			check16(val);
			if (teller > 127) {
				Error("Over 128 values in DW/DEFW/WORD", 0, FATAL);
			}
			e[teller++] = val & 65535;
		} else {
			Error("[DW/DEFW/WORD] Syntax error", lp, CATCHALL); return;
		}
		SkipBlanks();
		if (*lp != ',') {
			break;
		}
		++lp; SkipBlanks();
	}
	e[teller] = -1;
	if (!teller) {
		Error("DW/DEFW/WORD with no arguments", 0); return;
	}
	EmitWords(e);
}

void dirDWORD() {
	aint val;
	int teller = 0,e[129 * 2];
	SkipBlanks();
	while (*lp) {
		if (ParseExpression(lp, val)) {
			if (teller > 127) {
				Error("[DWORD] Over 128 values", 0, FATAL);
			}
			e[teller * 2] = val & 65535; e[teller * 2 + 1] = val >> 16; ++teller;
		} else {
			Error("[DWORD] Syntax error", lp, CATCHALL); return;
		}
		SkipBlanks();
		if (*lp != ',') {
			break;
		}
		++lp; SkipBlanks();
	}
	e[teller * 2] = -1;
	if (!teller) {
		Error("DWORD with no arguments", 0); return;
	}
	EmitWords(e);
}

void dirD24() {
	aint val;
	int teller = 0,e[129 * 3];
	SkipBlanks();
	while (*lp) {
		if (ParseExpression(lp, val)) {
			check24(val);
			if (teller > 127) {
				Error("[D24] Over 128 values", 0, FATAL);
			}
			e[teller * 3] = val & 255; e[teller * 3 + 1] = (val >> 8) & 255; e[teller * 3 + 2] = (val >> 16) & 255; ++teller;
		} else {
			Error("[D24] Syntax error", lp, CATCHALL); return;
		}
		SkipBlanks();
		if (*lp != ',') {
			break;
		}
		++lp; SkipBlanks();
	}
	e[teller * 3] = -1;
	if (!teller) {
		Error("D24 with no arguments", 0); return;
	}
	EmitBytes(e);
}

void dirBLOCK() {
	aint teller,val = 0;
	if (ParseExpression(lp, teller)) {
		if ((signed) teller < 0) {
			Error("Negative BLOCK?", 0, FATAL);
		}
		if (comma(lp)) {
			ParseExpression(lp, val);
		}
		EmitBlock(val, teller);
	} else {
		Error("[BLOCK] Syntax Error", lp, CATCHALL);
	}
}

void dirORG() {
	aint val;
	if (Options::MemoryType != MT_NONE) {
		if (ParseExpression(lp, val)) {
			if (val < 0x4000) {
				Error("ORG less than 4000h not allowed in ZX-Spectrum memory mode(key --mem=..)", lp, CATCHALL); return;
			}
			CurAddress = val;
		} else {
			Error("[ORG] Syntax error", lp, CATCHALL); return;
		}
		if (comma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[ORG] Syntax error", lp, CATCHALL); return;
			}
			if (Options::MemoryType == MT_ZX48) {
				Warning("[PAGE] ZX-Spectrum 48 doesn't support memory paging", 0);
				return;
			}
			if (val < 0) {
				Error("[ORG] Negative page number are not allowed", lp); return;
			} else if (val > MemoryPagesCount - 1) {
				char buf[LINEMAX];
				SPRINTF1(buf, LINEMAX, "[ORG] Page number must be in range 0..%s", MemoryPagesCount - 1);
			  	Error(buf, 0, CATCHALL); return;
			}
			MemoryCPage = val;
		}
		CheckPage();
	} else {
		if (ParseExpression(lp, val)) {
			CurAddress = val;
		} else {
			Error("[ORG] Syntax error", 0, CATCHALL);
		}
	}
}

void dirDISP() {
	aint val;
	if (ParseExpression(lp, val)) {
		adrdisp = CurAddress;CurAddress = val;
	} else {
		Error("[DISP] Syntax error", 0, CATCHALL); return;
	}
	PseudoORG = 1;
}

void dirENT() {
	if (!PseudoORG) {
		Error("ENT should be after DISP", 0);return;
	}
	CurAddress = adrdisp;
	PseudoORG = 0;
}

void dirPAGE() {
	aint val;
	if (Options::MemoryType == MT_NONE) {
		Error("PAGE only allowed in paged memory support mode(key --mem)", 0, CATCHALL);
		return;
	}
	if (!ParseExpression(lp, val)) {
		Error("Syntax error", 0, CATCHALL);
		return;
	}
	if (Options::MemoryType == MT_ZX48) {
		Warning("[PAGE] ZX-Spectrum 48 doesn't support memory paging", 0);
		return;
	}
	if (val < 0 || val > 7) {
		Error("[PAGE] Page number must be in range 0..7", 0, CATCHALL);
		return;
	}
	MemoryCPage = val;
	CheckPage();
}

void dirMAP() {
	AddressList = new CAddressList(AddressOfMAP, AddressList); /* from SjASM 0.39g */
	aint val;
	IsLabelNotFound = 0;
	if (ParseExpression(lp, val)) {
		AddressOfMAP = val;
	} else {
		Error("[MAP] Syntax error", 0, CATCHALL);
	}
	if (IsLabelNotFound) {
		Error("[MAP] Forward reference", 0, ALL);
	}
}

void dirENDMAP() {
	if (AddressList) {
		AddressOfMAP = AddressList->val; AddressList = AddressList->next;
	} else {
		Error("ENDMAP without MAP", 0);
	}
}

void dirALIGN() {
	aint val;
	if (!ParseExpression(lp, val)) {
		val = 4;
	}
	switch (val) {
	case 1:
		break;
	case 2:
	case 4:
	case 8:
	case 16:
	case 32:
	case 64:
	case 128:
	case 256:
	case 512:
	case 1024:
	case 2048:
	case 4096:
	case 8192:
	case 16384:
	case 32768:
		val = (~CurAddress + 1) & (val - 1);
		EmitBlock(0, val);
		break;
	default:
		Error("[ALIGN] Illegal align", 0); break;
	}
}

void dirMODULE() {
	char* n;
	ModuleList = new CStringList(ModuleName, ModuleList);
	if (ModuleName) {
		delete[] ModuleName;
	}
	if (n = GetID(lp)) {
		ModuleName = STRDUP(n);
		if (ModuleName == NULL) {
			Error("No enough memory!", 0, FATAL);
		}
	} else {
		Error("[MODULE] Syntax error", 0, CATCHALL);
	}
}

void dirENDMODULE() {
	if (ModuleList) {
		ModuleName = ModuleList->string;
		ModuleList = ModuleList->next;
	} else {
		Error("ENDMODULE without MODULE", 0);
	}
}

void dirZ80() {
	GetCPUInstruction = Z80::GetOpCode;
}

void dirEND() {
	char* p = lp;
	aint val;
	if (ParseExpression(lp, val)) {
		if (val > 65535 || val < 0) {
			char buf[LINEMAX];
			SPRINTF1(buf, LINEMAX, "[END] Invalid address: %s", val);
			Error(buf, 0, CATCHALL); return;
		}
		StartAddress = val;
	} else {
		lp = p;
	}
	IsRunning = 0;
}

void dirSIZE() {
	aint val;
	if (!ParseExpression(lp, val)) {
		Error("[SIZE] Syntax error", bp, CATCHALL); return;
	}
	if (pass == 2) {
		return;
	}
	if (size != (aint) - 1) {
		Error("[SIZE] Multiple sizes?", 0); return;
	}
	size = val;
}

void dirINCBIN() {
	aint val;
	char* fnaam;
	int offset = -1,length = -1;

	fnaam = GetFileName(lp);
	if (comma(lp)) {
		if (!comma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[INCBIN] Syntax error", bp, CATCHALL); return;
			} 
			if (val < 0) {
				Error("[INCBIN] Negative values are not allowed", bp); return;
			}
			offset = val;
		}
		if (comma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[INCBIN] Syntax error", bp, CATCHALL); return;
			} 
			if (val < 0) {
				Error("[INCBIN] Negative values are not allowed", bp); return;
			}
			length = val;
		}
	}
	BinIncFile(fnaam, offset, length);
	delete[] fnaam;
}

/* added */
void dirINCHOB() {
	aint val;
	char* fnaam, * fnaamh;
	unsigned char len[2];
	int offset = 17,length = -1,res;
	FILE* ff;

	fnaam = GetFileName(lp);
	if (comma(lp)) {
		if (!comma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[INCHOB] Syntax error", bp, CATCHALL); return;
			} 
			if (val < 0) {
				Error("[INCHOB] Negative values are not allowed", bp); return;
			}
			offset += val;
		}
		if (comma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[INCHOB] Syntax error", bp, CATCHALL); return;
			} 
			if (val < 0) {
				Error("[INCHOB] Negative values are not allowed", bp); return;
			}
			length = val;
		}
	}

	fnaamh = GetPath(fnaam, NULL);
	if (*fnaam == '<') {
		fnaam++;
	}
	if (!FOPEN_ISOK(ff, fnaamh, "rb")) {
		Error("[INCHOB] Error opening file", fnaam, FATAL);
	}
	if (fseek(ff, 0x0b, 0)) {
		Error("[INCHOB] Hobeta file has wrong format", fnaam, FATAL);
	}
	res = fread(len, 1, 2, ff);
	if (res != 2) {
		Error("[INCHOB] Hobeta file has wrong format", fnaam, FATAL);
	}
	if (length == -1) {
		length = len[0] + (len[1] << 8);
	}
	fclose(ff);
	BinIncFile(fnaam, offset, length);
	delete[] fnaam;
	delete[] fnaamh;
}

/* added */
void dirINCTRD() {
	aint val;
	char* fnaam, * fnaamh, * fnaamh2;
	char hobeta[12], hdr[17];
	int offset = -1,length = -1,res,i;
	FILE* ff;

	fnaam = GetFileName(lp);
	if (comma(lp)) {
		if (!comma(lp)) {
			fnaamh = GetHobetaFileName(lp);
			if (!*fnaamh) {
				Error("[INCTRD] Syntax error", bp, CATCHALL); return;
			}
		} else {
			Error("[INCTRD] Syntax error", bp, CATCHALL); return;
		}
	}
	if (comma(lp)) {
		if (!comma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[INCTRD] Syntax error", bp, CATCHALL); return;
			}
			if (val < 0) {
				Error("[INCTRD] Negative values are not allowed", bp); return;
			}
			offset += val;
		}
		if (comma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[INCTRD] Syntax error", bp, CATCHALL); return;
			}
			if (val < 0) {
				Error("[INCTRD] Negative values are not allowed", bp); return;
			}
			length = val;
		}
	}
	// get spectrum filename
	for (i = 0; i != 8; hobeta[i++] = 0x20) {
		;
	}
	for (i = 8; i != 11; hobeta[i++] = 0) {
		;
	}
	for (i = 0; i != 9; i++) {
		if (!*(fnaamh + i)) {
			break;
		}
		if (*(fnaamh + i) != '.') {
			hobeta[i] = *(fnaamh + i); continue;
		} else if (*(fnaamh + i + 1)) {
			hobeta[8] = *(fnaamh + i + 1);
		}
		break;
	}
	// open TRD
	fnaamh2 = GetPath(fnaam, NULL);
	if (*fnaam == '<') {
		fnaam++;
	}
	if (!FOPEN_ISOK(ff, fnaamh2, "rb")) {
		Error("[INCTRD] Error opening file", fnaam, FATAL);
	}
	// Find file
	fseek(ff, 0, SEEK_SET);
	for (i = 0; i < 128; i++) {
		res = fread(hdr, 1, 16, ff);
		hdr[16] = 0;
		if (res != 16) {
			Error("[INCTRD] Read error", fnaam, CATCHALL); return;
		}
		if (strstr(hdr, hobeta) != NULL) {
			i = 0; break;
		}
	}
	if (i) {
		Error("[INCTRD] File not found in TRD image", fnaamh, CATCHALL); return;
	}
	if (length > 0) {
		if (offset == -1) {
			offset = 0;
		}
	} else {
		if (length == -1) {
	  		length = ((unsigned char)hdr[0x0b]) + (((unsigned char)hdr[0x0c]) << 8);
		}
		if (offset == -1) {
			offset = 0;
		} else {
			length -= offset;
		}
	}
	offset += (((unsigned char)hdr[0x0f]) << 12) + (((unsigned char)hdr[0x0e]) << 8);
	fclose(ff);

	BinIncFile(fnaam, offset, length);
	delete[] fnaam;
	delete[] fnaamh;
	delete[] fnaamh2;
}

/* added */
void dirSAVESNA() {
	if (Options::MemoryType == MT_NONE) {
		Error("SAVESNA only allowed in ZX-Spectrum memory mode(key --mem=..)", 0, FATAL);
	}
	if (pass == 1) {
		return;
	}
	aint val;
	char* fnaam;
	int start = -1;

	fnaam = GetFileName(lp);
	if (comma(lp)) {
		if (!comma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[SAVESNA] Syntax error", bp, CATCHALL); return;
			} 
			if (val < 0) {
				Error("[SAVESNA] Negative values are not allowed", bp); return;
			}
			start = val;
		} else {
		  	Error("[SAVESNA] Syntax error. No parameters", bp, CATCHALL); return;
		}
	} else {
		Error("[SAVESNA] Syntax error. No parameters", bp, CATCHALL); return;
	}
	if (!SaveSNA_ZX(fnaam, start)) {
		Error("[SAVESNA] Error writing file (Disk full?)", bp, CATCHALL); return;
	}
	delete[] fnaam;
}

/* added */
void dirSAVETAP() {
	if (Options::MemoryType == MT_NONE) {
		Error("SAVETAP only allowed in ZX-Spectrum memory mode(key --mem=..)", 0, FATAL);
	}
	if (pass == 1) {
		return;
	}
	aint val;
	char* fnaam;
	int start = -1;

	fnaam = GetFileName(lp);
	if (comma(lp)) {
		if (!comma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[SAVETAP] Syntax error", bp, CATCHALL); return;
			} 
			if (val < 0) {
				Error("[SAVETAP] Negative values are not allowed", bp); return;
			}
			start = val;
		} else {
		  	Error("[SAVETAP] Syntax error. No parameters", bp, CATCHALL); return;
		}
	} else {
		Error("[SAVETAP] Syntax error. No parameters", bp, CATCHALL); return;
	}
	if (!SaveTAP_ZX(fnaam, start)) {
		Error("[SAVETAP] Error writing file (Disk full?)", bp, CATCHALL); return;
	}
	delete[] fnaam;
}

/* added */
void dirSAVEBIN() {
	if (Options::MemoryType == MT_NONE) {
		Error("SAVEBIN only allowed in ZX-Spectrum memory mode(key --mem=..)", 0, FATAL);
	}
	if (pass == 1) {
		return;
	}
	aint val;
	char* fnaam;
	int start = -1,length = -1;

	fnaam = GetFileName(lp);
	if (comma(lp)) {
		if (!comma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[SAVEBIN] Syntax error", bp, CATCHALL); return;
			} 
			if (val < 0x4000) {
				Error("[SAVEBIN] Values less than 4000h are not allowed", bp); return;
			} else if (val > 0xFFFF) {
			  	Error("[SAVEBIN] Values more than FFFFh are not allowed", bp); return;
			}
			start = val;
		} else {
		  	Error("[SAVEBIN] Syntax error. No parameters", bp, CATCHALL); return;
		}
		if (comma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[SAVEBIN] Syntax error", bp, CATCHALL); return;
			} 
			if (val < 0) {
				Error("[SAVEBIN] Negative values are not allowed", bp); return;
			}
			length = val;
		}
	} else {
		Error("[SAVEBIN] Syntax error. No parameters", bp, CATCHALL); return;
	}
	if (!SaveBinary(fnaam, start, length)) {
		Error("[SAVEBIN] Error writing file (Disk full?)", bp, CATCHALL); return;
	}
	delete[] fnaam;
}

/* added */
void dirSAVEHOB() {
	if (Options::MemoryType == MT_NONE) {
		Error("SAVEHOB only allowed in ZX-Spectrum memory mode(key --mem=..)", 0, FATAL);
	}
	if (pass == 1) {
		return;
	}
	aint val;
	char* fnaam, * fnaamh;
	int start = -1,length = -1;

	fnaam = GetFileName(lp);
	if (comma(lp)) {
		if (!comma(lp)) {
			fnaamh = GetHobetaFileName(lp);
			if (!*fnaamh) {
				Error("[SAVEHOB] Syntax error", bp, CATCHALL); return;
			}
		} else {
		  	Error("[SAVEHOB] Syntax error. No parameters", bp, CATCHALL); return;
		}
	}

	if (comma(lp)) {
		if (!comma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[SAVEHOB] Syntax error", bp, CATCHALL); return;
			} 
			if (val < 0x4000) {
				Error("[SAVEHOB] Values less than 4000h are not allowed", bp); return;
			} else if (val > 0xFFFF) {
			  	Error("[SAVEHOB] Values more than FFFFh are not allowed", bp); return;
			}
			start = val;
		} else {
		  	Error("[SAVEHOB] Syntax error. No parameters", bp, CATCHALL); return;
		}
		if (comma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[SAVEHOB] Syntax error", bp, CATCHALL); return;
			} 
			if (val < 0) {
				Error("[SAVEHOB] Negative values are not allowed", bp); return;
			}
			length = val;
		}
	} else {
		Error("[SAVEHOB] Syntax error. No parameters", bp, CATCHALL); return;
	}
	if (!SaveHobeta(fnaam, fnaamh, start, length)) {
		Error("[SAVEHOB] Error writing file (Disk full?)", bp, CATCHALL); return;
	}
	delete[] fnaam;
	delete[] fnaamh;
}

/* added */
void dirEMPTYTRD() {
	if (pass == 1) {
		return;
	}
	char* fnaam;

	fnaam = GetFileName(lp);
	if (!*fnaam) {
		Error("[EMPTYTRD] Syntax error", bp, CATCHALL); return;
	}
	TRD_SaveEmpty(fnaam);
	delete[] fnaam;
}

/* added */
void dirSAVETRD() {
	if (Options::MemoryType == MT_NONE) {
		Error("SAVETRD only allowed in ZX-Spectrum memory mode(key --mem=..)", 0, FATAL);
	}
	if (pass == 1) {
		return;
	}
	aint val;
	char* fnaam, * fnaamh;
	int start = -1,length = -1;

	fnaam = GetFileName(lp);
	if (comma(lp)) {
		if (!comma(lp)) {
			fnaamh = GetHobetaFileName(lp);
			if (!*fnaamh) {
				Error("[SAVETRD] Syntax error", bp, CATCHALL); return;
			}
		} else {
		  	Error("[SAVETRD] Syntax error. No parameters", bp, CATCHALL); return;
		}
	}

	if (comma(lp)) {
		if (!comma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[SAVETRD] Syntax error", bp, CATCHALL); return;
			} 
			if (val < 0x4000) {
				Error("[SAVETRD] Values less than 4000h are not allowed", bp); return;
			} else if (val > 0xFFFF) {
			  	Error("[SAVETRD] Values more than FFFFh are not allowed", bp); return;
			}
			start = val;
		} else {
		  	Error("[SAVETRD] Syntax error. No parameters", bp, CATCHALL); return;
		}
		if (comma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[SAVETRD] Syntax error", bp, CATCHALL); return;
			} 
			if (val < 0) {
				Error("[SAVETRD] Negative values are not allowed", bp); return;
			}
			length = val;
		}
	} else {
		Error("[SAVETRD] Syntax error. No parameters", bp, CATCHALL); return;
	}
	TRD_AddFile(fnaam, fnaamh, start, length);
	delete[] fnaam;
	delete[] fnaamh;
}

/* added */
void dirENCODING() {
	char* opt = GetHobetaFileName(lp);
	char* opt2 = opt;
	if (!(*opt)) {
		Error("[ENCODING] Syntax error. No parameters", bp, CATCHALL); return;
	}
	do {
		*opt2 = (char) tolower(*opt2);
	} while (*(opt2++));
	if (!strcmp(opt, "dos")) {
		c_encoding = ENCDOS;delete[] opt;return;
	}
	if (!strcmp(opt, "win")) {
		c_encoding = ENCWIN;delete[] opt;return;
	}
	Error("[ENCODING] Syntax error. Bad parameter", bp, CATCHALL); delete[] opt;return;
}

/* added */
void dirLABELSLIST() {
	if (Options::MemoryType == MT_NONE) {
		Error("LABELSLIST only allowed in ZX-Spectrum memory mode(key --mem=..)", 0, FATAL);
	}
	if (pass != 1) {
		SkipParam(lp);return;
	}
	char* opt = GetFileName(lp);
	if (!(*opt)) {
		Error("[LABELSLIST] Syntax error. No parameters", bp, CATCHALL); return;
	}
	STRCPY(Options::UnrealLabelListFName, LINEMAX, opt);
	delete[] opt;
}

/* deleted */
/*void dirTEXTAREA() {

}*/

/* modified */
void dirIF() {
	aint val;
	IsLabelNotFound = 0;
	/*if (!ParseExpression(p,val)) { Error("Syntax error",0,CATCHALL); return; }*/
	if (!ParseExpression(lp, val)) {
		Error("[IF] Syntax error", 0, CATCHALL); return;
	}
	/*if (IsLabelNotFound) Error("Forward reference",0,ALL);*/
	if (IsLabelNotFound) {
		Error("[IF] Forward reference", 0, ALL);
	}

	if (val) {
		ListFile();
		/*switch (ReadFile()) {*/
		switch (ReadFile(lp, "[IF] No endif")) {
			/*case ELSE: if (SkipFile()!=ENDIF) Error("No endif",0); break;*/
		case ELSE:
			if (SkipFile(lp, "[IF] No endif") != ENDIF) {
				Error("[IF] No endif", 0);
			} break;
		case ENDIF:
			break;
			/*default: Error("No endif!",0); break;*/
		default:
			Error("[IF] No endif!", 0); break;
		}
	} else {
		ListFile();
		/*switch (SkipFile()) {*/
		switch (SkipFile(lp, "[IF] No endif")) {
			/*case ELSE: if (ReadFile()!=ENDIF) Error("No endif",0); break;*/
		case ELSE:
			if (ReadFile(lp, "[IF] No endif") != ENDIF) {
				Error("[IF] No endif", 0);
			} break;
		case ENDIF:
			break;
			/*default: Error("No endif!",0); break;*/
		default:
			Error("[IF] No endif!", 0); break;
		}
	}
	/**lp=0;*/
}

/* added */
void dirIFN() {
	aint val;
	IsLabelNotFound = 0;
	if (!ParseExpression(lp, val)) {
		Error("[IFN] Syntax error", 0, CATCHALL); return;
	}
	if (IsLabelNotFound) {
		Error("[IFN] Forward reference", 0, ALL);
	}

	if (!val) {
		ListFile();
		switch (ReadFile(lp, "[IFN] No endif")) {
		case ELSE:
			if (SkipFile(lp, "[IFN] No endif") != ENDIF) {
				Error("[IFN] No endif", 0);
			} break;
		case ENDIF:
			break;
		default:
			Error("[IFN] No endif!", 0); break;
		}
	} else {
		ListFile();
		switch (SkipFile(lp, "[IFN] No endif")) {
		case ELSE:
			if (ReadFile(lp, "[IFN] No endif") != ENDIF) {
				Error("[IFN] No endif", 0);
			} break;
		case ENDIF:
			break;
		default:
			Error("[IFN] No endif!", 0); break;
		}
	}
}

void dirELSE() {
	Error("ELSE without IF", 0);
}

void dirENDIF() {
	Error("ENDIF without IF", 0);
}

/* deleted */
/*void dirENDTEXTAREA() {
  Error("ENDT without TEXTAREA",0);
}*/

/* modified */
void dirINCLUDE() {
	char* fnaam;
	fnaam = GetFileName(lp);
	ListFile(); /*OpenFile(fnaam);*/ IncludeFile(fnaam); donotlist = 1;
	delete[] fnaam;
}

/* modified */
void dirOUTPUT() {
	char* fnaam;

	fnaam = GetFileName(lp); //if (fnaam[0]=='<') fnaam++;
	/* begin from SjASM 0.39g */
	int mode = OUTPUT_TRUNCATE;
	if (comma(lp)) {
		char modechar = (*lp) | 0x20;
		lp++;
		if (modechar == 't') {
			mode = OUTPUT_TRUNCATE;
		} else if (modechar == 'r') {
			mode = OUTPUT_REWIND;
		} else if (modechar == 'a') {
			mode = OUTPUT_APPEND;
		} else {
			Error("Syntax error", bp, CATCHALL);
		}
	}
	if (pass == 2) {
		NewDest(fnaam, mode);
	}
	/* end from SjASM 0.39g */
	//if (pass==2) NewDest(fnaam);
	delete[] fnaam; /* added */
}

/* modified */
void dirDEFINE() {
	char* id;

	if (!(id = GetID(lp))) {
		Error("[DEFINE] Illegal define", 0); return;
	}

	DefineTable.Add(id, lp, 0);
}

/* modified */
void dirIFDEF() {
	/*char *p=line,*id;*/
	char* id;
	/* (this was cutted)
	while ('o') {
	  if (!*p) Error("ifdef error",0,FATAL);
	  if (*p=='.') { ++p; continue; }
	  if (*p=='i' || *p=='I') break;
	  ++p;
	}
	if (!cmphstr(p,"ifdef")) Error("ifdef error",0,FATAL);
	*/
	EReturn res;
	if (!(id = GetID(lp))) {
		Error("[IFDEF] Illegal identifier", 0, PASS1); return;
	}

	if (DefineTable.FindDuplicate(id)) {
		ListFile();
		/*switch (res=ReadFile()) {*/
		switch (res = ReadFile(lp, "[IFDEF] No endif")) {
			/*case ELSE: if (SkipFile()!=ENDIF) Error("No endif",0); break;*/
		case ELSE:
			if (SkipFile(lp, "[IFDEF] No endif") != ENDIF) {
				Error("[IFDEF] No endif", 0);
			} break;
		case ENDIF:
			break;
			/*default: Error("No endif!",0); break;*/
		default:
			Error("[IFDEF] No endif!", 0); break;
		}
	} else {
		ListFile();
		/*switch (res=SkipFile()) {*/
		switch (res = SkipFile(lp, "[IFDEF] No endif")) {
			/*case ELSE: if (ReadFile()!=ENDIF) Error("No endif",0); break;*/
		case ELSE:
			if (ReadFile(lp, "[IFDEF] No endif") != ENDIF) {
				Error("[IFDEF] No endif", 0);
			} break;
		case ENDIF:
			break;
			/*default: Error(" No endif!",0); break;*/
		default:
			Error("[IFDEF] No endif!", 0); break;
		}
	}
	/**lp=0;*/
}

/* modified */
void dirIFNDEF() {
	/*char *p=line,*id;*/
	char* id;
	/* (this was cutted)
	while ('o') {
	  if (!*p) Error("ifndef error",0,FATAL);
	  if (*p=='.') { ++p; continue; }
	  if (*p=='i' || *p=='I') break;
	  ++p;
	}
	if (!cmphstr(p,"ifndef")) Error("ifndef error",0,FATAL);
	*/
	EReturn res;
	if (!(id = GetID(lp))) {
		Error("[IFNDEF] Illegal identifier", 0, PASS1); return;
	}

	if (!DefineTable.FindDuplicate(id)) {
		ListFile();
		/*switch (res=ReadFile()) {*/
		switch (res = ReadFile(lp, "[IFNDEF] No endif")) {
			/*case ELSE: if (SkipFile()!=ENDIF) Error("No endif",0); break;*/
		case ELSE:
			if (SkipFile(lp, "[IFNDEF] No endif") != ENDIF) {
				Error("[IFNDEF] No endif", 0);
			} break;
		case ENDIF:
			break;
			/*default: Error("No endif!",0); break;*/
		default:
			Error("[IFNDEF] No endif!", 0); break;
		}
	} else {
		ListFile();
		/*switch (res=SkipFile()) {*/
		switch (res = SkipFile(lp, "[IFNDEF] No endif")) {
			/*case ELSE: if (ReadFile()!=ENDIF) Error("No endif",0); break;*/
		case ELSE:
			if (ReadFile(lp, "[IFNDEF] No endif") != ENDIF) {
				Error("[IFNDEF] No endif", 0);
			} break;
		case ENDIF:
			break;
			/*default: Error("No endif!",0); break;*/
		default:
			Error("[IFNDEF] No endif!", 0); break;
		}
	}
	/**lp=0;*/
}

/* modified */
void dirEXPORT() {
	aint val;
	char* n, * p;
	if (pass == 1) {
		return;
	}
	if (!Options::ExportFName[0]) {
		STRCPY(Options::ExportFName, LINEMAX, SourceFNames[CurrentSourceFName]);
		if (!(p = strchr(Options::ExportFName, '.'))) {
			p = Options::ExportFName;
		} else {
			*p = 0;
		}
		STRCAT(p, LINEMAX, ".exp");
		Warning("[EXPORT] Filename for exportfile was not indicated. Output will be in", Options::ExportFName);
	}
	if (!(n = p = GetID(lp))) {
		Error("[EXPORT] Syntax error", lp, CATCHALL); return;
	}
	IsLabelNotFound = 0;

	GetLabelValue(n, val);
	if (IsLabelNotFound) {
		Error("[EXPORT] Label not found", p, SUPPRESS); return;
	}
	WriteExp(p, val);
}

int printdec(char*& p, aint val) {
	int size = 0;
	for (int i = 10000; i != 0; i /= 10) {
		if (!size) {
			if (!(val / i)) {
				continue;
			}
		}
		size++;
		*(p++) = (char) ((val / i) + '0');
		val -= (val / i) * i;
	}
	if (!size) {
		*(p++) = '0';++size;
	}
	return size;
}

/* added */
void dirDISPLAY() {
	if (pass != 2) {
		return;
	}
	char decprint = 0;
	char e[LINEMAX];
	char* e1;
	aint val;
	int t = 0;
	while ('o') {
		SkipBlanks(lp);
		if (!*lp) {
			Error("[DISPLAY] Expression expected", 0, SUPPRESS); break;
		}
		if (t == LINEMAX - 1) {
			Error("[DISPLAY] Too many arguments", lp, SUPPRESS); break;
		}
		if (*(lp) == '/') {
			++lp;
			switch (*(lp++)) {
			case 'A':
			case 'a':
				decprint = 2;break;
			case 'D':
			case 'd':
				decprint = 1;break;
			case 'H':
			case 'h':
				decprint = 0;break ;
			case 'L':
			case 'l':
				break ;
			case 'T':
			case 't':
				break ;
			default:
				Error("[DISPLAY] Syntax error", line, SUPPRESS);return;
			}
			SkipBlanks(lp);

			if ((*(lp) != 0x2c)) {
				Error("[DISPLAY] Syntax error", line, SUPPRESS);return;
			}
			++lp;
			SkipBlanks(lp);
		}

		if (*lp == '"') {
			lp++;
			do {
				if (!*lp || *lp == '"') {
					Error("[DISPLAY] Syntax error", line, SUPPRESS); e[t] = 0; return;
				}
				if (t == 128) {
					Error("[DISPLAY] Too many arguments", line, SUPPRESS); e[t] = 0; return;
				}
				GetCharConstChar(lp, val); check8(val); e[t++] = (char) (val & 255);
			} while (*lp != '"');
			++lp;
		} else if (*lp == 0x27) {
		  	lp++;
			do {
				if (!*lp || *lp == 0x27) {
		  			Error("[DISPLAY] Syntax error", line, SUPPRESS); e[t] = 0; return;
				}
				if (t == LINEMAX - 1) {
		  			Error("[DISPLAY] Too many arguments", line, SUPPRESS); e[t] = 0; return;
				}
		  		GetCharConstCharSingle(lp, val); check8(val); e[t++] = (char) (val & 255);
			} while (*lp != 0x27);
		  	++lp;
		} else {
		  	displayerror = 0;displayinprocces = 1;
			if (ParseExpression(lp, val)) {
				if (displayerror) {
					displayinprocces = 0;
					Error("[DISPLAY] Bad argument", line, SUPPRESS);
					return;
				} else {
		  		  	displayinprocces = 0;
		  		  	check16(val); 
					if (decprint == 0 || decprint == 2) {
		  		  		e[t++] = '0';e[t++] = 'x';PrintHEX16(e1 = &e[0] + t, val);
		  		  		t += 4;
					}
					if (decprint == 2) {
						e[t++] = ',';
					}
					if (decprint == 1 || decprint == 2) {
						t += printdec(e1 = &e[0] + t, val);
					}
		  		  	decprint = 0;
				}
			} else {
				Error("[DISPLAY] Syntax error", line, SUPPRESS); return;
			}
		}
		SkipBlanks(lp);
		if (*lp != ',') {
			break;
		}
		++lp;
	}
	e[t] = 0;
	cout << "> " << e << endl;
}

/* modified */
void dirMACRO() {
	//if (lijst) Error("No macro definitions allowed here",0,FATAL);
	if (lijst) {
		Error("[MACRO] No macro definitions allowed here", 0, FATAL);
	}
	char* n;
	//if (!(n=GetID(lp))) { Error("Illegal macroname",0,PASS1); return; }
	if (!(n = GetID(lp))) {
		Error("[MACRO] Illegal macroname", 0, PASS1); return;
	}
	MacroTable.Add(n, lp);
}

void dirENDS() {
	Error("[ENDS] End structre without structure", 0);
}

/* modified */
void dirASSERT() {
	char* p = lp;
	aint val;
	/*if (!ParseExpression(lp,val)) { Error("Syntax error",0,CATCHALL); return; }
	if (pass==2 && !val) Error("Assertion failed",p);*/
	if (!ParseExpression(lp, val)) {
		Error("[ASSERT] Syntax error", 0, CATCHALL); return;
	}
	if (pass == 2 && !val) {
		Error("[ASSERT] Assertion failed", p);
	}
	/**lp=0;*/
}

void dirSHELLEXEC() {
	char* command;
	command = GetFileName(lp);
	//cout << "Executing " << command << endl;
	system(command);
	delete[] command;
}

void dirSTRUCT() {
	CStructure* st;
	int global = 0;
	aint offset = 0,bind = 0;
	char* naam;
	SkipBlanks();
	if (*lp == '@') {
		++lp; global = 1;
	}
	if (!(naam = GetID(lp))) {
		Error("[STRUCT] Illegal structure name", 0, PASS1); return;
	}
	if (comma(lp)) {
		IsLabelNotFound = 0;
		if (!ParseExpression(lp, offset)) {
			Error("[STRUCT] Syntax error", 0, CATCHALL); return;
		}
		if (IsLabelNotFound) {
			Error("[STRUCT] Forward reference", 0, ALL);
		}
	}
	st = StructureTable.Add(naam, offset, bind, global);
	ListFile();
	while ('o') {
		if (!ReadLine()) {
			Error("[STRUCT] Unexpected end of structure", 0, PASS1); break;
		}
		lp = line; /*if (White()) { SkipBlanks(lp); if (*lp=='.') ++lp; if (cmphstr(lp,"ends")) break; }*/
		SkipBlanks(lp); if (*lp == '.') {
							++lp;
						} if (cmphstr(lp, "ends")) {
						  	break;
						  }
		ParseStructLine(st);
		ListFileSkip(line);
	}
	st->deflab();
}

/* added from SjASM 0.39g */
void dirFORG() {
	aint val;
	int method = SEEK_SET;
	SkipBlanks(lp);
	if ((*lp == '+') || (*lp == '-')) {
		method = SEEK_CUR;
	}
	if (!ParseExpression(lp, val)) {
		Error("[FORG] Syntax error", 0, CATCHALL);
	}
	if (pass == 2) {
		SeekDest(val, method);
	}
}

/* i didn't modify it */
/*
void dirBIND() {
}
*/

/* added */
void dirDUP() {
	aint val;
	IsLabelNotFound = 0;

	if (!RepeatStack.empty()) {
		SRepeatStack& dup = RepeatStack.top();
		if (!dup.work) {
			if (!ParseExpression(lp, val)) {
				Error("[DUP/REPT] Syntax error", 0, CATCHALL); return;
			}
			dup.level++;
			return;
		}
	}

	if (!ParseExpression(lp, val)) {
		Error("[DUP/REPT] Syntax error", 0, CATCHALL); return;
	}
	if (IsLabelNotFound) {
		Error("[DUP/REPT] Forward reference", 0, ALL);
	}
	if ((int) val < 1) {
		Error("[DUP/REPT] Illegal repeat value", 0, CATCHALL); return;
	}

	SRepeatStack dup;
	dup.dupcount = val;
	dup.level = 0;

	dup.lines = new CStringList(lp, NULL);
	dup.pointer = dup.lines;
	dup.lp = lp; //чтобы брать код перед EDUP
	dup.CurrentGlobalLine = CurrentGlobalLine;
	dup.CurrentLocalLine = CurrentLocalLine;
	dup.work = false;
	RepeatStack.push(dup);
}

/* added */
void dirEDUP() {
	if (RepeatStack.empty()) {
		Error("[EDUP/ENDR] End repeat without repeat", 0);return;
	}

	if (!RepeatStack.empty()) {
		SRepeatStack& dup = RepeatStack.top();
		if (!dup.work && dup.level) {
			dup.level--;
			return;
		}
	}
	int olistmacro;
	long gcurln, lcurln;
	char* ml;
	SRepeatStack& dup = RepeatStack.top();
	dup.work = true;
	dup.pointer->string = new char[LINEMAX];
	if (dup.pointer->string == NULL) {
		Error("No enough memory!", 0, FATAL);
	}
	*dup.pointer->string = 0;
	STRNCAT(dup.pointer->string, LINEMAX, dup.lp, lp - dup.lp - 4); //чтобы взять код перед EDUP/ENDR/ENDM
	CStringList* s;
	olistmacro = listmacro;
	listmacro = 1;
	ml = STRDUP(line); 
	if (ml == NULL) {
		Error("No enough memory", 0, FATAL);
	}
	gcurln = CurrentGlobalLine;
	lcurln = CurrentLocalLine;
	while (dup.dupcount--) {
		CurrentGlobalLine = dup.CurrentGlobalLine;
		CurrentLocalLine = dup.CurrentLocalLine;
		s = dup.lines; 
		while (s) {
			STRCPY(line, LINEMAX, s->string);
			s = s->next;
			ParseLineSafe();
			CurrentLocalLine++;
			CurrentGlobalLine++;
			CurrentLine++;
		}
	}
	RepeatStack.pop();
	CurrentGlobalLine = gcurln;
	CurrentLocalLine = lcurln;
	listmacro = olistmacro;
	donotlist = 1;
	STRCPY(line, LINEMAX,  ml);

	ListFile();
}

void dirENDM() {
	if (!RepeatStack.empty()) {
		dirEDUP();
	} else {
		Error("[ENDM] End macro without macro", 0);
	}
}

/* modified */
void dirDEFARRAY() {
	char* n;
	char* id;
	char ml[LINEMAX];
	CStringList* a;
	CStringList* f;

	if (!(id = GetID(lp))) {
		Error("[DEFARRAY] Syntax error", 0); return;
	}
	SkipBlanks(lp);
	if (!*lp) {
		Error("DEFARRAY must have less one entry", 0); return;
	}

	a = new CStringList();
	f = a;
	while (*lp) {
		n = ml;
		SkipBlanks(lp);
		if (*lp == '<') {
			++lp;
			while (*lp != '>') {
				if (!*lp) {
					Error("[DEFARRAY] No closing bracket - <..>", 0); return;
				}
				if (*lp == '!') {
					++lp; if (!*lp) {
						  	Error("[DEFARRAY] No closing bracket - <..>", 0); return;
						  }
				}
				*n = *lp; ++n; ++lp;
			}
			++lp;
		} else {
			while (*lp && *lp != ',') {
				*n = *lp; ++n; ++lp;
			}
		}
		*n = 0;
		//cout << a->string << endl;
		f->string = STRDUP(ml);
		if (f->string == NULL) {
			Error("No enough memory", 0, FATAL);
		}
		SkipBlanks(lp);
		if (*lp == ',') {
			++lp;
		} else {
			break;
		}
		f->next = new CStringList();
		f = f->next;
	}
	DefineTable.Add(id, "\n", a);
	//while (a) { STRCPY(ml,a->string); cout << ml << endl; a=a->next; }
}

/* modified */
void InsertDirectives() {
	DirectivesTable.insertd("assert", dirASSERT);
	DirectivesTable.insertd("byte", dirBYTE);
	DirectivesTable.insertd("abyte", dirABYTE);
	DirectivesTable.insertd("abytec", dirABYTEC);
	DirectivesTable.insertd("abytez", dirABYTEZ);
	DirectivesTable.insertd("word", dirWORD);
	DirectivesTable.insertd("block", dirBLOCK);
	DirectivesTable.insertd("dword", dirDWORD);
	DirectivesTable.insertd("d24", dirD24);
	DirectivesTable.insertd("org", dirORG);
	DirectivesTable.insertd("map", dirMAP);
	DirectivesTable.insertd("align", dirALIGN);
	DirectivesTable.insertd("module", dirMODULE);
	DirectivesTable.insertd("z80", dirZ80);
	DirectivesTable.insertd("size", dirSIZE);
	//DirectivesTable.insertd("textarea",dirTEXTAREA);
	DirectivesTable.insertd("textarea", dirDISP);
	DirectivesTable.insertd("msx", dirZ80);
	DirectivesTable.insertd("else", dirELSE);
	DirectivesTable.insertd("export", dirEXPORT);
	DirectivesTable.insertd("display", dirDISPLAY); /* added */
	DirectivesTable.insertd("end", dirEND);
	DirectivesTable.insertd("include", dirINCLUDE);
	DirectivesTable.insertd("incbin", dirINCBIN);
	DirectivesTable.insertd("binary", dirINCBIN); /* added */
	DirectivesTable.insertd("inchob", dirINCHOB); /* added */
	DirectivesTable.insertd("inctrd", dirINCTRD); /* added */
	DirectivesTable.insertd("insert", dirINCBIN); /* added */
	DirectivesTable.insertd("savesna", dirSAVESNA); /* added */
	DirectivesTable.insertd("savehob", dirSAVEHOB); /* added */
	DirectivesTable.insertd("savebin", dirSAVEBIN); /* added */
	DirectivesTable.insertd("emptytrd", dirEMPTYTRD); /* added */
	DirectivesTable.insertd("savetrd", dirSAVETRD); /* added */
	DirectivesTable.insertd("savetap", dirSAVETAP); /* added */
	DirectivesTable.insertd("shellexec", dirSHELLEXEC); /* added */
	DirectivesTable.insertd("if", dirIF);
	DirectivesTable.insertd("ifn", dirIFN); /* added */
	DirectivesTable.insertd("output", dirOUTPUT);
	DirectivesTable.insertd("define", dirDEFINE);
	DirectivesTable.insertd("defarray", dirDEFARRAY); /* added */
	DirectivesTable.insertd("ifdef", dirIFDEF);
	DirectivesTable.insertd("ifndef", dirIFNDEF);
	DirectivesTable.insertd("macro", dirMACRO);
	DirectivesTable.insertd("struct", dirSTRUCT);
	DirectivesTable.insertd("dc", dirDC);
	DirectivesTable.insertd("dz", dirDZ);
	DirectivesTable.insertd("db", dirBYTE);
	DirectivesTable.insertd("dm", dirBYTE); /* added */
	DirectivesTable.insertd("dw", dirWORD);
	DirectivesTable.insertd("ds", dirBLOCK);
	DirectivesTable.insertd("dd", dirDWORD);
	DirectivesTable.insertd("defb", dirBYTE);
	DirectivesTable.insertd("defw", dirWORD);
	DirectivesTable.insertd("defs", dirBLOCK);
	DirectivesTable.insertd("defd", dirDWORD);
	DirectivesTable.insertd("defm", dirBYTE); /* added */
	DirectivesTable.insertd("endmod", dirENDMODULE);
	DirectivesTable.insertd("endmodule", dirENDMODULE);
	DirectivesTable.insertd("endmap", dirENDMAP); /* added from SjASM 0.39g */
	DirectivesTable.insertd("rept", dirDUP);
	DirectivesTable.insertd("dup", dirDUP); /* added */
	DirectivesTable.insertd("disp", dirDISP); /* added */
	DirectivesTable.insertd("phase", dirDISP); /* added */
	DirectivesTable.insertd("ent", dirENT); /* added */
	DirectivesTable.insertd("unphase", dirENT); /* added */
	DirectivesTable.insertd("dephase", dirENT); /* added */
	DirectivesTable.insertd("page", dirPAGE); /* added */
	DirectivesTable.insertd("encoding", dirENCODING); /* added */
	DirectivesTable.insertd("labelslist", dirLABELSLIST); /* added */
	//  DirectivesTable.insertd("bind",dirBIND); /* i didn't comment this */
	DirectivesTable.insertd("endif", dirENDIF);
	//DirectivesTable.insertd("endt",dirENDTEXTAREA);
	DirectivesTable.insertd("endt", dirENT);
	DirectivesTable.insertd("endm", dirENDM);
	DirectivesTable.insertd("edup", dirEDUP); /* added */
	DirectivesTable.insertd("endr", dirEDUP); /* added */
	DirectivesTable.insertd("ends", dirENDS);
	DirectivesTable_dup.insertd("dup", dirDUP); /* added */
	DirectivesTable_dup.insertd("edup", dirEDUP); /* added */
	DirectivesTable_dup.insertd("endm", dirENDM); /* added */
	DirectivesTable_dup.insertd("endr", dirEDUP); /* added */
	DirectivesTable_dup.insertd("rept", dirDUP); /* added */
}
//eof direct.cpp
