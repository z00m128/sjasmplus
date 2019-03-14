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

// sjio.cpp

#include "sjdefs.h"

#include <fcntl.h>

#define DESTBUFLEN 8192

char rlbuf[4096 * 2]; //x2 to prevent errors
int RL_Readed;
bool rldquotes = false,rlsquotes = false,rlspace = false,rlcomment = false,rlcolon = false,rlnewline = true;
char* rlpbuf, * rlppos;

FILE* FP_UnrealList;

int EB[1024 * 64],nEB = 0;
char WriteBuffer[DESTBUFLEN];
int tape_seek = 0;
int tape_length = 0;
int tape_parity = 0x55;
FILE* FP_tapout = NULL;
FILE* FP_Input = NULL, * FP_Output = NULL, * FP_RAW = NULL;
FILE* FP_ListingFile = NULL,* FP_ExportFile = NULL;
aint PreviousAddress,epadres,IsSkipErrors = 0;
aint WBLength = 0;
char hd[] = {
	'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
};

void Error(const char* message, const char* badValueMessage, EStatus type) {
	// check if it is correct pass by the type of error
	if (type == EARLY && LASTPASS <= pass) return;
	if ((type == SUPPRESS || type == IF_FIRST || type == PASS3) && pass < LASTPASS) return;
	// check if this one should be skipped due to type constraints and current-error-state
	if (FATAL != type && PreviousErrorLine == CurrentLocalLine) {
		// non-fatal error, on the same line as previous, maybe skip?
		if (IsSkipErrors || IF_FIRST == type) return;
	}
	// update current-error-state
	if (PreviousErrorLine != CurrentLocalLine) IsSkipErrors = false;	// reset "skip" on new line
	IsSkipErrors |= (SUPPRESS == type);		// keep it holding over the same line, raise it by SUPPRESS type
	++ErrorCount;							// number of non-skipped (!) errors
	PreviousErrorLine = CurrentLocalLine;

	DefineTable.Replace("_ERRORS", ErrorCount);

	if (1 <= pass && pass <= LASTPASS) {	// during assembling, show also file+line info
		int ln = CurrentLocalLine;
#ifdef USE_LUA
		if (LuaLine >= 0) {
			lua_Debug ar;
			lua_getstack(LUA, 1, &ar) ;
			lua_getinfo(LUA, "l", &ar);
			ln = LuaLine + ar.currentline;
		}
#endif //USE_LUA
		SPRINTF2(ErrorLine, LINEMAX2, "%s(%d): ", filename, ln);
	} else ErrorLine[0] = 0;				// reset ErrorLine for STRCAT
	STRCAT(ErrorLine, LINEMAX2, "error: ");
	STRCAT(ErrorLine, LINEMAX2, message);
	if (badValueMessage) {
		STRCAT(ErrorLine, LINEMAX2, ": "); STRCAT(ErrorLine, LINEMAX2, badValueMessage);
	}
	if (!strchr(ErrorLine, '\n')) STRCAT(ErrorLine, LINEMAX2, "\n");	// append EOL if needed
	// print the error into listing file (the OutputVerbosity is intentionally ignored in listing)
	if (FP_ListingFile) fputs(ErrorLine, FP_ListingFile);
	// print the error into stderr if OutputVerbosity allows errors
	if (Options::OutputVerbosity <= OV_ERROR) {
		_CERR ErrorLine _END;
	}
	// terminate whole assembler in case of fatal error
	if (type == FATAL) {
		ExitASM(1);
	}
}

void ErrorInt(const char* message, aint badValue, EStatus type) {
	char numBuf[24];
	SPRINTF1(numBuf, 24, "%ld", badValue);
	Error(message, numBuf, type);
}

void Warning(const char* message, const char* badValueMessage, EWStatus type)
{
	// check if it is correct pass by the type of error
	if (type == W_EARLY && LASTPASS <= pass) return;
	if (type == W_PASS3 && pass < LASTPASS) return;

	++WarningCount;

	DefineTable.Replace("_WARNINGS", WarningCount);

	if (pass <= LASTPASS) {					// during assembling, show also file+line info
		int ln = CurrentLocalLine;
#ifdef USE_LUA
		if (LuaLine >= 0) {
			lua_Debug ar;
			lua_getstack(LUA, 1, &ar) ;
			lua_getinfo(LUA, "l", &ar);
			ln = LuaLine + ar.currentline;
		}
#endif //USE_LUA
		SPRINTF2(ErrorLine, LINEMAX2, "%s(%d): ", filename, ln);
	} else ErrorLine[0] = 0;				// reset ErrorLine for STRCAT
	STRCAT(ErrorLine, LINEMAX2, "warning: ");
	STRCAT(ErrorLine, LINEMAX2, message);
	if (badValueMessage) {
		STRCAT(ErrorLine, LINEMAX2, ": "); STRCAT(ErrorLine, LINEMAX2, badValueMessage);
	}
	if (!strchr(ErrorLine, '\n')) STRCAT(ErrorLine, LINEMAX2, "\n");	// append EOL if needed
	// print the error into listing file (the OutputVerbosity is intentionally ignored in listing)
	if (FP_ListingFile) fputs(ErrorLine, FP_ListingFile);
	// print the error into stderr if OutputVerbosity allows errors
	if (Options::OutputVerbosity <= OV_WARNING) {
		_CERR ErrorLine _END;
	}
}

void CheckRamLimitExceeded()
{
	if (CurAddress >= 0x10000)
	{
		char buf[64];
		SPRINTF2(buf, 1024, "RAM limit exceeded 0x%X by %s", (unsigned int)CurAddress, PseudoORG ? "DISP":"ORG");
		Warning(buf);
		CurAddress &= 0xFFFF;
	}

	if (PseudoORG) if (adrdisp >= 0x10000)
	{
		char buf[64];
		SPRINTF1(buf, 1024, "RAM limit exceeded 0x%X by ORG", (unsigned int)adrdisp);
		Warning(buf);
		adrdisp &= 0xFFFF;
	}
}

