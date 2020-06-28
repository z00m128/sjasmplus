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

static int saveEmptyWrite(FILE* ff, byte* buf, const char label[8]) {
	int i;
	//catalog (8 zeroed sectors)
	if (fwrite(buf, 1, 1024, ff) < 1024) return 0;
	if (fwrite(buf, 1, 1024, ff) < 1024) return 0;
	// disc info in sector 8
	buf[0xe1] = 0;		// first free sector
	buf[0xe2] = 1;		// track of first free sector
	buf[0xe3] = 0x16;	// disk type (80 tracks, double sided)
	buf[0xe4] = 0;		// number of used catalog entries (including deleted!) (number of files)
	buf[0xe5] = 0xf0;	// number of free sectors (WORD)
	buf[0xe6] = 0x09;	// ^^
	buf[0xe7] = 0x10;	// TR-DOS ID (0x10)
	buf[0xe8] = buf[0xe9] = 0;		// unused WORD = 0
	for (i = 0; i < 9; ++i) buf[0xea + i] = 0x20;	// spaces fill or disk protecting password
	buf[0xf3] = 0;		// unused = 0
	buf[0xf4] = 0;		// number of deleted files on disk
	// disc label + end of disk info (8x 20h, 3x 0)
	for (i = 0; i < 8; ++i) buf[0xf5 + i] = (nullptr != label) ? label[i] : 0x20;
	if (fwrite(buf, 1, 256, ff) < 256) return 0;
	for (i = 0xe1; i < 0x100; ++i) buf[i] = 0;		// clear the buffer back to all zeroes
	// remaining sectors in image contains all zeroes
	if (fwrite(buf, 1, 768, ff) < 768) return 0;
	for (i = 0; i < 640 - 3; i++) {
		if (fwrite(buf, 1, 1024, ff) < 1024) return 0;
	}
	return 1;
}

int TRD_SaveEmpty(const char* fname, const char label[8]) {
	FILE* ff;
	if (!FOPEN_ISOK(ff, fname, "wb")) {
		Error("Error opening file", fname, IF_FIRST);
		return 0;
	}
	byte* buf = (byte*) calloc(1024, sizeof(byte));
	if (buf == NULL) ErrorOOM();
	int result = saveEmptyWrite(ff, buf, label);
	free(buf);
	fclose(ff);
	if (!result) Error("Write error (disk full?)", fname, IF_FIRST);
	return result;
}

ETrdFileName TRD_FileNameToBytes(const char* inputName, byte binName[12], int & nameL) {
	nameL = 0;
	while (inputName[nameL] && ('.' != inputName[nameL]) && nameL < 8) {
		binName[nameL] = inputName[nameL];
		++nameL;
	}
	while (nameL < 8) binName[nameL++] = ' ';
	const char* ext = strrchr(inputName, '.');
	while (ext && ext[nameL-7] && nameL < 11) {
		binName[nameL] = ext[nameL-7];
		++nameL;
	}
	while (9 != nameL && 11 != nameL) binName[nameL++] = ' ';	// the file name is either 8+1 or 8+3 (not 8+2)
	int fillIdx = nameL;
	while (fillIdx < 12) binName[fillIdx++] = 0;
	if (9 < nameL) return THREE_LETTER_EXTENSION;
	switch (binName[8]) {
		case 'B': case 'C': case 'D': case '#':
			return OK;
	}
	return INVALID_EXTENSION;
}

