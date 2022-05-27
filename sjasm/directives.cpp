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
	if (!(n = getinstr(lp))) {	// will also reject any instruction followed by colon char (label)
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
	if ((isDigitDot && !White(*lp)) || !ParseExpression(isDigitDot ? ++n : ++lp, val) || (isExprDot && ')' != *lp++)) {
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

static void dirBYTE() {
	getBytesWithCheck();
}

static void dirDC() {
	getBytesWithCheck(0, 1);
}

static void dirDZ() {
	getBytesWithCheck(0, 0, true);
}

static void dirABYTE() {
	aint add;
	if (ParseExpressionNoSyntaxError(lp, add)) {
		getBytesWithCheck(add);
	} else {
		Error("ABYTE <offset> <bytes>: parsing <offset> failed", bp, SUPPRESS);
	}
}

static void dirABYTEC() {
	aint add;
	if (ParseExpressionNoSyntaxError(lp, add)) {
		getBytesWithCheck(add, 1);
	} else {
		Error("ABYTEC <offset> <bytes>: parsing <offset> failed", bp, SUPPRESS);
	}
}

static void dirABYTEZ() {
	aint add;
	if (ParseExpressionNoSyntaxError(lp, add)) {
		getBytesWithCheck(add, 0, true);
	} else {
		Error("ABYTEZ <offset> <bytes>: parsing <offset> failed", bp, SUPPRESS);
	}
}

static void dirWORD() {
	aint val;
	int teller = 0, e[130];
	do {
		// reset alternate result flag in ParseExpression part of code
		Relocation::isResultAffected = false;
		if (SkipBlanks()) {
			Error("Expression expected", NULL, SUPPRESS);
		} else if (ParseExpressionNoSyntaxError(lp, val)) {
			check16(val);
			e[teller] = val & 65535;
			Relocation::resolveRelocationAffected(teller * 2);
			++teller;
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

static void dirDWORD() {
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

static void dirD24() {
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

static void dirDG() {
	int dirDx[130];
	if (GetBits(lp, dirDx)) {
		EmitBytes(dirDx);
	} else {
		Error("no arguments");
	}
}

static void dirDH() {
	int dirDx[130];
	if (GetBytesHexaText(lp, dirDx)) {
		EmitBytes(dirDx);
	} else {
		Error("no arguments");
	}
}

static void dirBLOCK() {
	aint teller,val = 0;
	if (ParseExpressionNoSyntaxError(lp, teller)) {
		if (teller < 0) {
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

bool dirPageImpl(const char* const dirName, int pageNumber) {
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

static void dirORG() {
	aint val;
	if (!ParseExpressionNoSyntaxError(lp, val)) {
		Error("[ORG] Syntax error in <address>", lp, SUPPRESS);
		return;
	}
	// crop (with warning) address in device or non-longptr mode to 16bit address range
	if ((DeviceID || !Options::IsLongPtr) && !check16u(val)) val &= 0xFFFF;
	CurAddress = val;
	if (DISP_NONE != PseudoORG) WarningById(W_DISPLACED_ORG);
	if (!DeviceID) return;
	if (!comma(lp)) {
		Device->CheckPage(CDevice::CHECK_RESET);
		return;
	}
	// emit warning when current slot does not cover address used for ORG
	auto slot = Device->GetCurrentSlot();
	if ((CurAddress < slot->Address || slot->Address + slot->Size <= CurAddress)) {
		char warnTxt[LINEMAX];
		SPRINTF4(warnTxt, LINEMAX,
					"address 0x%04X vs slot %d range 0x%04X..0x%04X",
					CurAddress, Device->GetCurrentSlotNum(), slot->Address, slot->Address + slot->Size - 1);
		WarningById(W_ORG_PAGE, warnTxt);
	}
	dirPageImpl("ORG");
}

static void dirDISP() {
	if (DISP_NONE != PseudoORG) {
		Warning("[DISP] displacement inside another displacement block, ignoring it.");
		SkipToEol(lp);
		return;
	}
	aint valAdr, valPageNum;
	// parse+validate values first, don't even switch into DISP mode in case of any error
	Relocation::isResultAffected = false;
	if (!ParseExpressionNoSyntaxError(lp, valAdr)) {
		Error("[DISP] Syntax error in <address>", lp, SUPPRESS);
		return;
	}
	// the expression of the DISP shouldn't be affected by relocation (even when starting inside relocation block)
	if (Relocation::checkAndWarn(true)) {
		SkipToEol(lp);
		return;		// report it as error and exit early
	}
	if (comma(lp)) {
		if (!ParseExpressionNoSyntaxError(lp, valPageNum)) {
			Error("[DISP] Syntax error in <page number>", lp);
			return;
		}
		if (!DeviceID) {
			Error("[DISP] <page number> is accepted only in device mode", line);
			return;
		}
		if (valPageNum < 0 || Device->PagesCount <= valPageNum) {
			ErrorInt("[DISP] <page number> is out of range", valPageNum);
			return;
		}
		dispPageNum = valPageNum;
	} else {
		dispPageNum = LABEL_PAGE_UNDEFINED;
	}
	// crop (with warning) address in device or non-longptr mode to 16bit address range
	if ((DeviceID || !Options::IsLongPtr) && !check16u(valAdr)) valAdr &= 0xFFFF;
	// everything is valid, switch to DISP mode (dispPageNum is already set above)
	adrdisp = CurAddress;
	CurAddress = valAdr;
	PseudoORG = Relocation::isActive ? DISP_INSIDE_RELOCATE : DISP_ACTIVE;
}

static void dirENT() {
	if (DISP_NONE == PseudoORG) {
		Error("ENT should be after DISP");
		return;
	}
	// check if the DISP..ENT block is either fully inside relocation block, or engulfing it fully.
	if (DISP_ACTIVE == PseudoORG && Relocation::isActive) {
		Error("The DISP block did start outside of relocation block, can't end inside it");
		return;
	}
	if (DISP_INSIDE_RELOCATE == PseudoORG && !Relocation::isActive) {
		Error("The DISP block did start inside of relocation block, can't end outside of it");
		return;
	}
	CurAddress = adrdisp;
	PseudoORG = DISP_NONE;
	dispPageNum = LABEL_PAGE_UNDEFINED;
}

static void dirPAGE() {
	if (!DeviceID) {
		Warning("PAGE only allowed in real device emulation mode (See DEVICE)");
		SkipParam(lp);
	} else {
		dirPageImpl("PAGE");
	}
}

static void dirMMU() {
	if (!DeviceID) {
		Warning("MMU is allowed only in real device emulation mode (See DEVICE)");
		SkipToEol(lp);
		return;
	}
	aint slot1, slot2, pageN = -1, address = -1;
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
	if (comma(lp)) {
		if (!ParseExpressionNoSyntaxError(lp, address)) {
			Error("[MMU] address parsing failed", bp, SUPPRESS);
			return;
		}
		check16(address);
		address &= 0xFFFF;
	}
	// convert slot entered as addresses into slot numbering (must be precise start address of slot)
	slot1 = Device->SlotNumberFromPreciseAddress(slot1);
	slot2 = Device->SlotNumberFromPreciseAddress(slot2);
	// validate argument values
	if (slot1 < 0 || slot2 < slot1 || Device->SlotsCount <= slot2) {
		char buf[LINEMAX];
		SPRINTF1(buf, LINEMAX, "[MMU] Slot number(s) must be in range 0..%u (or exact starting address of slot) and form a range",
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
	if (DISP_NONE != PseudoORG) adrdisp &= 0xFFFF; else CurAddress &= 0xFFFF;
	// set explicit ORG address if the third argument was provided
	if (0 <= address) {
		CurAddress = address;
		if (DISP_NONE != PseudoORG) {
			WarningById(W_DISPLACED_ORG);
		}
	}
	Device->CheckPage(CDevice::CHECK_RESET);
}

static void dirSLOT() {
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
	val = Device->SlotNumberFromPreciseAddress(val);
	if (!Device->SetSlot(val)) {
		char buf[LINEMAX];
		SPRINTF1(buf, LINEMAX, "[SLOT] Slot number must be in range 0..%u, or exact starting address of slot", Device->SlotsCount - 1);
		Error(buf, NULL, IF_FIRST);
	}
}

static void dirALIGN() {
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

static void dirMODULE() {
	char* n = GetID(lp);
	if (n && (nullptr == STRCHR(n, '.'))) {
		if (*ModuleName) STRCAT(ModuleName, LINEMAX-1-strlen(ModuleName), ".");
		STRCAT(ModuleName, LINEMAX-1-strlen(ModuleName), n);
		// reset non-local label to default "_"
		if (vorlabp) free(vorlabp);
		vorlabp = STRDUP("_");
		if (IsSldExportActive()) {
			WriteToSldFile(-1, CurAddress, 'L', ExportModuleToSld());
		}
	} else {
		if (n) {
			Error("[MODULE] Dots not allowed in <module_name>", n, SUPPRESS);
		} else {
			Error("[MODULE] Syntax error in <name>", bp, SUPPRESS);
		}
	}
}

static void dirENDMODULE() {
	if (! *ModuleName) {
		Error("ENDMODULE without MODULE");
		return;
	}
	if (IsSldExportActive()) {
		WriteToSldFile(-1, CurAddress, 'L', ExportModuleToSld(true));
	}
	// remove last part of composite modules name
	char* lastDot = strrchr(ModuleName, '.');
	if (lastDot)	*lastDot = 0;
	else			*ModuleName = 0;
	// reset non-local label to default "_"
	if (vorlabp) free(vorlabp);
	vorlabp = STRDUP("_");
}

static void dirEND() {
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

static void dirSIZE() {
	aint val;
	if (!ParseExpressionNoSyntaxError(lp, val)) {
		Error("[SIZE] Syntax error in <filesize>", bp, SUPPRESS);
		return;
	}
	if (LASTPASS != pass) return;	// only active during final pass
	if (-1L == size) size = val;	// first time set
	else if (size != val) ErrorInt("[SIZE] Different size than previous", size);	// just check it's same
}

static void dirINCBIN() {
	int offset = 0, length = INT_MAX;
	std::unique_ptr<char[]> fnaam(GetFileName(lp));
	if (anyComma(lp)) {
		aint val;
		if (!anyComma(lp)) {
			if (!ParseExpressionNoSyntaxError(lp, val)) {
				Error("[INCBIN] Syntax error in <offset>", bp, SUPPRESS);
				return;
			}
			offset = val;
		} else --lp;		// there was second comma right after, reread it
		if (anyComma(lp)) {
			if (!ParseExpressionNoSyntaxError(lp, val)) {
				Error("[INCBIN] Syntax error in <length>", bp, SUPPRESS);
				return;
			}
			length = val;
		}
	}
	BinIncFile(fnaam.get(), offset, length);
}

static void dirINCHOB() {
	aint val;
	char* fnaamh;
	unsigned char len[2];
	int offset = 0,length = -1;
	FILE* ff;

	std::unique_ptr<char[]> fnaam(GetFileName(lp));
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

	fnaamh = GetPath(fnaam.get());
	if (!FOPEN_ISOK(ff, fnaamh, "rb")) {
		Error("[INCHOB] Error opening file", fnaam.get(), FATAL);
	}
	if (fseek(ff, 0x0b, 0) || 2 != fread(len, 1, 2, ff)) {
		Error("[INCHOB] Hobeta file has wrong format", fnaam.get(), FATAL);
	}
	fclose(ff);
	if (length == -1) {
		// calculate remaining length of the file (from the specified offset)
		length = len[0] + (len[1] << 8) - offset;
	}
	offset += 17;		// adjust offset (skip HOB header)
	BinIncFile(fnaam.get(), offset, length);
	free(fnaamh);
}

static void dirINCTRD() {
	aint val, offset = 0, length = INT_MAX;
	std::unique_ptr<char[]> trdname(GetFileName(lp));
	std::unique_ptr<char[]> filename;
	if (anyComma(lp) && !anyComma(lp)) filename.reset(GetFileName(lp));
	if ( !filename || !filename[0] ) {
		// file-in-disk syntax error
		Error("[INCTRD] Syntax error", bp, IF_FIRST);
		SkipToEol(lp);
		return;
	}
	if (anyComma(lp)) {
		if (!anyComma(lp)) {
			if (!ParseExpressionNoSyntaxError(lp, val)) {
				Error("[INCTRD] Syntax error", bp, IF_FIRST);
				SkipToEol(lp);
				return;
			}
			if (val < 0) {
				ErrorInt("[INCTRD] Negative offset value is not allowed", val);
				SkipToEol(lp);
				return;
			}
			offset = val;
		} else --lp;		// there was second comma right after, reread it
		if (anyComma(lp)) {
			if (!ParseExpressionNoSyntaxError(lp, val)) {
				Error("[INCTRD] Syntax error", bp, IF_FIRST);
				SkipToEol(lp);
				return;
			}
			if (val < 0) {
				ErrorInt("[INCTRD] Negative length value is not allowed", val);
				SkipToEol(lp);
				return;
			}
			length = val;
		}
	}
	if (TRD_PrepareIncFile(trdname.get(), filename.get(), offset, length)) {
		BinIncFile(trdname.get(), offset, length);
	}
}

static void dirSAVESNA() {
	if (pass != LASTPASS) return;		// syntax error is not visible in early passes

	if (!DeviceID) {
		Error("SAVESNA only allowed in real device emulation mode (See DEVICE)", nullptr, SUPPRESS);
		return;
	} else if (!IsZXSpectrumDevice(DeviceID)) {
		Error("[SAVESNA] Device must be ZXSPECTRUM48 or ZXSPECTRUM128.", nullptr, SUPPRESS);
		return;
	}

	std::unique_ptr<char[]> fnaam(GetOutputFileName(lp));
	int start = StartAddress;
	if (anyComma(lp)) {
		aint val;
		if (!ParseExpression(lp, val)) return;
		if (0 <= start) Warning("[SAVESNA] Start address was also defined by END, SAVESNA argument used instead");
		if (0 <= val) {
			start = val;
		} else {
			Error("[SAVESNA] Negative values are not allowed", bp, SUPPRESS);
			return;
		}
	}
	if (start < 0) {
		Error("[SAVESNA] No start address defined", bp, SUPPRESS);
		return;
	}

	if (!SaveSNA_ZX(fnaam.get(), start)) Error("[SAVESNA] Error writing file (Disk full?)", bp, IF_FIRST);
}

static void dirEMPTYTAP() {
	if (pass != LASTPASS) {
		SkipParam(lp);
		return;
	}
	std::unique_ptr<char[]> fnaam(GetOutputFileName(lp));
	if (!fnaam[0]) {
		Error("[EMPTYTAP] Syntax error", bp, IF_FIRST); return;
	}
	TAP_SaveEmpty(fnaam.get());
}

static void dirSAVETAP() {

	if (pass != LASTPASS) {
		SkipParam(lp);
		return;
	}

	bool exec = true, realtapeMode = false;
	int headerType = -1;
	aint val;
	int start = -1, length = -1, param2 = -1, param3 = -1;

	if (!DeviceID) {
		Error("SAVETAP only allowed in real device emulation mode (See DEVICE)");
		exec = false;
	}

	std::unique_ptr<char[]> fnaam(GetOutputFileName(lp));
	std::unique_ptr<char[]> fnaamh;
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
						fnaamh.reset(GetFileName(lp));
						if (!fnaamh[0]) {
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
				IsLabelNotFound = false;
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
			done = TAP_SaveBlock(fnaam.get(), headerType, fnaamh.get(), start, length, param2, param3);
		} else {
			if (!IsZXSpectrumDevice(DeviceID)) {
				Error("[SAVETAP snapshot] Device is not of ZX Spectrum type.", Device->ID, SUPPRESS);
			} else {
				done = TAP_SaveSnapshot(fnaam.get(), start);
			}
		}

		if (!done) {
			Error("[SAVETAP] Error writing file", bp, IF_FIRST);
		}
	}
}

static void dirSAVEBIN() {
	if (!DeviceID) {
		Error("SAVEBIN only allowed in real device emulation mode (See DEVICE)");
		SkipToEol(lp);
		return;
	}
	bool exec = (LASTPASS == pass);
	aint val;
	int start = -1, length = -1;
	std::unique_ptr<char[]> fnaam(GetOutputFileName(lp));
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

	if (exec && !SaveBinary(fnaam.get(), start, length)) {
		Error("[SAVEBIN] Error writing file (Disk full?)", bp, IF_FIRST);
	}
}

static void dirSAVEDEV() {
	bool exec = DeviceID && LASTPASS == pass;
	if (!exec && LASTPASS == pass) Error("SAVEDEV only allowed in real device emulation mode (See DEVICE)");

	aint args[3]{-1, -1, -1};		// page, offset, length
	std::unique_ptr<char[]> fnaam(GetOutputFileName(lp));
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
		if (exec && !SaveDeviceMemory(fnaam.get(), (size_t)start, (size_t)args[2])) {
			Error("[SAVEDEV] Error writing file (Disk full?)", bp, IF_FIRST);
		}
	}
}

static void dirSAVE3DOS() {
	if (!DeviceID) {
		Error("SAVE3DOS works in real device emulation mode (See DEVICE)");
		SkipToEol(lp);
		return;
	}
	bool exec = (LASTPASS == pass);
	std::unique_ptr<char[]> fnaam(GetOutputFileName(lp));
	aint args[5] = { -1, -1, 3, -1, -1 };	// address, size, type, w2_line, w3
	const bool optional[] = {false, false, true, true, true};
	if (!anyComma(lp) || !getIntArguments<5>(lp, args, optional)) {
		Error("[SAVE3DOS] expected syntax is <filename>,<address>,<size>[,<type>[,<w2_line>[,<w3>]]]", bp, SUPPRESS);
		return;
	}
	aint &address = args[0], &size = args[1], &type = args[2], &w2_line = args[3], &w3 = args[4];
	if (address < 0 || size < 1 || 0x10000 < address + size) {
		Error("[SAVE3DOS] [address, size] region outside of 64ki", bp);
		return;
	}
	if (-1 == w3) w3 = size;	// default for w3 is size for all types, unless overridden
	switch (type) {
	case 0:		// type Program: default w2 = 0x8000
		if (-1 == w2_line) w2_line = 0x8000;
	case 1:		// type Numeric array: no idea what w2 actually should be for these
	case 2:		// type Character array:
		break;
	case 3:		// type Code: default w2 = load address
		if (-1 == w2_line) w2_line = address;
		break;
	default:
		Error("[SAVE3DOS] expected type 0..3", bp);
		return;
	}
	if (exec && !SaveBinary3dos(fnaam.get(), address, size, type, w2_line, w3)) {
		Error("[SAVE3DOS] Error writing file (Disk full?)", bp, IF_FIRST);
	}
}

static void dirSAVEHOB() {

	if (!DeviceID || pass != LASTPASS) {
		if (!DeviceID) Error("SAVEHOB only allowed in real device emulation mode (See DEVICE)");
		SkipToEol(lp);
		return;
	}
	aint val;
	int start = -1,length = -1;
	bool exec = true;

	std::unique_ptr<char[]> fnaam(GetOutputFileName(lp));
	std::unique_ptr<char[]> fnaamh;
	if (anyComma(lp)) {
		if (!anyComma(lp)) {
			fnaamh.reset(GetFileName(lp));
			if (!fnaamh[0]) {
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
	if (exec && !SaveHobeta(fnaam.get(), fnaamh.get(), start, length)) {
		Error("[SAVEHOB] Error writing file (Disk full?)", bp, IF_FIRST); return;
	}
}

static void dirEMPTYTRD() {
	if (pass != LASTPASS) {
		SkipToEol(lp);
		return;
	}
	char diskLabel[9] = "        ";

	std::unique_ptr<char[]> fnaam(GetOutputFileName(lp));
	if (!fnaam[0]) {
		Error("[EMPTYTRD] Syntax error", bp, IF_FIRST);
		return;
	}
	if (anyComma(lp)) {
		std::unique_ptr<char[]> srcLabel(GetFileName(lp, false));
		if (!srcLabel[0]) {
			Error("[EMPTYTRD] Syntax error, empty label", bp, IF_FIRST);
		} else {
			for (int i = 0; i < 8; ++i) {
				if (!srcLabel[i]) break;
				diskLabel[i] = srcLabel[i];
			}
			if (8 < strlen(srcLabel.get())) {
				Warning("[EMPTYTRD] label will be truncated to 8 characters", diskLabel);
			}
		}
	}
	TRD_SaveEmpty(fnaam.get(), diskLabel);
}

static void dirSAVETRD() {
	if (!DeviceID || pass != LASTPASS) {
		if (!DeviceID) Error("SAVETRD only allowed in real device emulation mode (See DEVICE)");
		SkipToEol(lp);
		return;
	}

	bool exec = true, replace = false, addplace = false;
	aint val;
	int start = -1, length = -1, autostart = -1, lengthMinusVars = -1;

	std::unique_ptr<char[]> fnaam(GetOutputFileName(lp));
	std::unique_ptr<char[]> fnaamh;
	if (anyComma(lp)) {
		if (!anyComma(lp)) {
			if ((replace = ('|' == *lp))) SkipBlanks(++lp);	// detect "|" for "replace" feature
			else if ((addplace = ('&' == *lp))) SkipBlanks(++lp); // detect "&" for "addplace" feature
			fnaamh.reset(GetFileName(lp));
			if (!fnaamh[0]) {
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
			if (addplace) {
				Error("[SAVETRD] Autostart is not used here", bp, PASS3); return;
			} else {
				if (!ParseExpression(lp, val)) {
					Error("[SAVETRD] Syntax error", bp, PASS3); return;
				}
				if (val < 0) {
					Error("[SAVETRD] Negative values are not allowed", bp, PASS3); return;
				}
				autostart = val;
				// optional length of BASIC without variables
				if (anyComma(lp)) {
					if (!ParseExpression(lp, val)) {
						Error("[SAVETRD] Syntax error", bp, PASS3); return;
					}
					lengthMinusVars = val;
				}
			}
		}
	} else {
		Error("[SAVETRD] Syntax error. No parameters", bp, PASS3); return;
	}

	if (exec) TRD_AddFile(fnaam.get(), fnaamh.get(), start, length, autostart, replace, addplace, lengthMinusVars);
}

static void dirENCODING() {
	std::unique_ptr<char[]> opt(GetFileName(lp, false));
	char* comparePtr = opt.get();
	if (cmphstr(comparePtr, "dos")) {
		ConvertEncoding = ENCDOS;
	} else if (cmphstr(comparePtr, "win")) {
		ConvertEncoding = ENCWIN;
	} else {
		Error("[ENCODING] Invalid argument (valid values: \"dos\" and \"win\")", opt.get(), IF_FIRST);
	}
}

static void dirOPT() {
	// supported options: --zxnext[=cspect] --reversepop --dirbol --nofakes --syntax=<...> -W...
	// process OPT specific command keywords first: {push, pop, reset, listoff, liston, listall, listact, listmc}
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
		} else if (cmphstr(lp, "listall")) {
			if (!didList) ListFile();		// *list* the OPT line changing the filtering
			didList = true;
			donotlist = 1;
			Options::syx.ListingType = Options::LST_T_ALL;
		} else if (cmphstr(lp, "listact")) {
			if (!didList) ListFile();		// *list* the OPT line changing the filtering
			didList = true;
			donotlist = 1;
			Options::syx.ListingType = Options::LST_T_ACTIVE;
		} else if (cmphstr(lp, "listmc")) {
			if (!didList) ListFile();		// *list* the OPT line changing the filtering
			didList = true;
			donotlist = 1;
			Options::syx.ListingType = Options::LST_T_MC_ONLY;
		} else {
			Error("[OPT] invalid command (valid commands: push, pop, reset, liston, listoff, listall, listact, listmc)", lp);
			SkipToEol(lp);
			return;
		}
	}
	// split user arguments into "argc, argv" like variables (by white-space)
	char parsedOpts[LINEMAX];
	std::vector<char*> parsedOptsArray;
	int charI = 0, errI;
	while (!SkipBlanks(lp)) {
		parsedOptsArray.push_back(parsedOpts + charI);
		while (*lp && !White()) parsedOpts[charI++] = *lp++;
		parsedOpts[charI++] = 0;
	}
	int optI = parsedOptsArray.size();
	parsedOptsArray.push_back(nullptr);
	// parse user arguments and adjust current syntax setup
	if (optI != (errI = Options::parseSyntaxOptions(optI, parsedOptsArray.data()))) {
		Error("[OPT] invalid/failed option", parsedOptsArray[errI]);
	}
	// init Z80N extensions if requested (the Init is safe to be called multiple times)
	if (Options::syx.IsNextEnabled) Z80::InitNextExtensions();
}

static void dirLABELSLIST() {
	if (pass != 1 || !DeviceID) {
		if (!DeviceID) Error("LABELSLIST only allowed in real device emulation mode (See DEVICE)");
		SkipToEol(lp);
		return;
	}
	std::unique_ptr<char[]> opt(GetOutputFileName(lp));
	if (opt[0]) {
		STRCPY(Options::UnrealLabelListFName, LINEMAX, opt.get());
		Options::EmitVirtualLabels = false;
		if (comma(lp)) {
			aint virtualLabelsArg;
			if (!ParseExpressionNoSyntaxError(lp, virtualLabelsArg)) {
				Error("[LABELSLIST] Syntax error in <virtual labels>", bp, EARLY);
				return;
			}
			Options::EmitVirtualLabels = (virtualLabelsArg != 0);
		}
	} else {
		Error("[LABELSLIST] No filename", bp, EARLY);	// pass == 1 -> EARLY
	}
}

static void dirCSPECTMAP() {
	if (LASTPASS != pass || !DeviceID) {
		if (!DeviceID) Error("CSPECTMAP only allowed in real device emulation mode (See DEVICE)");
		SkipParam(lp);
		return;
	}
	std::unique_ptr<char[]> fName(GetOutputFileName(lp));
	if (fName[0]) {
		STRCPY(Options::CSpectMapFName, LINEMAX, fName.get());
	} else {		// create default map file name from current source file name (appends ".map")
		STRCPY(Options::CSpectMapFName, LINEMAX-5, CurSourcePos.filename);
		STRCAT(Options::CSpectMapFName, LINEMAX-1, ".map");
	}
	// remember page size of current device (in case the source is multi-device later)
	Options::CSpectMapPageSize = Device->GetPage(0)->Size;
}

static void dirBPLIST() {
	// breakpoint file is opened in second pass, and content is written through third pass
	// so position of `BPLIST` directive in source does not matter
	if (2 != pass || !DeviceID) {	// nothing to do in first or last pass, second will open the file
		if (2 == pass) {	// !Device is true -> no device in second pass -> error
			Error("BPLIST only allowed in real device emulation mode (See DEVICE)", nullptr, EARLY);
		}
		SkipToEol(lp);
		return;
	}
	std::unique_ptr<char[]> fName(GetOutputFileName(lp));
	EBreakpointsFile type = BPSF_UNREAL;
	if (cmphstr(lp, "unreal")) {
		type = BPSF_UNREAL;
	} else if (cmphstr(lp, "zesarux")) {
		type = BPSF_ZESARUX;
	} else if (!SkipBlanks()) {
		Warning("[BPLIST] invalid breakpoints file type (use \"unreal\" or \"zesarux\")", lp, W_EARLY);
	}
	OpenBreakpointsFile(fName.get(), type);
}

static void dirSETBREAKPOINT() {
	if (LASTPASS != pass) {
		SkipToEol(lp);
		return;
	}
	aint val = 0;
	if (SkipBlanks(lp)) {		// without any expression do the "$" breakpoint
		WriteBreakpoint(CurAddress);
	} else if (ParseExpressionNoSyntaxError(lp, val)) {
		WriteBreakpoint(val);
	} else {
		Error("[SETBREAKPOINT] Syntax error", bp, SUPPRESS);
	}
}

/*void dirTEXTAREA() {

}*/

// error message templates for IF**some** directives
constexpr static size_t dirIfErrorsN = 2, dirIfErrorsSZ = 48;
const static char dirIfErrorsTxtSrc[dirIfErrorsN][dirIfErrorsSZ] = {
	{ "[%s] No ENDIF" },
	{ "[%s] one ELSE only expected" }
};

// IF and IFN internal helper, to evaluate expression
static bool dirIfIfn(aint & val) {
	IsLabelNotFound = false;
	if (!ParseExpression(lp, val)) {
		Error("[IF/IFN] Syntax error", lp, IF_FIRST);
		return false;
	}
	if (IsLabelNotFound) {
		WarningById(W_FWD_REF, bp, W_EARLY);
	}
	return true;
}

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
	aint elseCounter = 0;
	aint orVal = false;
	while (ENDIF != ret) {
		orVal |= val;
		switch (ret = val ? ReadFile() : SkipFile()) {
			case ELSE:
				if (elseCounter++) Error(errorsTxt[1]);
				val = !val && !orVal;
				break;
			case ELSEIF:
				val = !val && !orVal;
				if (val) {		// active ELSEIF, evaluate expression
					if (!dirIfIfn(val)) {
						val = false;		// syntax error in expression
						orVal = true;		// force remaining IF-blocks inactive
					}
				}
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
		std::unique_ptr<char[]> validLabel(ValidateLabel(lp, false, true));
		if (validLabel) {
			id = STRDUP(validLabel.get());
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

static void dirElseCheckLiveDup() {
	if (RepeatStack.empty()) return;
	if (!RepeatStack.top().IsInWork) return;

	// Seems some ELSE/ELSEIF/ENDIF was encountered inside DUP->EDUP without starting IF
	// -> probably IF was outside of DUP->EDUP block, which is not legal in sjasmplus
	// terminate the current DUP->EDUP macro early and report the open ELSE/ELSEIF/ENDIF
	Error("Conditional block must start and finish inside the repeat block, nested completely");
	lijstp = nullptr;
	RepeatStack.top().RepeatCount = 0;
}

static void dirELSE() {
	dirElseCheckLiveDup();
	Error("ELSE without IF/IFN/IFUSED/IFNUSED/IFDEF/IFNDEF");
}

static void dirELSEIF() {
	dirElseCheckLiveDup();
	Error("ELSEIF without IF/IFN");
}

static void dirENDIF() {
	dirElseCheckLiveDup();
	Error("ENDIF without IF/IFN/IFUSED/IFNUSED/IFDEF/IFNDEF");
}

/*void dirENDTEXTAREA() {
  Error("ENDT without TEXTAREA",0);
}*/

static void dirINCLUDE() {
	std::unique_ptr<char[]> fnaam(GetFileName(lp));
	if (fnaam[0]) {
		EDelimiterType dt = GetDelimiterOfLastFileName();
		ListFile();
		IncludeFile(fnaam.get(), DT_ANGLE == dt);
		donotlist = 1;
	} else {
		Error("[INCLUDE] empty filename", bp);
	}
}

static void dirOUTPUT() {
	if (LASTPASS != pass) {
		SkipToEol(lp);
		return;
	}
	std::unique_ptr<char[]> fnaam(GetOutputFileName(lp));
	char modechar = 0;
	int mode = OUTPUT_TRUNCATE;
	if (comma(lp)) {
		if (!SkipBlanks(lp)) modechar = (*lp++) | 0x20;
		switch (modechar) {
			case 't': mode = OUTPUT_TRUNCATE;	break;
			case 'r': mode = OUTPUT_REWIND;		break;
			case 'a': mode = OUTPUT_APPEND;		break;
			default:
				Error("[OUTPUT] Invalid <mode> (valid modes: t, a, r)", bp);
				return;
		}
	}
	//Options::NoDestinationFile = false;
	NewDest(fnaam.get(), mode);
}

static void dirOUTEND()
{
	if (pass == LASTPASS) CloseDest();
}

static void dirTAPOUT()
{
	aint val;
	std::unique_ptr<char[]> fnaam(GetOutputFileName(lp));
	int tape_flag = 255;
	if (comma(lp))
	{
		if (!ParseExpression(lp, val))
		{
			Error("[TAPOUT] Missing flagbyte value", bp, PASS3); return;
		}
		tape_flag = val;
	}
	if (pass == LASTPASS) OpenTapFile(fnaam.get(), tape_flag);
}

static void dirTAPEND()
{
	// if (!FP_tapout) {Error("TAPEND without TAPOUT", bp, PASS3); return;}
	if (pass == LASTPASS) CloseTapFile();
}

static void dirDEFINE() {
	bool replaceEnabled = ('+' == *lp) ? ++lp, true : false;
	char* id = GetID(lp);
	if (nullptr == id) {
		Error("[DEFINE] Illegal <id>", lp, SUPPRESS);
		return;
	}
	if (White(*lp)) ++lp;		// skip one whitespace (not considered part of value) (others are)
	// but trim trailing spaces of value, if there's eol-comment
	if (eolComment) {
		char *rtrim = lp + strlen(lp);
		while (lp < rtrim && ' ' == rtrim[-1]) --rtrim;
		*rtrim = 0;
	}

	if (replaceEnabled) {
		DefineTable.Replace(id, lp);
	} else {
		DefineTable.Add(id, lp, nullptr);
	}
	SkipToEol(lp);
	substitutedLine = line;		// override substituted listing for DEFINE
}

static void dirUNDEFINE() {
	char* id;

	if (!(id = GetID(lp)) && *lp != '*') {
		Error("[UNDEFINE] Illegal <id>", lp, SUPPRESS);
		return;
	}

	if (*lp == '*') {
		++lp;
		DefineTable.RemoveAll();
	} else if (DefineTable.FindDuplicate(id)) {
		DefineTable.Remove(id);
	} else {
		Warning("[UNDEFINE] Identifier not found", id);
	}
}

static void dirEXPORT() {
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
	IsLabelNotFound = false;
	GetLabelValue(n, val);
	if (!IsLabelNotFound) WriteExp(p, val);
}

static void dirDISPLAY() {
	char decprint = 'H';
	char e[LINEMAX + 32], optionChar;		// put extra buffer at end for particular H/A/D number printout
	char* ep = e, * const endOfE = e + LINEMAX;
	aint val;
	do {
		if (SkipBlanks()) {
			Error("[DISPLAY] Expression expected");
			break;
		}
		if (*lp == '/') {
			switch (optionChar = toupper((byte)lp[1])) {
			case 'A': case 'D': case 'H': case 'B': case 'C':
				// known options, switching hex+dec / dec / hex / binary mode / char mode
				decprint = optionChar;
				break;
			case 'L': case 'T':				// silently ignored options (legacy compatibility)
				// in ALASM: 'L' is "concatenate to previous line" (as if there was no \r\n on it)
				// in ALASM: 'T' used ahead of expression will display first the expression itself, then value
				break ;
			default:
				Error("[DISPLAY] Syntax error, unknown option", lp, SUPPRESS);
				return;
			}
			lp += 2;
			continue;
		}
		// try to parse some string literal
		const int remainingBufferSize = endOfE - ep;
		if (remainingBufferSize <= 0) {
			Error("[DISPLAY] internal buffer overflow, resulting text is too long", line);
			return;
		}
		int ei = 0;
		val = GetCharConstAsString(lp, ep, ei, remainingBufferSize);
		if (-1 == val) {
			Error("[DISPLAY] Syntax error", line);
			return;
		} else if (val) {
			ep += ei;				// string literal successfuly parsed
		} else {
			// string literal was not there, how about expression?
			if (ParseExpressionNoSyntaxError(lp, val)) {
				if (decprint == 'B') {	// 8-bit binary (doesn't care about higher bits)
					*(ep++) = '%';
					aint bitMask = 0x80;
					while (bitMask) {
						*(ep++) = (val & bitMask) ? '1' : '0';
						if (0x10 == bitMask) *(ep++) = '\'';
						bitMask >>= 1;
					}
				}
				if (decprint == 'C') {
					val &= 0xFF;	// truncate to 8bit value
					if (' ' <= val && val < 127) {	// printable ASCII
						*ep++ = '\'';
						*ep++ = val;
						*ep++ = '\'';
					} else {		// non-printable char, do the \x?? form
						*ep++ = '\'';
						*ep++ = '\\';
						*ep++ = 'x';
						PrintHex(ep, val, 2);
						*ep++ = '\'';
					}
				}
				if (decprint == 'H' || decprint == 'A') {
					*(ep++) = '0';
					*(ep++) = 'x';
					PrintHexAlt(ep, val);
				}
				if (decprint == 'D' || decprint == 'A') {
					if (decprint == 'A') {
						*(ep++) = ','; *(ep++) = ' ';
					}
					int charsToPrint = SPRINTF1(ep, remainingBufferSize, "%u", val);
					if (remainingBufferSize <= charsToPrint) {
						Error("[DISPLAY] internal buffer overflow, resulting text is too long", line);
						return;
					}
					ep += charsToPrint;
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
		_CERR "> " _CMDL Options::tcols->display _CMDL e _CMDL Options::tcols->end _ENDL;
	}
}

static void dirMACRO() {
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

static void dirENDS() {
	Error("[ENDS] End structure without structure");
}

static void dirASSERT() {
	char* p = lp;
	aint val;
	if (!ParseExpressionNoSyntaxError(lp, val)) {
		Error("[ASSERT] Syntax error", p, SUPPRESS);
		return;
	}
	if (pass == LASTPASS && !val) {
		Error("[ASSERT] Assertion failed", p);
	}
	if (comma(lp)) SkipToEol(lp);
}

static void dirSHELLEXEC() {
	//TODO for v2.x change the "SHELLEXEC <command>[, <params>]" syntax to "SHELLEXEC <whatever>"
	// (and add good examples how to deal with quotes/colons/long file names with spaces)
	std::unique_ptr<char[]> command(GetFileName(lp, false));
	std::unique_ptr<char[]> parameters;
	if (comma(lp)) {
		parameters.reset(GetFileName(lp, false));
	}
	if (pass == LASTPASS) {
		if (!system(nullptr)) {
			Error("[SHELLEXEC] clib command processor is not available on this platform!");
		} else {
			temp[0] = 0;
			STRNCPY(temp, LINEMAX, command.get(), LINEMAX-1);
			if (parameters) {
				STRNCAT(temp, LINEMAX, " ", 2);
				STRNCAT(temp, LINEMAX, parameters.get(), LINEMAX-1);
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
}

static void dirSTRUCT() {
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
		IsLabelNotFound = false;
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
			++CompiledCurrentLine;
			if (st) st->deflab();
			lp = ReplaceDefine(lp);		// skip any empty substitutions and comments
			substitutedLine = line;		// override substituted listing for ENDS
			return;
		}
		if (st) ParseStructLine(st);
		ListFile(true);
	}
	Error("[STRUCT] Unexpected end of structure");
	st->deflab();
}

static void dirFPOS() {
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

// isWhile == false: DUP/REPT parsing
// isWhile == true: WHILE parsing
static void DupWhileImplementation(bool isWhile) {
	aint val = 0;
	CStringsList* condition = nullptr;

	if (!RepeatStack.empty()) {
		SRepeatStack& dup = RepeatStack.top();
		if (!dup.IsInWork) {
			SkipToEol(lp);		// Just skip the expression to the end of line, don't evaluate yet
			++dup.Level;
			return;
		}
	}

	if (isWhile) {
		condition = new CStringsList(lp);
		if (nullptr == condition) ErrorOOM();
		lp += strlen(condition->string);
		// scan condition string for extra guardian value, and split + parse it as needed
		char* expressionSource = condition->string;
		bool parseOk = ParseExpressionNoSyntaxError(expressionSource, val);
		if (parseOk && *expressionSource && comma(expressionSource)) {
			// comma found, try to parse explicit guardian value
			char* guardianSource = expressionSource;
			parseOk = parseOk && ParseExpressionNoSyntaxError(guardianSource, val);
			// overwrite the comma to keep only condition string without guardian argument
			if (parseOk) {
				assert(',' == expressionSource[-1]);
				expressionSource[-1] = 0;
				++val;		// +1 to explicit value to report error when WHILE does *over* that
			}
		} else {
			val = 100001;	// default guardian value is 100k
		}
		if (!parseOk) {
			Error("[WHILE] Syntax error in <expression>", condition->string, SUPPRESS);
			free(condition->string);			// release original string
			condition->string = STRDUP("0");	// force it to evaluate to zero
			val = 1;
		}
	} else {
		IsLabelNotFound = false;
		if (!ParseExpressionNoSyntaxError(lp, val)) {
			Error("[DUP/REPT] Syntax error in <count>", lp, SUPPRESS);
			return;
		}
		if (IsLabelNotFound) {
			Error("[DUP/REPT] Forward reference", NULL, ALL);
		}
		if ((int) val < 0) {
			ErrorInt("[DUP/REPT] Repeat value must be positive or zero", val, IF_FIRST); return;
		}
	}

	SRepeatStack dup;
	dup.RepeatCount = val;
	dup.RepeatCondition = condition;
	dup.Level = 0;
	dup.Lines = new CStringsList(lp);
	if (!SkipBlanks()) Error("[DUP] unexpected chars", lp, FATAL);	// Ped7g: should have been empty!
	dup.Pointer = dup.Lines;
	dup.sourcePos = CurSourcePos;
	dup.IsInWork = false;
	RepeatStack.push(dup);
}

static void dirDUP() {
	DupWhileImplementation(false);
}

static void dirWHILE() {
	DupWhileImplementation(true);
}

static bool shouldRepeat(SRepeatStack& dup) {
	if (nullptr == dup.RepeatCondition) {
		return 0 <= --dup.RepeatCount;
	} else {
		if (!dup.RepeatCount--) {
			Error("[WHILE] infinite loop? (reaching the guardian value, default 100k)");
			return false;
		}
		aint val = 0;
		IsLabelNotFound = false;
		char* expressionSource = dup.RepeatCondition->string;
		if (!ParseExpressionNoSyntaxError(expressionSource, val) || *expressionSource) {
			TextFilePos oSrcPos = CurSourcePos;
			CurSourcePos = dup.RepeatCondition->source;
			Error("[WHILE] Syntax error in <expression>", dup.RepeatCondition->string, SUPPRESS);
			CurSourcePos = oSrcPos;
			return false;
		}
		if (IsLabelNotFound) {
			WarningById(W_FWD_REF, dup.RepeatCondition->string, W_EARLY);
			return false;
		}
		return val;
	}
}

static void dirEDUP() {
	if (RepeatStack.empty() || RepeatStack.top().IsInWork) {
		Error("[EDUP/ENDR/ENDW] End repeat without repeat");
		return;
	}

	SRepeatStack& dup = RepeatStack.top();
	if (!dup.IsInWork && dup.Level) {
		--dup.Level;
		return;
	}
	dup.IsInWork = true;
	// kill the "EDUP" inside DUP-list (+ works as "while (IsRunning && lijstp && lijstp->string)" terminator)
	if (dup.Pointer->string) free(dup.Pointer->string);
	dup.Pointer->string = NULL;
	++listmacro;
	char* ml = STRDUP(line);	// copy the EDUP line for List purposes (after the DUP block emit)
	if (ml == NULL) ErrorOOM();

	TextFilePos oldPos = CurSourcePos;
	CStringsList* olijstp = lijstp;
	++lijst;
	while (shouldRepeat(dup)) {
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
	if (dup.RepeatCondition) delete dup.RepeatCondition;
	RepeatStack.pop();
	lijstp = olijstp;
	--lijst;
	CurSourcePos = oldPos;
	DefinitionPos = TextFilePos();
	--listmacro;
	STRCPY(line, LINEMAX,  ml);		// show EDUP line itself
	free(ml);
	++CompiledCurrentLine;
	substitutedLine = line;			// override substituted list line for EDUP
	ListFile();
}

static void dirENDM() {
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

static void dirDEFARRAY() {
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

static void dirDEVICE() {
	// refresh source position of first DEVICE directive
	if (1 == ++deviceDirectivesCount) {
		globalDeviceSourcePos = CurSourcePos;
	}

	char* id = GetID(lp);
	if (id) {
		aint ramtop = 0;
		if (anyComma(lp)) {
			if (!ParseExpressionNoSyntaxError(lp, ramtop)) {
				Error("[DEVICE] Syntax error", bp); return;
			}
			if (ramtop < 0x5D00 || 0xFFFF < ramtop) {
			  	ErrorInt("[DEVICE] valid range for RAMTOP is $5D00..$FFFF", ramtop); return;
			}
		}
		// if (1 == deviceDirectivesCount && Device) -> device was already set globally, skip SetDevice
		if (1 < deviceDirectivesCount || !Devices) {
			if (!SetDevice(id, ramtop)) {
				Error("[DEVICE] Invalid parameter", id, IF_FIRST);
			}
		}
	} else {
		Error("[DEVICE] Syntax error in <deviceid>", lp, SUPPRESS);
	}
}

static void dirSLDOPT() {
	SkipBlanks(lp);
	if (cmphstr(lp, "COMMENT")) {
		do {
			SldAddCommentKeyword(GetID(lp));
		} while (!SkipBlanks(lp) && anyComma(lp));
	} else {
		Error("[SLDOPT] Syntax error in <type> (valid is only COMMENT)", lp, SUPPRESS);
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
	DirectivesTable.insertd(".elseif", dirELSEIF);
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
	DirectivesTable.insertd(".savecpcsna", dirSAVECPCSNA);
	DirectivesTable.insertd(".savecdt", dirSAVECDT);
	DirectivesTable.insertd(".save3dos", dirSAVE3DOS);
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
	DirectivesTable.insertd(".while", dirWHILE);
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
	DirectivesTable.insertd(".endw", dirEDUP);
	DirectivesTable.insertd(".ends", dirENDS);

	DirectivesTable.insertd(".device", dirDEVICE);

	DirectivesTable.insertd(".bplist", dirBPLIST);
	DirectivesTable.insertd(".setbreakpoint", dirSETBREAKPOINT);
	DirectivesTable.insertd(".setbp", dirSETBREAKPOINT);

	DirectivesTable.insertd(".relocate_start", Relocation::dirRELOCATE_START);
	DirectivesTable.insertd(".relocate_end", Relocation::dirRELOCATE_END);
	DirectivesTable.insertd(".relocate_table", Relocation::dirRELOCATE_TABLE);

	DirectivesTable.insertd(".sldopt", dirSLDOPT);

#ifdef USE_LUA
	DirectivesTable.insertd(".lua", dirLUA);
	DirectivesTable.insertd(".endlua", dirENDLUA);
	DirectivesTable.insertd(".includelua", dirINCLUDELUA);
#endif //USE_LUA

	DirectivesTable_dup.insertd(".dup", dirDUP);
	DirectivesTable_dup.insertd(".edup", dirEDUP);
	DirectivesTable_dup.insertd(".endm", dirENDM);
	DirectivesTable_dup.insertd(".endr", dirEDUP);
	DirectivesTable_dup.insertd(".endw", dirEDUP);
	DirectivesTable_dup.insertd(".rept", dirDUP);
	DirectivesTable_dup.insertd(".while", dirWHILE);
}

//eof direct.cpp
