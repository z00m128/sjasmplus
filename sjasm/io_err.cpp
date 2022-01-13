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
#include <cassert>

static bool IsSkipErrors = false;
static char ErrorLine[LINEMAX2], ErrorLine2[LINEMAX2];
static aint PreviousErrorLine = -1L;

static const char AnsiErrorBeg[] = "\033[31m";
static const char AnsiWarningBeg[] = "\033[33m";
static const char AnsiEnd[] = "\033[m";

static void initErrorLine() {		// adds filename + line of definition if possible
	*ErrorLine = 0;
	*ErrorLine2 = 0;
	// when OpenFile is reporting error, the filename is still nullptr, but pass==1 already
	if (pass < 1 || LASTPASS < pass || nullptr == CurSourcePos.filename) return;
	// during assembling, show also file+line info
	TextFilePos errorPos = DefinitionPos.line ? DefinitionPos : CurSourcePos;
	bool isEmittedMsgEnabled = true;
#ifdef USE_LUA
	lua_Debug ar;					// must be in this scope, as some memory is reused by errorPos
	if (LuaStartPos.line) {
		errorPos = LuaStartPos;

		// find either top level of lua stack, or standalone file, otherwise it's impossible
		// to precisely report location of error (ASM can have 2+ LUA blocks defining functions)
		int level = 1;			// level 0 is "C" space, ignore that always
		// suppress "is emitted here" when directly inlined in current code
		isEmittedMsgEnabled = (0 < listmacro);
		while (true) {
			if (!lua_getstack(LUA, level, &ar)) break;	// no more lua stack levels
			if (!lua_getinfo(LUA, "Sl", &ar)) break;	// no more info about current level
			if (strcmp("[string \"script\"]", ar.short_src)) {
				// standalone definition in external file found, pinpoint it precisely
				errorPos.filename = ar.short_src;
				errorPos.line = ar.currentline;
				isEmittedMsgEnabled = true;				// and add "emitted here" in any case
				break;	// no more lua-stack traversing, stop here
			}
			// if source was inlined script, update the possible source line
			errorPos.line = LuaStartPos.line + ar.currentline;
			// and keep traversing stack until top level is found (to make the line meaningful)
			++level;
		}
	}
#endif //USE_LUA
	SPRINTF2(ErrorLine, LINEMAX2, "%s(%d): ", errorPos.filename, errorPos.line);
	// if the error filename:line is not identical with current source line, add ErrorLine2 about emit
	if (isEmittedMsgEnabled &&
		(strcmp(errorPos.filename, CurSourcePos.filename) || errorPos.line != CurSourcePos.line)) {
		SPRINTF2(ErrorLine2, LINEMAX2, "%s(%d): ^ emitted from here\n", CurSourcePos.filename, CurSourcePos.line);
	}
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
		if (OV_ERROR == errorLevel && Options::HasAnsiColours) _CERR AnsiErrorBeg _END;
		if (OV_WARNING == errorLevel && Options::HasAnsiColours) _CERR AnsiWarningBeg _END;
		_CERR ErrorLine _END;
		if (*ErrorLine2) _CERR ErrorLine2 _END;
		if (Options::HasAnsiColours) _CERR AnsiEnd _END;
	}
}

void Error(const char* message, const char* badValueMessage, EStatus type) {
	// check if it is correct pass by the type of error
	if (type == EARLY && LASTPASS <= pass) return;
	if ((type == SUPPRESS || type == IF_FIRST || type == PASS3) && pass < LASTPASS) return;
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
	STRCAT(ErrorLine, LINEMAX2-1, message);
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
	STRCAT(ErrorLine, LINEMAX2-1, message);
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

const char* W_ABS_LABEL = "abs";
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

static messages_map w_texts = {
	{ W_ABS_LABEL,
		{ true,
			"the `abs` is now absolute value operator, if you are using it as label, please rename",
			"Warn about parsing error of new abs operator (v1.18.0)."
		}
	},
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
		{ true,
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
			"Fake instruction",
			"Warn when fake instruction is used in the source."
		}
	},
};

static messages_map::iterator findWarningByIdText(const char* id) {
	return std::find_if(w_texts.begin(), w_texts.end(), [id](const auto& v){ return !strcmp(id, v.first); } );
}

//TODO deprecated, add single-warning around mid 2021, remove ~1y later (replaced by warning-id system)
// checks for "ok" (or also "fake") in EOL comment
// "ok" must follow the comment start, "fake" can be anywhere inside
bool warningNotSuppressed(bool alsoFake) {
	if (nullptr == eolComment) return true;
	char* comment = eolComment;
	while (';' == *comment || '/' == *comment) ++comment;
	while (' ' == *comment || '\t' == *comment) ++comment;
	// check if "ok" is first word
	if ('o' == comment[0] && 'k' == comment[1] && !isalnum((byte)comment[2])) return false;
	return alsoFake ? (nullptr == strstr(eolComment, "fake")) : true;
}

bool suppressedById(const char* id) {
	assert(id);
	if (nullptr == eolComment) return false;
	const size_t idLength = strlen(id);
	assert(0 < idLength);
	const char* commentToCheck = eolComment;
	while (const char* idPos = strstr(commentToCheck, id)) {
		commentToCheck = idPos + idLength;
		if ('-' == commentToCheck[0] && 'o' == commentToCheck[1] && 'k' == commentToCheck[2]) {
			return true;
		}
	}
	return false;
}

static bool isInactiveTypeInCurrentPass(EWStatus type) {
	if (type == W_EARLY && LASTPASS <= pass) return true;	// "early" is inactive during pass3+
	if (type == W_PASS3 && pass < LASTPASS) return true;	// "pass3" is inactive during 0..2 pass
	return false;
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
		// from command line pass == 0, from source by OPT the pass is above zero
		Error("no argument after -W", (0 == pass) ? nullptr : bp, (0 == pass) ? EARLY : PASS3);
		return;
	}
	// check for specific id, with possible "no-" prefix ("-Wabs" vs "-Wno-abs")
	const bool enable = strncmp("no-", option, 3);
	const char* id = enable ? option : option + 3;
	// handle ID "fake" separately, changing the enable/disable value directly in Options::syx
	if (!strcmp(id, W_FAKE)) {
		Options::syx.FakeWarning = enable;
		return;			// keep the w_texts["fake"].enabled == true all the time
	}
	auto warning_it = findWarningByIdText(id);
	if (w_texts.end() != warning_it) warning_it->second.enabled = enable;
	else Warning("unknown warning id in -W option", id, (0 == pass) ? W_EARLY : W_PASS3);
}

static const char* spaceFiller = "                       ";

void PrintHelpWarnings() {
	_COUT "The following options control compiler warning messages:" _ENDL;
	std::vector<const char*> ids;
	ids.reserve(w_texts.size());
	for (const auto& w_text : w_texts) ids.push_back(w_text.first);
	std::sort(ids.begin(), ids.end(), [](const char* a, const char* b) -> bool { return (strcmp(a,b) < 0); } );
	for (const auto& id : ids) {
		assert(strlen(id) < strlen(spaceFiller));
		_COUT "  -W" _CMDL id _CMDL spaceFiller+strlen(id) _CMDL w_texts[id].help _ENDL;
	}
	_COUT " Use -Wno- prefix to disable specific warning, example: -Wno-abs" _ENDL;
	_COUT " Use -ok suffix in comment to suppress it per line, example: jr abs ; abs-ok" _ENDL;
}

//eof io_err.cpp
