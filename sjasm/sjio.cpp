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

int ListAddress;
std::vector<const char*> archivedFileNames;	// archive of all files opened (also includes!) (fullname!)

static constexpr int LIST_EMIT_BYTES_BUFFER_SIZE = 1024 * 64;
static constexpr int DESTBUFLEN = 8192;

// ReadLine buffer and variables around
static char rlbuf[LINEMAX2 * 2];
static char * rlpbuf, * rlpbuf_end, * rlppos;
static bool colonSubline;
static int blockComment;

static int ListEmittedBytes[LIST_EMIT_BYTES_BUFFER_SIZE], nListBytes = 0;
static char WriteBuffer[DESTBUFLEN];
static int tape_seek = 0;
static int tape_length = 0;
static int tape_parity = 0x55;
static FILE* FP_tapout = NULL;
static FILE* FP_Input = NULL, * FP_Output = NULL, * FP_RAW = NULL;
static FILE* FP_ListingFile = NULL,* FP_ExportFile = NULL;
static aint WBLength = 0;

static void CloseBreakpointsFile();

// returns permanent C-string pointer to the fullpathname (if new, it is added to archive)
const char* ArchiveFilename(const char* fullpathname) {
	for (auto fname : archivedFileNames) {		// search whole archive for identical full name
		if (!strcmp(fname, fullpathname)) return fname;
	}
	const char* newName = STRDUP(fullpathname);
	archivedFileNames.push_back(newName);
	return newName;
}

// does release all archived filenames, making all pointers (and archive itself) invalid
void ReleaseArchivedFilenames() {
	for (auto filename : archivedFileNames) free((void*)filename);
	archivedFileNames.clear();
}

