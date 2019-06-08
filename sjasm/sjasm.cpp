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

// sjasm.cpp

#include "sjdefs.h"
#include <cstdlib>

#ifdef USE_LUA

#include "lua_sjasm.h"

#endif //USE_LUA

void PrintHelp() {
	// Please keep help lines at most 79 characters long (cursor at column 88 after last char)
	//     |<-- ...8901234567890123456789012345678901234567890123456789012... 80 chars -->|
	_COUT "Based on code of SjASM by Sjoerd Mastijn (http://www.xl2s.tk)" _ENDL;
	_COUT "Copyright 2004-2019 by Aprisobal and all other participants" _ENDL;
	//_COUT "Patches by Antipod / boo_boo / PulkoMandy and others" _ENDL;
	//_COUT "Tidy up by Tygrys / UB880D / Cizo / mborik / z00m" _ENDL;
	_COUT "\nUsage:\nsjasmplus [options] sourcefile(s)" _ENDL;
	_COUT "\nOption flags as follows:" _ENDL;
	_COUT "  -h or --help             Help information (you see it)" _ENDL;
	_COUT "  --zxnext[=cspect]        Enable ZX Spectrum Next Z80 extensions" _ENDL;
	_COUT "  -i<path> or -I<path> or --inc=<path>" _ENDL;
	_COUT "                           Include path (later defined have higher priority)" _ENDL;
	_COUT "  --lst[=<filename>]       Save listing to <filename> (<source>.lst is default)" _ENDL;
	_COUT "  --lstlab                 Enable label table in listing" _ENDL;
	_COUT "  --sym=<filename>         Save symbols list to <filename>" _ENDL;
	_COUT "  --exp=<filename>         Save exports to <filename> (see EXPORT pseudo-op)" _ENDL;
	//_COUT "  --autoreloc              Switch to autorelocation mode. See more in docs." _ENDL;
	_COUT "  --raw=<filename>         Machine code saved also to <filename> (- is STDOUT)" _ENDL;
	_COUT " Note: use OUTPUT, LUA/ENDLUA and other pseudo-ops to control output" _ENDL;
	_COUT " Logging:" _ENDL;
	_COUT "  --nologo                 Do not show startup message" _ENDL;
	_COUT "  --msg=[all|war|err|none|lst|lstlab]" _ENDL;
	_COUT "                           Stderr messages verbosity (\"all\" is default)" _ENDL;
	_COUT "  --fullpath               Show full path to error file" _ENDL;
	_COUT " Other:" _ENDL;
	_COUT "  -D<NAME>[=<value>]       Define <NAME> as <value>" _ENDL;
	_COUT "  -                        Reads STDIN as source (no other sourcefile allowed)" _ENDL;
	_COUT "  --reversepop             Enable reverse POP order (as in base SjASM version)" _ENDL;
	_COUT "  --dirbol                 Enable directives from the beginning of line" _ENDL;
	_COUT "  --nofakes                Disable fake instructions" _ENDL;
	_COUT "  --dos866                 Encode from Windows codepage to DOS 866 (Cyrillic)" _ENDL;
	_COUT "  --syntax=<...>           Adjust parsing syntax, check docs for details." _ENDL;
}

namespace Options {
	char SymbolListFName[LINEMAX] = {0};
	char ListingFName[LINEMAX] = {0};
	char ExportFName[LINEMAX] = {0};
	char DestinationFName[LINEMAX] = {0};
	char RAWFName[LINEMAX] = {0};
	char UnrealLabelListFName[LINEMAX] = {0};
	char CSpectMapFName[LINEMAX] = {0};

	char ZX_SnapshotFName[LINEMAX] = {0};
	char ZX_TapeFName[LINEMAX] = {0};

	EOutputVerbosity OutputVerbosity = OV_ALL;
	bool IsLabelTableInListing = 0;
	bool IsDefaultListingName = false;
	bool IsShowFullPath = 0;
	bool AddLabelListing = false;
	bool HideLogo = 0;
	bool ShowHelp = 0;
	bool NoDestinationFile = true;		// no *.out file by default
	SSyntax syx, systemSyntax;
	bool SourceStdIn = false;