void WriteDest() {
	if (!WBLength) {
		return;
	}
	destlen += WBLength;
	if (FP_Output != NULL && (aint) fwrite(WriteBuffer, 1, WBLength, FP_Output) != WBLength) {
		Error("Write error (disk full?)", NULL, FATAL);
	}
	if (FP_RAW != NULL && (aint) fwrite(WriteBuffer, 1, WBLength, FP_RAW) != WBLength) {
		Error("Write error (disk full?)", NULL, FATAL);
	}

	if (FP_tapout)
	{
		int write_length = tape_length + WBLength > 65535 ? 65535 - tape_length : WBLength;

		if ( (aint)fwrite(WriteBuffer, 1, write_length, FP_tapout) != write_length) Error("Write error (disk full?)", NULL, FATAL);

		for (int i = 0; i < write_length; i++) tape_parity ^= WriteBuffer[i];
		tape_length += write_length;

		if (write_length < WBLength)
		{
			WBLength = 0;
			CloseTapFile();
			Error("Tape block exceeds maximal size");
		}
	}
	WBLength = 0;
}

void PrintHEX8(char*& p, aint h) {
	aint hh = h&0xff;
	*(p++) = hd[hh >> 4];
	*(p++) = hd[hh & 15];
}

void listbytes(char*& p) {
	int i = 0;
	while (nEB--) {
		PrintHEX8(p, EB[i++]); *(p++) = ' ';
	}
	i = 4 - i;
	while (i--) {
		*(p++) = ' '; *(p++) = ' '; *(p++) = ' ';
	}
}

void listbytes2(char*& p) {
	for (int i = 0; i != 5; ++i) {
		PrintHEX8(p, EB[i]);
	}
	*(p++) = ' '; *(p++) = ' ';
}

void printCurrentLocalLine(char*& p) {
	aint v = CurrentLocalLine;
	switch (reglenwidth) {
	default:
		*(p++) = (unsigned char)('0' + v / 1000000); v %= 1000000;
	case 6:
		*(p++) = (unsigned char)('0' + v / 100000); v %= 100000;
	case 5:
		*(p++) = (unsigned char)('0' + v / 10000); v %= 10000;
	case 4:
		*(p++) = (unsigned char)('0' + v / 1000); v %= 1000;
	case 3:
		*(p++) = (unsigned char)('0' + v / 100); v %= 100;
	case 2:
		*(p++) = (unsigned char)('0' + v / 10); v %= 10;
	case 1:
		*(p++) = (unsigned char)('0' + v);
	}
	*(p++) = IncludeLevel > 0 ? '+' : ' ';
	*(p++) = IncludeLevel > 1 ? '+' : ' ';
	*(p++) = IncludeLevel > 2 ? '+' : ' ';
}

void PrintHEX32(char*& p, aint h) {
	aint hh = h&0xffffffff;
	*(p++) = hd[hh >> 28]; hh &= 0xfffffff;
	*(p++) = hd[hh >> 24]; hh &= 0xffffff;
	*(p++) = hd[hh >> 20]; hh &= 0xfffff;
	*(p++) = hd[hh >> 16]; hh &= 0xffff;
	*(p++) = hd[hh >> 12]; hh &= 0xfff;
	*(p++) = hd[hh >> 8];  hh &= 0xff;
	*(p++) = hd[hh >> 4];  hh &= 0xf;
	*(p++) = hd[hh];
}

void PrintHEX16(char*& p, aint h) {
	aint hh = h&0xffff;
	*(p++) = hd[hh >> 12]; hh &= 0xfff;
	*(p++) = hd[hh >> 8]; hh &= 0xff;
	*(p++) = hd[hh >> 4]; hh &= 0xf;
	*(p++) = hd[hh];
}

char hd2[] = {
	'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
};

void PrintHEXAlt(char*& p, aint h) {
	aint hh = h&0xffffffff;
	if (hh >> 28 != 0) {
		*(p++) = hd2[hh >> 28];
	}
	hh &= 0xfffffff;
	if (hh >> 24 != 0) {
		*(p++) = hd2[hh >> 24];
	}
	hh &= 0xffffff;
	if (hh >> 20 != 0) {
		*(p++) = hd2[hh >> 20];
	}
	hh &= 0xfffff;
	if (hh >> 16 != 0) {
		*(p++) = hd2[hh >> 16];
	}
	hh &= 0xffff;
	*(p++) = hd2[hh >> 12]; hh &= 0xfff;
	*(p++) = hd2[hh >> 8];  hh &= 0xff;
	*(p++) = hd2[hh >> 4];  hh &= 0xf;
	*(p++) = hd2[hh];
}

void listbytes3(int pad) {
	int i = 0,t;
	char* pp,* sp = pline + 3 + reglenwidth;
	while (nEB) {
		pp = sp;
		PrintHEX16(pp, pad);
		*(pp++) = ' '; t = 0;
		while (nEB && t < 32) {
			PrintHEX8(pp, EB[i++]); --nEB; ++t;
		}
		*(pp++) = '\n'; *pp = 0;
		if (FP_ListingFile != NULL) {
			fputs(pline, FP_ListingFile);
		}
		pad += 32;
	}
}

