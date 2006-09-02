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

// sjio.cpp

#include "sjdefs.h"

#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>

#define DESTBUFLEN 8192

char rlbuf[4096 * 2]; //x2 to prevent errors
int RL_Readed;
bool rldquotes = false,rlsquotes = false,rlspace = false,rlcomment = false,rlcolon = false,rlnewline = true;
char* rlpbuf, * rlppos;

FILE* FP_UnrealList;

int EB[1024 * 64],nEB = 0;
char WriteBuffer[DESTBUFLEN];
FILE* FP_Input, * FP_Output, * FP_RAW;
FILE* FP_ListingFile,* FP_ExportFile = NULL;
aint eadres,epadres,IsSkipErrors = 0;
aint WBLength = 0;
char hd[] = {
	'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
};

void Error(char* fout, char* bd, int soort) {
	char* ep = ErrorLine;
	if (IsSkipErrors && PreviousErrorLine == CurrentLocalLine && soort != FATAL) {
		return;
	}
	if (soort == CATCHALL && PreviousErrorLine == CurrentLocalLine) {
		return;
	}
	if (soort == PASS1 && pass != 1) {
		return;
	}
	if ((soort == CATCHALL || soort == SUPPRESS || soort == PASS2) && pass < 2) {
		return;
	}
	IsSkipErrors = (soort == SUPPRESS);
	PreviousErrorLine = CurrentLocalLine;
	++ErrorCount;

	/*SPRINTF3(ep, LINEMAX2, "%s line %lu: %s", filename, CurrentLocalLine, fout);
	if (bd) {
		STRCAT(ep, LINEMAX2, ": "); STRCAT(ep, LINEMAX2, bd);
	}
	if (!strchr(ep, '\n')) {
		STRCAT(ep, LINEMAX2, "\n");
	}*/

	if (pass == 9999) {
		SPRINTF1(ep, LINEMAX2, "error: %s", fout);
	} else {
		SPRINTF3(ep, LINEMAX2, "%s(%lu) : error: %s", filename, CurrentLocalLine, fout);
	}

	if (bd) {
		STRCAT(ep, LINEMAX2, " : "); STRCAT(ep, LINEMAX2, bd);
	}
	if (!strchr(ep, '\n')) {
		STRCAT(ep, LINEMAX2, "\n");
	}

	if (FP_ListingFile) {
		fputs(ErrorLine, FP_ListingFile);
	}
	cout << ErrorLine;
	/*if (soort==FATAL) exit(1);*/
	if (soort == FATAL) {
		ExitASM(1);
	}
}

void Warning(char* fout, char* bd, int soort) {
	char* ep = ErrorLine;
	
	if (soort == PASS1 && pass != 1) {
		return;
	}
	if (soort == PASS2 && pass < 2) {
		return;
	}

	++WarningCount;
	
	if (pass == 9999) {
		SPRINTF1(ep, LINEMAX2, "warning: %s", fout);
	} else {
		SPRINTF3(ep, LINEMAX2, "%s(%lu) : warning: %s", filename, CurrentLocalLine, fout);
	}

	if (bd) {
		STRCAT(ep, LINEMAX2, " : ");
		STRCAT(ep, LINEMAX2, bd);
	}
	if (!strchr(ep, '\n')) {
		STRCAT(ep, LINEMAX2, "\n");
	}

	if (FP_ListingFile) {
		fputs(ErrorLine, FP_ListingFile);
	}
	cout << ErrorLine;
}

void WriteDest() {
	if (!WBLength) {
		return;
	}
	destlen += WBLength;
	if (fwrite(WriteBuffer, 1, WBLength, FP_Output) != WBLength) {
		Error("Write error (disk full?)", 0, FATAL);
	}
	if (FP_RAW && fwrite(WriteBuffer, 1, WBLength, FP_RAW) != WBLength) {
		Error("Write error (disk full?)", 0, FATAL);
	}
	WBLength = 0;
}

void PrintHEX8(char*& p, aint h) {
	aint hh = h&0xff;
	*(p++) = hd[hh >> 4];
	*(p++) = hd[hh & 15];
}

void listbytes(char*& p) {
	int i = 0;
	while (nEB--) {
		PrintHEX8(p, EB[i++]); *(p++) = ' ';
	}
	i = 4 - i;
	while (i--) {
		*(p++) = ' '; *(p++) = ' '; *(p++) = ' ';
	}
}

void listbytes2(char*& p) {
	for (int i = 0; i != 5; ++i) {
		PrintHEX8(p, EB[i]);
	}
	*(p++) = ' '; *(p++) = ' ';
}

