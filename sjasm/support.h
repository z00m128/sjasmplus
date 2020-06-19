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

extern const char pathBadSlash;
extern const char pathGoodSlash;

#if defined (_MSC_VER)

#define _CRT_SECURE_NO_WARNINGS 1

// #define FOPEN(pFile, filename, mode) fopen_s(&pFile, filename, mode)
// #define FOPEN_ISOK(pFile, filename, mode) (fopen_s(&pFile, filename, mode) == 0)

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

#define FOPEN(pFile, filename, mode) (pFile = fopen(filename, mode))
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
