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

	// if END/.END directive is at the beginning of line = ignore them (even with "--dirbol")
	if (beginningOfLine && (cmphstr(lp, "end") || cmphstr(lp, ".end"))) {
		lp = olp;
		return 0;
	}

	bp = lp;
	char* n;
	aint val;
	if (!(n = getinstr(lp))) {
		lp = olp;
		return 0;
	}

	if (DirectivesTable.zoek(n)) return 1;

	// Only "." repeat directive remains, but that one can't start at beginning of line (without --dirbol)
	const bool isDigitDot = ('.' == *n) && isdigit((byte)n[1]);
	const bool isExprDot = ('.' == *n) && (0 == n[1]) && ('(' == *lp);
	if ((beginningOfLine && !Options::syx.IsPseudoOpBOF) || (!isDigitDot && !isExprDot)) {
		lp = olp;		// alone "." must be followed by digit, or math expression in parentheses
		return 0;		// otherwise just return
	}

	// parse repeat-count either from n+1 (digits) or lp (parentheses) (if syntax is valid)
	if ((isDigitDot && !White(*lp)) || !ParseExpression(isDigitDot ? ++n : lp, val)) {
		lp = olp; Error("Dot-repeater must be followed by number or parentheses", olp, SUPPRESS);
		return 0;
	}
	if (val < 1) {
		lp = olp; ErrorInt(".N must be positive integer", val, SUPPRESS);
		return 0;
	}

	// preserve original line buffer, and also the line to be repeated (at `lp`)
	char* ml = STRDUP(line);
	SkipBlanks();
	char* pp = STRDUP(lp);
	// create new copy of eolComment because original "line" content will be destroyed
	char* eolCommCopy = eolComment ? STRDUP(eolComment) : nullptr;
	eolComment = eolCommCopy;
	if (NULL == ml || NULL == pp) ErrorOOM();
	++listmacro;
	do {
		line[0] = ' ';
		STRCPY(line+1, LINEMAX-1, pp);	// reset `line` to the content which should be repeated
		ParseLineSafe();			// and parse it
		eolComment = NULL;			// switch OFF EOL-comment after first line
	} while (--val);
	// restore everything
	STRCPY(line, LINEMAX, ml);
	--listmacro;
	donotlist = 1;
	if (eolCommCopy) free(eolCommCopy);
	free(pp);
	free(ml);
	// make lp point at \0, as the repeating line was processed fully
	lp = sline;
	*sline = 0;
	return 1;
}

int ParseDirective_REPT() {
	char* olp = bp = lp, * n;
	if ((n = getinstr(lp)) && DirectivesTable_dup.zoek(n)) return 1;
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
	if (ParseExpressionNoSyntaxError(lp, add)) {
		getBytesWithCheck(add);
	} else {
		Error("ABYTE <offset> <bytes>: parsing <offset> failed", bp, SUPPRESS);
	}
}

void dirABYTEC() {
	aint add;
	if (ParseExpressionNoSyntaxError(lp, add)) {
		getBytesWithCheck(add, 1);
	} else {
		Error("ABYTEC <offset> <bytes>: parsing <offset> failed", bp, SUPPRESS);
	}
}

void dirABYTEZ() {
	aint add;
	if (ParseExpressionNoSyntaxError(lp, add)) {
		getBytesWithCheck(add, 0, true);
	} else {
		Error("ABYTEZ <offset> <bytes>: parsing <offset> failed", bp, SUPPRESS);
	}
}

void dirWORD() {
	aint val;
	int teller = 0, e[130];
	do {
		if (SkipBlanks()) {
			Error("Expression expected", NULL, SUPPRESS);
		} else if (ParseExpressionNoSyntaxError(lp, val)) {
			check16(val);
			e[teller++] = val & 65535;
		} else {
			Error("[DW/DEFW/WORD] Syntax error", lp, SUPPRESS);
			break;
		}
	} while (comma(lp) && teller < 128);
	e[teller] = -1;
	if (teller == 128 && *lp) Error("Over 128 values in DW/DEFW/WORD. Values over", lp, SUPPRESS);
	if (teller) EmitWords(e);
	else		Error("DW/DEFW/WORD with no arguments");
}

void dirDWORD() {
	aint val;
	int teller = 0, e[130 * 2];
	do {
		if (SkipBlanks()) {
			Error("Expression expected", NULL, SUPPRESS);
		} else if (ParseExpressionNoSyntaxError(lp, val)) {
			e[teller * 2] = val & 65535; e[teller * 2 + 1] = (val >> 16) & 0xFFFF; ++teller;
		} else {
			Error("[DWORD] Syntax error", lp, SUPPRESS);
			break;
		}
	} while (comma(lp) && teller < 128);
	e[teller * 2] = -1;
	if (teller == 128 && *lp) Error("Over 128 values in DWORD. Values over", lp, SUPPRESS);
	if (teller) EmitWords(e);
	else		Error("DWORD with no arguments");
}

void dirD24() {
	aint val;
	int teller = 0, e[130 * 3];
	do {
		if (SkipBlanks()) {
			Error("Expression expected", NULL, SUPPRESS);
		} else if (ParseExpressionNoSyntaxError(lp, val)) {
			check24(val);
			e[teller++] = val & 255; e[teller++] = (val >> 8) & 255; e[teller++] = (val >> 16) & 255;
		} else {
			Error("[D24] Syntax error", lp, SUPPRESS);
			break;
		}
	} while (comma(lp) && teller < 128*3);
	e[teller] = -1;
	if (teller == 128*3 && *lp) Error("Over 128 values in D24. Values over", lp, SUPPRESS);
	if (teller) EmitBytes(e);
	else		Error("D24 with no arguments");
}

void dirDG() {
	int dirDx[130];
	if (GetBits(lp, dirDx)) {
		EmitBytes(dirDx);
	} else {
		Error("no arguments");
	}
}

void dirDH() {
	int dirDx[130];
	if (GetBytesHexaText(lp, dirDx)) {
		EmitBytes(dirDx);
	} else {
		Error("no arguments");
	}
}

void dirBLOCK() {
	aint teller,val = 0;
	if (ParseExpressionNoSyntaxError(lp, teller)) {
		if ((signed) teller < 0) {
			Warning("Negative BLOCK?");
		}
		if (comma(lp)) {
			if (ParseExpression(lp, val)) check8(val);
		}
		EmitBlock(val, teller);
	} else {
		Error("[BLOCK] Syntax Error in <length>", lp, SUPPRESS);
	}
}

static bool dirPageImpl(const char* const dirName, int pageNumber) {
	if (!Device) return false;
	if (pageNumber < 0 || Device->PagesCount <= pageNumber) {
		char buf[LINEMAX];
		SPRINTF2(buf, LINEMAX, "[%s] Page number must be in range 0..%d", dirName, Device->PagesCount - 1);
		ErrorInt(buf, pageNumber);
		return false;
	}
	Device->GetCurrentSlot()->Page = Device->GetPage(pageNumber);
	Device->CheckPage(CDevice::CHECK_RESET);
	return true;
}

