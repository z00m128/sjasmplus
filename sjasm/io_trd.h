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

// io_trd.h

#ifndef __IO_TRD
#define __IO_TRD

enum ETrdFileName { OK, INVALID_EXTENSION, THREE_LETTER_EXTENSION };

int TRD_SaveEmpty(const char* fname, const char label[8]);
ETrdFileName TRD_FileNameToBytes(const char* inputName, byte binName[12], int & nameL);
int TRD_AddFile(const char* fname, const char* fhobname, int start, int length, int autostart, bool replace, bool addplace, int lengthMinusVars = -1);

/**
 * @brief Checks TRD file and return absolute offset + length into the raw file.
 *
 * @param trdname filename of the TRD image (will be passed to GetPath(...))
 * @param filename filename of the requested file inside the TRD image
 * @param offset data offset (0 or more), and return value = absolute offset into TRD file
 * @param length data length (1 or more or INT_MAX to include all), and return value = data length
 * @return int 0 when error, 1 when offset + length are valid values into TRD image file
 */
int TRD_PrepareIncFile(const char* trdname, const char* filename, aint & offset, aint & length);

#endif

//eof io_trd.h