void PrepareListLine(aint hexadd)
{
	////////////////////////////////////////////////////
	// Line numbers to 1 to 99999 are supported only  //
	// For more lines, then first char is incremented //
	////////////////////////////////////////////////////

	int digit = ' ';
	int linewidth = reglenwidth;
	long linenumber = CurrentLocalLine % 10000;
	if (linewidth > 5)
	{
		linewidth = 5;
		digit = CurrentLocalLine / 10000 + '0';
		if (digit > '~') digit = '~';
		if (CurrentLocalLine >= 10000) linenumber += 10000;
	}
	memset(pline, ' ', 24);
	if (listmacro) pline[23] = '>';
	sprintf(pline, "%*lu", linewidth, linenumber); pline[linewidth] = ' ';
	memcpy(pline + linewidth, "++++++", IncludeLevel > 6 - linewidth ? 6 - linewidth : IncludeLevel);
	sprintf(pline + 6, "%04lX", hexadd & 0xFFFF); pline[10] = ' ';
	if (digit > '0') *pline = digit & 0xFF;
	STRCPY(pline + 24, LINEMAX2, line);
}

static void ListFileStringRtrim() {
	// find end of currently prepared line
	char* beyondLine = pline+24;
	while (*beyondLine) ++beyondLine;
	// and remove trailing white space (space, tab, newline, carriage return, etc..)
	while (pline < beyondLine && beyondLine[-1] <= ' ') --beyondLine;
	// set new line and new string terminator after
	*beyondLine++ = '\n';
	*beyondLine = 0;
}

void ListFile(bool showAsSkipped) {
	if (LASTPASS != pass || NULL == FP_ListingFile || donotlist) {
		donotlist = nEB = 0; return;
	}
	aint pad = PreviousAddress;
	if (pad == -1L) pad = epadres;

	int pos = 0;
	do {
		PrepareListLine(pad);
		if (pos) pline[24] = 0;		// remove source line on sub-sequent list-lines
		char* pp = pline + 10;
		int BtoList = (nEB < 4) ? nEB : 4;
		for (int i = 0; i < BtoList; ++i) pp += sprintf(pp, " %02X", EB[i + pos]);
		*pp = ' ';
		if (showAsSkipped) pline[11] = '~';
		ListFileStringRtrim();
		fputs(pline, FP_ListingFile);
		nEB -= BtoList;
		pad += BtoList;
		pos += BtoList;
	} while (0 < nEB);
	epadres = CurAddress;
	PreviousAddress = -1L;
	nEB = 0;
}

void CheckPage() {
	if (!DeviceID) {
		return;
	}
	/*
	int addadr = 0;
	switch (Slot->Number) {
	case 0:
		addadr = 0x8000;
		break;
	case 1:
		addadr = 0xc000;
		break;
	case 2:
		addadr = 0x4000;
		break;
	case 3:
		addadr = 0x10000;
		break;
	case 4:
		addadr = 0x14000;
		break;
	case 5:
		addadr = 0x0000;
		break;
	case 6:
		addadr = 0x18000;
		break;
	case 7:
		addadr = 0x1c000;
		break;
	}
	if (MemoryCPage > 7) {
		addadr = 0x4000 * MemoryCPage;
	}
	if (PseudoORG) {
		if (adrdisp < 0xC000) {
			addadr = adrdisp - 0x4000;
		} else {
			addadr += adrdisp - 0xC000;
		}
	} else {
		if (CurAddress < 0xC000) {
			addadr = CurAddress - 0x4000;
		} else {
			addadr += CurAddress - 0xC000;
		}
	}
	MemoryPointer = MemoryRAM + addadr;*/

	CDeviceSlot* S;
	for (aint i=0;i<Device->SlotsCount;i++) {
		S = Device->GetSlot(i);
		if (CurAddress >= S->Address \
			&& ((CurAddress < 65536 && CurAddress < S->Address + S->Size) \
				|| (CurAddress >= 65536 && CurAddress <= S->Address + S->Size)) \
		   ) {
			if (PseudoORG) {
				MemoryPointer = S->Page->RAM + (adrdisp - S->Address);
				Page = S->Page;
				return;
			} else {
				MemoryPointer = S->Page->RAM + (CurAddress - S->Address);
				Page = S->Page;
				return;
			}
		}
	}

	Error("CheckPage(): please, contact the author of this program.", NULL, FATAL);
}

void Emit(int byte)
{
	EB[nEB++] = byte;

	CheckRamLimitExceeded();

	if (pass == LASTPASS)
	{
		WriteBuffer[WBLength++] = (char)byte;
		if (WBLength == DESTBUFLEN) WriteDest();

		if (DeviceID)
		{
			if ((MemoryPointer - Page->RAM) >= (int)Page->Size) CheckPage();
			*(MemoryPointer++) = (char)byte;
		}
	}

	++CurAddress;
	if (PseudoORG) ++adrdisp;
}

void EmitByte(int byte) {
	Emit(byte);
}

void EmitWord(int word) {
	Emit(word % 256);
	Emit(word / 256);
}

void EmitBytes(int* bytes) {
	if (*bytes == -1) {
		Error("Illegal instruction", line, IF_FIRST); *lp = 0;
	}
	while (*bytes != -1) {
		Emit(*bytes++);
	}
}

void EmitWords(int* words) {
	while (*words != -1) {
		Emit((*words) % 256);
		Emit((*words++) / 256);
	}
}

void EmitBlock(aint byte, aint len, bool preserveDeviceMemory) {
	if (len) EB[nEB++] = byte;

	if (len < 0)
	{
		CurAddress = (CurAddress + len) & 0xFFFF;
		if (PseudoORG) adrdisp = (adrdisp + len) & 0xFFFF;
		CheckPage();
	}
	else while (len--)
	{
		CheckRamLimitExceeded();

		if (pass == LASTPASS)
		{
			WriteBuffer[WBLength++] = (char)byte;
			if (WBLength == DESTBUFLEN) WriteDest();

			if (DeviceID)
			{
				if ((MemoryPointer - Page->RAM) >= (int)Page->Size) CheckPage();
				if (!preserveDeviceMemory) *MemoryPointer = (char)byte;

				MemoryPointer++;
			}
		}
		++CurAddress;
		if (PseudoORG) ++adrdisp;
	}
}

