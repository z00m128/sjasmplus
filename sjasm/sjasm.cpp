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
	_COUT "  --lst=<filename>         Save listing to <filename>" _ENDL;
	_COUT "  --lstlab                 Enable label table in listing" _ENDL;
	_COUT "  --sym=<filename>         Save symbols list to <filename>" _ENDL;
	_COUT "  --exp=<filename>         Save exports to <filename> (see EXPORT pseudo-op)" _ENDL;
	//_COUT "  --autoreloc              Switch to autorelocation mode. See more in docs." _ENDL;
	_COUT "  --raw=<filename>         Save all output to <filename> ignoring OUTPUT pseudo-ops" _ENDL;
	_COUT " Note: use OUTPUT, LUA/ENDLUA and other pseudo-ops to control output" _ENDL;
	_COUT " Logging:" _ENDL;
	_COUT "  --nologo                 Do not show startup message" _ENDL;
	_COUT "  --msg=[all|war|err]      Stderr messages verbosity (\"all\" is default)" _ENDL;
	_COUT "  --fullpath               Show full path to error file" _ENDL;
	_COUT " Other:" _ENDL;
	_COUT "  -D<NAME>[=<value>]       Define <NAME> as <value>" _ENDL;
	_COUT "  --reversepop             Enable reverse POP order (as in base SjASM version)" _ENDL;
	_COUT "  --dirbol                 Enable processing directives from the beginning of line" _ENDL;
	_COUT "  --nofakes                Disable fake instructions" _ENDL;
	_COUT "  --dos866                 Encode from Windows codepage to DOS 866 (Cyrillic)" _ENDL;
}

namespace Options {
	char SymbolListFName[LINEMAX] = {0};
	char ListingFName[LINEMAX] = {0};
	char ExportFName[LINEMAX] = {0};
	char DestionationFName[LINEMAX] = {0};
	char RAWFName[LINEMAX] = {0};
	char UnrealLabelListFName[LINEMAX] = {0};

	char ZX_SnapshotFName[LINEMAX] = {0};
	char ZX_TapeFName[LINEMAX] = {0};

	EOutputVerbosity OutputVerbosity = OV_ALL;
	bool IsPseudoOpBOF = 0;
	bool IsAutoReloc = 0;
	bool IsLabelTableInListing = 0;
	bool IsReversePOP = 0;
	bool IsShowFullPath = 0;
	bool AddLabelListing = 0;
	bool HideLogo = 0;
	bool ShowHelp = 0;
	bool NoDestinationFile = true;		// no *.out file by default
	bool FakeInstructions = 1;
	bool IsNextEnabled = false;

	// Include directories list is initialized with "." directory
	CStringsList* IncludeDirsList = new CStringsList((char *)".", NULL);
	CDefineTable CmdDefineTable;		// is initialized by constructor

} // eof namespace Options

//EMemoryType MemoryType = MT_NONE;
CDevice *Devices = 0;
CDevice *Device = 0;
CDeviceSlot *Slot = 0;
CDevicePage *Page = 0;
char* DeviceID = 0;

// extend
char filename[LINEMAX], * lp, line[LINEMAX], temp[LINEMAX], * tp, pline[LINEMAX2], ErrorLine[LINEMAX2], * bp;
char mline[LINEMAX2], sline[LINEMAX2], sline2[LINEMAX2];

char SourceFNames[128][MAX_PATH];
int CurrentSourceFName = 0;
int SourceFNamesCount = 0;

bool displayerror,displayinprocces = 0;
int ConvertEncoding = ENCWIN;

int pass = 0, IsLabelNotFound = 0, ErrorCount = 0, WarningCount = 0, IncludeLevel = -1;
int IsRunning = 0, IsListingFileOpened = 1, donotlist = 0,listdata  = 0,listmacro  = 0;
int adrdisp = 0,PseudoORG = 0;
char* MemoryRAM=NULL, * MemoryPointer=NULL;
int MemoryCPage = 0, MemoryPagesCount = 0, StartAddress = -1;
aint MemorySize = 0;
int macronummer = 0, lijst = 0, reglenwidth = 0, synerr = 1;
aint CurAddress = 0, AddressOfMAP = 0, CurrentGlobalLine = 0, CurrentLocalLine = 0, CompiledCurrentLine = 0;
aint destlen = 0, size = (aint)-1,PreviousErrorLine = (aint)-1, maxlin = 0, comlin = 0;
char* CurrentDirectory=NULL;

