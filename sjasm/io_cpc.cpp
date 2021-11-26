/*

  SjASMPlus Z80 Cross Compiler - modified - SAVECPCSNA extension

  Copyright (c) 2006 Sjoerd Mastijn (original SW)

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

// io_cpc.cpp

#include "sjdefs.h"
#include "io_cpc_ldrs.h"

//FIXME before v1.18.4:
// - consider "cdtname" instead of "filename" in error/args hints
// - getContigRAM seems to be doing too much about device memory, check if some other internal Device API can't simplify it
// - increase test coverage

//
// Amstrad CPC snapshot file saving (SNA)
//

namespace
{
	// report error and close the file
	static int writeError(const char* fname, FILE*& fileToClose) {
		Error("[SAVECPCSNA] Write error (disk full?)", fname, IF_FIRST);
		fclose(fileToClose);
		return 0;
	}

	static bool isCPC6128() {
		return strcmp(DeviceID, "AMSTRADCPC464");
	}

	static word getCPCMemoryDepth() {
		return Device->PagesCount * 0x10;
	}

	template <int argsN> static bool getIntArguments(aint(&args)[argsN], const bool(&argOptional)[argsN]) {	
		for (int i = 0; i < argsN; ++i) {
			if (0 < i && !comma(lp)) return argOptional[i];
			aint val;				// temporary variable to preserve original value in case of error
			if (!ParseExpression(lp, val)) return (0 == i) && argOptional[i];
			args[i] = val;
		}
		return !comma(lp);
	}
}

static int SaveSNA_CPC(const char* fname, word start) {
	// for Lua
	if (!DeviceID) {
		Error("SAVECPCSNA only allowed in real device emulation mode (See DEVICE)"); return 0;
	}
	else if (!IsAmstradCPCDevice(DeviceID)) {
		Error("[SAVECPCSNA] Device must be AMSTRADCPC464 or AMSTRADCPC6128."); return 0;
	}

	FILE* ff;
	if (!FOPEN_ISOK(ff, fname, "wb")) {
		Error("[SAVECPCSNA] Error opening file", fname, FATAL);
	}

	// format:  http://cpctech.cpc-live.com/docs/snapshot.html
	constexpr int SNA_HEADER_SIZE = 256;
	const char magic[8] = { 'M', 'V', ' ', '-', ' ', 'S', 'N', 'A' };
	// basic rom initialized pens
	const byte ga_pens[17] = { 0x04, 0x0A, 0x13, 0x0C, 0x0B, 0x14, 0x15, 0x0D, 0x06, 0x1E, 0x1F, 0x07, 0x12, 0x19, 0x04, 0x17, 0x04 };
	// crtc set to standard mode 1 screen @ $C000
	const byte crtc_defaults[18] = { 
		0x3F,		// h total
		0x28,		// h displayed
		0x2E,		// h sync pos
		0x8E,		// h/v sync widths
		0x26,		// v total (height)
		0x00,		// v adjust
		0x19,		// v displayed (height)
		0x1E,		// v sync pos
		0x00,		// interlace & skew
		0x07,		// max raster
		0x00, 0x00, // cursor start
		0x30, 0x00, // display (xxPPSSOO) -> 0xC000 based screen
		0x00, 0x00, // cursor addr
		0x00, 0x00  // light pen
	};
	// psg defaults as initialized by ROM
	const byte psg_defaults[16] = { 0x0E, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };

	// init header
	byte snbuf[SNA_HEADER_SIZE];
	memset(snbuf, 0, SNA_HEADER_SIZE);
	// copy over the magic marker
	memcpy(snbuf, magic, sizeof(magic));
	snbuf[0x10] = 2; // v2 file format

	// v1 format fields
	snbuf[0x1B] = 0; snbuf[0x1C] = 0; // ensure interrupts are disabled
	snbuf[0x21] = 0xF0; snbuf[0x22] = 0xBF; // set the sp to $BFF0
	snbuf[0x23] = start & 0xFF; snbuf[0x24] = start >> 8; // pc set to start addr
	snbuf[0x25] = 1; // im = 1
	// set the pens to the defaults
	memcpy(snbuf + 0x2F, ga_pens, sizeof(ga_pens));
	// multi-config (RMR: 100I ULVM)
	snbuf[0x40] = 0b1000'01'01; // Upper ROM paged out, Lower ROM paged in, Mode 1
	// RAM config (MMR see https://www.grimware.org/doku.php/documentations/devices/gatearray#mmr)
	snbuf[0x41] = 0; // default RAM paging
	// set the crtc registers to the default values
	snbuf[0x42] = 0x0D;	// selected crtc reg
	memcpy(snbuf + 0x43, crtc_defaults, sizeof(crtc_defaults));
	// PPI
	snbuf[0x59] = 0x82;	// PPI control port default
	// Set the PSG registers to sensible defaults
	memcpy(snbuf + 0x5B, psg_defaults, sizeof(psg_defaults));

	word memdepth = getCPCMemoryDepth();
	snbuf[0x6B] = memdepth & 0xFF;
	snbuf[0x6C] = memdepth >> 8;

	// v2 format fields
	snbuf[0x6D] = isCPC6128() ? 2 : 0;	// machine type (0 = 464, 1 = 664, 2 = 6128)

	if (fwrite(snbuf, 1, SNA_HEADER_SIZE, ff) != SNA_HEADER_SIZE) {
		return writeError(fname, ff);
	}

	// Write the pages out in order
	for (int page = 0; page < Device->PagesCount; ++page) {
		if ((aint)fwrite(Device->GetPage(page)->RAM, 1, Device->GetPage(page)->Size, ff) != Device->GetPage(page)->Size) {
			return writeError(fname, ff);
		}
	}

	fclose(ff);
	return 1;
}

void dirSAVECPCSNA() {
	if (pass != LASTPASS) {
		SkipToEol(lp);
		return;
	}
	std::unique_ptr<char[]> fnaam(GetOutputFileName(lp));
	int start = StartAddress;
	if (anyComma(lp)) {
		aint val;
		if (ParseExpression(lp, val)) {
			if (0 <= start) Warning("[SAVECPCSNA] Start address was also defined by END, SAVECPCSNA argument used instead");
			if (0 <= val) {
				start = val;
			}
			else {
				Error("[SAVECPCSNA] Negative values are not allowed", bp, SUPPRESS); return;
			}
		}
		else {
			return;
		}
	}
	if (start < 0) {
		Error("[SAVECPCSNA] No start address defined", bp, SUPPRESS); return;
	}

	if (!SaveSNA_CPC(fnaam.get(), start))
		Error("[SAVECPCSNA] Error writing file (Disk full?)", bp, IF_FIRST);
}

//
// Amstrad CPC tape file saving (CDT)
//

enum ECDTHeadlessFormat { AMSTRAD, SPECTRUM };

namespace CDTUtil {

	static constexpr word DefaultPause = 1000;
	static constexpr byte BlockTypeReg = 0x0A;
	static constexpr byte BlockTypeHeader = 0x2C;
	static constexpr byte BlockTypeData = 0x16;

	static constexpr byte FileTypeBASIC = (0 << 1);
	static constexpr byte FileTypeBINARY = (1 << 1);
	static constexpr byte FileTypeSCREEN = (2 << 1);

	/* CRC polynomial: X^16+X^12+X^5+1 */
	static unsigned int crcupdate(word c, byte b) {
		constexpr unsigned int poly = 4129;
		unsigned int aux = c ^ (b << 8);
		for (aint i = 0; i < 8; i++) {
			if (aux & 0x8000) {
				aux = (aux << 1) ^ poly;
			}
			else {
				aux <<= 1;
			}
		}
		return aux;
	}

	static void writeChunkedData(const char* fname, const byte* buf, const aint buflen, word pauseAfter, byte sync) {
		constexpr aint chunkLen = 256;

		const aint chunkCount = (buflen + 255) >> 8;
		const aint dataLen = (chunkCount * chunkLen)	// data size (in chunks)
			+ (chunkCount * 2)	// crcs
			+ 5; // sync byte + trailer

		std::unique_ptr<byte[]> chunkedData(new byte[dataLen]);
		byte* wptr = chunkedData.get(); // write ptr
		const byte* rptr = buf; // read ptr
		// build the buffer
		*(wptr++) = sync; // sync pattern

		aint remaining = buflen;
	
		// N chunks of 256 bytes with a 2 byte checksum at the end
		for (aint i = 0; i < chunkCount; ++i) {		
			if (remaining < chunkLen) {
				memcpy(wptr, rptr, remaining);
				memset(wptr + remaining, 0, chunkLen - remaining);
				rptr += remaining;
				remaining = 0;
			}
			else {
				memcpy(wptr, rptr, chunkLen);
				rptr += chunkLen;
				remaining -= chunkLen;
			}

			unsigned int check = 0xFFFF;
			for (aint n = 0; n < chunkLen; ++n) {
				check = crcupdate(check, wptr[n]);
			}

			wptr += chunkLen;
			// append block crc
			check ^= 0xFFFF;
			*(wptr++) = check >> 8;
			*(wptr++) = check & 0xFF;
		}

		// 4 trailer bytes of 0xFF
		const byte trailer[] = { 0xFF, 0xFF, 0xFF, 0xFF };
		memcpy(wptr, trailer, sizeof(trailer));

		// save block
		STZXTurboBlock turbo;
		turbo.PilotPulseLen = 0x091A;
		turbo.FirstSyncLen = 0x048D;
		turbo.SecondSyncLen = 0x048D;
		turbo.ZeroBitLen = 0x048D;
		turbo.OneBitLen = 0x091A;
		turbo.PilotToneLen = 0x1000;
		turbo.LastByteUsedBits = 0x08;
		turbo.PauseAfterMs = pauseAfter;

		TZX_AppendTurboBlock(fname, chunkedData.get(), dataLen, turbo);
	}

	static void writeTapeFile(const char* fname, const char* tfname, byte fileType, const byte* buf, aint buflen, word memaddr, word startaddr, word pause) {
		constexpr aint blocksize = 2048;
		constexpr aint headerlen = 64;

		byte hbuf[headerlen];
		memset(hbuf, 0, headerlen);
		/*
		   0   16  Filename       Name of the file, padded with nulls
		  16    1  Block number   The first block is 1, numbers are consecutive
		  17    1  Last block     A non-zero value means that this is the last block of a file
		  18    1  File type      A value recording  the type of the file
		  19    2  Data length    The number of data bytes in the data record
		  21    2  Data location  Where the data was written from originally
		  23    1  First block    A non-zero value means that this is the first block of a file
		  24    2  Logical length This is the total length of the file in bytes
		  26    2  Entry address  The execution address for machine code programs
		*/
		
		// ensure name is <= 16
		aint tapefname_len = strlen(tfname);
		if (tapefname_len > 16) {
			tapefname_len = 16;
		}

		// copy tape file name (16 bytes)
		memcpy(hbuf, tfname, tapefname_len);

		// init header
		hbuf[16] = 1; // block 1
		hbuf[18] = fileType;
		hbuf[24] = buflen & 0xFF;	// logical len (size of whole file)
		hbuf[25] = buflen >> 8;
		hbuf[26] = startaddr & 0xFF;
		hbuf[27] = startaddr >> 8; // entry addr

		word memloc = memaddr;
		aint remaining = buflen;
		byte block = 1;
		const byte* rptr = buf;

		// split the file into blocks of up to 2048 bytes, each with a header and a payload
		while (remaining) {
			hbuf[16] = block;	// write block num
			hbuf[21] = memloc & 0xFF; // where's this block going in memory?
			hbuf[22] = memloc >> 8;
			hbuf[23] = block == 1 ? 0xFF : 0x00;	// first block flag

			aint dlen = remaining;
			if (remaining > blocksize) {
				dlen = blocksize;
				hbuf[17] = 0x00;	// more blocks to come
			}
			else {
				hbuf[17] = 0xFF;	// last block
			}

			// write data len (size of block)
			hbuf[19] = dlen & 0xFF;
			hbuf[20] = dlen >> 8;

			writeChunkedData(fname, hbuf, headerlen, 10, BlockTypeHeader); // header
			writeChunkedData(fname, rptr, dlen, pause, BlockTypeData);	// data
			rptr += dlen;
			memloc += dlen;
			remaining -= dlen;
			++block;
		}
	}

	static void writeBASICLoader(const char* fname, byte screenMode, const byte* palette) {
		constexpr byte mode_values[] = { 0x0E, 0x0F, 0x10 };
		byte border = 0;
		border = *palette;
		// Border is always the first entry in the palette
		++palette;

		// BASIC number encoding format for the palette entries
		byte p[32];
		for (aint i = 0, n = 0; i < 16; ++i, n+=2) {
			p[n] = (palette[i] / 10) + '0';
			p[n+1] = (palette[i] % 10) + '0';
		}

		const word callad = SaveCDT_AmstradCPC464_ORG;
		const word himem = callad - 1; // himem is one byte lower than the program we load

		// BASIC loader to set the screen mode, border color, palette, and then load the asm loader and execute it
		const byte basic[] = {
			// Line format <Line Len (int16)> <line no (int16)> <tokens...> <0x00>
			//
			//		10		MODE		N						:		CLS  :     BORDER		N
			15, 00, 10, 00, 0xAD, 0x20, mode_values[screenMode], 0x01, 0x8A, 0x01, 0x82, 0x20, 0x19, border, 0x00,
			//		20		DATA [16 bytes of int8]
			54, 00, 20, 00, 0x8C, 0x20, 
				p[0], p[1], ',', p[2], p[3], ',', p[4], p[5], ',', p[6], p[7], ',',
				p[8], p[9], ',', p[10], p[11], ',', p[12], p[13], ',', p[14], p[15], ',',
				p[16], p[17], ',', p[18], p[19], ',', p[20], p[21], ',', p[22], p[23], ',',
				p[24], p[25], ',', p[26], p[27], ',', p[28], p[29], ',', p[30], p[31], 0x00,
			//		30		FOR			i						=	  0			  TO		  15
			18, 00,	30, 00, 0x9E, 0x20, 0x0D, 0x00, 0x00, 0xE9, 0xEF, 0x0E, 0x20, 0xEC, 0x20, 0x19, 0x0F, 0x00,
			//		40		READ		v						:	  INK		  	i					  ,           v                       ,                             v
			30, 00, 40, 00, 0xC3, 0x20, 0x0D, 0x00, 0x00, 0xF6, 0x01, 0xA2, 0x20, 0x0D, 0x00, 0x00, 0xE9, 0x2C, 0x20, 0x0D, 0x00, 0x00, 0xF6, 0x2C, 0x20, 0x0D, 0x00, 0x00, 0xF6, 0x00,
			//		50		NEXT		i
			11, 00,	50, 00, 0xB0, 0x20, 0x0D, 0x00, 0x00, 0xE9, 0x00,
			//		60		MEMORY		&NNNN			  :		LOAD 
			20, 00, 60, 00, 0xAA, 0x20, 0x1C, himem & 0xFF, himem >> 8, 0x01,	0xA8, 0x20, 0x22, '!', 'c', 'o', 'd', 'e', 0x22, 0x00,
			//		70		CALL
			10, 00, 70, 00, 0x83, 0x20, 0x1C, callad & 0xFF, callad >> 8, 0x00,
			// EOF
			00, 00 
		};
		constexpr aint basiclen = sizeof(basic);
		writeTapeFile(fname, "LOADER", FileTypeBASIC, basic, basiclen, 0x0170, 0x0000, DefaultPause);
	}

	static void writeUserProgram(const char* fname, const char* tapefname, const byte* buf, aint buflen, word baseAddr, word startAddr) {
		writeTapeFile(fname, tapefname, FileTypeBINARY, buf, buflen, baseAddr, startAddr, DefaultPause);
	}

	static bool hasScreen() {
		const CDevicePage* page = Device->GetPage(3);
		const byte* ptr = page->RAM;
		for (int i = 0; i < page->Size; ++i) {
			if (*ptr != 0) {
				return true;
			}
			++ptr;
		}
		return false;
	}

	static aint calcRAMStart(const byte* ram, aint ramlen) {
		aint startAddr = 0x0000;
		const byte* ptr = ram;
		for (int i = 0; i < ramlen; ++i) {
			if (*ptr != 0) {
				return startAddr + i;
			}
			++ptr;
		}
		return 0xFFFF;
	}

	static aint calcRAMLength(const byte* ram, aint ramlen) {
		if (!ramlen) {
			return 0x0000;
		}
		const byte* ptr = ram + ramlen - 1;
		while (ramlen) {
			if (ptr < ram) {
				return 0x0000;
			}

			if (*ptr != 0) {
				return ramlen;
			}
			--ptr;
			--ramlen;
		}
		return 0x0000;
	}

	static std::unique_ptr<byte[]> getContigRAM(aint startAddr, aint length) {
		std::unique_ptr<byte[]> data(new byte[length]);
		byte* bptr = data.get();
		// copy the basic into our buffer
		CDeviceSlot* S;
		for (aint i = 0, ptr; i < Device->SlotsCount; i++) {
			S = Device->GetSlot(i);
			if (S->Address + S->Size <= startAddr) continue;
			if (length <= 0) break;

			ptr = (startAddr - S->Address);
			while (length && ptr < S->Size) {
				*bptr = S->Page->RAM[ptr];
				++bptr;
				++startAddr;
				++ptr;
				--length;
			}
		}
		return data;
	}

	static constexpr byte basicToHWColor[] = {
		0x54, 0x44, 0x55, 0x5C,	0x58, 0x5D,	0x4C, 0x45,
		0x4D, 0x56,	0x46, 0x57,	0x5E, 0x40,	0x5F, 0x4E,
		0x47, 0x4F,	0x52, 0x42,	0x53, 0x5A,	0x59, 0x5B,
		0x4A, 0x43,	0x4B, 0x41,	0x48, 0x49,	0x50, 0x51,
	};
}

