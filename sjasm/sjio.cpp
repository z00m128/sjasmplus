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

// ReadLine buffer and variables around
char rlbuf[4096 * 2]; //x2 to prevent errors
char * rlpbuf, * rlpbuf_end, * rlppos;
bool colonSubline;
int blockComment;

int EB[1024 * 64],nEB = 0;
char WriteBuffer[DESTBUFLEN];
int tape_seek = 0;
int tape_length = 0;
int tape_parity = 0x55;
FILE* FP_tapout = NULL;
FILE* FP_Input = NULL, * FP_Output = NULL, * FP_RAW = NULL;
FILE* FP_ListingFile = NULL,* FP_ExportFile = NULL;
int ListAddress;
aint WBLength = 0;
bool IsSkipErrors = false;

void Error(const char* message, const char* badValueMessage, EStatus type) {
	// check if it is correct pass by the type of error
	if (type == EARLY && LASTPASS <= pass) return;
	if ((type == SUPPRESS || type == IF_FIRST || type == PASS3) && pass < LASTPASS) return;
	// check if this one should be skipped due to type constraints and current-error-state
	if (FATAL != type && PreviousErrorLine == CompiledCurrentLine) {
		// non-fatal error, on the same line as previous, maybe skip?
		if (IsSkipErrors || IF_FIRST == type) return;
	}
	// update current-error-state (reset "skip" on new parsed-line, set "skip" by SUPPRESS type)
	IsSkipErrors = (IsSkipErrors && (PreviousErrorLine == CompiledCurrentLine)) || (SUPPRESS == type);
	PreviousErrorLine = CompiledCurrentLine;
	++ErrorCount;							// number of non-skipped (!) errors

	DefineTable.Replace("_ERRORS", ErrorCount);

	if (1 <= pass && pass <= LASTPASS) {	// during assembling, show also file+line info
		int ln = CurSourcePos.line;
#ifdef USE_LUA
		if (LuaLine >= 0) {
			lua_Debug ar;
			lua_getstack(LUA, 1, &ar) ;
			lua_getinfo(LUA, "l", &ar);
			ln = LuaLine + ar.currentline;
		}
#endif //USE_LUA
		SPRINTF2(ErrorLine, LINEMAX2, "%s(%d): ", CurSourcePos.filename, ln);
	} else ErrorLine[0] = 0;				// reset ErrorLine for STRCAT
	STRCAT(ErrorLine, LINEMAX2-1, "error: ");
	STRCAT(ErrorLine, LINEMAX2-1, message);
	if (badValueMessage) {
		STRCAT(ErrorLine, LINEMAX2-1, ": "); STRCAT(ErrorLine, LINEMAX2-1, badValueMessage);
	}
	if (!strchr(ErrorLine, '\n')) STRCAT(ErrorLine, LINEMAX2-1, "\n");	// append EOL if needed
	// print the error into listing file always (the OutputVerbosity does not apply to listing)
	if (GetListingFile()) fputs(ErrorLine, GetListingFile());
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
	SPRINTF1(numBuf, 24, "%d", badValue);
	Error(message, numBuf, type);
}

void ErrorOOM() {		// out of memory
	Error("Not enough memory!", nullptr, FATAL);
}

void Warning(const char* message, const char* badValueMessage, EWStatus type)
{
	// check if it is correct pass by the type of error
	if (type == W_EARLY && LASTPASS <= pass) return;
	if (type == W_PASS3 && pass < LASTPASS) return;

	// turn the warning into error if "Warnings as errors" is switched on
	if (Options::syx.WarningsAsErrors) switch (type) {
		case W_EARLY:	Error(message, badValueMessage, EARLY); return;
		case W_PASS3:	Error(message, badValueMessage, PASS3); return;
		case W_ALL:		Error(message, badValueMessage, ALL); return;
	}

	++WarningCount;

	DefineTable.Replace("_WARNINGS", WarningCount);

	if (pass <= LASTPASS) {					// during assembling, show also file+line info
		int ln = CurSourcePos.line;
#ifdef USE_LUA
		if (LuaLine >= 0) {
			lua_Debug ar;
			lua_getstack(LUA, 1, &ar) ;
			lua_getinfo(LUA, "l", &ar);
			ln = LuaLine + ar.currentline;
		}
#endif //USE_LUA
		SPRINTF2(ErrorLine, LINEMAX2, "%s(%d): ", CurSourcePos.filename, ln);
	} else ErrorLine[0] = 0;				// reset ErrorLine for STRCAT
	STRCAT(ErrorLine, LINEMAX2-1, "warning: ");
	STRCAT(ErrorLine, LINEMAX2-1, message);
	if (badValueMessage) {
		STRCAT(ErrorLine, LINEMAX2-1, ": "); STRCAT(ErrorLine, LINEMAX2-1, badValueMessage);
	}
	if (!strchr(ErrorLine, '\n')) STRCAT(ErrorLine, LINEMAX2-1, "\n");	// append EOL if needed
	// print the warning into listing file always (the OutputVerbosity does not apply to listing)
	if (GetListingFile()) fputs(ErrorLine, GetListingFile());
	// print the warning into stderr if OutputVerbosity allows warnings
	if (Options::OutputVerbosity <= OV_WARNING) {
		_CERR ErrorLine _END;
	}
}

// find position of extension in filename (points at dot char or beyond filename if no extension)
// filename is pointer to writeable format containing file name (can be full path) (NOT NULL)
// if initWithName and filenameBufferSize are explicitly provided, filename will be first overwritten with those
char* FilenameExtPos(char* filename, const char* initWithName, size_t initNameMaxLength) {
	// if the init value is provided with positive buffer size, init the buffer first
	if (0 < initNameMaxLength && initWithName) {
		STRCPY(filename, initNameMaxLength, initWithName);
	}
	// find start of the base filename
	const char* baseName = FilenameBasePos(filename);
	// find extension of the filename and return position of it
	char* const filenameEnd = filename + strlen(filename);
	char* extPos = filenameEnd;
	while (baseName < extPos && '.' != *extPos) --extPos;
	if (baseName < extPos) return extPos;
	// no extension found (empty filename, or "name", or ".name"), return end of filename
	return filenameEnd;
}

