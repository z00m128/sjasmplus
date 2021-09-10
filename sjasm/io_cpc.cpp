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

}

int SaveSNA_CPC(const char* fname, word start) {
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
	for (int i = 0; i < 17; ++i)
		snbuf[0x2F + i] = ga_pens[i];
	// multi-config (RMR: 100I ULVM)
	snbuf[0x40] = 0b1000'01'01; // Upper ROM paged out, Lower ROM paged in, Mode 1
	// RAM config (MMR see https://www.grimware.org/doku.php/documentations/devices/gatearray#mmr)
	snbuf[0x41] = 0; // default RAM paging
	// set the crtc registers to the default values
	snbuf[0x42] = 0x0D;	// selected crtc reg
	for (int i = 0; i < 18; ++i)
		snbuf[0x43 + i] = crtc_defaults[i];

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

// eof io_cpc.cpp