void printCurrentLocalLine(char*& p) {
	aint v = CurrentLocalLine;
	switch (reglenwidth) {
	default:
		*(p++) = (unsigned char)('0' + v / 1000000); v %= 1000000;
	case 6:
		*(p++) = (unsigned char)('0' + v / 100000); v %= 100000;
	case 5:
		*(p++) = (unsigned char)('0' + v / 10000); v %= 10000;
	case 4:
		*(p++) = (unsigned char)('0' + v / 1000); v %= 1000;
	case 3:
		*(p++) = (unsigned char)('0' + v / 100); v %= 100;
	case 2:
		*(p++) = (unsigned char)('0' + v / 10); v %= 10;
	case 1:
		*(p++) = (unsigned char)('0' + v);
	}
	*(p++) = IncludeLevel > 0 ? '+' : ' ';
	*(p++) = IncludeLevel > 1 ? '+' : ' ';
	*(p++) = IncludeLevel > 2 ? '+' : ' ';
}

void PrintHEX32(char*& p, aint h) {
	aint hh = h&0xffffffff;
	*(p++) = hd[hh >> 28]; hh &= 0xfffffff;
	*(p++) = hd[hh >> 24]; hh &= 0xffffff;
	*(p++) = hd[hh >> 20]; hh &= 0xfffff;
	*(p++) = hd[hh >> 16]; hh &= 0xffff;
	*(p++) = hd[hh >> 12]; hh &= 0xfff;
	*(p++) = hd[hh >> 8];  hh &= 0xff;
	*(p++) = hd[hh >> 4];  hh &= 0xf;
	*(p++) = hd[hh];
}

void PrintHEX16(char*& p, aint h) {
	aint hh = h&0xffff;
	*(p++) = hd[hh >> 12]; hh &= 0xfff;
	*(p++) = hd[hh >> 8]; hh &= 0xff;
	*(p++) = hd[hh >> 4]; hh &= 0xf;
	*(p++) = hd[hh];
}

void listbytes3(int pad) {
	int i = 0,t;
	char* pp,* sp = pline + 3 + reglenwidth;
	while (nEB) {
		pp = sp;
		PrintHEX16(pp, pad);
		*(pp++) = ' '; t = 0;
		while (nEB && t < 32) {
			PrintHEX8(pp, EB[i++]); --nEB; ++t;
		}
		*(pp++) = '\n'; *pp = 0;
		if (FP_ListingFile) {
			fputs(pline, FP_ListingFile);
		}
		pad += 32;
	}
}

void ListFile() {
	char* pp = pline;
	aint pad;
	if (pass == 1 || !IsListingFileOpened || donotlist) {
		donotlist = nEB = 0; return;
	}
	if (!Options::ListingFName[0] || !FP_ListingFile) {
		return;
	}
	if (listmacro) {
		if (!nEB) {
			return;
		}
	}
	if ((pad = eadres) == (aint) - 1) {
		pad = epadres;
	}
	if (strlen(line) && line[strlen(line) - 1] != 10) {
		STRCAT(line, LINEMAX, "\n");
	} else {
		STRCPY(line, LINEMAX, "\n");
	}
	*pp = 0;
	printCurrentLocalLine(pp);
	PrintHEX16(pp, pad);
	*(pp++) = ' ';
	if (nEB < 5) {
		listbytes(pp);
		*pp = 0;
		if (listmacro) {
			STRCAT(pp, LINEMAX2, ">");
		}
		STRCAT(pp, LINEMAX2, line);
		fputs(pline, FP_ListingFile);
	} else if (nEB < 6) {
		listbytes2(pp); *pp = 0;
		if (listmacro) {
			STRCAT(pp, LINEMAX2, ">");
		}
		STRCAT(pp, LINEMAX2, line);
		fputs(pline, FP_ListingFile);
	} else {
		for (int i = 0; i != 12; ++i) {
			*(pp++) = ' ';
		}
		*pp = 0;
		if (listmacro) {
			STRCAT(pp, LINEMAX2, ">");
		}
		STRCAT(pp, LINEMAX2, line); 
		fputs(pline, FP_ListingFile); 
		listbytes3(pad);
	}
	epadres = CurAddress;
	eadres = (aint) - 1;
	nEB = 0;
	listdata = 0;
}

void ListFileSkip(char* line) {
	char* pp = pline;
	aint pad;
	if (pass == 1 || !IsListingFileOpened || donotlist) {
		donotlist = nEB = 0;
		return;
	}
	if (!Options::ListingFName[0] || !FP_ListingFile) {
		return;
	}
	if (listmacro) {
		return;
	}
	if ((pad = eadres) == (aint) - 1) {
		pad = epadres;
	}
	if (strlen(line) && line[strlen(line) - 1] != 10) {
		STRCAT(line, LINEMAX, "\n");
	}
	*pp = 0;
	printCurrentLocalLine(pp);
	PrintHEX16(pp, pad);
	*pp = 0;
	STRCAT(pp, LINEMAX2, "~            ");
	if (nEB) {
		Error("Internal error lfs", 0, FATAL);
	}
	if (listmacro) {
		STRCAT(pp, LINEMAX2, ">");
	}
	STRCAT(pp, LINEMAX2, line);
	fputs(pline, FP_ListingFile);
	epadres = CurAddress;
	eadres = (aint) - 1;
	nEB = 0;
	listdata = 0;
}

