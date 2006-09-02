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

// io_snapshots.cpp

#include "sjdefs.h"

int SaveSNA_ZX(char* fname, unsigned short start) {
	unsigned char snbuf[31];
	FILE* ff;
	if (!FOPEN_ISOK(ff, fname, "wb")) {
		Error("Error opening file", fname, FATAL);
	}

	memset(snbuf, 0, sizeof(snbuf));

	snbuf[1] = 0x58; //hl'
	snbuf[2] = 0x27; //hl'
	snbuf[15] = 0x3a; //iy
	snbuf[16] = 0x5c; //iy
	snbuf[23] = 0xff; //sp
	snbuf[24] = 0x5F; //sp
	snbuf[25] = 1; //im 1

	if (fwrite(snbuf, 1, sizeof(snbuf) - 4, ff) != sizeof(snbuf) - 4) {
		Error("Write error (disk full?)", fname, CATCHALL);
		fclose(ff);
		return 0;
	}
	if (fwrite(MemoryRAM, 1, PAGESIZE, ff) != PAGESIZE) {
		Error("Write error (disk full?)", fname, CATCHALL);
		fclose(ff);
		return 0;
	}
	if (fwrite(MemoryRAM + PAGESIZE, 1, PAGESIZE, ff) != PAGESIZE) {
		Error("Write error (disk full?)", fname, CATCHALL);
		fclose(ff);
		return 0;
	}
	if (fwrite(MemoryRAM + PAGESIZE * 2, 1, PAGESIZE, ff) != PAGESIZE) {
		Error("Write error (disk full?)", fname, CATCHALL);
		fclose(ff);
		return 0;
	}

	snbuf[27] = char(start & 0x00FF); //pc
	snbuf[28] = char(start >> 8); //pc
	snbuf[29] = 0x10; //7ffd
	snbuf[30] = 0; //tr-dos
	if (fwrite(snbuf + 27, 1, 4, ff) != 4) {
		Error("Write error (disk full?)", fname, CATCHALL);
		fclose(ff);
		return 0;
	}

	if (Options::MemoryType == MT_ZX128 || Options::MemoryType == MT_ZX512) {
		int n = 1;
		for (int i = 0; i < 8; i++) {
			if (i != 0 && i != 2 && i != 5) {
				if (fwrite(MemoryRAM + PAGESIZE * 2 + PAGESIZE * n, 1, PAGESIZE, ff) != PAGESIZE) {
					Error("Write error (disk full?)", fname, CATCHALL);
					fclose(ff);
					return 0;
				}
				n++;
			}
		}
	} else {
		char *buf = (char*) calloc(0x14000, sizeof(char));
		if (buf == NULL) {
			Error("No enough memory", 0, FATAL);
		}
		memset(buf, 0, 0x14000);
		if (fwrite(buf, 1, 0x14000, ff) != 0x14000) {
			Error("Write error (disk full?)", fname, CATCHALL);
			fclose(ff);
			return 0;
		}
	}

	if (Options::MemoryType == MT_ZX512) {
		Warning("Only 128kb will be written to snapshot", fname);
	}

	fclose(ff);
	return 1;
}

//eof io_snapshots.cpp
