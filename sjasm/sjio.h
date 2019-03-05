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

// sjio.h

enum EStatus { ALL, PASS1, PASS2, PASS3, FATAL, CATCHALL, SUPPRESS };
enum EReturn { END, ELSE, ENDIF, ENDTEXTAREA, ENDM };

#ifdef PAGESIZE
#undef PAGESIZE
#endif

#define PAGESIZE 0x4000

extern aint PreviousAddress, epadres;

#define OUTPUT_TRUNCATE 0
#define OUTPUT_REWIND 1
#define OUTPUT_APPEND 2

extern FILE* FP_UnrealList, * FP_Input;

void OpenDest(int);
void NewDest(char* newfilename, int mode);
int FileExists(char* filename);
void Error(const char*, const char*, int = LASTPASS);
void Warning(const char*, const char*, int = LASTPASS);
void ListFile();
void ListFileSkip(char*);
void CheckPage();
void EmitByte(int byte);
void EmitWord(int word);
void EmitBytes(int* bytes);
void EmitWords(int* words);
void EmitBlock(aint byte, aint len, bool nulled = false);
void OpenFile(char* nfilename, bool systemPathsBeforeCurrent = false);
void IncludeFile(char* nfilename, bool systemPathsBeforeCurrent);
void Close();
void OpenList();
void OpenUnrealList();
void ReadBufLine(bool Parse = true, bool SplitByColon = true);
void OpenDest();
void CloseDest();
void CloseTapFile();
void OpenTapFile(char * tapename, int flagbyte);
void PrintHEX32(char*& p, aint h);
void PrintHEX16(char*& p, aint h);
void PrintHEXAlt(char*& p, aint h);
char* GetPath(char* fname, char** filenamebegin = NULL, bool systemPathsBeforeCurrent = false);
void BinIncFile(char* fname, int offset, int length);
int SaveRAM(FILE*, int, int);
unsigned char MemGetByte(unsigned int address);
unsigned int MemGetWord(unsigned int address);
int SaveBinary(char* fname, int start, int length);
int SaveHobeta(char* fname, char* fhobname, int start, int length);
int ReadLine(bool SplitByColon = true);
EReturn ReadFile();
EReturn ReadFile(const char* pp, const char* err);
EReturn SkipFile();
EReturn SkipFile(char* pp, const char* err);
void NewDest(char* newfilename);
void SeekDest(long, int);
int ReadFileToCStringsList(CStringsList*& f, const char* end);
void WriteExp(char* n, aint v);

//eof sjio.h