/* added */
void CheckPage() {
	if (Options::MemoryType == MT_NONE) {
		return;
	}
	int addadr = 0;
	switch (MemoryCPage) {
	case 0:
		addadr = 0x8000;
		break;
	case 1:
		addadr = 0xc000;
		break;
	case 2:
		addadr = 0x4000;
		break;
	case 3:
		addadr = 0x10000;
		break;
	case 4:
		addadr = 0x14000;
		break;
	case 5:
		addadr = 0x0000;
		break;
	case 6:
		addadr = 0x18000;
		break;
	case 7:
		addadr = 0x1c000;
		break;
	}
	if (MemoryCPage > 7) {
		addadr = 0x4000 * MemoryCPage;
	}
	if (PseudoORG) {
		if (adrdisp < 0xC000) {
			addadr = adrdisp - 0x4000;
		} else {
			addadr += adrdisp - 0xC000;
		}
	} else {
		if (CurAddress < 0xC000) {
			addadr = CurAddress - 0x4000;
		} else {
			addadr += CurAddress - 0xC000;
		}
	}
	MemoryPointer = MemoryRAM + addadr;
}

/* modified */
void Emit(int byte) {
	EB[nEB++] = byte;
	if (pass == 2) {
		WriteBuffer[WBLength++] = (char) byte;
		if (WBLength == DESTBUFLEN) {
			WriteDest();
		}
		/* (begin add) */
		if (Options::MemoryType != MT_NONE) {
			if (PseudoORG) {
				if (CurAddress >= 0x10000) {
					char buf[1024];
					SPRINTF1(buf, LINEMAX, "RAM limit exceeded %s", CurAddress);
					Error(buf, 0, FATAL);
				}
				*(MemoryPointer++) = (char) byte;
				if ((adrdisp & 0x3FFF) == 0x3FFF) {
					++adrdisp; ++CurAddress;
					CheckPage(); return;
				}
			} else {
				if (CurAddress >= 0x10000) {
					char buf[1024];
					SPRINTF1(buf, LINEMAX, "RAM limit exceeded %s", CurAddress);
					Error(buf, 0, FATAL);
				}
				*(MemoryPointer++) = (char) byte;
				if ((CurAddress & 0x3FFF) == 0x3FFF) {
					++CurAddress;
					CheckPage(); return;
				}
			}
		}
		/* (end add) */
	}
	if (PseudoORG) {
		++adrdisp;
	} /* added */
	++CurAddress;
}

void EmitByte(int byte) {
	eadres = CurAddress;
	Emit(byte);
}

void EmitBytes(int* bytes) {
	eadres = CurAddress;
	if (*bytes == -1) {
		Error("Illegal instruction", line, CATCHALL); *lp = 0;
	}
	while (*bytes != -1) {
		Emit(*bytes++);
	}
}

void EmitWords(int* words) {
	eadres = CurAddress;
	while (*words != -1) {
		Emit((*words) % 256);
		Emit((*words++) / 256);
	}
}

/* modified */
void EmitBlock(aint byte, aint len) {
	eadres = CurAddress;
	if (len) {
		EB[nEB++] = byte;
	}
	while (len--) {
		if (pass == 2) {
			WriteBuffer[WBLength++] = (char) byte; 
			if (WBLength == DESTBUFLEN) {
				WriteDest();
			} 
			/* (begin add) */
			if (Options::MemoryType != MT_NONE) {
				if (PseudoORG) {
					if (CurAddress >= 0x10000) {
						Error("RAM limit exceeded", 0, FATAL);
					}
					*(MemoryPointer++) = (char) byte;
					if ((adrdisp & 0x3FFF) == 0x3FFF) {
						++adrdisp; ++CurAddress;
						CheckPage(); continue;
					}
				} else {
					if (CurAddress >= 0x10000) {
						Error("RAM limit exceeded", 0, FATAL);
					}
					*(MemoryPointer++) = (char) byte;
					if ((CurAddress & 0x3FFF) == 0x3FFF) {
						++CurAddress;
						CheckPage(); continue;
					}
				}
			}
			/* (end add) */
		}
		if (PseudoORG) {
			++adrdisp;
		} /* added */
		++CurAddress;
	}
}

