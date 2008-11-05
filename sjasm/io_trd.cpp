/*

  SjASMPlus Z80 Cross Compiler

  Copyright (c) 2004-2006 Aprisobal

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

// io_trd.cpp

#include "sjdefs.h"

int TRD_SaveEmpty(char* fname) {
	FILE* ff;
	int i;
	unsigned char* buf;
	if (!FOPEN_ISOK(ff, fname, "wb")) {
		Error("Error opening file", fname, CATCHALL); return 0;
	}
	buf = (unsigned char*) calloc(1024, sizeof(unsigned char));
	if (buf == NULL) {
		Error("No enough memory", 0, FATAL);
	}
	if (fwrite(buf, 1, 1024, ff) < 1024) {
		Error("Write error (disk full?)", fname, CATCHALL); return 0;
	} //catalog
	if (fwrite(buf, 1, 1024, ff) < 1024) {
		Error("Write error (disk full?)", fname, CATCHALL); return 0;
	} //catalog
	buf[0xe1] = 0;
	buf[0xe2] = 1;
	buf[0xe3] = 0x16;
	buf[0xe4] = 0;
	buf[0xe5] = 0xf0;
	buf[0xe6] = 0x09;
	buf[0xe7] = 0x10;
	buf[0xe8] = 0;
	buf[0xe9] = 0;
	for (i = 0; i < 9; i++) {
		buf[0xea + i] = 0x20;
	}
	buf[0xf3] = 0;
	buf[0xf4] = 0;
	for (i = 0; i < 10; buf[0xf5 + i++] = 0x20) {
		;
	}
	if (fwrite(buf, 1, 256, ff) < 256) {
		Error("Write error (disk full?)", fname, CATCHALL); return 0;
	} //
	for (i = 0; i < 31; buf[0xe1 + i++] = 0) {
		;
	}
	if (fwrite(buf, 1, 768, ff) < 768) {
		Error("Write error (disk full?)", fname, CATCHALL); return 0;
	} //
	for (i = 0; i < 640 - 3; i++) {
		if (fwrite(buf, 1, 1024, ff) < 1024) {
			Error("Write error (disk full?)", fname, CATCHALL); return 0;
		}
	}
	fclose(ff);
	return 1;
}

int TRD_AddFile(char* fname, char* fhobname, int start, int length, int autostart) { //autostart added by boo_boo 19_0ct_2008
	FILE* ff;
	unsigned char hdr[16], trd[31], abin[4];
	int i,secs,pos = 0;
	aint res;
	int autostart_add = autostart > 0? 4 : 0; //added by boo_boo 19_0ct_2008

	// for Lua
	if (!DeviceID) {
		Error("zx.trdimage_addfile: this function available only in real device emulation mode.", 0);
		return 0;
	}

	// for Lua
	if (start > 0xFFFF) {
		Error("zx.trdimage_addfile: start address more than 0FFFFh are not allowed", bp, PASS3); return 0;
	}
	// for Lua
	if (length > 0x10000) {
		Error("zx.trdimage_addfile: length more than 10000h are not allowed", bp, PASS3); return 0;
	}
	// for Lua
	if (start < 0) {
		start = 0;
	}
	// for Lua
	if (length < 0) {
		length = 0x10000 - start;
	}

	if (!FOPEN_ISOK(ff, fname, "r+b")) {
		Error("Error opening file", fname, FATAL);
	}

	if (fseek(ff, 0x8e1, SEEK_SET)) {
		Error("TRD image has wrong format", fname, CATCHALL); return 0;
	}
	res = fread(trd, 1, 31, ff);
	if (res != 31) {
		_COUT "Read error: " _CMDL fname _ENDL; return 0;
	}
	secs = trd[4] + (trd[5] << 8);
	if (secs < ((length + autostart_add) >> 8) + 1) {
		Error("TRD image haven't free space", fname, CATCHALL); return 0;
	}

	// Find free position
	fseek(ff, 0, SEEK_SET);
	for (i = 0; i < 128; i++) {
		res = fread(hdr, 1, 16, ff);
		if (res != 16) {
			Error("Read error", fname, CATCHALL); return 0;
		}
		if (hdr[0] < 2) {
			i = 0; break;
		}
		pos += 16;
	}
	if (i) {
		Error("TRD image is full of files", fname, CATCHALL); return 0;
	}

	if (fseek(ff, (trd[1] << 12) + (trd[0] << 8), SEEK_SET)) {
		Error("TRD image has wrong format", fname, CATCHALL); return 0;
	}
	if (length + start > 0xFFFF) {
		length = -1;
	}
	if (length <= 0) {
		length = 0x10000 - start;
	}
	SaveRAM(ff, start, length);

	if(autostart_add)
	{
		abin[0] = 0x80;
		abin[1] = 0xAA;
		abin[2] = autostart & 0xFF;
		abin[3] = (autostart >> 8) & 0xFF;
		
		if(fwrite(abin, 1, 4, ff) != 4) {
			Error("Write error", fname, CATCHALL); return 0;
		}
	}

	//header of file
	for (i = 0; i != 9; hdr[i++] = 0x20) {
		;
	}
	//for (i = 0; i != 9; ++i) {
	for (i = 0; i < 9; ++i) {

		if (*(fhobname + i) == 0) {
			break;
		}
		if (*(fhobname + i) != '.') {
			hdr[i] = *(fhobname + i); continue;
		} else if (*(fhobname + i + 1)) {
			hdr[8] = *(fhobname + i + 1);
		}
		break;
	}

	if (*(fhobname + i + 2) != 0 && *(fhobname + i + 3) != 0) {
		hdr[0x09] = *(fhobname + i + 2);
		hdr[0x0a] = *(fhobname + i + 3);
	} else {
		if (hdr[8] == 'B') {
			hdr[0x09] = (unsigned char)(length & 0xff);
			hdr[0x0a] = (unsigned char)(length >> 8);
		} else {
			hdr[0x09] = (unsigned char)(start & 0xff);
			hdr[0x0a] = (unsigned char)(start >> 8);
		}
	}

	hdr[0x0b] = (unsigned char)(length & 0xff);
	hdr[0x0c] = (unsigned char)(length >> 8);
	hdr[0x0d] = ((length + autostart_add) >> 8) + ((length + autostart_add) & 0xFF ? 1: 0);
	hdr[0x0e] = trd[0];
	hdr[0x0f] = trd[1];

	if (fseek(ff, pos, SEEK_SET)) {
		Error("TRD image has wrong format", fname, CATCHALL); return 0;
	}
	res = fwrite(hdr, 1, 16, ff);
	if (res != 16) {
		Error("Write error", fname, CATCHALL); return 0;
	}

	trd[0] += hdr[0x0d];
	if (trd[0] > 15) {
		trd[1] += (trd[0] >> 4); trd[0] = (trd[0] & 15);
	}
	secs -= hdr[0x0d];
	trd[4] = (unsigned char)(secs & 0xff);
	trd[5] = (unsigned char)(secs >> 8);
	trd[3]++;

	if (fseek(ff, 0x8e1, SEEK_SET)) {
		Error("TRD image has wrong format", fname, CATCHALL); return 0;
	}
	res = fwrite(trd, 1, 31, ff);
	if (res != 31) {
		Error("Write error", fname, CATCHALL); return 0;
	}

	fclose(ff);
	return 1;
}

//eof io_trd.cpp
