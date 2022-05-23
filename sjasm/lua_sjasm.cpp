/*

  SjASMPlus Z80 Cross Compiler - modified - lua scripting module

  Copyright (c) 2006 Sjoerd Mastijn (original SW)
  Copyright (c) 2022 Peter Ped Helcmanovsky (lua scripting module)

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

// lua_sjasm.cpp

#include "sjdefs.h"

#ifdef USE_LUA

#include "lua.hpp"
#include "LuaBridge/LuaBridge.h"
#include <cassert>

lua_State *LUA = nullptr;		// lgtm[cpp/short-global-name]
TextFilePos LuaStartPos;
// LUA and LuaStartPos are also used by io_err.cpp - keep it in sync in case of some changes

static void lua_impl_fatalError(lua_State *L) {
	Error((char *)lua_tostring(L, -1), NULL, FATAL);
}

// skips file+line_number info (but will adjust global LuaStartPos data for Error output)
static void lua_impl_splitLuaErrorMessage(const char*& LuaError) {
	if (nullptr == LuaError) return;
	const char* colonPos = strchr(LuaError, ':');
	const char* colon2Pos = nullptr != colonPos ? strchr(colonPos+1, ':') : nullptr;
	if (nullptr == colonPos || nullptr == colon2Pos) return;	// error, format not recognized
	int lineNumber = atoi(colonPos + 1);
	//TODO track each chunk under own name, and track their source position
	if (strstr(LuaError, "[string \"script\"]") == LuaError) {
		// inlined script, add to start pos
		LuaStartPos.line += lineNumber;
	} else {
		// standalone script, use line number as is (if provided by lua error)
		if (lineNumber) LuaStartPos.line = lineNumber;
	}
	LuaError = colon2Pos + 1;
	while (White(*LuaError)) ++LuaError;
}

static void lua_impl_showLoadError(const EStatus type) {
	const char *msgp = lua_tostring(LUA, -1);
	lua_impl_splitLuaErrorMessage(msgp);
	Error(msgp, nullptr, type);
	lua_pop(LUA, 1);
}

static aint lua_sj_calc(const char *str) {
	// substitute defines + macro_args in the `str` first (preserve original global variables)
	char* const oldSubstitutedLine = substitutedLine;
	const int oldComlin = comlin;
	comlin = 0;
	char* tmp = nullptr, * tmp2 = nullptr;
	if (sline[0]) {
		tmp = STRDUP(sline);
		if (nullptr == tmp) ErrorOOM();
	}
	if (sline2[0]) {
		tmp2 = STRDUP(sline2);
		if (nullptr == tmp2) ErrorOOM();
	}
	// non-const copy of input string for ReplaceDefine argument
	//TODO: v2.x, rewrite whole parser of sjasmplus to start with const input to avoid such copies
	char* luaInput = STRDUP(str ? str : "");
	char* substitutedStr = ReplaceDefine(luaInput);

	// evaluate the expression
	aint val;
	int parseResult = ParseExpression(substitutedStr, val);
	free(luaInput);

	// restore any global values affected by substitution
	sline[0] = 0;
	if (tmp) {
		STRCPY(sline, LINEMAX2, tmp);
		free(tmp);
	}
	sline2[0] = 0;
	if (tmp2) {
		STRCPY(sline2, LINEMAX2, tmp2);
		free(tmp2);
	}
	substitutedLine = oldSubstitutedLine;
	comlin = oldComlin;

	return parseResult ? val : 0;
}

static void lua_sj_parse_line(const char *str) {
	// preserve current actual line which will be parsed next
	char *oldLine = STRDUP(line);
	char *oldEolComment = eolComment;
	if (nullptr == oldLine) ErrorOOM();

	// inject new line from Lua call and assemble it
	STRCPY(line, LINEMAX, str ? str : "");
	eolComment = nullptr;
	ParseLineSafe();

	// restore the original line
	STRCPY(line, LINEMAX, oldLine);
	eolComment = oldEolComment;
	free(oldLine);
}

static void lua_sj_parse_code(const char *str) {
	char *ml = STRDUP(line);
	if (nullptr == ml) ErrorOOM();

	STRCPY(line, LINEMAX, str ? str : "");
	ParseLineSafe(false);

	STRCPY(line, LINEMAX, ml);
	free(ml);
}

static void lua_sj_error(const char* message, const char* value = nullptr) {
	Error(message, value, ALL);
}

static void lua_sj_warning(const char* message, const char* value = nullptr) {
	Warning(message, value, W_ALL);
}

static const char* lua_sj_get_define(const char* name) {
	// wrapper to resolve member-function call (without std::function wrapping lambda, just to KISS)
	return DefineTable.Get(name);
}

static bool lua_sj_insert_define(const char* name, const char* value) {
	// wrapper to resolve member-function call (without std::function wrapping lambda, just to KISS)
	char* lua_name = const_cast<char*>(name);		//TODO v2.x avoid const_cast like this
	char* id = name ? GetID(lua_name) : nullptr;
	if (nullptr == id) return false;
	return DefineTable.Replace(id, value ? value : "");
}

static int lua_sj_get_label(const char *name) {
	if (nullptr == name) return -1;
	aint val;
	char* n = const_cast<char*>(name);	//TODO try to get rid of const_cast, LuaBridge requires const char* to understand it as lua string
	if (!GetLabelValue(n, val)) val = -1;
	return val;
}

static bool lua_sj_insert_label(const char *name, int address) {
	std::unique_ptr<char[]> fullName(ValidateLabel(name, false, false));
	if (nullptr == fullName.get()) return false;
	return LabelTable.Insert(name, address);
}

static bool lua_sj_set_page(aint n) {
	if (!DeviceID) {
		Warning("sj.set_page: only allowed in real device emulation mode (See DEVICE)");
		return false;
	}
	return dirPageImpl("sj.set_page", n);
}

static bool lua_sj_set_slot(aint n) {
	if (!DeviceID) {
		Warning("sj.set_slot: only allowed in real device emulation mode (See DEVICE)");
		return false;
	}
	n = Device->SlotNumberFromPreciseAddress(n);
	if (!Device->SetSlot(n)) {
		char buf[LINEMAX];
		SPRINTF1(buf, LINEMAX, "sj.set_slot: Slot number must be in range 0..%u", Device->SlotsCount - 1);
		Error(buf, NULL, IF_FIRST);
		return false;
	}
	return true;
}

static bool lua_sj_set_device(const char* id, const aint ramtop = 0) {
	// refresh source position of first DEVICE directive (to make global-device detection work correctly)
	if (1 == ++deviceDirectivesCount) {
		globalDeviceSourcePos = LuaStartPos;	// rough source position, try to find exact line
		// search for deepest stack level number
		lua_Debug ar;
		int ar_level = 0;
		while (lua_getstack(LUA, ar_level, &ar)) ++ar_level;
		// some level found, last level in "ar"
		if (ar_level && lua_getinfo(LUA, "l", &ar)) {
			if (1 <= ar.currentline) globalDeviceSourcePos.line += ar.currentline;
		}
	}
	// check for nullptr id??
	return SetDevice(id, ramtop);
}

static bool lua_zx_trdimage_create(const char* trdname, const char* label = nullptr) {
	// setup label to truncated 8 char array padded with spaces
	char l8[9] = "        ";
	char* l8_ptr = l8;
	while (label && *label && (l8_ptr - l8) < 8) *l8_ptr++ = *label++;
	return TRD_SaveEmpty(trdname, l8);
}

bool lua_zx_trdimage_add_file(const char* trd, const char* file, int start, int length, int autostart = -1, bool replace = false) {
	return nullptr != trd && nullptr != file && TRD_AddFile(trd, file, start, length, autostart, replace, false);
}

// extra lua script inserting interface (sj.something) entry functions
// for functions with optional arguments, like error and warning
// (as LuaBridge2.6 doesn't offer that type of binding as far as I can tell)
// Sidestepping LuaBridge write-protection by "rawset" the end point into it
static const std::string lua_impl_init_bindings_script = R"BINDING_LUA(
rawset(sj,"error",function(m,v)sj.error_i(m or "no message",v)end)
rawset(sj,"warning",function(m,v)sj.warning_i(m or "no message",v)end)
rawset(sj,"insert_define",function(n,v)return sj.insert_define_i(n,v)end)
rawset(sj,"exit",function(e)return sj.exit_i(e or 1)end)
rawset(sj,"set_device",function(i,t)return sj.set_device_i(i or "NONE",t or 0)end)
rawset(zx,"trdimage_create",function(n,l)return zx.trdimage_create_i(n,l)end)
rawset(zx,"trdimage_add_file",function(t,f,s,l,a,r)return zx.trdimage_add_file_i(t,f,s,l,a or -1,r or false)end)
)BINDING_LUA";

static void lua_impl_init() {
	assert(nullptr == LUA);

	// initialise Lua (regular Lua, without sjasmplus bindings/extensions)
	LUA = luaL_newstate();
	lua_atpanic(LUA, (lua_CFunction)lua_impl_fatalError);	//FIXME verify if this works
	luaL_openlibs(LUA);

	// initialise sjasmplus bindings/extensions
	luabridge::getGlobalNamespace(LUA)
		.addFunction("_c", lua_sj_calc)
		.addFunction("_pl", lua_sj_parse_line)
		.addFunction("_pc", lua_sj_parse_code)
		.beginNamespace("sj")
			.addProperty("current_address", &CurAddress, false)	// read-only
			.addProperty("warning_count", &WarningCount, false)	// read-only
			.addProperty("error_count", &ErrorCount, false)	// read-only
			// internal functions which are lua-wrapped to enable optional arguments
			.addFunction("error_i", lua_sj_error)
			.addFunction("warning_i", lua_sj_warning)
			.addFunction("insert_define_i", lua_sj_insert_define)
			.addFunction("exit_i", ExitASM)
			.addFunction("set_device_i", lua_sj_set_device)
			// remaining public functions with all arguments mandatory (boolean args seems to default to false?)
			.addFunction("get_define", lua_sj_get_define)
			.addFunction("get_label", lua_sj_get_label)
			.addFunction("insert_label", lua_sj_insert_label)
			.addFunction("shellexec", LuaShellExec)
			.addFunction("calc", lua_sj_calc)
			.addFunction("parse_line", lua_sj_parse_line)
			.addFunction("parse_code", lua_sj_parse_code)
			.addFunction("add_byte", EmitByte)
			.addFunction("add_word", EmitWord)
			.addFunction("get_byte", MemGetByte)
			.addFunction("get_word", MemGetWord)
			.addFunction("get_device", GetDeviceName)
			.addFunction("set_page", lua_sj_set_page)
			.addFunction("set_slot", lua_sj_set_slot)
			// MMU API will be not added, it is too dynamic, and _pc("MMU ...") works
			.addFunction("file_exists", FileExists)
		.endNamespace()
		.beginNamespace("zx")
			.addFunction("trdimage_create_i", lua_zx_trdimage_create)
			.addFunction("trdimage_add_file_i", lua_zx_trdimage_add_file)
			.addFunction("save_snapshot_sna", SaveSNA_ZX)
		.endNamespace();

		//TODO extend bindings with reading macro arguments

		//TODO when tracking each chunk under own name, this must stay hidden as "chunk 0" or something like that
		if (luaL_loadbuffer(LUA, lua_impl_init_bindings_script.c_str(), lua_impl_init_bindings_script.size(), "script")
			|| lua_pcall(LUA, 0, LUA_MULTRET, 0)) {
			lua_impl_showLoadError(FATAL);								// unreachable? (I hope)
		}
}

void dirENDLUA() {
	Error("[ENDLUA] End of lua script without script");
}

void dirLUA() {
	// lazy init of Lua scripting upon first hit of LUA directive
	if (nullptr == LUA) lua_impl_init();
	assert(LUA);

	constexpr size_t luaBufferSize = 32768;
	char* id, * buff = nullptr, * bp = nullptr;

	int passToExec = LASTPASS;
	if ((id = GetID(lp)) && strlen(id) > 0) {
		if (cmphstr(id, "pass1")) {
			passToExec = 1;
		} else if (cmphstr(id, "pass2")) {
			passToExec = 2;
		} else if (cmphstr(id, "pass3")) {
			passToExec = LASTPASS;
		} else if (cmphstr(id, "allpass")) {
			passToExec = -1;
		} else {
			Error("[LUA] Syntax error", id);
		}
	}

	const EStatus errorType = (1 == passToExec || 2 == passToExec) ? EARLY : PASS3;
	const bool execute = (-1 == passToExec) || (passToExec == pass);
	// remember warning suppression also from block start
	bool showWarning = !suppressedById(W_LUA_MC_PASS);

	if (execute) {
		LuaStartPos = DefinitionPos.line ? DefinitionPos : CurSourcePos;
		buff = new char[luaBufferSize];
		bp = buff;
	}
	ListFile();

	while (1) {
		if (!ReadLine(false)) {
			Error("Unexpected end of lua script");
			break;
		}
		lp = line;
		SkipBlanks(lp);
		const int isEndLua = cmphstr(lp, "endlua");
		const size_t lineLen = isEndLua ? (lp - 6 - line) : strlen(line);
		if (execute) {
			if (luaBufferSize < (bp - buff) + lineLen + 4) {
				ErrorInt("[LUA] Maximum byte-size of Lua script is", luaBufferSize-4, FATAL);
			}
			STRNCPY(bp, (luaBufferSize - (bp - buff)), line, lineLen);
			bp += lineLen;
			*bp++ = '\n';
		}
		if (isEndLua) {		// eat also any trailing eol-type of comment
			++CompiledCurrentLine;
			lp = ReplaceDefine(lp);		// skip any empty substitutions and comments
			substitutedLine = line;		// override substituted listing for ENDLUA
			// take into account also warning suppression used at end of block
			showWarning = showWarning && !suppressedById(W_LUA_MC_PASS);
			break;
		}
		ListFile(true);
	}

	if (execute) {
		*bp = 0;
		DidEmitByte();			// reset the flag before running lua script
		if (luaL_loadbuffer(LUA, buff, bp-buff, "script") || lua_pcall(LUA, 0, LUA_MULTRET, 0)) {
			//TODO track each chunk under own name, and track their source position
			//if (luaL_loadbuffer(LUA, buff, bp-buff, std::to_string(++lua_script_counter).c_str()) || lua_pcall(LUA, 0, LUA_MULTRET, 0)) {
			lua_impl_showLoadError(errorType);
		}
		LuaStartPos = TextFilePos();
		delete[] buff;
		if (DidEmitByte() && (-1 != passToExec) && showWarning) {
			const EWStatus warningType = (1 == passToExec || 2 == passToExec) ? W_EARLY : W_PASS3;
			WarningById(W_LUA_MC_PASS, nullptr, warningType);
		}
	}

	++CompiledCurrentLine;
	substitutedLine = line;		// override substituted list line for ENDLUA
}

void dirINCLUDELUA() {
	// lazy init of Lua scripting upon first hit of INCLUDELUA directive
	if (nullptr == LUA) lua_impl_init();
	assert(LUA);

	if (1 != pass) {
		SkipToEol(lp);		// skip till EOL (colon), to avoid parsing file name
		return;
	}
	std::unique_ptr<char[]> fnaam(GetFileName(lp));
	EDelimiterType dt = GetDelimiterOfLastFileName();
	char* fullpath = GetPath(fnaam.get(), NULL, DT_ANGLE == dt);
	if (!fullpath[0]) {
		Error("[INCLUDELUA] File doesn't exist", fnaam.get(), EARLY);
	} else {
		fileNameFull = ArchiveFilename(fullpath);	// get const pointer into archive
		LuaStartPos.newFile(Options::IsShowFullPath ? fileNameFull : FilenameBasePos(fileNameFull));
		LuaStartPos.line = 1;
		if (luaL_dofile(LUA, fullpath)) {
			lua_impl_showLoadError(EARLY);
		}
		LuaStartPos = TextFilePos();
	}
	free(fullpath);
}

#endif //USE_LUA

////////////////////////////////////////////////////////////////////////////////////////////
// close LUA engine and release everything related
void lua_impl_close() {
	#ifdef USE_LUA
		// if Lua was used and initialised, release everything
		if (LUA) lua_close(LUA);
	#endif //USE_LUA

	// do nothing when Lua is compile-time disabled
}

//eof lua_sjasm.cpp