char* GetPath(char* fname, char** filenamebegin, bool systemPathsBeforeCurrent)
{
	// temporary "head" with CurrentDirectory as first item in list
	CStringsList includesWithCurrent(CurrentDirectory, Options::IncludeDirsList);
	// start search either with the temporary head, or with the list of system include-paths
	CStringsList* dir = systemPathsBeforeCurrent ? Options::IncludeDirsList : &includesWithCurrent;
	char fullFilePath[MAX_PATH];
	while (dir) {
		if (SearchPath(dir->string, fname, NULL, MAX_PATH, fullFilePath, filenamebegin)) break;
		dir = dir->next;
	}
	// disconnect temporary head from real include list (prevents destructor from releasing it all)
	includesWithCurrent.next = NULL;
	// if the file was not found in the list
	if (NULL == dir) {
		//and the current directory was not searched yet, do it now, set empty string if nothing
		if (systemPathsBeforeCurrent ||
			!SearchPath(CurrentDirectory, fname, NULL, MAX_PATH, fullFilePath, filenamebegin)) {
			fullFilePath[0] = 0;
		}
	}
	// copy the result into new memory
	char* kip = STRDUP(fullFilePath);
	if (kip == NULL) Error("No enough memory!", NULL, FATAL);
	// convert filenamebegin pointer into the copied string (from temporary buffer pointer)
	if (filenamebegin) *filenamebegin += (kip - fullFilePath);
	return kip;
}

void BinIncFile(char* fname, int offset, int len) {
	FILE* bif;
	int res;
	int totlen = 0;
	char* fullFilePath;

	fullFilePath = GetPath(fname);
	if (!FOPEN_ISOK(bif, fullFilePath, "rb")) {
		Error("Error opening file", fname, FATAL);
	}
	free(fullFilePath);

	if (offset == -1) offset = 0;

	// Get length of file //
	if (fseek(bif, 0, SEEK_END))
		Error("Error seeking file (len)", fname, FATAL);
	totlen = ftell(bif);
	if (totlen < 0)
		Error("Error telling file (len)", fname, FATAL);

	if (len == -1) len = totlen - offset;
	// Getting final length of included data //
	if (0 == len) {
		Warning("INCBIN: requested to include no data (len=0)");
		fclose(bif);
		return;
	}

	if (LASTPASS == pass && Options::OutputVerbosity <= OV_ALL) {
		printf("INCBIN: name=%s  Offset=%u  Len=%u\n", fname, offset, len);
	}

	// Check requested data //
	if (offset + len > totlen)
		Error("Error file too short", fname, FATAL);

	// Seek to begin of including part //
	if (offset > totlen)
		Error("Offset overflows file length", fname, FATAL);
	if (fseek(bif, offset, SEEK_SET))
		Error("Error seeking file (offs)", fname, FATAL);
	if (ftell(bif) != offset)
		Error("Error telling file (offs)", fname, FATAL);

	// Getting final length of included data //
	if (len > 0x10000) {
		len = 0x10000;
		Warning("Included data truncated to 64kB from");
	}

	if (pass != LASTPASS) {
		CurAddress = (CurAddress + len) & 0xFFFF;
		if (PseudoORG) adrdisp = (adrdisp + len) & 0xFFFF;
	} else {
		// Reading data from file //
		char* data = new char[len + 1];
		char *bp = data;

		if (bp == NULL)
			ErrorInt("No enough memory for file", (len + 1), FATAL);

		res = fread(bp, 1, len, bif);

		if (res == -1)
			Error("Can't read file (read error)", fname, FATAL);
		if (res != len)
			Error("Can't read file (no enough data)", fname, FATAL);

		while (len--) {
			CheckRamLimitExceeded();

			if (pass == LASTPASS) {
				WriteBuffer[WBLength++] = *bp;
				if (WBLength == DESTBUFLEN) WriteDest();

				if (DeviceID) {
					if ((MemoryPointer - Page->RAM) >= (int)Page->Size) CheckPage();
					*MemoryPointer = *bp;

					MemoryPointer++;
				}
			}
			++bp;
			++CurAddress;
			if (PseudoORG) ++adrdisp;
		}
		CheckRamLimitExceeded();
		delete[] data;
	}
	fclose(bif);
}

void OpenFile(char* nfilename, bool systemPathsBeforeCurrent)
{
	char ofilename[LINEMAX];
	char* oCurrentDirectory, * fullpath, * listFullName = NULL;
	TCHAR* filenamebegin;

	if (++IncludeLevel > 20) {
		Error("Over 20 files nested", NULL, FATAL);
	}
	fullpath = GetPath(nfilename, &filenamebegin, systemPathsBeforeCurrent);

	if (!FOPEN_ISOK(FP_Input, fullpath, "rb")) {
		free(fullpath);
		Error("Error opening file", nfilename, FATAL);
	}

	// show in listing file which file was opened
	if (LASTPASS == pass && FP_ListingFile) {
		listFullName = STRDUP(fullpath);	// create copy of full filename for listing file
		fputs("# file opened: ", FP_ListingFile);
		fputs(listFullName, FP_ListingFile);
		fputs("\n", FP_ListingFile);
	}

	aint oCurrentLocalLine = CurrentLocalLine;
	CurrentLocalLine = 0;
	STRCPY(ofilename, LINEMAX, filename);

	if (Options::IsShowFullPath) {
		STRCPY(filename, LINEMAX, fullpath);
	} else {
		STRCPY(filename, LINEMAX, nfilename);
	}

	oCurrentDirectory = CurrentDirectory;
	*filenamebegin = 0;
	CurrentDirectory = fullpath;

	RL_Readed = 0; rlpbuf = rlbuf; rlcolon = false;
	ReadBufLine(true);

	fclose(FP_Input);
	--IncludeLevel;
	CurrentDirectory = oCurrentDirectory;

	// show in listing file which file was closed
	if (LASTPASS == pass && FP_ListingFile) {
		fputs("# file closed: ", FP_ListingFile);
		fputs(listFullName, FP_ListingFile);
		fputs("\n", FP_ListingFile);
		free(listFullName);
	}

	// Free memory
	free(fullpath);

	STRCPY(filename, LINEMAX, ofilename);
	if (CurrentLocalLine > maxlin) {
		maxlin = CurrentLocalLine;
	}
	CurrentLocalLine = oCurrentLocalLine;
}

