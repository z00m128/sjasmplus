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

int ParseDirective(bool beginningOfLine)
{
	char* olp = lp;
	char* n;

	// if END/.END directive is at the beginning of line = ignore them (even with "--dirbol")
	if (beginningOfLine && (cmphstr(lp, "end") || cmphstr(lp, ".end"))) {
		lp = olp;
		return 0;
	}

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

	if (DirectivesTable.zoek(n)) return 1;

	// Only "." repeat directive remains, but that one can't start at beginning of line (without --dirbol)
	if (beginningOfLine && !Options::IsPseudoOpBOF) return 0;

	if (*n == '.' && (isdigit((unsigned char) * (n + 1)) || *lp == '(')) {
		aint val;
		if (isdigit((unsigned char) * (n + 1))) {
			++n;
			if (!ParseExpression(n, val)) {
				Error("Syntax error", n, IF_FIRST); lp = olp; return 0;
			}
		} else if (*lp == '(') {
			if (!ParseExpression(lp, val)) {
				Error("Syntax error", lp, IF_FIRST); lp = olp; return 0;
			}
		} else {
			lp = olp; return 0;
		}
		if (val < 1) {
			ErrorInt(".X must be positive integer", val, IF_FIRST); lp = olp; return 0;
		}

		char* pp = mline;
		STRCPY(pp, LINEMAX2, " ");

		if (!SkipBlanks()) {
			STRCAT(pp, LINEMAX2, lp);
			lp += strlen(lp);
		}
		++listmacro;
		char* ml = STRDUP(line);
		if (ml == NULL) {
			Error("No enough memory!", NULL, FATAL);
		}
		do {
			STRCPY(line, LINEMAX, pp);
			ParseLineSafe();
		} while (--val);
		STRCPY(line, LINEMAX, ml);
		--listmacro;
		donotlist = 1;

		delete[] ml;
		return 1;
	}
	lp = olp;
	return 0;
}

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


static void getBytesWithCheck(int add = 0, int dc = 0, bool dz = false) {
	check8(add); add &= 255;
	int dirDx[130];
	if (GetBytes(lp, dirDx, add, dc)) {
		EmitBytes(dirDx);
		if (dz) EmitByte(0);
	} else {
		Error("no arguments");
	}
}

void dirBYTE() {
	getBytesWithCheck();
}

void dirDC() {
	getBytesWithCheck(0, 1);
}

void dirDZ() {
	getBytesWithCheck(0, 0, true);
}

void dirABYTE() {
	aint add;
	if (ParseExpression(lp, add))	getBytesWithCheck(add);
	else							Error("[ABYTE] Expression expected");
}

void dirABYTEC() {
	aint add;
	if (ParseExpression(lp, add))	getBytesWithCheck(add, 1);
	else							Error("[ABYTEC] Expression expected");
}

void dirABYTEZ() {
	aint add;
	if (ParseExpression(lp, add))	getBytesWithCheck(add, 0, true);
	else							Error("[ABYTEZ] Expression expected");
}

void dirWORD() {
	aint val;
	int teller = 0, e[130];
	do {
		if (SkipBlanks()) {
			Error("Expression expected", NULL, SUPPRESS);
		} else if (ParseExpression(lp, val)) {
			check16(val);
			if (teller > 127) {
				Error("Over 128 values in DW/DEFW/WORD", NULL, SUPPRESS);
				break;
			}
			e[teller++] = val & 65535;
		} else {
			Error("[DW/DEFW/WORD] Syntax error", lp, SUPPRESS);
			break;
		}
	} while (comma(lp));
	e[teller] = -1;
	if (teller) EmitWords(e);
	else		Error("DW/DEFW/WORD with no arguments");
}

void dirDWORD() {
	aint val;
	int teller = 0, e[130 * 2];
	do {
		if (SkipBlanks()) {
			Error("Expression expected", NULL, SUPPRESS);
		} else if (ParseExpression(lp, val)) {
			if (teller > 127) {
				Error("Over 128 values in DWORD", NULL, SUPPRESS);
				break;
			}
			e[teller * 2] = val & 65535; e[teller * 2 + 1] = (val >> 16) & 0xFFFF; ++teller;
		} else {
			Error("[DWORD] Syntax error", lp, SUPPRESS);
			break;
		}
	} while (comma(lp));
	e[teller * 2] = -1;
	if (teller) EmitWords(e);
	else		Error("DWORD with no arguments");
}

void dirD24() {
	aint val;
	int teller = 0, e[130 * 3];
	do {
		if (SkipBlanks()) {
			Error("Expression expected", NULL, SUPPRESS);
		} else if (ParseExpression(lp, val)) {
			check24(val);
			if (teller > 127*3) {
				Error("Over 128 values in D24", NULL, SUPPRESS);
				break;
			}
			e[teller++] = val & 255; e[teller++] = (val >> 8) & 255; e[teller++] = (val >> 16) & 255;
		} else {
			Error("[D24] Syntax error", lp, SUPPRESS);
			break;
		}
	} while (comma(lp));
	e[teller] = -1;
	if (teller) EmitBytes(e);
	else		Error("D24 with no arguments");
}

void dirBLOCK() {
	aint teller,val = 0;
	if (ParseExpression(lp, teller)) {
		if ((signed) teller < 0) {
			Warning("Negative BLOCK?");
		}
		if (comma(lp)) {
			ParseExpression(lp, val);
		}
		EmitBlock(val, teller);
	} else {
		Error("[BLOCK] Syntax Error", lp, IF_FIRST);
	}
}

void dirORG() {
	aint val;
	if (DeviceID) {
		if (ParseExpression(lp, val)) {
			CurAddress = val;
		} else {
			Error("[ORG] Syntax error", lp, IF_FIRST); return;
		}
		if (comma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[ORG] Syntax error", lp, IF_FIRST); return;
			}
			if (val < 0) {
				Error("[ORG] Negative page number are not allowed", lp); return;
			} else if (Device->PagesCount <= val) {
				char buf[LINEMAX];
				SPRINTF1(buf, LINEMAX, "[ORG] Page number must be in range 0..%u", Device->PagesCount - 1);
			  	Error(buf, NULL, IF_FIRST); return;
			}
			Slot->Page = Device->GetPage(val);
			//Page = Slot->Page;
		}
		CheckPage();
	} else {
		if (ParseExpression(lp, val)) {
			CurAddress = val;
		} else {
			Error("[ORG] Syntax error", lp, IF_FIRST);
		}
	}
}

void dirDISP() {
	aint val;
	if (ParseExpression(lp, val)) {
		adrdisp = CurAddress;CurAddress = val;
	} else {
		Error("[DISP] Syntax error", lp, IF_FIRST); return;
	}
	PseudoORG = 1;
}

void dirENT() {
	if (!PseudoORG) {
		Error("ENT should be after DISP");return;
	}
	CurAddress = adrdisp;
	PseudoORG = 0;
}

void dirPAGE() {
	aint val;
	if (!DeviceID) {
		Warning("PAGE only allowed in real device emulation mode (See DEVICE)");
		SkipParam(lp);
		return;
	}
	if (!ParseExpression(lp, val)) {
		Error("Syntax error", lp, IF_FIRST);
		return;
	}
	if (val < 0) {
		Error("[PAGE] Negative page number are not allowed", lp); return;
	} else if (Device->PagesCount <= val) {
		char buf[LINEMAX];
		SPRINTF1(buf, LINEMAX, "[PAGE] Page number must be in range 0..%u", Device->PagesCount - 1);
		Error(buf, NULL, IF_FIRST); return;
	}

	Slot->Page = Device->GetPage(val);
	CheckPage();
}

