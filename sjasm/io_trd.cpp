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
	byte		addressLo;		// sometimes: other two extension letters for 8.3 naming scheme
	byte		addressHi;		// can't be `word` because of BE-hosts support
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

	static long fileOffset(const long track, const long sector) {
		return (track * SECTOR_SZ * SECTORS_PER_TRACK) + (sector * SECTOR_SZ);
	}

	void swapEndianness();
	bool writeToFile(FILE *ftrd);
}
#ifndef _MSC_VER
	__attribute__((packed));
#else
	;
#pragma pack(pop)
#endif
static_assert(STrdDisc::SECTOR_SZ == sizeof(STrdDisc), "TRD disc info is expected to be 256 bytes long!");

void STrdDisc::swapEndianness() {
	numOfFreeSectors = sj_bswap16(numOfFreeSectors);
}

bool STrdDisc::writeToFile(FILE *ftrd) {
	if (Options::IsBigEndian) swapEndianness();		// fix endianness in binary form before write
	if (1 != fwrite(this, sizeof(STrdDisc), 1, ftrd)) return false;
	if (Options::IsBigEndian) swapEndianness();		// revert endianness back to native host form
	return true;
}

#ifdef _MSC_VER
#pragma pack(push, 1)
#endif
struct STrdHead {
	constexpr static size_t NUM_OF_FILES_MAX = 128;		// 8 sectors with 16B records

	STrdFile	catalog[NUM_OF_FILES_MAX];
	STrdDisc	info;

	void swapEndianness();
	bool readFromFile(FILE *ftrd);
	bool writeToFile(FILE *ftrd);
}
#ifndef _MSC_VER
	__attribute__((packed));
#else
	;
#pragma pack(pop)
#endif
static_assert(9 * STrdDisc::SECTOR_SZ == sizeof(STrdHead), "TRD catalog and info area should be 9 sectors long!");

void STrdHead::swapEndianness() {
	info.swapEndianness();
	for (STrdFile & file : this->catalog) file.length = sj_bswap16(file.length);
}

bool STrdHead::readFromFile(FILE *ftrd) {
	if (1 != fread(this, sizeof(STrdHead), 1, ftrd)) return false;
	if (Options::IsBigEndian) swapEndianness();
	return this->info.isTrdInfo();
}

bool STrdHead::writeToFile(FILE *ftrd) {
	if (Options::IsBigEndian) swapEndianness();		// fix endianness in binary form before write
	if (1 != fwrite(this, sizeof(STrdHead), 1, ftrd)) return false;
	if (Options::IsBigEndian) swapEndianness();		// revert endianness back to native host form
	return true;
}

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
		if (!discInfo.writeToFile(ff)) return 0;
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
	constexpr int baseSz = int(STrdFile::NAME_BASE_SZ);	// pre-cast to `int` (vs `nameL`)
	const char* ext = strrchr(inputName, '.');
	const int maxL = std::min(baseSz, ext ? int(ext-inputName) : baseSz);
	nameL = 0;
	while (inputName[nameL] && nameL < maxL) {
		binName[nameL] = inputName[nameL];
		++nameL;
	}
	while (nameL < baseSz) binName[nameL++] = ' ';
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
	switch (binName[baseSz]) {
		case 'B': case 'C': case 'D': case '#':
			return OK;
	}
	return INVALID_EXTENSION;
}

static int ReturnWithError(const char* errorText, const char* fname, FILE* fileToClose) {
	if (nullptr != fileToClose) fclose(fileToClose);
	Error(errorText, fname, IF_FIRST);
	return 0;
}

