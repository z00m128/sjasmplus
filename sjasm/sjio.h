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

/**
 * Error types:
 * ALL = will try to display in every pass
 * FATAL = terminates assembler
 * EARLY = displays only during early phase (pass 1+2)
 * PASS3 = normal error message level for code-gen pass (pass 3)
 * IF_FIRST = normal code-gen error, but will display only if it is first error on the current line
 * SUPPRESS = will suppress further errors (PASS3+IF_FIRST+ALL) for current line, except FATAL
 * */
enum EStatus { ALL, FATAL, EARLY, PASS3, IF_FIRST, SUPPRESS };
enum EWStatus { W_ALL, W_EARLY, W_PASS3 };
enum EReturn { END, ELSE, ENDIF, ENDTEXTAREA, ENDM };

extern int ListAddress;

#define OUTPUT_TRUNCATE 0
#define OUTPUT_REWIND 1
#define OUTPUT_APPEND 2

extern FILE* FP_Input;

char* FilenameExtPos(char* filename, const char* initWithName = nullptr, size_t initNameMaxLength = 0);
const char* FilenameBasePos(const char* fullname);
void OpenDest(int mode = OUTPUT_TRUNCATE);
void NewDest(char* newfilename, int mode = OUTPUT_TRUNCATE);
int FileExists(char* filename);
void Error(const char* message, const char* badValueMessage = NULL, EStatus type = PASS3);
void ErrorInt(const char* message, aint badValue, EStatus type = PASS3);
void ErrorOOM();		// out of memory
void Warning(const char* message, const char* badValueMessage = NULL, EWStatus type = W_PASS3);
FILE* GetListingFile();
void ListFile(bool showAsSkipped = false);
void ListSilentOrExternalEmits();
void CheckRamLimitExceeded();
void EmitByte(int byte);
void EmitWord(int word);
void EmitBytes(const int* bytes);
void EmitWords(int* words);
void EmitBlock(aint byte, aint len, bool preserveDeviceMemory = false, int emitMaxToListing = 4);
void OpenFile(const char* nfilename, bool systemPathsBeforeCurrent = false);
void IncludeFile(const char* nfilename, bool systemPathsBeforeCurrent);
void Close();
void OpenList();

void OpenUnrealList();
void ReadBufLine(bool Parse = true, bool SplitByColon = true);
void CloseDest();
void CloseTapFile();
void OpenTapFile(char * tapename, int flagbyte);
void PrintHex(char* & dest, aint value, int nibbles);
void PrintHex32(char* & dest, aint value);
void PrintHexAlt(char* & dest, aint value);
char* GetPath(const char* fname, char** filenamebegin = NULL, bool systemPathsBeforeCurrent = false);

/**
 * @brief Includes bytes of particular file into output (and virtual device memory).
 *
 * @param fname file name to open (include paths will be searched, order depends on syntax "" vs <>)
 * @param offset positive: bytes to skip / negative: bytes to rewind back from end
 * @param length positive: bytes to include / negative: bytes to skip from end / INT_MAX: all remaining
 */
void BinIncFile(char* fname, int offset = 0, int length = INT_MAX);

int SaveRAM(FILE*, int, int);
unsigned char MemGetByte(unsigned int address);
unsigned int MemGetWord(unsigned int address);
int SaveBinary(char* fname, int start, int length);
bool SaveDeviceMemory(FILE* file, const size_t start, const size_t length);
bool SaveDeviceMemory(const char* fname, const size_t start, const size_t length);
int SaveHobeta(char* fname, char* fhobname, int start, int length);
int ReadLineNoMacro(bool SplitByColon = true);
int ReadLine(bool SplitByColon = true);
EReturn ReadFile();
EReturn SkipFile();
void SeekDest(long, int);
int ReadFileToCStringsList(CStringsList*& f, const char* end);
void WriteExp(char* n, aint v);

/////// source-level-debugging support by Ckirby
bool IsSldExportActive();
void OpenSld();
void CloseSld();
void WriteToSldFile(int pageNum, int value, char type = 'T', const char* symbol = nullptr);

//eof sjio.h

