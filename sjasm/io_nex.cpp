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
#include "crc32c.h"
#include <cassert>

// Banks in file are ordered in SNA way (but array "banks" in header is in numeric order instead)
static constexpr aint nexBankOrder[8] = {5, 2, 0, 1, 3, 4, 6, 7};

#ifdef _MSC_VER
#pragma pack(push, 1)
#endif
struct SNexHeader {
	constexpr static size_t COPPER_SIZE = 0x0800;
	constexpr static size_t PAL_SIZE = 0x200;
	constexpr static aint MAX_BANK = 112;
	constexpr static aint MAX_PAGE = MAX_BANK * 2;
	constexpr static byte SCR_LAYER2	= 0x01;
	constexpr static byte SCR_ULA		= 0x02;
	constexpr static byte SCR_LORES		= 0x04;
	constexpr static byte SCR_HIRES		= 0x08;
	constexpr static byte SCR_HICOL		= 0x10;
	constexpr static byte SCR_EXT2		= 0x40;
	constexpr static byte SCR_NOPAL		= 0x80;
	constexpr static byte SCR2_320x256	= 1;
	constexpr static byte SCR2_640x256	= 2;
	constexpr static byte SCR2_tilemap	= 3;

	byte		magicAndVersion[8];	// the "magic" number + file version at the beginning
	byte		ramReq;				// 0 = 768k, 1 = 1792k
	byte		numBanks;			// number of 16k banks to load: 0..112
	byte		screen;				// loading screen flags
	byte		border;				// border colour 0..7
	word		sp;					// stack pointer
	word		pc;					// start address (0 = no start)
	word		_obsolete_numfiles;
	byte		banks[MAX_BANK];	// 112 16ki banks (1.75MiB) - non-zero value = in file
	// banks array is ordinary order 0, 1, 2, ..., but banks in file are in order: 5, 2, 0, 1, ...
	byte		loadbar;			// 0/1 show progress bar
	byte		loadbarColour;		// colour of progress bar (precise meaning depends on gfx mode)
	byte		loadDelay;			// delay after each bank is loaded (number of frames)
	byte		startDelay;			// delay after whole file is loaded (number of frames)
	byte		preserveNextRegs;	// 0 = reset whole machine state, 1 = preserve most of it
	byte		coreVersion[3];
	byte		hiResColour;		// bits 5-3 for port 255 (ASM source provides 0..7 value, needs shift)
	byte		entryBank;			// 16ki bank 0..111 to be mapped into C000..FFFF range
	word		fileHandleCfg;		// 0 = close NEX file, 1 = pass handle in BC, 0x4000+ = address to write handle
	// V1.3 fields
	byte		expBusDisable;		// 0 = disable expansion bus by setting top four bits of NextReg 0x80, 1 = no-op
	byte		hasChecksum;		// 0 = no checksum, 1 = last 4B of header are CRC-32C (Castagnoli)
	uint32_t	banksOffset;		// where data of first bank start in file (NEX V1.3+ file, 0 olders)
	word		cliBuffer;			// address of buffer for command line copy (0 = off)
	word		cliBufferSize;		// size of the provided buffer (0 = off) (cmd line is truncated to this size)
	byte		screen2;			// extended screen flag (old "screen" must have +64 flag)
	byte		hasCopperCode;		// 0 = no copper, 1 = 2048B copper block after loading screens
	byte		tilesScrConfig[4];	// NextReg registers $6B, $6C, $6E, $6F values for Tilemode screen
	byte		bigL2barPosY;		// Y position (0..255) of loading bar for new Layer 2 320x256 and 640x256 modes
	byte		_reserved[349];
	uint32_t	crc32c;				// CRC-32C build by: file offset 512->EOF (including append bin), then 508B header

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
	aint		reqFileVersion;		// requested file version in OPEN command
	aint		minFileVersion;		// currently auto-detected file version
	FILE*		f = nullptr;		// NEX file handle, stay opened, fseek stays at <EOF>
		// file is build sequentially, adding further blocks, only finalize does refresh the header
	aint		lastBankIndex;		// numeric order (0, 1, ...) value, -1 is init value
	byte*		copper = nullptr;	// temporary storage of copper code (add it ahead of first bank)
	byte*		palette = nullptr;	// final palette (will override the one stored upon finalize)
	bool		palDefined;			// whether the palette data/type was enforced by PALETTE command
	bool		canAppend = false;	// true when `fwrite(..., f)` can be used in "append like" way
	// set `canAppend` to false whenever you do fseek/fread, it cancels validity of "next fwrite"