	// Include directories list is initialized with "." directory
	CStringsList* IncludeDirsList = new CStringsList((char *)".");
	CDefineTable CmdDefineTable;		// is initialized by constructor

	// returns true if fakes are completely disabled, false when they are enabled
	// showMessage=true: will also display error/warning (use when fake ins. is emitted)
	// showMessage=false: can be used to silently check if fake instructions are even possible
	bool noFakes(bool showMessage) {
		if (!showMessage) return !syx.FakeEnabled;
		if (!syx.FakeEnabled) {
			Error("Fake instructions are not enabled", bp, SUPPRESS);
			return true;
		}
		if (syx.FakeWarning) {	// check end-of-line comment for mentioning "fake" to remove warning
			bool inEolComment = eolComment ? nullptr != strstr(eolComment, "fake") : false;
			if (!inEolComment) Warning("Fake instruction", bp);
		}
		return false;
	}

	std::stack<SSyntax> SSyntax::syxStack;

	void SSyntax::resetCurrentSyntax() {
		new (&syx) SSyntax();	// restore defaults in current syntax
	}

	void SSyntax::pushCurrentSyntax() {
		syxStack.push(syx);		// store current syntax options into stack
	}

	bool SSyntax::popSyntax() {
		if (syxStack.empty()) return false;	// no syntax stored in stack
		syx = syxStack.top();	// copy the syntax values from stack
		syxStack.pop();
		return true;
	}

	void SSyntax::restoreSystemSyntax() {
		while (!syxStack.empty()) syxStack.pop();	// empty the syntax stack first
		syx = systemSyntax;		// reset to original system syntax
	}

} // eof namespace Options

CDevice *Devices = 0;
CDevice *Device = 0;
CDevicePage *Page = 0;
char* DeviceID = 0;

// extend
char filename[LINEMAX], * lp, line[LINEMAX], temp[LINEMAX], ErrorLine[LINEMAX2], * bp;
char sline[LINEMAX2], sline2[LINEMAX2], * substitutedLine, * eolComment;

char SourceFNames[128][MAX_PATH];
static int SourceFNamesCount = 0;
std::vector<char> stdin_log;

int ConvertEncoding = ENCWIN;

int pass = 0, IsLabelNotFound = 0, ErrorCount = 0, WarningCount = 0, IncludeLevel = -1;
int IsRunning = 0, donotlist = 0, listmacro = 0;
int adrdisp = 0, PseudoORG = 0, StartAddress = -1;
byte* MemoryPointer=NULL;
int macronummer = 0, lijst = 0, reglenwidth = 0;
aint CurAddress = 0, CurrentSourceLine = 0, CompiledCurrentLine = 0, LastParsedLabelLine = 0;
aint destlen = 0, size = -1L,PreviousErrorLine = -1L, maxlin = 0, comlin = 0;
char* CurrentDirectory=NULL;

char* ModuleName=NULL, * vorlabp=NULL, * macrolabp=NULL, * LastParsedLabel=NULL;
std::stack<SRepeatStack> RepeatStack;
CStringsList* lijstp = NULL;
CLabelTable LabelTable;
CLocalLabelTable LocalLabelTable;
CDefineTable DefineTable;
CMacroDefineTable MacroDefineTable;
CMacroTable MacroTable;
CStructureTable StructureTable;
CStringsList* ModuleList = NULL;

#ifdef USE_LUA

lua_State *LUA;
int LuaLine=-1;

#endif //USE_LUA

int deviceDirectivesCounter = 0;
static char* globalDeviceID = NULL;