char* GetPath(char* fname, TCHAR** filenamebegin) {
	int g = 0;
	char* kip, nieuwzoekpad[MAX_PATH];
	g = SearchPath(CurrentDirectory, fname, NULL, MAX_PATH, nieuwzoekpad, filenamebegin);
	if (!g) {
		if (fname[0] == '<') {
			fname++;
		}
		CStringList* dir = Options::IncludeDirsList;
		while (dir) {
			if (SearchPath(dir->string, fname, NULL, MAX_PATH, nieuwzoekpad, filenamebegin)) {
				g = 1; break;
			}
			dir = dir->next;
		}
	}
	if (!g) {
		SearchPath(CurrentDirectory, fname, NULL, MAX_PATH, nieuwzoekpad, filenamebegin);
	}
	kip = STRDUP(nieuwzoekpad);
	if (kip == NULL) {
		Error("No enough memory!", 0, FATAL);
	}
	if (filenamebegin) {
		*filenamebegin += kip - nieuwzoekpad;
	}
	return kip;
}

void BinIncFile(char* fname, int offset, int len) {
	char* bp;
	FILE* bif;
	int res;
	int leng;
	char* nieuwzoekpad;
	nieuwzoekpad = GetPath(fname, NULL);
	if (*fname == '<') {
		fname++;
	}
	if (!FOPEN_ISOK(bif, nieuwzoekpad, "rb")) {
		Error("Error opening file", fname, FATAL);
	}
	if (offset > 0) {
		bp = new char[offset + 1];
		if (bp == NULL) {
			Error("No enough memory!", 0, FATAL);
		}
		res = fread(bp, 1, offset, bif);
		if (res == -1) {
			Error("Read error", fname, FATAL);
		}
		if (res != offset) {
			Error("Offset beyond filelength", fname, FATAL);
		}
	}
	if (len > 0) {
		bp = new char[len + 1];
		if (bp == NULL) {
			Error("No enough memory!", 0, FATAL);
		}
		res = fread(bp, 1, len, bif);
		if (res == -1) {
			Error("Read error", fname, FATAL);
		}
		if (res != len) {
			Error("Unexpected end of file", fname, FATAL);
		}
		while (len--) {
			if (pass == 2) {
				WriteBuffer[WBLength++] = *bp; 
				if (WBLength == DESTBUFLEN) {
					WriteDest();
				} 
				if (Options::MemoryType != MT_NONE) {
					if (PseudoORG) {
						if (CurAddress >= 0x10000) {
							Error("RAM limit exceeded", 0, FATAL);
						}
						*(MemoryPointer++) = *bp;
						if ((adrdisp & 0x3FFF) == 0x3FFF) {
							++adrdisp; ++CurAddress;
							CheckPage(); continue;
						}
					} else {
						if (CurAddress >= 0x10000) {
							Error("RAM limit exceeded", 0, FATAL);
						}
						*(MemoryPointer++) = *bp;
						if ((CurAddress & 0x3FFF) == 0x3FFF) {
							++CurAddress;
							CheckPage(); continue;
						}
					}
				}
				*bp++;
			}
			if (PseudoORG) {
				++adrdisp;
			}
			++CurAddress;
		}
	} else {
		if (pass == 2) {
			WriteDest();
		}
		do {
			res = fread(WriteBuffer, 1, DESTBUFLEN, bif);
			if (res == -1) {
				Error("Read error", fname, FATAL);
			}
			if (pass == 2) {
				WBLength = res; 
				if (Options::MemoryType != MT_NONE) {
					leng = 0;
					while (leng != res) {
						if (PseudoORG) {
							if (CurAddress >= 0x10000) {
								Error("RAM limit exceeded", 0, FATAL);
							}
							*(MemoryPointer++) = (char) WriteBuffer[leng++];
							if ((adrdisp & 0x3FFF) == 0x3FFF) {
								++adrdisp; ++CurAddress;
								CheckPage();
							} else {
								++adrdisp; ++CurAddress;
							}
						} else {
							if (CurAddress >= 0x10000) {
								Error("RAM limit exceeded", 0, FATAL);
							}
							*(MemoryPointer++) = (char) WriteBuffer[leng++];
							if ((CurAddress & 0x3FFF) == 0x3FFF) {
								++CurAddress;
								CheckPage();
							} else {
								++CurAddress;
							}
						}
					}
				}
				WriteDest();
			}
			if (Options::MemoryType == MT_NONE || pass == 1) {
				if (PseudoORG) {
					adrdisp += res;
				} CurAddress += res;
			}
		} while (res == DESTBUFLEN);
	}
	fclose(bif);
}