void dirSLOT() {
	aint val;
	if (!DeviceID) {
		Warning("SLOT only allowed in real device emulation mode (See DEVICE)");
		SkipParam(lp);
		return;
	}
	if (!ParseExpression(lp, val)) {
		Error("Syntax error", lp, IF_FIRST);
		return;
	}
	if (val < 0) {
		Error("[SLOT] Negative slot number are not allowed", lp); return;
	} else if (Device->SlotsCount <= val) {
		char buf[LINEMAX];
		SPRINTF1(buf, LINEMAX, "[SLOT] Slot number must be in range 0..%u", Device->SlotsCount - 1);
		Error(buf, NULL, IF_FIRST); return;
	}
	Slot = Device->GetSlot(val);
	Device->CurrentSlot = Slot->Number;
	CheckPage();
}

void dirMAP() {
	AddressList = new CAddressList(AddressOfMAP, AddressList);
	aint val;
	IsLabelNotFound = 0;
	if (ParseExpression(lp, val)) {
		AddressOfMAP = val;
	} else {
		Error("[MAP] Syntax error", lp, IF_FIRST);
	}
	if (IsLabelNotFound) {
		Error("[MAP] Forward reference", NULL, ALL);
	}
}

void dirENDMAP() {
	if (AddressList) {
		AddressOfMAP = AddressList->val; AddressList = AddressList->next;
	} else {
		Error("ENDMAP without MAP");
	}
}

void dirALIGN() {
	// default alignment is 4, default filler is "0/none" (if not specified in directive explicitly)
	char *oldLp = lp;
	aint val, fill = 0;
	bool explicitVal;
	bool explicitFill = (explicitVal = ParseExpression(lp, val)) && comma(lp) && ParseExpression(lp, fill);
	if (!explicitVal) val = 4;
	// check if alignment value is power of two (0..15-th power only)
	if (val < 1 || (1<<15) < val || (val & (val-1))) {
		Error("[ALIGN] Illegal align", oldLp-5, SUPPRESS);
		return;
	}
	// check if filler byte is legal byte value
	if (fill < 0 || 255 < fill) {
		Error("[ALIGN] Illegal align fill-byte", oldLp-5, SUPPRESS);
		return;
	}
	// calculate how many bytes has to be filled to reach desired alignment
	aint len = (~CurAddress + 1) & (val - 1);
	if (len < 1) return;		// nothing to fill, already aligned
	EmitBlock(fill, len, !explicitFill);
}

/*void dirMODULE() {
	char* n;
	ModuleList = new CStringsList(ModuleName, ModuleList);
	if (ModuleName != NULL) {
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
		if (ModuleName != NULL) {
			delete[] ModuleName;
		}
		if (ModuleList->string != NULL) {
			ModuleName = STRDUP(ModuleList->string);
			if (ModuleName == NULL) {
				Error("No enough memory!", 0, FATAL);
			}
		} else {
			ModuleName = NULL;
		}
		ModuleList = ModuleList->next;
	} else {
		Error("ENDMODULE without MODULE", 0);
	}
}*/

void dirMODULE() {
	char* n;
	if ((n = GetID(lp))) {
		if(ModuleName == NULL)
		{
			ModuleName = STRDUP(n);
			if (ModuleName == NULL) {
				Error("Not enough memory!", NULL, FATAL);
			}
		}
		else
		{
			ModuleName = (char*)realloc(ModuleName,strlen(n)+strlen(ModuleName)+2);
			if (ModuleName == NULL) {
				Error("Not enough memory!", NULL, FATAL);
			}
			STRCAT(ModuleName, sizeof("."), ".");
			STRCAT(ModuleName, sizeof(n), n);
		}
	} else {
		Error("[MODULE] Syntax error", lp, IF_FIRST);
	}

	if (ModuleName != NULL) {
		ModuleList = new CStringsList(ModuleName, ModuleList);
	}
}

void dirENDMODULE() {
	CStringsList* tmp;

	if (ModuleList) {
		if (ModuleName != NULL) {
			free(ModuleName);
			ModuleName = NULL;
		}
		tmp = ModuleList->next;
		if(tmp!=NULL)
		{
			ModuleList->next = NULL;
			delete ModuleList;
		}
		ModuleList = tmp;
		if (ModuleList != NULL && ModuleList->string != NULL) {
			ModuleName = STRDUP(ModuleList->string);
			if (ModuleName == NULL) {
				Error("No enough memory!", NULL, FATAL);
			}
		} else {
			ModuleName = NULL;
		}
	} else {
		Error("ENDMODULE without MODULE");
	}
}

void dirZ80() {
	GetCPUInstruction = Z80::GetOpCode;
}

void dirEND() {
	char* p = lp;
	aint val;
	if (ParseExpression(lp, val)) {
		if (val > 65535 || val < 0) ErrorInt("[END] Invalid address", IF_FIRST);
		else 						StartAddress = val;
	} else {
		lp = p;
	}

	IsRunning = 0;
}

void dirSIZE() {
	aint val;
	if (!ParseExpression(lp, val)) {
		Error("[SIZE] Syntax error", bp, IF_FIRST); return;
	}
	if (pass == LASTPASS) {
		return;
	}
	if (size != (aint) - 1) {
		Error("[SIZE] Multiple sizes?"); return;
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
				Error("[INCBIN] Syntax error", bp, IF_FIRST); return;
			}
			if (val < 0) {
				Error("[INCBIN] Negative values are not allowed", bp); return;
			}
			offset = val;
		} else --lp;		// there was second comma right after, reread it
		if (comma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[INCBIN] Syntax error", bp, IF_FIRST); return;
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

void dirINCHOB() {
	aint val;
	char* fnaam, * fnaamh;
	unsigned char len[2];
	int offset = 0,length = -1;
	FILE* ff;

	fnaam = GetFileName(lp);
	if (comma(lp)) {
		if (!comma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[INCHOB] Syntax error", bp, IF_FIRST); return;
			}
			if (val < 0) {
				Error("[INCHOB] Negative values are not allowed", bp); return;
			}
			offset += val;
		} else --lp;		// there was second comma right after, reread it
		if (comma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[INCHOB] Syntax error", bp, IF_FIRST); return;
			}
			if (val < 0) {
				Error("[INCHOB] Negative values are not allowed", bp); return;
			}
			length = val;
		}
	}

	fnaamh = GetPath(fnaam);
	if (!FOPEN_ISOK(ff, fnaamh, "rb")) {
		Error("[INCHOB] Error opening file", fnaam, FATAL);
	}
	if (fseek(ff, 0x0b, 0) || 2 != fread(len, 1, 2, ff)) {
		Error("[INCHOB] Hobeta file has wrong format", fnaam, FATAL);
	}
	fclose(ff);
	if (length == -1) {
		// calculate remaining length of the file (from the specified offset)
		length = len[0] + (len[1] << 8) - offset;
	}
	offset += 17;		// adjust offset (skip HOB header)
	BinIncFile(fnaam, offset, length);
	delete[] fnaam;
	delete[] fnaamh;
}

