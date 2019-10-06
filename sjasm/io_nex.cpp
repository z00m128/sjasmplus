/*

  SjASMPlus Z80 Cross Compiler - modified - SAVENEX extension

  Copyright (c) 2006 Sjoerd Mastijn (original SW)
  Copyright (c) 2019 Peter Ped Helcmanovsky (SAVENEX extension)

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

// Banks in file are ordered in SNA way (but array "banks" in header is in numeric order instead)
static constexpr aint nexBankOrder[8] = {5, 2, 0, 1, 3, 4, 6, 7};

#ifdef _MSC_VER
#pragma pack(push, 1)
#endif
struct SNexHeader {
	constexpr static aint MAX_BANK = 112;
	constexpr static aint MAX_PAGE = MAX_BANK * 2;
	constexpr static byte SCR_LAYER2	= 0x01;
	constexpr static byte SCR_ULA		= 0x02;
	constexpr static byte SCR_LORES		= 0x04;
	constexpr static byte SCR_HIRES		= 0x08;
	constexpr static byte SCR_HICOL		= 0x10;
	constexpr static byte SCR_NOPAL		= 0x80;

	byte		magicAndVersion[8];	// the "magic" number + file version at the beginning
	byte		ramReq;				// 0 = 768k, 1 = 1792k
	byte		numBanks;			// number of 16k banks to load: 0..112
	byte		screen;				// loading screen flags
	byte		border;				// border colour 0..7
	word		sp;					// stack pointer
	word		pc;					// start address (0 = no start)
	word		_obsolete_numfiles;
	byte		banks[MAX_BANK];	// 112 16ki banks (1.75MiB) - non-zero value = in file
	// this array is ordinary order 0, 1, 2, ..., but banks in file are in order: 5, 2, 0, 1, ...
	byte		loadbar;			// 0/1 show progress bar
	byte		loadbarColour;		// colour of progress bar (precise meaning depends on gfx mode)
	byte		loadDelay;			// delay after each bank is loaded (number of frames)
	byte		startDelay;			// delay after whole file is loaded (number of frames)
	byte		preserveNextRegs;	// 0 = reset whole machine state, 1 = preserve most of it
	byte		coreVersion[3];
	byte		hiResColour;		// bits 5-3 for port 255 (ASM source provides 0..7 value, needs shift)
	byte		entryBank;			// 16ki bank 0..111 to be mapped into C000..FFFF range
	word		fileHandleCfg;		// 0 = close NEX file, 1 = pass handle in BC, 0x4000+ = address to write handle
	byte		_reserved[370];

	void init();
}
#ifndef _MSC_VER
	__attribute__((packed));
#else
	;
#pragma pack(pop)
#endif
static_assert(512 == sizeof(SNexHeader), "NEX header is expected to be 512 bytes long!");

struct SNexFile {
	SNexHeader	h;
	FILE*		f = nullptr;		// NEX file handle, stay opened, fseek stays at <EOF>
		// file is build sequentially, adding further blocks, only finalize does refresh the header
	aint		lastBankIndex;		// numeric order (0, 1, ...) value, -1 is init value

	~SNexFile();
	void writeHeader();
	void finalizeFile();
};

// the instance holding all tooling data and header about currently opened NEX file
static SNexFile nex;

void SNexHeader::init() {
	memset(magicAndVersion, 0, sizeof(SNexHeader));	// clear whole 512 bytes
	// set "magic" number and file version
	memcpy(magicAndVersion, "NextV1.2", 8);			// setup "magic" number at beginning
	// required core version is by default 2.00.28 (latest released)
	coreVersion[0] = 2;
	coreVersion[1] = 0;
	coreVersion[2] = 28;
}

SNexFile::~SNexFile() {
	finalizeFile();
}

void SNexFile::writeHeader() {
	if (nullptr == f) return;
	// refresh/write the file header
	fseek(f, 0, SEEK_SET);
	if (sizeof(SNexHeader) != fwrite(&h, 1, sizeof(SNexHeader), f)) {
		Error("[SAVENEX] writing header content failed", NULL, SUPPRESS);
	}
}

void SNexFile::finalizeFile() {
	if (nullptr == f) return;
	writeHeader();				// refresh the file header to final state
	// close the file
	fclose(f);
	f = nullptr;
	return;
}

static aint getNexBankIndex(const aint bank16kNum) {
	if (8 <= bank16kNum && bank16kNum < SNexHeader::MAX_BANK) return bank16kNum;
	for (aint i = 0; i < 8; ++i) {
		if (nexBankOrder[i] == bank16kNum) return i;
	}
	return -2;
}

aint getNexBankNum(const aint bankIndex) {
	if (0 <= bankIndex && bankIndex < 8) return nexBankOrder[bankIndex];
	if (8 <= bankIndex && bankIndex < SNexHeader::MAX_BANK) return bankIndex;
	return -1;
}

template <int argsN> static bool getIntArguments(aint (&args)[argsN], const bool argOptional[argsN]) {
	for (int i = 0; i < argsN; ++i) {
		if (0 < i && !comma(lp)) return argOptional[i];
		aint val;				// temporary variable to preserve original value in case of error
		if (!ParseExpression(lp, val)) return (0 == i) && argOptional[i];
		args[i] = val;
	}
	return !comma(lp);
}

static void dirNexOpen() {
	if (nex.f) {
		Error("[SAVENEX] NEX file is already open", bp, SUPPRESS);
		return;
	}
	nex.h.init();				// clears header and resets everything in it
	nex.lastBankIndex = -1;		// reset last bank index
	// read OPEN command arguments
	char* fname = GetFileName(lp);
	aint openArgs[3] = { (-1 == StartAddress ? 0 : StartAddress), 0xFFFE, 0 };
	if (comma(lp)) {
		const bool optionals[] = {false, true, true};	// start address is mandatory because comma
		if (!getIntArguments<3>(openArgs, optionals)) {
			Error("[SAVENEX] expected syntax is OPEN <filename>[,<startAddress>[,<stackAddress>[,<entryBank 0..111>]]]", bp, SUPPRESS);
			delete[] fname;
			return;
		}
	}
	// validate argument values
	if (-1 != StartAddress && StartAddress != openArgs[0]) {
		Warning("[SAVESNA] Start address was also defined by END, OPEN argument used instead");
	}
	check16(openArgs[0]);
	check16(openArgs[1]);
	if (openArgs[2] < 0 || SNexHeader::MAX_BANK <= openArgs[2]) {
		ErrorInt("[SAVENEX] entry bank can be 0..111 value only", openArgs[2], SUPPRESS);
		delete[] fname;
		return;
	}
	// try to open the actual file
	if (!FOPEN_ISOK(nex.f, fname, "wb")) Error("[SAVENEX] Error opening file", fname, SUPPRESS);
	delete[] fname;
	if (nullptr == nex.f) return;
	// set the argument values into header, and write the initial version of header into file
	nex.h.pc = openArgs[0] & 0xFFFF;
	nex.h.sp = openArgs[1] & 0xFFFF;
	nex.h.entryBank = openArgs[2];
	nex.writeHeader();
}

static void dirNexCore() {
	if (nullptr == nex.f) {
		Error("[SAVENEX] NEX file is not open", NULL, SUPPRESS);
		return;
	}
	// parse arguments
	aint coreArgs[3] = {0};
	const bool optionals[] = {false, false, false};
	if (!getIntArguments<3>(coreArgs, optionals)) {
		Error("[SAVENEX] expected syntax is CORE <major 0..15>,<minor 0..15>,<subminor 0..255>", bp, SUPPRESS);
		return;
	}
	// warn about invalid values
	if (coreArgs[0] < 0 || 15 < coreArgs[0] ||
		coreArgs[1] < 0 || 15 < coreArgs[1] ||
		coreArgs[2] < 0 || 255 < coreArgs[2]) Warning("[SAVENEX] values are not within 0..15,0..15,0..255 ranges");
	// set the values in header
	nex.h.coreVersion[0] = coreArgs[0];
	nex.h.coreVersion[1] = coreArgs[1];
	nex.h.coreVersion[2] = coreArgs[2];
}

static void dirNexCfg() {
	if (nullptr == nex.f) {
		Error("[SAVENEX] NEX file is not open", NULL, SUPPRESS);
		return;
	}
	// parse arguments
	aint cfgArgs[4] = {0};
	const bool optionals[] = {false, true, true, true};
	if (!getIntArguments<4>(cfgArgs, optionals)) {
		Error("[SAVENEX] expected syntax is CFG <border 0..7>[,<fileHandle 0/1/$4000+>[,<PreserveNextRegs 0/1>[,<2MbRamReq 0/1>]]]", bp, SUPPRESS);
		return;
	}
	// warn about invalid values
	if (cfgArgs[0] < 0 || 7 < cfgArgs[0] ||
		cfgArgs[1] < 0 || 0xFFFE < cfgArgs[1] ||
		cfgArgs[2] < 0 || 1 < cfgArgs[2] ||
		cfgArgs[3] < 0 || 1 < cfgArgs[3]) Warning("[SAVENEX] values are not within 0..7,0..65534,0/1,0/1 ranges");
	// set the values in header
	nex.h.border = cfgArgs[0] & 7;
	nex.h.fileHandleCfg = cfgArgs[1];
	nex.h.preserveNextRegs = cfgArgs[2];
	nex.h.ramReq = cfgArgs[3];
}

static void dirNexBar() {
	if (nullptr == nex.f) {
		Error("[SAVENEX] NEX file is not open", NULL, SUPPRESS);
		return;
	}
	// parse arguments
	aint barArgs[4] = {0};
	const bool optionals[] = {false, false, true, true};
	if (!getIntArguments<4>(barArgs, optionals)) {
		Error("[SAVENEX] expected syntax is BAR <loadBar 0/1>,<barColour 0..255>[,<startDelay 0..255>[,<bankDelay 0..255>]]", bp, SUPPRESS);
		return;
	}
	// warn about invalid values
	if (barArgs[0] < 0 || 1 < barArgs[0] ||
		barArgs[1] < 0 || 255 < barArgs[1] ||
		barArgs[2] < 0 || 255 < barArgs[2] ||
		barArgs[3] < 0 || 255 < barArgs[3]) Warning("[SAVENEX] values are not within 0/1,0..255,0..255,0..255 ranges");
	// set the values in header
	nex.h.loadbar = barArgs[0];
	nex.h.loadbarColour = barArgs[1];
	nex.h.startDelay = barArgs[2];
	nex.h.loadDelay = barArgs[3];
}

static void dirNexScreenLayer2andLowRes(bool Layer2) {
// ;; SCREEN L2 [<Page8kNum 0..223>,<offset>[,<palPage8kNum 0..223>,<palOffset>]]
// ;; SCREEN LR [<Page8kNum 0..223>,<offset>[,<palPage8kNum 0..223>,<palOffset>]]
	// parse arguments
	aint screenArgs[4] = {-1, 0, -1, 0};
	const bool optionals[] = {true, false, true, false};
	if (!getIntArguments<4>(screenArgs, optionals)
			|| screenArgs[0] < -1 || SNexHeader::MAX_PAGE <= screenArgs[0]		// -1 for default pixel data
			|| screenArgs[2] < -1 || SNexHeader::MAX_PAGE <= screenArgs[2]) {	// -1 for no-palette
		Error("[SAVENEX] expected syntax is ... [<Page8kNum 0..223>,<offset>[,<palPage8kNum 0..223>,<palOffset>]]", bp, SUPPRESS);
		return;
	}
	// warn about invalid values
	const size_t totalRam = Device->GetMemoryOffset(Device->PagesCount, 0);
	size_t adrPixelData = (-1 == screenArgs[0]) ? 0 : Device->GetMemoryOffset(screenArgs[0], screenArgs[1]);
	size_t pixelDataSize = Layer2 ? 0xC000 : 0x3000;
	if (totalRam < adrPixelData + pixelDataSize) {
		Error("[SAVENEX] pixel data address range is outside of Next memory", bp, SUPPRESS);
		return;
	}
	// palette is written first into file
	if (-1 == screenArgs[2]) nex.h.screen = SNexHeader::SCR_NOPAL;		// no palette data
	else {
		const int32_t adrPalData = Device->GetMemoryOffset(screenArgs[2], screenArgs[3]);
		const size_t palDataSize = 0x200;
		if (adrPalData < 0 || totalRam < adrPalData + palDataSize) {
			Error("[SAVENEX] palette data address range is outside of Next memory", bp, SUPPRESS);
			return;
		}
		if (palDataSize != fwrite(Device->Memory + adrPalData, 1, palDataSize, nex.f)) {
			Error("[SAVENEX] writing palette data failed", NULL, FATAL);
		}
	}
	// update header loading screen status
	nex.h.screen |= Layer2 ? SNexHeader::SCR_LAYER2 : SNexHeader::SCR_LORES;
	// write pixel data into file - first check if default RAM position should be used to read data
	if (-1 == screenArgs[0]) {
		if (!Layer2) {		// write first half of LoRes data straight from the VRAM position
			adrPixelData = Device->GetMemoryOffset(5*2, 0);
			pixelDataSize = 0x1800;
			if (pixelDataSize != fwrite(Device->Memory + adrPixelData, 1, pixelDataSize, nex.f)) {
				Error("[SAVENEX] writing pixel data failed", NULL, FATAL);
			}
			adrPixelData += 0x2000;		// address of second half of data
		} else {
			adrPixelData = Device->GetMemoryOffset(9*2, 0);
		}
	}
	// write [remaining] part of pixel data into file
	if (pixelDataSize != fwrite(Device->Memory + adrPixelData, 1, pixelDataSize, nex.f)) {
		Error("[SAVENEX] writing pixel data failed", NULL, FATAL);
	}
}

static void dirNexScreenUlaTimex(byte scrType) {
// ;; SCREEN (SCR|SHC|SHR) [<hiResColour 0..7>]
	// parse argument (only HiRes screen type)
	if (SNexHeader::SCR_HIRES == scrType) {
		aint hiResColor = 0;
		if (ParseExpression(lp, hiResColor)) {
			if (hiResColor < 0 || 7 < hiResColor) Warning("[SAVENEX] value is not in 0..7 range", bp);
			nex.h.hiResColour = hiResColor << 3;
		}
	}
	// update header loading screen status
	nex.h.screen = scrType;
	// warn about invalid values
	size_t adrPixelData = Device->GetMemoryOffset(5*2, 0);
	size_t pixelDataSize = (SNexHeader::SCR_ULA == scrType) ? 0x1B00 : 0x1800;
	// write pixel data into file (from the default VRAM position of device)
	if (pixelDataSize != fwrite(Device->Memory + adrPixelData, 1, pixelDataSize, nex.f)) {
		Error("[SAVENEX] writing pixel data failed", NULL, FATAL);
	}
	if (SNexHeader::SCR_ULA == scrType) return;		//ULA is written in one go
	adrPixelData += 0x2000;							// address of second half of data
	// write [remaining] part of pixel data into file
	if (pixelDataSize != fwrite(Device->Memory + adrPixelData, 1, pixelDataSize, nex.f)) {
		Error("[SAVENEX] writing pixel data failed", NULL, FATAL);
	}
}

static void dirNexScreen() {
	if (nullptr == nex.f) {
		Error("[SAVENEX] NEX file is not open", NULL, SUPPRESS);
		return;
	}
	if (0 != nex.h.screen) {
		Error("[SAVENEX] screen for this NEX file was already stored", NULL, SUPPRESS);
		return;
	}
	if (-1 != nex.lastBankIndex) {
		Error("[SAVENEX] some bank was already stored (store screen first)", NULL, SUPPRESS);
		return;
	}
	SkipBlanks(lp);
	if (cmphstr(lp, "l2")) dirNexScreenLayer2andLowRes(true);
	else if (cmphstr(lp, "lr")) dirNexScreenLayer2andLowRes(false);
	else if (cmphstr(lp, "scr")) dirNexScreenUlaTimex(SNexHeader::SCR_ULA);
	else if (cmphstr(lp, "shc")) dirNexScreenUlaTimex(SNexHeader::SCR_HICOL);
	else if (cmphstr(lp, "shr")) dirNexScreenUlaTimex(SNexHeader::SCR_HIRES);
	else Error("[SAVENEX] unknown screen type (types: L2, LR, SCR, SHC, SHR)", lp, SUPPRESS);
}

static bool saveBank(aint bankIndex, aint bankNum, bool onlyNonZero = false) {
	if (bankNum < 0 || SNexHeader::MAX_BANK <= bankNum) return false;
	if (bankIndex <= nex.lastBankIndex) {
		ErrorInt("[SAVENEX] it's too late to save this bank (correct order: 5, 2, 0, 1, 3, 4, 6, ...)",
					bankNum, SUPPRESS);
		return false;
	}
	const size_t offset = Device->GetMemoryOffset(bankNum * 2, 0);
	const size_t size = 0x4000;
	nex.lastBankIndex = bankIndex;
	// detect bank which is just full of zeroes and exit early if onlyNonZero is requested
	if (onlyNonZero) {
		size_t zeroOfs = 0;
		while (zeroOfs < size) {
			if (0 != Device->Memory[offset + zeroOfs]) break;
			++zeroOfs;
		}
		if (size == zeroOfs) return true;
	}
	// update NEX header data
	nex.h.banks[bankNum] = 1;
	++nex.h.numBanks;
	// save the bank memory
	if (size != fwrite(Device->Memory + offset, 1, size, nex.f)) {
		Error("[SAVENEX] writing bank data failed", NULL, FATAL);
	}
	return true;
}

static void dirNexBank() {
	if (nullptr == nex.f) {
		Error("[SAVENEX] NEX file is not open", NULL, SUPPRESS);
		return;
	}
	do {
		aint bankNum, bankIndex;
		char *nextLp = lp;
		if (!ParseExpressionNoSyntaxError(lp, bankNum)
			|| (bankIndex = getNexBankIndex(bankNum)) < 0) {
			Error("[SAVENEX] expected bank number 0..111", nextLp, SUPPRESS);
			break;
		}
		if (!saveBank(bankIndex, bankNum)) break;
	} while (comma(lp));
}

static void dirNexAuto() {
	if (nullptr == nex.f) {
		Error("[SAVENEX] NEX file is not open", NULL, SUPPRESS);
		return;
	}
	if (SNexHeader::MAX_BANK-1 == nex.lastBankIndex) {	// actually there's nothing left to scan
		Error("[SAVENEX] all banks are already stored", NULL, SUPPRESS);
		return;
	}
	// parse arguments
	aint autoArgs[2] = { getNexBankNum(nex.lastBankIndex+1), SNexHeader::MAX_BANK-1 };
	const bool optionals[] = {true, true};
	if (!getIntArguments<2>(autoArgs, optionals)
			|| autoArgs[0] < 0 || SNexHeader::MAX_BANK <= autoArgs[0]
			|| autoArgs[1] < 0 || SNexHeader::MAX_BANK <= autoArgs[1]) {
		Error("[SAVENEX] expected syntax is AUTO [<fromBank 0..111>[,<toBank 0..111>]]", bp, SUPPRESS);
		return;
	}
	// validate arguments
	aint fromI = getNexBankIndex(autoArgs[0]), toI = getNexBankIndex(autoArgs[1]);
	if (toI < fromI) {
		Error("[SAVENEX] 'toBank' is less than 'fromBank'", bp, SUPPRESS);
		return;
	}
	while (fromI <= toI) {
		if (!saveBank(fromI, getNexBankNum(fromI), true)) return;
		++fromI;
	}
}

static void dirNexClose() {
	if (nullptr == nex.f) {
		Error("[SAVENEX] NEX file is not open", NULL, SUPPRESS);
		return;
	}
	// read CLOSE command argument and try to append the proposed file (if some was provided)
	char* appendName = nullptr;
	if (!SkipBlanks(lp)) appendName = GetFileName(lp);
	if (appendName) {	// some append file requested, try to copy its content at tail of NEX
		FILE* appendF = nullptr;
		if (!FOPEN_ISOK(appendF, appendName, "rb")) {
			Error("[SAVENEX] Error opening append file", appendName, SUPPRESS);
		} else {
			static constexpr int copyBufSize = 0x4000;
			byte* copyBuffer = new byte[copyBufSize];
			if (nullptr == copyBuffer) ErrorOOM();
			do {
				const size_t read = fread(copyBuffer, 1, copyBufSize, appendF);
				if (read) {
					const size_t write = fwrite(copyBuffer, 1, read, nex.f);
					if (write != read) Error("[SAVENEX] writing append data failed", NULL, FATAL);
				}
			} while (!feof(appendF));
			delete[] copyBuffer;
			fclose(appendF);
		}
		delete[] appendName;
	}
	// finalize the NEX file (refresh the header data and close it)
	nex.finalizeFile();
}

void dirSAVENEX() {
	if (pass != LASTPASS) return;		// syntax error is not visible in early passes
	if (nullptr == DeviceID || strcmp(DeviceID, "ZXSPECTRUMNEXT")) {
		Error("[SAVENEX] is allowed only in ZXSPECTRUMNEXT device mode", NULL, SUPPRESS);
		return;
	}
	SkipBlanks(lp);
	if (cmphstr(lp, "open")) dirNexOpen();
	else if (cmphstr(lp, "core")) dirNexCore();
	else if (cmphstr(lp, "cfg")) dirNexCfg();
	else if (cmphstr(lp, "bar")) dirNexBar();
	else if (cmphstr(lp, "screen")) dirNexScreen();
	else if (cmphstr(lp, "bank")) dirNexBank();
	else if (cmphstr(lp, "auto")) dirNexAuto();
	else if (cmphstr(lp, "close")) dirNexClose();
	else Error("[SAVENEX] unknown command (commands: OPEN, CORE, CFG, BAR, SCREEN, BANK, AUTO, CLOSE)", lp, SUPPRESS);
}