void InitPass() {
	Options::SSyntax::restoreSystemSyntax();	// release all stored syntax variants and reset to initial
	aint pow10 = 1;
	reglenwidth = 0;
	do {
		++reglenwidth;
		pow10 *= 10;
		if (pow10 < 10) ExitASM(1);	// 32b overflow
	} while (pow10 <= maxlin);
	if (ModuleName != NULL) {
		free(ModuleName);
		ModuleName = NULL;
	}
	ModuleName = NULL;
	SetLastParsedLabel(nullptr);
	if (vorlabp) free(vorlabp);
	vorlabp = STRDUP("_");
	macrolabp = NULL;
	listmacro = 0;
	CurAddress = 0;
	CurrentSourceLine = CompiledCurrentLine = 0;
	PseudoORG = 0; adrdisp = 0;
	ListAddress = 0; macronummer = 0; lijst = 0; comlin = 0;
	lijstp = NULL;
	ModuleList = NULL;
	StructureTable.Init();
	MacroTable.Init();
	DefineTable = Options::CmdDefineTable;
	MacroDefineTable.Init();
	LocalLabelTable.InitPass();
	// reset "device" stuff
	if (2 == pass && Devices && 1 == deviceDirectivesCounter) {	// only single device detected
		globalDeviceID = STRDUP(Devices->ID);		// make it global for remaining passes
	}
	if (Devices) delete Devices;
	Devices = Device = NULL;
	DeviceID = NULL;
	deviceDirectivesCounter = 0;

	// predefined
	DefineTable.Replace("_SJASMPLUS", "1");
	DefineTable.Replace("_VERSION", "\"" VERSION "\"");
	DefineTable.Replace("_RELEASE", "0");
	DefineTable.Replace("_ERRORS", "0");
	DefineTable.Replace("_WARNINGS", "0");
	// resurrect "global" device here
	if (globalDeviceID && !SetDevice(globalDeviceID)) {
		Error("Failed to re-initialize global device", globalDeviceID, FATAL);
	}
}

void FreeRAM() {
	if (Devices) {
		delete Devices;		Devices = NULL;
	}
	if (globalDeviceID) {
		free(globalDeviceID);	globalDeviceID = NULL;
	}
	if (ModuleList) {
		delete ModuleList;	ModuleList = NULL;
	}
	if (lijstp) {
		delete lijstp;		lijstp = NULL;
	}
	free(vorlabp);		vorlabp = NULL;
	LabelTable.RemoveAll();
	DefineTable.RemoveAll();
	SetLastParsedLabel(nullptr);
}


void ExitASM(int p) {
	FreeRAM();
	if (pass == LASTPASS) {
		Close();
	}
	exit(p);
}

namespace Options {

	class COptionsParser {
	private:
		const char* arg;
		char opt[LINEMAX];
		char val[LINEMAX];

		// returns 1 when argument was processed (keyword detected, value copied into buffer)
		// If buffer == NULL, only detection of keyword + check for non-zero "value" is done (no copy)
		int CheckAssignmentOption(const char* keyword, char* buffer, const size_t bufferSize) {
			if (strcmp(keyword, opt)) return 0;		// detect "keyword" (return 0 if not)
			if (*val) {
				if (NULL != buffer) STRCPY(buffer, bufferSize, val);
			} else {
				_CERR "No parameters found in " _CMDL arg _ENDL;
			}
			return 1;	// keyword detected, option was processed
		}

		static void splitByChar(const char* s, const int splitter,
							   char* v1, const size_t v1Size,
							   char* v2, const size_t v2Size) {
			// only non-zero splitter character is supported
			const char* spos = splitter ? STRCHR(s, splitter) : NULL;
			if (NULL == spos) {
				// splitter character not found, copy whole input string into v1, v2 = empty string
				STRCPY(v1, v1Size, s);
				v2[0] = 0;
			} else {
				// splitter found, copy string ahead splitter to v1, after it to v2
				STRNCPY(v1, v1Size, s, spos - s);
				v1[spos - s] = 0;
				STRCPY(v2, v2Size, spos + 1);
			}
		}

