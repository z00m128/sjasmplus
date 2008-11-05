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
#include "lua_sjasm.h"

namespace Options {
	char SymbolListFName[LINEMAX];
	char ListingFName[LINEMAX];
	char ExportFName[LINEMAX];
	char DestionationFName[LINEMAX];
	char RAWFName[LINEMAX];
	char UnrealLabelListFName[LINEMAX];

	char ZX_SnapshotFName[LINEMAX];
	char ZX_TapeFName[LINEMAX];

	bool IsPseudoOpBOF = 0;
	bool IsAutoReloc = 0;
	bool IsLabelTableInListing = 0;
	bool IsReversePOP = 0;
	bool IsShowFullPath = 0;
	bool AddLabelListing = 0;
	bool HideLogo = 0;
	bool NoDestinationFile = 0;
	bool FakeInstructions = 1;

	CStringsList* IncludeDirsList = 0;


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
int ConvertEncoding = ENCWIN; /* added */

int pass = 0, IsLabelNotFound = 0, ErrorCount = 0, WarningCount = 0, IncludeLevel = -1;
int IsRunning = 0, IsListingFileOpened = 1, donotlist = 0,listdata  = 0,listmacro  = 0;
int adrdisp = 0,PseudoORG = 0; /* added for spectrum ram */
char* MemoryRAM=NULL, * MemoryPointer=NULL; /* added for spectrum ram */
int MemoryCPage = 0, MemoryPagesCount = 0, StartAddress = -1;
aint MemorySize = 0;
int macronummer = 0, lijst = 0, reglenwidth = 0, synerr = 1;
aint CurAddress = 0, AddressOfMAP = 0, CurrentGlobalLine = 0, CurrentLocalLine = 0, CompiledCurrentLine = 0;
aint destlen = 0, size = (aint)-1,PreviousErrorLine = (aint)-1, maxlin = 0, comlin = 0;
char* CurrentDirectory=NULL;

void (*GetCPUInstruction)(void);

char* ModuleName=NULL, * vorlabp=NULL, * macrolabp=NULL, * LastParsedLabel=NULL;
stack<SRepeatStack> RepeatStack; /* added */
CStringsList* lijstp = 0;
CLabelTable LabelTable;
CLocalLabelTable LocalLabelTable;
CDefineTable DefineTable;
CMacroDefineTable MacroDefineTable;
CMacroTable MacroTable;
CStructureTable StructureTable;
CAddressList* AddressList = 0; /* from SjASM 0.39g */
CStringsList* ModuleList = NULL;

lua_State *LUA;
int LuaLine=-1;

/* modified */
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
	PseudoORG = 0; adrdisp = 0; /* added */
	PreviousAddress = 0; epadres = 0; macronummer = 0; lijst = 0; comlin = 0;
	ModuleList = NULL;
	StructureTable.Init();
	MacroTable.Init();
	DefineTable.Init();
	MacroDefineTable.Init();

