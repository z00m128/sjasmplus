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

// io_err.h

/**
 * Error types:
 * ALL = will try to display in every pass
 * FATAL = terminates assembler
 * EARLY = displays only during early phase (pass 1+2)
 * PASS3 = normal error message level for code-gen pass (pass 3)
 * IF_FIRST = normal code-gen error, but will display only if it is first error on the current line
 * SUPPRESS = will suppress further errors (PASS3+IF_FIRST+ALL) for current line, except FATAL
 * PASS03 = like PASS3, but does display also during pass 0 (sjasmplus init, parsing CLI options)
 * */
enum EStatus { ALL, FATAL, EARLY, PASS3, IF_FIRST, SUPPRESS, PASS03 };
enum EWStatus { W_ALL, W_EARLY, W_PASS3, W_PASS03 };

extern const char* W_NO_RAMTOP;
extern const char* W_DEV_RAMTOP;
extern const char* W_DISPLACED_ORG;
extern const char* W_ORG_PAGE;
extern const char* W_FWD_REF;
extern const char* W_LUA_MC_PASS;
extern const char* W_NEX_STACK;
extern const char* W_SNA_48;
extern const char* W_SNA_128;
extern const char* W_TRD_EXT_INVALID;
extern const char* W_TRD_EXT_3;
extern const char* W_TRD_EXT_B;
extern const char* W_TRD_DUPLICATE;
extern const char* W_RELOCATABLE_ALIGN;
extern const char* W_READ_LOW_MEM;
extern const char* W_REL_DIVERTS;
extern const char* W_REL_UNSTABLE;
extern const char* W_DISP_MEM_PAGE;
extern const char* W_BP_FILE;
extern const char* W_OUT0;
extern const char* W_BACKSLASH;
extern const char* W_OPKEYWORD;
extern const char* W_BE_HOST;
extern const char* W_FAKE;
extern const char* W_ENABLE_ALL;

extern TextFilePos skipEmitMessagePos;
extern const char* extraErrorWarningPrefix;

void Error(const char* message, const char* badValueMessage = nullptr, EStatus type = PASS3);
void ErrorInt(const char* message, aint badValue, EStatus type = PASS3);
void ErrorOOM();		// out of memory

bool suppressedById(const char* id);	// checks for "id-ok" in EOL comment
void Warning(const char* message, const char* badValueMessage = nullptr, EWStatus type = W_PASS3);
void WarningById(const char* id, const char* badValueMessage = nullptr, EWStatus type = W_PASS3);
void WarningById(const char* id, int badValue, EWStatus type = W_PASS3);
void CliWoption(const char* option);
void PrintHelpWarnings();

//eof io_err.h
