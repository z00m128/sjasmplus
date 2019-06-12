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

	// structure to group all options affecting parsing syntax
	typedef struct SSyntax {
		bool		IsPseudoOpBOF;
		bool		IsReversePOP;
		bool		FakeEnabled;
		bool		FakeWarning;
		bool		IsListingSuspended;
		bool		CaseInsensitiveInstructions;
		int			MemoryBrackets;	// 0 = [] enabled (default), 1 = [] disabled, 2 = [] required
		int			IsNextEnabled;	// 0 = OFF, 1 = ordinary NEXT, 2 = CSpect emulator extensions
		bool		(*MultiArg)(char*&);	// function checking if multi-arg delimiter is next

		SSyntax() : IsPseudoOpBOF(false), IsReversePOP(false), FakeEnabled(true), FakeWarning(false),
					IsListingSuspended(false), CaseInsensitiveInstructions(false), MemoryBrackets(0),
					IsNextEnabled(0), MultiArg(&comma) {}
		bool isMultiArgPlainComma() const { return &comma == MultiArg; }

	// preservation utils, the push will also reset current syntax to defaults
		static void resetCurrentSyntax();	// resets current syntax to defaults
		static void pushCurrentSyntax();	// pushes current syntax
		static bool popSyntax();			// restores the syntax from previous push
		static void restoreSystemSyntax();	// restores the syntax (ahead of pass), and empties the syntax stack
	private:
		static std::stack<SSyntax> syxStack;	// previous syntax
	} SSyntax;

	extern char SymbolListFName[LINEMAX];
	extern char ListingFName[LINEMAX];
	extern char ExportFName[LINEMAX];
	extern char DestinationFName[LINEMAX];
	extern char RAWFName[LINEMAX];
	extern char UnrealLabelListFName[LINEMAX];
	extern char CSpectMapFName[LINEMAX];

	extern EOutputVerbosity OutputVerbosity;
	extern bool IsLabelTableInListing;
	extern bool IsDefaultListingName;
	extern bool IsShowFullPath;
	extern bool AddLabelListing;
	extern bool NoDestinationFile;
	extern SSyntax syx;
	extern bool SourceStdIn;

	extern CStringsList* IncludeDirsList;
	extern CDefineTable CmdDefineTable;

	// returns true if fakes are completely disabled, false when they are enabled
	// showMessage=true: will also display error/warning (use when fake ins. is emitted)
	// showMessage=false: can be used to silently check if fake instructions are even possible
	bool noFakes(bool showMessage = true);

	int parseSyntaxOptions(int n, char** options);	// returns index of failed option or "n"==OK
		//options[n] must contain nullptr (and it must be valid index)
} // eof namespace Options

extern CDevice *Devices;
extern CDevice *Device;
extern CDevicePage *Page;
extern char* DeviceID;
extern int deviceDirectivesCounter;

// extend
extern char filename[LINEMAX], * lp, line[LINEMAX], temp[LINEMAX], ErrorLine[LINEMAX2], * bp;
extern char sline[LINEMAX2], sline2[LINEMAX2], * substitutedLine, * eolComment;
// the "substitutedLine" may be overriden to point back to un-substituted line, it's only "decorative" for Listing purposes

extern char SourceFNames[128][MAX_PATH];
extern std::vector<char> stdin_log;	// buffer for Options::SourceStdIn, to replay input in 2nd+ pass

extern int ConvertEncoding;
extern int pass, IsLabelNotFound, ErrorCount, WarningCount, IncludeLevel, IsRunning, donotlist, listmacro;
extern int adrdisp, PseudoORG, StartAddress;
extern byte* MemoryPointer;
extern int macronummer, lijst, reglenwidth;
extern aint CurAddress, CurrentSourceLine, CompiledCurrentLine, LastParsedLabelLine;
extern aint destlen, size, PreviousErrorLine, maxlin, comlin;

extern char* ModuleName, * vorlabp, * macrolabp, * LastParsedLabel;

enum EEncoding { ENCDOS, ENCWIN };
extern char* CurrentDirectory;

void ExitASM(int p);
extern CStringsList* lijstp;
extern std::stack<SRepeatStack> RepeatStack;

extern CLabelTable LabelTable;
extern CLocalLabelTable LocalLabelTable;
extern CDefineTable DefineTable;
extern CMacroDefineTable MacroDefineTable;
extern CMacroTable MacroTable;
extern CStructureTable StructureTable;
extern CStringsList* ModuleList;

#ifdef USE_LUA

extern lua_State *LUA;
extern int LuaLine;

#endif //USE_LUA

#endif
//eof sjasm.h