void dirINCTRD() {
	aint val;
	char* fnaam, * fnaamh, * fnaamh2;
	char hobeta[12], hdr[17];
	int offset = -1,length = -1,res,i;
	FILE* ff;

	fnaam = GetFileName(lp);
	if (comma(lp)) {
		if (!comma(lp)) {
			fnaamh = GetFileName(lp);
			if (!*fnaamh) {
				Error("[INCTRD] Syntax error", bp, IF_FIRST); return;
			}
		} else {
			Error("[INCTRD] Syntax error", bp, IF_FIRST); return;
		}
	} else {
		Error("[INCTRD] Syntax error", bp, IF_FIRST); return; //is this ok?
	}
	if (comma(lp)) {
		if (!comma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[INCTRD] Syntax error", bp, IF_FIRST); return;
			}
			if (val < 0) {
				Error("[INCTRD] Negative values are not allowed", bp); return;
			}
			offset += val;
		}
		if (comma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[INCTRD] Syntax error", bp, IF_FIRST); return;
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
	fnaamh2 = GetPath(fnaam);
	if (!FOPEN_ISOK(ff, fnaamh2, "rb")) {
		Error("[INCTRD] Error opening file", fnaam, FATAL);
	}
	// Find file
	fseek(ff, 0, SEEK_SET);
	for (i = 0; i < 128; i++) {
		res = fread(hdr, 1, 16, ff);
		hdr[16] = 0;
		if (res != 16) {
			Error("[INCTRD] Read error", fnaam, IF_FIRST); return;
		}
		if (strstr(hdr, hobeta) != NULL) {
			i = 0; break;
		}
	}
	if (i) {
		Error("[INCTRD] File not found in TRD image", fnaamh, IF_FIRST); return;
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

void dirSAVESNA() {

	if (pass != LASTPASS) {
		SkipParam(lp);
		return;
	}

	bool exec = true;

	if (!DeviceID) {
		if (pass == LASTPASS) {
			Error("SAVESNA only allowed in real device emulation mode (See DEVICE)");
		}
		exec = false;
	} else if (pass != LASTPASS) {
		exec = false;
	}

	if (exec && !IsZXSpectrumDevice(DeviceID)) {
		Error("[SAVESNA] Device must be ZXSPECTRUM48 or ZXSPECTRUM128.");
		exec = false;
	}

	aint val;
	char* fnaam;
	int start = -1;

	fnaam = GetFileName(lp);
	if (comma(lp)) {
		if (!comma(lp) && StartAddress < 0) {
			if (!ParseExpression(lp, val)) {
				Error("[SAVESNA] Syntax error", bp, PASS3); return;
			}
			if (val < 0) {
				Error("[SAVESNA] Negative values are not allowed", bp, PASS3); return;
			}
			start = val;
		} else {
			Error("[SAVESNA] Syntax error. No parameters", bp, PASS3); return;
		}
	} else if (StartAddress < 0) {
		Error("[SAVESNA] Syntax error. No parameters", bp, PASS3); return;
	} else {
		start = StartAddress;
	}

	if (exec && !SaveSNA_ZX(fnaam, start)) {
		Error("[SAVESNA] Error writing file (Disk full?)", bp, IF_FIRST); return;
	}

	delete[] fnaam;
}

void dirEMPTYTAP() {
	if (pass != LASTPASS) {
		SkipParam(lp);
		return;
	}
	char* fnaam;

	fnaam = GetFileName(lp);
	if (!*fnaam) {
		Error("[EMPTYTAP] Syntax error", bp, IF_FIRST); return;
	}
	TAP_SaveEmpty(fnaam);
	delete[] fnaam;
}

void dirSAVETAP() {

	if (pass != LASTPASS) {
		SkipParam(lp);
		return;
	}

	bool exec = true, realtapeMode = false;
	int headerType = -1;
	aint val;
	char* fnaam, *fnaamh = NULL;
	int start = -1, length = -1, param2 = -1, param3 = -1;

	if (!DeviceID) {
		if (pass == LASTPASS) {
			Error("SAVETAP only allowed in real device emulation mode (See DEVICE)");
		}
		exec = false;
	} else if (pass != LASTPASS) {
		exec = false;
	}

	fnaam = GetFileName(lp);
	if (comma(lp)) {
		if (!comma(lp)) {
			char *tlp = lp;
			char *id;

			if ((id = GetID(lp)) && strlen(id) > 0) {
				if (cmphstr(id, "basic")) {
					headerType = BASIC;
					realtapeMode = true;
				} else if (cmphstr(id, "numbers")) {
					headerType = NUMBERS;
					realtapeMode = true;
				} else if (cmphstr(id, "chars")) {
					headerType = CHARS;
					realtapeMode = true;
				} else if (cmphstr(id, "code")) {
					headerType = CODE;
					realtapeMode = true;
				} else if (cmphstr(id, "headless")) {
					headerType = HEADLESS;
					realtapeMode = true;
				}
			}

			if (realtapeMode) {
				if (comma(lp)) {
					if (headerType == HEADLESS) {
						if (!comma(lp)) {
							if (!ParseExpression(lp, val)) {
								Error("[SAVETAP] Syntax error", bp, PASS3); return;
							}
							if (val < 0) {
								Error("[SAVETAP] Negative values are not allowed", bp, PASS3); return;
							} else if (val > 0xFFFF) {
								Error("[SAVETAP] Values higher than FFFFh are not allowed", bp, PASS3); return;
							}
							start = val;
						} else {
							Error("[SAVETAP] Syntax error. Missing start address", bp, PASS3); return;
						}
						if (comma(lp)) {
							if (!ParseExpression(lp, val)) {
								Error("[SAVETAP] Syntax error", bp, PASS3); return;
							}
							if (val < 0) {
								Error("[SAVETAP] Negative values are not allowed", bp, PASS3); return;
							} else if (val > 0xFFFF) {
								Error("[SAVETAP] Values higher than FFFFh are not allowed", bp, PASS3); return;
							}
							length = val;
						}
						if (comma(lp)) {
							if (!ParseExpression(lp, val)) {
								Error("[SAVETAP] Syntax error", bp, PASS3); return;
							}
							if (val < 0 || val > 255) {
								Error("[SAVETAP] Invalid flag byte", bp, PASS3); return;
							}
							param3 = val;
						}
					} else if (!comma(lp)) {
						fnaamh = GetFileName(lp);
						if (!*fnaamh) {
							Error("[SAVETAP] Syntax error in tape file name", bp, PASS3);
							return;
						} else if (comma(lp) && !comma(lp) && ParseExpression(lp, val)) {
							if (val < 0) {
								Error("[SAVETAP] Negative values are not allowed", bp, PASS3); return;
							} else if (val > 0xFFFF) {
								Error("[SAVETAP] Values higher than FFFFh are not allowed", bp, PASS3); return;
							}
							start = val;

							if (comma(lp) && !comma(lp) && ParseExpression(lp, val)) {
								if (val < 0) {
									Error("[SAVETAP] Negative values are not allowed", bp, PASS3); return;
								} else if (val > 0xFFFF) {
									Error("[SAVETAP] Values higher than FFFFh are not allowed", bp, PASS3); return;
								}
								length = val;

								if (comma(lp)) {
									if (!ParseExpression(lp, val)) {
										Error("[SAVETAP] Syntax error", bp, IF_FIRST); return;
									}
									if (val < 0) {
										Error("[SAVETAP] Negative values are not allowed", bp, PASS3); return;
									} else if (val > 0xFFFF) {
										Error("[SAVETAP] Values more than FFFFh are not allowed", bp, PASS3); return;
									}
									param2 = val;
								}
								if (comma(lp)) {
									if (!ParseExpression(lp, val)) {
										Error("[SAVETAP] Syntax error", bp, IF_FIRST); return;
									}
									if (val < 0) {
										Error("[SAVETAP] Negative values are not allowed", bp, PASS3); return;
									} else if (val > 0xFFFF) {
										Error("[SAVETAP] Values more than FFFFh are not allowed", bp, PASS3); return;
									}
									param3 = val;
								}
							} else {
								Error("[SAVETAP] Syntax error. Missing block length", bp, PASS3); return;
							}
						} else {
							Error("[SAVETAP] Syntax error. Missing start address", bp, PASS3); return;
						}
					} else {
						Error("[SAVETAP] Syntax error. Missing tape block file name", bp, PASS3); return;
					}
				} else {
					realtapeMode = false;
				}
			}
			if (!realtapeMode) {
				lp = tlp;
				if (!ParseExpression(lp, val)) {
					Error("[SAVETAP] Syntax error", bp, PASS3); return;
				}
				if (val < 0) {
					Error("[SAVETAP] Negative values are not allowed", bp, PASS3); return;
				}
				start = val;
			}
		} else {
			Error("[SAVETAP] Syntax error. No parameters", bp, PASS3); return;
		}
	} else if (StartAddress < 0) {
		Error("[SAVETAP] Syntax error. No parameters", bp, PASS3); return;
	} else {
		start = StartAddress;
	}

	if (exec && IsZXSpectrumDevice(DeviceID)) {
		int done = 0;

		if (realtapeMode) {
			done = TAP_SaveBlock(fnaam, headerType, fnaamh, start, length, param2, param3);
		} else {
			done = TAP_SaveSnapshot(fnaam, start);
		}

		if (!done) {
			Error("[SAVETAP] Error writing file", bp, IF_FIRST);
		}
	} else if (exec) {
		Error("[SAVETAP] Device must be defined.");
	}

	if (fnaamh) {
		delete[] fnaamh;
	}
	delete[] fnaam;
}

void dirSAVEBIN() {
	bool exec = true;

	if (!DeviceID) {
		if (pass == LASTPASS) {
			Error("SAVEBIN only allowed in real device emulation mode (See DEVICE)");
		}
		exec = false;
	} else if (pass != LASTPASS) {
		exec = false;
	}

	aint val;
	char* fnaam;
	int start = -1, length = -1;

	fnaam = GetFileName(lp);
	if (comma(lp)) {
		if (!comma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[SAVEBIN] Syntax error", bp, PASS3); return;
			}
			if (val < 0) {
				Error("[SAVEBIN] Values less than 0000h are not allowed", bp, PASS3); return;
			} else if (val > 0xFFFF) {
			  	Error("[SAVEBIN] Values more than FFFFh are not allowed", bp, PASS3); return;
			}
			start = val;
		} else {
		  	Error("[SAVEBIN] Syntax error. No parameters", bp, PASS3); return;
		}
		if (comma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[SAVEBIN] Syntax error", bp, PASS3); return;
			}
			if (val < 0) {
				Error("[SAVEBIN] Negative values are not allowed", bp, PASS3); return;
			}
			length = val;
		}
	} else {
		Error("[SAVEBIN] Syntax error. No parameters", bp, PASS3); return;
	}

	if (exec && !SaveBinary(fnaam, start, length)) {
		Error("[SAVEBIN] Error writing file (Disk full?)", bp, IF_FIRST); return;
	}
	delete[] fnaam;
}

void dirSAVEHOB() {

	if (pass != LASTPASS) {
		SkipParam(lp);
		return;
	}
	aint val;
	char* fnaam, * fnaamh;
	int start = -1,length = -1;
	bool exec = true;

	if (!DeviceID) {
		if (pass == LASTPASS) {
			Error("SAVEHOB only allowed in real device emulation mode (See DEVICE)");
		}
		exec = false;
	} else if (pass != LASTPASS) {
		exec = false;
	}

	fnaam = GetFileName(lp);
	if (comma(lp)) {
		if (!comma(lp)) {
			fnaamh = GetFileName(lp);
			if (!*fnaamh) {
				Error("[SAVEHOB] Syntax error", bp, PASS3); return;
			}
		} else {
		  	Error("[SAVEHOB] Syntax error. No parameters", bp, PASS3); return;
		}
	} else {
		Error("[SAVEHOB] Syntax error. No parameters", bp, PASS3); return; //is this ok?
	}

	if (comma(lp)) {
		if (!comma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[SAVEHOB] Syntax error", bp, PASS3); return;
			}
			if (val < 0x4000) {
				Error("[SAVEHOB] Values less than 4000h are not allowed", bp, PASS3); return;
			} else if (val > 0xFFFF) {
			  	Error("[SAVEHOB] Values more than FFFFh are not allowed", bp, PASS3); return;
			}
			start = val;
		} else {
		  	Error("[SAVEHOB] Syntax error. No parameters", bp, PASS3); return;
		}
		if (comma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[SAVEHOB] Syntax error", bp, PASS3); return;
			}
			if (val < 0) {
				Error("[SAVEHOB] Negative values are not allowed", bp, PASS3); return;
			}
			length = val;
		}
	} else {
		Error("[SAVEHOB] Syntax error. No parameters", bp, PASS3); return;
	}
	if (exec && !SaveHobeta(fnaam, fnaamh, start, length)) {
		Error("[SAVEHOB] Error writing file (Disk full?)", bp, IF_FIRST); return;
	}
	delete[] fnaam;
	delete[] fnaamh;
}