	~SNexFile();
	void init();
	void writeHeader();
	void writePalette();
	void calculateCrc32C();
	void updateIfAheadFirstBankSave();
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

void SNexFile::init() {
	h.init();
	lastBankIndex = -1;		// reset last bank index
	palDefined = false;
	reqFileVersion = 0;
	minFileVersion = 2;
}

void SNexFile::updateIfAheadFirstBankSave() {
	// check if already updated or file is not ready for appending (no file, or finalizing)
	if (h.banksOffset || !canAppend) return;
	// updating bank offset after some bank was already stored -> should never happen
	if (-1 != lastBankIndex) Error("[SAVENEX] V1.3?!", NULL, FATAL);	// unreachable
	if (palDefined && 0 == h.screen) {
		Warning("[SAVENEX] some palette was defined, but without screen it is ignored.");
	}
	// V1.3 feature, copper code is the last block ahead of first bank
	if (h.hasCopperCode) {
		if (SNexHeader::COPPER_SIZE != fwrite(copper, 1, SNexHeader::COPPER_SIZE, f)) {
			Error("[SAVENEX] writing copper data failed", NULL, FATAL);
		}
	}
	// V1.3 feature, offset of very first bank stored in file
	h.banksOffset = ftell(f);
}

void SNexFile::writeHeader() {
	if (nullptr == f) return;
	canAppend = false;							// does fseek, cancel the "append" mode
	// refresh/write the file header
	fseek(f, 0, SEEK_SET);
	if (sizeof(SNexHeader) != fwrite(&h, 1, sizeof(SNexHeader), f)) {
		Error("[SAVENEX] writing header content failed", NULL, SUPPRESS);
	}
}

void SNexFile::writePalette() {
	if (!canAppend) return;
	if (!palDefined || nullptr == palette) {	// palette is completely undefined or
		h.screen = SNexHeader::SCR_NOPAL;		// "no palette" was defined
	} else {
		if (SNexHeader::PAL_SIZE != fwrite(palette, 1, SNexHeader::PAL_SIZE, f)) {
			Error("[SAVENEX] writing palette data failed", NULL, FATAL);
		}
	}
}

void SNexFile::calculateCrc32C() {
	if (!h.hasChecksum) return;
	if (nullptr == f) return;
	canAppend = false;							// does fseek+fread, cancel the "append" mode
	// calculate checksum CRC-32C (Castagnoli)
	crc32_init();
	constexpr size_t BUFFER_SIZE = 128 * 1024;	// 128kiB buffer to read file (must be 512+ !!)
	uint8_t *buffer = new uint8_t[BUFFER_SIZE];
	if (nullptr == buffer) ErrorOOM();
	uint32_t crc = 0;
	// calculate CRC of the file part after header (offset 512)
	fseek(f, 512, SEEK_SET);
	size_t bytes_read = 0;
	do {
		bytes_read = fread(buffer, 1, BUFFER_SIZE, f);
		if (0 == bytes_read) break;
		crc = crc32c_append_sw(crc, buffer, bytes_read);
	} while (BUFFER_SIZE == bytes_read);
	// calculate CRC of the header part (first 508 bytes of header)
	fseek(f, 0, SEEK_SET);
	bytes_read = fread(buffer, 1, 508, f);
	h.hasChecksum = (508 == bytes_read);
	if (h.hasChecksum) {
		h.crc32c = crc32c_append_sw(crc, buffer, bytes_read);
	} else {
		Error("[SAVENEX] reading file for CRC calculation failed");
	}
	delete[] buffer;
}

void SNexFile::finalizeFile() {
	if (nullptr == f) return;
	// do the final V1.2 / V1.3 updates to the header fields
	// V1.3 auto-detected when V1.2 is required should never happen (Error should be unreachable)
	if (3 == minFileVersion && 2 == reqFileVersion) Error("[SAVENEX] V1.3?!", NULL, FATAL);
	updateIfAheadFirstBankSave();	// if no BANK/AUTO/CLOSE was used -> update all now
	if (2 == minFileVersion) {
		h.banksOffset = 0;		// clear banksOffset for V1.2 files
		h.bigL2barPosY = 0;		// clear big Layer 2 loading-bar posY for V1.2 files
	} else {
		h.magicAndVersion[7] = '3';				// modify file version to "V1.3" string
		calculateCrc32C();
	}
	// refresh the file header to final state
	writeHeader();
	// close the file
	fclose(f);
	f = nullptr;
	canAppend = false;
	if (nullptr != copper) delete[] copper;
	copper = nullptr;
	if (nullptr != palette) delete[] palette;
	palette = nullptr;
	return;
}

enum EBmpType { other, Layer2, LoRes, L2_320x256, L2_640x256 };

class SBmpFile {
	FILE*		bmp;
	byte		tempHeader[0x36];		// 14B header + BITMAPINFOHEADER 40B header
	byte*		palBuffer = nullptr;

public:
	EBmpType	type = other;
	int32_t		width = 0, height = 0;
	bool		upsideDown = false;
	uint32_t	colorsCount = 0;

