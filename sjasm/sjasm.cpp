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
	_COUT "  --zxnext                 Enable SpecNext Z80 extensions" _ENDL;
	_COUT "  -i<path> or -I<path> or --inc=<path>" _ENDL;
	_COUT "                           Include path (later defined have higher priority)" _ENDL;
	_COUT "  --lst[=<filename>]       Save listing to <filename> (<source>.lst is default)" _ENDL;
	_COUT "  --lstlab                 Enable label table in listing" _ENDL;
	_COUT "  --sym=<filename>         Save symbols list to <filename>" _ENDL;
	_COUT "  --exp=<filename>         Save exports to <filename> (see EXPORT pseudo-op)" _ENDL;
	//_COUT "  --autoreloc              Switch to autorelocation mode. See more in docs." _ENDL;
	_COUT "  --raw=<filename>         All output to <filename> ignoring OUTPUT pseudo-ops" _ENDL;
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
}

namespace Options {
	char SymbolListFName[LINEMAX] = {0};
	char ListingFName[LINEMAX] = {0};
	char ExportFName[LINEMAX] = {0};
	char DestinationFName[LINEMAX] = {0};
	char RAWFName[LINEMAX] = {0};
	char UnrealLabelListFName[LINEMAX] = {0};

	char ZX_SnapshotFName[LINEMAX] = {0};
	char ZX_TapeFName[LINEMAX] = {0};

	EOutputVerbosity OutputVerbosity = OV_ALL;
	bool IsPseudoOpBOF = 0;
	bool IsAutoReloc = 0;
	bool IsLabelTableInListing = 0;
	bool IsDefaultListingName = false;
	bool IsReversePOP = 0;
	bool IsShowFullPath = 0;
	bool AddLabelListing = false;
	bool HideLogo = 0;
	bool ShowHelp = 0;
	bool NoDestinationFile = true;		// no *.out file by default
	bool FakeInstructions = 1;
	bool IsNextEnabled = false;
	bool SourceStdIn = false;

	// Include directories list is initialized with "." directory
	CStringsList* IncludeDirsList = new CStringsList((char *)".");
	CDefineTable CmdDefineTable;		// is initialized by constructor

} // eof namespace Options

//EMemoryType MemoryType = MT_NONE;
CDevice *Devices = 0;
CDevice *Device = 0;
CDeviceSlot *Slot = 0;
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
int adrdisp = 0,PseudoORG = 0;
char* MemoryRAM=NULL, * MemoryPointer=NULL;
int MemoryCPage = 0, MemoryPagesCount = 0, StartAddress = -1;
aint MemorySize = 0;
int macronummer = 0, lijst = 0, reglenwidth = 0;
aint CurAddress = 0, AddressOfMAP = 0, CurrentSourceLine = 0, CompiledCurrentLine = 0;
aint destlen = 0, size = -1L,PreviousErrorLine = -1L, maxlin = 0, comlin = 0;
char* CurrentDirectory=NULL;

char* ModuleName=NULL, * vorlabp=NULL, * macrolabp=NULL, * LastParsedLabel=NULL;
stack<SRepeatStack> RepeatStack;
CStringsList* lijstp = NULL;
CLabelTable LabelTable;
CLocalLabelTable LocalLabelTable;
CDefineTable DefineTable;
CMacroDefineTable MacroDefineTable;
CMacroTable MacroTable;
CStructureTable StructureTable;
CAddressList* AddressList = 0;
CStringsList* ModuleList = NULL;

#ifdef USE_LUA

lua_State *LUA;
int LuaLine=-1;

#endif //USE_LUA

void InitPass() {
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
	if (LastParsedLabel != NULL) {
		free(LastParsedLabel);
		LastParsedLabel = NULL;
	}
	LastParsedLabel = NULL;
	vorlabp = (char *)malloc(2);
	STRCPY(vorlabp, sizeof("_"), "_");
	macrolabp = NULL;
	listmacro = 0;
	CurAddress = AddressOfMAP = 0;
	CurrentSourceLine = CompiledCurrentLine = 0;
	PseudoORG = 0; adrdisp = 0;
	PreviousAddress = 0; epadres = 0; macronummer = 0; lijst = 0; comlin = 0;
	lijstp = NULL;
	ModuleList = NULL;
	StructureTable.Init();
	MacroTable.Init();
	DefineTable = Options::CmdDefineTable;
	MacroDefineTable.Init();

	// predefined
	DefineTable.Replace("_SJASMPLUS", "1");
	DefineTable.Replace("_VERSION", "\"" VERSION "\"");
	DefineTable.Replace("_RELEASE", "0");
	DefineTable.Replace("_ERRORS", "0");
	DefineTable.Replace("_WARNINGS", "0");
}

void FreeRAM() {
	if (Devices) {
		delete Devices;
	}
	if (AddressList) {
		delete AddressList;
	}
	if (ModuleList) {
		delete ModuleList;
	}
	if (lijstp) {
		delete lijstp;
	}
	free(vorlabp);
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
		char* arg;
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

	public:
		void GetOptions(char**& argv, int& i) {
			while ((arg=argv[i]) && ('-' == arg[0])) {
				++i;					// next CLI argument

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
				if (!strcmp(opt,"h") || !strcmp(opt, "help")) {
					ShowHelp = 1;
				} else if (!strcmp(opt, "lstlab")) {
					AddLabelListing = true;
				} else if (CheckAssignmentOption("msg", NULL, 0)) {
					if (!strcmp("none", val)) {
						OutputVerbosity = OV_NONE;
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
				} else if (!strcmp(opt, "zxnext")) {
					IsNextEnabled = true;
				} else if (!strcmp(opt, "reversepop")) {
					IsReversePOP = 1;
				} else if (!strcmp(opt, "nologo")) {
					HideLogo = 1;
				} else if (!strcmp(opt, "nofakes")) {
					FakeInstructions = 0;
				} else if (!strcmp(opt, "dos866")) {
					ConvertEncoding = ENCDOS;
				} else if (!strcmp(opt, "dirbol")) {
					IsPseudoOpBOF = 1;
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
			}
		}
	};
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
	int i = 1;

	// start counter
	long dwStart;
	dwStart = GetTickCount();

	// get current directory
	GetCurrentDirectory(MAX_PATH, buf);
	CurrentDirectory = buf;

	if (argc > 1) {
		Options::COptionsParser optParser;
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

	if (argc == 1 || Options::ShowHelp) {
		_COUT logo _ENDL;
		PrintHelp();
		exit(1);
	}

	if (!Options::HideLogo) {
		//FIXME STDOUT
		_COUT logo _ENDL;
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
	if (Devices) {
		delete Devices;
	}

#ifdef USE_LUA

	// close Lua
	lua_close(LUA);

#endif //USE_LUA

	return (ErrorCount != 0);
}
//eof sjasm.cpp