void dirEMPTYTRD() {
	if (pass != LASTPASS) {
		SkipParam(lp);
		return;
	}
	char* fnaam;

	fnaam = GetFileName(lp);
	if (!*fnaam) {
		Error("[EMPTYTRD] Syntax error", bp, IF_FIRST); return;
	}
	TRD_SaveEmpty(fnaam);
	delete[] fnaam;
}

void dirSAVETRD() {

	if (pass != LASTPASS) {
		SkipParam(lp);
		return;
	}

	bool exec = true;

	if (!DeviceID) {
		if (pass == LASTPASS) {
			Error("SAVETRD only allowed in real device emulation mode (See DEVICE)");
		}
		exec = false;
	} else if (pass != LASTPASS) {
		exec = false;
	}

	aint val;
	char* fnaam, * fnaamh;
	int start = -1,length = -1,autostart = -1; //autostart added by boo_boo 19_0ct_2008

	fnaam = GetFileName(lp);
	if (comma(lp)) {
		if (!comma(lp)) {
			fnaamh = GetFileName(lp);
			if (!*fnaamh) {
				Error("[SAVETRD] Syntax error", bp, PASS3); return;
			}
		} else {
		  	Error("[SAVETRD] Syntax error. No parameters", bp, PASS3); return;
		}
	} else {
		Error("[SAVETRD] Syntax error. No parameters", bp, PASS3); return; //is this ok?
	}

	if (comma(lp)) {
		if (!comma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[SAVETRD] Syntax error", bp, PASS3); return;
			}
			if (val > 0xFFFF) {
			  	Error("[SAVETRD] Values more than 0FFFFh are not allowed", bp, PASS3); return;
			}
			start = val;
		} else {
		  	Error("[SAVETRD] Syntax error. No parameters", bp, PASS3); return;
		}
		if (comma(lp)) {
			if (!comma(lp)) {
				if (!ParseExpression(lp, val)) {
					Error("[SAVETRD] Syntax error", bp, PASS3); return;
				}
				if (val < 0) {
					Error("[SAVETRD] Negative values are not allowed", bp, PASS3); return;
				}
				length = val;
			} else {
		  		Error("[SAVETRD] Syntax error. No parameters", bp, PASS3); return;
			}
		}
		if (comma(lp)) { //added by boo_boo 19_0ct_2008
			if (!ParseExpression(lp, val)) {
				Error("[SAVETRD] Syntax error", bp, PASS3); return;
			}
			if (val < 0) {
				Error("[SAVETRD] Negative values are not allowed", bp, PASS3); return;
			}
			autostart = val;
		}
	} else {
		Error("[SAVETRD] Syntax error. No parameters", bp, PASS3); return;
	}

	if (exec) {
		TRD_AddFile(fnaam, fnaamh, start, length, autostart);
	}
	delete[] fnaam;
	delete[] fnaamh;
}

void dirENCODING() {
	char* opt = GetFileName(lp);
	char* opt2 = opt;
	if (!(*opt)) {
		Error("[ENCODING] Syntax error. No parameters", bp, IF_FIRST); return;
	}
	do {
		*opt2 = (char) tolower(*opt2);
	} while (*(opt2++));
	if (!strcmp(opt, "dos")) {
		ConvertEncoding = ENCDOS;
		delete[] opt;
		return;
	}
	if (!strcmp(opt, "win")) {
		ConvertEncoding = ENCWIN;
		delete[] opt;
		return;
	}
	Error("[ENCODING] Syntax error. Bad parameter", bp, IF_FIRST); delete[] opt;return;
}