void IncludeFile(char* nfilename, bool systemPathsBeforeCurrent)
{
	FILE* oFP_Input = FP_Input;
	FP_Input = 0;

	char* pbuf = rlpbuf;
	char* buf = STRDUP(rlbuf);
	if (buf == NULL) Error("No enough memory!", NULL, FATAL);
	int readed = RL_Readed;
	bool squotes = rlsquotes,dquotes = rldquotes,space = rlspace,comment = rlcomment,colon = rlcolon,newline = rlnewline;

	rldquotes = false; rlsquotes = false;rlspace = false;rlcomment = false;rlcolon = false;rlnewline = true;

	memset(rlbuf, 0, 8192);

	OpenFile(nfilename, systemPathsBeforeCurrent);

	rlsquotes = squotes,rldquotes = dquotes,rlspace = space,rlcomment = comment,rlcolon = colon,rlnewline = newline;
	rlpbuf = pbuf;
	STRCPY(rlbuf, 8192, buf);
	RL_Readed = readed;

	free(buf);

	FP_Input = oFP_Input;
}

void ReadBufLine(bool Parse, bool SplitByColon) {
	//FIXME Ped7g - seems a bit too complicated, check + comment + refactor if needed
	rlppos = line;
	if (rlcolon) {
		*(rlppos++) = '\t';
	}
	while (IsRunning && (RL_Readed > 0 || (RL_Readed = fread(rlbuf, 1, 4096, FP_Input)))) {
		if (!*rlpbuf) {
			rlpbuf = rlbuf;
		}
		while (IsRunning && RL_Readed > 0) {

			if (!CurrentLocalLine)
			{
				CurrentLocalLine++;
				CurrentGlobalLine++;
				CompiledCurrentLine++;
			}

			if (*rlpbuf == '\n' || *rlpbuf == '\r') {

				rlpbuf++; RL_Readed--;
				if (rlpbuf[-1] == '\r')
				{
					if (!RL_Readed)
					{
						RL_Readed = fread(rlbuf, 1, 4096, FP_Input);
						if (!RL_Readed) break;
						rlpbuf = rlbuf;
					}
					if (*rlpbuf == '\n') { rlpbuf++; RL_Readed--; }
				}
				*rlppos = 0;
				if (strlen(line) == LINEMAX - 1) {
					Error("Line too long", NULL, FATAL);
				}
				rlsquotes = rldquotes = rlcomment = rlspace = rlcolon = false;
				if (IsRunning && Parse) {
					ParseLine();
				} else {
					rlnewline = true;
					CurrentLocalLine++;
					CurrentGlobalLine++;
					CompiledCurrentLine++;
					return;
				}
				rlppos = line;
				if (rlcolon) {
					*(rlppos++) = ' ';
				}
				rlnewline = true;
				CurrentLocalLine++;
				CurrentGlobalLine++;
				CompiledCurrentLine++;
			} else if (SplitByColon && *rlpbuf == ':' && rlspace && !rldquotes && !rlsquotes && !rlcomment) {
				while (*rlpbuf && *rlpbuf == ':') {
					rlpbuf++;RL_Readed--;
				}
			  	*rlppos = 0;
				if (strlen(line) == LINEMAX - 1) {
					Error("Line too long", NULL, FATAL);
				}
				rlcolon = true;
				if (IsRunning && Parse) {
					ParseLine();
				} else {
					return;
				}
				rlppos = line;
				if (rlcolon) *(rlppos++) = ' ';
			} else if (*rlpbuf == ':' && !rlspace && !rlcolon && !rldquotes && !rlsquotes && !rlcomment) {
				lp = line; *rlppos = 0;
				// it's label
				*(rlppos++) = ':';
				rlspace = true;
				while (*rlpbuf && *rlpbuf == ':') {
					rlpbuf++;
					RL_Readed--;
				}
			} else {
				if (*rlpbuf == '\\' && rldquotes && !rlcomment) {	// \ inside "" = escaping next char
					*rlppos++ = *rlpbuf++; RL_Readed--;		// copy extra backslash (escape)
				} else if (*rlpbuf == '\'' && !rldquotes && !rlcomment) {
					rlsquotes = !rlsquotes;
				} else if (*rlpbuf == '"' && !rlsquotes && !rlcomment) {
					rldquotes = !rldquotes;
				} else if (*rlpbuf == ';' && !rlsquotes && !rldquotes) {
					rlcomment = true;
				} else if (*rlpbuf == '/' && *(rlpbuf + 1) == '/' && !rlsquotes && !rldquotes) {
					rlcomment = true;
					*rlppos++ = *rlpbuf++; RL_Readed--;		// copy extra slash
				} else if (*rlpbuf <= ' ' && !rlsquotes && !rldquotes && !rlcomment) {
					rlspace = true;
				}
				*rlppos++ = *rlpbuf++; RL_Readed--;
			}
		}
		rlpbuf = rlbuf;
	}
	//for end of line
	if (feof(FP_Input) && RL_Readed <= 0 && *line) {
		rlsquotes = rldquotes = rlcomment = rlspace = rlcolon = false;
		rlnewline = true;
		*rlppos = 0;
		if (IsRunning && Parse) {
			ParseLine();
		} else {
			return;
		}
		rlppos = line;
	}
}