static void createCDTDump464(const char* fname, aint startAddr, byte screenMode, const byte* palette) {

	byte* ramptr;
	aint ram_size = 0xC000; // 3 x 16K pages (eg: excl screen)
	std::unique_ptr<byte[]> ram(new byte[ram_size]);
	ramptr = ram.get();
	memcpy(ramptr + 0x0000, Device->GetPage(0)->RAM, 0x4000);
	memcpy(ramptr + 0x4000, Device->GetPage(1)->RAM, 0x4000);
	memcpy(ramptr + 0x8000, Device->GetPage(2)->RAM, 0x4000);

	if (screenMode > 2) {
		screenMode = 0xFF; // Turn mode & palette select off
	}
	bool hasScreen = CDTUtil::hasScreen();
	aint ramBase = CDTUtil::calcRAMStart(ramptr, ram_size);
	aint ramEnd = CDTUtil::calcRAMLength(ramptr, ram_size);

	if (ramEnd == 0x0000) {
		Error("[SAVECDT] Could not determine the end of the program", nullptr, SUPPRESS); return;
	}
	if (ramBase == 0xFFFF) {
		Error("[SAVECDT] Could not determine the start of the program", nullptr, SUPPRESS); return;
	}

	aint ramUsed = ramEnd - ramBase;

	if (startAddr < 0) {
		startAddr = ramBase;
	}

	// construct the asm loader
	byte loader[SaveCDT_AmstradCPC464_Len];
	memcpy(loader, SaveCDT_AmstradCPC464, SaveCDT_AmstradCPC464_Len);

	// loader settings
	loader[SaveCDT_AmstradCPC464_Settings + 0x0] = hasScreen;
	loader[SaveCDT_AmstradCPC464_Settings + 0x1] = startAddr & 0xFF;
	loader[SaveCDT_AmstradCPC464_Settings + 0x2] = startAddr >> 8;

	loader[SaveCDT_AmstradCPC464_Settings + 0x3] = ramBase & 0xFF;
	loader[SaveCDT_AmstradCPC464_Settings + 0x4] = ramBase >> 8;

	loader[SaveCDT_AmstradCPC464_Settings + 0x5] = ramUsed & 0xFF;
	loader[SaveCDT_AmstradCPC464_Settings + 0x6] = ramUsed >> 8;

	// Create an empty file with a 2s pause to start with
	TZX_CreateEmpty(fname);
	TZX_AppendPauseBlock(fname, 2000);

	// append a CPC basic loader which will run the asm loader
	CDTUtil::writeBASICLoader(fname, screenMode, palette);

	// append the asm loader program
	CDTUtil::writeUserProgram(fname, "CODE", loader, SaveCDT_AmstradCPC464_Len, SaveCDT_AmstradCPC464_ORG, SaveCDT_AmstradCPC464_ORG);

	// append screen if we have one
	if (hasScreen) {
		CDTUtil::writeChunkedData(fname, Device->GetPage(3)->RAM, Device->GetPage(3)->Size, CDTUtil::DefaultPause, CDTUtil::BlockTypeData);
	}
	// finally write the main code
	CDTUtil::writeChunkedData(fname, ramptr + ramBase, ramUsed, CDTUtil::DefaultPause, CDTUtil::BlockTypeData);
}

