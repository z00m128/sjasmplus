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

#define PAGESIZE 0x4000 /* added */

extern aint PreviousAddress, epadres;

#define OUTPUT_TRUNCATE 0
#define OUTPUT_REWIND 1
#define OUTPUT_APPEND 2

extern FILE* FP_UnrealList, * FP_Input; /* added */

void OpenDest(int); /* added from new SjASM 0.39g */
void NewDest(char* newfilename, int mode); /* added from new SjASM 0.39g */
int FileExists(char* filename); /* added from new SjASM 0.39g */
void Error(const char*, const char*, int = PASS2);
void Warning(const char*, const char*, int = PASS2);
void ListFile();
void ListFileSkip(char*);
void CheckPage(); /* added */
void EmitByte(int byte);
void EmitWord(int word);
void EmitBytes(int* bytes);
void EmitWords(int* words);
void EmitBlock(aint byte, aint len, bool nulled = false);
void OpenFile(char* nfilename);
void IncludeFile(char* nfilename); /* added */
void Close();
void OpenList();
void OpenUnrealList(); /* added */
void ReadBufLine(bool Parse = true, bool SplitByColon = true); /* added */
void OpenDest();
void PrintHEX32(char*& p, aint h);
void PrintHEX16(char*& p, aint h); /* added */
void PrintHEXAlt(char*& p, aint h); /* added */
char* GetPath(char* fname, TCHAR** filenamebegin); /* added */
void BinIncFile(char* fname, int offset, int length);
int SaveRAM(FILE*, int, int);
unsigned char MemGetByte(unsigned int address); /* added */
unsigned int MemGetWord(unsigned int address); /* added */
int SaveBinary(char* fname, int start, int length); /* added */
int SaveHobeta(char* fname, char* fhobname, int start, int length); /* added */
int ReadLine(bool SplitByColon = true);
EReturn ReadFile();
EReturn ReadFile(const char* pp, const char* err); /* added */
EReturn SkipFile();
EReturn SkipFile(char* pp, char* err); /* added */
void NewDest(char* newfilename);
void SeekDest(long, int); /* added from new SjASM 0.39g */
int ReadFileToCStringsList(CStringsList*& f, const char* end);
void WriteExp(char* n, aint v);

//eof sjio.h