static void dirPageImpl(const char* const dirName) {
	aint pageNum;
	if (ParseExpressionNoSyntaxError(lp, pageNum)) {
		dirPageImpl(dirName, pageNum);
	} else {
		Error("Syntax error in <page_number>", lp, SUPPRESS);
	}
}

void dirORG() {
	aint val;
	if (!ParseExpressionNoSyntaxError(lp, val)) {
		Error("[ORG] Syntax error in <address>", lp, SUPPRESS);
		return;
	}
	CurAddress = val;
	if (!DeviceID) return;
	if (comma(lp))	dirPageImpl("ORG");
	else 			Device->CheckPage(CDevice::CHECK_RESET);
}

void dirDISP() {
	aint val;
	if (ParseExpressionNoSyntaxError(lp, val)) {
		adrdisp = CurAddress;
		CurAddress = val;
		PseudoORG = 1;
		dispPageNum = LABEL_PAGE_UNDEFINED;
		if (comma(lp)) {
			if (!ParseExpressionNoSyntaxError(lp, dispPageNum)) {
				dispPageNum = LABEL_PAGE_UNDEFINED;
				Error("[DISP] Syntax error in <page number>", lp);
			} else {
				if (DeviceID) {
					if (dispPageNum < 0 || Device->PagesCount <= dispPageNum) {
						ErrorInt("[DISP] <page number> is out of range", dispPageNum);
						dispPageNum = LABEL_PAGE_UNDEFINED;
					}
				} else {
					Error("[DISP] <page number> is accepted only in device mode", line);
				}
			}
		}
	} else {
		Error("[DISP] Syntax error in <address>", lp, SUPPRESS);
	}
}

void dirENT() {
	if (!PseudoORG) {
		Error("ENT should be after DISP");return;
	}
	CurAddress = adrdisp;
	PseudoORG = 0;
	dispPageNum = LABEL_PAGE_UNDEFINED;
}

void dirPAGE() {
	if (!DeviceID) {
		Warning("PAGE only allowed in real device emulation mode (See DEVICE)");
		SkipParam(lp);
	} else {
		dirPageImpl("PAGE");
	}
}

void dirMMU() {
	if (!DeviceID) {
		Warning("MMU is allowed only in real device emulation mode (See DEVICE)");
		SkipToEol(lp);
		return;
	}
	aint slot1, slot2, pageN = -1;
	CDeviceSlot::ESlotOptions slotOpt = CDeviceSlot::O_NONE;
	if (!ParseExpression(lp, slot1)) {
		Error("[MMU] First slot number parsing failed", bp, SUPPRESS);
		return;
	}
	slot2 = slot1;
	if (!comma(lp)) {	// second slot or slot-option should follow (if not comma)
		// see if there is slot1-only with option-char (e/w/n options)
		const char slotOptChar = (*lp)|0x20;	// primitive ASCII tolower
		if ('a' <= slotOptChar && slotOptChar <= 'z' && (',' == lp[1] || White(lp[1]))) {
			if ('e' == slotOptChar) slotOpt = CDeviceSlot::O_ERROR;
			else if ('w' == slotOptChar) slotOpt = CDeviceSlot::O_WARNING;
			else if ('n' == slotOptChar) slotOpt = CDeviceSlot::O_NEXT;
			else {
				Warning("[MMU] Unknown slot option (legal: e, w, n)", lp);
			}
			++lp;
		} else {	// there was no option char, check if there was slot2 number to define range
			if (!ParseExpression(lp, slot2)) {
				Error("[MMU] Second slot number parsing failed", bp, SUPPRESS);
				return;
			}
		}
		if (!comma(lp)) {
			Error("[MMU] Comma and page number expected after slot info", bp, SUPPRESS);
			return;
		}
	}
	if (!ParseExpression(lp, pageN)) {
		Error("[MMU] Page number parsing failed", bp, SUPPRESS);
		return;
	}
	// validate argument values
	if (slot1 < 0 || slot2 < slot1 || Device->SlotsCount <= slot2) {
		char buf[LINEMAX];
		SPRINTF1(buf, LINEMAX, "[MMU] Slot number(s) must be in range 0..%u and form a range",
				 Device->SlotsCount - 1);
		Error(buf, NULL, SUPPRESS);
		return;
	}
	if (pageN < 0 || Device->PagesCount <= pageN + (slot2 - slot1)) {
		char buf[LINEMAX];
		SPRINTF1(buf, LINEMAX, "[MMU] Requested page(s) must be in range 0..%u", Device->PagesCount - 1);
		Error(buf, NULL, SUPPRESS);
		return;
	}
	// all valid, set it up
	for (aint slotN = slot1; slotN <= slot2; ++slotN, ++pageN) {
		Device->GetSlot(slotN)->Page = Device->GetPage(pageN);
		// this ^ is also enough to keep global "Slot" up to date (it's a pointer)
		Device->GetSlot(slotN)->Option = slotOpt;	// resets whole range to NONE when range
	}
	// wrap output addresses back into 64ki address space, it's essential for MMU functionality
	if (PseudoORG) adrdisp &= 0xFFFF; else CurAddress &= 0xFFFF;
	Device->CheckPage(CDevice::CHECK_RESET);
}

void dirSLOT() {
	aint val;
	if (!DeviceID) {
		Warning("SLOT only allowed in real device emulation mode (See DEVICE)");
		SkipParam(lp);
		return;
	}
	if (!ParseExpressionNoSyntaxError(lp, val)) {
		Error("[SLOT] Syntax error in <slot_number>", lp, SUPPRESS);
		return;
	}
	if (!Device->SetSlot(val)) {
		char buf[LINEMAX];
		SPRINTF1(buf, LINEMAX, "[SLOT] Slot number must be in range 0..%u", Device->SlotsCount - 1);
		Error(buf, NULL, IF_FIRST);
	}
}

void dirALIGN() {
	// default alignment is 4, default filler is "0/none" (if not specified in directive explicitly)
	aint val, fill;
	ParseAlignArguments(lp, val, fill);
	if (-1 == val) val = 4;
	// calculate how many bytes has to be filled to reach desired alignment
	aint len = (~CurAddress + 1) & (val - 1);
	if (len < 1) return;		// nothing to fill, already aligned
	if (-1 == fill) EmitBlock(0, len, true);
	else			EmitBlock(fill, len, false);
}

void dirMODULE() {
	char* n = GetID(lp);
	if (n && (nullptr == STRCHR(n, '.'))) {
		if (*ModuleName) STRCAT(ModuleName, LINEMAX-1-strlen(ModuleName), ".");
		STRCAT(ModuleName, LINEMAX-1-strlen(ModuleName), n);
		// reset non-local label to default "_"
		if (vorlabp) free(vorlabp);
		vorlabp = STRDUP("_");
	} else {
		if (n) {
			Error("[MODULE] Dots not allowed in <module_name>", n, SUPPRESS);
		} else {
			Error("[MODULE] Syntax error in <name>", bp, SUPPRESS);
		}
	}
}