static void createCDTDump6128(const char* fname, aint startAddr, byte screenMode, const byte* palette) {

	byte* ramptr;
	aint ram_size = 0xC000; // 3 x 16K pages (eg: excl screen)
	std::unique_ptr<byte[]> ram(new byte[ram_size]);
	ramptr = ram.get();
	memcpy(ramptr + 0x0000, Device->GetPage(0)->RAM, 0x4000);
	memcpy(ramptr + 0x4000, Device->GetPage(1)->RAM, 0x4000);
	memcpy(ramptr + 0x8000, Device->GetPage(2)->RAM, 0x4000);

	if (screenMode > 2) {
		screenMode = 0xFF; // Turn mode & palette select off
	}
	bool hasScreen = CDTUtil::hasScreen();
	aint ramBase = CDTUtil::calcRAMStart(ramptr, ram_size);
	aint ramEnd = CDTUtil::calcRAMLength(ramptr, ram_size);

	if (ramEnd == 0x0000) {
		Error("[SAVECDT] Could not determine the end of the program", nullptr, SUPPRESS); return;
	}
	if (ramBase == 0xFFFF) {
		Error("[SAVECDT] Could not determine the start of the program", nullptr, SUPPRESS); return;
	}

	aint ramUsed = ramEnd - ramBase;

	if (startAddr < 0) {
		startAddr = ramBase;
	}

	// the max possible length for the loader
	constexpr aint max_loader_len = SaveCDT_AmstradCPC6128_Len + (SaveCDT_AmstradCPC6128_PageEntrySize * 4);
	// construct the asm loader
	byte loader[max_loader_len];
	memcpy(loader, SaveCDT_AmstradCPC6128, SaveCDT_AmstradCPC6128_Len);
	aint loader_actual_len = SaveCDT_AmstradCPC6128_Len;

	// loader settings
	loader[SaveCDT_AmstradCPC6128_Settings + 0x0] = hasScreen;
	loader[SaveCDT_AmstradCPC6128_Settings + 0x1] = startAddr & 0xFF;
	loader[SaveCDT_AmstradCPC6128_Settings + 0x2] = startAddr >> 8;

	loader[SaveCDT_AmstradCPC6128_Settings + 0x3] = ramBase & 0xFF;
	loader[SaveCDT_AmstradCPC6128_Settings + 0x4] = ramBase >> 8;

	loader[SaveCDT_AmstradCPC6128_Settings + 0x5] = ramUsed & 0xFF;
	loader[SaveCDT_AmstradCPC6128_Settings + 0x6] = ramUsed >> 8;

	byte* loader_pages = loader + SaveCDT_AmstradCPC6128_Pages;
	byte* loader_entries = loader_pages + 1;

	unsigned char* pages_ram[4];
	aint pages_len[4];
	aint pages_start[4];
	aint count = 0;

	// Ignore the lower 64K at this time!
	for (aint i = 4; i < Device->PagesCount; i++) {
		{
			// Calc start and end of this block
			aint base = CDTUtil::calcRAMStart(Device->GetPage(i)->RAM, 0x4000);
			aint length = CDTUtil::calcRAMLength(Device->GetPage(i)->RAM, 0x4000);

			if (length == 0 || base == 0xFFFF) {
				continue;
			}

			loader_entries[0] = i;	// configuration (4-7)
			loader_entries[1] = base & 0xFF;
			loader_entries[2] = (base >> 8) & 0xFF;
			loader_entries[3] = length & 0xFF;
			loader_entries[4] = (length >> 8) & 0xFF;

			loader_actual_len += SaveCDT_AmstradCPC6128_PageEntrySize;
			loader_entries += SaveCDT_AmstradCPC6128_PageEntrySize;

			pages_ram[count] = Device->GetPage(i)->RAM;
			pages_start[count] = base;
			pages_len[count] = length;

			++count;
		}
	}

	loader_pages[0] = count;

	// Create an empty file with a 2s pause to start with
	TZX_CreateEmpty(fname);
	TZX_AppendPauseBlock(fname, 2000);

	// append a CPC basic loader which will run the asm loader
	CDTUtil::writeBASICLoader(fname, screenMode, palette);

	// append the asm loader program
	CDTUtil::writeUserProgram(fname, "CODE", loader, loader_actual_len, SaveCDT_AmstradCPC6128_ORG, SaveCDT_AmstradCPC6128_ORG);

	// append screen if we have one
	if (hasScreen) {
		CDTUtil::writeChunkedData(fname, Device->GetPage(3)->RAM, Device->GetPage(3)->Size, CDTUtil::DefaultPause, CDTUtil::BlockTypeData);
	}

	// Write each of the pages
	for (aint i = 0; i < count; ++i) {
		CDTUtil::writeChunkedData(fname, pages_ram[i] + pages_start[i], pages_len[i], CDTUtil::DefaultPause, CDTUtil::BlockTypeData);
	}

	// Now drop the rest of the low 64k
	CDTUtil::writeChunkedData(fname, ramptr + ramBase, ramUsed, CDTUtil::DefaultPause, CDTUtil::BlockTypeData);
}

