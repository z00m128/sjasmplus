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

int SaveSNA_ZX(char* fname, unsigned short start) {
	unsigned char snbuf[31];

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

	memset(snbuf, 0, sizeof(snbuf));
	snbuf[0] = 0x3F; //i
	snbuf[1] = 0x58; //hl'
	snbuf[2] = 0x27; //hl'
	snbuf[3] = 0x9B; //de'
	snbuf[4] = 0x36; //de'
	snbuf[5] = 0x00; //bc'
	snbuf[6] = 0x00; //bc'
	snbuf[7] = 0x44; //af'
	snbuf[8] = 0x00; //af'
	snbuf[9] = 0x2B; //hl
	snbuf[10] = 0x2D; //hl
	snbuf[11] = 0xDC; //de
	snbuf[12] = 0x5C; //de
	snbuf[13] = start & 0xFF;		//bc
	snbuf[14] = (start>>8) & 0xFF;	//bc
	snbuf[15] = 0x3a; //iy
	snbuf[16] = 0x5c; //iy
	snbuf[17] = 0x3C; //ix
	snbuf[18] = 0xFF; //ix
	snbuf[21] = 0x54; //af
	snbuf[22] = 0x00; //af
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
		if (is48kSnap) stackAdr -= 2;
		snbuf[23] = (stackAdr) & 0xFF;	// SP (may point to injected start address for 48k snap)
		snbuf[24] = (stackAdr>>8) & 0xFF;
		if (is48kSnap) {
			// inject PC under default stack
			CDeviceSlot* slot = Device->GetSlot(Device->GetSlotOfA16(stackAdr));
			CDevicePage* page = Device->GetPage(slot->InitialPage);
			page->RAM[stackAdr & (page->Size-1)] = start & 0xFF;
			++stackAdr;
			slot = Device->GetSlot(Device->GetSlotOfA16(stackAdr));
			page = Device->GetPage(slot->InitialPage);
			page->RAM[stackAdr & (page->Size-1)] = (start>>8) & 0xFF;
		}
	} else {
		if (is48kSnap) {
			Warning("[SAVESNA] RAM <0x4000-0x4001> will be overriden due to 48k snapshot imperfect format.");
			snbuf[23] = 0x00; //sp
			snbuf[24] = 0x40; //sp
			Device->GetPage(1)->RAM[0] = start & 0xFF;	//pc
			Device->GetPage(1)->RAM[1] = start >> 8;	//pc
		} else {
			snbuf[23] = 0x00; //sp
			snbuf[24] = 0x60; //sp
		}
	}
	snbuf[25] = 1; //im 1
	snbuf[26] = 7; //border 7

	if (fwrite(snbuf, 1, sizeof(snbuf) - 4, ff) != sizeof(snbuf) - 4) {
		Error("Write error (disk full?)", fname, IF_FIRST);
		fclose(ff);
		return 0;
	}

	if (is48kSnap) {
		if ((aint) fwrite(Device->GetPage(1)->RAM, 1, Device->GetPage(1)->Size, ff) != Device->GetPage(1)->Size) {
			Error("Write error (disk full?)", fname, IF_FIRST);
			fclose(ff);
			return 0;
		}
		if ((aint) fwrite(Device->GetPage(2)->RAM, 1, Device->GetPage(2)->Size, ff) != Device->GetPage(2)->Size) {
			Error("Write error (disk full?)", fname, IF_FIRST);
			fclose(ff);
			return 0;
		}
		if ((aint) fwrite(Device->GetPage(3)->RAM, 1, Device->GetPage(3)->Size, ff) != Device->GetPage(3)->Size) {
			Error("Write error (disk full?)", fname, IF_FIRST);
			fclose(ff);
			return 0;
		}
	} else {
		if ((aint) fwrite(Device->GetPage(5)->RAM, 1, Device->GetPage(5)->Size, ff) != Device->GetPage(5)->Size) {
			Error("Write error (disk full?)", fname, IF_FIRST);
			fclose(ff);
			return 0;
		}
		if ((aint) fwrite(Device->GetPage(2)->RAM, 1, Device->GetPage(2)->Size, ff) != Device->GetPage(2)->Size) {
			Error("Write error (disk full?)", fname, IF_FIRST);
			fclose(ff);
			return 0;
		}
		if ((aint) fwrite(Device->GetPage(Device->GetSlot(3)->Page->Number)->RAM, 1, Device->GetPage(0)->Size, ff) != Device->GetPage(0)->Size) {
			Error("Write error (disk full?)", fname, IF_FIRST);
			fclose(ff);
			return 0;
		}
		// 128k snapshot extra header fields
		snbuf[27] = char(start & 0x00FF); //pc
		snbuf[28] = char(start >> 8); //pc
		snbuf[29] = 0x10 + Device->GetSlot(3)->Page->Number; //7ffd
		snbuf[30] = 0; //tr-dos
		if (fwrite(snbuf + 27, 1, 4, ff) != 4) {
			Error("Write error (disk full?)", fname, IF_FIRST);
			fclose(ff);
			return 0;
		}
		// 128k banks
		for (aint i = 0; i < 8; i++) {
			if (i != Device->GetSlot(3)->Page->Number && i != 2 && i != 5) {
				if ((aint) fwrite(Device->GetPage(i)->RAM, 1, Device->GetPage(i)->Size, ff) != Device->GetPage(i)->Size) {
					Error("Write error (disk full?)", fname, IF_FIRST);
					fclose(ff);
					return 0;
				}
			}
		}
	}

	if (128*1024 < Device->PagesCount * Device->GetPage(0)->Size) {
		Warning("Only 128kb will be written to snapshot", fname);
	}

	fclose(ff);
	return 1;
}

//eof io_snapshots.cpp
