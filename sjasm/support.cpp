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

#ifdef UNDER_CE

#endif

// http://legacy.imatix.com/html/sfl/sfl282.htm
char* strpad(char* string, char ch, aint length) {
	int cursize;
	cursize = strlen (string);          /*  Get current length of string     */
	while (cursize < length)            /*  Pad until at desired length      */
		string [cursize++] = ch;

	string [cursize++] = '\0';          /*  Add terminating null             */
	return (string);                    /*    and return to caller           */
}

#if !defined (_MSC_VER) || defined (UNDER_CE)

void GetCurrentDirectory(int whatever, char* pad) {
	pad[0] = 0;
}

int SearchPath(char* oudzp, char* filename, char* whatever, int maxlen, char* nieuwzp, char** ach) {
	FILE* fp;
	char* p, * f;
	if (filename[0] == '/') {
		STRCPY(nieuwzp, maxlen, filename);
	} else {
		STRCPY(nieuwzp, maxlen, oudzp);
		if (*nieuwzp && nieuwzp[strlen(nieuwzp)] != '/') {
			STRCAT(nieuwzp, maxlen, "/");
		}
		STRCAT(nieuwzp, maxlen, filename);
	}
	if (ach) {
		p = f = nieuwzp;
		while (*p) {
			if (*p == '/') {
				f = p + 1;
			} ++p;
		}
		*ach = f;
	}
	if (FOPEN_ISOK(fp, nieuwzp, "r")) {
		fclose(fp);
		return 1;
	}
	return 0;
}

char* strset(char* str, char val) {
	//non-aligned
	char* pByte = str;
	while (((unsigned long)pByte) & 3) {
		if (*pByte) {
			*pByte++ = val;
		} else {
			return str;
		}
	}

	//4-byte aligned
	unsigned long* pBlock = (unsigned long*) pByte;
	unsigned long a;
	unsigned long dwVal = val | val << 8 | val << 16 | val << 24;
	for (; ;) {
		a = *pBlock;
		a &= 0x7f7f7f7f;
		a -= 0x01010101;
		if (a & 0x80808080) {
			break;
		} else {
			*pBlock++ = dwVal;
		}
	}

	//non-aligned
	pByte = (char*) pBlock;
	while (*pByte) {
		*pByte++ = val;
	}
	return str;
}

#ifndef WIN32
long GetTickCount() {
	struct timeval tv1[1];
	gettimeofday(tv1, 0);
	return tv1->tv_usec / 1000;
}
#endif

#endif

void LuaShellExec(char *command) {
#ifdef UNDER_CE
	//_wsystem(_towchar(command));
	SHELLEXECUTEINFO info;
	info.cbSize = sizeof(SHELLEXECUTEINFO);
	info.fMask = NULL;
    info.hwnd = NULL;
    info.lpVerb = NULL;
    info.lpFile = _totchar(command);
    info.lpParameters = NULL;
    info.lpDirectory = NULL;
    info.nShow = SW_MAXIMIZE;
    info.hInstApp = NULL;
	ShellExecuteEx(&info);
#else
#ifdef WIN32

	WinExec(command, SW_SHOWNORMAL);
#else	
	system(command);
#endif
#endif
}

//eof support.cpp