static void SaveCDT_SnapshotWithPalette(const char* fname, aint startAddr, byte screenMode, const byte* palette) {
	isCPC6128() ?
		createCDTDump6128(fname, startAddr, screenMode, palette) :
		createCDTDump464(fname, startAddr, screenMode, palette);
}

static void SaveCDT_Snapshot(const char* fname, aint startAddr) {
	// Default mode after loading from BASIC
	constexpr byte mode = 1;
	// Default ROM palette
	constexpr byte palette[] = {
		1,
		01, 24, 20, 06, 26, 00, 02, 8,
		10, 12, 14, 16, 18, 22, 24, 16,
	};
	SaveCDT_SnapshotWithPalette(fname, startAddr, mode, palette);
}

static void SaveCDT_BASIC(const char* fname, const char* tfname, aint startAddr, aint length) {
	std::unique_ptr<byte[]> data(CDTUtil::getContigRAM(startAddr, length));

	CDTUtil::writeTapeFile(fname, tfname, CDTUtil::FileTypeBASIC, data.get(), length, startAddr, 0x0000, CDTUtil::DefaultPause);
}

static void SaveCDT_Code(const char* fname, const char* tfname, aint startAddr, aint length, aint entryAddr) {
	if (entryAddr < 0) {
		entryAddr = startAddr & 0xFFFF;
	}

	std::unique_ptr<byte[]> data(CDTUtil::getContigRAM(startAddr, length));
	CDTUtil::writeTapeFile(fname, tfname, CDTUtil::FileTypeBINARY, data.get(), length, startAddr, entryAddr, CDTUtil::DefaultPause);
}

