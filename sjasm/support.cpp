/*

  SjASMPlus Z80 Cross Compiler

  This is modified sources of SjASM by Aprisobal - aprisobal@tut.by

  Copyright (c) 2005 Sjoerd Mastijn

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

// support.cpp

#include "sjdefs.h"

FILE* SJ_fopen(const char* fname, const char* mode) {
	if (nullptr == fname || nullptr == mode || !*fname) return nullptr;
	return fopen(fname, mode);
}

/*
FILE* dbg_fopen(const char* fname, const char* modes) {
	FILE* f = fopen(fname, modes);
	printf("fopen = %p modes [%s]\tname (%lu) [%s]\n", (void*)f, modes, strlen(fname), fname);
	return f;
}
*/

void SJ_GetCurrentDirectory(int whatever, char* pad) {
	pad[0] = 0;
	//TODO implement this one? And decide what to do with it?
	// Will affect "--fullpath" paths if implemented correctly (as GetCurrentDirectory on windows)
}

static bool isAnySlash(const char c) {
	return pathGoodSlash == c || pathBadSlash == c;
}

/**
 * @brief Check if the path does start with MS windows drive-letter and colon, but accepts
 * only absolute form with slash after colon, otherwise warns about relative way not supported.
 *
 * @param filePath p_filePath: filename to check
 * @return bool true if the filename contains drive-letter with ABSOLUTE path
 */
static bool isWindowsDrivePathStart(const char* filePath) {
	if (!filePath || !filePath[0] || ':' != filePath[1]) return false;
	const char driveLetter = toupper(filePath[0]);
	if (driveLetter < 'A' || 'Z' < driveLetter) return false;
	if (!isAnySlash(filePath[2])) {
		Warning("Relative file path with drive letter detected (not supported)", filePath, W_EARLY);
		return false;
	}
	return true;
}

int SJ_SearchPath(const char* oudzp, const char* filename, const char*, int maxlen, char* nieuwzp, char** ach) {
	assert(nieuwzp);
	*nieuwzp = 0;
	if (nullptr == filename) return 0;
	if (isAnySlash(filename[0]) || isWindowsDrivePathStart(filename)) {
		STRCPY(nieuwzp, maxlen, filename);
	} else {
		STRCPY(nieuwzp, maxlen, oudzp);
		if (*nieuwzp) {
			char *lastChar = nieuwzp + strlen(nieuwzp) - 1;
			if (!isAnySlash(*lastChar)) {
				lastChar[1] = pathGoodSlash;
				lastChar[2] = 0;
			}
		}
		STRCAT(nieuwzp, maxlen, filename);
	}
	if (ach) {
		char* p = *ach = nieuwzp;
		while (*p) {
			if (isAnySlash(*p++)) *ach = p;
		}
	}
	FILE* fp;
	if (FOPEN_ISOK(fp, nieuwzp, "r")) {
		fclose(fp);
		return 1;
	}
	return 0;
}

#ifndef WIN32

long GetTickCount() {
	struct timeval tv1[1];
	gettimeofday(tv1, 0);
	return tv1->tv_sec * 1000 + tv1->tv_usec / 1000;
}

#endif	// #ifndef WIN32

#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#endif

void switchStdOutIntoBinaryMode() {
#ifdef __CYGWIN__
	setmode(1, O_BINARY);
#elif _WIN32
	_setmode(1, _O_BINARY);
#else
	// nothing on systems with no text-vs-binary mode
#endif
}

#ifdef USE_LUA

void LuaShellExec(const char *command) {
#ifdef WIN32
	WinExec(command, SW_SHOWNORMAL);
#else
	int ret = system(command);
	if ( ret == -1 ) {
		Error("[LUASHELEXEC] Unable to start child process for command", command, IF_FIRST);
	}
#endif
}
#endif //USE_LUA

//eof support.cpp
