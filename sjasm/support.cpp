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

#if defined (_WIN32) || defined (__CYGWIN__)
std::filesystem::path SJ_force_slash(const std::filesystem::path path) {
	delim_string_t pathStr { path.string(), DT_COUNT };
	SJ_FixSlashes(pathStr, false);
	return pathStr.first;
}
#endif

void SJ_FixSlashes(delim_string_t & str, bool do_warning) {
	if (std::string::npos == str.first.find('\\')) return;
	if (do_warning) WarningById(W_BACKSLASH, str.first.c_str());
	std::replace(str.first.begin(), str.first.end(), '\\', '/');
}

FILE* SJ_fopen(const std::filesystem::path & fname, const char* mode) {
	if (nullptr == mode || fname.empty()) return nullptr;
	return fopen(fname.string().c_str(), mode);
}

#ifndef WIN32

long GetTickCount() {
	struct timeval tv1[1];
	gettimeofday(tv1, 0);
	return tv1->tv_sec * 1000 + tv1->tv_usec / 1000;
}

#endif	// #ifndef WIN32

#if defined (_WIN32) || defined (__CYGWIN__)
	// cygwin: O_BINARY is in fcntl.h, setmode is in io.h
	// MSVC: _O_BINARY and _setmode
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

#if defined (_WIN32)
static bool restoreWinMode = false;
static HANDLE hWinOut;
static HANDLE hWinIn;
static DWORD dwOriginalOutMode = 0, dwOriginalInMode = 0;

void restoreOriginalConsoleMode() {
	if (!restoreWinMode) return;
	SetConsoleMode(hWinIn, dwOriginalInMode);
	SetConsoleMode(hWinOut, dwOriginalOutMode);
}
#endif

bool autoColorsDetection() {
	// existence of NO_COLOR env.var. disables auto-colors: http://no-color.org/
	const char* envNoColor = std::getenv("NO_COLOR");
	if (envNoColor) return false;
	// check either TERM variable or in windows try to enable virtual terminal emulation
#if defined (_WIN32)
	// check if running inside console with isatty
	if (!_isatty(_fileno(stderr))) return false;	// redirected to file? don't color
	// Try to set output mode to handle virtual terminal sequences (VT100)
	hWinOut = GetStdHandle(STD_OUTPUT_HANDLE);
	hWinIn = GetStdHandle(STD_INPUT_HANDLE);
	if (hWinOut != INVALID_HANDLE_VALUE && hWinIn != INVALID_HANDLE_VALUE) {
		DWORD dwOutMode = 0;
		DWORD dwInMode = 0;
		if (GetConsoleMode(hWinOut, &dwOutMode) && GetConsoleMode(hWinIn, &dwInMode)) {
			dwOriginalInMode = dwInMode;
			dwOriginalOutMode = dwOutMode;
			restoreWinMode = true;
			std::atexit(restoreOriginalConsoleMode);
			dwOutMode |= ENABLE_VIRTUAL_TERMINAL_PROCESSING;
			dwInMode |= ENABLE_VIRTUAL_TERMINAL_INPUT;
			return SetConsoleMode(hWinOut, dwOutMode) && SetConsoleMode(hWinIn, dwInMode);
		}
	}
	return false;
#else
	// check if running inside console with isatty
	if (!isatty(STDERR_FILENO)) return false;		// redirected to file? don't color
	// try to auto-detect ANSI-colour support (true if env.var. TERM exist and contains "color" substring)
	const char* envTerm = std::getenv("TERM");
	return envTerm && strstr(envTerm, "color");
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