static void SaveCDT_Headless(const char* fname, aint startAddr, aint length, byte sync, ECDTHeadlessFormat format) {
	std::unique_ptr<byte[]> data(CDTUtil::getContigRAM(startAddr, length));

	if (format == ECDTHeadlessFormat::AMSTRAD) CDTUtil::writeChunkedData(fname, data.get(), length, CDTUtil::DefaultPause, sync);
	else if (format == ECDTHeadlessFormat::SPECTRUM) TZX_AppendStandardBlock(fname, data.get(), length, CDTUtil::DefaultPause, sync);
	else Error("Unknown mode specified. Expected 0 (CPC) or 1 (Spectrum).");
}

typedef void (*savecdt_command_t)(const char*);

// Creates a CDT tape file of a full memory snapshot, with loader
static void dirSAVECDTFull(const char* cdtname) {
	constexpr const char* argerr = "[SAVECDT] Invalid args. SAVECDT FULL <filename>[,<startaddr>,<screenmode>,<border>,<ink0>...<ink15>]";

	aint args[] = {
		StartAddress,
		0xFF, 0, // mode, border
		0, 0, 0, 0, 0, 0, 0, 0, // palette
		0, 0, 0, 0, 0, 0, 0, 0,
	};

	bool opt[] = {
		false,
		true, true,
		true, true, true, true, true, true, true, true,
		true, true, true, true, true, true, true, true,
	};

	if (anyComma(lp) && !getIntArguments<19>(args, opt)) {
		Error(argerr, lp, SUPPRESS); return;
	}

	if (args[1] != 0xFF) {
		byte palette[17];
		for (aint i = 0; i < 17; ++i) {
			palette[i] = args[2 + i];
		}

		SaveCDT_SnapshotWithPalette(cdtname, args[0], args[1], palette);
	}
	else {
		SaveCDT_Snapshot(cdtname, args[0]);
	}
}