void dirLABELSLIST() {
	if (!DeviceID) {
		Error("LABELSLIST only allowed in real device emulation mode (See DEVICE)");
	}

	if (pass != 1 || !DeviceID) {
		SkipParam(lp);return;
	}
	char* opt = GetFileName(lp);
	if (!(*opt)) {
		Error("[LABELSLIST] Syntax error. No parameters", bp, IF_FIRST); return;
	}
	STRCPY(Options::UnrealLabelListFName, LINEMAX, opt);
	delete[] opt;
}

/*void dirTEXTAREA() {

}*/

// error message templates for IF**some** directives
constexpr static size_t dirIfErrorsN = 2, dirIfErrorsSZ = 48;
const static char dirIfErrorsTxtSrc[dirIfErrorsN][dirIfErrorsSZ] = {
	{ "[%s] No ENDIF" },
	{ "[%s] one ELSE only expected" }
};

// main IF implementation parsing/skipping part of source depending on "val", handling ELSE/ENDIF
static void dirIfInternal(const char* dirName, aint val) {
	// set up error messages for the particular pseudo-op
	char errorsTxt[dirIfErrorsN][dirIfErrorsSZ];
	for (size_t i = 0; i < dirIfErrorsN; ++i) {
		SPRINTF1(errorsTxt[i], dirIfErrorsSZ, dirIfErrorsTxtSrc[i], dirName);
	}
	// do the IF**some** part
	ListFile();
	EReturn ret = END;
	int elseCounter = 0;
	while (ENDIF != ret) {
		switch (ret = val ? ReadFile() : SkipFile()) {
			case ELSE:
				if (elseCounter++) Warning(errorsTxt[1]);
				val = !val;
				break;
			case ENDIF:
				break;
			default:
				if (IsRunning) Error(errorsTxt[0]);
				donotlist=!IsRunning;		// do the listing only if still running
				return;
		}
	}
}

// IF and IFN internal helper, to evaluate expression
static bool dirIfIfn(aint & val) {
	IsLabelNotFound = 0;
	if (!ParseExpression(lp, val)) {
		Error("[IF/IFN] Syntax error", lp, IF_FIRST);
		return false;
	}
	if (IsLabelNotFound) Error("[IF/IFN] Forward reference");
	return true;
}

static void dirIF() {
	aint val;
	if (dirIfIfn(val)) dirIfInternal("IF", val);
}

static void dirIFN() {
	aint val;
	if (dirIfIfn(val)) dirIfInternal("IFN", !val);
}

// IFUSED and IFNUSED internal helper, to parse label
static bool dirIfusedIfnused(char* & id) {
	if ( (((id = GetID(lp)) == NULL || *id == 0) && LastParsedLabel == NULL) || !SkipBlanks()) {
		Error("[IFUSED] Syntax error", bp, SUPPRESS);
		return false;
	}
	if (id == NULL || *id == 0) {
		id = LastParsedLabel;
	} else {	// Ped7g: I was unable to trigger this code path by ASM source, GetID is foolproof.
		id = ValidateLabel(id, 0);		// So I added `|| !SkipBlanks()` above to verify there's only label
		if (id == NULL) Error("[IFUSED] Invalid label name", bp, IF_FIRST);
	}
	return NULL != id;
}

static void dirIFUSED() {
	char* id;
	if (dirIfusedIfnused(id)) dirIfInternal("IFUSED", LabelTable.IsUsed(id));
}

static void dirIFNUSED() {
	char* id;
	if (dirIfusedIfnused(id)) dirIfInternal("IFUSED", !LabelTable.IsUsed(id));
}

static void dirIFDEF() {
	char* id;
	if ((id = GetID(lp)) && *id) {
		dirIfInternal("IFDEF", DefineTable.FindDuplicate(id));
	} else {
		Error("[IFDEF] Illegal identifier", bp);
	}
}

static void dirIFNDEF() {
	char* id;
	if ((id = GetID(lp)) && *id) {
		dirIfInternal("IFDEF", !DefineTable.FindDuplicate(id));
	} else {
		Error("[IFNDEF] Illegal identifier", bp);
	}
}

static void dirELSE() {
	Error("ELSE without IF/IFN/IFUSED/IFNUSED/IFDEF/IFNDEF");
}

static void dirENDIF() {
	Error("ENDIF without IF/IFN/IFUSED/IFNUSED/IFDEF/IFNDEF");
}

/*void dirENDTEXTAREA() {
  Error("ENDT without TEXTAREA",0);
}*/

void dirINCLUDE() {
	char* fnaam;
	fnaam = GetFileName(lp);
	EDelimiterType dt = GetDelimiterOfLastFileName();
	ListFile();
	IncludeFile(fnaam, DT_ANGLE == dt);
	donotlist = 1;
	delete[] fnaam;
}

void dirOUTPUT() {
	char* fnaam = GetFileName(lp);
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
			Error("Syntax error", bp, IF_FIRST);
		}
	}
	//Options::NoDestinationFile = false;
	if (pass == LASTPASS) {
		NewDest(fnaam, mode);
	}
	delete[] fnaam;
}

void dirOUTEND()
{
	// if (!FP_Output) {Error("OUTEND without OUTPUT", bp, PASS3); return;}
	if (pass == LASTPASS) CloseDest();
}

void dirTAPOUT()
{
	aint val;
	char* fnaam;

	fnaam = GetFileName(lp);
	int tape_flag = 255;
	if (comma(lp))
	{
		if (!ParseExpression(lp, val))
		{
			Error("[TAPOUT] Missing flagbyte value", bp, PASS3); return;
		}
		tape_flag = val;
	}
	if (pass == LASTPASS) OpenTapFile(fnaam, tape_flag);

	delete[] fnaam;
}

void dirTAPEND()
{
	// if (!FP_tapout) {Error("TAPEND without TAPOUT", bp, PASS3); return;}
	if (pass == LASTPASS) CloseTapFile();
}

void dirDEFINE() {
	char* id;

	if (!(id = GetID(lp))) {
		Error("[DEFINE] Illegal syntax"); return;
	}

	DefineTable.Add(id, lp, 0);

	*(lp) = 0;
}

void dirUNDEFINE() {
	char* id;

	if (!(id = GetID(lp)) && *lp != '*') {
		Error("[UNDEFINE] Illegal syntax"); return;
	}

	if (*lp == '*') {
		lp++;
		LabelTable.RemoveAll();
		DefineTable.RemoveAll();
	} else if (DefineTable.FindDuplicate(id)) {
		DefineTable.Remove(id);
	} else if (LabelTable.Find(id)) {
		LabelTable.Remove(id);
	} else {
		Warning("[UNDEFINE] Identifier not found", id); return;
	}
}

void dirEXPORT() {
	aint val;
	char* n, * p;

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
		Error("[EXPORT] Syntax error", lp, IF_FIRST); return;
	}
	if (pass != LASTPASS) {
		return;
	}
	IsLabelNotFound = 0;

	GetLabelValue(n, val);
	if (IsLabelNotFound) {
		Error("[EXPORT] Label not found", p, SUPPRESS); return;
	}
	WriteExp(p, val);
}

