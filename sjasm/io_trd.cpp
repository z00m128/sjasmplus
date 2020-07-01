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

#ifdef _MSC_VER
#pragma pack(push, 1)
#endif
struct STrdFile {
	constexpr static size_t NAME_BASE_SZ = 8;
	constexpr static size_t NAME_EXT_SZ = 1;
	constexpr static size_t NAME_ALT_EXT_SZ = 3;	// 3-letter extensions are sometimes used instead of "address" field
	constexpr static size_t NAME_FULL_SZ = NAME_BASE_SZ + NAME_EXT_SZ;
	constexpr static size_t NAME_ALT_FULL_SZ = NAME_BASE_SZ + NAME_ALT_EXT_SZ;

	byte		filename[NAME_BASE_SZ];
	byte		ext;
	word		address;		// sometimes: other two extension letters for 8.3 naming scheme
	word		length;
	byte		sectorLength;
	byte		startSector;
	byte		startTrack;
}
#ifndef _MSC_VER
	__attribute__((packed));
#else
	;
#pragma pack(pop)
#endif
static_assert(16 == sizeof(STrdFile), "TRD file header is expected to be 16 bytes long!");

#ifdef _MSC_VER
#pragma pack(push, 1)
#endif
struct STrdDisc {
	constexpr static byte TRDOS_DISC_ID = 0x10;
	constexpr static size_t SECTOR_SZ = 256;
	constexpr static size_t SECTORS_PER_TRACK = 16;
	constexpr static size_t PASSWORD_SZ = 9;
	constexpr static size_t LABEL_SZ = 8;
	constexpr static byte DISK_TYPE_T80_S2 = 0x16;		// 80 tracks, double sided
	constexpr static byte DISK_TYPE_T40_S2 = 0x17;		// 40 tracks, double sided
	constexpr static byte DISK_TYPE_T80_S1 = 0x18;		// 80 tracks, single sided
	constexpr static byte DISK_TYPE_T40_S1 = 0x19;		// 40 tracks, single sided

	byte		_endOfRootDirectory		= 0x00;
	byte		_unused[224]			= {};
	byte		freeSector				= 0;
	byte		freeTrack				= 1;
	byte		diskType				= DISK_TYPE_T80_S2;
	byte		numOfFiles				= 0;
	word		numOfFreeSectors		= (79+80)*SECTORS_PER_TRACK;	// 0x09F0 for T80_S2 empty disc
	byte		trDosId					= TRDOS_DISC_ID;
	byte		_unused2[2]				= {};
	byte		password[PASSWORD_SZ]	= {' ',' ',' ',' ',' ',' ',' ',' ',' '};
	byte		_unused3[1]				= {};
	byte		numOfDeleted			= 0;
	byte		label[LABEL_SZ]			= {' ',' ',' ',' ',' ',' ',' ',' '};
	byte		_unused4[3]				= {};

	bool isTrdInfo() const {
		return (TRDOS_DISC_ID == trDosId);
	}
}
#ifndef _MSC_VER
	__attribute__((packed));
#else
	;
#pragma pack(pop)
#endif
static_assert(STrdDisc::SECTOR_SZ == sizeof(STrdDisc), "TRD disc info is expected to be 256 bytes long!");

#ifdef _MSC_VER
#pragma pack(push, 1)
#endif
struct STrdHead {
	constexpr static size_t NUM_OF_FILES_MAX = 128;		// 8 sectors with 16B records

	STrdFile	catalog[NUM_OF_FILES_MAX];
	STrdDisc	info;
}
#ifndef _MSC_VER
	__attribute__((packed));
#else
	;
#pragma pack(pop)
#endif
static_assert(9 * STrdDisc::SECTOR_SZ == sizeof(STrdHead), "TRD catalog and info area should be 9 sectors long!");

/**
 * @brief Write empty TRD file (80 tracks, 2 sides) into file
 *
 * @param ff file handle to write content into
 * @param buf 4096 bytes long buffer (must be zeroed by caller) (16 sectors = 1 track)
 * @param label nullptr or 8 characters long disc label
 * @return int 1 if OK, 0 in case of write error
 */