// use autostart == -1 to disable it (the valid autostart is 0..9999 as line number of BASIC program)
int TRD_AddFile(const char* fname, const char* fhobname, int start, int length, int autostart, bool replace, bool addplace, int lengthMinusVars) {

	// do some preliminary checks with file name and autostart - prepare final catalog entry data
	union {
		STrdFile trdf;			// structure to hold future form of catalog record about new file
		byte longFname[12];		// 12 byte access for TRD_FileNameToBytes (to avoid LGTM alert)
	};
	int Lname = 0;
	// this will overwrite also first byte of "trd.length" (12 bytes are affected, not just 11)
	const ETrdFileName nameWarning = TRD_FileNameToBytes(fhobname, longFname, Lname);
	const bool isExtensionB = ('B' == trdf.ext);
	if (!addplace && warningNotSuppressed()) {
		if (INVALID_EXTENSION == nameWarning) {
			WarningById(W_TRD_EXT_INVALID, fhobname);
		}
		if (THREE_LETTER_EXTENSION == nameWarning) {
			WarningById(W_TRD_EXT_3, fhobname);
			if (isExtensionB) {
				WarningById(W_TRD_EXT_B, fhobname);
				Lname = STrdFile::NAME_FULL_SZ;
			}
		}
	}
	if (0 <= autostart && (!isExtensionB || 9999 < autostart)) {
		Warning("zx.trdimage_add_file: autostart value is BASIC program line number (0..9999) (in lua use -1 otherwise).");
		autostart = -1;
	}
	if (-1 != lengthMinusVars) {
		if (!isExtensionB) {
			Error("zx.trdimage_add_file: length without variables is for BASIC files only.");
			return 0;
		} else if (lengthMinusVars < 0 || length < lengthMinusVars) {
			Error("zx.trdimage_add_file: length without variables is not in <0..length> range.");
			return 0;
		}
	}

	// more validations - for Lua (or SAVETRD letting wrong values go through)
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
	trdf.length = word(length);
	trdf.sectorLength = byte((length + 255 + (0 <= autostart ? 4 : 0))>>8);
	if (isExtensionB) {
		trdf.addressLo = byte(length);
		trdf.addressHi = byte(length>>8);
		if (-1 != lengthMinusVars) trdf.length = word(lengthMinusVars);
	} else {
		if (Lname <= int(STrdFile::NAME_FULL_SZ)) {
			trdf.addressLo = byte(start);	// single letter extension => "start" field is used for start value
			trdf.addressHi = byte(start>>8);
		}
	}
	if (0 == trdf.sectorLength) {	// can overflow only when 0xFF00 length with autostart => 0
		Error("zx.trdimage_add_file: sector length over 0xFF max", bp, PASS3);
		return 0;
	}

	// read 9 sectors of disk into "trdHead" (contains root directory catalog and disk info data)
	FILE* ff;
	STrdHead trdHead;
	if (!FOPEN_ISOK(ff, fname, "r+b")) Error("Error opening file", fname, FATAL);
	if (!trdHead.readFromFile(ff)) {
		return ReturnWithError("TRD image read error", fname, ff);
	}

	// check if the requested file is already on the disk
	// in "add" or "replace" mode also delete all extra ones with the same name, keeping only last
	unsigned fileIndex = STrdHead::NUM_OF_FILES_MAX;
	for (unsigned fatIndex = 0; fatIndex < STrdHead::NUM_OF_FILES_MAX; ++fatIndex) {
		auto & entry = trdHead.catalog[fatIndex];
		if (0 == entry.filename[0]) break;		// beyond last FAT record, finish the loop
		if (memcmp(entry.filename, trdf.filename, Lname)) continue;	// different file name -> continue
		// in "add" or "replace" mode delete the previous incarnations of this filename (returns only last one)
		if ((addplace || replace) && STrdHead::NUM_OF_FILES_MAX != fileIndex) {
			// delete the previously found file (it stays in catalog as deleted file)
			trdHead.catalog[fileIndex].filename[0] = 1;
			++trdHead.info.numOfDeleted;
		}
		// remember the position of last entry with the requested file name
		fileIndex = fatIndex;
	}

	// check and process [un]found file based on the requested mode
	if (addplace) {
		// in "add" mode the file must already exist
		if (STrdHead::NUM_OF_FILES_MAX == fileIndex) {
			return ReturnWithError("TRD image does not have a specified file to add data", fname, ff);
		}
	} else if (replace) {
		// in "replace" mode delete also the last occurance
		if (STrdHead::NUM_OF_FILES_MAX != fileIndex) {
			auto & entry = trdHead.catalog[fileIndex];
			if (fileIndex + 1 == trdHead.info.numOfFiles) {		// if last file in the catalog
				// It's last file of catalog, erase it as if it was not on disc at all
				// verify if the free space starts just where last file ends (integrity of TRD image)
				const byte nextTrack = ((entry.sectorLength + entry.startSector) >> 4) + entry.startTrack;
				const byte nextSector = (entry.sectorLength + entry.startSector) & 0x0F;
				// if file connects to first free sector, salvage the space back
				if (nextSector != trdHead.info.freeSector || nextTrack != trdHead.info.freeTrack) {
					return ReturnWithError("TRD free sector was not connected to last file", fname, ff);
				}
				// return the sectors used by file back to "free sectors" pool
				trdHead.info.freeSector = entry.startSector;
				trdHead.info.freeTrack = entry.startTrack;
				trdHead.info.numOfFreeSectors += entry.sectorLength;
				// delete the file (wipe catalog entry completely as if it was not written)
				--trdHead.info.numOfFiles;
				entry.filename[0] = 0;
			} else {
				// delete the file (but it stays in catalog as deleted file) (and new file will be added)
				entry.filename[0] = 1;
				++trdHead.info.numOfDeleted;
			}
		}
		fileIndex = trdHead.info.numOfFiles;
	} else {
		// in "normal" mode warn when file already exists
		if (STrdHead::NUM_OF_FILES_MAX != fileIndex && warningNotSuppressed()) {
			// to keep legacy behaviour of older sjasmplus versions, this is just warning
			// and the same file will be added to end of directory any way
			WarningById(W_TRD_DUPLICATE, fname);
		}
		fileIndex = trdHead.info.numOfFiles;
	}

	// fileIndex should point to valid record in catalog, verify the status and free space
	if (STrdHead::NUM_OF_FILES_MAX == fileIndex) {
		return ReturnWithError("TRD image is full of files", fname, ff);
	}
	auto & target = trdHead.catalog[fileIndex];
	const bool isNewTarget = !!memcmp(target.filename, trdf.filename, Lname);
	if (0 != target.filename[0] && isNewTarget) {
		// the target entry must have zero as first char or must have requested name
		return ReturnWithError("TRD inconsistent catalog data", fname, ff);
	}
	if (trdHead.info.numOfFreeSectors < trdf.sectorLength) {
		return ReturnWithError("TRD image has not enough free space", fname, ff);
	}
	const int keepSectors = addplace ? target.sectorLength : 0;
	if (0xFF < keepSectors + int(trdf.sectorLength)) {
		return ReturnWithError("zx.trdimage_add_file: new sector length over 0xFF max",  fname, ff);
	}

	// set the target record in catalog
	if (addplace) {
		// just add sector length, keep target.length at old value (no idea why, ask Dart Alver)
		target.sectorLength += trdf.sectorLength;
		// keeps basically EVERYTHING in the old catalog entry as it was, only sector length is raised
	} else {
		// finalize the prepared catalog entry record with starting position
		if (isNewTarget) {
			trdf.startSector = trdHead.info.freeSector;
			trdf.startTrack = trdHead.info.freeTrack;
		} else {
			trdf.startSector = target.startSector;
			trdf.startTrack = target.startTrack;
		}
		// write it to the actual catalog
		target = trdf;
	}

	// in "add" mode shift all data sectors to make room for the newly added ones
	if (addplace) {
		const long targetPos = STrdDisc::fileOffset(target.startTrack, target.startSector);
		const long oldTargetEndPos = targetPos + (keepSectors * STrdDisc::SECTOR_SZ);
		const long newTargetEndPos = targetPos + (target.sectorLength * STrdDisc::SECTOR_SZ);
		const long freePos = STrdDisc::fileOffset(trdHead.info.freeTrack, trdHead.info.freeSector);
		if (oldTargetEndPos < freePos) {	// some data after old file -> shift them a bit
			// first move the data inside the TRD image
			size_t dataToMoveLength = freePos - oldTargetEndPos;
			byte* dataToMove = new byte[dataToMoveLength];
			if (nullptr == dataToMove) ErrorOOM();
			if (fseek(ff, oldTargetEndPos, SEEK_SET)) {
				return ReturnWithError("TRD image has wrong format", fname, ff);
			}
			if (dataToMoveLength != fread(dataToMove, 1, dataToMoveLength, ff)) {
				return ReturnWithError("TRD read error", fname, ff);
			}
			if (fseek(ff, newTargetEndPos, SEEK_SET)) {
				return ReturnWithError("TRD image has wrong format", fname, ff);
			}
			// first modification of the provided TRD file (since here, if something fails, the file is damaged)
			if (dataToMoveLength != fwrite(dataToMove, 1, dataToMoveLength, ff)) {
				return ReturnWithError("TRD write error", fname, ff);
			}
			delete[] dataToMove;
			// adjust all catalog entries which got the content sectors shifted
			for (unsigned entryIndex = 0; entryIndex < STrdHead::NUM_OF_FILES_MAX; ++entryIndex) {
				auto & entry = trdHead.catalog[entryIndex];
				if (0 == entry.filename[0]) break;		// beyond last FAT record, finish the loop
				if (entryIndex == fileIndex) continue;	// ignore the "target" itself
				// check if all files in catalog after target are also affected by content shift and vice versa
				const long entryPos = STrdDisc::fileOffset(entry.startTrack, entry.startSector);
				if ((entryIndex < fileIndex) != (entryPos < targetPos)) {
					return ReturnWithError("TRD inconsistent catalog data", fname, ff);
				}
				if (entryPos < targetPos) continue;		// this one is ahead of the target file
				// the file got shifted content => update the catalog entry
				entry.startTrack += (trdf.sectorLength + entry.startSector) >> 4;
				entry.startSector = (trdf.sectorLength + entry.startSector) & 0x0F;
			}
		} // END if (oldTargetEndPos < freePos)
	} // END if (addplace)

	// save the new data into the TRD (content sectors)
	long writePos = STrdDisc::fileOffset(target.startTrack, target.startSector);
	writePos += keepSectors * STrdDisc::SECTOR_SZ;
	if (fseek(ff, writePos, SEEK_SET)) {
		return ReturnWithError("TRD image has wrong format", fname, ff);
	}
	if (!SaveRAM(ff, start, length)) {
		return ReturnWithError("TRD write device RAM error", fname, ff);
	}
	if (!addplace && 0 <= autostart) {
		byte abin[] {0x80, 0xAA, static_cast<byte>(autostart), static_cast<byte>(autostart>>8)};
		if (4 != fwrite(abin, 1, 4, ff)) {
			return ReturnWithError("Write error", fname, ff);
		}
	}

	// update next free sector/track position
	trdHead.info.freeTrack += (trdf.sectorLength + trdHead.info.freeSector) >> 4;
	trdHead.info.freeSector = (trdf.sectorLength + trdHead.info.freeSector) & 0x0F;
	// update remaining free sectors
	trdHead.info.numOfFreeSectors -= trdf.sectorLength;
	if (isNewTarget) ++trdHead.info.numOfFiles;

	// update whole catalog and disc info with modified data
	if (fseek(ff, 0, SEEK_SET)) {
		return ReturnWithError("TRD image has wrong format", fname, ff);
	}
	if (!trdHead.writeToFile(ff)) {
		return ReturnWithError("TRD write error", fname, ff);
	}

	fclose(ff);
	return 1;
}