void dirDISPLAY() {
	char decprint = 0;
	char e[LINEMAX];
	char* ep = e;
	aint val;
	int t = 0;
	while (1) {
		if (SkipBlanks()) {
			Error("[DISPLAY] Expression expected"); break;
		}
		if (t == LINEMAX - 1) {
			Error("[DISPLAY] Too many arguments", lp); break;
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
				Error("[DISPLAY] Syntax error", line);return;
			}
			SkipBlanks(lp);

			if ((*(lp) != 0x2c)) {
				Error("[DISPLAY] Syntax error", line);return;
			}
			++lp;
			SkipBlanks(lp);
		}

		if (*lp == '"') {		//FIXME Ped7g fix the string literal parsing (GetBytes for new style)
			lp++;
			do {
				if (!*lp || *lp == '"') {
					Error("[DISPLAY] Syntax error", line);
					*ep = 0;
					return;
				}
				if (t == 128) {
					Error("[DISPLAY] Too many arguments", line);
					*ep = 0;
					return;
				}
				GetCharConstInDoubleQuotes(lp, val);
				check8(val);
				*(ep++) = (char) (val & 255);
			} while (*lp != '"');
			++lp;
		} else if (*lp == '\'') {
		  	lp++;
			do {
				if (!*lp || *lp == '\'') {
		  			Error("[DISPLAY] Syntax error", line);
					*ep = 0;
					return;
				}
				if (t == LINEMAX - 1) {
		  			Error("[DISPLAY] Too many arguments", line);
					*ep = 0;
					return;
				}
		  		GetCharConstInApostrophes(lp, val);
				check8(val);
				*(ep++) = (char) (val & 255);
			} while (*lp != '\'');
		  	++lp;
		} else {
		  	displayerror = 0;displayinprocces = 1;
			if (ParseExpression(lp, val)) {
				if (displayerror) {
					displayinprocces = 0;
					Error("[DISPLAY] Bad argument", line);
					return;
				} else {
		  		  	displayinprocces = 0;
					if (decprint == 0 || decprint == 2) {
		  		  		*(ep++) = '0';
						*(ep++) = 'x';
						if (val < 0x1000) {
							PrintHEX16(ep, val);
						} else {
							PrintHEXAlt(ep, val);
						}
					}
					if (decprint == 2) {
						*(ep++) = ',';
						*(ep++) = ' ';
					}
					if (decprint == 1 || decprint == 2) {
						SPRINTF1(ep, (int)(&e[0] + LINEMAX - ep), "%lu", val);
						ep += strlen(ep);
					}
		  		  	decprint = 0;
				}
			} else {
				Error("[DISPLAY] Syntax error", line);
				return;
			}
		}
		SkipBlanks(lp);
		if (*lp != ',') {
			break;
		}
		++lp;
	}
	*ep = 0; // end line

	if (pass != LASTPASS) {
		// do none
	} else {
		_COUT "> " _CMDL e _ENDL;
	}
}

void dirMACRO() {
	if (lijst) Error("[MACRO] No macro definitions allowed here", NULL, FATAL);
	char* n = GetID(lp);
	if (n) MacroTable.Add(n, lp);
	else   Error("[MACRO] Illegal macroname");
}

void dirENDS() {
	Error("[ENDS] End structure without structure");
}

void dirASSERT() {
	char* p = lp;
	aint val;
	/*if (!ParseExpression(lp,val)) { Error("Syntax error",0,CATCHALL); return; }
	if (pass==2 && !val) Error("Assertion failed",p);*/
	if (!ParseExpression(lp, val)) {
		Error("[ASSERT] Syntax error", NULL, IF_FIRST); return;
	}
	if (pass == LASTPASS && !val) {
		Error("[ASSERT] Assertion failed", p);
	}
	/**lp=0;*/
}

void dirSHELLEXEC() {
	char* command = NULL;
	char* parameters = NULL;

	command = GetFileName(lp, false);
	if (comma(lp)) {
		parameters = GetFileName(lp, false);
	} else {
		parameters = 0;
	}
	if (pass == LASTPASS) {
		if (parameters) {
			_COUT "Executing " _CMDL command _CMDL " " _CMDL parameters _ENDL;
		} else {
			_COUT "Executing " _CMDL command _ENDL;
		}
#if defined(WIN32)
		STARTUPINFO si;
		PROCESS_INFORMATION pi;
		ZeroMemory( &si, sizeof(si) );
		si.cb = sizeof(si);
		ZeroMemory( &pi, sizeof(pi) );

		// Start the child process.
		if (parameters) {
			if( !CreateProcess( command,   // No module name (use command line).
				parameters, // Command line.
				NULL,             // Process handle not inheritable.
				NULL,             // Thread handle not inheritable.
				TRUE,            // Set handle inheritance to FALSE.
				0,                // No creation flags.
				NULL,             // Use parent's environment block.
				NULL,             // Use parent's starting directory.
				&si,              // Pointer to STARTUPINFO structure.
				&pi )             // Pointer to PROCESS_INFORMATION structure.
				) {
				temp[0] = 0;
				STRCAT(temp, LINEMAX, command);
				STRCAT(temp, LINEMAX, " ");
				STRCAT(temp, LINEMAX, parameters);
				Error( "[SHELLEXEC] Execution of command failed", temp, PASS3 );
			} else {
				CloseHandle(pi.hThread);
				WaitForSingleObject(pi.hProcess, 500);
				CloseHandle(pi.hProcess);
			}
		} else {
			if( !CreateProcess( NULL,   // No module name (use command line).
				command, // Command line.
				NULL,             // Process handle not inheritable.
				NULL,             // Thread handle not inheritable.
				FALSE,            // Set handle inheritance to FALSE.
				0,                // No creation flags.
				NULL,             // Use parent's environment block.
				NULL,             // Use parent's starting directory.
				&si,              // Pointer to STARTUPINFO structure.
				&pi )             // Pointer to PROCESS_INFORMATION structure.
				) {
				Error( "[SHELLEXEC] Execution of command failed", command, PASS3 );
			} else {
				CloseHandle(pi.hThread);
				WaitForSingleObject(pi.hProcess, 500);
				CloseHandle(pi.hProcess);
			}
		}
		//system(command);
		///WinExec ( command, SW_SHOWNORMAL );
#else
		if (system(command) == -1) {
			Error("[SHELLEXEC] Execution of command failed", command);
		}
#endif
	}
	delete[] command;
}

/*void dirWINEXEC() {
	char* command;
	command = GetFileName(lp);
	if (pass == LASTPASS) {

	}
	delete[] command;
}*/

void dirSTRUCT() {
	CStructure* st;
	int global = 0;
	aint offset = 0,bind = 0;
	char* naam;
	SkipBlanks();
	if (*lp == '@') {
		++lp; global = 1;
	}

	if (!(naam = GetID(lp)) || !strlen(naam)) {
		Error("[STRUCT] Illegal structure name"); return;
	}
	if (comma(lp)) {
		IsLabelNotFound = 0;
		if (!ParseExpression(lp, offset)) {
			Error("[STRUCT] Syntax error", lp, IF_FIRST); return;
		}
		if (IsLabelNotFound) {
			Error("[STRUCT] Forward reference", NULL, ALL);
		}
	}
	st = StructureTable.Add(naam, offset, bind, global);
	ListFile();
	while ('o') {
		if (!ReadLine()) {
			Error("[STRUCT] Unexpected end of structure"); break;
		}
		lp = line; /*if (White()) { SkipBlanks(lp); if (*lp=='.') ++lp; if (cmphstr(lp,"ends")) break; }*/
		SkipBlanks(lp);
		if (*lp == '.') {
			++lp;
		} if (cmphstr(lp, "ends")) {
			break;
		 }
		ParseStructLine(st);
		ListFile(true);
	}
	st->deflab();
}

void dirFORG() {
	aint val;
	int method = SEEK_SET;
	SkipBlanks(lp);
	if ((*lp == '+') || (*lp == '-')) {
		method = SEEK_CUR;
	}
	if (!ParseExpression(lp, val)) {
		Error("[FORG] Syntax error", lp, IF_FIRST);
	}
	if (pass == LASTPASS) {
		SeekDest(val, method);
	}
}

/* i didn't modify it */
/*
void dirBIND() {
}
*/

