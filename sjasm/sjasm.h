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

#ifndef __SJASM
#define __SJASM

enum EOutputVerbosity { OV_ALL = 0, OV_WARNING, OV_ERROR, OV_NONE, OV_LST };

namespace Options {

	// which lines should made it into listing: all, active (not skipped by IF false), only-if-has-machine-code
	enum ELstType { LST_T_ALL, LST_T_ACTIVE, LST_T_MC_ONLY };

	typedef struct STerminalColorSequences {
		const char * end, * display, * warning, * error, * bold;
	} STerminalColorSequences;

	// structure to group all options affecting parsing syntax
	typedef struct SSyntax {
		bool		IsPseudoOpBOF;
		bool		IsReversePOP;
		bool		FakeEnabled;
		bool		FakeWarning;	// accessed also by io_err.cpp implementation for W_FAKE warning state
		bool		IsListingSuspended;
		ELstType	ListingType;
		bool		CaseInsensitiveInstructions;
		bool		WarningsAsErrors;
		bool		Is_M_Memory;
		bool		IsSubwordSubstitution;
		int			MemoryBrackets;	// 0 = [] enabled (default), 1 = [] disabled, 2 = [] required
		int			IsNextEnabled;	// 0 = OFF, 1 = ordinary NEXT, 2 = CSpect emulator extensions
		bool		(*MultiArg)(char*&);	// function checking if multi-arg delimiter is next

		SSyntax() : IsPseudoOpBOF(false), IsReversePOP(false), FakeEnabled(true), FakeWarning(false),
					IsListingSuspended(false), ListingType(LST_T_ALL),
					CaseInsensitiveInstructions(false), WarningsAsErrors(false),
					Is_M_Memory(false), IsSubwordSubstitution(true),
					MemoryBrackets(0), IsNextEnabled(0), MultiArg(&comma) {}
		bool isMultiArgPlainComma() const { return &comma == MultiArg; }

	// preservation utils, the push will also reset current syntax to defaults
		static void resetCurrentSyntax();	// resets current syntax to defaults
		static void pushCurrentSyntax();	// pushes current syntax
		static bool popSyntax();			// restores the syntax from previous push
		static void restoreSystemSyntax();	// restores the syntax (ahead of pass), and empties the syntax stack
	private:
		static std::stack<SSyntax> syxStack;	// previous syntax
	} SSyntax;

	extern const STerminalColorSequences* tcols;
	extern std::filesystem::path OutPrefix;
	extern std::filesystem::path SymbolListFName;
	extern std::filesystem::path ListingFName;
	extern std::filesystem::path ExportFName;
	extern std::filesystem::path DestinationFName;
	extern std::filesystem::path RAWFName;
	extern std::filesystem::path UnrealLabelListFName;
	extern std::filesystem::path CSpectMapFName;
	extern int CSpectMapPageSize;
	extern std::filesystem::path SourceLevelDebugFName;
	extern bool IsDefaultSldName;

	extern EOutputVerbosity OutputVerbosity;
	extern bool IsLabelTableInListing;
	extern bool IsDefaultListingName;
	extern bool IsShowFullPath;
	extern bool AddLabelListing;
	extern bool NoDestinationFile;
	extern SSyntax syx;
	extern bool IsI8080;			// "i8080" CPU mode (must be set at CLI, blocks others)
	extern bool IsLR35902;			// "Sharp LR35902" CPU mode (must be set at CLI, blocks others)
	extern bool IsLongPtr;
	extern bool SortSymbols;
	extern bool IsBigEndian;		// true when hosting platform is big-endian

	// emit virtual labels in LABELSLIST, that have only 64ki address and no page
	// format is then `:ADDR label`, starting from colon, then 16bit address, then label.
	extern bool EmitVirtualLabels;

	extern CStringsList* IncludeDirsList;
	extern CDefineTable CmdDefineTable;

	void SetTerminalColors(bool enabled);

	// returns true if fakes are completely disabled, false when they are enabled
	// showMessage=true: will also display error/warning (use when fake ins. is emitted)
	// showMessage=false: can be used to silently check if fake instructions are even possible
	bool noFakes(bool showMessage = true);

	int parseSyntaxOptions(int n, char** options);	// returns index of failed option or "n"==OK
		//options[n] must contain nullptr (and it must be valid index)
} // eof namespace Options

extern std::vector<CDeviceDef*> DefDevices;
extern CDevice *Devices;
extern CDevice *Device;
extern CDevicePage *Page;
extern char* DeviceID;
extern TextFilePos globalDeviceSourcePos;
extern aint deviceDirectivesCount;

//*current* full file name (used as full for CurSourcePos when `--fullpath`)
//content at this pointer is immutable and valid till assembler exits, so you can archive/reuse it
//for example SLD tracing remembers original file where macro was defined by using pointer into this
extern const char* fileNameFull;

// extend
extern char* lp, line[LINEMAX], temp[LINEMAX], * bp;
extern char sline[LINEMAX2], sline2[LINEMAX2], * substitutedLine, * eolComment, ModuleName[LINEMAX];
// the "substitutedLine" may be overriden to point back to un-substituted line, it's only "decorative" for Listing purposes

typedef struct SSource {
	char fname[MAX_PATH];
	stdin_log_t* stdin_log;	// buffer for STDIN option, to replay input in 2nd+ pass

// 	SSource();
	SSource() = delete;
	SSource(SSource && src);
	SSource(const char* fname);
	SSource(int);		// constructor for "stdin" type of source ("int" just to distinct it)
	~SSource();
} SSource;

extern std::vector<SSource> sourceFiles;

enum EDispMode { DISP_NONE = 0, DISP_ACTIVE = 1, DISP_INSIDE_RELOCATE = 2 };
extern EDispMode PseudoORG;

extern bool IsLabelNotFound, IsSubstituting;
extern int ConvertEncoding;
extern int pass, ErrorCount, WarningCount, IncludeLevel, IsRunning, donotlist, listmacro;
extern int adrdisp, dispPageNum, StartAddress;
extern byte* MemoryPointer;
extern int macronummer, lijst, reglenwidth;
extern source_positions_t sourcePosStack;
extern source_positions_t smartSmcLines;
extern source_positions_t::size_type smartSmcIndex;
extern uint32_t maxlin;
extern aint CurAddress, CompiledCurrentLine, LastParsedLabelLine, PredefinedCounter;
extern aint destlen, size, comlin;

extern char* vorlabp, * macrolabp, * LastParsedLabel;

enum EEncoding { ENCDOS, ENCWIN };
extern const char* CurrentDirectory;

void ExitASM(int p);
extern CStringsList* lijstp;
extern std::stack<SRepeatStack> RepeatStack;

extern CLabelTable LabelTable;
extern CTemporaryLabelTable TemporaryLabelTable;
extern CDefineTable DefineTable;
extern CMacroDefineTable MacroDefineTable;
extern CMacroTable MacroTable;
extern CStructureTable StructureTable;

#endif
//eof sjasm.h
