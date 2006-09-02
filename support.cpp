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

#ifndef WIN32

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

long GetTickCount() {
	struct timeval tv1[1];
	gettimeofday(tv1, 0);
	return tv1->tv_usec / 1000;
}

#endif

//eof support.cpp