	~SBmpFile();
	void close();
	bool open(const char* bmpname);
	word getColor(uint32_t index);
	void loadPixelData(byte* buffer);
};

SBmpFile::~SBmpFile() {
	close();
}

void SBmpFile::close() {
	if (nullptr == bmp) return;
	fclose(bmp);
	bmp = nullptr;
	delete[] palBuffer;
	palBuffer = nullptr;
}

bool SBmpFile::open(const char* bmpname) {
	if (!FOPEN_ISOK(bmp, bmpname, "rb")) {
		Error("[SAVENEX] Error opening file", bmpname, SUPPRESS);
		return false;
	}
	// read header of BMP and verify the file is of expected format
	palBuffer = new byte[4*256];
	if (nullptr == palBuffer) ErrorOOM();
	const size_t readElements = fread(tempHeader, 1, 0x36, bmp) + fread(palBuffer, 4, 256, bmp);
	// these following casts assume the sjasmplus itself is running at little-endian platform
	// if you are using big-endian, report the issue, so this can be fixed in more universal way
	const uint32_t header2Size = reinterpret_cast<SAlignSafeCast<uint32_t>*>(tempHeader + 14)->val;
	const uint16_t colorPlanes = *reinterpret_cast<uint16_t*>(tempHeader + 26);
	const uint16_t bpp = *reinterpret_cast<uint16_t*>(tempHeader + 28);
	const uint32_t compressionType = reinterpret_cast<SAlignSafeCast<uint32_t>*>(tempHeader + 30)->val;
	// check "BM", BITMAPINFOHEADER type (size 40), 8bpp, no compression
	if (0x36+256 != readElements || 'B' != tempHeader[0] || 'M' != tempHeader[1] ||
		40 != header2Size || 1 != colorPlanes || 8 != bpp || 0 != compressionType)
	{
		Error("[SAVENEX] BMP file is not in expected format (uncompressed, 8bpp, 40B BITMAPINFOHEADER header)",
				bmpname, SUPPRESS);
		close();
		return false;
	}
	colorsCount = reinterpret_cast<SAlignSafeCast<uint32_t>*>(tempHeader + 46)->val;
	// check if the size is 256x192 (Layer 2) or 128x96 (LoRes), or 320/640 x 256 (V1.3).
	width = reinterpret_cast<SAlignSafeCast<int32_t>*>(tempHeader + 18)->val;
	height = reinterpret_cast<SAlignSafeCast<int32_t>*>(tempHeader + 22)->val;
	upsideDown = 0 < height;
	if (height < 0) height = -height;
	if (256 == width && 192 == height) type = Layer2;
	if (128 == width && 96 == height) type = LoRes;
	if (256 == height) {
		if (320 == width) type = L2_320x256;
		if (640 == width) type = L2_640x256;
	}
	return true;
}

word SBmpFile::getColor(uint32_t index) {
	if (nullptr == bmp || nullptr == palBuffer || colorsCount <= index) return 0;
	const byte B = palBuffer[index * 4 + 0] >> 5;
	const byte G = palBuffer[index * 4 + 1] >> 5;
	const byte R = palBuffer[index * 4 + 2] >> 5;
	return ((B&1) << 8) | (B >> 1) | (G << 2) | (R << 5);
}

void SBmpFile::loadPixelData(byte* buffer) {
	const uint32_t offset = reinterpret_cast<SAlignSafeCast<uint32_t>*>(tempHeader + 10)->val;
	const size_t w = static_cast<size_t>(width);
	for (int32_t y = 0; y < height; ++y) {
		const int32_t fileY = upsideDown ? (height - y - 1) : y;
		fseek(bmp, offset + (w * fileY), SEEK_SET);
		if (w != fread(buffer + (w * y), 1, w, bmp)) {
			Error("[SAVENEX] reading BMP pixel data failed", NULL, FATAL);
		}
	}
}

static aint getNexBankIndex(const aint bank16kNum) {
	if (8 <= bank16kNum && bank16kNum < SNexHeader::MAX_BANK) return bank16kNum;
	for (aint i = 0; i < 8; ++i) {
		if (nexBankOrder[i] == bank16kNum) return i;
	}
	return -2;
}

static aint getNexBankNum(const aint bankIndex) {
	if (0 <= bankIndex && bankIndex < 8) return nexBankOrder[bankIndex];
	if (8 <= bankIndex && bankIndex < SNexHeader::MAX_BANK) return bankIndex;
	return -1;
}

static void checkStackPointer() {
	constexpr int CHECK_SIZE = 10;
	constexpr int EXPECTED_SLOTS_COUNT = 8;
	const int adrMask = Device->GetCurrentSlot()->Size - 1;
	const int pages[EXPECTED_SLOTS_COUNT] = { 0, 0, 5*2, 5*2+1, 2*2, 2*2+1, nex.h.entryBank*2, nex.h.entryBank*2+1 };
	assert(EXPECTED_SLOTS_COUNT == Device->SlotsCount);
	// check if SP is too close to ROM (0x0001 ... 0x4009)
	if (0x0000 < nex.h.sp && nex.h.sp < 0x4000 + CHECK_SIZE) {
		Warning("[SAVENEX] stackAddress is too close to ROM area");
		return;
	}
	// check if good-looking SP points to enough of zeroed memory, warn about overwrite if not
	word spCheck = word(nex.h.sp - CHECK_SIZE);
	while (spCheck != nex.h.sp) {
		const int pageNum = pages[Device->GetSlotOfA16(spCheck)];
		const size_t offset = Device->GetMemoryOffset(pageNum, spCheck & adrMask);
		if (0 != Device->Memory[offset]) break;
		++spCheck;
	}
	if (spCheck == nex.h.sp) return;
	WarningById(W_NEX_STACK);
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
	nex.init();			// reset everything around NEX file data
	// read OPEN command arguments
	std::unique_ptr<char[]> fname(GetOutputFileName(lp));
	aint openArgs[4] = { (-1 == StartAddress ? 0 : StartAddress), 0xFFFE, 0, 0 };
	if (comma(lp)) {
		const bool optionals[] = {false, true, true, true};	// start address is mandatory because comma
		if (!getIntArguments<4>(openArgs, optionals)) {
			Error("[SAVENEX] expected syntax is OPEN <filename>[,<startAddress>[,<stackAddress>[,<entryBank 0..111>[,<fileVersion 2..3>]]]]", bp, SUPPRESS);
			return;
		}
	}
	// validate argument values
	if (-1 != StartAddress && StartAddress != openArgs[0]) {
		Warning("[SAVENEX] Start address was also defined by END, OPEN argument used instead");
	}
	check16(openArgs[0]);
	check16(openArgs[1]);
	if (openArgs[2] < 0 || SNexHeader::MAX_BANK <= openArgs[2]) {
		ErrorInt("[SAVENEX] entry bank can be 0..111 value only", openArgs[2], SUPPRESS);
		return;
	}
	if (openArgs[3] && (openArgs[3] < 2 || 3 < openArgs[3])) {
		ErrorInt("[SAVENEX] only file version 2 (V1.2) or 3 (V1.3) can be enforced", openArgs[3], SUPPRESS);
		return;
	}
	// try to open the actual file
	if (!FOPEN_ISOK(nex.f, fname.get(), "w+b")) Error("[SAVENEX] Error opening file", fname.get(), SUPPRESS);
	if (nullptr == nex.f) return;
	// set the argument values into header, and write the initial version of header into file
	nex.h.pc = openArgs[0] & 0xFFFF;
	nex.h.sp = openArgs[1] & 0xFFFF;
	nex.h.entryBank = openArgs[2];
	nex.reqFileVersion = openArgs[3];
	nex.minFileVersion = (3 == nex.reqFileVersion) ? 3 : 2;	// reset auto-detected file version
	nex.writeHeader();
	// After writing header first time, the file is ready for "append like" usage
	nex.canAppend = true;
	checkStackPointer();
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

static void dirNexCfg3() {
// ;; SAVENEX CFG3 <DoCRC 0/1>[,<PreserveExpansionBus 0/1>[,<CLIbufferAdr>,<CLIbufferSize>]]
	if (nullptr == nex.f) {
		Error("[SAVENEX] NEX file is not open", NULL, SUPPRESS);
		return;
	}
	if (nex.reqFileVersion == 2) {
		Error("[SAVENEX] V1.2 was requested with OPEN, but CFG3 is V1.3 feature.", NULL, SUPPRESS);
		return;
	}
	nex.minFileVersion = 3;		// V1.3 detected
	// parse arguments
	aint cfgArgs[4] = {1, 0};
	const bool optionals[] = {false, true, true, false};
	if (!getIntArguments<4>(cfgArgs, optionals)) {
		Error("[SAVENEX] expected syntax is CFG3 <DoCRC 0/1>[,<PreserveExpansionBus 0/1>[,<CLIbufferAdr>,<CLIbufferSize>]]", bp, SUPPRESS);
		return;
	}
	const bool someCliBuffer = cfgArgs[2] || cfgArgs[3];	// [0, 0] = no CLI buffer, don't check validity
	// warn about invalid values
	if (cfgArgs[0] < 0 || 1 < cfgArgs[0] ||
		cfgArgs[1] < 0 || 1 < cfgArgs[1] ||
		(someCliBuffer &&
			(cfgArgs[2] < 0x4000 || 0x10000 < (cfgArgs[2] + cfgArgs[3]) ||
			cfgArgs[3] < 1 || 0x0800 < cfgArgs[3]))) {
		Warning("[SAVENEX] crc/preserve values are not 0/1 or CLI buffer doesn't fit into $4000..$FFFF range (size can be 2048 max)");
	}
	// set the values in header
	nex.h.hasChecksum = !!cfgArgs[0];
	nex.h.expBusDisable = !!cfgArgs[1];
	nex.h.cliBuffer = cfgArgs[2];
	nex.h.cliBufferSize = cfgArgs[3];
}

static void dirNexCfg() {
// ;; SAVENEX CFG <border 0..7>[,<fileHandle 0/1/$4000+>[,<PreserveNextRegs 0/1>[,<2MbRamReq 0/1>]]]
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
	aint barArgs[5] = {0, 0, 0, 0, 254};
	const bool optionals[] = {false, false, true, true, true};
	if (!getIntArguments<5>(barArgs, optionals)) {
		Error("[SAVENEX] expected syntax is BAR <loadBar 0/1>,<barColour 0..255>[,<startDelay 0..255>[,<bankDelay 0..255>[,<posY 0..255>]]]", bp, SUPPRESS);
		return;
	}
	// warn about invalid values
	if (barArgs[0] < 0 || 1 < barArgs[0] ||
		barArgs[1] < 0 || 255 < barArgs[1] ||
		barArgs[2] < 0 || 255 < barArgs[2] ||
		barArgs[3] < 0 || 255 < barArgs[3] ||
		barArgs[4] < 0 || 255 < barArgs[4]) Warning("[SAVENEX] values are not within 0/1 or 0..255 ranges");
	// set the values in header
	nex.h.loadbar = barArgs[0];
	nex.h.loadbarColour = barArgs[1];
	nex.h.startDelay = barArgs[2];
	nex.h.loadDelay = barArgs[3];
	nex.h.bigL2barPosY = barArgs[4];
}

static void dirNexPaletteDefault() {
// ;; SAVENEX PALETTE DEFAULT
	nex.palDefined = true;
	nex.palette = new byte[SNexHeader::PAL_SIZE];
	if (nullptr == nex.palette) ErrorOOM();
	for (uint32_t i = 0; i < 256; ++i) {
		nex.palette[i*2 + 0] = static_cast<byte>(i);
		nex.palette[i*2 + 1] = (i & 3) ? 1 : 0;		// bottom blue bit is 1 when some upper bit is
	}
}

static bool dirNexPaletteMem(const aint page8kNum, const aint palOffset) {
	if (nex.palDefined) return true;	// palette was already defined, silently ignore
	if (-1 == page8kNum) {				// this is used as "no palette" by some screen commands
		nex.palDefined = true;
		return true;
	}
	// warn about invalid values
	const size_t totalRam = Device->GetMemoryOffset(Device->PagesCount, 0);
	const int32_t adrPalData = Device->GetMemoryOffset(page8kNum, palOffset);
	if (adrPalData < 0 || totalRam < adrPalData + SNexHeader::PAL_SIZE) {
		Error("[SAVENEX] palette data address range is outside of Next memory", bp, SUPPRESS);
		return false;
	}
	// copy the data into internal palette buffer
	nex.palDefined = true;
	nex.palette = new byte[SNexHeader::PAL_SIZE];
	if (nullptr == nex.palette) ErrorOOM();
	memcpy(nex.palette, Device->Memory + adrPalData, SNexHeader::PAL_SIZE);
	return true;
}

static bool dirNexPaletteBmp(SBmpFile & bmp) {
	if (nex.palDefined) return true;	// palette was already defined, silently ignore
	if (256 != bmp.colorsCount && warningNotSuppressed()) {
		WarningById(W_NEX_BMP_PAL, bmp.colorsCount);
	}
	// copy the data into internal palette buffer
	nex.palDefined = true;
	nex.palette = new byte[SNexHeader::PAL_SIZE];
	if (nullptr == nex.palette) ErrorOOM();
	constexpr size_t palDataSize = 256;
	for (size_t i = 0; i < palDataSize; ++i) {
		const word nextColor = bmp.getColor(i);
		nex.palette[i*2 + 0] = nextColor & 0xFF;
		nex.palette[i*2 + 1] = nextColor >> 8;
	}
	return true;
}

static void dirNexPaletteMem() {
// ;; SAVENEX PALETTE MEM <palPage8kNum 0..223>,<palOffset>
	aint palArgs[2] = {0, 0};
	const bool optionals[] = {false, false};
	if (!getIntArguments<2>(palArgs, optionals)
			|| palArgs[0] < 0 || SNexHeader::MAX_PAGE <= palArgs[0] || palArgs[1] < 0) {
		Error("[SAVENEX] expected syntax is MEM <palPage8kNum 0..223>,<palOffset 0+>", bp, SUPPRESS);
		return;
	}
	dirNexPaletteMem(palArgs[0], palArgs[1]);
}

static void dirNexPaletteBmp() {
// ;; SAVENEX PALETTE BMP <filename>
	const char* const bmpname = GetFileName(lp);
	if (!bmpname[0] || comma(lp)) {
		Error("[SAVENEX] expected syntax is BMP <filename>", bp, SUPPRESS);
		delete[] bmpname;
		return;
	}
	// try to open the actual BMP file
	SBmpFile bmp;
	bool bmpOpened = bmp.open(bmpname);
	delete[] bmpname;
	if (!bmpOpened) return;
	// check the palette if it was requested from this bmp and process it
	dirNexPaletteBmp(bmp);
}

static void dirNexPalette() {
// ;; SAVENEX PALETTE (NONE|DEFAULT|MEM|BMP)
	if (nullptr == nex.f) {
		Error("[SAVENEX] NEX file is not open", NULL, SUPPRESS);
		return;
	}
	if (nex.palDefined || 0 != nex.h.screen) {
		Error("[SAVENEX] some palette/screen was already defined (define palette once and ahead)", NULL, SUPPRESS);
		return;
	}
	if (-1 != nex.lastBankIndex) {
		Error("[SAVENEX] some bank was already stored (define palette ahead)", NULL, SUPPRESS);
		return;
	}
	SkipBlanks(lp);
	if (cmphstr(lp, "none")) nex.palDefined = true;
	else if (cmphstr(lp, "default")) dirNexPaletteDefault();
	else if (cmphstr(lp, "mem")) dirNexPaletteMem();
	else if (cmphstr(lp, "bmp")) dirNexPaletteBmp();
	else Error("[SAVENEX] unknown palette command (commands: NONE, DEFAULT, MEM, BMP)", lp, SUPPRESS);
}

static void dirNexScreenLayer2andLowRes(EBmpType type) {
// ;; SCREEN L2 [<Page8kNum 0..223>,<offset>[,<palPage8kNum 0..223>,<palOffset>]]
// ;; SCREEN LR [<Page8kNum 0..223>,<offset>[,<palPage8kNum 0..223>,<palOffset>]]
// ;; SCREEN L2_320 [<Page8kNum 0..223>,<offset>[,<palPage8kNum 0..223>,<palOffset>]]
// ;; SCREEN L2_640 [<Page8kNum 0..223>,<offset>[,<palPage8kNum 0..223>,<palOffset>]]
	// check V1.3 features vs V1.2 enforced file version
	if (L2_320x256 == type || L2_640x256 == type) {
		if (2 == nex.reqFileVersion) {
			Error("[SAVENEX] V1.2 was requested with OPEN, but 320x256 or 640x256 screen is V1.3 feature.", NULL, SUPPRESS);
			return;
		}
		nex.minFileVersion = 3;
		nex.h.hiResColour = 0;
	}
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
	size_t pixelDataSize = 0x14000;		// L2_320x256 and L2_640x256 size is default
	if (Layer2 == type) pixelDataSize = 0xC000;
	if (LoRes == type) pixelDataSize = 0x3000;
	if (totalRam < adrPixelData + pixelDataSize) {
		Error("[SAVENEX] pixel data address range is outside of Next memory", bp, SUPPRESS);
		return;
	}
	// extract palette into internal buffer
	if (!dirNexPaletteMem(screenArgs[2], screenArgs[3])) return;	// exit on serious error
	// write palette into file (or update nex.h.screen with NOPAL flag if no palette was defined)
	nex.writePalette();
	// update header loading screen status
	switch (type) {
		case Layer2:		nex.h.screen |= SNexHeader::SCR_LAYER2;		break;
		case LoRes:			nex.h.screen |= SNexHeader::SCR_LORES;		break;
		case L2_320x256:
			nex.h.screen |= SNexHeader::SCR_EXT2;
			nex.h.screen2 = SNexHeader::SCR2_320x256;
			break;
		case L2_640x256:
			nex.h.screen |= SNexHeader::SCR_EXT2;
			nex.h.screen2 = SNexHeader::SCR2_640x256;
			break;
		default:
			break;
	}
	// write pixel data into file - first check if default RAM position should be used to read data
	if (-1 == screenArgs[0]) {
		if (LoRes == type) {	// write first half of LoRes data straight from the VRAM position
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

static void dirNexScreenBmp() {
// ;; SAVENEX SCREEN BMP <filename>[,<savePalette 0/1>[,<paletteOffset 0..15>]]
	const char* const bmpname = GetFileName(lp);
	aint bmpArgs[2] = { 1, -1 };
	if (comma(lp)) {	// empty filename will fall here too, causing syntax error
		const bool optionals[] = {false, true};	// savePalette is mandatory after comma
		if (!getIntArguments<2>(bmpArgs, optionals)) {
			Error("[SAVENEX] expected syntax is BMP <filename>[,<savePalette 0/1>[,<paletteOffset 0..15>]]", bp, SUPPRESS);
			delete[] bmpname;
			return;
		}
	}
	// validate argument values
	if (bmpArgs[0] < 0 || 1 < bmpArgs[0]) {
		Warning("[SAVENEX] savePalette should be 0 or 1 (defaulting to 1)");
		bmpArgs[0] = 1;
	}
	if (bmpArgs[1] < -1 || 15 < bmpArgs[1]) {	// -1 is internal "off" value
		Warning("[SAVENEX] paletteOffset should be in 0..15 range");
	}
	// try to open the actual BMP file
	SBmpFile bmp;
	bool bmpOpened = bmp.open(bmpname);
	if (bmpOpened && other == bmp.type) {
		Error("[SAVENEX] BMP file is not 256x192, 128x96, 320x256 or 640x256", bmpname, SUPPRESS);
		bmpOpened = false;
	}
	delete[] bmpname;
	if (!bmpOpened) return;
	// bmp opened, and some known type, verify details
	if ((-1 != bmpArgs[1]) && (Layer2 == bmp.type || LoRes == bmp.type)) {
		// V1.2 screen types -> no paletteOffset
		Warning("[SAVENEX] BMP paletteOffset is available only for new V1.3 images (320 or 640 x256)");
		bmpArgs[1] = -1;
	}
	// check if V1.3 screens were provided, and if V1.3 is allowed, init internals
	if (256 == bmp.height) {
		if (2 == nex.reqFileVersion) {
			Error("[SAVENEX] V1.2 was requested with OPEN, but 320x256 or 640x256 BMP is V1.3 feature.", NULL, SUPPRESS);
			return;
		} else {
			nex.minFileVersion = 3;
			if (-1 == bmpArgs[1]) bmpArgs[1] = 0;
		}
	}
	// check the palette if it was requested from this bmp and process it
	if (bmpArgs[0]) dirNexPaletteBmp(bmp);
	// palette is written first into file
	nex.writePalette();
	// update header loading screen status
	switch (bmp.type) {
		case Layer2:
			nex.h.screen |= SNexHeader::SCR_LAYER2;
			break;
		case LoRes:
			nex.h.screen |= SNexHeader::SCR_LORES;
			break;
		case L2_320x256:
			nex.h.screen |= SNexHeader::SCR_EXT2;
			nex.h.screen2 = SNexHeader::SCR2_320x256;
			nex.h.hiResColour = bmpArgs[1];
			break;
		case L2_640x256:
			nex.h.screen |= SNexHeader::SCR_EXT2;
			nex.h.screen2 = SNexHeader::SCR2_640x256;
			nex.h.hiResColour = bmpArgs[1];
			break;
		default:
			; // should be unreachable
	}
	// load and write pixel data
	byte* buffer = new byte[641*256];		// buffer to read pixel data +1 write buffer
	if (nullptr == buffer) ErrorOOM();
	// read BMP first line by line into buffer (undid upside-down also)
	bmp.loadPixelData(buffer);
	// write pixel data into file - do transformation for 320/640 x 256 modes
	if (Layer2 == bmp.type || LoRes == bmp.type) {
		const size_t pixelBlockSize = static_cast<size_t>(bmp.width) * static_cast<size_t>(bmp.height);
		if (pixelBlockSize != fwrite(buffer, 1, pixelBlockSize, nex.f)) {
			Error("[SAVENEX] writing pixel data failed", NULL, FATAL);
		}
	} else {
		constexpr size_t h = 256, wB = 320;
		const bool xMul2 = (L2_640x256 == bmp.type);
		byte* const wbuf = buffer + 640 * 256;	// write buffer is at last 256B block
		// transpose data, store them column by column (two columns at time for 640x256)
		for (size_t x = 0; x < wB; ++x) {
			const byte* src = buffer + (xMul2 ? x*2 : x);
			for (size_t y = 0; y < h; ++y) {
				const byte pixel = xMul2 ? (src[0]<<4) | (src[1]&0x0F) : src[0];
				src += bmp.width;
				wbuf[y] = pixel;
			}
			if (h != fwrite(wbuf, 1, h, nex.f)) {
				Error("[SAVENEX] writing pixel data failed", NULL, FATAL);
			}
		}
	}
	delete[] buffer;
}

static void dirNexScreenUlaTimex(byte scrType) {
// ;; SCREEN (SCR|SHC|SHR) [<hiResColour 0..7>]
	// parse argument (only HiRes screen type)
	if (SNexHeader::SCR_HIRES == scrType) {
		aint hiResColor = 0;
		if (ParseExpression(lp, hiResColor)) {
			if (hiResColor < 0 || 7 < hiResColor) Warning("[SAVENEX] value is not in 0..7 range", bp);
			nex.h.hiResColour = (hiResColor&7) << 3;
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

static bool saveBank(aint bankIndex, aint bankNum, bool onlyNonZero = false);

static void dirNexScreenTile() {
// ;; SCREEN TILE <NextReg $6B>,<NextReg $6C>,<NextReg $6E>,<NextReg $6F>[,<AlsoStoreBank5 0/1 = 1>]
	// parse arguments
	aint tileArgs[5] = {0, 0, 0, 0, 1};
	const bool optionals[] = {false, false, false, false, true};
	if (!getIntArguments<5>(tileArgs, optionals)
			|| tileArgs[0] < 0 || 255 < tileArgs[0]
			|| tileArgs[1] < 0 || 255 < tileArgs[1]
			|| tileArgs[2] < 0 || 255 < tileArgs[2]
			|| tileArgs[3] < 0 || 255 < tileArgs[3]
			|| tileArgs[4] < 0 || 1 < tileArgs[4]) {
		Error("[SAVENEX] expected syntax is TILE <NextReg $6B>,<NextReg $6C>,<NextReg $6E>,<NextReg $6F>[,<AlsoStoreBank5 0/1 = 1>]", bp, SUPPRESS);
		return;
	}
	// check file version and set it up to V1.3
	if (2 == nex.reqFileVersion) {
		Error("[SAVENEX] V1.2 was requested with OPEN, but tilemap screen is V1.3 feature.", NULL, SUPPRESS);
		return;
	}
	nex.minFileVersion = 3;
	// write palette into file (or update nex.h.screen with NOPAL flag if no palette was defined)
	nex.writePalette();
	nex.h.screen |= SNexHeader::SCR_EXT2;
	nex.h.screen2 = SNexHeader::SCR2_tilemap;
	nex.h.tilesScrConfig[0] = static_cast<byte>(tileArgs[0]);
	nex.h.tilesScrConfig[1] = static_cast<byte>(tileArgs[1]);
	nex.h.tilesScrConfig[2] = static_cast<byte>(tileArgs[2]);
	nex.h.tilesScrConfig[3] = static_cast<byte>(tileArgs[3]);
	// write Bank 5 into file, if requested/default
	if (0 == tileArgs[4]) return;		// suppressed
	saveBank(getNexBankIndex(5), 5);
}

static void dirNexScreen() {
	if (!nex.canAppend) {
		Error("[SAVENEX] NEX file is not open", NULL, SUPPRESS);
		return;
	}
	if (0 != nex.h.screen) {
		Error("[SAVENEX] screen for this NEX file was already stored", NULL, SUPPRESS);
		return;
	}
	if (-1 != nex.lastBankIndex) {
		Error("[SAVENEX] some bank was already stored (store screen ahead)", NULL, SUPPRESS);
		return;
	}
	SkipBlanks(lp);
	if (cmphstr(lp, "l2")) dirNexScreenLayer2andLowRes(Layer2);
	else if (cmphstr(lp, "lr")) dirNexScreenLayer2andLowRes(LoRes);
	else if (cmphstr(lp, "l2_320")) dirNexScreenLayer2andLowRes(L2_320x256);
	else if (cmphstr(lp, "l2_640")) dirNexScreenLayer2andLowRes(L2_640x256);
	else if (cmphstr(lp, "bmp")) dirNexScreenBmp();
	else if (cmphstr(lp, "scr")) dirNexScreenUlaTimex(SNexHeader::SCR_ULA);
	else if (cmphstr(lp, "shc")) dirNexScreenUlaTimex(SNexHeader::SCR_HICOL);
	else if (cmphstr(lp, "shr")) dirNexScreenUlaTimex(SNexHeader::SCR_HIRES);
	else if (cmphstr(lp, "tile")) dirNexScreenTile();
	else Error("[SAVENEX] unknown screen type (types: BMP, L2, L2_320, L2_640, LR, SCR, SHC, SHR, TILE)", lp, SUPPRESS);
}

static void dirNexCopper() {
// ;; SAVENEX COPPER <Page8kNum 0..223>,<offset>
	if (!nex.canAppend) {
		Error("[SAVENEX] NEX file is not open", NULL, SUPPRESS);
		return;
	}
	if (nex.reqFileVersion == 2) {
		Error("[SAVENEX] V1.2 was requested with OPEN, but COPPER is V1.3 feature.", NULL, SUPPRESS);
		return;
	}
	if (-1 != nex.lastBankIndex) {
		Error("[SAVENEX] some bank was already stored (store copper ahead)", NULL, SUPPRESS);
		return;
	}
	nex.minFileVersion = 3;		// V1.3 detected
	// parse arguments
	aint screenArgs[2] = {0, 0};
	const bool optionals[] = {false, false};
	if (!getIntArguments<2>(screenArgs, optionals)
			|| screenArgs[0] < 0 || SNexHeader::MAX_PAGE <= screenArgs[0]) {
		Error("[SAVENEX] expected syntax is COPPER <Page8kNum 0..223>,<offset>", bp, SUPPRESS);
		return;
	}
	// warn about invalid values
	const size_t totalRam = Device->GetMemoryOffset(Device->PagesCount, 0);
	size_t adrCopperData = Device->GetMemoryOffset(screenArgs[0], screenArgs[1]);
	if (totalRam < adrCopperData + SNexHeader::COPPER_SIZE) {
		Error("[SAVENEX] copper data address range is outside of Next memory", bp, SUPPRESS);
		return;
	}
	// adjust header and remember the copper data for saving them ahead of first bank
	nex.h.hasCopperCode = 1;
	if (nullptr == nex.copper) nex.copper = new byte[SNexHeader::COPPER_SIZE];
	memcpy(nex.copper, Device->Memory + adrCopperData, SNexHeader::COPPER_SIZE);
}

static bool saveBank(aint bankIndex, aint bankNum, bool onlyNonZero) {
	if (bankNum < 0 || SNexHeader::MAX_BANK <= bankNum) return false;
	if (bankIndex <= nex.lastBankIndex) {
		ErrorInt("[SAVENEX] it's too late to save this bank (correct order: 5, 2, 0, 1, 3, 4, 6, ...)",
					bankNum, SUPPRESS);
		return false;
	}
	nex.updateIfAheadFirstBankSave();
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
	if (!nex.canAppend) {
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
	if (!nex.canAppend) {
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
	if (!nex.canAppend) {
		Error("[SAVENEX] NEX file is not open", NULL, SUPPRESS);
		return;
	}
	// update V1.3 banksOffset in case there was no bank stored at all (before appending binary data!)
	nex.updateIfAheadFirstBankSave();
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
	else if (cmphstr(lp, "cfg3")) dirNexCfg3();
	else if (cmphstr(lp, "cfg")) dirNexCfg();
	else if (cmphstr(lp, "bar")) dirNexBar();
	else if (cmphstr(lp, "palette")) dirNexPalette();
	else if (cmphstr(lp, "screen")) dirNexScreen();
	else if (cmphstr(lp, "copper")) dirNexCopper();
	else if (cmphstr(lp, "bank")) dirNexBank();
	else if (cmphstr(lp, "auto")) dirNexAuto();
	else if (cmphstr(lp, "close")) dirNexClose();
	else Error("[SAVENEX] unknown command (commands: OPEN, CORE, CFG, BAR, SCREEN, BANK, AUTO, CLOSE)", lp, SUPPRESS);
}
