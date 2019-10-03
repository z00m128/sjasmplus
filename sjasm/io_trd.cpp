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

static int saveEmptyWrite(FILE* ff, byte* buf) {
	int i;
	//catalog (8 zeroed sectors)
	if (fwrite(buf, 1, 1024, ff) < 1024) return 0;
	if (fwrite(buf, 1, 1024, ff) < 1024) return 0;
	// disc info in sector 8
	buf[0xe1] = 0;		// first free sector
	buf[0xe2] = 1;		// track of first free sector
	buf[0xe3] = 0x16;	// disk type (80 tracks, double sided)
	buf[0xe4] = 0;		// number of (non-deleted) files on disk
	buf[0xe5] = 0xf0;	// number of free sectors (WORD)
	buf[0xe6] = 0x09;	// ^^
	buf[0xe7] = 0x10;	// TR-DOS ID (0x10)
	buf[0xe8] = buf[0xe9] = 0;		// unused WORD = 0
	for (i = 0; i < 9; ++i) buf[0xea + i] = 0x20;	// spaces fill or disk protecting password
	buf[0xf3] = 0;		// unused = 0
	buf[0xf4] = 0;		// number of deleted files on disk
	for (i = 0; i < 8; ++i) buf[0xf5 + i] = 0x20;	// disc label + end of disk info (8x 20h, 3x 0)
	if (fwrite(buf, 1, 256, ff) < 256) return 0;
	for (i = 0xe1; i < 0x100; ++i) buf[i] = 0;		// clear the buffer back to all zeroes
	// remaining sectors in image contains all zeroes
	if (fwrite(buf, 1, 768, ff) < 768) return 0;
	for (i = 0; i < 640 - 3; i++) {
		if (fwrite(buf, 1, 1024, ff) < 1024) return 0;
	}
	return 1;
}

int TRD_SaveEmpty(char* fname) {	//TODO add disc label maybe? Type as well?
	FILE* ff;
	if (!FOPEN_ISOK(ff, fname, "wb")) {
		Error("Error opening file", fname, IF_FIRST);
		return 0;
	}
	byte* buf = (byte*) calloc(1024, sizeof(byte));
	if (buf == NULL) ErrorOOM();
	int result = saveEmptyWrite(ff, buf);
	free(buf);
	fclose(ff);
	if (!result) Error("Write error (disk full?)", fname, IF_FIRST);
	return result;
}