void OpenFile(char* nfilename) {
	char ofilename[LINEMAX];
	char* oCurrentDirectory, * nieuwzoekpad;
	TCHAR* filenamebegin;
	aint oCurrentLocalLine = CurrentLocalLine;
	CurrentLocalLine = 0;
	STRCPY(ofilename, LINEMAX, filename);
	if (++IncludeLevel > 20) {
		Error("Over 20 files nested", 0, FATAL);
	}
	nieuwzoekpad = GetPath(nfilename, &filenamebegin);
	if (*nfilename == '<') {
		nfilename++;
	}
	STRCPY(filename, LINEMAX, nfilename);
	if (!FOPEN_ISOK(FP_Input, nieuwzoekpad, "r")) {
		Error("Error opening file", nfilename, FATAL);
	}
	oCurrentDirectory = CurrentDirectory; *filenamebegin = 0; CurrentDirectory = nieuwzoekpad;

	RL_Readed = 0; rlpbuf = rlbuf; 
	ReadBufLine(true);

	fclose(FP_Input);
	--IncludeLevel;
	CurrentDirectory = oCurrentDirectory;
	STRCPY(filename, LINEMAX, ofilename);
	if (CurrentLocalLine > maxlin) {
		maxlin = CurrentLocalLine;
	}
	CurrentLocalLine = oCurrentLocalLine;
}

/* added */
void IncludeFile(char* nfilename) {
	FILE* oFP_Input = FP_Input;
	FP_Input = 0;

	char* pbuf = rlpbuf;
	char* buf = STRDUP(rlbuf);
	if (buf == NULL) {
		Error("No enough memory!", 0, FATAL);
	}
	int readed = RL_Readed;
	bool squotes = rlsquotes,dquotes = rldquotes,space = rlspace,comment = rlcomment,colon = rlcolon,newline = rlnewline;

	rldquotes = false; rlsquotes = false;rlspace = false;rlcomment = false;rlcolon = false;rlnewline = true;

	memset(rlbuf, 0, 8192);

	OpenFile(nfilename);

	rlsquotes = squotes,rldquotes = dquotes,rlspace = space,rlcomment = comment,rlcolon = colon,rlnewline = newline;
	rlpbuf = pbuf;
	STRCPY(rlbuf, 8192, buf);
	RL_Readed = readed;

	delete[] buf;

	FP_Input = oFP_Input;
}

/* added */
void ReadBufLine(bool Parse) {
	rlppos = line;
	if (rlcolon) {
		*(rlppos++) = '\t';
	}
	while (IsRunning && (RL_Readed > 0 || (RL_Readed = fread(rlbuf, 1, 4096, FP_Input)))) {
		if (!*rlpbuf) {
			rlpbuf = rlbuf;
		}
		while (RL_Readed > 0) {
			if (*rlpbuf == '\n' || *rlpbuf == '\r') {
				if (*rlpbuf == '\n') {
					rlpbuf++;RL_Readed--;if (*rlpbuf && *rlpbuf == '\r') {
											rlpbuf++;RL_Readed--;
										}
				} else if (*rlpbuf == '\r') {
					rlpbuf++;RL_Readed--;
				}
				*rlppos = 0;
				if (strlen(line) == LINEMAX - 1) {
					Error("Line too long", 0, FATAL);
				}
				if (rlnewline) {
					CurrentLocalLine++; CurrentLine++; CurrentGlobalLine++;
				}
				rlsquotes = rldquotes = rlcomment = rlspace = rlcolon = false;
				//cout << line << endl;
				if (Parse) {
					ParseLine();
				} else {
					return;
				}
				rlppos = line; if (rlcolon) {
							   	*(rlppos++) = ' ';
							   } rlnewline = true;
			} else if (*rlpbuf == ':' && rlspace && !rldquotes && !rlsquotes && !rlcomment) {
				while (*rlpbuf && *rlpbuf == ':') {
					rlpbuf++;RL_Readed--;
				}
			  	*rlppos = 0;
				if (strlen(line) == LINEMAX - 1) {
					Error("Line too long", 0, FATAL);
				}
				if (rlnewline) {
					CurrentLocalLine++; CurrentLine++; CurrentGlobalLine++; rlnewline = false;
				}
			  	rlcolon = true;
				if (Parse) {
					ParseLine();
				} else {
					return;
				}
			  	rlppos = line; if (rlcolon) {
							   	*(rlppos++) = ' ';
							   }
			} else if (*rlpbuf == ':' && !rlspace && !rlcolon && !rldquotes && !rlsquotes && !rlcomment) {
			  	lp = line; *rlppos = 0; char* n;
				if ((n = getinstr(lp)) && DirectivesTable.Find(n)) {
					//it's directive
					while (*rlpbuf && *rlpbuf == ':') {
						rlpbuf++;RL_Readed--;
					}
					if (strlen(line) == LINEMAX - 1) {
						Error("Line too long", 0, FATAL);
					}
					if (rlnewline) {
						CurrentLocalLine++; CurrentLine++; CurrentGlobalLine++; rlnewline = false;
					}
					rlcolon = true; 
					if (Parse) {
						ParseLine();
					} else {
						return;
					}
					rlspace = true;
					rlppos = line; if (rlcolon) {
								   	*(rlppos++) = ' ';
								   }
				} else {
					//it's label
					*(rlppos++) = ':';
					*(rlppos++) = ' ';
					rlspace = true;
					while (*rlpbuf && *rlpbuf == ':') {
						rlpbuf++;RL_Readed--;
					}
				}
			} else {
				if (*rlpbuf == '\'') {
					if (rlsquotes) {
						rlsquotes = false;
					} else {
						rlsquotes = true;
					}
				} else if (*rlpbuf == '"') {
					if (rldquotes) {
						rldquotes = false;
					} else {
						rldquotes = true;
					}
				} else if (*rlpbuf == ';') {
					rlcomment = true;
				} else if (*rlpbuf == '/' && *(rlpbuf + 1) == '/') {
					rlcomment = true;  
					*(rlppos++) = *(rlpbuf++); RL_Readed--;
				} else if (*rlpbuf <= ' ') {
					rlspace = true;
				}
				*(rlppos++) = *(rlpbuf++); RL_Readed--;
			}
		}
		rlpbuf = rlbuf;
	}
	//for end line
	if (feof(FP_Input) && RL_Readed <= 0 && line) {
		if (rlnewline) {
			CurrentLocalLine++; CurrentLine++; CurrentGlobalLine++;
		}
		rlsquotes = rldquotes = rlcomment = rlspace = rlcolon = false;
		rlnewline = true;
		*rlppos = 0;
		if (Parse) {
			ParseLine();
		} else {
			return;
		}
		rlppos = line;
	}
}