void dirDUP() {
	aint val;
	IsLabelNotFound = 0;

	if (!RepeatStack.empty()) {
		SRepeatStack& dup = RepeatStack.top();
		if (!dup.IsInWork) {
			// Just skip the expression to the end of line, don't try to evaluate yet
			while (*lp) ++lp;
			++dup.Level;
			return;
		}
	}

	if (!ParseExpression(lp, val)) {
		Error("[DUP/REPT] Syntax error", lp, IF_FIRST); return;
	}
	if (IsLabelNotFound) {
		Error("[DUP/REPT] Forward reference", NULL, ALL);
	}
	if ((int) val < 1) {
		Error("[DUP/REPT] Illegal repeat value", NULL, IF_FIRST); return;
	}

	SRepeatStack dup;
	dup.RepeatCount = val;
	dup.Level = 0;

	dup.Lines = new CStringsList(lp);
	if (!SkipBlanks()) Error("[DUP] unexpected chars", lp, FATAL);	// Ped7g: should have been empty!
	dup.Pointer = dup.Lines;
	dup.CurrentSourceLine = CurrentSourceLine;
	dup.IsInWork = false;
	RepeatStack.push(dup);
}

void dirEDUP() {
	if (RepeatStack.empty()) {
		Error("[EDUP/ENDR] End repeat without repeat");
		return;
	}

	SRepeatStack& dup = RepeatStack.top();
	if (!dup.IsInWork && dup.Level) {
		--dup.Level;
		return;
	}
	dup.IsInWork = true;
	dup.Pointer->string = NULL;	// kill the EDUP inside DUP-list (also works as "while" terminator)
	++listmacro;
	char* ml = STRDUP(line);	// copy the EDUP line for List purposes (after the DUP block emit)
	if (ml == NULL) Error("[EDUP/ENDR] No enough memory", NULL, FATAL);
	long lcurln = CurrentSourceLine;
	CStringsList* olijstp = lijstp;
	++lijst;
	while (dup.RepeatCount--) {
		CurrentSourceLine = dup.CurrentSourceLine;
		donotlist=1;	// skip first empty line (where DUP itself is parsed)
		lijstp = dup.Lines;
		while (IsRunning && lijstp && lijstp->string) {	// the EDUP/REPT/ENDM line has string=NULL => ends loop
			if (lijstp->sourceLine) CurrentSourceLine = lijstp->sourceLine;
			STRCPY(line, LINEMAX, lijstp->string);
			lijstp = lijstp->next;
			ParseLineSafe();
			++CurrentSourceLine;
		}
	}
	RepeatStack.pop();
	lijstp = olijstp;
	--lijst;
	CurrentSourceLine = lcurln;
	--listmacro;
	STRCPY(line, LINEMAX,  ml);		// show EDUP line itself
	ListFile();
}

void dirENDM() {
	if (!RepeatStack.empty()) {
		Warning("ENDM used as DUP/REPT block terminator, this is deprecated (and bugged when used inside macro), change to EDUP or ENDR");
		dirEDUP();
	} else {
		Error("[ENDM] End macro without macro");
	}
}

void dirDEFARRAY() {
	char* id;
	if (!(id = GetID(lp))) {
		Error("[DEFARRAY] Syntax error"); return;
	}
	CStringsList* a = NULL;
	CStringsList** f = &a;
	char ml[LINEMAX];
	while (!SkipBlanks()) {
		const char* const itemLp = lp;
		char* n = ml;
		if (!GetMacroArgumentValue(lp, n)) {
			Error("[DEFARRAY] Syntax error", itemLp);
			return;
		}
		*f = new CStringsList(ml);
		if ((*f)->string == NULL) Error("[DEFARRAY] No enough memory", NULL, FATAL);
		f = &((*f)->next);
		if (!comma(lp)) break;
	}
	if (NULL == a) {
		Error("DEFARRAY must have at least one entry"); return;
	}
	DefineTable.Add(id, (char *)"\n", a);
	//while (a) { STRCPY(ml,a->string); _COUT ml _ENDL; a=a->next; }
}

#ifdef USE_LUA

void _lua_showerror() {
	int ln;

	// part from Error(...)
	char *err = STRDUP(lua_tostring(LUA, -1));
	if (err == NULL) {
		Error("No enough memory!", NULL, FATAL);
	}
	//_COUT err _ENDL;
	err += 18;
	char *pos = strstr(err, ":");
	//_COUT err _ENDL;
	//_COUT pos _ENDL;
	*(pos++) = 0;
	//_COUT err _ENDL;
	ln = atoi(err) + LuaLine;

	// print error and other actions
	err = ErrorLine;
	SPRINTF3(err, LINEMAX2, "%s(%d): error: [LUA]%s", filename, ln, pos);

	if (!strchr(err, '\n')) {
		STRCAT(err, LINEMAX2, "\n");
	}

	if (FP_ListingFile != NULL) {
		fputs(ErrorLine, FP_ListingFile);
	}
	_CERR ErrorLine _END;

	PreviousErrorLine = ln;

	ErrorCount++;

	char count[25];
	SPRINTF1(count, 25, "%d", ErrorCount);
	DefineTable.Replace("_ERRORS", count);
	// end Error(...)

	lua_pop(LUA, 1);
}

typedef struct luaMemFile
{
  const char *text;
  size_t size;
} luaMemFile;

const char *readMemFile(lua_State *, void *ud, size_t *size)
{
  // Convert the ud pointer (UserData) to a pointer of our structure
  luaMemFile *luaMF = (luaMemFile *) ud;

  // Are we done?
  if(luaMF->size == 0)
    return NULL;

  // Read everything at once
  // And set size to zero to tell the next call we're done
  *size = luaMF->size;
  luaMF->size = 0;

  // Return a pointer to the readed text
  return luaMF->text;
}

void dirLUA() {
	int error;
	char *rp, *id;
	char *buff = new char[32768];
	char *bp=buff;
//	char size=0;
	int ln=0;
	bool execute=false;

	luaMemFile luaMF;

	SkipBlanks();

	if ((id = GetID(lp)) && strlen(id) > 0) {
		if (cmphstr(id, "pass1")) {
			if (pass == 1) {
				execute = true;
			}
		} else if (cmphstr(id, "pass2")) {
			if (pass == 2) {
				execute = true;
			}
		} else if (cmphstr(id, "pass3")) {
			if (pass == 3) {
				execute = true;
			}
		} else if (cmphstr(id, "allpass")) {
			execute = true;
		} else {
			//_COUT id _CMDL "A" _ENDL;
			Error("[LUA] Syntax error", id);
		}
	} else if (pass == LASTPASS) {
		execute = true;
	}

	ln = CurrentSourceLine;
	ListFile();
	while (1) {
		if (!ReadLine(false)) {
			Error("[LUA] Unexpected end of lua script"); break;
		}
		lp = line;
		rp = line;
		SkipBlanks(rp);
		if (cmphstr(rp, "endlua")) {
			if (execute) {
				if ((bp-buff) + (rp-lp-6) < 32760 && (rp-lp-6) > 0) {
					STRNCPY(bp, 32768-(bp-buff)+1, lp, rp-lp-6);
					bp += rp-lp-6;
					*(bp++) = '\n';
					*(bp) = 0;
				} else {
					Error("[LUA] Maximum size of Lua script is 32768 bytes", NULL, FATAL);
					return;
				}
			}
			lp = rp;
			break;
		}
		if (execute) {
			if ((bp-buff) + strlen(lp) < 32760) {
				STRCPY(bp, 32768-(bp-buff)+1, lp);
				bp += strlen(lp);
				*(bp++) = '\n';
				*(bp) = 0;
			} else {
				Error("[LUA] Maximum size of Lua script is 32768 bytes", NULL, FATAL);
				return;
			}
		}

		ListFile(true);
	}

	if (execute) {
		LuaLine = ln;
		luaMF.text = buff;
		luaMF.size = strlen(luaMF.text);
		error = lua_load(LUA, readMemFile, &luaMF, "script") || lua_pcall(LUA, 0, 0, 0);
		//error = luaL_loadbuffer(LUA, (char*)buff, sizeof(buff), "script") || lua_pcall(LUA, 0, 0, 0);
		//error = luaL_loadstring(LUA, buff) || lua_pcall(LUA, 0, 0, 0);
		if (error) {
			_lua_showerror();
		}
		LuaLine = -1;
	}

	delete[] buff;
}