	// predefined
	DefineTable.Replace("_SJASMPLUS", "1");
	DefineTable.Replace("_VERSION", "\"1.07\"");
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

/* added */
void ExitASM(int p) {
	FreeRAM();
	if (pass == LASTPASS) {
		Close();
	}
	exit(p);
}

namespace Options {
#ifdef UNDER_CE
	void GetOptions(_TCHAR* argv[], int& i) {
#else
	void GetOptions(char**& argv, int& i) {
#endif
		char* p, *ps;
		char c[LINEMAX];
#ifdef UNDER_CE
		while (argv[i] && *argv[i] == '-') {
			if (*(argv[i] + 1) == '-') {
				p = argv[i++] + 2;
			} else {
				p = argv[i++] + 1;
			}
#else
		while (argv[i] && *argv[i] == '-') {
			if (*(argv[i] + 1) == '-') {
				p = argv[i++] + 2;
			} else {
				p = argv[i++] + 1;
			}
#endif
			memset(c, 0, LINEMAX); //todo
			ps = STRSTR(p, "=");
			if (ps != NULL) {
				STRNCPY(c, LINEMAX, p, (int)(ps - p));
			} else {
				STRCPY(c, LINEMAX, p);
			}

			if (!strcmp(c, "lstlab")) {
				AddLabelListing = 1;
			} else if (!strcmp(c, "help")) {
				// nothing
			} else if (!strcmp(c, "sym")) {
				if ((ps)&&(ps+1)) {
					STRCPY(SymbolListFName, LINEMAX, ps+1);
				} else {
					_COUT "No parameters found in " _CMDL argv[i-1] _ENDL;
				}
			} else if (!strcmp(c, "lst")) {
				if ((ps)&&(ps+1)) {
					STRCPY(ListingFName, LINEMAX, ps+1);
				} else {
					_COUT "No parameters found in " _CMDL argv[i-1] _ENDL;
				}
			} else if (!strcmp(c, "exp")) {
				if ((ps)&&(ps+1)) {
					STRCPY(ExportFName, LINEMAX, ps+1);
				} else {
					_COUT "No parameters found in " _CMDL argv[i-1] _ENDL;
				}
			/*} else if (!strcmp(c, "zxlab")) {
				if (ps+1) {
					STRCPY(UnrealLabelListFName, LINEMAX, ps+1);
				} else {
					_COUT "No parameters found in " _CMDL argv[i] _ENDL;
				}*/
			} else if (!strcmp(c, "raw")) {
				if ((ps)&&(ps+1)) {
					STRCPY(RAWFName, LINEMAX, ps+1);
				} else {
					_COUT "No parameters found in " _CMDL argv[i-1] _ENDL;
				}
			} else if (!strcmp(c, "fullpath")) {
				IsShowFullPath = 1;
			} else if (!strcmp(c, "reversepop")) {
				IsReversePOP = 1;
			} else if (!strcmp(c, "nologo")) {
				HideLogo = 1;
			} else if (!strcmp(c, "nofakes")) {
				FakeInstructions = 0;
			} else if (!strcmp(c, "dos866")) {
				ConvertEncoding = ENCDOS;
			} else if (!strcmp(c, "dirbol")) {
				IsPseudoOpBOF = 1;
			} else if (!strcmp(c, "inc")) {
				if ((ps)&&(ps+1)) {
					IncludeDirsList = new CStringsList(ps+1, IncludeDirsList);
				} else {
					_COUT "No parameters found in " _CMDL argv[i-1] _ENDL;
				}
			} else if (*p == 'i' || *p == 'I') {
				IncludeDirsList = new CStringsList(p+1, IncludeDirsList);
			} else {
				_COUT "Unrecognized option: " _CMDL c _ENDL;
			}
		}
	}
}

void LuaFatalError(lua_State *L) {
	Error((char *)lua_tostring(L, -1), 0, FATAL);
}


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
	int base_encoding; /* added */
	char* p;
	const char* logo = "SjASMPlus Z80 Cross-Assembler v1.07 Stable (build 04-04-2008)";
	int i = 1;

	if (argc == 1) {
		_COUT logo _ENDL;
		_COUT "based on code of SjASM by Sjoerd Mastijn / http://www.xl2s.tk /" _ENDL;
		_COUT "Copyright 2004-2008 by Aprisobal / http://sjasmplus.sf.net / my@aprisobal.by /" _ENDL;
		_COUT "\nUsage:\nsjasmplus [options] sourcefile(s)" _ENDL;
		_COUT "\nOption flags as follows:" _ENDL;
		_COUT "  --help                   Help information (you see it)" _ENDL;
		_COUT "  -i<path> or -I<path> or --inc=<path>" _ENDL;
		_COUT "                           Include path" _ENDL;
		_COUT "  --lst=<filename>         Save listing to <filename>" _ENDL;
		_COUT "  --lstlab                 Enable label table in listing" _ENDL;
		_COUT "  --sym=<filename>         Save symbols list to <filename>" _ENDL;
		_COUT "  --exp=<filename>         Save exports to <filename> (see EXPORT pseudo-op)" _ENDL;
		//_COUT "  --autoreloc              Switch to autorelocation mode. See more in docs." _ENDL;
		//_COUT " By output format (you can use it all in some time):" _ENDL;
		_COUT "  --raw=<filename>         Save all output to <filename> ignoring OUTPUT pseudo-ops" _ENDL;
		//_COUT "  --nooutput               Do not generate *.out file" _ENDL;
		_COUT "  Note: use OUTPUT, LUA/ENDLUA and other pseudo-ops to control output" _ENDL;
		_COUT " Logging:" _ENDL;
		_COUT "  --nologo                 Do not show startup message" _ENDL;
		_COUT "  --msg=error              Show only error messages" _ENDL;
		_COUT "  --msg=all                Show all messages (by default)" _ENDL;
		_COUT "  --fullpath               Show full path to error file" _ENDL;
		_COUT " Other:" _ENDL;
		_COUT "  --reversepop             Enable reverse POP order (as in base SjASM version)" _ENDL;
		_COUT "  --dirbol                 Enable processing directives from the beginning of line" _ENDL;
		_COUT "  --nofakes                Disable fake instructions" _ENDL;
		_COUT "  --dos866                 Encode from Windows codepage to DOS 866 (Cyrillic)" _ENDL;
#ifdef UNDER_CE
		return false;
#else
		exit(1);
#endif
	}

	// init LUA
	LUA = lua_open();
	lua_atpanic(LUA, (lua_CFunction)LuaFatalError);
	luaL_openlibs(LUA);
	luaopen_pack(LUA);

	tolua_sjasm_open(LUA);

	// init vars
	Options::DestionationFName[0] = 0;
	Options::ListingFName[0] = 0;
	Options::UnrealLabelListFName[0] = 0;
	Options::SymbolListFName[0] = 0;
	Options::ExportFName[0] = 0;
	Options::RAWFName[0] = 0;
	Options::NoDestinationFile = true; // not *.out files by default

	// start counter
	long dwStart;
	dwStart = GetTickCount();

	// get current directory
	GetCurrentDirectory(MAX_PATH, buf);
	CurrentDirectory = buf;

	// get arguments
	Options::IncludeDirsList = new CStringsList((char *)".", Options::IncludeDirsList);
	while (argv[i]) {
		Options::GetOptions(argv, i);
		if (argv[i]) {
#ifdef UNDER_CE
			STRCPY(SourceFNames[SourceFNamesCount++], LINEMAX, _tochar(argv[i++]));
#else
			STRCPY(SourceFNames[SourceFNamesCount++], LINEMAX, argv[i++]);
#endif
		}
	}

	if (!Options::HideLogo) {
		_COUT logo _ENDL;
	}

	if (!SourceFNames[0][0]) {
		_COUT "No inputfile(s)" _ENDL;
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

	_COUT "Pass 1 complete (" _CMDL ErrorCount _CMDL " errors)" _ENDL;

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

		if (pass != LASTPASS) {
			_COUT "Pass " _CMDL pass _CMDL " complete (" _CMDL ErrorCount _CMDL " errors)" _ENDL;
		} else {
			_COUT "Pass 3 complete" _ENDL;
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

	_COUT "Errors: " _CMDL ErrorCount _CMDL ", warnings: " _CMDL WarningCount _CMDL ", compiled: " _CMDL CompiledCurrentLine _CMDL " lines" _END;

	double dwCount;
	dwCount = GetTickCount() - dwStart;
	if (dwCount < 0) {
		dwCount = 0;
	}
	printf(", work time: %.3f seconds", dwCount / 1000);

	_COUT "" _ENDL;

#ifndef UNDER_CE
	cout << flush;
#endif

	// free RAM
	if (Devices) {
		delete Devices;
	}
	// close Lua
	lua_close(LUA);

	return (ErrorCount != 0);
}
//eof sjasm.cpp
