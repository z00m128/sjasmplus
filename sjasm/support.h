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

// support.h

constexpr char pathBadSlash = '\\';
constexpr char pathGoodSlash = '/';

////////////// <endian.h> and the need of `htobe16 / htole16 / ...` //////////////////////////////////////////////
// __has_include should be supported from GCC 5+ and VS2015
//
// IMO the <endian.h> should have been standartized in last 30 years (plenty of time to agree on *some* variant)
//
// if you have platform where this fails to build, ask the platform vendor why they can't have
// what 70% of current computers used to build SW (= linux) has, I had enough of headache with it
#if __has_include(<endian.h>)
#  include <endian.h> // gnu libc normally provides, linux
#elif __has_include(<machine/endian.h>)
#  include <machine/endian.h> //open bsd, macos
#elif __has_include(<sys/param.h>)
#  include <sys/param.h> // mingw, some bsd (not open/macos)
#elif __has_include(<sys/isadefs.h>)
#  include <sys/isadefs.h> // solaris
#elif __has_include(<libkern/OSByteOrder.h>) // macos second variant
#  include <libkern/OSByteOrder.h>
#  define htobe16(x) OSSwapHostToBigInt16(x)
#  define htole16(x) OSSwapHostToLittleInt16(x)
#  define be16toh(x) OSSwapBigToHostInt16(x)
#  define le16toh(x) OSSwapLittleToHostInt16(x)
#  define htobe32(x) OSSwapHostToBigInt32(x)
#  define htole32(x) OSSwapHostToLittleInt32(x)
#  define be32toh(x) OSSwapBigToHostInt32(x)
#  define le32toh(x) OSSwapLittleToHostInt32(x)
#else
#  error "No <endian.h> solution found on your platform"
#endif

#if defined (_MSC_VER)

#define _CRT_SECURE_NO_WARNINGS 1

// #define FOPEN(pFile, filename, mode) fopen_s(&pFile, filename, mode)
// #define FOPEN_ISOK(pFile, filename, mode) (fopen_s(&pFile, filename, mode) == 0)

#define strcasecmp(s1, s2) stricmp(s1, s2)

#else

#include <sys/time.h>
#if !defined(__MINGW32__)
#include <sys/wait.h>
#endif
#include <unistd.h>

#endif

#ifndef TCHAR
#define TCHAR char
#endif
#ifndef WIN32
long GetTickCount();
#endif

void SJ_GetCurrentDirectory(int, char*);
int SJ_SearchPath(const char* oudzp, const char* filename, const char* /*extension*/, int maxlen, char* nieuwzp, char** ach);

FILE* dbg_fopen(const char* fname, const char* modes);

#define FOPEN_ISOK(pFile, filename, mode) ((pFile = fopen(filename, mode)) != NULL)

#define STRDUP strdup
#define STRCAT(strDestination, sizeInBytes, strSource) strncat(strDestination, strSource, sizeInBytes)
#define STRCPY(strDestination, sizeInBytes, strSource) strcpy(strDestination, strSource)
#define STRNCPY(strDestination, sizeInBytes, strSource, count) strncpy(strDestination, strSource, count)
#define SPRINTF1(buffer, sizeOfBuffer, format, arg1) snprintf(buffer, sizeOfBuffer, format, arg1)
#define SPRINTF2(buffer, sizeOfBuffer, format, arg1, arg2) snprintf(buffer, sizeOfBuffer, format, arg1, arg2)
#define SPRINTF3(buffer, sizeOfBuffer, format, arg1, arg2, arg3) snprintf(buffer, sizeOfBuffer, format, arg1, arg2, arg3)
#define SPRINTF4(buffer, sizeOfBuffer, format, arg1, arg2, arg3, arg4) snprintf(buffer, sizeOfBuffer, format, arg1, arg2, arg3, arg4)
#define STRNCAT(strDest, bufferSizeInBytes, strSource, count) strncat(strDest, strSource, count)
#define STRSTR(str, strSearch) strstr(str, strSearch)
#define STRCHR(str, charToSearch) strchr(str, charToSearch)

void switchStdOutIntoBinaryMode();

#ifdef USE_LUA
void LuaShellExec(char *command);
#endif //USE_LUA

#ifndef WEXITSTATUS
# define WEXITSTATUS(exitstatus) (exitstatus)
#endif

//eof support.h
