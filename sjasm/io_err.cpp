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

static bool IsSkipErrors = false;
static char ErrorLine[LINEMAX2], ErrorLine2[LINEMAX2];
static aint PreviousErrorLine = -1L;

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

static void outputErrorLine(const EOutputVerbosity errorLevel) {
	// always print the message into listing file (the OutputVerbosity does not apply to listing)
	if (GetListingFile()) {
		fputs(ErrorLine, GetListingFile());
		if (*ErrorLine2) fputs(ErrorLine2, GetListingFile());
	}
	// print the error into stderr if OutputVerbosity allows this type of message
	if (Options::OutputVerbosity <= errorLevel) {
		_CERR ErrorLine _END;
		if (*ErrorLine2) _CERR ErrorLine2 _END;
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
	if (!strchr(ErrorLine, '\n')) STRCAT(ErrorLine, LINEMAX2-1, "\n");	// append EOL if needed
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

void Warning(const char* message, const char* badValueMessage, EWStatus type)
{
	// check if it is correct pass by the type of error
	if (type == W_EARLY && LASTPASS <= pass) return;
	if (type == W_PASS3 && pass < LASTPASS) return;

	// turn the warning into error if "Warnings as errors" is switched on
	if (Options::syx.WarningsAsErrors) switch (type) {
		case W_EARLY:	Error(message, badValueMessage, EARLY); return;
		case W_PASS3:	Error(message, badValueMessage, PASS3); return;
		case W_ALL:		Error(message, badValueMessage, ALL); return;
	}

	++WarningCount;

	DefineTable.Replace("__WARNINGS__", WarningCount);

	initErrorLine();
	STRCAT(ErrorLine, LINEMAX2-1, "warning: ");
#ifdef USE_LUA
	if (LuaStartPos.line) STRCAT(ErrorLine, LINEMAX2-1, "[LUA] ");
#endif
	STRCAT(ErrorLine, LINEMAX2-1, message);
	if (badValueMessage) {
		STRCAT(ErrorLine, LINEMAX2-1, ": "); STRCAT(ErrorLine, LINEMAX2-1, badValueMessage);
	}
	if (!strchr(ErrorLine, '\n')) STRCAT(ErrorLine, LINEMAX2-1, "\n");	// append EOL if needed
	outputErrorLine(OV_WARNING);
}

//eof io_err.cpp
