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
#include <chrono>
#include <ctime>

#ifdef USE_LUA

#include "lua_sjasm.h"

#endif //USE_LUA

static void PrintHelpMain() {
	// Please keep help lines at most 79 characters long (cursor at column 88 after last char)
	//     |<-- ...8901234567890123456789012345678901234567890123456789012... 80 chars -->|
	_COUT "Based on code of SjASM by Sjoerd Mastijn (http://www.xl2s.tk)" _ENDL;
	_COUT "Copyright 2004-2020 by Aprisobal and all other participants" _ENDL;
	//_COUT "Patches by Antipod / boo_boo / PulkoMandy and others" _ENDL;
	//_COUT "Tidy up by Tygrys / UB880D / Cizo / mborik / z00m" _ENDL;
	_COUT "\nUsage:\nsjasmplus [options] sourcefile(s)" _ENDL;
	_COUT "\nOption flags as follows:" _ENDL;
	_COUT "  -h or --help[=warnings]  Help information (you see it)" _ENDL;
	_COUT "  --zxnext[=cspect]        Enable ZX Spectrum Next Z80 extensions (Z80N)" _ENDL;
	_COUT "  --i8080                  Limit valid instructions to i8080 only (+ no fakes)" _ENDL;
	_COUT "  --lr35902                Sharp LR35902 CPU instructions mode (+ no fakes)" _ENDL;
	_COUT "  --outprefix=<path>       Prefix for save/output/.. filenames in directives" _ENDL;
	_COUT "  -i<path> or -I<path> or --inc=<path> ( --inc without \"=\" to empty the list)" _ENDL;
	_COUT "                           Include path (later defined have higher priority)" _ENDL;
	_COUT "  --lst[=<filename>]       Save listing to <filename> (<source>.lst is default)" _ENDL;
	_COUT "  --lstlab[=sort]          Append [sorted] symbol table to listing" _ENDL;
	_COUT "  --sym=<filename>         Save symbol table to <filename>" _ENDL;
	_COUT "  --exp=<filename>         Save exports to <filename> (see EXPORT pseudo-op)" _ENDL;
	//_COUT "  --autoreloc              Switch to autorelocation mode. See more in docs." _ENDL;
	_COUT "  --raw=<filename>         Machine code saved also to <filename> (- is STDOUT)" _ENDL;
	_COUT "  --sld[=<filename>]       Save Source Level Debugging data to <filename>" _ENDL;
	_COUT " Note: use OUTPUT, LUA/ENDLUA and other pseudo-ops to control output" _ENDL;
	_COUT " Logging:" _ENDL;
	_COUT "  --nologo                 Do not show startup message" _ENDL;
	_COUT "  --msg=[all|war|err|none|lst|lstlab]" _ENDL;
	_COUT "                           Stderr messages verbosity (\"all\" is default)" _ENDL;
	_COUT "  --fullpath               Show full path to file in errors" _ENDL;
	_COUT " Other:" _ENDL;
	_COUT "  -D<NAME>[=<value>]       Define <NAME> as <value>" _ENDL;
	_COUT "  -                        Reads STDIN as source (even in between regular files)" _ENDL;
	_COUT "  --longptr                No device: program counter $ can go beyond 0x10000" _ENDL;
	_COUT "  --reversepop             Enable reverse POP order (as in base SjASM version)" _ENDL;
	_COUT "  --dirbol                 Enable directives from the beginning of line" _ENDL;
	_COUT "  --dos866                 Encode from Windows codepage to DOS 866 (Cyrillic)" _ENDL;
	_COUT "  --syntax=<...>           Adjust parsing syntax, check docs for details." _ENDL;
}