void OpenList() {
	if (NULL != FP_ListingFile) return;		// already opened
	if (Options::ListingFName[0]) {
		if (!FOPEN_ISOK(FP_ListingFile, Options::ListingFName, "w")) {
			Error("Error opening file", Options::ListingFName, FATAL);
		}
	}
}

void OpenUnrealList() {
	/*if (!FP_UnrealList && Options::UnrealLabelListFName && !FOPEN_ISOK(FP_UnrealList, Options::UnrealLabelListFName, "w")) {
		Error("Error opening file", Options::UnrealLabelListFName, FATAL);
	}*/
}

void CloseDest() {
	
	// Correction for 1.10.1
	// Flush buffer before any other operations
	WriteDest();

	// simple check
	if (FP_Output == NULL) {
		return;
	}

	long pad;
	//if (WBLength) {
	//	WriteDest();
	//}
	if (size != (aint)-1) {
		if (destlen > size) {
			ErrorInt("File exceeds 'size'", destlen);
		} else {
			pad = size - destlen;
			if (pad > 0) {
				while (pad--) {
					WriteBuffer[WBLength++] = 0;
					if (WBLength == 256) {
						WriteDest();
					}
				}
			}
			if (WBLength) {
				WriteDest();
			}
		}
	}
	fclose(FP_Output);
	FP_Output = NULL;
}

void SeekDest(long offset, int method) {
	WriteDest();
	if (FP_Output != NULL && fseek(FP_Output, offset, method)) {
		Error("File seek error (FORG)", NULL, FATAL);
	}
}

void NewDest(char* newfilename) {
	NewDest(newfilename, OUTPUT_TRUNCATE);
}

void NewDest(char* newfilename, int mode) {
	// close file
	CloseDest();

	// and open new file
	STRCPY(Options::DestionationFName, LINEMAX, newfilename);
	OpenDest(mode);
}

void OpenDest() {
	OpenDest(OUTPUT_TRUNCATE);
}

void OpenDest(int mode) {
	destlen = 0;
	if (mode != OUTPUT_TRUNCATE && !FileExists(Options::DestionationFName)) {
		mode = OUTPUT_TRUNCATE;
	}
	if (!Options::NoDestinationFile && !FOPEN_ISOK(FP_Output, Options::DestionationFName, mode == OUTPUT_TRUNCATE ? "wb" : "r+b")) {
		Error("Error opening file", Options::DestionationFName, FATAL);
	}
	Options::NoDestinationFile = false;
	if (FP_RAW == NULL && Options::RAWFName[0] && !FOPEN_ISOK(FP_RAW, Options::RAWFName, "wb")) {
		Error("Error opening file", Options::RAWFName);
	}
	if (FP_Output != NULL && mode != OUTPUT_TRUNCATE) {
		if (fseek(FP_Output, 0, mode == OUTPUT_REWIND ? SEEK_SET : SEEK_END)) {
			Error("File seek error (OUTPUT)", NULL, FATAL);
		}
	}
}

void CloseTapFile()
{
	char tap_data[2];

	WriteDest();
	if (FP_tapout == NULL) return;

	tap_data[0] = tape_parity & 0xFF;
	if (fwrite(tap_data, 1, 1, FP_tapout) != 1) Error("Write error (disk full?)", NULL, FATAL);

	if (fseek(FP_tapout, tape_seek, SEEK_SET)) Error("File seek end error in TAPOUT", NULL, FATAL);

	tap_data[0] =  tape_length     & 0xFF;
	tap_data[1] = (tape_length>>8) & 0xFF;
	if (fwrite(tap_data, 1, 2, FP_tapout) != 2) Error("Write error (disk full?)", NULL, FATAL);

	fclose(FP_tapout);
	FP_tapout = NULL;
}

void OpenTapFile(char * tapename, int flagbyte)
{
	CloseTapFile();

	if (!FOPEN_ISOK(FP_tapout,tapename, "r+b"))	Error( "Error opening file in TAPOUT", tapename, FATAL);
	if (fseek(FP_tapout, 0, SEEK_END))			Error("File seek end error in TAPOUT", tapename, FATAL);
	
	tape_seek = ftell(FP_tapout);
	tape_parity = flagbyte;
	tape_length = 2;
	
	char tap_data[4] = { 0,0,0,0 };
	tap_data[2] = (char)flagbyte;
	
	if (fwrite(tap_data, 1, 3, FP_tapout) != 3)
	{
		fclose(FP_tapout);
		Error("Write error (disk full?)", NULL, FATAL);
	}
}

int FileExists(char* file_name) {
	int exists = 0;
	FILE* test;
	if (FOPEN_ISOK(test, file_name, "r")) {
		exists = 1;
		fclose(test);
	}
	return exists;
}

void Close() {
	CloseDest();
	CloseTapFile();
	if (FP_ExportFile != NULL) {
		fclose(FP_ExportFile);
		FP_ExportFile = NULL;
	}
	if (FP_RAW != NULL) {
		fclose(FP_RAW);
		FP_RAW = NULL;
	}
	if (FP_ListingFile != NULL) {
		fclose(FP_ListingFile);
		FP_ListingFile = NULL;
	}
	//if (FP_UnrealList && pass == 9999) {
	//	fclose(FP_UnrealList);
	//}
}