		void parseSyntaxValue() {
			// Options::syx is expected to be already in default state before entering this
			for (const auto & syntaxOption : val) {
				switch (syntaxOption) {
				case 0:   return;
				// f F - instructions: fake warning, no fakes (default = fake enabled)
				case 'f': syx.FakeEnabled = syx.FakeWarning = true; break;
				case 'F': syx.FakeEnabled = false; break;
				// a A - multi-argument delimiter: ",,", "``" (default = ",")
				case 'a': syx.MultiArg = &doubleComma; break;
				case 'A': syx.MultiArg = &doubleBacktick; break;
				// b B - memory access brackets []: disabled, required (default = enabled)
				case 'b':
				case 'B':
				// l L - warn/error about labels using keywords (default = no message)
				case 'l':
				case 'L':
					if (0 == pass || LASTPASS == pass) {
						_CERR "Syntax option not implemented yet: " _CMDL syntaxOption _ENDL;
					}
					break;
				case 'i': syx.CaseInsensitiveInstructions = true; break;
				default:
					if (0 == pass || LASTPASS == pass) {
						_CERR "Unrecognized syntax option: " _CMDL syntaxOption _ENDL;
					}
					break;
				}
			}
		}

	public:
		void GetOptions(const char* const * const argv, int& i, bool onlySyntaxOptions = false) {
			while ((arg=argv[i]) && ('-' == arg[0])) {
				// copy "option" (up to '=' char) into `opt`, copy "value" (after '=') into `val`
				if ('-' == arg[1]) {	// double-dash detected, value is expected after "="
					splitByChar(arg + 2, '=', opt, LINEMAX, val, LINEMAX);
				} else {				// single dash, parse value from second character onward
					opt[0] = arg[1];	// copy only single letter into `opt`
					opt[1] = 0;
					if (opt[0]) {		// if it was not empty, try to copy also `val`
						STRCPY(val, LINEMAX, arg + 2);
					}
				}

				// check for particular options and setup option value by it
				// first check all syntax-only options which may be modified by OPT directive
				if (!strcmp(opt, "zxnext")) {
					syx.IsNextEnabled = 1;
					if (!strcmp(val, "cspect")) syx.IsNextEnabled = 2;	// CSpect emulator extensions
				} else if (!strcmp(opt, "reversepop")) {
					syx.IsReversePOP = true;
				} else if (!strcmp(opt, "dirbol")) {
					syx.IsPseudoOpBOF = true;
				} else if (!strcmp(opt, "nofakes")) {
					syx.FakeEnabled = false;
				} else if (!strcmp(opt, "syntax")) {
					parseSyntaxValue();
				} else if (onlySyntaxOptions) {
					// rest of the options is available only when launching the sjasmplus
					return;
				} else if (!strcmp(opt,"h") || !strcmp(opt, "help")) {
					ShowHelp = 1;
				} else if (!strcmp(opt, "lstlab")) {
					AddLabelListing = true;
				} else if (CheckAssignmentOption("msg", NULL, 0)) {
					if (!strcmp("none", val)) {
						OutputVerbosity = OV_NONE;
						HideLogo = true;
					} else if (!strcmp("err", val)) {
						OutputVerbosity = OV_ERROR;
					} else if (!strcmp("war", val)) {
						OutputVerbosity = OV_WARNING;
					} else if (!strcmp("all", val)) {
						OutputVerbosity = OV_ALL;
					} else if (!strcmp("lst", val)) {
						OutputVerbosity = OV_LST;
						AddLabelListing = false;
					} else if (!strcmp("lstlab", val)) {
						OutputVerbosity = OV_LST;
						AddLabelListing = true;
					} else {
						_CERR "Unexpected parameter in " _CMDL arg _ENDL;
					}
				} else if (!strcmp(opt, "lst") && !val[0]) {
					IsDefaultListingName = true;
				} else if (
					CheckAssignmentOption("sym", SymbolListFName, LINEMAX) ||
					CheckAssignmentOption("lst", ListingFName, LINEMAX) ||
					CheckAssignmentOption("exp", ExportFName, LINEMAX) ||
					CheckAssignmentOption("raw", RAWFName, LINEMAX) ) {
					// was proccessed inside CheckAssignmentOption function
				} else if (!strcmp(opt, "fullpath")) {
					IsShowFullPath = 1;
				} else if (!strcmp(opt, "nologo")) {
					HideLogo = 1;
				} else if (!strcmp(opt, "dos866")) {
					ConvertEncoding = ENCDOS;
				} else if (!strcmp(opt, "inc") || !strcmp(opt, "i") || !strcmp(opt, "I")) {
					if (*val) {
						IncludeDirsList = new CStringsList(val, IncludeDirsList);
					} else {
						_CERR "No include path found in " _CMDL arg _ENDL;
					}
				} else if (opt[0] == 'D') {
					char defN[LINEMAX], defV[LINEMAX];
					if (*val) {		// for -Dname=value the `val` contains "name=value" string
						//TODO the `Error("Duplicate name"..)` is not shown while parsing CLI options
						splitByChar(val, '=', defN, LINEMAX, defV, LINEMAX);
						CmdDefineTable.Add(defN, defV, NULL);
					} else {
						_CERR "No parameters found in " _CMDL arg _ENDL;
					}
				} else if (0 == opt[0]) {
					SourceStdIn = true;		// only single "-" was on command line = source STDIN
					stdin_log.reserve(100000);	// reserve 100k bytes for a start
				} else {
					_CERR "Unrecognized option: " _CMDL opt _ENDL;
				}

				++i;					// next CLI argument
			} // end of while ((arg=argv[i]) && ('-' == arg[0]))
		}
	};