void (*GetCPUInstruction)(void);

char* ModuleName=NULL, * vorlabp=NULL, * macrolabp=NULL, * LastParsedLabel=NULL;
stack<SRepeatStack> RepeatStack;
CStringsList* lijstp = 0;
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

void InitPass(int p) {
	reglenwidth = 1;
	if (maxlin > 9) {
		reglenwidth = 2;
	}
	if (maxlin > 99) {
		reglenwidth = 3;
	}
	if (maxlin > 999) {
		reglenwidth = 4;
	}
	if (maxlin > 9999) {
		reglenwidth = 5;
	}
	if (maxlin > 99999) {
		reglenwidth = 6;
	}
	if (maxlin > 999999) {
		reglenwidth = 7;
	}
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
	pass = p;
	CurAddress = AddressOfMAP = 0;
	IsRunning = 1;
	CurrentGlobalLine = CurrentLocalLine = CompiledCurrentLine = 0;
	PseudoORG = 0; adrdisp = 0;
	PreviousAddress = 0; epadres = 0; macronummer = 0; lijst = 0; comlin = 0;
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
#ifdef UNDER_CE
		void GetOptions(_TCHAR* argv[], int& i) {
#else
		void GetOptions(char**& argv, int& i) {
#endif
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
					AddLabelListing = 1;
				} else if (CheckAssignmentOption("msg", NULL, 0)) {
					if (!strcmp("err", val)) {
						OutputVerbosity = OV_ERROR;
					} else if (!strcmp("war", val)) {
						OutputVerbosity = OV_WARNING;
					} else if (!strcmp("all", val)) {
						OutputVerbosity = OV_ALL;
					} else {
						_CERR "Unexpected parameter in " _CMDL arg _ENDL;
					}
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
				} else {
					_CERR "Unrecognized option: " _CMDL opt _ENDL;
				}
			}
		}
	};
}

#ifdef USE_LUA

void LuaFatalError(lua_State *L) {
	Error((char *)lua_tostring(L, -1), 0, FATAL);
}

#endif //USE_LUA

#ifdef UNDER_CE
int main(int argc, _TCHAR* argv[]) {
#else
#ifdef WIN32
int main(int argc, char* argv[]) {
#else
int main(int argc, char **argv) {
#endif
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
			if (argv[i]) {
#ifdef UNDER_CE
				STRCPY(SourceFNames[SourceFNamesCount++], LINEMAX, _tochar(argv[i++]));
#else
				STRCPY(SourceFNames[SourceFNamesCount++], LINEMAX, argv[i++]);
#endif
			}
		}
	}

	if (argc == 1 || Options::ShowHelp) {
		_COUT logo _ENDL;
		PrintHelp();
#ifdef UNDER_CE
		return false;
#else
		exit(1);
#endif
	}

	if (!Options::HideLogo) {
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

	if (!SourceFNames[0][0]) {
		_CERR "No inputfile(s)" _ENDL;
#ifdef UNDER_CE
		return 0;
#else
		exit(1);
#endif
	}

	if (!Options::DestionationFName[0]) {
		STRCPY(Options::DestionationFName, LINEMAX, SourceFNames[0]);
		if (!(p = strchr(Options::DestionationFName, '.'))) {
			p = Options::DestionationFName;
		} else {
			*p = 0;
		}
		STRCAT(p, LINEMAX-(p-Options::DestionationFName), ".out");
	}

	// init some vars
	InitCPU();

	// if memory type != none
	base_encoding = ConvertEncoding;

	// init first pass
	InitPass(1);

	// open lists
	OpenList();

	// open source filenames
	for (i = 0; i < SourceFNamesCount; i++) {
		OpenFile(SourceFNames[i]);
	}

	if (Options::OutputVerbosity <= OV_ALL) {
		_CERR "Pass 1 complete (" _CMDL ErrorCount _CMDL " errors)" _ENDL;
	}

	ConvertEncoding = base_encoding;

	do {
		pass++;

		InitPass(pass);

		if (pass == LASTPASS) {
			OpenDest();
		}
		for (i = 0; i < SourceFNamesCount; i++) {
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
	} while (pass < 3);//MAXPASSES);

	pass = 9999; /* added for detect end of compiling */
	if (Options::AddLabelListing) {
		LabelTable.Dump();
	}

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

#ifndef UNDER_CE
	cout << flush;
#endif

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
