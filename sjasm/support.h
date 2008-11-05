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

#ifdef UNDER_CE
void WriteOutput(char Char);
void WriteOutput(char* String);
void WriteOutput(int Number);
void WriteOutput(float Number);
void WriteOutput(unsigned char Number);
void WriteOutput(long Number);
void WriteOutput(unsigned long Number);
void WriteOutput(_TCHAR* String);
void WriteOutputEOF();
#endif

char* strpad(char* string, char ch, aint length);

#if defined (_MSC_VER) && !defined (UNDER_CE)

#define STRDUP _strdup
#define STRSET(str, sizeInBytes, c) _strset_s(str, sizeInBytes, c)
#define STRCAT(strDestination, sizeInBytes, strSource) strcat_s(strDestination, sizeInBytes, strSource)
#define STRCPY(strDestination, sizeInBytes, strSource) strcpy_s(strDestination, sizeInBytes, strSource)
#define STRNCPY(strDestination, sizeInBytes, strSource, count) strncpy_s(strDestination, sizeInBytes, strSource, count)
#define FOPEN(pFile, filename, mode) fopen_s(&pFile, filename, mode)
#define FOPEN_ISOK(pFile, filename, mode) (fopen_s(&pFile, filename, mode) == 0)
#define SPRINTF1(buffer, sizeOfBuffer, format, arg1) sprintf_s(buffer, sizeOfBuffer, format, arg1)
#define SPRINTF2(buffer, sizeOfBuffer, format, arg1, arg2) sprintf_s(buffer, sizeOfBuffer, format, arg1, arg2)
#define SPRINTF3(buffer, sizeOfBuffer, format, arg1, arg2, arg3) sprintf_s(buffer, sizeOfBuffer, format, arg1, arg2, arg3)
#define STRNCAT(strDest, bufferSizeInBytes, strSource, count) strncat_s(strDest, bufferSizeInBytes, strSource, count)
#define STRSTR(str, strSearch) strstr(str, strSearch)

#else

#ifdef UNDER_CE
#include <time.h>
#else
#include <sys/time.h>
#include <unistd.h>
#endif

#ifndef TCHAR
#define TCHAR char
#endif
void GetCurrentDirectory(int, char*);
int SearchPath(char*, char*, char*, int, char*, char**);
char* strset(char* str, char val);
#ifndef WIN32
long GetTickCount();
#endif

#ifdef UNDER_CE
#define STRDUP _strdup
#else
#define STRDUP strdup
#endif
#define STRSET(str, sizeInBytes, c) strset(str, c)
#define STRCAT(strDestination, sizeInBytes, strSource) strcat(strDestination, strSource)
#define STRCPY(strDestination, sizeInBytes, strSource) strcpy(strDestination, strSource)
#define STRNCPY(strDestination, sizeInBytes, strSource, count) strncpy(strDestination, strSource, count)
#define FOPEN(pFile, filename, mode) (pFile = fopen(filename, mode))
#define FOPEN_ISOK(pFile, filename, mode) ((pFile = fopen(filename, mode)) != NULL)
#define SPRINTF1(buffer, sizeOfBuffer, format, arg1) sprintf(buffer, format, arg1)
#define SPRINTF2(buffer, sizeOfBuffer, format, arg1, arg2) sprintf(buffer, format, arg1, arg2)
#define SPRINTF3(buffer, sizeOfBuffer, format, arg1, arg2, arg3) sprintf(buffer, format, arg1, arg2, arg3)
#define STRNCAT(strDest, bufferSizeInBytes, strSource, count) strncat(strDest, strSource, count)
#define STRSTR(str, strSearch) strstr(str, strSearch)

#endif

void LuaShellExec(char *command);

//eof support.h