int SaveRAM(FILE* ff, int start, int length) {
	//unsigned int addadr = 0,save = 0;
	aint save = 0;

	if (!DeviceID) {
		return 0;
	}

	if (length + start > 0xFFFF) {
		length = -1;
	}
	if (length <= 0) {
		length = 0x10000 - start;
	}

	CDeviceSlot* S;
	for (aint i=0;i<Device->SlotsCount;i++) {
		S = Device->GetSlot(i);
		if (start >= (int)S->Address  && start < (int)(S->Address + S->Size)) {
			if (length < (int)(S->Size - (start - S->Address))) {
				save = length;
			} else {
				save = S->Size - (start - S->Address);
			}
			if ((aint) fwrite(S->Page->RAM + (start - S->Address), 1, save, ff) != save) {
				return 0;
			}
			length -= save;
			start += save;
			//_COUT "Start: " _CMDL start _CMDL " Length: " _CMDL length _ENDL;
			if (length <= 0) {
				return 1;
			}
		}
	}

	return 1;
/*
	// $4000-$7FFF
	if (start < 0x8000) {
		save = length;
		addadr = start - 0x4000;
		if (save + start > 0x8000) {
			save = 0x8000 - start;
			length -= save;
			start = 0x8000;
		} else {
			length = 0;
		}
		if (fwrite(MemoryRAM + addadr, 1, save, ff) != save) {
			return 0;
		}
	}

	// $8000-$BFFF
	if (length > 0 && start < 0xC000) {
		save = length;
		addadr = start - 0x4000;
		if (save + start > 0xC000) {
			save = 0xC000 - start;
			length -= save;
			start = 0xC000;
		} else {
			length = 0;
		}
		if (fwrite(MemoryRAM + addadr, 1, save, ff) != save) {
			return 0;
		}
	}

	// $C000-$FFFF
	if (length > 0) {
		if (Options::MemoryType == MT_ZX48) {
			addadr = start;
		} else {
			switch (MemoryCPage) {
			case 0:
				addadr = 0x8000;
				break;
			case 1:
				addadr = 0xc000;
				break;
			case 2:
				addadr = 0x4000;
				break;
			case 3:
				addadr = 0x10000;
				break;
			case 4:
				addadr = 0x14000;
				break;
			case 5:
				addadr = 0x0000;
				break;
			default:
				addadr = 0x4000*MemoryCPage;
				break;
			}
			addadr += start - 0xC000;
		}
		save = length;
		if (fwrite(MemoryRAM + addadr, 1, save, ff) != save) {
			return 0;
		}
	}
	return 1;*/
}

unsigned int MemGetWord(unsigned int address) {
	if (pass != LASTPASS) {
		return 0;
	}

	return MemGetByte(address)+(MemGetByte(address+1)*256);
}

unsigned char MemGetByte(unsigned int address) {
	if (!DeviceID || pass != LASTPASS) {
		return 0;
	}

	CDeviceSlot* S;
	for (aint i=0;i<Device->SlotsCount;i++) {
		S = Device->GetSlot(i);
		if (address >= (unsigned int)S->Address  && address < (unsigned int)S->Address + (unsigned int)S->Size) {
			return S->Page->RAM[address - S->Address];
		}
	}

	Error("Error with MemGetByte!", NULL, FATAL);
	return 0;

	/*// $4000-$7FFF
	if (address < 0x8000) {
		return MemoryRAM[address - 0x4000];
	}
	// $8000-$BFFF
	else if (address < 0xC000) {
		return MemoryRAM[address - 0x8000];
	}
		// $C000-$FFFF
	else {*/
		/*unsigned int addadr = 0;
		if (Options::MemoryType == MT_ZX48) {
			return MemoryRAM[address];
		} else {
			switch (MemoryCPage) {
			case 0:
				addadr = 0x8000;
				break;
			case 1:
				addadr = 0xc000;
				break;
			case 2:
				addadr = 0x4000;
				break;
			case 3:
				addadr = 0x10000;
				break;
			case 4:
				addadr = 0x14000;
				break;
			case 5:
				addadr = 0x0000;
				break;
			default:
				addadr = 0x4000*MemoryCPage;
				break;
			}
			addadr += address - 0xC000;*/
			/*if (MemoryRAM[addadr]) {
				return 0;
			}*/
			//return MemoryRAM[addadr];
		//}
	//}
}


int SaveBinary(char* fname, int start, int length) {
	FILE* ff;
	if (!FOPEN_ISOK(ff, fname, "wb")) {
		Error("Error opening file", fname, FATAL);
	}

	if (length + start > 0xFFFF) {
		length = -1;
	}
	if (length <= 0) {
		length = 0x10000 - start;
	}
	//_COUT "Start: " _CMDL start _CMDL " Length: " _CMDL length _ENDL;
	if (!SaveRAM(ff, start, length)) {
		fclose(ff);return 0;
	}

	fclose(ff);
	return 1;
}


int SaveHobeta(char* fname, char* fhobname, int start, int length) {
	unsigned char header[0x11];
	int i;
	for (i = 0; i != 8; header[i++] = 0x20) {
		;
	}
	//for (i = 0; i != 8; ++i) {
	for (i = 0; i < 9; ++i) {

		if (*(fhobname + i) == 0) {
			break;
		}
		if (*(fhobname + i) != '.') {
			header[i] = *(fhobname + i);continue;
		} else if (*(fhobname + i + 1)) {
			header[8] = *(fhobname + i + 1);
		}
		break;
	}


	if (length + start > 0xFFFF) {
		length = -1;
	}
	if (length <= 0) {
		length = 0x10000 - start;
	}

	if (*(fhobname + i + 2) != 0 && *(fhobname + i + 3) != 0) {
		header[0x09] = *(fhobname + i + 2);
		header[0x0a] = *(fhobname + i + 3);
	} else {
		if (header[8] == 'B') {
			header[0x09] = (unsigned char)(length & 0xff);
			header[0x0a] = (unsigned char)(length >> 8);
		} else {
			header[0x09] = (unsigned char)(start & 0xff);
			header[0x0a] = (unsigned char)(start >> 8);
		}
	}

	header[0x0b] = (unsigned char)(length & 0xff);
	header[0x0c] = (unsigned char)(length >> 8);
	header[0x0d] = 0;
	if (header[0x0b] == 0) {
		header[0x0e] = header[0x0c];
	} else {
		header[0x0e] = header[0x0c] + 1;
	}
	length = header[0x0e] * 0x100;
	int chk = 0;
	for (i = 0; i <= 14; chk = chk + (header[i] * 257) + i,i++) {
		;
	}
	header[0x0f] = (unsigned char)(chk & 0xff);
	header[0x10] = (unsigned char)(chk >> 8);

	FILE* ff;
	if (!FOPEN_ISOK(ff, fname, "wb")) {
		Error("Error opening file", fname, FATAL);
	}

	if (fwrite(header, 1, 17, ff) != 17) {
		fclose(ff);return 0;
	}

	if (!SaveRAM(ff, start, length)) {
		fclose(ff);return 0;
	}

	fclose(ff);
	return 1;
}