int TRD_PrepareIncFile(const char* trdname, const char* filename, aint & offset, aint & length) {
	// parse filename into TRD file form (max 8+3, don't warn about 3-letter extension)
	byte trdFormName[12];
	int Lname = 0;
	TRD_FileNameToBytes(filename, trdFormName, Lname);	// ignore diagnostic info about extension

	// read 9 sectors of disk into "trdHead" (contains root directory catalog and disk info data)
	FILE* ff;
	STrdHead trdHead;
	char* fullTrdName = GetPath(trdname);
	if (!FOPEN_ISOK(ff, fullTrdName, "rb")) Error("[INCTRD] Error opening file", trdname, FATAL);
	free(fullTrdName);
	fullTrdName = nullptr;
	if (!trdHead.readFromFile(ff)) {
		return ReturnWithError("TRD image read error", trdname, ff);
	}
	fclose(ff);
	ff = nullptr;

	// find the requested file
	unsigned fileIndex = 0;
	for (fileIndex = 0; fileIndex < STrdHead::NUM_OF_FILES_MAX; ++fileIndex) {
		const auto & entry = trdHead.catalog[fileIndex];
		if (0 == entry.filename[0]) {	// beyond last FAT record, finish the loop
			fileIndex = STrdHead::NUM_OF_FILES_MAX;
			break;
		} else {
			if (!memcmp(entry.filename, trdFormName, Lname)) break;	// found!
		}
	}
	if (STrdHead::NUM_OF_FILES_MAX == fileIndex) {
		return ReturnWithError("[INCTRD] File not found in TRD image", filename, ff);
	}

	// calculate absolute file offset and length + validate input values
	const auto & entry = trdHead.catalog[fileIndex];
	if (INT_MAX == length) {
		length = entry.length;
		length -= offset;
	}
	const aint fileOffset = STrdDisc::fileOffset(entry.startTrack, entry.startSector);
	const aint fileEnd = fileOffset + entry.length;
	offset += fileOffset;

	// report success when resulting offset + length fits into the file definition
	if (fileOffset <= offset && (offset + length) <= fileEnd && 0 < length) return 1;

	return ReturnWithError("[INCTRD] File too short to cover requested offset and length", bp, ff);
}