static void dirSAVECDTEmpty(const char* cdtname) {
	// EMPTY <filename>
	TZX_CreateEmpty(cdtname);
}

static void dirSAVECDTBasic(const char* cdtname) {
	constexpr const char* argerr = "[SAVECDT] Invalid args. SAVECDT BASIC <filename>,<fileintapeheader>,<start>,<length>";

	if (!anyComma(lp)) {
		Error(argerr, lp, SUPPRESS); return;
	}

	std::unique_ptr<char[]> tfname(GetFileName(lp));	
	if (!anyComma(lp)) {
		Error(argerr, lp, SUPPRESS); return;
	}

	aint args[] = { StartAddress, 0 };
	bool opt[] = { false, false };
	if (!getIntArguments<2>(args, opt)) {
		Error(argerr, lp, SUPPRESS); return;
	}

	word start = args[0];
	word length = args[1];

	SaveCDT_BASIC(cdtname, tfname.get(), start, length);
}

static void dirSAVECDTCode(const char* cdtname) {
	constexpr const char* argerr = "[SAVECDT] Invalid args. SAVECDT CODE <filename>,<fileintapeheader>,<start>,<length>[,<customstartaddress>]";

	if (!anyComma(lp)) {
		Error(argerr, lp, SUPPRESS); return;
	}

	std::unique_ptr<char[]> tfname(GetFileName(lp));
	if (!anyComma(lp)) {
		Error(argerr, lp, SUPPRESS); return;
	}

	aint args[] = { StartAddress, 0, -1 };
	bool opt[] = { false, false, true };
	if (!getIntArguments<3>(args, opt)) {
		Error(argerr, lp, SUPPRESS); return;
	}

	word start = args[0];
	word length = args[1];
	aint customStart = args[2];

	SaveCDT_Code(cdtname, tfname.get(), start, length, customStart);
}

