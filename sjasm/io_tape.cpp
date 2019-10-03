/*

SjASMPlus Z80 Cross Compiler

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

// io_tape.cpp

#include "sjdefs.h"
#include "io_tape_ldrs.h"
#include <cassert>

unsigned char parity;
unsigned char blocknum=1;

void writebyte(unsigned char, FILE *);
void writenumber(unsigned int, FILE *);
void writeword(unsigned int, FILE *);
void writeheader(unsigned char, const char *, unsigned short, unsigned short, unsigned short, FILE *);
void writecode(unsigned char*, aint, unsigned short, bool header, FILE *);
void remove_basic_sp(unsigned char* ram);
void detect_vars_changes();
bool has_screen_changes();
aint remove_unused_space(unsigned char* ram, aint length);
aint detect_ram_start(unsigned char* ram, aint length);

int TAP_SaveEmpty(char* fname) {
	FILE* ff;
	if (!FOPEN_ISOK(ff, fname, "wb")) {
		Error("Error opening file", fname, IF_FIRST); return 0;
	}
	fclose(ff);
	return 1;
}

int TAP_SaveBlock(char* fname, unsigned char flag, const char *ftapname, int start, int length, int param2, int param3) {
	FILE* fpout;
	if (!FOPEN_ISOK(fpout, fname, "ab")) {
		Error("Error opening file", fname, FATAL);
	}

	if (length + start > 0x10000) {
	    length = -1;
	}
	if (length <= 0) {
	    length = 0x10000 - start;
	}

	int varBase = 0x80, defaultValue = 0x8000;
	switch (flag) {
		case BASIC:
			if (param2 < 0) {
				param2 = defaultValue; // no autostart
			} else if (param2 >= 16384 && param2 != defaultValue) {
				ErrorInt("[SAVETAP] Autostart LINE out of range", param2);
			}
			if (param3 < 0) {
				param3 = length;
			}
			break;

		case CHARS:
			varBase = 0xC0;
		case NUMBERS:
			if (param2 <= 0) {
				param2 = 1; // reset to default A variable
			}
			param2 &= 0x1F;
			if (param2 < 1 || param2 > 26) { // A..Z
				Error("[SAVETAP] Variable name out of range");
			}
			param2 = (param2 | varBase) << 8;
			param3 = defaultValue;
			break;

		case CODE:
			if (param2 < 0) {
				param2 = start;
			}
			if (param3 < 0) {
				param3 = defaultValue;
			}
			break;
	}

	if (flag == HEADLESS) {
		flag = param3 & 0xff;
	} else if (ftapname) {
		writeheader(flag, ftapname, length, param2, param3, fpout);
		flag = 0xff;
	}

	writeword(length + 2, fpout);
	parity = 0;
	writebyte(flag, fpout);

	CDeviceSlot *S;
	for (aint i = 0, ptr; i < Device->SlotsCount; i++) {
	    S = Device->GetSlot(i);
		if (S->Address + S->Size <= start) continue;
		if (length <= 0) break;
		assert(S->Address <= start && start < S->Address + S->Size);
		ptr = (start - S->Address);

		while (length && ptr < S->Size) {
			writebyte(S->Page->RAM[ptr], fpout);
			++start;
			++ptr;
			--length;
		}
	}

	writebyte(parity, fpout);
	fclose(fpout);
	return 1;
}

int TAP_SaveSnapshot(char* fname, unsigned short start) {
	FILE* fpout;
	if (!FOPEN_ISOK(fpout, fname, "wb")) {
		Error("Error opening file", fname, FATAL);
	}

	aint datastart = 0x5E00;
	aint exeat = 0x5E00;
	aint basiclen = 0x1e + 2;

	/* Filetype (0: Basic), with autostart "LINE 10" */
	writeheader(0, "LOADER", basiclen, 10, basiclen, fpout);

	writeword(basiclen + 2, fpout);	// length of block
	parity = 0;
	writebyte(0xff, fpout);
	writebyte(0, fpout);
	writebyte(10, fpout);		// LINE 10
	writebyte(basiclen, fpout);	// basic line length
	writebyte(0, fpout);

	// :CLEAR VAL "xxxxx"
	writebyte(0xfd, fpout);			// CLEAR
	writebyte(0xb0, fpout);			// VAL
	writebyte('\"', fpout);
	writenumber(datastart-1, fpout);
	writebyte('\"', fpout);

	// :INK VAL "7"
	/*writebyte(':', fpout);
	writebyte(0xd9, fpout);			// INK
	writebyte(0xb0, fpout);			// VAL
	writebyte('\"', fpout);
	writenumber(7, fpout);
	writebyte('\"', fpout);

	// :PAPER VAL "0"
	writebyte(':', fpout);
	writebyte(0xda, fpout);			// PAPER
	writebyte(0xb0, fpout);			// VAL
	writebyte('\"', fpout);
	writenumber(0, fpout);
	writebyte('\"', fpout);

	// :BORDER VAL "0"
	writebyte(':', fpout);
	writebyte(0xe7, fpout);			// BORDER
	writebyte(0xb0, fpout);			// VAL
	writebyte('\"', fpout);
	writenumber(0, fpout);
	writebyte('\"', fpout);*/

	// :CLS
	writebyte(':', fpout);
	writebyte(0xfb, fpout);			// CLS

	writebyte(':', fpout);
	writebyte(0xef, fpout);      /* LOAD */
	writebyte('\"', fpout);
	writebyte('\"', fpout);
	writebyte(0xaf, fpout);      /* CODE */
	writebyte(':', fpout);
	writebyte(0xf9, fpout);      /* RANDOMIZE */
	writebyte(0xc0, fpout);      /* USR */
	writebyte(0xb0, fpout);      /* VAL */
	writebyte('\"', fpout);
	writenumber(exeat, fpout);
	writebyte('\"', fpout);
	writebyte(0x0d, fpout);
	writebyte(parity, fpout);

	if (!strcmp(DeviceID, "ZXSPECTRUM48")) {
		// prepare code block
		aint ram_length = 0xA200;
		aint ram_start = 0x0000;
		unsigned char* ram = (unsigned char*)malloc(ram_length);
		if (ram == NULL) ErrorOOM();
		memcpy(ram, (unsigned char*)Device->GetSlot(1)->Page->RAM + 0x1E00, 0x2200);
		memcpy(ram + 0x2200, (unsigned char*)Device->GetSlot(2)->Page->RAM, 0x4000);
		memcpy(ram + 0x6200, (unsigned char*)Device->GetSlot(3)->Page->RAM, 0x4000);

		// remove basic vars
		remove_basic_sp(ram + ram_length - sizeof(BASin48SP));

		detect_vars_changes();

		ram_length = remove_unused_space(ram, ram_length);
		ram_start = detect_ram_start(ram, ram_length);
		ram_length -= ram_start;

		// write loader
		unsigned char *loader = new unsigned char[SaveTAP_ZX_Spectrum_48K_SZ];
		memcpy(loader, (char*)&SaveTAP_ZX_Spectrum_48K[0], SaveTAP_ZX_Spectrum_48K_SZ);
		if (loader == NULL) ErrorOOM();
		// Settings.LoadScreen
		loader[SaveTAP_ZX_Spectrum_48K_SZ - 7] = char(has_screen_changes());
		loader[SaveTAP_ZX_Spectrum_48K_SZ - 6] = char(start & 0x00FF);
		loader[SaveTAP_ZX_Spectrum_48K_SZ - 5] = char(start >> 8);
		loader[SaveTAP_ZX_Spectrum_48K_SZ - 4] = char((ram_start + 0x5E00) & 0x00FF);
		loader[SaveTAP_ZX_Spectrum_48K_SZ - 3] = char((ram_start + 0x5E00) >> 8);
		loader[SaveTAP_ZX_Spectrum_48K_SZ - 2] = char(ram_length & 0x00FF);
		loader[SaveTAP_ZX_Spectrum_48K_SZ - 1] = char(ram_length >> 8);
		writecode(loader, SaveTAP_ZX_Spectrum_48K_SZ, 0x5E00, true, fpout);

		// write screen$
		if (loader[SaveTAP_ZX_Spectrum_48K_SZ - 7]) {
			writecode((unsigned char*)Device->GetSlot(1)->Page->RAM, 6912, 16384, false, fpout);
		}

		// write code block
		writecode(ram + ram_start, ram_length, 0x5E00 + ram_start, false, fpout);

		free(ram);
	} else {
		detect_vars_changes();

		// prepare main code block
		aint ram_length = 0x6200, ram_start = 0x0000;
		unsigned char* ram = (unsigned char*)malloc(ram_length);
		if (ram == NULL) ErrorOOM();
		memcpy(ram, (unsigned char*)Device->GetSlot(1)->Page->RAM + 0x1E00, 0x2200);
		memcpy(ram + 0x2200, (unsigned char*)Device->GetSlot(2)->Page->RAM, 0x4000);

		ram_length = remove_unused_space(ram, ram_length);
		ram_start = detect_ram_start(ram, ram_length);
		ram_length -= ram_start;

		// init loader
		aint loader_defsize;
		unsigned char* loader_code;
		if (!strcmp(DeviceID, "ZXSPECTRUM128")) {
			loader_defsize = SaveTAP_ZX_Spectrum_128K_SZ;
			loader_code = (unsigned char*)&SaveTAP_ZX_Spectrum_128K[0];
		} else {
			loader_defsize = SaveTAP_ZX_Spectrum_256K_SZ;
			loader_code = (unsigned char*)&SaveTAP_ZX_Spectrum_256K[0];
		}
		aint loader_len = loader_defsize + (Device->PagesCount - 2)*5;
		unsigned char *loader = new unsigned char[loader_len];
		memcpy(loader, loader_code, loader_defsize);
		if (loader == NULL) ErrorOOM();
		// Settings.Start
		loader[loader_defsize - 8] = char(start & 0x00FF);
		loader[loader_defsize - 7] = char(start >> 8);
		// Settings.MainBlockStart
		loader[loader_defsize - 6] = char((ram_start + 0x5E00) & 0x00FF);
		loader[loader_defsize - 5] = char((ram_start + 0x5E00) >> 8);
		// Settings.MainBlockLength
		loader[loader_defsize - 4] = char(ram_length & 0x00FF);
		loader[loader_defsize - 3] = char(ram_length >> 8);
		// Settings.Page
		loader[loader_defsize - 2] = char(Device->GetSlot(3)->Page->Number);

		//
		unsigned char* pages_ram[1024];
		aint pages_len[1024];
		aint pages_start[1024];

		// build pages table
		aint count = 0;
		for (aint i=0;i < Device->PagesCount;i++) {
			if (Device->GetSlot(2)->Page->Number != i && Device->GetSlot(1)->Page->Number != i) {
				aint length = 0x4000;
				length = remove_unused_space((unsigned char*)Device->GetPage(i)->RAM, length);
				if (length > 0) {
					pages_ram[count] = (unsigned char*)Device->GetPage(i)->RAM;
					pages_start[count] = detect_ram_start(pages_ram[count], length);
					pages_len[count] = length - pages_start[count];

					loader[loader_defsize + (count*5) + 0] = char(i);
					loader[loader_defsize + (count*5) + 1] = char((pages_start[count] + 0xC000) & 0x00FF);
					loader[loader_defsize + (count*5) + 2] = char((pages_start[count] + 0xC000) >> 8);
					loader[loader_defsize + (count*5) + 3] = char(pages_len[count] & 0x00FF);
					loader[loader_defsize + (count*5) + 4] = char(pages_len[count] >> 8);

					count++;
				}
			}
		}

		// Table_BlockList.Count
		loader[loader_defsize - 1] = char(count);

		// Settings.LoadScreen
		loader[loader_defsize - 9] = char(has_screen_changes());

		// write loader
		writecode(loader, loader_len, 0x5E00, true, fpout);

		// write screen$
		if (loader[loader_defsize - 9]) {
			writecode((unsigned char*)Device->GetSlot(1)->Page->RAM, 6912, 0x4000, false, fpout);
		}

		// write code blocks
		for (aint i=0;i < count;i++) {
			writecode(pages_ram[i] + pages_start[i], pages_len[i], 0xC000 + pages_start[i], false, fpout);
		}

		// write main code block
		writecode(ram + ram_start, ram_length, 0x5E00 + ram_start, false, fpout);

		free(ram);
	}

	fclose(fpout);
	return 1;
}