	int parseSyntaxOptions(int n, char** options) {
		if (n <= 0) return 0;
		int i = 0;
		Options::COptionsParser optParser;
		optParser.GetOptions(options, i, true);
		return i;
	}
}

#ifdef USE_LUA

void LuaFatalError(lua_State *L) {
	Error((char *)lua_tostring(L, -1), NULL, FATAL);
}

#endif //USE_LUA

#ifdef WIN32
int main(int argc, char* argv[]) {
#else
int main(int argc, char **argv) {
#endif
	char buf[MAX_PATH];
	int base_encoding;
	char* p;
	const char* logo = "SjASMPlus Z80 Cross-Assembler v" VERSION " (https://github.com/z00m128/sjasmplus)";

	// start counter
	long dwStart;
	dwStart = GetTickCount();

	// get current directory
	GetCurrentDirectory(MAX_PATH, buf);
	CurrentDirectory = buf;

	Options::COptionsParser optParser;
	char* envFlags = std::getenv("SJASMPLUSOPTS");
	if (nullptr != envFlags) {
		// split environment arguments into "argc, argv" like variables (by white-space)
		char* parsedOptsArray[33] {};	// there must be one more nullptr in the array (32+1)
		int optI = 0, charI = 0;
		while (optI < 32 && !SkipBlanks(envFlags)) {
			parsedOptsArray[optI++] = temp + charI;
			while (*envFlags && !White(*envFlags) && charI < LINEMAX-1) temp[charI++] = *envFlags++;
			temp[charI++] = 0;
		}
		if (!SkipBlanks(envFlags)) {
			_CERR "SJASMPLUSOPTS environment variable contains too many options (max is 32)" _ENDL;
		}
		// process environment variable ahead of command line options (in the same way)
		int i = 0;
		while (parsedOptsArray[i]) {
			optParser.GetOptions(parsedOptsArray, i);
			if (!parsedOptsArray[i] || 128 <= SourceFNamesCount) break;
			STRCPY(SourceFNames[SourceFNamesCount++], MAX_PATH-32, parsedOptsArray[i++]);
		}
	}

	int i = 1;
	if (argc > 1) {
		while (argv[i]) {
			optParser.GetOptions(argv, i);
			if (!argv[i] || 128 <= SourceFNamesCount) break;
			STRCPY(SourceFNames[SourceFNamesCount++], MAX_PATH-32, argv[i++]);
		}
		if (Options::IsDefaultListingName && Options::ListingFName[0]) {
			Error("Using both  --lst  and  --lst=<filename>  is not possible.", NULL, FATAL);
		}
		if (OV_LST == Options::OutputVerbosity && (Options::IsDefaultListingName || Options::ListingFName[0])) {
			Error("Using  --msg=lst[lab]  and other list options is not possible.", NULL, FATAL);
		}
	}
	Options::systemSyntax = Options::syx;		// create copy of initial system settings of syntax

	if (argc == 1 || Options::ShowHelp) {
		_COUT logo _ENDL;
		PrintHelp();
		exit(1);
	}

	if (!Options::HideLogo) {
		_CERR logo _ENDL;
	}

#ifdef USE_LUA

	// init LUA
	LUA = lua_open();
	lua_atpanic(LUA, (lua_CFunction)LuaFatalError);
	luaL_openlibs(LUA);
	luaopen_pack(LUA);

	tolua_sjasm_open(LUA);

#endif //USE_LUA

	// exit with error if no input file were specified
	if (!SourceFNames[0][0] && !Options::SourceStdIn) {
		if (Options::OutputVerbosity <= OV_ERROR) {
			_CERR "No inputfile(s)" _ENDL;
		}
		exit(1);
	}
	// verify for STDIN input there is no other file specified + create empty name signaling STDIN
	if (Options::SourceStdIn) {
		if (0 < SourceFNamesCount) {	// list of explicit input files must be empty with `-` option
			if (Options::OutputVerbosity <= OV_ERROR) {
				_CERR "Don't add input file when STDIN option is specified." _ENDL;
			}
			exit(1);
		}
		// stdin itself has empty filename
		SourceFNames[SourceFNamesCount++][0] = 0;
		// but fake output name if not selected explicitly
		if (!Options::DestinationFName[0]) STRCPY(Options::DestinationFName, LINEMAX, "asm.out");
	}

	// create default output name, if not specified
	if (!Options::DestinationFName[0]) {
		STRCPY(Options::DestinationFName, LINEMAX, SourceFNames[0]);
		if (!(p = strchr(Options::DestinationFName, '.'))) {
			p = Options::DestinationFName;
		} else {
			*p = 0;
		}
		STRCAT(p, LINEMAX-(p-Options::DestinationFName), ".out");
	}

	base_encoding = ConvertEncoding;

	// init some vars
	InitCPU();

	// open lists (if not set to "default" file name, then the OpenFile will handle it)
	OpenList();

	do {
		++pass;
		InitPass();

		if (pass == LASTPASS) OpenDest();

		for (i = 0; i < SourceFNamesCount; i++) {
			IsRunning = 1;
			ConvertEncoding = base_encoding;
			OpenFile(SourceFNames[i]);
		}

		if (PseudoORG) {
			CurAddress = adrdisp; PseudoORG = 0;
		}

		if (Options::OutputVerbosity <= OV_ALL) {
			if (pass != LASTPASS) {
				_CERR "Pass " _CMDL pass _CMDL " complete (" _CMDL ErrorCount _CMDL " errors)" _ENDL;
			} else {
				_CERR "Pass 3 complete" _ENDL;
			}
		}
	} while (pass < LASTPASS);

	pass = 9999; /* added for detect end of compiling */

	// dump label table into listing file, the explicit one (Options::IsDefaultListingName == false)
	if (Options::AddLabelListing) LabelTable.Dump();

	Close();

	if (Options::UnrealLabelListFName[0]) {
		LabelTable.DumpForUnreal();
	}

	if (Options::CSpectMapFName[0]) {
		LabelTable.DumpForCSpect();
	}

	if (Options::SymbolListFName[0]) {
		LabelTable.DumpSymbols();
	}

	if (Options::OutputVerbosity <= OV_ALL) {
		_CERR "Errors: " _CMDL ErrorCount _CMDL ", warnings: " _CMDL WarningCount _CMDL ", compiled: " _CMDL CompiledCurrentLine _CMDL " lines" _END;

		double dwCount;
		dwCount = GetTickCount() - dwStart;
		if (dwCount < 0) {
			dwCount = 0;
		}
		char workTimeTxt[200] = "";
		SPRINTF1(workTimeTxt, 200, ", work time: %.3f seconds", dwCount / 1000);

		_CERR workTimeTxt _ENDL;
	}

	cout << flush;

	// free RAM
	FreeRAM();

#ifdef USE_LUA

	// close Lua
	lua_close(LUA);

#endif //USE_LUA

	return (ErrorCount != 0);
}
//eof sjasm.cpp