static void dirSAVECDTHeadless(const char* cdtname) {
	constexpr const char* argerr = "[SAVECDT] Invalid args. SAVECDT HEADLESS <filename>,<start>,<length>[,<sync>,<format>]";

	if (!anyComma(lp)) {
		Error(argerr, lp, SUPPRESS); return;
	}

	aint args[] = { StartAddress, 0, CDTUtil::BlockTypeData, 0 };
	bool opt[] = { false, false, true, true };
	if (!getIntArguments<4>(args, opt)) {
		Error(argerr, lp, SUPPRESS); return;
	}

	word start = args[0];
	word length = args[1];
	byte sync = args[2];

	ECDTHeadlessFormat format;
	switch (args[3]) {
	case 0:
		format = ECDTHeadlessFormat::AMSTRAD;
		break;
	case 1:
		format = ECDTHeadlessFormat::SPECTRUM;
		break;
	default:
		Error("[SAVECDT HEADLESS] invalid format flag. Expected 0 (AMSTRAD) or 1 (SPECTRUM).", NULL, SUPPRESS); return;
	}

	SaveCDT_Headless(cdtname, start, length, sync, format);
}

static void cdtParseFnameAndExecuteCmd(savecdt_command_t command_fn) {
	std::unique_ptr<char[]> cdtname(GetOutputFileName(lp));
	if (cdtname[0]) command_fn(cdtname.get());
	else Error("[SAVECDT] CDT file name is empty", bp, SUPPRESS);
}

void dirSAVECDT() {
	if (pass != LASTPASS) {
		SkipToEol(lp);
		return;
	}
	if (!IsAmstradCPCDevice(DeviceID)) {
		Error("[SAVECDT] is allowed only in AMSTRADCPC464 or AMSTRADCPC6128 device mode", NULL, SUPPRESS);
		return;
	}
	SkipBlanks(lp);
	if (cmphstr(lp, "full")) cdtParseFnameAndExecuteCmd(dirSAVECDTFull);
	else if (cmphstr(lp, "empty")) cdtParseFnameAndExecuteCmd(dirSAVECDTEmpty);
	else if (cmphstr(lp, "basic")) cdtParseFnameAndExecuteCmd(dirSAVECDTBasic);
	else if (cmphstr(lp, "code")) cdtParseFnameAndExecuteCmd(dirSAVECDTCode);
	else if (cmphstr(lp, "headless")) cdtParseFnameAndExecuteCmd(dirSAVECDTHeadless);
	else Error("[SAVECDT] unknown command (commands: FULL, EMPTY, BASIC, CODE, HEADLESS)", lp, SUPPRESS);	
}

// eof io_cpc.cpp
