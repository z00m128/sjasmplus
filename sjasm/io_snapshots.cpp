/*

  SjASMPlus Z80 Cross Assembler

  Copyright (c) 2004-2008 Aprisobal

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

// io_snapshots.cpp

#include "sjdefs.h"

// report error and close the file
static int writeError(char* fname, FILE* & fileToClose) {
	Error("Write error (disk full?)", fname, IF_FIRST);
	fclose(fileToClose);
	return 0;
}

int SaveSNA_ZX(char* fname, word start) {
	// for Lua
	if (!DeviceID) {
		Error("[SAVESNA] Only for real device emulation mode.");
		return 0;
	} else if (!IsZXSpectrumDevice(DeviceID)) {
		Error("[SAVESNA] Device must be ZXSPECTRUM48 or ZXSPECTRUM128.");
		return 0;
	}

	FILE* ff;
	if (!FOPEN_ISOK(ff, fname, "wb")) {
		Error("Error opening file", fname, FATAL);
	}

	constexpr int SNA_HEADER_48_SIZE = 27;
	constexpr int SNA_HEADER_128_SIZE = 4;
	byte snbuf[SNA_HEADER_48_SIZE + SNA_HEADER_128_SIZE] = {
	//	I     L'    H'    E'    D'    C'    B'    F'    A'    L     H     E     D     C **  B **
		0x3F, 0x58, 0x27, 0x9B, 0x36, 0x00, 0x00, 0x44, 0x00, 0x2B, 0x2D, 0xDC, 0x5C, 0x00, 0x00,
	//	IYL   IYH   IXL   IXH   IFF2  R     F     A     SP(L) SP(H) IM #  border
		0x3A, 0x5C, 0x3C, 0xFF, 0x00, 0x00, 0x54, 0x00, 0x00, 0x00, 0x01, 0x07,
	// end of 48k SNA header, following 4 bytes are extra 128k SNA header "interlude" after 48k data
	//	PC(L) PC(H) 7FFD  TR-DOS
		0x00, 0x00, 0x00, 0x00
	};

	// set BC to start address
	snbuf[13] = start & 0xFF;
	snbuf[14] = (start>>8) & 0xFF;

	// check if default ZX-like stack was modified - if not, it will be used for snapshot
	bool is48kSnap = !strcmp(DeviceID, "ZXSPECTRUM48");
	bool defaultStack = true;
	aint stackAdr = Device->ZxRamTop + 1 - sizeof(ZX_STACK_DATA);
	for (aint ii = is48kSnap ? -2 : 0; ii < aint(sizeof(ZX_STACK_DATA)); ++ii) {
		// will check for 48k snap if there is `00 00` ahead of fake stack data
		const byte cmpValue = (0 <= ii) ? ZX_STACK_DATA[ii] : 0;
		CDeviceSlot* slot = Device->GetSlot(Device->GetSlotOfA16(stackAdr + ii));
		CDevicePage* page = Device->GetPage(slot->InitialPage);
		defaultStack &= (cmpValue == page->RAM[(stackAdr + ii) & (page->Size-1)]);
	}
	if (defaultStack) {
		if (is48kSnap) {
			--stackAdr;
			// inject PC under default stack
			CDeviceSlot* slot = Device->GetSlot(Device->GetSlotOfA16(stackAdr));
			CDevicePage* page = Device->GetPage(slot->InitialPage);
			page->RAM[stackAdr & (page->Size-1)] = (start>>8) & 0xFF;
			--stackAdr;
			slot = Device->GetSlot(Device->GetSlotOfA16(stackAdr));
			page = Device->GetPage(slot->InitialPage);
			page->RAM[stackAdr & (page->Size-1)] = start & 0xFF;
		}
		// SP (may point to injected start address for 48k snap)
		snbuf[23] = (stackAdr) & 0xFF;
		snbuf[24] = (stackAdr>>8) & 0xFF;
	} else {
		if (is48kSnap) {
			WarningById(W_SNA_48);
			snbuf[23] = 0x00; //sp
			snbuf[24] = 0x40; //sp
			Device->GetPage(1)->RAM[0] = start & 0xFF;	//pc
			Device->GetPage(1)->RAM[1] = start >> 8;	//pc
		} else {
			snbuf[23] = 0x00; //sp
			snbuf[24] = 0x60; //sp
		}
	}

	if (fwrite(snbuf, 1, SNA_HEADER_48_SIZE, ff) != SNA_HEADER_48_SIZE) {
		return writeError(fname, ff);
	}

	const int pages48[3] = { 1, 2, 3 };
	const int pages128[3] = { 5, 2, Device->GetSlot(3)->Page->Number };

	for (const int page : is48kSnap ? pages48 : pages128) {
		if ((aint) fwrite(Device->GetPage(page)->RAM, 1, Device->GetPage(page)->Size, ff) != Device->GetPage(page)->Size) {
			return writeError(fname, ff);
		}
	}

	if (!is48kSnap) {
		// 128k snapshot extra header fields
		snbuf[27] = char(start & 0x00FF); //pc
		snbuf[28] = char(start >> 8); //pc
		snbuf[29] = 0x10 + Device->GetSlot(3)->Page->Number; //7ffd
		snbuf[30] = 0; //tr-dos
		if (fwrite(snbuf + SNA_HEADER_48_SIZE, 1, SNA_HEADER_128_SIZE, ff) != SNA_HEADER_128_SIZE) {
			return writeError(fname, ff);
		}
		// 128k banks
		for (aint i = 0; i < 8; i++) {
			if (i != Device->GetSlot(3)->Page->Number && i != 2 && i != 5) {
				if ((aint) fwrite(Device->GetPage(i)->RAM, 1, Device->GetPage(i)->Size, ff) != Device->GetPage(i)->Size) {
					return writeError(fname, ff);
				}
			}
		}
	}

	if (128*1024 < Device->PagesCount * Device->GetPage(0)->Size) {
		WarningById(W_SNA_128, fname);
	}

	fclose(ff);
	return 1;
}

int SaveSNA_CPC(char* fname, word start) {
	// for Lua
	if (!DeviceID) {
		Error("[SAVESNA] Only for real device emulation mode.");
		return 0;
	}
	else if (!IsAmstradCPCDevice(DeviceID)) {
		Error("[SAVESNA] Device must be AMSTRADCPC464.");
		return 0;
	}

	FILE* ff;
	if (!FOPEN_ISOK(ff, fname, "wb")) {
		Error("[SAVESNA] Error opening file", fname, FATAL);
		return 0;
	}

	// format:  http://cpctech.cpc-live.com/docs/snapshot.html
	constexpr int SNA_HEADER_SIZE = 256;
	const char magic[8] = { 'M', 'V', ' ', '-', ' ', 'S', 'N', 'A' };
	// basic rom initialized pens
	const byte ga_pens[17] = { 0x04, 0x0A, 0x13, 0x0C, 0x0B, 0x14, 0x15, 0x0D, 0x06, 0x1E, 0x1F, 0x07, 0x12, 0x19, 0x04, 0x17, 0x04 };
	// crtc set to standard screen @ $C000
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
		0x30, 0x00, // display (xxPPSSOO) 
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
	snbuf[0x21] = 0xF0; snbuf[0x22] = 0xBF; // sp to BFF0
	snbuf[0x23] = char(start & 0xFF); snbuf[0x24] = char(start >> 8); // pc
	snbuf[0x25] = 1; // im = 1
	// pens
	for (int i = 0; i < 17; ++i)
		snbuf[0x2F + i] = ga_pens[i];
	// multi-config (RMR: 100I ULVM)
	snbuf[0x40] = 0b1000'01'00; // UR out, LR in, Mode 0
	// RAM config (MMR see https://www.grimware.org/doku.php/documentations/devices/gatearray#mmr)
	snbuf[0x41] = 0;
	// crtc
	snbuf[0x42] = 0x0D;	// selected crtc reg
	for (int i = 0; i < 18; ++i)
		snbuf[0x43 + i] = crtc_defaults[i];

	snbuf[0x6B] = 0x40; // 64Kb RAM

	// v2 format fields
	snbuf[0x6D] = 0;	// machine type (0 = 464, 1 = 664, 2 = 6128)

	if (fwrite(snbuf, 1, SNA_HEADER_SIZE, ff) != SNA_HEADER_SIZE) {
		return writeError(fname, ff);
	}

	const int pages464[4] = { 0, 1, 2, 3 };

	for (const int page : pages464) {
		if ((aint)fwrite(Device->GetPage(page)->RAM, 1, Device->GetPage(page)->Size, ff) != Device->GetPage(page)->Size) {
			return writeError(fname, ff);
		}
	}

	fclose(ff);
	return 1;
}

//eof io_snapshots.cpp