/* modified */
void OpenList() {
	if (Options::ListingFName[0]) {
		if (!FOPEN_ISOK(FP_ListingFile, Options::ListingFName, "w")) {
			Error("Error opening file", Options::ListingFName, FATAL);
		}
	}
}

/* added */
void OpenUnrealList() {
	/*if (!FP_UnrealList && Options::UnrealLabelListFName && !FOPEN_ISOK(FP_UnrealList, Options::UnrealLabelListFName, "w")) {
		Error("Error opening file", Options::UnrealLabelListFName, FATAL);
	}*/
}

void CloseDest() {
	long pad;
	if (WBLength) {
		WriteDest();
	}
	if (size != -1) {
		if (destlen > size) {
			Error("File exceeds 'size'", 0);
		} else {
			pad = size - destlen;
			if (pad > 0) {
				while (pad--) {
					WriteBuffer[WBLength++] = 0;
					if (WBLength == 256) {
						WriteDest();
					}
				}
			}
			if (WBLength) {
				WriteDest();
			}
		}
	}
	fclose(FP_Output);
}

void SeekDest(long offset, int method) {
	WriteDest();
	if (fseek(FP_Output, offset, method)) {
		Error("File seek error (FORG)", 0, FATAL);
	}
}

void NewDest(char* newfilename) {
	NewDest(newfilename, OUTPUT_TRUNCATE);
}

void NewDest(char* newfilename, int mode) {
	CloseDest();
	STRCPY(Options::DestionationFName, LINEMAX, newfilename);
	OpenDest(mode);
}

void OpenDest() {
	OpenDest(OUTPUT_TRUNCATE);
}

void OpenDest(int mode) {
	destlen = 0;
	if (mode != OUTPUT_TRUNCATE && !FileExists(Options::DestionationFName)) {
		mode = OUTPUT_TRUNCATE;
	}
	if (!FOPEN_ISOK(FP_Output, Options::DestionationFName, mode == OUTPUT_TRUNCATE ? "wb" : "r+b")) {
		Error("Error opening file", Options::DestionationFName, FATAL);
	}
	if (Options::RAWFName[0] && !FOPEN_ISOK(FP_RAW, Options::RAWFName, "wb")) {
		Warning("Error opening file", Options::RAWFName);
	}
	if (mode != OUTPUT_TRUNCATE) {
		if (fseek(FP_Output, 0, mode == OUTPUT_REWIND ? SEEK_SET : SEEK_END)) {
			Error("File seek error (OUTPUT)", 0, FATAL);
		}
	}
}

int FileExists(char* filename) {
	int exists = 0;
	FILE* test;
	if (FOPEN_ISOK(test, filename, "r")) {
		exists = -1;
		fclose(test);
	}
	return exists;
}

void Close() {
	CloseDest();
	if (FP_ExportFile) {
		fclose(FP_ExportFile);
		FP_ExportFile = NULL;
	}
	if (FP_RAW) {
		fclose(FP_RAW);
	}
	if (FP_ListingFile) {
		fclose(FP_ListingFile);
	}
	//if (FP_UnrealList && pass == 9999) {
	//	fclose(FP_UnrealList);
	//}
}

