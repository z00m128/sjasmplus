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
static bool writeError(const std::filesystem::path & fname, FILE* & fileToClose) {
	Error("Write error (disk full?)", fname.c_str(), IF_FIRST);
	fclose(fileToClose);
	return false;
}

bool SaveSNA_ZX(const std::filesystem::path & fname, word start) {
	// for Lua
	if (!DeviceID) {
		Error("[SAVESNA] Only for real device emulation mode.");
		return false;
	} else if (!IsZXSpectrumDevice(DeviceID)) {
		Error("[SAVESNA] Device must be ZXSPECTRUM48 or ZXSPECTRUM128.");
		return false;
	}

	FILE* ff;
	if (!FOPEN_ISOK(ff, fname, "wb")) {
		Error("opening file for write", fname.c_str());
		return false;
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
		snbuf[27] = start & 0xFF; //pc
		snbuf[28] = (start>>8) & 0xFF; //pc
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
		WarningById(W_SNA_128, fname.c_str());
	}

	fclose(ff);
	return true;
}

//eof io_snapshots.cpp