void writenumber(unsigned int i, FILE *fp) {
	int c;
	c=i/10000;
	i-=c*10000;
	writebyte(c+48, fp);
	c=i/1000;
	i-=c*1000;
	writebyte(c+48, fp);
	c=i/100;
	i-=c*100;
	writebyte(c+48, fp);
	c=i/10;
	writebyte(c+48, fp);
	i%=10;
	writebyte(i+48, fp);
}

void writeword(unsigned int i, FILE *fp) {
	writebyte(i%256,fp);
	writebyte(i/256,fp);
}

void writebyte(unsigned char c, FILE *fp) {
	fputc(c,fp);
	parity^=c;
}

void writeheader(unsigned char flag, const char *fname, unsigned short param1, unsigned short param2, unsigned short param3, FILE *fp) {
	/* Write out the code header file */
	writeword(19, fp);		/* Header len */
	writebyte(0, fp);		/* Header is 0 */
	parity = 0;
	writebyte(flag, fp);	/* Filetype flag */

	const char *ptr = fname;
	for (int i = 0; i < 10; i++) {
		if (*ptr) {
			writebyte(*ptr++, fp);
		} else {
			writebyte(' ', fp);
		}
	}

	writeword(param1, fp);
	writeword(param2, fp);
	writeword(param3, fp);
	writebyte(parity, fp);
}