int SaveRAM(FILE* ff, int start, int length) {
	unsigned int addadr = 0,save = 0;

	if (length + start > 0xFFFF) {
		length = -1;
	}
	if (length <= 0) {
		length = 0x10000 - start;
	}

	// $4000-$7FFF
	if (start < 0x8000) {
		save = length;
		addadr = start - 0x4000;
		if (save + start > 0x8000) {
			save = 0x8000 - start;
			length -= save;
			start = 0x8000;
		} else {
			length = 0;
		}
		if (fwrite(MemoryRAM + addadr, 1, save, ff) != save) {
			return 0;
		}
	}
	// $8000-$BFFF
	if (length > 0 && start < 0xC000) {
		save = length;
		addadr = start - 0x4000;
		if (save + start > 0xC000) {
			save = 0xC000 - start;
			length -= save;
			start = 0xC000;
		} else {
			length = 0;
		}
		if (fwrite(MemoryRAM + addadr, 1, save, ff) != save) {
			return 0;
		}
	}

	// $C000-$FFFF
	if (length > 0) {
		switch (MemoryCPage) {
		case 0:
			addadr = 0x8000;
			break;
		case 1:
			addadr = 0xc000;
			break;
		case 2:
			addadr = 0x4000;
			break;
		case 3:
			addadr = 0x10000;
			break;
		case 4:
			addadr = 0x14000;
			break;
		case 5:
			addadr = 0x0000;
			break;
		case 6:
			addadr = 0x18000;
			break;
		case 7:
			addadr = 0x1c000;
			break;
		}
		save = length;
		addadr += start - 0xC000;
		if (fwrite(MemoryRAM + addadr, 1, save, ff) != save) {
			return 0;
		}
	}
	return 1;
}


char MemGetByte(unsigned int address) {
	if (pass == 1) {
		return 0;
	}
	// $4000-$7FFF
	if (address < 0x8000) {
		return MemoryRAM[address - 0x4000];
	}
	// $8000-$BFFF
	else if (address < 0xC000) {
		return MemoryRAM[address - 0x8000];
	}
		// $C000-$FFFF
	else {
		unsigned int addadr = 0;
		switch (MemoryCPage) {
		case 0:
			addadr = 0x8000;
			break;
		case 1:
			addadr = 0xc000;
			break;
		case 2:
			addadr = 0x4000;
			break;
		case 3:
			addadr = 0x10000;
			break;
		case 4:
			addadr = 0x14000;
			break;
		case 5:
			addadr = 0x0000;
			break;
		case 6:
			addadr = 0x18000;
			break;
		case 7:
			addadr = 0x1c000;
			break;
		}
		addadr += address - 0xC000;
		if (addadr > 0x1FFFF) {
			return 0;
		}
		return MemoryRAM[addadr];
	}
}


int SaveBinary(char* fname, int start, int length) {
	FILE* ff;
	if (!FOPEN_ISOK(ff, fname, "wb")) {
		Error("Error opening file", fname, FATAL);
	}

	if (length + start > 0xFFFF) {
		length = -1;
	}
	if (length <= 0) {
		length = 0x10000 - start;
	}

	if (!SaveRAM(ff, start, length)) {
		fclose(ff);return 0;
	}

	fclose(ff);
	return 1;
}


int SaveHobeta(char* fname, char* fhobname, int start, int length) {
	unsigned char header[0x11];
	int i;
	for (i = 0; i != 8; header[i++] = 0x20) {
		;
	}
	for (i = 0; i != 8; ++i) {
		if (*(fhobname + i) == 0) {
			break;
		}
		if (*(fhobname + i) != '.') {
			header[i] = *(fhobname + i);continue;
		} else if (*(fhobname + i + 1)) {
			header[8] = *(fhobname + i + 1);
		}
		break;
	}


	if (length + start > 0xFFFF) {
		length = -1;
	}
	if (length <= 0) {
		length = 0x10000 - start;
	}

	header[0x09] = (unsigned char)(start & 0xff);
	header[0x0a] = (unsigned char)(start >> 8);
	header[0x0b] = (unsigned char)(length & 0xff);
	header[0x0c] = (unsigned char)(length >> 8);
	header[0x0d] = 0;
	if (header[0x0b] == 0) {
		header[0x0e] = header[0x0c];
	} else {
		header[0x0e] = header[0x0c] + 1;
	}
	length = header[0x0e] * 0x100;
	int chk = 0;
	for (i = 0; i <= 14; chk = chk + (header[i] * 257) + i,i++) {
		;
	}
	header[0x0f] = (unsigned char)(chk & 0xff);
	header[0x10] = (unsigned char)(chk >> 8);

	FILE* ff;
	if (!FOPEN_ISOK(ff, fname, "wb")) {
		Error("Error opening file", fname, FATAL);
	}

	if (fwrite(header, 1, 17, ff) != 17) {
		fclose(ff);return 0;
	}

	if (!SaveRAM(ff, start, length)) {
		fclose(ff);return 0;
	}

	fclose(ff);
	return 1;
}