void dirENDLUA() {
	Error("[ENDLUA] End of lua script without script");
}

void dirINCLUDELUA() {
	if (1 != pass) {
		while (*lp) ++lp;	// skip till EOL (colon), to avoid parsing file name
		return;
	}
	char* fnaam = GetFileName(lp);
	EDelimiterType dt = GetDelimiterOfLastFileName();
	char* fullpath = GetPath(fnaam, NULL, DT_ANGLE == dt);
	if (!fullpath[0]) {
		Error("[INCLUDELUA] File doesn't exist", fnaam, EARLY);
	} else {
		LuaLine = CurrentSourceLine;
		int error = luaL_loadfile(LUA, fullpath) || lua_pcall(LUA, 0, 0, 0);
		if (error) {
			_lua_showerror();
		}
		LuaLine = -1;
	}
	free(fullpath);
	delete[] fnaam;
}

#endif //USE_LUA

void dirDEVICE() {
	char* id;

	if ((id = GetID(lp))) {
		if (!SetDevice(id)) {
			Error("[DEVICE] Invalid parameter", NULL, IF_FIRST);
		}
	} else {
		Error("[DEVICE] Syntax error", NULL, IF_FIRST);
	}


}

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
	DirectivesTable.insertd("fpos",dirFORG);
	DirectivesTable.insertd("map", dirMAP);
	DirectivesTable.insertd("align", dirALIGN);
	DirectivesTable.insertd("module", dirMODULE);
	//DirectivesTable.insertd("z80", dirZ80);
	DirectivesTable.insertd("size", dirSIZE);
	//DirectivesTable.insertd("textarea",dirTEXTAREA);
	DirectivesTable.insertd("textarea", dirDISP);
	//DirectivesTable.insertd("msx", dirZ80);
	DirectivesTable.insertd("else", dirELSE);
	DirectivesTable.insertd("export", dirEXPORT);
	DirectivesTable.insertd("display", dirDISPLAY);
	DirectivesTable.insertd("end", dirEND);
	DirectivesTable.insertd("include", dirINCLUDE);
	DirectivesTable.insertd("incbin", dirINCBIN);
	DirectivesTable.insertd("binary", dirINCBIN);
	DirectivesTable.insertd("inchob", dirINCHOB);
	DirectivesTable.insertd("inctrd", dirINCTRD);
	DirectivesTable.insertd("insert", dirINCBIN);
	DirectivesTable.insertd("savesna", dirSAVESNA);
	DirectivesTable.insertd("savehob", dirSAVEHOB);
	DirectivesTable.insertd("savebin", dirSAVEBIN);
	DirectivesTable.insertd("emptytap", dirEMPTYTAP);
	DirectivesTable.insertd("savetap", dirSAVETAP);
	DirectivesTable.insertd("emptytrd", dirEMPTYTRD);
	DirectivesTable.insertd("savetrd", dirSAVETRD);
	DirectivesTable.insertd("shellexec", dirSHELLEXEC);
/*#ifdef WIN32
	DirectivesTable.insertd("winexec", dirWINEXEC);
#endif*/
	DirectivesTable.insertd("if", dirIF);
	DirectivesTable.insertd("ifn", dirIFN);
	DirectivesTable.insertd("ifused", dirIFUSED);
	DirectivesTable.insertd("ifnused", dirIFNUSED);
	DirectivesTable.insertd("ifdef", dirIFDEF);
	DirectivesTable.insertd("ifndef", dirIFNDEF);
	DirectivesTable.insertd("output", dirOUTPUT);
	DirectivesTable.insertd("outend", dirOUTEND);
	DirectivesTable.insertd("tapout", dirTAPOUT);
	DirectivesTable.insertd("tapend", dirTAPEND);
	DirectivesTable.insertd("define", dirDEFINE);
	DirectivesTable.insertd("undefine", dirUNDEFINE);
	DirectivesTable.insertd("defarray", dirDEFARRAY);
	DirectivesTable.insertd("macro", dirMACRO);
	DirectivesTable.insertd("struct", dirSTRUCT);
	DirectivesTable.insertd("dc", dirDC);
	DirectivesTable.insertd("dz", dirDZ);
	DirectivesTable.insertd("db", dirBYTE);
	DirectivesTable.insertd("dm", dirBYTE);
	DirectivesTable.insertd("dw", dirWORD);
	DirectivesTable.insertd("ds", dirBLOCK);
	DirectivesTable.insertd("dd", dirDWORD);
	DirectivesTable.insertd("defb", dirBYTE);
	DirectivesTable.insertd("defw", dirWORD);
	DirectivesTable.insertd("defs", dirBLOCK);
	DirectivesTable.insertd("defd", dirDWORD);
	DirectivesTable.insertd("defm", dirBYTE);
	DirectivesTable.insertd("endmod", dirENDMODULE);
	DirectivesTable.insertd("endmodule", dirENDMODULE);
	DirectivesTable.insertd("endmap", dirENDMAP);
	DirectivesTable.insertd("rept", dirDUP);
	DirectivesTable.insertd("dup", dirDUP);
	DirectivesTable.insertd("disp", dirDISP);
	DirectivesTable.insertd("phase", dirDISP);
	DirectivesTable.insertd("ent", dirENT);
	DirectivesTable.insertd("unphase", dirENT);
	DirectivesTable.insertd("dephase", dirENT);
	DirectivesTable.insertd("page", dirPAGE);
	DirectivesTable.insertd("slot", dirSLOT);
	DirectivesTable.insertd("encoding", dirENCODING);
	DirectivesTable.insertd("labelslist", dirLABELSLIST);
	//  DirectivesTable.insertd("bind",dirBIND); /* i didn't comment this */
	DirectivesTable.insertd("endif", dirENDIF);
	//DirectivesTable.insertd("endt",dirENDTEXTAREA);
	DirectivesTable.insertd("endt", dirENT);
	DirectivesTable.insertd("endm", dirENDM);
	DirectivesTable.insertd("edup", dirEDUP);
	DirectivesTable.insertd("endr", dirEDUP);
	DirectivesTable.insertd("ends", dirENDS);

	DirectivesTable.insertd("device", dirDEVICE);

#ifdef USE_LUA
	DirectivesTable.insertd("lua", dirLUA);
	DirectivesTable.insertd("endlua", dirENDLUA);
	DirectivesTable.insertd("includelua", dirINCLUDELUA);
#endif //USE_LUA

	DirectivesTable_dup.insertd("dup", dirDUP);
	DirectivesTable_dup.insertd("edup", dirEDUP);
	DirectivesTable_dup.insertd("endm", dirENDM);
	DirectivesTable_dup.insertd("endr", dirEDUP);
	DirectivesTable_dup.insertd("rept", dirDUP);
}

#ifdef USE_LUA

bool LuaSetPage(aint n) {
	if (n < 0) {
		Error("sj.set_page: negative page number are not allowed", lp); return false;
	} else if (Device->PagesCount <= n) {
		char buf[LINEMAX];
		SPRINTF1(buf, LINEMAX, "sj.set_page: page number must be in range 0..%u", Device->PagesCount - 1);
		Error(buf, NULL, IF_FIRST); return false;
	}
	Slot->Page = Device->GetPage(n);
	CheckPage();
	return true;
}

bool LuaSetSlot(aint n) {
	if (n < 0) {
		Error("sj.set_slot: negative slot number are not allowed", lp); return false;
	} else if (Device->SlotsCount <= n) {
		char buf[LINEMAX];
		SPRINTF1(buf, LINEMAX, "sj.set_slot: slot number must be in range 0..%u", Device->SlotsCount - 1);
		Error(buf, NULL, IF_FIRST); return false;
	}
	Slot = Device->GetSlot(n);
	Device->CurrentSlot = Slot->Number;
	CheckPage();
	return true;
}

#endif //USE_LUA

//eof direct.cpp