EReturn ReadFile(const char* pp, const char* err) {
	char* p;
	while (lijst || RL_Readed > 0 || !feof(FP_Input)) {
		if (!IsRunning) {
			return END;
		}
		if (lijst) {
			if (!lijstp) {
				return END;
			}
			STRCPY(line, LINEMAX, lijstp->string);
			p = line;
			lijstp = lijstp->next;
		} else {
			ReadBufLine(false);
			p = line;
			//_COUT "RF:" _CMDL rlcolon _CMDL line _ENDL;
		}

		SkipBlanks(p);
		if (*p == '.') {
			++p;
		}
		if (cmphstr(p, "endif")) {
			lp = ReplaceDefine(p); return ENDIF;
		}
		if (cmphstr(p, "else")) {
			ListFile(); lp = ReplaceDefine(p); return ELSE;
		}
		if (cmphstr(p, "endt")) {
			lp = ReplaceDefine(p); return ENDTEXTAREA;
		}
		if (cmphstr(p, "dephase")) {
			lp = ReplaceDefine(p); return ENDTEXTAREA;
		} // hmm??
		if (cmphstr(p, "unphase")) {
			lp = ReplaceDefine(p); return ENDTEXTAREA;
		} // hmm??
		ParseLineSafe();
	}
	Error("Unexpected end of file", NULL, FATAL);
	return END;
}


EReturn SkipFile(char* pp, const char* err) {
	char* p;
	int iflevel = 0;
	while (lijst || RL_Readed > 0 || !feof(FP_Input)) {
		if (!IsRunning) {
			return END;
		}
		if (lijst) {
			if (!lijstp) {
				return END;
			}
			STRCPY(line, LINEMAX, lijstp->string);
			p = line;
			lijstp = lijstp->next;
		} else {
			ReadBufLine(false);
			p = line;
			//_COUT "SF:" _CMDL rlcolon _CMDL line _ENDL;
		}
		SkipBlanks(p);
		if (*p == '.') {
			++p;
		}
		if (cmphstr(p, "if")) {
			++iflevel;
		}
		if (cmphstr(p, "ifn")) {
			++iflevel;
		}
		if (cmphstr(p, "ifused")) {
			++iflevel;
		}
		if (cmphstr(p, "ifnused")) {
			++iflevel;
		}
		//if (cmphstr(p,"ifexist")) { ++iflevel; }
		//if (cmphstr(p,"ifnexist")) { ++iflevel; }
		if (cmphstr(p, "ifdef")) {
			++iflevel;
		}
		if (cmphstr(p, "ifndef")) {
			++iflevel;
		}
		if (cmphstr(p, "endif")) {
			if (iflevel) {
				--iflevel;
			} else {
				lp = ReplaceDefine(p);
				return ENDIF;
			}
		}
		if (cmphstr(p, "else")) {
			if (!iflevel) {
				ListFile();
				lp = ReplaceDefine(p);
				return ELSE;
			}
		}
		ListFile(true);
	}
	Error("Unexpected end of file", NULL, FATAL);
	return END;
}

int ReadLine(bool SplitByColon) {
	if (!IsRunning || (RL_Readed == 0 && feof(FP_Input))) return 0;
	ReadBufLine(false, SplitByColon);
	return 1;
}

int ReadFileToCStringsList(CStringsList*& f, const char* end) {
	CStringsList* s,* l = NULL;
	char* p;
	f = NULL;
	while (RL_Readed > 0 || !feof(FP_Input)) {
		if (!IsRunning) {
			return 0;
		}
		ReadBufLine(false);
		p = line;

		if (*p) {
			SkipBlanks(p);
			if (*p == '.') {
				++p;
			}
			if (cmphstr(p, end)) {
				lp = ReplaceDefine(p);
				return 1;
			}
		}
		s = new CStringsList(line, NULL);
		if (!f) {
			f = s;
		} if (l) {
			l->next = s;
		}
		l = s;
		ListFile(true);
	}
	Error("Unexpected end of file", NULL, FATAL);
	return 0;
}

void WriteExp(char* n, aint v) {
	char lnrs[16],* l = lnrs;
	if (FP_ExportFile == NULL) {
		if (!FOPEN_ISOK(FP_ExportFile, Options::ExportFName, "w")) {
			Error("Error opening file", Options::ExportFName, FATAL);
		}
	}
	STRCPY(ErrorLine, LINEMAX2, n);
	STRCAT(ErrorLine, LINEMAX2, ": EQU ");
	STRCAT(ErrorLine, LINEMAX2, "0x");
	PrintHEX32(l, v); *l = 0;
	STRCAT(ErrorLine, LINEMAX2, lnrs);
	STRCAT(ErrorLine, LINEMAX2, "\n");
	fputs(ErrorLine, FP_ExportFile);
}

//eof sjio.cpp