// use autostart == -1 to disable it (the valid autostart is 0..9999 as line number of BASIC program)
int TRD_AddFile(char* fname, char* fhobname, int start, int length, int autostart, bool replace) {
	// do some preliminary checks with file name and autostart
	size_t hobNameL = strlen(fhobname), fatPos;
	char extLetter = 0;
	if (hobNameL > 1) {
		char* ext = strrchr(fhobname, '.');
		if (ext) {
			extLetter = ext[1];
			hobNameL = ext - fhobname;
		}
	}
	byte hobnamebin[9];			// prepare binary format of name (as on disc) (for replace search)
	memset(hobnamebin,' ',9);
	if (extLetter) hobnamebin[8] = extLetter;
	memcpy(hobnamebin, fhobname, std::min(hobNameL, size_t(8)));	// binary form is 8+1 with spaces-padding
	if (0 <= autostart && ('B' != extLetter || 9999 < autostart)) {
		Warning("zx.trdimage_add_file: autostart value is BASIC program line number (0..9999) (in lua use -1 otherwise).");
		autostart = -1;
	}
	switch (extLetter) {
		case 'B': case 'C': case 'D': case '#': break;
		default:
			Warning("zx.trdimage_add_file: invalid file extension, TRDOS extensions are B, C, D and #.", fhobname);
	}
	// more validations - for Lua (or SAVETRD letting wrong values go through)
	const int secsLength = (length + 255 + (0 <= autostart ? 4 : 0))>>8;
	if (!DeviceID) {
		Error("zx.trdimage_add_file: this function available only in real device emulation mode.");
		return 0;
	}
	if (start < 0 || 0xFFFF < start) {
		Error("zx.trdimage_add_file: start address must be in 0000..FFFF range", bp, PASS3);
		return 0;
	}
	if (length <= 0 || 0xFF00 < length) {
		// zero length not allowed any more, because TRD docs on internet are imprecise
		// and I'm not sure what is the correct way of saving zero length file => error
		Error("zx.trdimage_add_file: length must be in 0001..FF00 range", bp, PASS3);
		return 0;
	}
	if (0x10000 < start+length) {
		Error("zx.trdimage_add_file: provided start+length will run out of device memory", bp, PASS3);
		return 0;
	}
	if (0xFF < secsLength) {
		Error("zx.trdimage_add_file: sector length over 0xFF max", bp, PASS3);
		return 0;
	}

	FILE* ff;
	if (!FOPEN_ISOK(ff, fname, "r+b")) Error("Error opening file", fname, FATAL);

	byte hdr[16], trd[31];
	if (fseek(ff, 0x8e1, SEEK_SET)) {
		Error("TRD image has wrong format", fname, IF_FIRST); return 0;
	}
	if (31UL != fread(trd, 1, 31, ff) && 0x10 != trd[6]) {	// verify also TR-DOS ID
		Error("TRD image read error", fname, IF_FIRST); return 0;
	}
	constexpr size_t FAT_END_POS = 128*16;
	int freeSecs = trd[4] + (trd[5] << 8);

	// "replace" feature, goes through whole FAT and deletes all files with identical name
	// In special case one of the files connects to current first free sector the disc space
	// will be recovered, but overall this feature is very primitive (not defragging fat or disc)
	if (replace) {
		const byte oldDeletedCount = trd[19];
		fseek(ff, 0, SEEK_SET);
		for (fatPos = 0; fatPos < FAT_END_POS; fatPos += 16) {
			if (16UL != fread(hdr, 1, 16, ff)) {
				Error("Read error", fname, IF_FIRST); return 0;
			}
			if (0 == hdr[0]) break;		// beyond last FAT record, finish the loop
			if (memcmp(hdr, hobnamebin, 9)) continue;	// different file name -> continue
			// try to get freed sectors back (works only if there was no other file written after this one)
			int secsLengthDel = hdr[0x0d];
			byte nextTrack = ((secsLengthDel+hdr[0x0e])>>4) + hdr[0x0f];
			byte nextSector = (secsLength+hdr[0x0e])&0x0F;
			// if file connects to first free sector, salvage the space back
			if (trd[0] == nextSector && trd[1] == nextTrack) {
				trd[0] = hdr[0x0e];
				trd[1] = hdr[0x0f];
				freeSecs += secsLengthDel;
			}
			// delete the actual file
			hdr[0] = 1;		--trd[3];	++trd[19];	// delete file, update file counters
			// write modified FAT entry
			if (fseek(ff, fatPos, SEEK_SET)) {
				Error("TRD image has wrong format", fname, IF_FIRST); return 0;
			}
			if (16UL != fwrite(hdr, 1, 16, ff)) {
				Error("FAT write error", fname, IF_FIRST); return 0;
			}
		}
		// if some files were deleted, update disc info sector too to make image "valid" before writing file
		if (oldDeletedCount != trd[19]) {
			// update remaining free sectors
			trd[4] = (unsigned char)(freeSecs & 0xff);
			trd[5] = (unsigned char)(freeSecs >> 8);
			if (fseek(ff, 0x8e1, SEEK_SET)) {
				Error("TRD image has wrong format", fname, IF_FIRST); return 0;
			}
			if (31UL != fwrite(trd, 1, 31, ff)) {
				Error("Disc info write error", fname, IF_FIRST); return 0;
			}
		}
	}

	if (freeSecs < secsLength) {
		Error("TRD image has not enough free space", fname, IF_FIRST); return 0;
	}
	// Find free position
	fseek(ff, 0, SEEK_SET);
	for (fatPos = 0; fatPos < FAT_END_POS; fatPos += 16) {
		if (16UL != fread(hdr, 1, 16, ff)) {
			Error("Read error", fname, IF_FIRST); return 0;
		}
		if (hdr[0] < 2) {
			// if overwriting deleted file, refresh "deleted" counter
			if (1 == hdr[0]) --trd[19];
			break;
		}
	}
	if (FAT_END_POS <= fatPos) {
		Error("TRD image is full of files", fname, IF_FIRST); return 0;
	}

	if (fseek(ff, (trd[1] << 12) + (trd[0] << 8), SEEK_SET)) {
		Error("TRD image has wrong format", fname, IF_FIRST); return 0;
	}

	SaveRAM(ff, start, length);

	if (0 <= autostart) {
		byte abin[] {0x80, 0xAA, static_cast<byte>(autostart), static_cast<byte>(autostart>>8)};
		if (4 != fwrite(abin, 1, 4, ff)) {
			Error("Write error", fname, IF_FIRST);
			return 0;
		}
	}

	//header of file
	memcpy(hdr, hobnamebin, 9);
	if ('B' == extLetter)	{
		hdr[0x09] = (unsigned char)(length & 0xff);
		hdr[0x0a] = (unsigned char)(length >> 8);
	} else	{
		hdr[0x09] = (unsigned char)(start & 0xff);
		hdr[0x0a] = (unsigned char)(start >> 8);
	}
	hdr[0x0b] = (unsigned char)(length & 0xff);
	hdr[0x0c] = (unsigned char)(length >> 8);
	hdr[0x0d] = secsLength;
	hdr[0x0e] = trd[0];
	hdr[0x0f] = trd[1];

	if (fseek(ff, fatPos, SEEK_SET)) {
		Error("TRD image has wrong format", fname, IF_FIRST); return 0;
	}
	if (16UL != fwrite(hdr, 1, 16, ff)) {
		Error("FAT Write error", fname, IF_FIRST); return 0;
	}

	// update next free sector/track position
	trd[1] += (secsLength+trd[0])>>4;
	trd[0] = (secsLength+trd[0])&0x0F;
	// update remaining free sectors
	freeSecs -= secsLength;
	trd[4] = (unsigned char)(freeSecs & 0xff);
	trd[5] = (unsigned char)(freeSecs >> 8);
	++trd[3];		// count of non-deleted files

	if (fseek(ff, 0x8e1, SEEK_SET)) {
		Error("TRD image has wrong format", fname, IF_FIRST); return 0;
	}
	if (31UL != fwrite(trd, 1, 31, ff)) {
		Error("Disc info write error", fname, IF_FIRST); return 0;
	}

	fclose(ff);
	return 1;
}