// use autostart == -1 to disable it (the valid autostart is 0..9999 as line number of BASIC program)
int TRD_AddFile(const char* fname, const char* fhobname, int start, int length, int autostart, bool replace, bool addplace) {

	// do some preliminary checks with file name and autostart
	byte hobnamebin[16];
	int Lname = 0;
	ETrdFileName nameWarning = TRD_FileNameToBytes(fhobname, hobnamebin, Lname);
	if (!addplace && warningNotSuppressed()) {
		if (INVALID_EXTENSION == nameWarning) {
			Warning("zx.trdimage_add_file: invalid file extension, TRDOS extensions are B, C, D and #.", fhobname);
		}
		if (THREE_LETTER_EXTENSION == nameWarning) {
			Warning("zx.trdimage_add_file: additional non-standard TRDOS file extension with 3 characters", fhobname);
			if ('B' == hobnamebin[8]) Warning("SAVETRD: the \"B\" extension is always single letter.", fhobname);
		}
	}
	if (0 <= autostart && ('B' != hobnamebin[8] || 9999 < autostart)) {
		Warning("zx.trdimage_add_file: autostart value is BASIC program line number (0..9999) (in lua use -1 otherwise).");
		autostart = -1;
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

	// read disc info into "trd" array
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
	size_t fatPos;
	int freeSecs = trd[4] + (trd[5] << 8);

	// "replace" feature, goes through whole FAT and deletes all files with identical name
	// In special case when last file connects to current first free sector => the disc space
	// will be recovered, but overall this feature is very primitive (not defragging fat or disc)
	if (replace) {
		bool discInfoModified = false;
		for (fatPos = 0; fatPos < FAT_END_POS; fatPos += 16) {
			fseek(ff, fatPos, SEEK_SET);
			if (16UL != fread(hdr, 1, 16, ff)) {
				Error("Read error", fname, IF_FIRST); return 0;
			}
			if (0 == hdr[0]) break;		// beyond last FAT record, finish the loop
			if (memcmp(hdr, hobnamebin, Lname)) continue;	// different file name -> continue
			discInfoModified = true;
			const bool isLastFile = ((fatPos>>4) + 1) == trd[3];
			if (isLastFile) {
				// It's last file of catalog, erase it as if it was not on disc at all
				// verify if the free space starts just where last file ends (integrity of TRD image)
				const int secsLengthDel = hdr[0x0d];
				const byte nextTrack = ((secsLengthDel+hdr[0x0e])>>4) + hdr[0x0f];
				const byte nextSector = (secsLengthDel+hdr[0x0e])&0x0F;
				// if file connects to first free sector, salvage the space back
				if (nextSector != trd[0] || nextTrack != trd[1]) {
					Error("TRD free sector was not connected to last file", fname, IF_FIRST); return 0;
				}
				// return the sectors used by file back to "free sectors" pool
				trd[0] = hdr[0x0e];
				trd[1] = hdr[0x0f];
				freeSecs += secsLengthDel;
				trd[4] = byte(freeSecs & 0xff);
				trd[5] = byte(freeSecs >> 8);
				// delete the file (wipe catalog entry completely as if it was not written)
				--trd[3];
				hdr[0] = 0;
			} else {
				// delete the file (but it stays in catalog as deleted file)
				hdr[0] = 1;
				++trd[19];
			}
			// write modified FAT entry
			if (fseek(ff, fatPos, SEEK_SET)) {
				Error("TRD image has wrong format", fname, IF_FIRST); return 0;
			}
			if (16UL != fwrite(hdr, 1, 16, ff)) {
				Error("FAT write error", fname, IF_FIRST); return 0;
			}
		}
		// if some files were deleted, update disc info sector too to make image "valid" before writing file
		if (discInfoModified) {
			// update remaining free sectors
			if (fseek(ff, 0x8e1, SEEK_SET)) {
				Error("TRD image has wrong format", fname, IF_FIRST); return 0;
			}
			if (31UL != fwrite(trd, 1, 31, ff)) {
				Error("Disc info write error", fname, IF_FIRST); return 0;
			}
			fflush(ff);
		}
	} // end of "if (replace)"

	if (freeSecs < secsLength) {
		Error("TRD image has not enough free space", fname, IF_FIRST); return 0;
	}

	if (addplace) {
		for (fatPos = 0; fatPos < FAT_END_POS; fatPos += 16) {
			fseek(ff, fatPos, SEEK_SET);
			if (16UL != fread(hdr, 1, 16, ff)) {
				Error("Read error", fname, IF_FIRST); return 0;
			}
			if (hdr[0] == 0) {
				// if not file for add data
				Error("TRD image does not have a specified file to add data", fname, IF_FIRST); return 0;

			}
			if (!memcmp(hdr, hobnamebin, Lname)) break;	// equal file name -> break
		}

		size_t currpos = (trd[1] << 12) + (trd[0] << 8) - 16 , filepos = (hdr[0x0F] << 12) + (hdr[0x0E] << 8);

		size_t lastpos = currpos + (secsLength << 8) , finpos = filepos + (hdr[0x0D] << 8);

		// save file new sector length
		if (fseek(ff, fatPos, SEEK_SET)) {
			Error("TRD image has wrong format", fname, IF_FIRST); return 0;
		}
		if (0xFF < (hdr[0x0d] + secsLength)) {
			Error("zx.trdimage_add_file: new sector length over 0xFF max",  fname, IF_FIRST);
			return 0;
		}
		hdr[0x0d] += secsLength;
		if (16UL != fwrite(hdr, 1, 16, ff)) {
			Error("FAT write error", fname, IF_FIRST); return 0;
		}

		// move files data (of other files which are after the currently enlarged file)
		while (currpos >= finpos) {
			if (fseek(ff, currpos, SEEK_SET)) {
				Error("TRD image has wrong format", fname, IF_FIRST); return 0;
			}
			if (16UL != fread(hdr, 1, 16, ff)) {
				Error("Read error", fname, IF_FIRST); return 0;
			}
			if (fseek(ff, lastpos, SEEK_SET)) {
				Error("TRD image has wrong format", fname, IF_FIRST); return 0;
			}
			if (16UL != fwrite(hdr, 1, 16, ff)) {
				Error("FAT write error", fname, IF_FIRST); return 0;
			}
			lastpos -=16; currpos -=16;
		}
		// save data to end of file
		if (fseek(ff, finpos, SEEK_SET)) {
			Error("TRD image has wrong format", fname, IF_FIRST); return 0;
		}
		SaveRAM(ff, start, length);

		// catalogue correction
		for (currpos = 0; currpos < FAT_END_POS; currpos += 16) {
		        if (fseek(ff, currpos, SEEK_SET)) {
				Error("TRD image has wrong format", fname, IF_FIRST); return 0;
			}
			if (16UL != fread(hdr, 1, 16, ff)) {
				Error("Read error", fname, IF_FIRST); return 0;
			}
			if (hdr[0] == 0) break; // end of files
			if ((lastpos = (hdr[0x0F] << 12) + (hdr[0x0E] << 8)) > filepos) {
				lastpos += (secsLength << 8);
				hdr[0x0F] = lastpos >> 12;
				hdr[0x0E] = (lastpos >> 8) & 0x0F;
				if (fseek(ff, currpos, SEEK_SET)) {
					Error("TRD image has wrong format", fname, IF_FIRST); return 0;
				}
				if (16UL != fwrite(hdr, 1, 16, ff)) {
					Error("FAT write error", fname, IF_FIRST); return 0;
				}
			}
		}
	} else {
		// Use the last catalog position and verify it's free
		fatPos = size_t(trd[3]) * 16;
		if (FAT_END_POS <= fatPos) {
			Error("TRD image is full of files", fname, IF_FIRST); return 0;
		}
		fseek(ff, fatPos, SEEK_SET);
		if (16UL != fread(hdr, 1, 16, ff)) {
			Error("Read error", fname, IF_FIRST); return 0;
		}
		if (hdr[0] != 0) {
			Error("TRD inconsistent catalog data", fname, IF_FIRST); return 0;
		}

		// save the file content first
		if (fseek(ff, (long(trd[1]) << 12) + (long(trd[0]) << 8), SEEK_SET)) {
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
		memcpy(hdr, hobnamebin, Lname);
		if ('B' == hobnamebin[8]) {
			hdr[0x09] = (unsigned char)(length & 0xff);
			hdr[0x0a] = (unsigned char)(length >> 8);
		} else {
			if (Lname <= 9) {	// single letter extension => "start" field is used for start value
				hdr[0x09] = (unsigned char)(start & 0xff);
				hdr[0x0a] = (unsigned char)(start >> 8);
			}
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
			Error("TRD FAT Write error (file damaged)", fname, IF_FIRST); return 0;
		}
	}

	// update next free sector/track position
	trd[1] += (secsLength+trd[0])>>4;
	trd[0] = (secsLength+trd[0])&0x0F;
	// update remaining free sectors
	freeSecs -= secsLength;
	trd[4] = (unsigned char)(freeSecs & 0xff);
	trd[5] = (unsigned char)(freeSecs >> 8);
	if (!addplace) ++trd[3];	// count of total files (including deleted)
	// write disc info
	if (fseek(ff, 0x8e1, SEEK_SET)) {
		Error("TRD image has wrong format", fname, IF_FIRST); return 0;
	}
	if (31UL != fwrite(trd, 1, 31, ff)) {
		Error("Disc info write error", fname, IF_FIRST); return 0;
	}

	fclose(ff);
	return 1;
}