EReturn ReadFile(char* pp, char* err) {
	CStringList* ol;
	char* p;
	while (RL_Readed > 0 || !feof(FP_Input)) {
		if (!IsRunning) {
			return END;
		}
		if (lijst) {
			if (!lijstp) {
				return END;
			}
			//p = STRCPY(line, LINEMAX, lijstp->string); //mmm
			STRCPY(line, LINEMAX, lijstp->string);
			p = line;
			ol = lijstp;
			lijstp = lijstp->next;
		} else {
			ReadBufLine(false);
			p = line;
			//cout << "RF:" << rlcolon << line << endl;
		}

		SkipBlanks(p);
		if (*p == '.') {
			++p;
		}
		if (cmphstr(p, "endif")) {
			lp = ReplaceDefine(p); return ENDIF;
		}
		if (cmphstr(p, "else")) {
			ListFile(); lp = ReplaceDefine(p); return ELSE;
		}
		if (cmphstr(p, "endt")) {
			lp = ReplaceDefine(p); return ENDTEXTAREA;
		}
		if (cmphstr(p, "dephase")) {
			lp = ReplaceDefine(p); return ENDTEXTAREA;
		} // hmm??
		if (cmphstr(p, "unphase")) {
			lp = ReplaceDefine(p); return ENDTEXTAREA;
		} // hmm??
		ParseLineSafe();
	}
	Error("Unexpected end of file", 0, FATAL);
	return END;
}


EReturn SkipFile(char* pp, char* err) {
	CStringList* ol;
	char* p;
	int iflevel = 0;
	while (RL_Readed > 0 || !feof(FP_Input)) {
		if (!IsRunning) {
			return END;
		}
		if (lijst) {
			if (!lijstp) {
				return END;
			}
			//p = STRCPY(line, LINEMAX, lijstp->string); //mmm
			STRCPY(line, LINEMAX, lijstp->string);
			p = line;
			ol = lijstp;
			lijstp = lijstp->next;
		} else {
			ReadBufLine(false);
			p = line;
			//cout << "SF:" << rlcolon << line << endl;
		}
		SkipBlanks(p);
		if (*p == '.') {
			++p;
		}
		if (cmphstr(p, "if")) {
			++iflevel;
		}
		if (cmphstr(p, "ifn")) {
			++iflevel;
		}
		//if (cmphstr(p,"ifexist")) { ++iflevel; }
		//if (cmphstr(p,"ifnexist")) { ++iflevel; }
		if (cmphstr(p, "ifdef")) {
			++iflevel;
		}
		if (cmphstr(p, "ifndef")) {
			++iflevel;
		}
		if (cmphstr(p, "endif")) {
			if (iflevel) {
				--iflevel;
			} else {
				lp = ReplaceDefine(p);return ENDIF;
			}
		}
		if (cmphstr(p, "else")) {
			if (!iflevel) {
				ListFile(); lp = ReplaceDefine(p);return ELSE;
			}
		}
		ListFileSkip(line);
	}
	Error("Unexpected end of file", 0, FATAL);
	return END;
}


int ReadLine() {
	if (!IsRunning) {
		return 0;
	}
	/*if (!fgets(line,LINEMAX,FP_Input)) Error("Unexpected end of file",0,FATAL);
	++CurrentLocalLine; ++CurrentLine;
	if (strlen(line)==LINEMAX-1) Error("Line too long",0,FATAL);*/
	int res = (RL_Readed > 0 || !feof(FP_Input));
	ReadBufLine(false);
	return res;
}

int ReadFileToCStringList(CStringList*& f, char* end) {
	CStringList* s,* l = NULL;
	char* p;
	f = NULL;
	while (RL_Readed > 0 || !feof(FP_Input)) {
		if (!IsRunning) {
			return 0;
		}
		ReadBufLine(false);
		p = line;
		//cout << "P" << line << endl;
		if (*p) {
			SkipBlanks(p); if (*p == '.') {
						   	++p;
						   }
			if (cmphstr(p, end)) {
				lp = ReplaceDefine(p); return 1;
			}
		}
		s = new CStringList(line, NULL); if (!f) {
										 	f = s;
										 } if (l) {
										   	l->next = s;
										   } l = s;
		ListFileSkip(line);
	}
	Error("Unexpected end of file", 0, FATAL);
	return 0;
}

void WriteExp(char* n, aint v) {
	char lnrs[16],* l = lnrs;
	if (!FP_ExportFile) {
		if (!FOPEN_ISOK(FP_ExportFile, Options::ExportFName, "w")) {
			Error("Error opening file", Options::ExportFName, FATAL);
		}
	}
	STRCPY(ErrorLine, LINEMAX2, n);
	STRCAT(ErrorLine, LINEMAX2, ": EQU ");
	PrintHEX32(l, v); *l = 0;
	STRCAT(ErrorLine, LINEMAX2, lnrs);
	STRCAT(ErrorLine, LINEMAX2, "h\n");
	fputs(ErrorLine, FP_ExportFile);
}

//eof sjio.cpp
