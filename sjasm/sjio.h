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

enum EReturn { END, ELSE, ENDIF, ENDTEXTAREA, ENDM, ELSEIF };

extern int ListAddress;
extern std::vector<const char*> archivedFileNames;	// archive of all files opened (also includes!) (fullname!)

constexpr int BYTES_END_MARKER = -1;
constexpr int INSTRUCTION_START_MARKER = -2;

#define OUTPUT_TRUNCATE 0
#define OUTPUT_REWIND 1
#define OUTPUT_APPEND 2

// input file archiving helper struct (holding instance of full and base name strings to keep c_str() pointers valid)
struct SInputFile {
  const std::filesystem::path full;
  const std::string fullStr;
  const std::string baseStr;

  SInputFile(const std::filesystem::path && fullName) :
                  full(std::move(fullName)),
                  fullStr(full.string()),
                  baseStr(full.filename().string()) {
  }

  SInputFile(int) : full(), fullStr("<stdin>"), baseStr("<stdin>") {} // special const. for stdin

  SInputFile() = delete;
  SInputFile(const SInputFile &) = delete;
};

using fullpath_ref_t = const SInputFile &;
using fullpath_p_t = const SInputFile *;

// map to archive all input files (to have stable valid c_str pointers of their filenames until exit)
// key: filename + delimiter info
// value: archived fullpath/basename ready to open or print
using files_in_map_t = std::map<const delim_string_t, const SInputFile>;

// Look for provided string + delimiter type in include paths and return full path to existing file or original string
// (archives the input in case this is first time, otherwise returns archived path)
fullpath_ref_t GetInputFile(delim_string_t && in);
fullpath_ref_t GetInputFile(char*& p);
std::filesystem::path GetOutputFileName(char*& p);

//FIXME this is still used by Lua to archive its temporary filenames retrieved trough debug interface, maybe abuse GetInputFile here too? (DT_COUNT delim string)
const char* ArchiveFilename(const char* fullpathname);	// returns permanent c_str pointer to input c_str (used for Lua script file names)
void ReleaseArchivedFilenames();	// does release all archived filenames, making all pointers invalid
void ConstructDefaultFilename(std::filesystem::path & dest, const char* ext, bool checkIfDestIsEmpty = true);
void OpenDest(int mode = OUTPUT_TRUNCATE);
void OpenExpFile();
void NewDest(const std::filesystem::path & newfilename, int mode = OUTPUT_TRUNCATE);
bool FileExists(const std::filesystem::path & file_name);
bool FileExistsCstr(const char* filename);
FILE* GetListingFile();
void ListFile(bool showAsSkipped = false);
void ListSilentOrExternalEmits();
void CheckRamLimitExceeded();
void resolveRelocationAndSmartSmc(const aint immediateOffset, Relocation::EType minType = Relocation::REGULAR);
void EmitByte(int byte, bool isInstructionStart = false);
void EmitWord(int word, bool isInstructionStart = false);
void EmitBytes(const int* bytes, bool isInstructionStart = false);
void EmitWords(const int* words, bool isInstructionStart = false);
void EmitBlock(aint byte, aint len, bool preserveDeviceMemory = false, int emitMaxToListing = 4);
bool DidEmitByte();		// returns true if some byte was emitted since last call to this function
void OpenFile(fullpath_ref_t nfilename, stdin_log_t* fStdinLog = nullptr);
void IncludeFile(fullpath_ref_t nfilename);
void Close();
void OpenList();

void OpenUnrealList();
void ReadBufLine(bool Parse = true, bool SplitByColon = true);
void CloseDest();
void CloseTapFile();
void OpenTapFile(const std::filesystem::path & tapename, int flagbyte);
void PrintHex(char* & dest, aint value, int nibbles);
void PrintHex32(char* & dest, aint value);
void PrintHexAlt(char* & dest, aint value);

/**
 * @brief Includes bytes of particular file into output (and virtual device memory).
 *
 * @param file input file to open
 * @param offset positive: bytes to skip / negative: bytes to rewind back from end
 * @param length positive: bytes to include / negative: bytes to skip from end / INT_MAX: all remaining
 */
void BinIncFile(fullpath_ref_t file, aint offset, aint length);

int SaveRAM(FILE*, int, int);
unsigned char MemGetByte(unsigned int address);
unsigned int MemGetWord(unsigned int address);
int SaveBinary(const std::filesystem::path & fname, aint start, aint length);
int SaveBinary3dos(const std::filesystem::path & fname, aint start, aint length, byte type, word w2, word w3);
int SaveBinaryAmsdos(const std::filesystem::path & fname, aint start, aint length, word start_adr = 0, byte type = 2);
bool SaveDeviceMemory(FILE* file, const size_t start, const size_t length);
bool SaveDeviceMemory(const std::filesystem::path & fname, const size_t start, const size_t length);
int SaveHobeta(const std::filesystem::path & fname, const char* fhobname, aint start, aint length);
int ReadLineNoMacro(bool SplitByColon = true);
int ReadLine(bool SplitByColon = true);
EReturn ReadFile();
EReturn SkipFile();
void SeekDest(long, int);
int ReadFileToCStringsList(CStringsList*& f, const char* end);
void WriteLabelEquValue(const char* name, aint value, FILE* f);
void WriteExp(const char* n, aint v);

/////// source-level-debugging support by Ckirby
bool IsSldExportActive();
void OpenSld();
void CloseSld();
void WriteToSldFile(int pageNum, int value, char type = 'T', const char* symbol = nullptr);
void SldAddCommentKeyword(const char* keyword);
void SldTrackComments();

/////// Breakpoints list (for different emulators)
enum EBreakpointsFile { BPSF_UNREAL, BPSF_ZESARUX };
void OpenBreakpointsFile(const std::filesystem::path & filename, const EBreakpointsFile type);
void WriteBreakpoint(const aint val);

//eof sjio.h