const char* FilenameBasePos(const char* fullname) {
	const char* const filenameEnd = fullname + strlen(fullname);
	const char* baseName = filenameEnd;
	while (fullname < baseName && '/' != baseName[-1] && '\\' != baseName[-1]) --baseName;
	return baseName;
}

void CheckRamLimitExceeded() {
	static bool notWarnedCurAdr = true;
	static bool notWarnedDisp = true;
	char buf[64];
	if (CurAddress >= 0x10000) {
		if (notWarnedCurAdr) {
			SPRINTF2(buf, 64, "RAM limit exceeded 0x%X by %s", (unsigned int)CurAddress, PseudoORG ? "DISP":"ORG");
			Warning(buf);
			notWarnedCurAdr = false;
		}
		if (PseudoORG) CurAddress &= 0xFFFF;	// fake DISP address gets auto-wrapped FFFF->0
	} else notWarnedCurAdr = true;
	if (PseudoORG && adrdisp >= 0x10000) {
		if (notWarnedDisp) {
			SPRINTF1(buf, 64, "RAM limit exceeded 0x%X by ORG", (unsigned int)adrdisp);
			Warning(buf);
			notWarnedDisp = false;
		}
	} else notWarnedDisp = true;
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

void PrintHex(char* & dest, aint value, int nibbles) {
	if (nibbles < 1 || 8 < nibbles) ExitASM(33);	// invalid argument
	const char oldChAfter = dest[nibbles];
	const aint mask = (int(sizeof(aint)*2) <= nibbles) ? ~0L : (1L<<(nibbles*4))-1L;
	if (nibbles != sprintf(dest, "%0*X", nibbles, value&mask)) ExitASM(33);
	dest += nibbles;
	*dest = oldChAfter;
}

void PrintHex32(char*& dest, aint value) {
	PrintHex(dest, value, 8);
}

void PrintHexAlt(char*& dest, aint value)
{
	char buffer[24] = { 0 }, * bp = buffer;
	sprintf(buffer, "%04X", value);
	while (*bp) *dest++ = *bp++;
}

static char pline[4*LINEMAX];

// buffer must be at least 4*LINEMAX chars long
void PrepareListLine(char* buffer, aint hexadd)
{
	////////////////////////////////////////////////////
	// Line numbers to 1 to 99999 are supported only  //
	// For more lines, then first char is incremented //
	////////////////////////////////////////////////////

	int digit = ' ';
	int linewidth = reglenwidth;
	aint linenumber = CurSourcePos.line % 10000;
	if (linewidth > 5)
	{
		linewidth = 5;
		digit = CurSourcePos.line / 10000 + '0';
		if (digit > '~') digit = '~';
		if (CurSourcePos.line >= 10000) linenumber += 10000;
	}
	memset(buffer, ' ', 24);
	if (listmacro) buffer[23] = '>';
	sprintf(buffer, "%*u", linewidth, linenumber); buffer[linewidth] = ' ';
	memcpy(buffer + linewidth, "++++++", IncludeLevel > 6 - linewidth ? 6 - linewidth : IncludeLevel);
	sprintf(buffer + 6, "%04X", hexadd & 0xFFFF); buffer[10] = ' ';
	if (digit > '0') *buffer = digit & 0xFF;
	// if substitutedLine is completely empty, list rather source line any way
	if (!*substitutedLine) substitutedLine = line;
	STRCPY(buffer + 24, LINEMAX2-24, substitutedLine);
	// add EOL comment if substituted was used and EOL comment is available
	if (substitutedLine != line && eolComment) STRCAT(buffer, LINEMAX2, eolComment);
}

static void ListFileStringRtrim() {
	// find end of currently prepared line
	char* beyondLine = pline+24;
	while (*beyondLine) ++beyondLine;
	// and remove trailing white space (space, tab, newline, carriage return, etc..)
	while (pline < beyondLine && White(beyondLine[-1])) --beyondLine;
	// set new line and new string terminator after
	*beyondLine++ = '\n';
	*beyondLine = 0;
}

// returns FILE* handle to either actual file defined by --lst=xxx, or stderr if --msg=lst, or NULL
// ! do not fclose this handle, for fclose logic use the FP_ListingFile variable itself !
FILE* GetListingFile() {
	if (NULL != FP_ListingFile) return FP_ListingFile;
	if (OV_LST == Options::OutputVerbosity) return stderr;
	return NULL;
}

void ListFile(bool showAsSkipped) {
	if (LASTPASS != pass || NULL == GetListingFile() || donotlist || Options::syx.IsListingSuspended) {
		donotlist = nEB = 0;
		return;
	}
	int pos = 0;
	do {
		if (showAsSkipped) substitutedLine = line;	// override substituted lines in skipped mode
		PrepareListLine(pline, ListAddress);
		if (pos) pline[24] = 0;		// remove source line on sub-sequent list-lines
		char* pp = pline + 10;
		int BtoList = (nEB < 4) ? nEB : 4;
		for (int i = 0; i < BtoList; ++i) {
			if (-2 == EB[i + pos]) pp += sprintf(pp, "...");
			else pp += sprintf(pp, " %02X", EB[i + pos]);
		}
		*pp = ' ';
		if (showAsSkipped) pline[11] = '~';
		ListFileStringRtrim();
		fputs(pline, GetListingFile());
		nEB -= BtoList;
		ListAddress += BtoList;
		pos += BtoList;
	} while (0 < nEB);
	nEB = 0;
}

void ListSilentOrExternalEmits() {
	// catch silent/external emits like "sj.add_byte(0x123)" from Lua script
	if (0 == nEB) return;		// no silent/external emit happened
	char silentOrExternalBytes[] = "; these bytes were emitted silently/externally (lua script?)";
	substitutedLine = silentOrExternalBytes;
	eolComment = nullptr;
	ListFile();
	substitutedLine = line;
}

static void EmitByteNoListing(int byte, bool preserveDeviceMemory = false) {
	if (LASTPASS == pass) {
		WriteBuffer[WBLength++] = (char)byte;
		if (DESTBUFLEN == WBLength) WriteDest();
	}
	// the page-checking in device mode must be done in all passes, the slot can have "wrap" option
	if (DeviceID) {
		Device->CheckPage(CDevice::CHECK_EMIT);
		if (MemoryPointer) {
			if (LASTPASS == pass && !preserveDeviceMemory) *MemoryPointer = (char)byte;
			++MemoryPointer;
		}
	}
	++CurAddress;
	if (PseudoORG) ++adrdisp;
}

void EmitByte(int byte) {
	byte &= 0xFF;
	EB[nEB++] = byte;		// write also into listing
	EmitByteNoListing(byte);
}

void EmitWord(int word) {
	EmitByte(word % 256);
	EmitByte(word / 256);
}

void EmitBytes(const int* bytes) {
	if (*bytes == -1) {
		Error("Illegal instruction", line, IF_FIRST);
		SkipToEol(lp);
	}
	while (*bytes != -1) EmitByte(*bytes++);
}

void EmitWords(int* words) {
	while (*words != -1) EmitWord(*words++);
}

void EmitBlock(aint byte, aint len, bool preserveDeviceMemory, int emitMaxToListing) {
	if (len <= 0) {
		CurAddress = (CurAddress + len) & 0xFFFF;
		if (PseudoORG) adrdisp = (adrdisp + len) & 0xFFFF;
		if (DeviceID)	Device->CheckPage(CDevice::CHECK_NO_EMIT);
		else			CheckRamLimitExceeded();
		return;
	}
	while (len--) {
		int dVal = (preserveDeviceMemory && DeviceID && MemoryPointer) ? MemoryPointer[0] : byte;
		EmitByteNoListing(byte, preserveDeviceMemory);
		if (LASTPASS == pass && emitMaxToListing) {
			// put "..." marker into listing if some more bytes are emitted after last listed
			if ((0 == --emitMaxToListing) && len) EB[nEB++] = -2;
			else EB[nEB++] = dVal&0xFF;
		}
	}
}

char* GetPath(const char* fname, char** filenamebegin, bool systemPathsBeforeCurrent)
{
	char fullFilePath[MAX_PATH] = { 0 };
	CStringsList* dir = Options::IncludeDirsList;	// include-paths to search
	// search current directory first (unless "systemPathsBeforeCurrent")
	if (!systemPathsBeforeCurrent) {
		// if found, just skip the `while (dir)` loop
		if (SearchPath(CurrentDirectory, fname, nullptr, MAX_PATH, fullFilePath, filenamebegin)) dir = nullptr;
		else fullFilePath[0] = 0;	// clear fullFilePath every time when not found
	}
	while (dir) {
		if (SearchPath(dir->string, fname, nullptr, MAX_PATH, fullFilePath, filenamebegin)) break;
		fullFilePath[0] = 0;	// clear fullFilePath every time when not found
		dir = dir->next;
	}
	// if the file was not found in the list, and current directory was not searched yet
	if (!fullFilePath[0] && systemPathsBeforeCurrent) {
		//and the current directory was not searched yet, do it now, set empty string if nothing
		if (!SearchPath(CurrentDirectory, fname, NULL, MAX_PATH, fullFilePath, filenamebegin)) {
			fullFilePath[0] = 0;	// clear fullFilePath every time when not found
		}
	}
	if (!fullFilePath[0] && filenamebegin) {	// if still not found, reset also *filenamebegin
		*filenamebegin = fullFilePath;
	}
	// copy the result into new memory
	char* kip = STRDUP(fullFilePath);
	if (kip == NULL) ErrorOOM();
	// convert filenamebegin pointer into the copied string (from temporary buffer pointer)
	if (filenamebegin) *filenamebegin += (kip - fullFilePath);
	return kip;
}

// if offset is negative, it functions as "how many bytes from end of file"
// if length is negative, it functions as "how many bytes from end of file to not load"
void BinIncFile(char* fname, int offset, int length) {
	// open the desired file
	FILE* bif;
	char* fullFilePath = GetPath(fname);
	if (!FOPEN_ISOK(bif, fullFilePath, "rb")) Error("Error opening file", fname, FATAL);
	free(fullFilePath);

	// Get length of file
	int totlen = 0, advanceLength;
	if (fseek(bif, 0, SEEK_END) || (totlen = ftell(bif)) < 0) Error("telling file length", fname, FATAL);

	// process arguments (extra features like negative offset/length or INT_MAX length)
	// negative offset means "from the end of file"
	if (offset < 0) offset += totlen;
	// negative length means "except that many from end of file"
	if (length < 0) length += totlen - offset;
	// default length INT_MAX is "till the end of file"
	if (INT_MAX == length) length = totlen - offset;
	// verbose output of final values (before validation may terminate assembler)
	if (LASTPASS == pass && Options::OutputVerbosity <= OV_ALL) {
		char diagnosticTxt[MAX_PATH];
		SPRINTF4(diagnosticTxt, MAX_PATH, "include data: name=%s (%d bytes) Offset=%d  Len=%d", fname, totlen, offset, length);
		_CERR diagnosticTxt _ENDL;
	}
	// validate the resulting [offset, length]
	if (offset < 0 || length < 0 || totlen < offset + length) {
		Error("file too short", fname, FATAL);
	}
	if (0 == length) {
		Warning("include data: requested to include no data (length=0)");
		fclose(bif);
		return;
	}

	// Seek to the beginning of part to include
	if (fseek(bif, offset, SEEK_SET) || ftell(bif) != offset) {
		Error("seeking in file to offset", fname, FATAL);
	}

	if (pass != LASTPASS) {
		while (length) {
			advanceLength = length;		// maximum possible to advance in address space
			if (DeviceID) {				// particular device may adjust that to less
				Device->CheckPage(CDevice::CHECK_EMIT);
				if (MemoryPointer) {	// fill up current memory page if possible
					advanceLength = Page->RAM + Page->Size - MemoryPointer;
					if (length < advanceLength) advanceLength = length;
					MemoryPointer += advanceLength;		// also update it! Doh!
				}
			}
			length -= advanceLength;
			if (length <= 0 && 0 == advanceLength) Error("BinIncFile internal error", NULL, FATAL);
			if (PseudoORG) adrdisp = adrdisp + advanceLength;
			CurAddress = CurAddress + advanceLength;
		}
	} else {
		// Reading data from file
		char* data = new char[length + 1], * bp = data;
		if (NULL == data) ErrorOOM();
		size_t res = fread(bp, 1, length, bif);
		if (res != (size_t)length) Error("reading data from file failed", fname, FATAL);
		while (length--) EmitByteNoListing(*bp++);
		delete[] data;
	}
	fclose(bif);
}

static void OpenDefaultList(const char *fullpath);

static auto stdin_log_it = stdin_log.cbegin();

void OpenFile(const char* nfilename, bool systemPathsBeforeCurrent)
{
	const char* oFileNameFull = fileNameFull;
	TextFilePos oSourcePos = CurSourcePos;
	char* oCurrentDirectory, * fullpath, * listFullName = NULL;
	TCHAR* filenamebegin;

	if (++IncludeLevel > 20) {
		Error("Over 20 files nested", NULL, FATAL);
	}
	if (!*nfilename) {
		fullpath = STRDUP("console_input");
		filenamebegin = fullpath;
		FP_Input = stdin;
		stdin_log_it = stdin_log.cbegin();	// reset read iterator (for 2nd+ pass)
	} else {
		fullpath = GetPath(nfilename, &filenamebegin, systemPathsBeforeCurrent);

		if (!FOPEN_ISOK(FP_Input, fullpath, "rb")) {
			free(fullpath);
			Error("Error opening file", nfilename, FATAL);
		}
	}
	// archive the filename (for referencing it in SLD tracing data or listing/errors)
	auto ofnIt = std::find(openedFileNames.cbegin(), openedFileNames.cend(), fullpath);
	if (ofnIt == openedFileNames.cend()) {		// new filename, add it to archive
		openedFileNames.push_back(fullpath);
		ofnIt = --openedFileNames.cend();
	}
	fileNameFull = ofnIt->c_str();				// get const pointer into archive
	CurSourcePos.newFile(Options::IsShowFullPath ? fileNameFull : FilenameBasePos(fileNameFull));

	// open default listing file for each new source file (if default listing is ON)
	if (LASTPASS == pass && 0 == IncludeLevel && Options::IsDefaultListingName) {
		OpenDefaultList(fullpath);			// explicit listing file is already opened
	}
	// show in listing file which file was opened
	FILE* listFile = GetListingFile();
	if (LASTPASS == pass && listFile) {
		listFullName = STRDUP(fullpath);	// create copy of full filename for listing file
		fputs("# file opened: ", listFile);
		fputs(listFullName, listFile);
		fputs("\n", listFile);
	}

	oCurrentDirectory = CurrentDirectory;
	*filenamebegin = 0;
	CurrentDirectory = fullpath;

	rlpbuf = rlpbuf_end = rlbuf;
	colonSubline = false;
	blockComment = 0;

	ReadBufLine();

	if (stdin != FP_Input) fclose(FP_Input);
	else if (1 == pass) stdin_log.push_back(0);		// add extra zero terminator
	CurrentDirectory = oCurrentDirectory;

	// show in listing file which file was closed
	if (LASTPASS == pass && listFile) {
		fputs("# file closed: ", listFile);
		fputs(listFullName, listFile);
		fputs("\n", listFile);
		free(listFullName);

		// close listing file (if "default" listing filename is used)
		if (FP_ListingFile && 0 == IncludeLevel && Options::IsDefaultListingName) {
			if (Options::AddLabelListing) LabelTable.Dump();
			fclose(FP_ListingFile);
			FP_ListingFile = NULL;
		}
	}

	--IncludeLevel;

	// Free memory
	free(fullpath);

	if (CurSourcePos.line > maxlin) {
		maxlin = CurSourcePos.line;
	}
	fileNameFull = oFileNameFull;
	CurSourcePos = oSourcePos;
}

void IncludeFile(const char* nfilename, bool systemPathsBeforeCurrent)
{
	FILE* oFP_Input = FP_Input;
	FP_Input = 0;

	char* pbuf = rlpbuf, * pbuf_end = rlpbuf_end, * buf = STRDUP(rlbuf);
	if (buf == NULL) ErrorOOM();
	bool oColonSubline = colonSubline;
	if (blockComment) Error("Internal error 'block comment'", NULL, FATAL);	// comment can't INCLUDE

	OpenFile(nfilename, systemPathsBeforeCurrent);

	colonSubline = oColonSubline;
	rlpbuf = pbuf, rlpbuf_end = pbuf_end;
	STRCPY(rlbuf, 8192, buf);
	free(buf);

	FP_Input = oFP_Input;
}

typedef struct {
	char	name[12];
	size_t	length;
	byte	marker[16];
} BOMmarkerDef;

const BOMmarkerDef UtfBomMarkers[] = {
	{ { "UTF8" }, 3, { 0xEF, 0xBB, 0xBF } },
	{ { "UTF32BE" }, 4, { 0, 0, 0xFE, 0xFF } },
	{ { "UTF32LE" }, 4, { 0xFF, 0xFE, 0, 0 } },		// must be detected *BEFORE* UTF16LE
	{ { "UTF16BE" }, 2, { 0xFE, 0xFF } },
	{ { "UTF16LE" }, 2, { 0xFF, 0xFE } }
};

static bool ReadBufData() {
	// check here also if `line` buffer is not full
	if ((LINEMAX-2) <= (rlppos - line)) Error("Line too long", NULL, FATAL);
	// now check for read data
	if (rlpbuf < rlpbuf_end) return 1;		// some data still in buffer
	// check EOF on files in every pass, stdin only in first, following will starve the stdin_log
	if ((stdin != FP_Input || 1 == pass) && feof(FP_Input)) return 0;	// no more data in file
	// read next block of data
	rlpbuf = rlbuf;
	// handle STDIN file differently (pass1 = read it, pass2+ replay "log" variable)
	if (1 == pass || stdin != FP_Input) {	// ordinary file is re-read every pass normally
		rlpbuf_end = rlbuf + fread(rlbuf, 1, 4096, FP_Input);
		*rlpbuf_end = 0;					// add zero terminator after new block
	}
	if (stdin == FP_Input) {
		// store copy of stdin into stdin_log during pass 1
		if (1 == pass && rlpbuf < rlpbuf_end) {
			stdin_log.insert(stdin_log.end(), rlpbuf, rlpbuf_end);
		}
		// replay the log in 2nd+ pass
		if (1 < pass) {
			rlpbuf_end = rlpbuf;
			long toCopy = std::min(8000L, (long)std::distance(stdin_log_it, stdin_log.cend()));
			if (0 < toCopy) {
				memcpy(rlbuf, &(*stdin_log_it), toCopy);
				stdin_log_it += toCopy;
				rlpbuf_end += toCopy;
			}
			*rlpbuf_end = 0;				// add zero terminator after new block
		}
	}
	// check UTF BOM markers only at the beginning of the file (source line == 0)
	if (CurSourcePos.line) return (rlpbuf < rlpbuf_end);	// return true if some data were read
	//UTF BOM markers detector
	for (const auto & bomMarkerData : UtfBomMarkers) {
		if (rlpbuf_end < (rlpbuf + bomMarkerData.length)) continue;	// not enough bytes in buffer
		if (memcmp(rlpbuf, bomMarkerData.marker, bomMarkerData.length)) continue;	// marker not found
		if (&bomMarkerData != UtfBomMarkers) {	// UTF8 is first in the array, other markers show error
			Error("Invalid UTF encoding detected (only ASCII and UTF8 works)", bomMarkerData.name, FATAL);
		}
		rlpbuf += bomMarkerData.length;	// skip the UTF8 BOM marker
	}
	return (rlpbuf < rlpbuf_end);			// return true if some data were read
}

void ReadBufLine(bool Parse, bool SplitByColon) {
	// if everything else fails (no data, not running, etc), return empty line
	*line = 0;
	bool IsLabel = true;
	// try to read through the buffer and produce new line from it
	while (IsRunning && ReadBufData()) {
		// start of new line (or fake "line" by colon)
		rlppos = line;
		substitutedLine = line;		// also reset "substituted" line to the raw new one
		eolComment = NULL;
		if (colonSubline) {			// starting from colon (creating new fake "line")
			colonSubline = false;	// (can't happen inside block comment)
			*(rlppos++) = ' ';
			IsLabel = false;
		} else {					// starting real new line
			IsLabel = (0 == blockComment);
		}
		bool afterNonAlphaNum, afterNonAlphaNumNext = true;
		// copy data from read buffer into `line` buffer until EOL/colon is found
		while (
				ReadBufData() && '\n' != *rlpbuf && '\r' != *rlpbuf &&	// split by EOL
				// split by colon only on 2nd+ char && SplitByColon && not inside block comment
				(blockComment || !SplitByColon || rlppos == line || ':' != *rlpbuf)) {
			// copy the new character to new line
			*rlppos = *rlpbuf++;
			afterNonAlphaNum = afterNonAlphaNumNext;
			afterNonAlphaNumNext = !isalnum((byte)*rlppos);
			// Block comments logic first (anything serious may happen only "outside" of block comment
			if ('*' == *rlppos && ReadBufData() && '/' == *rlpbuf) {
				if (0 < blockComment) --blockComment;	// block comment ends here, -1 from nesting
				++rlppos;	*rlppos++ = *rlpbuf++;		// copy the second char too
				continue;
			}
			if ('/' == *rlppos && ReadBufData() && '*' == *rlpbuf) {
				++rlppos, ++blockComment;				// block comment starts here, nest +1 more
				*rlppos++ = *rlpbuf++;					// copy the second char too
				continue;
			}
			if (blockComment) {							// inside block comment just copy chars
				++rlppos;
				continue;
			}
			// check if still in label area, if yes, copy the finishing colon as char (don't split by it)
			if ((IsLabel = IsLabel && islabchar(*rlppos))) {
				++rlppos;					// label character
				if (ReadBufData() && ':' == *rlpbuf) {	// colon after label, add it
					*rlppos++ = *rlpbuf++;
					IsLabel = false;
				}
				continue;
			}
			// not in label any more, check for EOL comments ";" or "//"
			if ((';' == *rlppos) || ('/' == *rlppos && ReadBufData() && '/' == *rlpbuf)) {
				eolComment = rlppos;
				++rlppos;					// EOL comment ";"
				while (ReadBufData() && '\n' != *rlpbuf && '\r' != *rlpbuf) *rlppos++ = *rlpbuf++;
				continue;
			}
			// check for string literals - double/single quotes
			if (afterNonAlphaNum && ('"' == *rlppos || '\'' == *rlppos)) {
				const bool quotes = '"' == *rlppos;
				int escaped = 0;
				do {
					if (escaped) --escaped;
					++rlppos;				// previous char confirmed
					*rlppos = ReadBufData() ? *rlpbuf : 0;	// copy next char (if available)
					if (!*rlppos || '\r' == *rlppos || '\n' == *rlppos) *rlppos = 0;	// not valid
					else ++rlpbuf;			// buffer char read (accepted)
					if (quotes && !escaped && '\\' == *rlppos) escaped = 2;	// escape sequence detected
				} while (*rlppos && (escaped || (quotes ? '"' : '\'') != *rlppos));
				if (*rlppos) ++rlppos;		// there should be ending "/' in line buffer, confirm it
				continue;
			}
			// anything else just copy
			++rlppos;				// previous char confirmed
		} // while "some char in buffer, and it's not line delimiter"
		// line interrupted somehow, may be correctly finished, check + finalize line and process it
		*rlppos = 0;
		// skip <EOL> char sequence in read buffer
		if (ReadBufData() && ('\r' == *rlpbuf || '\n' == *rlpbuf)) {
			char CRLFtest = (*rlpbuf++) ^ ('\r'^'\n');	// flip CR->LF || LF->CR (and eats first)
			if (ReadBufData() && CRLFtest == *rlpbuf) ++rlpbuf;	// if CRLF/LFCR pair, eat also second
			// if this was very last <EOL> in file (on non-empty line), add one more fake empty line
			if (!ReadBufData() && *line) *rlpbuf_end++ = '\n';	// to make listing files "as before"
		} else {
			// advance over single colon if that was the reason to terminate line parsing
			colonSubline = SplitByColon && ReadBufData() && (':' == *rlpbuf) && ++rlpbuf;
		}
		// do +1 for very first colon-segment only (rest is +1 due to artificial space at beginning)
		size_t advanceColumns = colonSubline ? (0 == CurSourcePos.colEnd) + strlen(line) : 0;
		CurSourcePos.nextSegment(colonSubline, advanceColumns);
		// line is parsed and ready to be processed
		if (Parse) 	ParseLine();	// processed here in loop
		else 		return;			// processed externally
	} // while (IsRunning && ReadBufData())
}

static void OpenListImp(const char* listFilename) {
	// if STDERR is configured to contain listing, disable other listing files
	if (OV_LST == Options::OutputVerbosity) return;
	if (NULL == listFilename || !listFilename[0]) return;
	if (!FOPEN_ISOK(FP_ListingFile, listFilename, "w")) {
		Error("Error opening file", listFilename, FATAL);
	}
}

void OpenList() {
	// if STDERR is configured to contain listing, disable other listing files
	if (OV_LST == Options::OutputVerbosity) return;
	// check if listing file is already opened, or it is set to "default" file names
	if (Options::IsDefaultListingName || NULL != FP_ListingFile) return;
	// Only explicit listing files are opened here
	OpenListImp(Options::ListingFName);
}

static void OpenDefaultList(const char *fullpath) {
	// if STDERR is configured to contain listing, disable other listing files
	if (OV_LST == Options::OutputVerbosity) return;
	// check if listing file is already opened, or it is set to explicit file name
	if (!Options::IsDefaultListingName || NULL != FP_ListingFile) return;
	if (NULL == fullpath || !*fullpath) return;		// no filename provided
	// Create default listing name, and try to open it
	char tempListName[LINEMAX+10];		// make sure there is enough room for new extension
	char* extPos = FilenameExtPos(tempListName, fullpath, LINEMAX);	// find extension position
	STRCPY(extPos, 5, ".lst");			// overwrite it with ".lst"
	// list filename prepared, open it
	OpenListImp(tempListName);
}

void CloseDest() {
	// Flush buffer before any other operations
	WriteDest();
	// does main output file exist? (to close it)
	if (FP_Output == NULL) return;
	// pad to desired size (and check for exceed of it)
	if (size != -1L) {
		if (destlen > size) {
			ErrorInt("File exceeds 'size' by", destlen - size);
		}
		memset(WriteBuffer, 0, DESTBUFLEN);
		while (destlen < size) {
			WBLength = std::min(aint(DESTBUFLEN), size-destlen);
			WriteDest();
		}
		size = -1L;
	}
	fclose(FP_Output);
	FP_Output = NULL;
}

void SeekDest(long offset, int method) {
	WriteDest();
	if (FP_Output != NULL && fseek(FP_Output, offset, method)) {
		Error("File seek error (FPOS)", NULL, FATAL);
	}
}

void NewDest(char* newfilename, int mode) {
	// close previous output file
	CloseDest();

	// and open new file (keep previous/default name, if no explicit was provided)
	if (newfilename && *newfilename) STRCPY(Options::DestinationFName, LINEMAX, newfilename);
	OpenDest(mode);
}

void OpenDest(int mode) {
	destlen = 0;
	if (mode != OUTPUT_TRUNCATE && !FileExists(Options::DestinationFName)) {
		mode = OUTPUT_TRUNCATE;
	}
	if (!Options::NoDestinationFile && !FOPEN_ISOK(FP_Output, Options::DestinationFName, mode == OUTPUT_TRUNCATE ? "wb" : "r+b")) {
		Error("Error opening file", Options::DestinationFName, FATAL);
	}
	Options::NoDestinationFile = false;
	if (NULL == FP_RAW && '-' == Options::RAWFName[0] && 0 == Options::RAWFName[1]) {
		FP_RAW = stdout;
		fflush(stdout);
		switchStdOutIntoBinaryMode();
	}
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

	if (fwrite(tap_data, 1, 3, FP_tapout) != 3) {
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
	if (*ModuleName) {
		Warning("ENDMODULE missing for module", ModuleName, W_ALL);
	}

	CloseDest();
	CloseTapFile();
	if (FP_ExportFile != NULL) {
		fclose(FP_ExportFile);
		FP_ExportFile = NULL;
	}
	if (FP_RAW != NULL) {
		if (stdout != FP_RAW) fclose(FP_RAW);
		FP_RAW = NULL;
	}
	if (FP_ListingFile != NULL) {
		fclose(FP_ListingFile);
		FP_ListingFile = NULL;
	}
	CloseSld();
}

int SaveRAM(FILE* ff, int start, int length) {
	//unsigned int addadr = 0,save = 0;
	aint save = 0;
	if (!DeviceID) return 0;		// unreachable currently
	if (length + start > 0x10000) {
		length = -1;
	}
	if (length <= 0) {
		length = 0x10000 - start;
	}

	CDeviceSlot* S;
	for (int i=0;i<Device->SlotsCount;i++) {
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
			if (length <= 0) {
				return 1;
			}
		}
	}
	return 0;		// unreachable (with current devices)
}

unsigned int MemGetWord(unsigned int address) {
	return MemGetByte(address) + (MemGetByte(address+1)<<8);
}

unsigned char MemGetByte(unsigned int address) {
	if (!DeviceID || pass != LASTPASS) {
		return 0;
	}

	CDeviceSlot* S;
	for (int i=0;i<Device->SlotsCount;i++) {
		S = Device->GetSlot(i);
		if (address >= (unsigned int)S->Address  && address < (unsigned int)S->Address + (unsigned int)S->Size) {
			return S->Page->RAM[address - S->Address];
		}
	}

	ErrorInt("MemGetByte: Error reading address", address);
	return 0;
}


int SaveBinary(char* fname, int start, int length) {
	FILE* ff;
	if (!FOPEN_ISOK(ff, fname, "wb")) {
		Error("Error opening file", fname, FATAL);
	}
	int result = SaveRAM(ff, start, length);
	fclose(ff);
	return result;
}


// all arguments must be sanitized by caller (this just writes data block into opened file)
bool SaveDeviceMemory(FILE* file, const size_t start, const size_t length) {
	return (length == fwrite(Device->Memory + start, 1, length, file));
}


// start and length must be sanitized by caller
bool SaveDeviceMemory(const char* fname, const size_t start, const size_t length) {
	FILE* ff;
	if (!FOPEN_ISOK(ff, fname, "wb")) Error("Error opening file", fname, FATAL);
	bool res = SaveDeviceMemory(ff, start, length);
	fclose(ff);
	return res;
}


int SaveHobeta(char* fname, char* fhobname, int start, int length) {
	unsigned char header[0x11];
	int i;

	if (length + start > 0x10000) {
		length = -1;
	}
	if (length <= 0) {
		length = 0x10000 - start;
	}

	memset(header,' ',9);
	i = strlen(fhobname);
	if (i > 1)
	{
		char *ext = strrchr(fhobname, '.');
		if (ext && ext[1])
		{
			header[8] = ext[1];
			i = ext-fhobname;
		}
	}
	memcpy(header, fhobname, std::min(i,8));

	if (header[8] == 'B')	{
		header[0x09] = (unsigned char)(length & 0xff);
		header[0x0a] = (unsigned char)(length >> 8);
	} else	{
		header[0x09] = (unsigned char)(start & 0xff);
		header[0x0a] = (unsigned char)(start >> 8);
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

	int result = (17 == fwrite(header, 1, 17, ff)) && SaveRAM(ff, start, length);
	fclose(ff);
	return result;
}

EReturn ReadFile() {
	while (ReadLine()) {
		const bool isInsideDupCollectingLines = !RepeatStack.empty() && !RepeatStack.top().IsInWork;
		if (!isInsideDupCollectingLines) {
			char* p = line;
			SkipBlanks(p);
			if ('.' == *p) ++p;
			if (cmphstr(p, "endif")) {
				lp = ReplaceDefine(p);
				substitutedLine = line;		// override substituted listing for ENDIF
				return ENDIF;
			} else if (cmphstr(p, "else")) {
				lp = ReplaceDefine(p);
				substitutedLine = line;		// override substituted listing for ELSE
				ListFile();
				return ELSE;
			}
		}
		ParseLineSafe();
	}
	return END;
}


EReturn SkipFile() {
	int iflevel = 0;
	while (ReadLine()) {
		char* p = line;
		SkipBlanks(p);
		if ('.' == *p) ++p;
		if (cmphstr(p, "if") || cmphstr(p, "ifn") || cmphstr(p, "ifused") ||
			cmphstr(p, "ifnused") || cmphstr(p, "ifdef") || cmphstr(p, "ifndef")) {
			++iflevel;
		} else if (cmphstr(p, "endif")) {
			if (iflevel) {
				--iflevel;
			} else {
				lp = ReplaceDefine(p);
				substitutedLine = line;		// override substituted listing for ENDIF
				return ENDIF;
			}
		} else if (cmphstr(p, "else")) {
			if (!iflevel) {
				lp = ReplaceDefine(p);
				substitutedLine = line;		// override substituted listing for ELSE
				ListFile();
				return ELSE;
			}
		}
		ListFile(true);
	}
	return END;
}

int ReadLineNoMacro(bool SplitByColon) {
	if (!IsRunning || !ReadBufData()) return 0;
	ReadBufLine(false, SplitByColon);
	return 1;
}

int ReadLine(bool SplitByColon) {
	DefinitionPos = TextFilePos();
	if (IsRunning && lijst) {		// read MACRO lines, if macro is being emitted
		if (!lijstp) return 0;
		DefinitionPos = lijstp->definition;
		STRCPY(line, LINEMAX, lijstp->string);
		substitutedLine = line;		// reset substituted listing
		eolComment = NULL;			// reset end of line comment
		lijstp = lijstp->next;
		return 1;
	}
	return ReadLineNoMacro(SplitByColon);
}

int ReadFileToCStringsList(CStringsList*& f, const char* end) {
	// f itself should be already NULL, not resetting it here
	CStringsList** s = &f;
	while (ReadLineNoMacro()) {
		char* p = line;
		SkipBlanks(p);
		if ('.' == *p) ++p;
		if (cmphstr(p, end)) {		// finished, read rest after end marker into line buffers
			lp = ReplaceDefine(p);
			return 1;
		}
		*s = new CStringsList(line);
		s = &((*s)->next);
		ListFile(true);
	}
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
	STRCAT(ErrorLine, LINEMAX2-1, ": EQU ");
	STRCAT(ErrorLine, LINEMAX2-1, "0x");
	PrintHex32(l, v); *l = 0;
	STRCAT(ErrorLine, LINEMAX2-1, lnrs);
	STRCAT(ErrorLine, LINEMAX2-1, "\n");
	fputs(ErrorLine, FP_ExportFile);
}

/////// source-level-debugging support by Ckirby

static FILE* FP_SourceLevelDebugging = NULL;
static char sldMessage[LINEMAX];
static const char* WriteToSld_noSymbol = "";
static char sldMessage_sourcePos[80];
static char sldMessage_definitionPos[80];
static const char* sldMessage_posFormat = "%d:%d:%d";	// at +3 is "%d:%d" and at +6 is "%d"

static void WriteToSldFile_TextFilePos(char* buffer, const TextFilePos & pos) {
	int offsetFormat = !pos.colBegin ? 6 : !pos.colEnd ? 3 : 0;
	snprintf(buffer, 79, sldMessage_posFormat + offsetFormat, pos.line, pos.colBegin, pos.colEnd);
}

static void OpenSldImp(const char* sldFilename) {
	if (nullptr == sldFilename || !sldFilename[0]) return;
	if (!FOPEN_ISOK(FP_SourceLevelDebugging, sldFilename, "w")) {
		Error("Error opening file", sldFilename, FATAL);
	}
	fputs("|SLD.data.version|0\n", FP_SourceLevelDebugging);
}

// will write directly into Options::SourceLevelDebugFName array
static void OpenSld_buildDefaultNameIfNeeded() {
	// check if SLD file name is already explicitly defined, or default is wanted
	if (Options::SourceLevelDebugFName[0] || !Options::IsDefaultSldName) return;
	// name is still empty, and default is wanted, create one (start with "out" or first source name)
	char* extPos = FilenameExtPos(
		Options::SourceLevelDebugFName, Options::SourceStdIn ? "out" : SourceFNames[0], LINEMAX-10);
	STRCPY(extPos, 10, ".sld.txt");		// overwrite extension
}

// returns true only in the LASTPASS and only when "sld" file was specified by user
// and only when assembling is in "virtual DEVICE" mode (for "none" device no tracing is emitted)
bool IsSldExportActive() {
	return (nullptr != FP_SourceLevelDebugging && DeviceID);
}

void OpenSld() {
	// check if source-level-debug file is already opened
	if (nullptr != FP_SourceLevelDebugging) return;
	// build default filename if not explicitly provided, and default was requested
	OpenSld_buildDefaultNameIfNeeded();
	// try to open it if not opened yet
	OpenSldImp(Options::SourceLevelDebugFName);
}

void CloseSld() {
	if (!FP_SourceLevelDebugging) return;
	fclose(FP_SourceLevelDebugging);
	FP_SourceLevelDebugging = nullptr;
}

void WriteToSldFile(int pageNum, int value, char type, const char* symbol) {
	// SLD line format:
	// <file name>|<source line>|<definition file>|<definition line>|<page number>|<value>|<type>|<data>\n
	//
	// * string <file name> can't be empty (empty is for specific "control lines" with different format)
	//
	// * unsigned <source line> when <file name> is not empty, line number (in human way starting at 1)
	// The actual format is "%d[:%d[:%d]]", first number is always line. If second number is present,
	// that's the start column (in bytes), and if also third number is present, that's end column.
	//
	// * string <definition file> where the <definition line> was defined, if empty, it's equal to <file name>
	//
	// * unsigned <definition line> explicit zero value in regular source, but inside macros
	// the <source line> keeps pointing at line emitting the macro, while this value points
	// to source with actual definitions of instructions/etc (nested macro in macro <source line>
	// still points at the top level source which initiated it).
	// The format is again "%d[:%d[:%d]]" same as <source line>, optionally including the columns data.
	//
	// * int <value> is not truncated to page range, but full 16b Z80 address or even 32b value (equ)
	//
	// * string <data> content depends on char <type>:
	// 'T' = instruction Trace, empty data
	// 'D' = EQU symbol, <data> is the symbol name ("label")
	// 'F' = function label, <data> is the symbol name
	// 'Z' = device (memory model) changed, <data> has special custom formatting
	//
	// 'Z' device <data> format:
	// pages.size:<page size>,pages.count:<page count>,slots.count:<slots count>[,slots.adr:<slot0 adr>,...,<slotLast adr>]
	// unsigned <page size> is also any-slot size in current version.
	// unsigned <page count> and <slots count> define how many pages/slots there are
	// uint16_t <slotX adr> is starting address of slot memory region in Z80 16b addressing
	//
	// specific lines (<file name> string was empty):
	// |SLD.data.version|<version number>
	// <version number> is SLD file format version, currently should be 0
	// ||<anything till EOL>
	// comment line, not to be parsed
	if (nullptr == FP_SourceLevelDebugging || !type) return;
	if (nullptr == symbol) symbol = WriteToSld_noSymbol;
	const char* macroFN = DefinitionPos.filename && strcmp(DefinitionPos.filename, CurSourcePos.filename) ?
							DefinitionPos.filename : "";
	WriteToSldFile_TextFilePos(sldMessage_sourcePos, CurSourcePos);
	WriteToSldFile_TextFilePos(sldMessage_definitionPos, DefinitionPos);
	snprintf(sldMessage, LINEMAX, "%s|%s|%s|%s|%d|%d|%c|%s\n",
				CurSourcePos.filename, sldMessage_sourcePos, macroFN, sldMessage_definitionPos,
				pageNum, value, type, symbol);
	fputs(sldMessage, FP_SourceLevelDebugging);
}

//eof sjio.cpp