namespace Options {
	char OutPrefix[LINEMAX] = {0};
	char SymbolListFName[LINEMAX] = {0};
	char ListingFName[LINEMAX] = {0};
	char ExportFName[LINEMAX] = {0};
	char DestinationFName[LINEMAX] = {0};
	char RAWFName[LINEMAX] = {0};
	char UnrealLabelListFName[LINEMAX] = {0};
	char CSpectMapFName[LINEMAX] = {0};
	int CSpectMapPageSize = 0x4000;
	char SourceLevelDebugFName[LINEMAX] = {0};
	bool IsDefaultSldName = false;

	char ZX_SnapshotFName[LINEMAX] = {0};
	char ZX_TapeFName[LINEMAX] = {0};

	EOutputVerbosity OutputVerbosity = OV_ALL;
	bool IsLabelTableInListing = 0;
	bool IsDefaultListingName = false;
	bool IsShowFullPath = 0;
	bool AddLabelListing = false;
	bool HideLogo = 0;
	bool ShowHelp = false;
	bool ShowHelpWarnings = false;
	bool ShowVersion = false;
	bool NoDestinationFile = true;		// no *.out file by default
	SSyntax syx, systemSyntax;
	bool IsI8080 = false;
	bool IsLR35902 = false;
	bool IsLongPtr = false;
	bool SortSymbols = false;
	bool IsBigEndian = false;
	bool EmitVirtualLabels = false;

	// Include directories list is initialized with "." directory
	CStringsList* IncludeDirsList = new CStringsList(".");

	CDefineTable CmdDefineTable;		// is initialized by constructor

	static const char* fakes_disabled_txt_error = "Fake instructions are not enabled";
	static const char* fakes_in_i8080_txt_error = "Fake instructions are not implemented in i8080 mode";
	static const char* fakes_in_lr35902_txt_error = "Fake instructions are not implemented in Sharp LR35902 mode";

