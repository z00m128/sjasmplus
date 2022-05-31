/*

  SjASMPlus Z80 Cross Compiler - modified - error/warning module

  Copyright (c) 2006 Sjoerd Mastijn (original SW)
  Copyright (c) 2020 Peter Ped Helcmanovsky (error/warning module)

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

// io_err.cpp

#include "sjdefs.h"
#include <vector>
#include <unordered_map>
#include <algorithm>

#ifdef USE_LUA

	// io_err.cpp is allowed to work with Lua stuff (and LUA global)
	// no other file (except lua_sjasm.cpp) should need to include/reference these!

	#include "lua.hpp"

	extern lua_State *LUA;
	extern TextFilePos LuaStartPos;

#endif //USE_LUA

static bool IsSkipErrors = false;
static char ErrorLine[LINEMAX2], ErrorLine2[LINEMAX2];
static aint PreviousErrorLine = -1L;

static const char* nullptr_message_txt = "<nullptr>";

static void initErrorLine() {		// adds filename + line of definition if possible
	*ErrorLine = 0;
	*ErrorLine2 = 0;
	// when OpenFile is reporting error, the filename is still nullptr, but pass==1 already
	if (pass < 1 || LASTPASS < pass || sourcePosStack.empty()) return;
	TextFilePos errorPos = sourcePosStack.back();

#ifdef USE_LUA
	lua_Debug ar;					// must be in this scope, as some memory is reused by errorPos
	bool extra_lua_err = false;
	if (LuaStartPos.line) {
		assert(LUA);
		errorPos = LuaStartPos;

		// find either top level of lua stack, or standalone file, otherwise it's impossible
		// to precisely report location of error (ASM can have 2+ LUA blocks defining functions)
		int level = 1;			// level 0 is "C" space, ignore that always
		while (true) {
			if (!lua_getstack(LUA, level, &ar)) break;	// no more lua stack levels
			if (!lua_getinfo(LUA, "Sl", &ar)) break;	// no more info about current level
			//TODO track each chunk under own name, and track their source position
			if (strcmp("[string \"script\"]", ar.short_src)) {
				// standalone definition in external file found, pinpoint it precisely
				errorPos.filename = ar.short_src;
				errorPos.line = ar.currentline;
				break;	// no more lua-stack traversing, stop here
			}
			// if source was inlined script, update the possible source line
			errorPos.line = LuaStartPos.line + ar.currentline;
			// and keep traversing stack until top level is found (to make the line meaningful)
			++level;
		}
		extra_lua_err = strcmp(errorPos.filename, sourcePosStack.back().filename);
		if (extra_lua_err) sourcePosStack.push_back(errorPos);
	}
#endif //USE_LUA

	SPRINTF2(ErrorLine, LINEMAX2, "%s(%d): ", errorPos.filename, errorPos.line);
	// if the error filename:line is not identical with current source line, add ErrorLine2 about emit
	if (2 <= sourcePosStack.size() && size_t(IncludeLevel + 1) < sourcePosStack.size()) {
		SPRINTF2(ErrorLine2, LINEMAX2, "%s(%d): ^ emitted from here\n", sourcePosStack.end()[-2].filename, sourcePosStack.end()[-2].line);
	}
#ifdef USE_LUA
	if (extra_lua_err) sourcePosStack.pop_back();
#endif //USE_LUA
}

static void trimAndAddEol(char* lineBuffer) {
	if (!lineBuffer[0]) return;		// ignore empty line buffer
	char* lastChar = lineBuffer + strlen(lineBuffer) - 1;
	while (lineBuffer < lastChar && (' ' == *lastChar || '\t' == *lastChar)) --lastChar;	// trim ending whitespace
	if ('\n' != *lastChar) lastChar[1] = '\n', lastChar[2] = 0;	// add EOL character if not present
}

static void outputErrorLine(const EOutputVerbosity errorLevel) {
	auto lstFile = GetListingFile();
	if (!lstFile && errorLevel < Options::OutputVerbosity) return;	// no output required
	// trim end of error/warning line and add EOL char if needed
	trimAndAddEol(ErrorLine);
	trimAndAddEol(ErrorLine2);
	// always print the message into listing file (the OutputVerbosity does not apply to listing)
	if (lstFile) {
		fputs(ErrorLine, lstFile);
		if (*ErrorLine2) fputs(ErrorLine2, lstFile);
	}
	// print the error into stderr if OutputVerbosity allows this type of message
	if (Options::OutputVerbosity <= errorLevel) {
		if (OV_ERROR == errorLevel) _CERR Options::tcols->error _END;
		if (OV_WARNING == errorLevel) _CERR Options::tcols->warning _END;
		_CERR ErrorLine _END;
		if (*ErrorLine2) _CERR ErrorLine2 _END;
		_CERR Options::tcols->end _END;
	}
}

void Error(const char* message, const char* badValueMessage, EStatus type) {
	// check if it is correct pass by the type of error
	if (type == EARLY && LASTPASS <= pass) return;
	if ((type == SUPPRESS || type == IF_FIRST || type == PASS3) && pass < LASTPASS) return;
	if (PASS03 == type && 0 < pass && pass < LASTPASS) return;
	// check if this one should be skipped due to type constraints and current-error-state
	if (FATAL != type && PreviousErrorLine == CompiledCurrentLine) {
		// non-fatal error, on the same line as previous, maybe skip?
		if (IsSkipErrors || IF_FIRST == type) return;
	}
	// update current-error-state (reset "skip" on new parsed-line, set "skip" by SUPPRESS type)
	IsSkipErrors = (IsSkipErrors && (PreviousErrorLine == CompiledCurrentLine)) || (SUPPRESS == type);
	PreviousErrorLine = CompiledCurrentLine;
	++ErrorCount;							// number of non-skipped (!) errors

	DefineTable.Replace("__ERRORS__", ErrorCount);

	initErrorLine();
	STRCAT(ErrorLine, LINEMAX2-1, "error: ");
#ifdef USE_LUA
	if (LuaStartPos.line) STRCAT(ErrorLine, LINEMAX2-1, "[LUA] ");
#endif
	STRCAT(ErrorLine, LINEMAX2-1, message ? message : nullptr_message_txt);
	if (badValueMessage) {
		STRCAT(ErrorLine, LINEMAX2-1, ": "); STRCAT(ErrorLine, LINEMAX2-1, badValueMessage);
	}
	outputErrorLine(OV_ERROR);
	// terminate whole assembler in case of fatal error
	if (type == FATAL) {
		ExitASM(1);
	}
}

void ErrorInt(const char* message, aint badValue, EStatus type) {
	char numBuf[24];
	SPRINTF1(numBuf, 24, "%d", badValue);
	Error(message, numBuf, type);
}

void ErrorOOM() {		// out of memory
	Error("Not enough memory!", nullptr, FATAL);
}

static void WarningImpl(const char* id, const char* message, const char* badValueMessage, EWStatus type) {
	// turn the warning into error if "Warnings as errors" is switched on
	if (Options::syx.WarningsAsErrors) switch (type) {
		case W_EARLY:	Error(message, badValueMessage, EARLY); return;
		case W_PASS3:	Error(message, badValueMessage, PASS3); return;
		case W_PASS03:	Error(message, badValueMessage, PASS03); return;
		case W_ALL:		Error(message, badValueMessage, ALL); return;
	}

	++WarningCount;
	DefineTable.Replace("__WARNINGS__", WarningCount);

	initErrorLine();
	if (id) {
		STRCAT(ErrorLine, LINEMAX2-1, "warning[");
		STRCAT(ErrorLine, LINEMAX2-1, id);
		STRCAT(ErrorLine, LINEMAX2-1, "]: ");
	} else {
		STRCAT(ErrorLine, LINEMAX2-1, "warning: ");
	}
#ifdef USE_LUA
	if (LuaStartPos.line) STRCAT(ErrorLine, LINEMAX2-1, "[LUA] ");
#endif
	STRCAT(ErrorLine, LINEMAX2-1, message ? message : nullptr_message_txt);
	if (badValueMessage) {
		STRCAT(ErrorLine, LINEMAX2-1, ": "); STRCAT(ErrorLine, LINEMAX2-1, badValueMessage);
	}
	outputErrorLine(OV_WARNING);
}

struct WarningEntry {
	bool enabled;
	const char* txt;
	const char* help;
};

typedef std::unordered_map<const char*, WarningEntry> messages_map;

const char* W_NO_RAMTOP = "noramtop";
const char* W_DEV_RAMTOP = "devramtop";
const char* W_DISPLACED_ORG = "displacedorg";
const char* W_ORG_PAGE = "orgpage";
const char* W_FWD_REF = "fwdref";
const char* W_LUA_MC_PASS = "luamc";
const char* W_NEX_STACK = "nexstack";
const char* W_SNA_48 = "sna48";
const char* W_SNA_128 = "sna128";
const char* W_TRD_EXT_INVALID = "trdext";
const char* W_TRD_EXT_3 = "trdext3";
const char* W_TRD_EXT_B = "trdextb";
const char* W_TRD_DUPLICATE = "trddup";
const char* W_RELOCATABLE_ALIGN = "relalign";
const char* W_READ_LOW_MEM = "rdlow";
const char* W_REL_DIVERTS = "reldiverts";
const char* W_REL_UNSTABLE = "relunstable";
const char* W_DISP_MEM_PAGE = "dispmempage";
const char* W_BP_FILE = "bpfile";
const char* W_OUT0 = "out0";
const char* W_BACKSLASH = "backslash";
const char* W_OPKEYWORD = "opkeyword";
const char* W_BE_HOST = "behost";
const char* W_FAKE = "fake";
const char* W_ENABLE_ALL = "all";

static messages_map w_texts = {
	{ W_NO_RAMTOP,
		{ true,
			"current device doesn't init memory in any way (RAMTOP is ignored)",
			"Warn when device ignores <ramtop> argument."
		}
	},
	{ W_DEV_RAMTOP,
		{ true,
			"[DEVICE] this device was already opened with different RAMTOP value",
			"Warn when different <ramtop> is used for same device."
		}
	},
	{ W_DISPLACED_ORG,
		{ true,
			"ORG-address set inside displaced block, the physical address is not modified, only displacement address",
			"Warn about ORG-address used inside DISP block."
		}
	},
	{ W_ORG_PAGE,
		{ true,
			"[ORG] page argument affects current slot while address is outside",
			"Warn about ORG address vs page argument mismatch."
		}
	},
	{ W_FWD_REF,
		{ true,
			"forward reference of symbol",
			"Warn about using undefined symbol in risky way."
		}
	},
	{ W_LUA_MC_PASS,
		{ true,
			"When lua script emits machine code bytes, use \"ALLPASS\" modifier",
			"Warn when lua script is not ALLPASS, but emits bytes."
		}
	},
	{ W_NEX_STACK,
		{ true,
			"[SAVENEX] non-zero data are in stackAddress area, may get overwritten by NEXLOAD",
			"Warn when NEX stack points into non-empty memory."
		}
	},
	{ W_SNA_48,
		{ true,
			"[SAVESNA] RAM <0x4000-0x4001> will be overwritten due to 48k snapshot imperfect format.",
			"Warn when 48k SNA does use screen for stack."
		}
	},
	{ W_SNA_128,
		{ true,
			"only 128kb will be written to snapshot",
			"Warn when saving snapshot from 256+ki device."
		}
	},
	{ W_TRD_EXT_INVALID,
		{ true,
			"invalid file extension, TRDOS official extensions are B, C, D and #.",
			"Warn when TRD file uses unofficial/invalid extension."
		}
	},
	{ W_TRD_EXT_3,
		{ true,
			"3-letter extension of TRDOS file (unofficial extension)",
			"Warn when TRD file does use 3-letter extension."
		}
	},
	{ W_TRD_EXT_B,
		{ true,
			"the \"B\" extension is always single letter",
			"Warn when long extension starts with letter B (can not)."
		}
	},
	{ W_TRD_DUPLICATE,
		{ true,
			"TRD file already exists, creating one more!",
			"Warn when second file with same name is added to disk."
		}
	},
	{ W_RELOCATABLE_ALIGN,
		{ true,
			"[ALIGN] inside relocation block: may become misaligned when relocated",
			"Warn when align is used inside relocatable code."
		}
	},
	{ W_READ_LOW_MEM,
		{ false,
			"Reading memory at low address",
			"Warn when reading memory from addresses 0..255."
		}
	},
	{ W_REL_DIVERTS,
		{ true,
			"Expression can't be relocated by simple \"+offset\" mechanics, value diverts differently.",
			"Warn when relocated expression differs non-trivially."
		}
	},
	{ W_REL_UNSTABLE,
		{ true,
			"Relocation makes one of the expressions unstable, resulting machine code is not relocatable",
			"Warn when expression result can't be relocated."
		}
	},
	{ W_DISP_MEM_PAGE,
		{ true,
			"DISP memory page differs from current mapping",
			"Warn when DISP page differs from current mapping."
		}
	},
	{ W_BP_FILE,
		{ true,
			"breakpoints file was not specified",
			"Warn when SETBREAKPOINT is used without breakpoint file."
		}
	},
	{ W_OUT0,
		{ true,
			"'out (c),0' is unstable, on CMOS based chips it does `out (c),255`",
			"Warn when instruction `out (c),0` is used."
		}
	},
	{ W_BACKSLASH,
		{ true,
			"File name contains \\, use / instead (\\ fails on most of the supported platforms)",
			"Warn when file name contains backslash."
		}
	},
	{ W_OPKEYWORD,
		{ true,
			"Label collides with one of the operator keywords, try capitalizing it or other name",
			"Warn when symbol name collides with operator keyword."
		}
	},
	{ W_BE_HOST,
		{ true,
			"Big-endian host detected: support is experimental, please report any issues",
			"Warn when big-endian host runs sjasmplus (experimental)."
		}
	},
	{ W_FAKE,
		{ true,	// fake-warnings are enabled/disabled through --syntax, this value here is always true
				// the main reason is that fake warning enabled can be reset/push/pop by OPT
			"Fake instruction",
			"Warn when fake instruction is used in the source."
		}
	},
	{ W_ENABLE_ALL,
		{ false,
			"",		// not emitted by code, just command-line option
			"Enable/disable all id-warnings"
		}
	},
};

static messages_map::iterator findWarningByIdText(const char* id) {
	// like w_texts.find(id) but compares id content (string), not pointer
	return std::find_if(w_texts.begin(), w_texts.end(), [id](const auto& v){ return !strcmp(id, v.first); } );
}

static bool & warning_state(messages_map::value_type & v) {
	// W_FAKE (ID "fake") stores enabled/disabled state in Options::syx to handle reset/push/pop of the state
	if (W_FAKE == v.first) return Options::syx.FakeWarning;
	// other warnings have global state stored in w_texts map
	return v.second.enabled;
}

bool suppressedById(const char* id) {
	assert(id);
	if (nullptr == eolComment) return false;
	const size_t idLength = strlen(id);
	assert(0 < idLength);
	const char* commentToCheck = eolComment;
	while (const char* idPos = strstr(commentToCheck, id)) {
		if (!strcmp(id, W_FAKE)) return true;				// "fake" only is enough to suppress those
		commentToCheck = idPos + idLength;
		if ('-' == commentToCheck[0] && 'o' == commentToCheck[1] && 'k' == commentToCheck[2]) {
			return true;
		}
	}
	return false;
}

static bool isInactiveTypeInCurrentPass(EWStatus type) {
	switch (type) {
		case W_EARLY:	// "early" is inactive during pass3+
			return LASTPASS <= pass;
		case W_PASS3:	// "pass3" is inactive during 0..2 pass
			return pass < LASTPASS;
		case W_PASS03:	// "pass03" is inactive during 1..2 pass
			return 0 < pass && pass < LASTPASS;
		default:		// never inactive for other types (W_ALL)
			return false;
	}
}

void Warning(const char* message, const char* badValueMessage, EWStatus type) {
	if (isInactiveTypeInCurrentPass(type)) return;
	WarningImpl(nullptr, message, badValueMessage, type);
}

void WarningById(const char* id, const char* badValueMessage, EWStatus type) {
	if (isInactiveTypeInCurrentPass(type)) return;

	// id-warnings could be suppressed by "id-ok" anywhere in eol comment
	if (suppressedById(id)) return;

	const messages_map::const_iterator idMessage = w_texts.find(id);	// searching by id POINTER!
	assert(idMessage != w_texts.end());

	if (!idMessage->second.enabled) return;
	WarningImpl(id, idMessage->second.txt, badValueMessage, type);
}

void WarningById(const char* id, int badValue, EWStatus type) {
	char buf[32];
	SPRINTF1(buf, 32, "%d", badValue);
	WarningById(id, buf, type);
}

void CliWoption(const char* option) {
	if (!option[0]) {
		// from command line 0 == pass, from source by OPT the pass is above zero
		Error("no argument after -W", (0 == pass) ? nullptr : bp, PASS03);
		return;
	}
	// check for specific id, with possible "no-" prefix ("-Wabs" vs "-Wno-abs")
	const bool enable = strncmp("no-", option, 3);
	const char* id = enable ? option : option + 3;
	// handle ID "all"
	if (!strcmp(id, W_ENABLE_ALL)) {
		for (auto & warning_entry : w_texts) warning_state(warning_entry) = enable;
		return;
	}
	auto warning_it = findWarningByIdText(id);
	if (w_texts.end() == warning_it) {
		Warning("unknown warning id in -W option", id, W_PASS03);
		return;
	}
	warning_state(*warning_it) = enable;
}

static const char* spaceFiller = "               ";
static const char* txt_on	= "on";
static const char* txt_off	= "off";
static const char* txt_none	= "      ";
static constexpr const int STATE_TXT_BUFFER_SIZE = 64;

static void initWarningStateTxt(char* buffer, const char* id) {
	if (W_ENABLE_ALL == id) {
		STRCPY(buffer, STATE_TXT_BUFFER_SIZE, txt_none);
		return;
	}
	const bool state = warning_state(*w_texts.find(id));
	buffer[0] = '[';
	STRCPY(buffer + 1, STATE_TXT_BUFFER_SIZE-1, state ? Options::tcols->display : Options::tcols->warning);
	STRCAT(buffer, STATE_TXT_BUFFER_SIZE, state ? txt_on : txt_off);
	STRCAT(buffer, STATE_TXT_BUFFER_SIZE, Options::tcols->end);
	STRCAT(buffer, STATE_TXT_BUFFER_SIZE, "] ");
	if (state) STRCAT(buffer, STATE_TXT_BUFFER_SIZE, " ");
}

void PrintHelpWarnings() {
	char state_txt[STATE_TXT_BUFFER_SIZE+1];
	_COUT "The following options control compiler warning messages:" _ENDL;
	std::vector<const char*> ids;
	ids.reserve(w_texts.size());
	for (const auto& w_text : w_texts) ids.push_back(w_text.first);
	std::sort(ids.begin(), ids.end(), [](const char* a, const char* b) -> bool { return (strcmp(a,b) < 0); } );
	for (const auto& id : ids) {
		assert(strlen(id) < strlen(spaceFiller));
		initWarningStateTxt(state_txt, id);
		_COUT " -W" _CMDL Options::tcols->bold _CMDL Options::tcols->warning _CMDL id _CMDL Options::tcols->end _CMDL spaceFiller+strlen(id) _CMDL state_txt _CMDL w_texts[id].help _ENDL;
	}
	_COUT "Use -W" _CMDL Options::tcols->bold _CMDL Options::tcols->warning _CMDL "no-" _CMDL Options::tcols->end;
	_COUT " prefix to disable specific warning, example: " _CMDL Options::tcols->display _CMDL "-Wno-out0" _CMDL Options::tcols->end _ENDL;
	_COUT "Use -ok suffix in comment to suppress it per line, example: ";
	_COUT Options::tcols->display _CMDL "out (c),0 ; out0-ok" _CMDL Options::tcols->end _ENDL;
}

//eof io_err.cpp