static const char* FilenameBasePos(const char* fullname) {
	const char* const filenameEnd = fullname + strlen(fullname);
	const char* baseName = filenameEnd;
	while (fullname < baseName && '/' != baseName[-1] && '\\' != baseName[-1]) --baseName;
	return baseName;
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

void ConstructDefaultFilename(std::filesystem::path & dest, const char* ext, bool checkIfDestIsEmpty) {
	if (nullptr == ext || !ext[0]) exit(1);	// invalid arguments
	// if the destination buffer has already some content and check is requested, exit
	if (checkIfDestIsEmpty && !dest.empty()) return;
	// construct the new default name - search for explicit name in sourcefiles
	dest = "asm";		// use "asm" base if no explicit filename available
	for (const SSource & src : sourceFiles) {
		if (!src.fname[0]) continue;
		dest = src.fname;
		break;
	}
	dest.replace_extension(ext);
}

void CheckRamLimitExceeded() {
	if (Options::IsLongPtr) return;		// in "longptr" mode with no device keep the address as is
	static bool notWarnedCurAdr = true;
	static bool notWarnedDisp = true;
	char buf[64];
	if (CurAddress >= 0x10000) {
		if (LASTPASS == pass && notWarnedCurAdr) {
			SPRINTF2(buf, 64, "RAM limit exceeded 0x%X by %s",
					 (unsigned int)CurAddress, DISP_NONE != PseudoORG ? "DISP":"ORG");
			Warning(buf);
			notWarnedCurAdr = false;
		}
		if (DISP_NONE != PseudoORG) CurAddress &= 0xFFFF;	// fake DISP address gets auto-wrapped FFFF->0
	} else notWarnedCurAdr = true;
	if (DISP_NONE != PseudoORG && adrdisp >= 0x10000) {
		if (LASTPASS == pass && notWarnedDisp) {
			SPRINTF1(buf, 64, "RAM limit exceeded 0x%X by ORG", (unsigned int)adrdisp);
			Warning(buf);
			notWarnedDisp = false;
		}
	} else notWarnedDisp = true;
}

void resolveRelocationAndSmartSmc(const aint immediateOffset, Relocation::EType minType) {
	// call relocation data generator to do its own errands
	Relocation::resolveRelocationAffected(immediateOffset, minType);
	// check smart-SMC functionality, if there is unresolved record to be set up
	if (INT_MAX == immediateOffset || sourcePosStack.empty() || 0 == smartSmcIndex) return;
	if (smartSmcLines.size() < smartSmcIndex) return;
	auto & smartSmc = smartSmcLines.at(smartSmcIndex - 1);
	if (~0U != smartSmc.colBegin || smartSmc != sourcePosStack.back()) return;
	if (1 < sourcePosStack.back().colBegin) return;		// only first segment belongs to SMC label
	// record does match current line, resolve the smart offset
	smartSmc.colBegin = immediateOffset;
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
	uint32_t currentLine = sourcePosStack.at(IncludeLevel).line;
	aint linenumber = currentLine % 10000;
	if (5 <= linewidth) {		// five-digit number, calculate the leading "digit"
		linewidth = 5;
		digit = currentLine / 10000 + '0';
		if (digit > '~') digit = '~';
		if (currentLine >= 10000) linenumber += 10000;
	}
	memset(buffer, ' ', 24);
	if (listmacro) buffer[23] = '>';
	if (Options::LST_T_MC_ONLY == Options::syx.ListingType) buffer[23] = '{';
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

static aint lastListedLine = -1;

void ListFile(bool showAsSkipped) {
	if (LASTPASS != pass || NULL == GetListingFile() || donotlist || Options::syx.IsListingSuspended) {
		donotlist = nListBytes = 0;
		return;
	}
	if (showAsSkipped && Options::LST_T_ACTIVE == Options::syx.ListingType) {
		assert(nListBytes <= 0);	// inactive line should not produce any machine code?!
		nListBytes = 0;
		return;		// filter out all "inactive" lines
	}
	if (Options::LST_T_MC_ONLY == Options::syx.ListingType && nListBytes <= 0) {
		return;		// filter out all lines without machine-code bytes
	}
	int pos = 0;
	do {
		if (showAsSkipped) substitutedLine = line;	// override substituted lines in skipped mode
		PrepareListLine(pline, ListAddress);
		const bool hideSource = !showAsSkipped && (lastListedLine == CompiledCurrentLine);
		if (hideSource) pline[24] = 0;				// hide *same* source line on sub-sequent list-lines
		lastListedLine = CompiledCurrentLine;		// remember this line as listed
		char* pp = pline + 10;
		int BtoList = (nListBytes < 4) ? nListBytes : 4;
		for (int i = 0; i < BtoList; ++i) {
			if (-2 == ListEmittedBytes[i + pos]) pp += sprintf(pp, "...");
			else pp += sprintf(pp, " %02X", ListEmittedBytes[i + pos]);
		}
		*pp = ' ';
		if (showAsSkipped) pline[11] = '~';
		ListFileStringRtrim();
		fputs(pline, GetListingFile());
		nListBytes -= BtoList;
		ListAddress += BtoList;
		pos += BtoList;
	} while (0 < nListBytes);
	nListBytes = 0;
	ListAddress = CurAddress;			// move ListAddress also beyond unlisted but emitted bytes
}

void ListSilentOrExternalEmits() {
	// catch silent/external emits like "sj.add_byte(0x123)" from Lua script
	if (0 == nListBytes) return;		// no silent/external emit happened
	++CompiledCurrentLine;
	char silentOrExternalBytes[] = "; these bytes were emitted silently/externally (lua script?)";
	substitutedLine = silentOrExternalBytes;
	eolComment = nullptr;
	ListFile();
	substitutedLine = line;
}

static bool someByteEmitted = false;

bool DidEmitByte() {	// returns true if some byte was emitted since last call to this function
	bool didEmit = someByteEmitted;		// value to return
	someByteEmitted = false;			// reset the flag
	return didEmit;
}

static void EmitByteNoListing(int byte, bool preserveDeviceMemory = false) {
	someByteEmitted = true;
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
	} else {
		CheckRamLimitExceeded();
	}
	++CurAddress;
	if (DISP_NONE != PseudoORG) ++adrdisp;
}

static bool PageDiffersWarningShown = false;

void EmitByte(int byte, bool isInstructionStart) {
	if (isInstructionStart) {
		// SLD (Source Level Debugging) tracing-data logging
		if (IsSldExportActive()) {
			int pageNum = Page->Number;
			if (DISP_NONE != PseudoORG) {
				int mappingPageNum = Device->GetPageOfA16(CurAddress);
				if (LABEL_PAGE_UNDEFINED == dispPageNum) {	// special DISP page is not set, use mapped
					pageNum = mappingPageNum;
				} else {
					pageNum = dispPageNum;					// special DISP page is set, use it instead
					if (pageNum != mappingPageNum && !PageDiffersWarningShown) {
						WarningById(W_DISP_MEM_PAGE);
						PageDiffersWarningShown = true;		// show warning about different mapping only once
					}
				}
			}
			WriteToSldFile(pageNum, CurAddress);
		}
	}
	byte &= 0xFF;
	if (nListBytes < LIST_EMIT_BYTES_BUFFER_SIZE-1) {
		ListEmittedBytes[nListBytes++] = byte;		// write also into listing
	} else {
		if (nListBytes < LIST_EMIT_BYTES_BUFFER_SIZE) {
			// too many bytes, show it in listing as "..."
			ListEmittedBytes[nListBytes++] = -2;
		}
	}
	EmitByteNoListing(byte);
}

void EmitWord(int word, bool isInstructionStart) {
	EmitByte(word % 256, isInstructionStart);
	EmitByte(word / 256, false);
}

void EmitBytes(const int* bytes, bool isInstructionStart) {
	if (BYTES_END_MARKER == *bytes) {
		Error("Illegal instruction", line, IF_FIRST);
		SkipToEol(lp);
	}
	while (BYTES_END_MARKER != *bytes) {
		EmitByte(*bytes++, isInstructionStart);
		isInstructionStart = (INSTRUCTION_START_MARKER == *bytes);	// only true for first byte, or when marker
		if (isInstructionStart) ++bytes;
	}
}

void EmitWords(const int* words, bool isInstructionStart) {
	while (BYTES_END_MARKER != *words) {
		EmitWord(*words++, isInstructionStart);
		isInstructionStart = false;		// only true for first word
	}
}

void EmitBlock(aint byte, aint len, bool preserveDeviceMemory, int emitMaxToListing) {
	if (len <= 0) {
		const aint adrMask = Options::IsLongPtr ? ~0 : 0xFFFF;
		CurAddress = (CurAddress + len) & adrMask;
		if (DISP_NONE != PseudoORG) adrdisp = (adrdisp + len) & adrMask;
		if (DeviceID)	Device->CheckPage(CDevice::CHECK_NO_EMIT);
		else			CheckRamLimitExceeded();
		return;
	}
	if (LIST_EMIT_BYTES_BUFFER_SIZE <= nListBytes + emitMaxToListing) {	// clamp emit to list buffer
		emitMaxToListing = LIST_EMIT_BYTES_BUFFER_SIZE - nListBytes;
	}
	while (len--) {
		int dVal = (preserveDeviceMemory && DeviceID && MemoryPointer) ? MemoryPointer[0] : byte;
		EmitByteNoListing(byte, preserveDeviceMemory);
		if (LASTPASS == pass && emitMaxToListing) {
			// put "..." marker into listing if some more bytes are emitted after last listed
			if ((0 == --emitMaxToListing) && len) ListEmittedBytes[nListBytes++] = -2;
			else ListEmittedBytes[nListBytes++] = dVal&0xFF;
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
		if (SJ_SearchPath(CurrentDirectory, fname, nullptr, MAX_PATH, fullFilePath, filenamebegin)) dir = nullptr;
		else fullFilePath[0] = 0;	// clear fullFilePath every time when not found
	}
	while (dir) {
		if (SJ_SearchPath(dir->string, fname, nullptr, MAX_PATH, fullFilePath, filenamebegin)) break;
		fullFilePath[0] = 0;	// clear fullFilePath every time when not found
		dir = dir->next;
	}
	// if the file was not found in the list, and current directory was not searched yet
	if (!fullFilePath[0] && systemPathsBeforeCurrent) {
		//and the current directory was not searched yet, do it now, set empty string if nothing
		if (!SJ_SearchPath(CurrentDirectory, fname, NULL, MAX_PATH, fullFilePath, filenamebegin)) {
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
void BinIncFile(const char* fname, aint offset, aint length, const bool systemPathsFirst) {
	// open the desired file
	FILE* bif;
	char* fullFilePath = GetPath(fname, nullptr, systemPathsFirst);
	if (!FOPEN_ISOK(bif, fullFilePath, "rb")) Error("opening file", fname);
	free(fullFilePath);

	// Get length of file
	int totlen = 0, advanceLength;
	if (bif && (fseek(bif, 0, SEEK_END) || (totlen = ftell(bif)) < 0)) Error("telling file length", fname, FATAL);

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
		Error("file too short", fname);
		offset = std::clamp(offset, 0, totlen);
		length = std::clamp(length, 0, totlen - offset);
		assert((0 <= offset) && (offset + length <= totlen));
	}
	if (0 == length) {
		Warning("include data: requested to include no data (length=0)");
		if (bif) fclose(bif);
		return;
	}
	assert(nullptr != bif);				// otherwise it was handled by 0 == length case above

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
			if (DISP_NONE != PseudoORG) adrdisp = adrdisp + advanceLength;
			CurAddress = CurAddress + advanceLength;
		}
	} else {
		// Seek to the beginning of part to include
		if (fseek(bif, offset, SEEK_SET) || ftell(bif) != offset) {
			Error("seeking in file to offset", fname, FATAL);
		}

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

static stdin_log_t::const_iterator stdin_read_it;
static stdin_log_t* stdin_log = nullptr;

void OpenFile(const char* nfilename, bool systemPathsBeforeCurrent, stdin_log_t* fStdinLog)
{
	if (++IncludeLevel > 20) {
		Error("Over 20 files nested", NULL, ALL);
		--IncludeLevel;
		return;
	}
	char* fullpath, * filenamebegin;
	if (!*nfilename && fStdinLog) {
		fullpath = STRDUP("<stdin>");
		filenamebegin = fullpath;
		FP_Input = stdin;
		stdin_log = fStdinLog;
		stdin_read_it = stdin_log->cbegin();	// reset read iterator (for 2nd+ pass)
	} else {
		fullpath = GetPath(nfilename, &filenamebegin, systemPathsBeforeCurrent);

		if (!FOPEN_ISOK(FP_Input, fullpath, "rb")) {
			free(fullpath);
			Error("opening file", nfilename, ALL);
			--IncludeLevel;
			return;
		}
	}

	const char* oFileNameFull = fileNameFull, * oCurrentDirectory = CurrentDirectory;

	// archive the filename (for referencing it in SLD tracing data or listing/errors)
	fileNameFull = ArchiveFilename(fullpath);	// get const pointer into archive
	sourcePosStack.emplace_back(Options::IsShowFullPath ? fileNameFull : FilenameBasePos(fileNameFull));

	// refresh pre-defined values related to file/include
	DefineTable.Replace("__INCLUDE_LEVEL__", IncludeLevel);
	DefineTable.Replace("__FILE__", fileNameFull);
	if (0 == IncludeLevel) DefineTable.Replace("__BASE_FILE__", fileNameFull);

	// open default listing file for each new source file (if default listing is ON)
	if (LASTPASS == pass && 0 == IncludeLevel && Options::IsDefaultListingName) {
		OpenDefaultList(fileNameFull);			// explicit listing file is already opened
	}
	// show in listing file which file was opened
	FILE* listFile = GetListingFile();
	if (LASTPASS == pass && listFile) {
		fputs("# file opened: ", listFile);
		fputs(fileNameFull, listFile);
		fputs("\n", listFile);
	}

	*filenamebegin = 0;					// shorten fullpath to only-path string
	CurrentDirectory = fullpath;		// and use it as CurrentDirectory

	rlpbuf = rlpbuf_end = rlbuf;
	colonSubline = false;
	blockComment = 0;

	ReadBufLine();

	if (stdin != FP_Input) fclose(FP_Input);
	else {
		if (1 == pass) {
			stdin_log->push_back(0);	// add extra zero terminator
			clearerr(stdin);			// reset EOF on the stdin for another round of input
		}
	}
	CurrentDirectory = oCurrentDirectory;
	free(fullpath);						// was used by CurrentDirectory till now
	fullpath = nullptr;

	// show in listing file which file was closed
	if (LASTPASS == pass && listFile) {
		fputs("# file closed: ", listFile);
		fputs(fileNameFull, listFile);
		fputs("\n", listFile);

		// close listing file (if "default" listing filename is used)
		if (FP_ListingFile && 0 == IncludeLevel && Options::IsDefaultListingName) {
			if (Options::AddLabelListing) LabelTable.Dump();
			fclose(FP_ListingFile);
			FP_ListingFile = NULL;
		}
	}

	--IncludeLevel;

	maxlin = std::max(maxlin, sourcePosStack.back().line);
	sourcePosStack.pop_back();
	fileNameFull = oFileNameFull;

	// refresh pre-defined values related to file/include
	DefineTable.Replace("__INCLUDE_LEVEL__", IncludeLevel);
	DefineTable.Replace("__FILE__", fileNameFull ? fileNameFull : "<none>");
	if (-1 == IncludeLevel) DefineTable.Replace("__BASE_FILE__", "<none>");
}

void IncludeFile(const char* nfilename, bool systemPathsBeforeCurrent)
{
	auto oStdin_log = stdin_log;
	auto oStdin_read_it = stdin_read_it;
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
	stdin_log = oStdin_log;
	stdin_read_it = oStdin_read_it;
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
			stdin_log->insert(stdin_log->end(), rlpbuf, rlpbuf_end);
		}
		// replay the log in 2nd+ pass
		if (1 < pass) {
			rlpbuf_end = rlpbuf;
			long toCopy = std::min(8000L, (long)std::distance(stdin_read_it, stdin_log->cend()));
			if (0 < toCopy) {
				memcpy(rlbuf, &(*stdin_read_it), toCopy);
				stdin_read_it += toCopy;
				rlpbuf_end += toCopy;
			}
			*rlpbuf_end = 0;				// add zero terminator after new block
		}
	}
	// check UTF BOM markers only at the beginning of the file (source line == 0)
	assert(!sourcePosStack.empty());
	if (sourcePosStack.back().line) {
		return (rlpbuf < rlpbuf_end);		// return true if some data were read
	}
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
			// handle EOL escaping, limited implementation, usage not recommended
			if ('\\' == *rlppos && ReadBufData() && ('\r' == *rlpbuf || '\n' == *rlpbuf))  {
				char CRLFtest = (*rlpbuf++) ^ ('\r'^'\n');	// flip CR->LF || LF->CR (and eats first)
				if (ReadBufData() && CRLFtest == *rlpbuf) ++rlpbuf;	// if CRLF/LFCR pair, eat also second
				sourcePosStack.back().nextSegment();	// mark last line in errors/etc
				continue;								// continue with chars from next line
			}
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
			if ((IsLabel = (IsLabel && islabchar(*rlppos)))) {
				++rlppos;					// label character
				//SMC offset handling
				if (ReadBufData() && '+' == *rlpbuf) {	// '+' after label, add it as SMC_offset syntax
					IsLabel = false;
					*rlppos++ = *rlpbuf++;
					if (ReadBufData() && (isdigit(byte(*rlpbuf)) || '*' == *rlpbuf)) *rlppos++ = *rlpbuf++;
				}
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
		assert(!sourcePosStack.empty());
		size_t advanceColumns = colonSubline ? (0 == sourcePosStack.back().colEnd) + strlen(line) : 0;
		sourcePosStack.back().nextSegment(colonSubline, advanceColumns);
		// line is parsed and ready to be processed
		if (Parse) 	ParseLine();	// processed here in loop
		else 		return;			// processed externally
	} // while (IsRunning && ReadBufData())
}

static void OpenListImp(const std::filesystem::path & listFilename) {
	// if STDERR is configured to contain listing, disable other listing files
	if (OV_LST == Options::OutputVerbosity) return;
	if (listFilename.empty()) return;
	if (!FOPEN_ISOK(FP_ListingFile, listFilename, "w")) {
		Error("opening file for write", listFilename.string().c_str(), FATAL);
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

void NewDest(const char* newfilename, int mode) {
	// close previous output file
	CloseDest();

	// and open new file (keep previous/default name, if no explicit was provided)
	if (newfilename && *newfilename) Options::DestinationFName = newfilename;
	OpenDest(mode);
}

void OpenDest(int mode) {
	destlen = 0;
	if (mode != OUTPUT_TRUNCATE && !FileExists(Options::DestinationFName)) {
		mode = OUTPUT_TRUNCATE;
	}
	if (!Options::NoDestinationFile && !FOPEN_ISOK(FP_Output, Options::DestinationFName, mode == OUTPUT_TRUNCATE ? "wb" : "r+b")) {
		Error("opening file for write", Options::DestinationFName.string().c_str(), FATAL);
	}
	Options::NoDestinationFile = false;
	if (NULL == FP_RAW && "-" == Options::RAWFName) {
		FP_RAW = stdout;
		fflush(stdout);
		switchStdOutIntoBinaryMode();
	}
	if (FP_RAW == NULL && Options::RAWFName.has_filename() && !FOPEN_ISOK(FP_RAW, Options::RAWFName, "wb")) {
		Error("opening file for write", Options::RAWFName.string().c_str());
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

void OpenTapFile(const char * tapename, int flagbyte)
{
	CloseTapFile();

	if (!FOPEN_ISOK(FP_tapout,tapename, "r+b")) {
		Error( "opening file for write", tapename);
		return;
	}
	if (fseek(FP_tapout, 0, SEEK_END)) Error("File seek end error in TAPOUT", tapename, FATAL);

	tape_seek = ftell(FP_tapout);
	tape_parity = flagbyte;
	tape_length = 2;

	byte tap_data[3] = { 0, 0, (byte)flagbyte };

	if (sizeof(tap_data) != fwrite(tap_data, 1, sizeof(tap_data), FP_tapout)) {
		fclose(FP_tapout);
		Error("Write error (disk full?)", NULL, FATAL);
	}
}

bool FileExists(const std::filesystem::path & file_name) {
	FILE* test;
	bool exists = FOPEN_ISOK(test, file_name, "r") && (0 == fclose(test));
	return exists;
}

bool FileExistsCstr(const char* file_name) {
	if (nullptr == file_name) return false;
	return FileExists(std::filesystem::path(file_name));
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
	CloseBreakpointsFile();
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


int SaveBinary(const char* fname, aint start, aint length) {
	FILE* ff;
	if (!FOPEN_ISOK(ff, fname, "wb")) {
		Error("opening file for write", fname, FATAL);
	}
	int result = SaveRAM(ff, start, length);
	fclose(ff);
	return result;
}


int SaveBinary3dos(const char* fname, aint start, aint length, byte type, word w2, word w3) {
	FILE* ff;
	if (!FOPEN_ISOK(ff, fname, "wb")) Error("opening file for write", fname, FATAL);
	// prepare +3DOS 128 byte header content
	constexpr aint hsize = 128;
	const aint full_length = hsize + length;
	byte sum = 0, p3dos_header[hsize] { "PLUS3DOS\032\001" };
	p3dos_header[11] = byte(full_length>>0);
	p3dos_header[12] = byte(full_length>>8);
	p3dos_header[13] = byte(full_length>>16);
	p3dos_header[14] = byte(full_length>>24);
	// +3 BASIC 8 byte header filled with "relevant values"
	p3dos_header[15+0] = type;
	p3dos_header[15+1] = byte(length>>0);
	p3dos_header[15+2] = byte(length>>8);
	p3dos_header[15+3] = byte(w2>>0);
	p3dos_header[15+4] = byte(w2>>8);
	p3dos_header[15+5] = byte(w3>>0);
	p3dos_header[15+6] = byte(w3>>8);
	// calculat checksum of the header
	for (const byte v : p3dos_header) sum += v;
	p3dos_header[hsize-1] = sum;
	// write header and data
	int result = (hsize == (aint) fwrite(p3dos_header, 1, hsize, ff)) ? SaveRAM(ff, start, length) : 0;
	fclose(ff);
	return result;
}


int SaveBinaryAmsdos(const char* fname, aint start, aint length, word start_adr, byte type) {
	FILE* ff;
	if (!FOPEN_ISOK(ff, fname, "wb")) {
		Error("opening file for write", fname, SUPPRESS);
		return 0;
	}
	// prepare AMSDOS 128 byte header content
	constexpr aint hsize = 128;
	byte amsdos_header[hsize] {};	// all zeroed (user_number and filename stay like that, just zeroes)
	amsdos_header[0x12] = type;
	amsdos_header[0x15] = byte(start>>0);
	amsdos_header[0x16] = byte(start>>8);
	amsdos_header[0x18] = amsdos_header[0x40] = byte(length>>0);
	amsdos_header[0x19] = amsdos_header[0x41] = byte(length>>8);
	amsdos_header[0x1A] = byte(start_adr>>0);
	amsdos_header[0x1B] = byte(start_adr>>8);
	// calculat checksum of the header
	word sum = 0;
	for (int ii = 0x43; ii--; ) sum += amsdos_header[ii];
	amsdos_header[0x43] = byte(sum>>0);
	amsdos_header[0x44] = byte(sum>>8);
	// write header and data
	int result = (hsize == (aint) fwrite(amsdos_header, 1, hsize, ff)) ? SaveRAM(ff, start, length) : 0;
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
	if (!FOPEN_ISOK(ff, fname, "wb")) Error("opening file for write", fname, FATAL);
	bool res = SaveDeviceMemory(ff, start, length);
	fclose(ff);
	return res;
}


int SaveHobeta(const char* fname, const char* fhobname, aint start, aint length) {
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
		const char *ext = strrchr(fhobname, '.');
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
		Error("opening file for write", fname, FATAL);
	}

	int result = (17 == fwrite(header, 1, 17, ff)) && SaveRAM(ff, start, length);
	fclose(ff);
	return result;
}

EReturn ReadFile() {
	while (ReadLine()) {
		const bool isInsideDupCollectingLines = !RepeatStack.empty() && !RepeatStack.top().IsInWork;
		if (!isInsideDupCollectingLines) {
			// check for ending of IF/IFN/... block (keywords: ENDIF, ELSE and ELSEIF)
			char* p = line;
			SkipBlanks(p);
			if ('.' == *p) ++p;
			EReturn retVal = END;
			if (cmphstr(p, "elseif")) retVal = ELSEIF;
			if (cmphstr(p, "else")) retVal = ELSE;
			if (cmphstr(p, "endif")) retVal = ENDIF;
			if (END != retVal) {
				// one of the end-block keywords was found, don't parse it as regular line
				// but just substitute the rest of it and return end value of the keyword
				++CompiledCurrentLine;
				lp = ReplaceDefine(p);		// skip any empty substitutions and comments
				substitutedLine = line;		// for listing override substituted line with source
				if (ENDIF != retVal) ListFile();	// do the listing for ELSE and ELSEIF
				return retVal;
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
		if (isLabelStart(p) && !Options::syx.IsPseudoOpBOF) {
			// this could be label, skip it (the --dirbol users can't use label + IF/... inside block)
			while (islabchar(*p)) ++p;
			if (':' == *p) ++p;
		}
		SkipBlanks(p);
		if ('.' == *p) ++p;
		if (cmphstr(p, "if") || cmphstr(p, "ifn") || cmphstr(p, "ifused") ||
			cmphstr(p, "ifnused") || cmphstr(p, "ifdef") || cmphstr(p, "ifndef")) {
			++iflevel;
		} else if (cmphstr(p, "endif")) {
			if (iflevel) {
				--iflevel;
			} else {
				++CompiledCurrentLine;
				lp = ReplaceDefine(p);		// skip any empty substitutions and comments
				substitutedLine = line;		// override substituted listing for ENDIF
				return ENDIF;
			}
		} else if (cmphstr(p, "else")) {
			if (!iflevel) {
				++CompiledCurrentLine;
				lp = ReplaceDefine(p);		// skip any empty substitutions and comments
				substitutedLine = line;		// override substituted listing for ELSE
				ListFile();
				return ELSE;
			}
		} else if (cmphstr(p, "elseif")) {
			if (!iflevel) {
				++CompiledCurrentLine;
				lp = ReplaceDefine(p);		// skip any empty substitutions and comments
				substitutedLine = line;		// override substituted listing for ELSEIF
				ListFile();
				return ELSEIF;
			}
		} else if (cmphstr(p, "lua")) {		// lua script block detected, skip it whole
			// with extra custom while loop, to avoid confusion by `if/...` inside lua scripts
			ListFile(true);
			while (ReadLine()) {
				p = line;
				SkipBlanks(p);
				if (cmphstr(p, "endlua")) break;
				ListFile(true);
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
	if (IsRunning && lijst) {		// read MACRO lines, if macro is being emitted
		if (!lijstp || !lijstp->string) return 0;
		assert(!sourcePosStack.empty());
		sourcePosStack.back() = lijstp->source;
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
		++CompiledCurrentLine;
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

void OpenExpFile() {
	assert(nullptr == FP_ExportFile);			// this should be the first and only call to open it
	if (!Options::ExportFName.has_filename()) return;	// no export file name provided, skip opening
	if (FOPEN_ISOK(FP_ExportFile, Options::ExportFName, "w")) return;
	Error("opening file for write", Options::ExportFName.string().c_str(), ALL);
}

void WriteLabelEquValue(const char* name, aint value, FILE* f) {
	if (nullptr == f) return;
	char lnrs[16],* l = lnrs;
	STRCPY(temp, LINEMAX-2, name);
	STRCAT(temp, LINEMAX-1, ": EQU ");
	STRCAT(temp, LINEMAX-1, "0x");
	PrintHex32(l, value); *l = 0;
	STRCAT(temp, LINEMAX-1, lnrs);
	STRCAT(temp, LINEMAX-1, "\n");
	fputs(temp, f);
}

void WriteExp(const char* n, aint v) {
	WriteLabelEquValue(n, v, FP_ExportFile);
}

/////// source-level-debugging support by Ckirby

static FILE* FP_SourceLevelDebugging = NULL;
static char sldMessage[LINEMAX2];
static const char* WriteToSld_noSymbol = "";
static char sldMessage_sourcePos[1024];
static char sldMessage_definitionPos[1024];
static const char* sldMessage_posFormat = "%d:%d:%d";	// at +3 is "%d:%d" and at +6 is "%d"
static std::vector<std::string> sldCommentKeywords;

static void WriteToSldFile_TextFilePos(char* buffer, const TextFilePos & pos) {
	int offsetFormat = !pos.colBegin ? 6 : !pos.colEnd ? 3 : 0;
	snprintf(buffer, 1024-1, sldMessage_posFormat + offsetFormat, pos.line, pos.colBegin, pos.colEnd);
}

static void OpenSldImp(const std::filesystem::path & sldFilename) {
	if (!sldFilename.has_filename()) return;
	if (!FOPEN_ISOK(FP_SourceLevelDebugging, sldFilename, "w")) {
		Error("opening file for write", sldFilename.string().c_str(), FATAL);
	}
	fputs("|SLD.data.version|1\n", FP_SourceLevelDebugging);
	if (0 < sldCommentKeywords.size()) {
		fputs("||K|KEYWORDS|", FP_SourceLevelDebugging);
		bool notFirst = false;
		for (auto keyword : sldCommentKeywords) {
			if (notFirst) fputs(",", FP_SourceLevelDebugging);
			notFirst = true;
			fputs(keyword.c_str(), FP_SourceLevelDebugging);
		}
		fputs("\n", FP_SourceLevelDebugging);
	}
}

// will write result directly into Options::SourceLevelDebugFName
static void OpenSld_buildDefaultNameIfNeeded() {
	// check if SLD file name is already explicitly defined, or default is wanted
	if (Options::SourceLevelDebugFName.has_filename() || !Options::IsDefaultSldName) return;
	// name is still empty, and default is wanted, create one (start with "out" or first source name)
	ConstructDefaultFilename(Options::SourceLevelDebugFName, ".sld.txt", false);
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

	assert(!sourcePosStack.empty());
	const bool outside_source = (sourcePosStack.size() <= size_t(IncludeLevel));
	const bool has_def_pos = !outside_source && (size_t(IncludeLevel + 1) < sourcePosStack.size());
	const TextFilePos & curPos = outside_source ? sourcePosStack.back() : sourcePosStack.at(IncludeLevel);
	const TextFilePos defPos = has_def_pos ? sourcePosStack.back() : TextFilePos();

	const char* macroFN = defPos.filename && strcmp(defPos.filename, curPos.filename) ? defPos.filename : "";
	WriteToSldFile_TextFilePos(sldMessage_sourcePos, curPos);
	WriteToSldFile_TextFilePos(sldMessage_definitionPos, defPos);
	snprintf(sldMessage, LINEMAX2, "%s|%s|%s|%s|%d|%d|%c|%s\n",
				curPos.filename, sldMessage_sourcePos, macroFN, sldMessage_definitionPos,
				pageNum, value, type, symbol);
	fputs(sldMessage, FP_SourceLevelDebugging);
}

void SldAddCommentKeyword(const char* keyword) {
	if (nullptr == keyword || !keyword[0]) {
		if (LASTPASS == pass) Error("[SLDOPT COMMENT] invalid keyword", lp, SUPPRESS);
		return;
	}
	if (1 == pass) {
		auto begin = sldCommentKeywords.cbegin();
		auto end = sldCommentKeywords.cend();
		// add keyword only if it is new (not included yet)
		if (std::find(begin, end, keyword) == end) sldCommentKeywords.push_back(keyword);
	}
}

void SldTrackComments() {
	assert(eolComment && IsSldExportActive());
	if (!eolComment[0]) return;
	for (auto keyword : sldCommentKeywords) {
		if (strstr(eolComment, keyword.c_str())) {
			int pageNum = Page->Number;
			if (DISP_NONE != PseudoORG) {
				pageNum = LABEL_PAGE_UNDEFINED != dispPageNum ? dispPageNum : Device->GetPageOfA16(CurAddress);
			}
			WriteToSldFile(pageNum, CurAddress, 'K', eolComment);
			return;
		}
	}
}

/////// Breakpoints list (for different emulators)
static FILE* FP_BreakpointsFile = nullptr;
static EBreakpointsFile breakpointsType;
static int breakpointsCounter;

void OpenBreakpointsFile(const char* filename, const EBreakpointsFile type) {
	if (nullptr == filename || !filename[0]) {
		Error("empty filename", filename, EARLY);
		return;
	}
	if (FP_BreakpointsFile) {
		Error("breakpoints file was already opened", nullptr, EARLY);
		return;
	}
	if (!FOPEN_ISOK(FP_BreakpointsFile, filename, "w")) {
		Error("opening file for write", filename, EARLY);
	}
	breakpointsCounter = 0;
	breakpointsType = type;
}

static void CloseBreakpointsFile() {
	if (!FP_BreakpointsFile) return;
	fclose(FP_BreakpointsFile);
	FP_BreakpointsFile = nullptr;
}

void WriteBreakpoint(const aint val) {
	if (!FP_BreakpointsFile) {
		WarningById(W_BP_FILE);
		return;
	}
	++breakpointsCounter;
	switch (breakpointsType) {
		case BPSF_UNREAL:
			check16u(val);
			fprintf(FP_BreakpointsFile, "x0=0x%04X\n", val&0xFFFF);
			break;
		case BPSF_ZESARUX:
			if (1 == breakpointsCounter) fputs(" --enable-breakpoints ", FP_BreakpointsFile);
			if (100 < breakpointsCounter) {
				Warning("Maximum amount of 100 breakpoints has been already reached, this one is ignored");
				break;
			}
			check16u(val);
			fprintf(FP_BreakpointsFile, "--set-breakpoint %d \"PC=%d\" ", breakpointsCounter, val&0xFFFF);
			break;
	}
}

//eof sjio.cpp