	// returns true if fakes are completely disabled, false when they are enabled
	// showMessage=true: will also display error/warning (use when fake ins. is emitted)
	// showMessage=false: can be used to silently check if fake instructions are even possible
	bool noFakes(bool showMessage) {
		bool fakesDisabled = Options::IsI8080 || Options::IsLR35902 || (!syx.FakeEnabled);
		if (!showMessage) return fakesDisabled;
		if (fakesDisabled) {
			const char* errorTxt = fakes_disabled_txt_error;
			if (Options::IsI8080) errorTxt = fakes_in_i8080_txt_error;
			if (Options::IsLR35902) errorTxt = fakes_in_lr35902_txt_error;
			Error(errorTxt, bp, SUPPRESS);
			return true;
		}
		// check end-of-line comment for mentioning "fake" to remove warning, or beginning with "ok"
		if (syx.FakeWarning && warningNotSuppressed(true)) {
			Warning("Fake instruction", bp);
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

static void PrintHelp(bool forceMainHelp) {
	if (forceMainHelp || Options::ShowHelp) PrintHelpMain();
	if (Options::ShowHelpWarnings) PrintHelpWarnings();
}

CDevice *Devices = nullptr;
CDevice *Device = nullptr;
CDevicePage *Page = nullptr;
char* DeviceID = nullptr;
TextFilePos globalDeviceSourcePos = TextFilePos();
aint deviceDirectivesCount = 0;
static char* globalDeviceID = nullptr;
static aint globalDeviceZxRamTop = 0;

// extend
const char* fileNameFull = nullptr, * fileName = nullptr;	//fileName is either full or basename (--fullpath)
char* lp, line[LINEMAX], temp[LINEMAX], * bp;
char sline[LINEMAX2], sline2[LINEMAX2], * substitutedLine, * eolComment, ModuleName[LINEMAX];

SSource::SSource(SSource && src) {	// move constructor, "pick" the stdin pointer
	memcpy(fname, src.fname, MAX_PATH);
	stdin_log = src.stdin_log;
	src.fname[0] = 0;
	src.stdin_log = nullptr;
}

SSource::SSource(const char* newfname) : stdin_log(nullptr) {
	STRNCPY(fname, MAX_PATH, newfname, MAX_PATH-1);
	fname[MAX_PATH-1] = 0;
}

SSource::SSource(int) {
	fname[0] = 0;
	stdin_log = new stdin_log_t();
	stdin_log->reserve(50*1024);
}

SSource::~SSource() {
	if (stdin_log) delete stdin_log;
}

std::vector<SSource> sourceFiles;
std::vector<std::string> openedFileNames;

int ConvertEncoding = ENCWIN;

EDispMode PseudoORG = DISP_NONE;
int pass = 0, IsLabelNotFound = 0, ErrorCount = 0, WarningCount = 0, IncludeLevel = -1;
int IsRunning = 0, donotlist = 0, listmacro = 0;
int adrdisp = 0, dispPageNum = LABEL_PAGE_UNDEFINED, StartAddress = -1;
byte* MemoryPointer=NULL;
int macronummer = 0, lijst = 0, reglenwidth = 0;
TextFilePos CurSourcePos, DefinitionPos;
uint32_t maxlin = 0;
aint CurAddress = 0, CompiledCurrentLine = 0, LastParsedLabelLine = 0, PredefinedCounter = 0;
aint destlen = 0, size = -1L, comlin = 0;
char* CurrentDirectory=NULL;

char* vorlabp=NULL, * macrolabp=NULL, * LastParsedLabel=NULL;
std::stack<SRepeatStack> RepeatStack;
CStringsList* lijstp = NULL;
CLabelTable LabelTable;
CLocalLabelTable LocalLabelTable;
CDefineTable DefineTable;
CMacroDefineTable MacroDefineTable;
CMacroTable MacroTable;
CStructureTable StructureTable;

#ifdef USE_LUA

lua_State *LUA;			// lgtm[cpp/short-global-name] .. name seems barely ok (especially considering rest of code)
TextFilePos LuaStartPos;

#endif //USE_LUA

// reserve keywords in labels table, to detect when user is defining label colliding with keyword
static void ReserveLabelKeywords() {
	for (const char* keyword : {
		"abs", "and", "high", "low", "mod", "norel", "not", "or", "shl", "shr", "xor"
	}) {
		LabelTable.Insert(keyword, -65536, LABEL_IS_UNDEFINED|LABEL_IS_KEYWORD);
	}
}

void InitPass() {
	Relocation::InitPass();
	Options::SSyntax::restoreSystemSyntax();	// release all stored syntax variants and reset to initial
	uint32_t maxpow10 = 1;
	reglenwidth = 0;
	do {
		++reglenwidth;
		maxpow10 *= 10;
		if (maxpow10 < 10) ExitASM(1);	// 32b overflow
	} while (maxpow10 <= maxlin);
	*ModuleName = 0;
	SetLastParsedLabel(nullptr);
	if (vorlabp) free(vorlabp);
	vorlabp = STRDUP("_");
	macrolabp = NULL;
	listmacro = 0;
	CurAddress = 0;
	CompiledCurrentLine = 0;
	PseudoORG = DISP_NONE; adrdisp = 0; dispPageNum = LABEL_PAGE_UNDEFINED;
	ListAddress = 0; macronummer = 0; lijst = 0; comlin = 0;
	lijstp = NULL;
	DidEmitByte();				// reset the emitted flag
	StructureTable.ReInit();
	MacroTable.ReInit();
	MacroDefineTable.ReInit();
	DefineTable = Options::CmdDefineTable;
	LocalLabelTable.InitPass();

	// reset "device" stuff + detect "global device" directive
	if (globalDeviceID) {		// globalDeviceID detector has to trigger before every pass
		free(globalDeviceID);
		globalDeviceID = nullptr;
	}
	if (1 < pass && 1 == deviceDirectivesCount && Devices) {	// only single DEVICE used
		globalDeviceID = STRDUP(Devices->ID);		// make it global for next pass
		globalDeviceZxRamTop = Devices->ZxRamTop;
	}
	if (Devices) delete Devices;
	Devices = Device = nullptr;
	DeviceID = nullptr;
	Page = nullptr;
	deviceDirectivesCount = 0;
	// resurrect "global" device here
	if (globalDeviceID) {
		CurSourcePos = globalDeviceSourcePos;
		DefinitionPos = TextFilePos();
		if (!SetDevice(globalDeviceID, globalDeviceZxRamTop)) {
			Error("Failed to re-initialize global device", globalDeviceID, FATAL);
		}
	}

	// reset current source/definition positions
	CurSourcePos = DefinitionPos = TextFilePos();

	// predefined defines - (deprecated) classic sjasmplus v1.x (till v1.15.1)
	DefineTable.Replace("_SJASMPLUS", "1");
	DefineTable.Replace("_RELEASE", "0");
	DefineTable.Replace("_VERSION", "__VERSION__");
	DefineTable.Replace("_ERRORS", "__ERRORS__");
	DefineTable.Replace("_WARNINGS", "__WARNINGS__");
	// predefined defines - sjasmplus v2.x-like (since v1.16.0)
	// __DATE__ and __TIME__ are defined just once in main(...) (stored in Options::CmdDefineTable)
	DefineTable.Replace("__SJASMPLUS__", VERSION_NUM);		// modified from _SJASMPLUS
	DefineTable.Replace("__VERSION__", "\"" VERSION "\"");	// migrated from _VERSION
	DefineTable.Replace("__ERRORS__", "0");					// migrated from _ERRORS
	DefineTable.Replace("__WARNINGS__", "0");				// migrated from _WARNINGS
	DefineTable.Replace("__PASS__", pass);					// current pass of assembler
	DefineTable.Replace("__INCLUDE_LEVEL__", "-1");			// include nesting
	DefineTable.Replace("__BASE_FILE__", "<none>");			// the include-level 0 file
	DefineTable.Replace("__FILE__", "<none>");				// current file
	DefineTable.Replace("__LINE__", "<dynamic value>");		// current line in current file
	DefineTable.Replace("__COUNTER__", "<dynamic value>");	// gcc-like, incremented upon every use
	PredefinedCounter = 0;
}

void FreeRAM() {
	if (Devices) {
		delete Devices;		Devices = nullptr;
	}
	if (globalDeviceID) {
		free(globalDeviceID);	globalDeviceID = nullptr;
	}
	lijstp = NULL;		// do not delete this, should be released by owners of DUP/regular macros
	free(vorlabp);		vorlabp = NULL;
	LabelTable.RemoveAll();
	DefineTable.RemoveAll();
	SetLastParsedLabel(nullptr);
	if (PreviousIsLabel) {
		free(PreviousIsLabel);
		PreviousIsLabel = nullptr;
	}
	if (Options::IncludeDirsList) delete Options::IncludeDirsList;
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
				// a - multi-argument delimiter ",," (default is ",")
				case 'a': syx.MultiArg = &doubleComma; break;
				// b - single parentheses enforce mem access (default = relaxed syntax)
				case 'b': syx.MemoryBrackets = 1; break;
				// B - memory access brackets [] required (default = relaxed syntax)
				case 'B': syx.MemoryBrackets = 2; break;
				// l L - warn/error about labels using keywords (default = no message)
				case 'l':
				case 'L':
					if (0 == pass || LASTPASS == pass) {
						_CERR "Syntax option not implemented yet: " _CMDL syntaxOption _ENDL;
					}
					break;
				// i - case insensitive instructions/directives (default = same case required)
				case 'i': syx.CaseInsensitiveInstructions = true; break;
				// w - warnings option: report warnings as errors
				case 'w': syx.WarningsAsErrors = true; break;
				// m - switch off "Accessing low memory" warning globally
				case 'm':
					syx.IsLowMemWarningEnabled = false;
					Warning("`--syntax=m` is deprecated, use `-Wno-rdlow` instead", (0 == pass) ? nullptr : bp, (0 == pass) ? W_EARLY : W_PASS3);
					//TODO remove "m" option completely after ~8/2021
					break;
				// M - alias "m" and "M" for "(hl)" to cover 8080-like syntax: ADD A,M
				case 'M': syx.Is_M_Memory = true; break;
				// unrecognized option
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
				bool doubleDash = false;
				// copy "option" (up to '=' char) into `opt`, copy "value" (after '=') into `val`
				if ('-' == arg[1]) {	// double-dash detected, value is expected after "="
					doubleDash = true;
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
					if (IsI8080) Error("Can't enable Next extensions while in i8080 mode", nullptr, FATAL);
					if (IsLR35902) Error("Can't enable Next extensions while in Sharp LR35902 mode", nullptr, FATAL);
					syx.IsNextEnabled = 1;
					if (!strcmp(val, "cspect")) syx.IsNextEnabled = 2;	// CSpect emulator extensions
				} else if (!strcmp(opt, "reversepop")) {
					syx.IsReversePOP = true;
				} else if (!strcmp(opt, "dirbol")) {
					syx.IsPseudoOpBOF = true;
				} else if (!strcmp(opt, "nofakes")) {
					syx.FakeEnabled = false;
					Warning("`--nofakes` is deprecated, use `--syntax=F` instead", nullptr, (0 == pass) ? W_EARLY : W_PASS3);
					//TODO remove "--nofakes" option completely after ~8/2021
				} else if (!strcmp(opt, "syntax")) {
					parseSyntaxValue();
				} else if (!doubleDash && 'W' == opt[0]) {
					CliWoption(val);
				} else if (onlySyntaxOptions) {
					// rest of the options is available only when launching the sjasmplus
					return;
				} else if (!strcmp(opt, "lr35902")) {
					IsLR35902 = true;
					// force (silently) other CPU modes OFF
					IsI8080 = false;
					syx.IsNextEnabled = 0;
				} else if (!strcmp(opt, "i8080")) {
					IsI8080 = true;
					// force (silently) other CPU modes OFF
					IsLR35902 = false;
					syx.IsNextEnabled = 0;
				} else if ((!doubleDash && 'h' == opt[0] && !val[0]) || (doubleDash && !strcmp(opt, "help"))) {
					ShowHelp |= strcmp("warnings", val);
					ShowHelpWarnings |= !strcmp("warnings", val);
				} else if (doubleDash && !strcmp(opt, "version")) {
					ShowVersion = true;
				} else if (!strcmp(opt, "lstlab")) {
					AddLabelListing = true;
					if (val[0]) SortSymbols = !strcmp("sort", val);
				} else if (!strcmp(opt, "longptr")) {
					IsLongPtr = true;
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
						HideLogo = true;
					} else if (!strcmp("lstlab", val)) {
						OutputVerbosity = OV_LST;
						AddLabelListing = true;
						SortSymbols = true;
						HideLogo = true;
					} else {
						_CERR "Unexpected parameter in " _CMDL arg _ENDL;
					}
				} else if (!strcmp(opt, "lst") && !val[0]) {
					IsDefaultListingName = true;
				} else if (!strcmp(opt, "sld") && !val[0]) {
					IsDefaultSldName = true;
				} else if (
					CheckAssignmentOption("outprefix", OutPrefix, LINEMAX) ||
					CheckAssignmentOption("sym", SymbolListFName, LINEMAX) ||
					CheckAssignmentOption("lst", ListingFName, LINEMAX) ||
					CheckAssignmentOption("exp", ExportFName, LINEMAX) ||
					CheckAssignmentOption("sld", SourceLevelDebugFName, LINEMAX) ||
					CheckAssignmentOption("raw", RAWFName, LINEMAX) ) {
					// was proccessed inside CheckAssignmentOption function
				} else if (!strcmp(opt, "fullpath")) {
					IsShowFullPath = 1;
				} else if (!strcmp(opt, "nologo")) {
					HideLogo = 1;
				} else if (!strcmp(opt, "dos866")) {
					ConvertEncoding = ENCDOS;
				} else if ((doubleDash && !strcmp(opt, "inc")) ||
							(!doubleDash && 'i' == opt[0]) ||
							(!doubleDash && 'I' == opt[0])) {
					if (*val) {
						IncludeDirsList = new CStringsList(val, IncludeDirsList);
					} else {
						if (!doubleDash || '=' == arg[5]) {
							_CERR "No include path found in " _CMDL arg _ENDL;
						} else {	// individual `--inc` without "=path" will RESET include dirs
							if (IncludeDirsList) delete IncludeDirsList;
							IncludeDirsList = nullptr;
						}
					}
				} else if (!doubleDash && 'D' == opt[0]) {
					char defN[LINEMAX], defV[LINEMAX];
					if (*val) {		// for -Dname=value the `val` contains "name=value" string
						//TODO the `Error("Duplicate name"..)` is not shown while parsing CLI options
						splitByChar(val, '=', defN, LINEMAX, defV, LINEMAX);
						CmdDefineTable.Add(defN, defV, NULL);
					} else {
						_CERR "No parameters found in " _CMDL arg _ENDL;
					}
				} else if (!doubleDash && 0 == opt[0]) {
					// only single "-" was on command line = source STDIN
					sourceFiles.push_back(SSource(1));		// special constructor for stdin input
				} else {
					_CERR "Unrecognized option: " _CMDL arg _ENDL;
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

// ==============================================================================================
// == UnitTest++ part, checking if unit tests are requested and does launch test-runner then   ==
// ==============================================================================================
#ifdef ADD_UNIT_TESTS

# include "UnitTest++/UnitTest++.h"

# define STOP_MAKE_BY_NON_ZERO_EXIT_CODE 0

//detect "--unittest" switch, prepare UnitTest++, run the test runner, collect results, exit
# define CHECK_UNIT_TESTS \
	{ \
		if (2 == argc && !strcmp("--unittest", argv[1])) { \
			_COUT "SjASMPlus \033[96mv" VERSION "\033[0m | \033[95mrunning unit tests:\033[0m" _ENDL _END \
			int exitCode = STOP_MAKE_BY_NON_ZERO_EXIT_CODE + UnitTest::RunAllTests(); \
			if (exitCode) _COUT "\033[91mNon-zero result from test runner!\033[0m" _ENDL _END \
			else _COUT "\033[92mOK: 0 UnitTest++ tests failed.\033[0m" _ENDL _END \
			exit(exitCode); \
		} \
	}
#else

# define CHECK_UNIT_TESTS { /* no unit tests in this build */ }

#endif

// == end of UnitTest++ part ====================================================================

#ifdef WIN32
int main(int argc, char* argv[]) {
#else
int main(int argc, char **argv) {
#endif
	char buf[MAX_PATH];
	int base_encoding;
	const char* logo = "SjASMPlus Z80 Cross-Assembler v" VERSION " (https://github.com/z00m128/sjasmplus)";

	sourceFiles.reserve(32);
	openedFileNames.reserve(64);

	CHECK_UNIT_TESTS		// UnitTest++ extra handling in specially built executable

	const word little_endian_test[] = { 0x1234 };
	const byte le_test_byte = *reinterpret_cast<const byte*>(little_endian_test);
	Options::IsBigEndian = (0x12 == le_test_byte);
	if (Options::IsBigEndian) WarningById(W_BE_HOST, nullptr, W_EARLY);

	// start counter
	long dwStart = GetTickCount();

	// get current directory
	SJ_GetCurrentDirectory(MAX_PATH, buf);
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
			if (!parsedOptsArray[i]) break;
			sourceFiles.push_back(SSource(parsedOptsArray[i++]));
		}
	}

	// setup __DATE__ and __TIME__ macros (setup them just once, not every pass!)
	auto now = std::chrono::system_clock::now();
	std::time_t now_c = std::chrono::system_clock::to_time_t(now);
	std::tm now_tm = *std::localtime(&now_c);	// lgtm [cpp/potentially-dangerous-function]
	char dateBuffer[32] = {}, timeBuffer[32] = {};
	SPRINTF3(dateBuffer, 30, "\"%04d-%02d-%02d\"", now_tm.tm_year + 1900, now_tm.tm_mon + 1, now_tm.tm_mday);
	SPRINTF3(timeBuffer, 30, "\"%02d:%02d:%02d\"", now_tm.tm_hour, now_tm.tm_min, now_tm.tm_sec);
	Options::CmdDefineTable.Add("__DATE__", dateBuffer, nullptr);
	Options::CmdDefineTable.Add("__TIME__", timeBuffer, nullptr);

	int i = 1;
	if (argc > 1) {
		while (argv[i]) {
			optParser.GetOptions(argv, i);
			if (!argv[i]) break;
			sourceFiles.push_back(SSource(argv[i++]));
		}
	}
	if (Options::IsDefaultListingName && Options::ListingFName[0]) {
		Error("Using both  --lst  and  --lst=<filename>  is not possible.", NULL, FATAL);
	}
	if (OV_LST == Options::OutputVerbosity && (Options::IsDefaultListingName || Options::ListingFName[0])) {
		Error("Using  --msg=lst[lab]  and other list options is not possible.", NULL, FATAL);
	}
	if (Options::IsDefaultSldName && Options::SourceLevelDebugFName[0]) {
		Error("Using both  --sld  and  --sld=<filename>  is not possible.", NULL, FATAL);
	}
	Options::systemSyntax = Options::syx;		// create copy of initial system settings of syntax

	if (argc == 1 || Options::ShowHelp || Options::ShowHelpWarnings) {
		_COUT logo _ENDL;
		PrintHelp(argc == 1);
		exit(argc == 1);
	}

	if (!Options::HideLogo) {
		_CERR logo _ENDL;
	}

	if (!Options::IsShowFullPath && (Options::IsDefaultSldName || Options::SourceLevelDebugFName[0])) {
		Warning("missing  --fullpath  with  --sld  may produce incomplete file paths.", NULL, W_EARLY);
	}

	if (Options::ShowVersion) {
		if (Options::HideLogo) {	// if "sjasmplus --version --nologo", emit only the raw VERSION
			_CERR VERSION _ENDL;
		}
		// otherwise the full logo was already printed
		// now check if there were some sources to assemble, if NOT, exit with "OK"!
		if (0 == sourceFiles.size()) exit(0);
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
	if (0 == sourceFiles.size()) {
		if (Options::OutputVerbosity <= OV_ERROR) {
			_CERR "No inputfile(s)" _ENDL;
		}
		exit(1);
	}

	// create default output name, if not specified
	ConstructDefaultFilename(Options::DestinationFName, LINEMAX, ".out");
	base_encoding = ConvertEncoding;

	// init some vars
	InitCPU();

	// open lists (if not set to "default" file name, then the OpenFile will handle it)
	OpenList();

	ReserveLabelKeywords();

	do {
		++pass;
		if (pass == LASTPASS) OpenSld();	//open source level debugging file (BEFORE InitPass)
		InitPass();
		if (pass == LASTPASS) OpenDest();

		for (SSource & src : sourceFiles) {
			IsRunning = 1;
			ConvertEncoding = base_encoding;
			OpenFile(src.fname, false, src.stdin_log);
		}

		while (!RepeatStack.empty()) {
			CurSourcePos = RepeatStack.top().sourcePos;	// fake source-file position to mark DUP line
			Error("[DUP/REPT] missing EDUP/ENDR to end repeat-block");
			RepeatStack.pop();
		}

		if (DISP_NONE != PseudoORG) {
			CurAddress = adrdisp;
			PseudoORG = DISP_NONE;
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
		if (dwCount < 0) dwCount = 0;
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