void writecode(unsigned char* block, aint length, unsigned short loadaddr, bool header, FILE *fp) {
	if (header) {
		/* Filetype (3: Code) */
		writeheader(3, "loader", length, loadaddr, 0, fp);
	}

	/* Now onto the data bit */
	writeword(length + 2, fp);	/* Length of next block */
	parity = 0;
	writebyte(255, fp); /* Data... */
	for (aint i = 0; i < length; i++) {
		writebyte(block[i], fp);
	}
	writebyte(parity, fp);
}

void remove_basic_sp(unsigned char* ram) {
	bool remove = true;
	for (size_t i=0; i < sizeof(BASin48SP);i++) {
		if (BASin48SP[i] != ram[i]) {
			remove = false;
		}
	}
	if (remove) {
		for (size_t i=0; i < sizeof(BASin48SP);i++) {
			ram[i] = 0;
		}
	}
}

void detect_vars_changes() {
	unsigned char *psys = (unsigned char*)Device->GetSlot(1)->Page->RAM + 0x1C00;

	bool nobas48 = false;
	for (size_t i=0; i < sizeof(BASin48Vars);i++) {
		if (BASin48Vars[i] != psys[i]) {
			nobas48 = true;
		}
	}

	bool nosys = false;
	for (size_t i=0; i < sizeof(ZXSysVars);i++) {
		if (ZXSysVars[i] != psys[i]) {
			nosys = true;
		}
	}

	if (nosys && nobas48) {
		Warning("[SAVETAP] Tape file will not contains data from 0x5B00 to 0x5E00");
	}
}

bool has_screen_changes() {
	unsigned char *pscr = (unsigned char*)Device->GetSlot(1)->Page->RAM;

	for (int i=0; i < 0x1800;i++) {
		if (0 != pscr[i]) {
			return true;
		}
	}

	for (int i=0x1800; i < 0x1B00;i++) {
		if (0x38 != pscr[i]) {
			return true;
		}
	}

	return false;
}

aint remove_unused_space(unsigned char* ram, aint length) {
	while (length > 0 && ram[length-1] == 0) {
		length--;
	}

	return length;
}

aint detect_ram_start(unsigned char* ram, aint length) {
	aint start = 0;

	while (start < length && ram[start] == 0) {
		start++;
	}

	return start;
}

//eof io_tape.cpp