static int saveEmptyWrite(FILE* ff, byte* buf, const char label[8]) {
	//catalog (8 zeroed sectors)
	if (8 != fwrite(buf, STrdDisc::SECTOR_SZ, 8, ff)) return 0;
	// disc info in sector 8
	{
		// the default 80 track two sided disc info initialized
		STrdDisc discInfo{};
		// replace label data if requested
		if (label) memcpy(discInfo.label, label, STrdDisc::LABEL_SZ);
		if (1 != fwrite(&discInfo, sizeof(STrdDisc), 1, ff)) return 0;
	}
	// zeroes till end of first track
	if (7 != fwrite(buf, STrdDisc::SECTOR_SZ, 7, ff)) return 0;
	// remaining tracks in image contains all zeroes
	for (int i = 0; i < (79 + 80); ++i) {		// 80 tracks, two sides, one track is already done
		if (STrdDisc::SECTORS_PER_TRACK != fwrite(buf, STrdDisc::SECTOR_SZ, STrdDisc::SECTORS_PER_TRACK, ff)) return 0;
	}
	return 1;
}

int TRD_SaveEmpty(const char* fname, const char label[8]) {
	FILE* ff;
	if (!FOPEN_ISOK(ff, fname, "wb")) {
		Error("Error opening file", fname, IF_FIRST);
		return 0;
	}
	byte* buf = (byte*) calloc(STrdDisc::SECTORS_PER_TRACK*STrdDisc::SECTOR_SZ, sizeof(byte));
	if (buf == NULL) ErrorOOM();
	int result = saveEmptyWrite(ff, buf, label);
	free(buf);
	fclose(ff);
	if (!result) Error("Write error (disk full?)", fname, IF_FIRST);
	return result;
}