void dirENDMODULE() {
	if (! *ModuleName) {
		Error("ENDMODULE without MODULE");
		return;
	}
	// remove last part of composite modules name
	char* lastDot = strrchr(ModuleName, '.');
	if (lastDot)	*lastDot = 0;
	else			*ModuleName = 0;
	// reset non-local label to default "_"
	if (vorlabp) free(vorlabp);
	vorlabp = STRDUP("_");
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
	if (!ParseExpressionNoSyntaxError(lp, val)) {
		Error("[SIZE] Syntax error in <filesize>", bp, SUPPRESS);
		return;
	}
	if (LASTPASS != pass) return;	// only active during final pass
	if (-1L == size) size = val;	// first time set
	else if (size != val) ErrorInt("[SIZE] Different size than previous", size);	// just check it's same
}

void dirINCBIN() {
	int offset = 0, length = INT_MAX;
	char* fnaam = GetFileName(lp);
	if (anyComma(lp)) {
		aint val;
		if (!anyComma(lp)) {
			if (!ParseExpressionNoSyntaxError(lp, val)) {
				Error("[INCBIN] Syntax error in <offset>", bp, SUPPRESS);
				delete[] fnaam;
				return;
			}
			offset = val;
		} else --lp;		// there was second comma right after, reread it
		if (anyComma(lp)) {
			if (!ParseExpressionNoSyntaxError(lp, val)) {
				Error("[INCBIN] Syntax error in <length>", bp, SUPPRESS);
				delete[] fnaam;
				return;
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
	if (anyComma(lp)) {
		if (!anyComma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[INCHOB] Syntax error", bp, IF_FIRST); return;
			}
			if (val < 0) {
				Error("[INCHOB] Negative values are not allowed", bp); return;
			}
			offset += val;
		} else --lp;		// there was second comma right after, reread it
		if (anyComma(lp)) {
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
	free(fnaamh);
}

void dirINCTRD() {
	aint val;
	char hobeta[12], hdr[17];
	int offset = 0, length = INT_MAX, res, i;
	FILE* ff;

	char* fnaam = GetFileName(lp), * fnaamh;
	if (anyComma(lp)) {
		if (!anyComma(lp)) {
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
	if (anyComma(lp)) {
		if (!anyComma(lp)) {
			if (!ParseExpression(lp, val)) {
				Error("[INCTRD] Syntax error", bp, IF_FIRST); return;
			}
			if (val < 0) {
				Error("[INCTRD] Negative values are not allowed", bp); return;
			}
			offset = val;
		} else --lp;		// there was second comma right after, reread it
		if (anyComma(lp)) {
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
	char* fnaamh2 = GetPath(fnaam);
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
	if (INT_MAX == length) {
		length = ((unsigned char)hdr[0x0b]) + (((unsigned char)hdr[0x0c]) << 8);
		length -= offset;
	}
	offset += (((unsigned char)hdr[0x0f]) << 12) + (((unsigned char)hdr[0x0e]) << 8);
	fclose(ff);

	BinIncFile(fnaam, offset, length);
	delete[] fnaam;
	delete[] fnaamh;
	free(fnaamh2);
}

void dirSAVESNA() {
	if (pass != LASTPASS) return;		// syntax error is not visible in early passes
	bool exec = true;

	if (!DeviceID) {
		Error("SAVESNA only allowed in real device emulation mode (See DEVICE)");
		exec = false;
	} else if (!IsZXSpectrumDevice(DeviceID)) {
		Error("[SAVESNA] Device must be ZXSPECTRUM48 or ZXSPECTRUM128.");
		exec = false;
	}

	char* fnaam = GetFileName(lp);
	int start = StartAddress;
	if (anyComma(lp)) {
		aint val;
		if (ParseExpression(lp, val)) {
			if (0 <= start) Warning("[SAVESNA] Start address was also defined by END, SAVESNA argument used instead");
			if (0 <= val) {
				start = val;
			} else {
				exec = false; Error("[SAVESNA] Negative values are not allowed", bp, SUPPRESS);
			}
		} else {
			exec = false;
		}
	}
	if (start < 0) {
		exec = false; Error("[SAVESNA] No start address defined", bp, SUPPRESS);
	}

	if (exec && !SaveSNA_ZX(fnaam, start)) {
		Error("[SAVESNA] Error writing file (Disk full?)", bp, IF_FIRST);
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
		Error("SAVETAP only allowed in real device emulation mode (See DEVICE)");
		exec = false;
	}

	fnaam = GetFileName(lp);
	if (anyComma(lp)) {
		if (!anyComma(lp)) {
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
				if (anyComma(lp)) {
					if (headerType == HEADLESS) {
						if (!anyComma(lp)) {
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
						if (anyComma(lp)) {
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
						if (anyComma(lp)) {
							if (!ParseExpression(lp, val)) {
								Error("[SAVETAP] Syntax error", bp, PASS3); return;
							}
							if (val < 0 || val > 255) {
								Error("[SAVETAP] Invalid flag byte", bp, PASS3); return;
							}
							param3 = val;
						}
					} else if (!anyComma(lp)) {
						fnaamh = GetFileName(lp);
						if (!*fnaamh) {
							Error("[SAVETAP] Syntax error in tape file name", bp, PASS3);
							return;
						} else if (anyComma(lp) && !anyComma(lp) && ParseExpression(lp, val)) {
							if (val < 0) {
								Error("[SAVETAP] Negative values are not allowed", bp, PASS3); return;
							} else if (val > 0xFFFF) {
								Error("[SAVETAP] Values higher than FFFFh are not allowed", bp, PASS3); return;
							}
							start = val;

							if (anyComma(lp) && !anyComma(lp) && ParseExpression(lp, val)) {
								if (val < 0) {
									Error("[SAVETAP] Negative values are not allowed", bp, PASS3); return;
								} else if (val > 0xFFFF) {
									Error("[SAVETAP] Values higher than FFFFh are not allowed", bp, PASS3); return;
								}
								length = val;

								if (anyComma(lp)) {
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
								if (anyComma(lp)) {
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
				IsLabelNotFound = 0;
				if (!ParseExpression(lp, val) || IsLabelNotFound) {
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

	if (exec) {
		int done = 0;

		if (realtapeMode) {
			done = TAP_SaveBlock(fnaam, headerType, fnaamh, start, length, param2, param3);
		} else {
			if (!IsZXSpectrumDevice(DeviceID)) {
				Error("[SAVETAP snapshot] Device is not of ZX Spectrum type.", Device->ID, SUPPRESS);
			} else {
				done = TAP_SaveSnapshot(fnaam, start);
			}
		}

		if (!done) {
			Error("[SAVETAP] Error writing file", bp, IF_FIRST);
		}
	}

	if (fnaamh) {
		delete[] fnaamh;
	}
	delete[] fnaam;
}

void dirSAVEBIN() {
	if (!DeviceID) {
		Error("SAVEBIN only allowed in real device emulation mode (See DEVICE)");
		SkipToEol(lp);
		return;
	}
	bool exec = (LASTPASS == pass);
	aint val;
	int start = -1, length = -1;
	char* fnaam = GetFileName(lp);
	if (anyComma(lp)) {
		if (!anyComma(lp)) {
			if (!ParseExpressionNoSyntaxError(lp, val)) {
				Error("[SAVEBIN] Syntax error", bp, SUPPRESS); return;
			}
			if (val < 0) {
				Error("[SAVEBIN] Values less than 0000h are not allowed", bp); return;
			} else if (val > 0xFFFF) {
			  	Error("[SAVEBIN] Values more than FFFFh are not allowed", bp); return;
			}
			start = val;
		} else {
		  	Error("[SAVEBIN] Syntax error. No parameters", bp, PASS3); return;
		}
		if (anyComma(lp)) {
			if (!ParseExpressionNoSyntaxError(lp, val)) {
				Error("[SAVEBIN] Syntax error", bp, SUPPRESS); return;
			}
			if (val < 0) {
				Error("[SAVEBIN] Negative values are not allowed", bp); return;
			}
			length = val;
		}
	} else {
		Error("[SAVEBIN] Syntax error. No parameters", bp); return;
	}

	if (exec && !SaveBinary(fnaam, start, length)) {
		Error("[SAVEBIN] Error writing file (Disk full?)", bp, IF_FIRST);
	}
	delete[] fnaam;
}

void dirSAVEDEV() {
	bool exec = DeviceID && LASTPASS == pass;
	if (!exec && LASTPASS == pass) Error("SAVEDEV only allowed in real device emulation mode (See DEVICE)");

	aint args[3]{-1, -1, -1};		// page, offset, length
	char* fnaam = GetFileName(lp);
	for (auto & arg : args) {
		if (!comma(lp) || !ParseExpression(lp, arg)) {
			exec = false;
			Error("Expected syntax SAVEDEV <filename>,<startPage>,<startOffset>,<length>", bp, SUPPRESS);
		}
	}
	if (exec) {
		// validate arguments
		if (args[0] < 0 || Device->PagesCount <= args[0]) {
			exec = false; ErrorInt("[SAVEDEV] page number is out of range", args[0]);
		}
		const int32_t start = Device->GetMemoryOffset(args[0], args[1]);
		const int32_t totalRam = Device->GetMemoryOffset(Device->PagesCount, 0);
		if (exec && (start < 0 || totalRam <= start)) {
			exec = false; ErrorInt("[SAVEDEV] calculated start address is out of range", start);
		}
		if (exec && (args[2] <= 0 || totalRam < start + args[2])) {
			exec = false;
			if (args[2]) ErrorInt("[SAVEDEV] invalid end address (bad length?)", start + args[2]);
			else Warning("[SAVEDEV] zero length requested");
		}
		if (exec && !SaveDeviceMemory(fnaam, (size_t)start, (size_t)args[2])) {
			Error("[SAVEDEV] Error writing file (Disk full?)", bp, IF_FIRST);
		}
	}
	delete[] fnaam;
}

void dirSAVEHOB() {

	if (!DeviceID || pass != LASTPASS) {
		if (!DeviceID) Error("SAVEHOB only allowed in real device emulation mode (See DEVICE)");
		SkipToEol(lp);
		return;
	}
	aint val;
	char* fnaam, * fnaamh;
	int start = -1,length = -1;
	bool exec = true;

	fnaam = GetFileName(lp);
	if (anyComma(lp)) {
		if (!anyComma(lp)) {
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

	if (anyComma(lp)) {
		if (!anyComma(lp)) {
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
		if (anyComma(lp)) {
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
	if (!DeviceID || pass != LASTPASS) {
		if (!DeviceID) Error("SAVETRD only allowed in real device emulation mode (See DEVICE)");
		SkipToEol(lp);
		return;
	}

	bool exec = true, replace = false;
	aint val;
	char* fnaam, * fnaamh;
	int start = -1, length = -1, autostart = -1;

	fnaam = GetFileName(lp);
	if (anyComma(lp)) {
		if (!anyComma(lp)) {
			if ((replace = ('|' == *lp))) SkipBlanks(++lp);	// detect "|" for "replace" feature
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

	if (anyComma(lp)) {
		if (!anyComma(lp)) {
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
		if (anyComma(lp)) {
			if (!anyComma(lp)) {
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
		if (anyComma(lp)) {
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

	if (exec) TRD_AddFile(fnaam, fnaamh, start, length, autostart, replace);
	delete[] fnaam;
	delete[] fnaamh;
}

void dirENCODING() {
	char* opt = GetFileName(lp);
	char* comparePtr = opt;
	if (cmphstr(comparePtr, "dos")) {
		ConvertEncoding = ENCDOS;
	} else if (cmphstr(comparePtr, "win")) {
		ConvertEncoding = ENCWIN;
	} else {
		Error("[ENCODING] Invalid argument (valid values: \"dos\" and \"win\")", opt, IF_FIRST);
	}
	delete[] opt;
}

void dirOPT() {
	// supported options: --zxnext[=cspect] --reversepop --dirbol --nofakes --syntax=<...>
	// process OPT specific command keywords first: {push, pop, reset, listoff, liston}
	bool didReset = false, didList = Options::syx.IsListingSuspended;
	while (!SkipBlanks(lp) && '-' != *lp) {
		if (cmphstr(lp, "pop")) {	// "pop" previous syntax state
			if (!Options::SSyntax::popSyntax()) Warning("[OPT] no previous syntax found");
			return;
		} else if (cmphstr(lp, "push")) {	// "push" previous syntax state
			if (didReset) Warning("[OPT] pushing syntax status after reset");
			// preserve current syntax status, before using arguments of OPT
			Options::SSyntax::pushCurrentSyntax();
		} else if (cmphstr(lp, "reset")) {	// keep current syntax state
			Options::SSyntax::resetCurrentSyntax();
			didReset = true;
		} else if (cmphstr(lp, "listoff")) {
			if (!didList) {
				ListFile();		// *list* the OPT line suspending the listing
				// show in listing file that some part was suspended
				FILE* listFile = GetListingFile();
				if (LASTPASS == pass && listFile) fputs("# listing file suspended...\n", listFile);
			}
			donotlist = 1;
			Options::syx.IsListingSuspended = didList = true;
		} else if (cmphstr(lp, "liston")) {
			Options::syx.IsListingSuspended = false;
		} else {
			Error("[OPT] invalid command (valid commands: push, pop, reset, liston, listoff)", lp);
			SkipToEol(lp);
			return;
		}
	}
	// split user arguments into "argc, argv" like variables (by white-space)
	char parsedOpts[LINEMAX];
	char* parsedOptsArray[17] {};	// there must be one more nullptr in the array (16+1)
	int optI = 0, charI = 0, errI;
	while (optI < 16 && !SkipBlanks(lp)) {
		parsedOptsArray[optI++] = parsedOpts + charI;
		while (*lp && !White()) parsedOpts[charI++] = *lp++;
		parsedOpts[charI++] = 0;
	}
	if (!SkipBlanks(lp)) Warning("[OPT] too many options");
	// parse user arguments and adjust current syntax setup
	if (optI != (errI = Options::parseSyntaxOptions(optI, parsedOptsArray))) {
		Error("[OPT] invalid/failed option", parsedOptsArray[errI]);
	}
	// init Z80N extensions if requested (the Init is safe to be called multiple times)
	if (Options::syx.IsNextEnabled) Z80::InitNextExtensions();
}

void dirLABELSLIST() {
	if (pass != 1 || !DeviceID) {
		if (!DeviceID) Error("LABELSLIST only allowed in real device emulation mode (See DEVICE)");
		SkipParam(lp);
		return;
	}
	char* opt = GetFileName(lp);
	if (*opt) {
		STRCPY(Options::UnrealLabelListFName, LINEMAX, opt);
	} else {
		Error("[LABELSLIST] No filename", bp, EARLY);	// pass == 1 -> EARLY
	}
	delete[] opt;
}

void dirCSPECTMAP() {
	if (LASTPASS != pass || !DeviceID) {
		if (!DeviceID) Error("CSPECTMAP only allowed in real device emulation mode (See DEVICE)");
		SkipParam(lp);
		return;
	}
	char* fName = GetFileName(lp);
	if (fName[0]) {
		STRCPY(Options::CSpectMapFName, LINEMAX, fName);
	} else {		// create default map file name from current source file name (appends ".map")
		STRCPY(Options::CSpectMapFName, LINEMAX-5, CurSourcePos.filename);
		STRCAT(Options::CSpectMapFName, LINEMAX-1, ".map");
	}
	delete[] fName;
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
	if (IsLabelNotFound) Error("[IF/IFN] Forward reference", bp, EARLY);
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
	id = NULL;
	if (SkipBlanks()) {						// no argument (use last parsed label)
		if (LastParsedLabel) {
			id = STRDUP(LastParsedLabel);
		} else {
			Error("[IFUSED/IFNUSED] no label defined ahead");
			return false;
		}
	} else {
		char* validLabel = ValidateLabel(lp, false);
		if (validLabel) {
			id = STRDUP(validLabel);
			delete[] validLabel;
			while (islabchar(*lp)) ++lp;	// advance lp beyond parsed label (valid chars only)
		} else {
			SkipToEol(lp);					// ValidateLabel aready reported some error, skip rest
		}
	}
	return id && SkipBlanks();				// valid "id" and no extra characters = OK
}

static void dirIFUSED() {
	char* id;
	if (dirIfusedIfnused(id)) dirIfInternal("IFUSED", LabelTable.IsUsed(id));
	if (id) free(id);
}

static void dirIFNUSED() {
	char* id;
	if (dirIfusedIfnused(id)) dirIfInternal("IFNUSED", !LabelTable.IsUsed(id));
	if (id) free(id);
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
		dirIfInternal("IFNDEF", !DefineTable.FindDuplicate(id));
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
	if (fnaam[0]) {
		EDelimiterType dt = GetDelimiterOfLastFileName();
		ListFile();
		IncludeFile(fnaam, DT_ANGLE == dt);
		donotlist = 1;
	} else {
		Error("[INCLUDE] empty filename", bp);
	}
	delete[] fnaam;
}

void dirOUTPUT() {
	if (LASTPASS != pass) {
		SkipToEol(lp);
		return;
	}
	char* fnaam = GetFileName(lp), modechar = 0;
	int mode = OUTPUT_TRUNCATE;
	if (comma(lp)) {
		if (!SkipBlanks(lp)) modechar = (*lp++) | 0x20;
		switch (modechar) {
			case 't': mode = OUTPUT_TRUNCATE;	break;
			case 'r': mode = OUTPUT_REWIND;		break;
			case 'a': mode = OUTPUT_APPEND;		break;
			default:
				Error("[OUTPUT] Invalid <mode> (valid modes: t, a, r)", bp);
				delete[] fnaam;
				return;
		}
	}
	//Options::NoDestinationFile = false;
	NewDest(fnaam, mode);
	delete[] fnaam;
}

void dirOUTEND()
{
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
		Error("[DEFINE] Illegal <id>", lp, SUPPRESS);
		return;
	}

	DefineTable.Add(id, lp, 0);
	SkipToEol(lp);
	substitutedLine = line;		// override substituted listing for DEFINE
}

void dirUNDEFINE() {
	char* id;

	if (!(id = GetID(lp)) && *lp != '*') {
		Error("[UNDEFINE] Illegal <id>", lp, SUPPRESS);
		return;
	}

	if (*lp == '*') {
		lp++;
// Label removal removed because it seems to be broken beyond repair
//		LabelTable.RemoveAll();
		DefineTable.RemoveAll();
	} else if (DefineTable.FindDuplicate(id)) {
		DefineTable.Remove(id);
// Label removal removed because it seems to be broken beyond repair
// 	} else if (LabelTable.Find(id)) {
// 		LabelTable.Remove(id);
	} else {
		Warning("[UNDEFINE] Identifier not found", id); return;
	}
}

void dirEXPORT() {
	aint val;
	char* n, * p;

	if (!Options::ExportFName[0]) {
		STRCPY(Options::ExportFName, LINEMAX, CurSourcePos.filename);
		if (!(p = strchr(Options::ExportFName, '.'))) {
			p = Options::ExportFName;
		} else {
			*p = 0;
		}
		STRCAT(p, LINEMAX, ".exp");
		Warning("[EXPORT] Filename for exportfile was not indicated. Output will be in", Options::ExportFName, W_EARLY);
	}
	if (!(n = p = GetID(lp))) {
		Error("[EXPORT] Syntax error", lp, SUPPRESS);
		return;
	}
	if (pass != LASTPASS) return;
	IsLabelNotFound = 0;
	GetLabelValue(n, val);
	if (!IsLabelNotFound) WriteExp(p, val);
}

void dirDISPLAY() {
	char decprint = 'H';
	char e[LINEMAX], optionChar;
	char* ep = e;
	aint val;
	do {
		if (SkipBlanks()) {
			Error("[DISPLAY] Expression expected");
			break;
		}
		if (*lp == '/') {
			switch (optionChar = toupper((byte)lp[1])) {
			case 'A': case 'D': case 'H':	// known options, switching hex+dec / dec / hex mode
				decprint = optionChar;
				break;
			case 'L': case 'T':				// silently ignored options (legacy compatibility)
				break ;
			default:
				Error("[DISPLAY] Syntax error, unknown option", lp, SUPPRESS);
				return;
			}
			lp += 2;
			continue;
		}
		// try to parse some string literal
		int ei = 0;
		val = GetCharConstAsString(lp, ep, ei, LINEMAX - (ep-e));
		if (-1 == val) {
			Error("[DISPLAY] Syntax error", line);
			return;
		} else if (val) {
			ep += ei;				// string literal successfuly parsed
		} else {
			// string literal was not there, how about expression?
			if (ParseExpressionNoSyntaxError(lp, val)) {
				if (decprint == 'H' || decprint == 'A') {
					*(ep++) = '0';
					*(ep++) = 'x';
					PrintHexAlt(ep, val);
				}
				if (decprint == 'D' || decprint == 'A') {
					if (decprint == 'A') {
						*(ep++) = ','; *(ep++) = ' ';
					}
					ep += SPRINTF1(ep, (int)(&e[0] + LINEMAX - ep), "%u", val);
				}
				decprint = 'H';
			} else {
				Error("[DISPLAY] Syntax error", line, SUPPRESS);
				return;
			}
		}
	} while(comma(lp));
	*ep = 0; // end line

	if (LASTPASS == pass && *e) {
		_CERR "> " _CMDL e _ENDL;
	}
}

void dirMACRO() {
	if (lijst) Error("[MACRO] No macro definitions allowed here", NULL, FATAL);
	char* lpLabel = LastParsedLabel;	// modifiable copy of global buffer pointer
	// get+validate macro name either from label on same line or from following line
	char* n = GetID(LastParsedLabelLine == CompiledCurrentLine ? lpLabel : lp);
	if (n) MacroTable.Add(n, lp);
	else {
		Error("[MACRO] Illegal macroname");
		SkipToEol(lp);
	}
}

void dirENDS() {
	Error("[ENDS] End structure without structure");
}

void dirASSERT() {
	char* p = lp;
	aint val;
	/*if (!ParseExpression(lp,val)) { Error("Syntax error",0,CATCHALL); return; }
	if (pass==2 && !val) Error("Assertion failed",p);*/
	if (!ParseExpressionNoSyntaxError(lp, val)) {
		Error("[ASSERT] Syntax error", NULL, SUPPRESS);
		return;
	}
	if (pass == LASTPASS && !val) {
		Error("[ASSERT] Assertion failed", p);
	}
	/**lp=0;*/
}

void dirSHELLEXEC() {
	//FIXME for v2.x change the "SHELLEXEC <command>[, <params>]" syntax to "SHELLEXEC <whatever>"
	// (and add good examples how to deal with quotes/colons/long file names with spaces)
	char* command = NULL;
	char* parameters = NULL;

	command = GetFileName(lp, false);
	if (comma(lp)) {
		parameters = GetFileName(lp, false);
	}
	if (pass == LASTPASS) {
		if (!system(nullptr)) {
			Error("[SHELLEXEC] clib command processor is not available on this platform!");
		} else {
			temp[0] = 0;
			STRNCPY(temp, LINEMAX, command, LINEMAX-1);
			if (parameters) {
				STRNCAT(temp, LINEMAX, " ", 2);
				STRNCAT(temp, LINEMAX, parameters, LINEMAX-1);
			}
			if (Options::OutputVerbosity <= OV_ALL) {
				_CERR "Executing <" _CMDL temp _CMDL ">" _ENDL;
			}
			// flush both stdout and stderr before trying to execute anything externally
			_COUT flush;
			_CERR flush;
			// execute the requested command
			int exitCode = system(temp);
			if (exitCode) {
				ErrorInt("[SHELLEXEC] non-zero exit code", WEXITSTATUS(exitCode));
			}
		}
	}
	delete[] command;
	if (NULL != parameters) {
		delete[] parameters;
	}
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
	aint offset = 0;
	char* naam;
	SkipBlanks();
	if (*lp == '@') {
		++lp; global = 1;
	}

	if (!(naam = GetID(lp)) || !strlen(naam)) {
		Error("[STRUCT] Illegal structure name", lp, SUPPRESS);
		return;
	}
	if (comma(lp)) {
		IsLabelNotFound = 0;
		if (!ParseExpressionNoSyntaxError(lp, offset)) {
			Error("[STRUCT] Offset syntax error", lp, SUPPRESS);
			return;
		}
		if (IsLabelNotFound) {
			Error("[STRUCT] Forward reference", NULL, EARLY);
		}
	}
	if (!SkipBlanks()) {
		Error("[STRUCT] syntax error, unexpected", lp);
	}
	st = StructureTable.Add(naam, offset, global);
	ListFile();
	while (ReadLine()) {
		lp = line; /*if (White()) { SkipBlanks(lp); if (*lp=='.') ++lp; if (cmphstr(lp,"ends")) break; }*/
		SkipBlanks(lp);
		if (*lp == '.') {
			++lp;
		}
		if (cmphstr(lp, "ends")) {
			st->deflab();
			return;
		}
		ParseStructLine(st);
		ListFile(true);
	}
	Error("[STRUCT] Unexpected end of structure");
	st->deflab();
}

void dirFPOS() {
	aint val;
	int method = SEEK_SET;
	SkipBlanks(lp);
	if ((*lp == '+') || (*lp == '-')) {
		method = SEEK_CUR;
	}
	if (!ParseExpressionNoSyntaxError(lp, val)) {
		Error("[FPOS] Syntax error", lp, SUPPRESS);
	} else if (pass == LASTPASS) {
		SeekDest(val, method);
	}
}

void dirDUP() {
	aint val;
	IsLabelNotFound = 0;

	if (!RepeatStack.empty()) {
		SRepeatStack& dup = RepeatStack.top();
		if (!dup.IsInWork) {
			SkipToEol(lp);		// Just skip the expression to the end of line, don't evaluate yet
			++dup.Level;
			return;
		}
	}

	if (!ParseExpressionNoSyntaxError(lp, val)) {
		Error("[DUP/REPT] Syntax error in <count>", lp, SUPPRESS);
		return;
	}
	if (IsLabelNotFound) {
		Error("[DUP/REPT] Forward reference", NULL, ALL);
	}
	if ((int) val < 1) {
		ErrorInt("[DUP/REPT] Repeat value must be positive", val, IF_FIRST); return;
	}

	SRepeatStack dup;
	dup.RepeatCount = val;
	dup.Level = 0;

	dup.Lines = new CStringsList(lp);
	if (!SkipBlanks()) Error("[DUP] unexpected chars", lp, FATAL);	// Ped7g: should have been empty!
	dup.Pointer = dup.Lines;
	dup.sourcePos = CurSourcePos;
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
	// kill the "EDUP" inside DUP-list (also works as "while" terminator)
	if (dup.Pointer->string) free(dup.Pointer->string);
	dup.Pointer->string = NULL;
	++listmacro;
	char* ml = STRDUP(line);	// copy the EDUP line for List purposes (after the DUP block emit)
	if (ml == NULL) ErrorOOM();

	// To achieve the state when SourceLine for DUP-EDUP block is constant EDUP line,
	// and MacroLine is pointing to source of particular line in block, basically just kill all
	// lines with CurrentSourceLine in remaining code. (TODO v2.x listing with src+macro lines?!)

	TextFilePos oldPos = CurSourcePos;
	CStringsList* olijstp = lijstp;
	++lijst;
	while (dup.RepeatCount--) {
		CurSourcePos = dup.sourcePos;
		DefinitionPos = dup.sourcePos;
		donotlist=1;	// skip first empty line (where DUP itself is parsed)
		lijstp = dup.Lines;
		while (IsRunning && lijstp && lijstp->string) {	// the EDUP/REPT/ENDM line has string=NULL => ends loop
			if (lijstp->source.line) CurSourcePos = lijstp->source;
			DefinitionPos = lijstp->definition;
			STRCPY(line, LINEMAX, lijstp->string);
			substitutedLine = line;		// reset substituted listing
			eolComment = NULL;			// reset end of line comment
			lijstp = lijstp->next;
			ParseLineSafe();
			CurSourcePos.nextSegment();
		}
	}
	delete dup.Lines;
	RepeatStack.pop();
	lijstp = olijstp;
	--lijst;
	CurSourcePos = oldPos;
	DefinitionPos = TextFilePos();
	--listmacro;
	STRCPY(line, LINEMAX,  ml);		// show EDUP line itself
	free(ml);
	substitutedLine = line;			// override substituted list line for EDUP
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

static bool dirDEFARRAY_parseItems(CStringsList** nextPtr) {
	char ml[LINEMAX];
	do {
		const char* const itemLp = lp;
		char* n = ml;
		if (!GetMacroArgumentValue(lp, n)) {
			Error("[DEFARRAY] Syntax error", itemLp, SUPPRESS);
			return false;
		}
		*nextPtr = new CStringsList(ml);
		if ((*nextPtr)->string == NULL) ErrorOOM();
		nextPtr = &((*nextPtr)->next);
	} while (anyComma(lp));
	return SkipBlanks();
}

static void dirDEFARRAY_add(const char* id) {
	DefineTable.Get(id);
	if (NULL == DefineTable.DefArrayList) {
		Error("[DEFARRAY+] unknown array <id>", id);
		SkipToEol(lp);
		return;
	}
	// array was already defined, seek to the last item in the list
	while (DefineTable.DefArrayList->next) DefineTable.DefArrayList = DefineTable.DefArrayList->next;
	dirDEFARRAY_parseItems(&DefineTable.DefArrayList->next);
	return;
}

void dirDEFARRAY() {
	bool plus = ('+' == *lp) ? ++lp, true : false;
	const char* id = White() ? GetID(lp) : nullptr;
	if (!id) {
		Error("[DEFARRAY] Syntax error in <id>", lp);
		SkipToEol(lp);
		return;
	}
	if (!White() || SkipBlanks()) {	// enforce whitespace between ID and first item and detect empty ones
		if (SkipBlanks()) Error("[DEFARRAY] must have at least one entry");
		else Error("[DEFARRAY] missing space between <id> and first <item>", lp);
		SkipToEol(lp);
		return;
	}
	if (plus) {
		dirDEFARRAY_add(id);
	} else {
		CStringsList* a = NULL;
		if (!dirDEFARRAY_parseItems(&a) || NULL == a) {
			if (a) delete a;	// release already parsed items, if there was syntax error
			return;
		}
		DefineTable.Add(id, "", a);
	}
}

#ifdef USE_LUA

static int SplitLuaErrorMessage(const char*& LuaError)
{
	int ln = LuaLine;
	if (LuaError && strstr(LuaError, "[string \"script\"]") == LuaError)
	{
		char *const err = STRDUP(LuaError), *lnp = err, *msgp = NULL;
		if (err == NULL) {
			ErrorOOM();
		} else {
			while (*lnp && (*lnp != ':' || !isdigit((byte)*(lnp+1))) )
				lnp++;
			if (*lnp && (msgp = strchr(++lnp, ':')) )
			{
				*(msgp++) = '\0';
				ln += atoi(lnp);
				SkipBlanks(msgp);
				if (*msgp)
					LuaError += msgp - err;
			}
			free(err);
		}
	}
	return ln;
}

void _lua_showerror() {
	// part from Error(...)
	const char *msgp = lua_tostring(LUA, -1);
	int ln = SplitLuaErrorMessage(msgp);

	// print error and other actions
	SPRINTF3(ErrorLine, LINEMAX2, "%s(%d): error: [LUA] %s", CurSourcePos.filename, ln, msgp);

	if (!strchr(ErrorLine, '\n')) {
		STRCAT(ErrorLine, LINEMAX2-1, "\n");
	}

	if (GetListingFile()) fputs(ErrorLine, GetListingFile());
	if (Options::OutputVerbosity <= OV_ERROR) {
		_CERR ErrorLine _END;
	}

	PreviousErrorLine = CompiledCurrentLine;

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
			Error("[LUA] Syntax error", id);
		}
	} else if (pass == LASTPASS) {
		execute = true;
	}

	ln = CurSourcePos.line;
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
	substitutedLine = line;		// override substituted list line for ENDLUA
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
		LuaLine = CurSourcePos.line;
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
	++deviceDirectivesCounter;		// any usage counts, even invalid
	char* id = GetID(lp);

	if (id) {
		if (!SetDevice(id)) {
			Error("[DEVICE] Invalid parameter", NULL, IF_FIRST);
		} else if (IsSldExportActive()) {
			// SLD tracing data are being exported, export the device data
			int pageSize = Device->GetCurrentSlot()->Size;
			int pageCount = Device->PagesCount;
			int slotsCount = Device->SlotsCount;
			char buf[LINEMAX];
			snprintf(buf, LINEMAX, "pages.size:%d,pages.count:%d,slots.count:%d",
				pageSize, pageCount, slotsCount
			);
			for (int slotI = 0; slotI < slotsCount; ++slotI) {
				size_t bufLen = strlen(buf);
				char* bufAppend = buf + bufLen;
				snprintf(bufAppend, LINEMAX-bufLen,
						 (0 == slotI) ? ",slots.adr:%d" : ",%d",
						 Device->GetSlot(slotI)->Address);
			}
			// pagesize
			WriteToSldFile(-1,-1,'Z',buf);
		}
	} else {
		Error("[DEVICE] Syntax error in <deviceid>", lp, SUPPRESS);
	}
}

void InsertDirectives() {
	DirectivesTable.insertd(".assert", dirASSERT);
	DirectivesTable.insertd(".byte", dirBYTE);
	DirectivesTable.insertd(".abyte", dirABYTE);
	DirectivesTable.insertd(".abytec", dirABYTEC);
	DirectivesTable.insertd(".abytez", dirABYTEZ);
	DirectivesTable.insertd(".word", dirWORD);
	DirectivesTable.insertd(".block", dirBLOCK);
	DirectivesTable.insertd(".dword", dirDWORD);
	DirectivesTable.insertd(".d24", dirD24);
	DirectivesTable.insertd(".dg", dirDG);
	DirectivesTable.insertd(".defg", dirDG);
	DirectivesTable.insertd(".dh", dirDH);
	DirectivesTable.insertd(".defh", dirDH);
	DirectivesTable.insertd(".hex", dirDH);
	DirectivesTable.insertd(".org", dirORG);
	DirectivesTable.insertd(".fpos",dirFPOS);
	DirectivesTable.insertd(".align", dirALIGN);
	DirectivesTable.insertd(".module", dirMODULE);
	DirectivesTable.insertd(".size", dirSIZE);
	//DirectivesTable.insertd(".textarea",dirTEXTAREA);
	DirectivesTable.insertd(".textarea", dirDISP);
	DirectivesTable.insertd(".else", dirELSE);
	DirectivesTable.insertd(".export", dirEXPORT);
	DirectivesTable.insertd(".display", dirDISPLAY);
	DirectivesTable.insertd(".end", dirEND);
	DirectivesTable.insertd(".include", dirINCLUDE);
	DirectivesTable.insertd(".incbin", dirINCBIN);
	DirectivesTable.insertd(".binary", dirINCBIN);
	DirectivesTable.insertd(".inchob", dirINCHOB);
	DirectivesTable.insertd(".inctrd", dirINCTRD);
	DirectivesTable.insertd(".insert", dirINCBIN);
	DirectivesTable.insertd(".savenex", dirSAVENEX);
	DirectivesTable.insertd(".savesna", dirSAVESNA);
	DirectivesTable.insertd(".savehob", dirSAVEHOB);
	DirectivesTable.insertd(".savebin", dirSAVEBIN);
	DirectivesTable.insertd(".savedev", dirSAVEDEV);
	DirectivesTable.insertd(".emptytap", dirEMPTYTAP);
	DirectivesTable.insertd(".savetap", dirSAVETAP);
	DirectivesTable.insertd(".emptytrd", dirEMPTYTRD);
	DirectivesTable.insertd(".savetrd", dirSAVETRD);
	DirectivesTable.insertd(".shellexec", dirSHELLEXEC);
/*#ifdef WIN32
	DirectivesTable.insertd(".winexec", dirWINEXEC);
#endif*/
	DirectivesTable.insertd(".if", dirIF);
	DirectivesTable.insertd(".ifn", dirIFN);
	DirectivesTable.insertd(".ifused", dirIFUSED);
	DirectivesTable.insertd(".ifnused", dirIFNUSED);
	DirectivesTable.insertd(".ifdef", dirIFDEF);
	DirectivesTable.insertd(".ifndef", dirIFNDEF);
	DirectivesTable.insertd(".output", dirOUTPUT);
	DirectivesTable.insertd(".outend", dirOUTEND);
	DirectivesTable.insertd(".tapout", dirTAPOUT);
	DirectivesTable.insertd(".tapend", dirTAPEND);
	DirectivesTable.insertd(".define", dirDEFINE);
	DirectivesTable.insertd(".undefine", dirUNDEFINE);
	DirectivesTable.insertd(".defarray", dirDEFARRAY);
	DirectivesTable.insertd(".macro", dirMACRO);
	DirectivesTable.insertd(".struct", dirSTRUCT);
	DirectivesTable.insertd(".dc", dirDC);
	DirectivesTable.insertd(".dz", dirDZ);
	DirectivesTable.insertd(".db", dirBYTE);
	DirectivesTable.insertd(".dm", dirBYTE);
	DirectivesTable.insertd(".dw", dirWORD);
	DirectivesTable.insertd(".ds", dirBLOCK);
	DirectivesTable.insertd(".dd", dirDWORD);
	DirectivesTable.insertd(".defb", dirBYTE);
	DirectivesTable.insertd(".defw", dirWORD);
	DirectivesTable.insertd(".defs", dirBLOCK);
	DirectivesTable.insertd(".defd", dirDWORD);
	DirectivesTable.insertd(".defm", dirBYTE);
	DirectivesTable.insertd(".endmod", dirENDMODULE);
	DirectivesTable.insertd(".endmodule", dirENDMODULE);
	DirectivesTable.insertd(".rept", dirDUP);
	DirectivesTable.insertd(".dup", dirDUP);
	DirectivesTable.insertd(".disp", dirDISP);
	DirectivesTable.insertd(".phase", dirDISP);
	DirectivesTable.insertd(".ent", dirENT);
	DirectivesTable.insertd(".unphase", dirENT);
	DirectivesTable.insertd(".dephase", dirENT);
	DirectivesTable.insertd(".page", dirPAGE);
	DirectivesTable.insertd(".slot", dirSLOT);
	DirectivesTable.insertd(".mmu", dirMMU);
	DirectivesTable.insertd(".encoding", dirENCODING);
	DirectivesTable.insertd(".opt", dirOPT);
	DirectivesTable.insertd(".labelslist", dirLABELSLIST);
	DirectivesTable.insertd(".cspectmap", dirCSPECTMAP);
	DirectivesTable.insertd(".endif", dirENDIF);
	DirectivesTable.insertd(".endt", dirENT);
	DirectivesTable.insertd(".endm", dirENDM);
	DirectivesTable.insertd(".edup", dirEDUP);
	DirectivesTable.insertd(".endr", dirEDUP);
	DirectivesTable.insertd(".ends", dirENDS);

	DirectivesTable.insertd(".device", dirDEVICE);

#ifdef USE_LUA
	DirectivesTable.insertd(".lua", dirLUA);
	DirectivesTable.insertd(".endlua", dirENDLUA);
	DirectivesTable.insertd(".includelua", dirINCLUDELUA);
#endif //USE_LUA

	DirectivesTable_dup.insertd(".dup", dirDUP);
	DirectivesTable_dup.insertd(".edup", dirEDUP);
	DirectivesTable_dup.insertd(".endm", dirENDM);
	DirectivesTable_dup.insertd(".endr", dirEDUP);
	DirectivesTable_dup.insertd(".rept", dirDUP);
}

#ifdef USE_LUA

bool LuaSetPage(aint n) {
	return dirPageImpl("sj.set_page", n);
}

bool LuaSetSlot(aint n) {
	if (!DeviceID) {
		Warning("sj.set_slot: only allowed in real device emulation mode (See DEVICE)");
		return false;
	}
	if (!Device->SetSlot(n)) {
		char buf[LINEMAX];
		SPRINTF1(buf, LINEMAX, "sj.set_slot: Slot number must be in range 0..%u", Device->SlotsCount - 1);
		Error(buf, NULL, IF_FIRST);
		return false;
	}
	return true;
}

#endif //USE_LUA

//eof direct.cpp