ETrdFileName TRD_FileNameToBytes(const char* inputName, byte binName[12], int & nameL) {
	nameL = 0;
	while (inputName[nameL] && ('.' != inputName[nameL]) && nameL < int(STrdFile::NAME_BASE_SZ)) {
		binName[nameL] = inputName[nameL];
		++nameL;
	}
	while (nameL < int(STrdFile::NAME_BASE_SZ)) binName[nameL++] = ' ';
	const char* ext = strrchr(inputName, '.');
	while (ext && ext[1] && nameL < int(STrdFile::NAME_ALT_FULL_SZ)) {
		binName[nameL] = ext[1];
		++nameL;
		++ext;
	}
	while (STrdFile::NAME_FULL_SZ != nameL && STrdFile::NAME_ALT_FULL_SZ != nameL) {
		binName[nameL++] = ' ';		// the file name is either 8+1 or 8+3 (not 8+2)
	}
	int fillIdx = nameL;
	while (fillIdx < 12) binName[fillIdx++] = 0;
	if (int(STrdFile::NAME_FULL_SZ) < nameL) return THREE_LETTER_EXTENSION;
	switch (binName[STrdFile::NAME_BASE_SZ]) {
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
	const ETrdFileName nameWarning = TRD_FileNameToBytes(fhobname, hobnamebin, Lname);
	const bool isExtensionB = ('B' == hobnamebin[STrdFile::NAME_BASE_SZ]);
	if (!addplace && warningNotSuppressed()) {
		if (INVALID_EXTENSION == nameWarning) {
			Warning("zx.trdimage_add_file: invalid file extension, TRDOS extensions are B, C, D and #.", fhobname);
		}
		if (THREE_LETTER_EXTENSION == nameWarning) {
			Warning("zx.trdimage_add_file: additional non-standard TRDOS file extension with 3 characters", fhobname);
			if (isExtensionB) Warning("SAVETRD: the \"B\" extension is always single letter.", fhobname);
		}
	}
	if (0 <= autostart && (!isExtensionB || 9999 < autostart)) {
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
	STrdHead trdHead;
	if (!FOPEN_ISOK(ff, fname, "r+b")) Error("Error opening file", fname, FATAL);
	if (1 != fread(&trdHead, sizeof(STrdHead), 1, ff) || !trdHead.info.isTrdInfo()) {
		Error("TRD image read error", fname, IF_FIRST); return 0;
	}

	// "replace" feature, goes through whole FAT and deletes all files with identical name
	// In special case when last file connects to current first free sector => the disc space
	// will be recovered, but overall this feature is very primitive (not defragging fat or disc)
	if (replace) {
		bool discInfoModified = false;
		for (unsigned i = 0; i < STrdHead::NUM_OF_FILES_MAX; ++i) {
			auto & entry = trdHead.catalog[i];
			if (0 == entry.filename[0]) break;		// beyond last FAT record, finish the loop
			if (memcmp(entry.filename, hobnamebin, Lname)) continue;	// different file name -> continue
			discInfoModified = true;
			if (i + 1 == trdHead.info.numOfFiles) {		// if last file in the catalog
				// It's last file of catalog, erase it as if it was not on disc at all
				// verify if the free space starts just where last file ends (integrity of TRD image)
				const byte nextTrack = ((entry.sectorLength + entry.startSector) >> 4) + entry.startTrack;
				const byte nextSector = (entry.sectorLength + entry.startSector) & 0x0F;
				// if file connects to first free sector, salvage the space back
				if (nextSector != trdHead.info.freeSector || nextTrack != trdHead.info.freeTrack) {
					Error("TRD free sector was not connected to last file", fname, IF_FIRST); return 0;
				}
				// return the sectors used by file back to "free sectors" pool
				trdHead.info.freeSector = entry.startSector;
				trdHead.info.freeTrack = entry.startTrack;
				trdHead.info.numOfFreeSectors += entry.sectorLength;
				// delete the file (wipe catalog entry completely as if it was not written)
				--trdHead.info.numOfFiles;
				entry.filename[0] = 0;
			} else {
				// delete the file (but it stays in catalog as deleted file)
				entry.filename[0] = 1;
				++trdHead.info.numOfDeleted;
			}
		}
		// if some files were deleted, update disc info sector too to make image "valid" before writing file
		if (discInfoModified) {
			// update whole catalog and disc info with modified data
			if (fseek(ff, 0, SEEK_SET)) {
				Error("TRD image has wrong format", fname, IF_FIRST); return 0;
			}
			if (1 != fwrite(&trdHead, sizeof(STrdHead), 1, ff)) {
				Error("Disc info write error", fname, IF_FIRST); return 0;
			}
			fflush(ff);
		}
	} // end of "if (replace)"

	byte hdr[16];
	constexpr size_t FAT_END_POS = 128*16;
	size_t fatPos;

	if (trdHead.info.numOfFreeSectors < secsLength) {
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

		size_t currpos = (trdHead.info.freeTrack << 12) + (trdHead.info.freeSector << 8) - 16;
		size_t filepos = (hdr[0x0F] << 12) + (hdr[0x0E] << 8);
		size_t lastpos = currpos + (secsLength << 8);
		size_t finpos = filepos + (hdr[0x0D] << 8);

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
		fatPos = size_t(trdHead.info.numOfFiles) * 16;
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
		if (fseek(ff, (long(trdHead.info.freeTrack) << 12) + (long(trdHead.info.freeSector) << 8), SEEK_SET)) {
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
		if (isExtensionB) {
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
		hdr[0x0e] = trdHead.info.freeSector;
		hdr[0x0f] = trdHead.info.freeTrack;

		if (fseek(ff, fatPos, SEEK_SET)) {
			Error("TRD image has wrong format", fname, IF_FIRST); return 0;
		}
		if (16UL != fwrite(hdr, 1, 16, ff)) {
			Error("TRD FAT Write error (file damaged)", fname, IF_FIRST); return 0;
		}
	}

	// update next free sector/track position
	trdHead.info.freeTrack += (secsLength + trdHead.info.freeSector)>>4;
	trdHead.info.freeSector = (secsLength + trdHead.info.freeSector) & 0x0F;
	// update remaining free sectors
	trdHead.info.numOfFreeSectors -= secsLength;
	if (!addplace) ++trdHead.info.numOfFiles;
	// write disc info
	if (fseek(ff, 8 * STrdDisc::SECTOR_SZ, SEEK_SET)) {
		Error("TRD image has wrong format", fname, IF_FIRST); return 0;
	}
	if (1 != fwrite(&trdHead.info, sizeof(STrdDisc), 1, ff)) {
		Error("Disc info write error", fname, IF_FIRST); return 0;
	}

	fclose(ff);
	return 1;
}
