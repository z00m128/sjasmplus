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

static lua_State *LUA = nullptr;

static const char* lua_err_prefix = "[LUA] ";

// extra lua script inserting interface (sj.something) entry functions
// for functions with optional arguments, like error and warning
// (as LuaBridge2.6 doesn't offer that type of binding as far as I can tell)
// Sidestepping LuaBridge write-protection by "rawset" the end point into it
static const char* binding_script_name = "lua_sjasm.cpp";
static constexpr int binding_script_line = __LINE__;
static const std::string lua_impl_init_bindings_script = R"BINDING_LUA(
rawset(sj,"error",function(m,v)sj.error_i(m or "no message",v)end)
rawset(sj,"warning",function(m,v)sj.warning_i(m or "no message",v)end)
rawset(sj,"insert_define",function(n,v)return sj.insert_define_i(n,v)end)
rawset(sj,"exit",function(e)return sj.exit_i(e or 1)end)
rawset(sj,"set_device",function(i,t)return sj.set_device_i(i or "NONE",t or 0)end)
rawset(zx,"trdimage_create",function(n,l)return zx.trdimage_create_i(n,l)end)
rawset(zx,"trdimage_add_file",function(t,f,s,l,a,r)return zx.trdimage_add_file_i(t,f,s,l,a or -1,r or false)end)
)BINDING_LUA";

static void lua_impl_fatalError(lua_State *L) {
	Error((char *)lua_tostring(L, -1), NULL, FATAL);
}

static std::vector<TextFilePos> scripts_origin;

static char internal_script_name[LINEMAX];

static const char* lua_impl_get_script_name(const TextFilePos & srcPos) {
	sprintf(internal_script_name, "script %u", uint32_t(scripts_origin.size()));
	scripts_origin.push_back(srcPos);
	return internal_script_name;
}

static bool isInlinedScript(TextFilePos & errorPos, const char* script_name) {
	// return false when the script is external (real file name)
	if (script_name != strstr(script_name, "[string \"script ")) return false;
	// inlined script, find it's origin and add line number to that
	int scriptNumber = atoi(script_name + 16);
	if (scriptNumber < 0 || int(scripts_origin.size()) <= scriptNumber) return false;
	errorPos = scripts_origin.at(scriptNumber);
	return true;
}

// adds current source position in lua script + full stack depth onto sourcePosStack
// = makes calls to Error/Warning API to display more precise error lines in lua scripts
static int addLuaSourcePositions() {
	// find all *known* inlined/standalone script names and line numbers on the lua stack
	assert(LUA);
	lua_Debug ar;
	source_positions_t luaPosTemp;
	luaPosTemp.reserve(16);
	int level = 1;			// level 0 is "C" space, ignore that always
	while (lua_getstack(LUA, level, &ar)) {			// as long lua stack level are available
		if (!lua_getinfo(LUA, "Sl", &ar)) break;	// not enough info about current level

		//assert(level || !strcmp("[C]", ar.short_src));	//TODO: verify if ever upgrading to newer lua
		//if (!strcmp("[C]", ar.short_src)) { ++level; continue; }

		TextFilePos levelErrorPos;
		if (isInlinedScript(levelErrorPos, ar.short_src)) {
			levelErrorPos.line += ar.currentline;
		} else {
			levelErrorPos.newFile(ArchiveFilename(ar.short_src));
			levelErrorPos.line = ar.currentline;
		}
		luaPosTemp.push_back(levelErrorPos);
		++level;
	}

	// add all lua positions in reversed order to sourcePosStack (hide binding script if anything else is available)
	bool hide_binding = (2 <= luaPosTemp.size()) && !strcmp(binding_script_name, luaPosTemp[0].filename);
	source_positions_t::iterator stop = hide_binding ? luaPosTemp.begin() + 1 : luaPosTemp.begin();
	source_positions_t::iterator i = luaPosTemp.end();
	while (i-- != stop) sourcePosStack.push_back(*i);

	return luaPosTemp.end() - stop;
}

static void removeLuaSourcePositions(int to_remove) {
	while (to_remove--) sourcePosStack.pop_back();	// restore sourcePosStack to original state
}

// skips file+line_number info (but will adjust global LuaStartPos data for Error output)
static TextFilePos lua_impl_splitLuaErrorMessage(const char*& LuaError) {
	TextFilePos luaErrorPos("?");
	if (!sourcePosStack.empty()) luaErrorPos = sourcePosStack.back();
	if (nullptr == LuaError) return luaErrorPos;

	const char* colonPos = strchr(LuaError, ':');
	const char* colon2Pos = nullptr != colonPos ? strchr(colonPos+1, ':') : nullptr;
	if (nullptr == colonPos || nullptr == colon2Pos) return luaErrorPos;	// error, format not recognized

	int lineNumber = atoi(colonPos + 1);
	if (isInlinedScript(luaErrorPos, LuaError)) {
		luaErrorPos.line += lineNumber;
	} else {
		// standalone script, use file name and line number as is (if provided by lua error)
		STRNCPY(internal_script_name, LINEMAX, LuaError, colonPos - LuaError);
		luaErrorPos.newFile(ArchiveFilename(internal_script_name));
		luaErrorPos.line = lineNumber;
	}

	// advance beyond filename and line in LuaError pointer
	LuaError = colon2Pos + 1;
	while (White(*LuaError)) ++LuaError;
	return luaErrorPos;
}

static void lua_impl_showLoadError(const EStatus type) {
	const char *msgp = lua_tostring(LUA, -1);
	sourcePosStack.push_back(lua_impl_splitLuaErrorMessage(msgp));
	Error(msgp, nullptr, type);
	sourcePosStack.pop_back();
	lua_pop(LUA, 1);
}

static aint lua_sj_calc(const char *str) {
	int positionsAdded = addLuaSourcePositions();	// add known script positions to sourcePosStack vector

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

	removeLuaSourcePositions(positionsAdded);
	return parseResult ? val : 0;
}

static void parse_line(const char* str, bool parseLabels) {
	int positionsAdded = addLuaSourcePositions();	// add known script positions to sourcePosStack vector

	// preserve current actual line which will be parsed next
	char *oldLine = STRDUP(line);
	if (nullptr == oldLine) ErrorOOM();
	char *oldEolComment = eolComment;

	// inject new line from Lua call and assemble it
	STRCPY(line, LINEMAX, str ? str : "");
	eolComment = nullptr;
	ParseLineSafe(parseLabels);

	// restore the original line
	STRCPY(line, LINEMAX, oldLine);
	eolComment = oldEolComment;
	free(oldLine);

	removeLuaSourcePositions(positionsAdded);
}

static void lua_sj_parse_line(const char *str) {
	parse_line(str, true);
}

static void lua_sj_parse_code(const char *str) {
	parse_line(str, false);
}

static void lua_sj_error(const char* message, const char* value = nullptr) {
	int positionsAdded = addLuaSourcePositions();	// add known script positions to sourcePosStack vector
	Error(message, value, ALL);
	removeLuaSourcePositions(positionsAdded);
}

static void lua_sj_warning(const char* message, const char* value = nullptr) {
	int positionsAdded = addLuaSourcePositions();			// add known script positions to sourcePosStack vector
	Warning(message, value, W_ALL);
	removeLuaSourcePositions(positionsAdded);
}

static const char* lua_sj_get_define(const char* name, bool macro_args = false) {
	const char* macro_res = (macro_args && macrolabp) ? MacroDefineTable.getverv(name) : nullptr;
	return macro_res ? macro_res : DefineTable.Get(name);
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
	int positionsAdded = addLuaSourcePositions();	// add known script positions to sourcePosStack vector
	char* n = const_cast<char*>(name);	//TODO try to get rid of const_cast, LuaBridge requires const char* to understand it as lua string
	if (!GetLabelValue(n, val)) val = -1;
	removeLuaSourcePositions(positionsAdded);
	return val;
}

static bool lua_sj_insert_label(const char *name, int address) {
	int positionsAdded = addLuaSourcePositions();	// add known script positions to sourcePosStack vector
	std::unique_ptr<char[]> fullName(ValidateLabel(name, false, false));
	removeLuaSourcePositions(positionsAdded);
	if (nullptr == fullName.get()) return false;
	return LabelTable.Insert(name, address);
}

static void lua_sj_shellexec(const char *command) {
	int positionsAdded = addLuaSourcePositions();	// add known script positions to sourcePosStack vector
	LuaShellExec(command);
	removeLuaSourcePositions(positionsAdded);
}

static bool lua_sj_set_page(aint n) {
	int positionsAdded = addLuaSourcePositions();	// add known script positions to sourcePosStack vector
	if (!DeviceID) Warning("sj.set_page: only allowed in real device emulation mode (See DEVICE)");
	bool result = DeviceID && dirPageImpl("sj.set_page", n);
	removeLuaSourcePositions(positionsAdded);
	return result;
}

static bool lua_sj_set_slot(aint n) {
	int positionsAdded = addLuaSourcePositions();	// add known script positions to sourcePosStack vector
	bool result = false;
	if (!DeviceID) {
		Warning("sj.set_slot: only allowed in real device emulation mode (See DEVICE)");
	} else {
		n = Device->SlotNumberFromPreciseAddress(n);
		result = Device->SetSlot(n);
		if (!result) {
			char buf[LINEMAX];
			SPRINTF1(buf, LINEMAX, "sj.set_slot: Slot number must be in range 0..%u", Device->SlotsCount - 1);
			Error(buf);
		}
	}
	removeLuaSourcePositions(positionsAdded);
	return result;
}

static bool lua_sj_set_device(const char* id, const aint ramtop = 0) {
	int positionsAdded = addLuaSourcePositions();	// add known script positions to sourcePosStack vector
	// refresh source position of first DEVICE directive (to make global-device detection work correctly)
	if (1 == ++deviceDirectivesCount) {
		assert(!sourcePosStack.empty());
		globalDeviceSourcePos = sourcePosStack.back();
	}
	// check for nullptr id??
	bool result = SetDevice(id, ramtop);
	removeLuaSourcePositions(positionsAdded);
	return result;
}

static void lua_sj_add_byte(int byte) {
	int positionsAdded = addLuaSourcePositions();	// add known script positions to sourcePosStack vector
	EmitByte(byte);
	removeLuaSourcePositions(positionsAdded);
}

static void lua_sj_add_word(int word) {
	int positionsAdded = addLuaSourcePositions();	// add known script positions to sourcePosStack vector
	EmitWord(word);
	removeLuaSourcePositions(positionsAdded);
}

static unsigned char lua_sj_get_byte(unsigned int address) {
	int positionsAdded = addLuaSourcePositions();	// add known script positions to sourcePosStack vector
	auto result = MemGetByte(address);
	removeLuaSourcePositions(positionsAdded);
	return result;
}

static unsigned int lua_sj_get_word(unsigned int address) {
	int positionsAdded = addLuaSourcePositions();	// add known script positions to sourcePosStack vector
	auto result = MemGetWord(address);
	removeLuaSourcePositions(positionsAdded);
	return result;
}

static const char* lua_sj_get_module(void) {
	return ModuleName;
}

static bool lua_zx_trdimage_create(const char* trdname, const char* label = nullptr) {
	// setup label to truncated 8 char array padded with spaces
	char l8[9] = "        ";
	char* l8_ptr = l8;
	while (label && *label && (l8_ptr - l8) < 8) *l8_ptr++ = *label++;
	int positionsAdded = addLuaSourcePositions();	// add known script positions to sourcePosStack vector
	bool result = TRD_SaveEmpty(trdname, l8);
	removeLuaSourcePositions(positionsAdded);
	return result;
}

bool lua_zx_trdimage_add_file(const char* trd, const char* file, int start, int length, int autostart = -1, bool replace = false) {
	int positionsAdded = addLuaSourcePositions();	// add known script positions to sourcePosStack vector
	bool result = nullptr != trd && nullptr != file && TRD_AddFile(trd, file, start, length, autostart, replace, false);
	removeLuaSourcePositions(positionsAdded);
	return result;
}

static bool lua_zx_save_snapshot_sna(const char* fname, word start) {
	int positionsAdded = addLuaSourcePositions();	// add known script positions to sourcePosStack vector
	bool result = SaveSNA_ZX(fname, start);
	removeLuaSourcePositions(positionsAdded);
	return result;
}

static void lua_impl_init() {
	assert(nullptr == LUA);

	scripts_origin.reserve(64);

	// initialise Lua (regular Lua, without sjasmplus bindings/extensions)
	LUA = luaL_newstate();
	lua_atpanic(LUA, (lua_CFunction)lua_impl_fatalError);

	// for manual testing of lua_atpanic handler
// 	{ lua_error(LUA); }
// 	{ lua_pushstring(LUA, "testing at panic handler"); lua_error(LUA); }

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
			.addFunction("shellexec", lua_sj_shellexec)
			.addFunction("calc", lua_sj_calc)
			.addFunction("parse_line", lua_sj_parse_line)
			.addFunction("parse_code", lua_sj_parse_code)
			.addFunction("add_byte", lua_sj_add_byte)
			.addFunction("add_word", lua_sj_add_word)
			.addFunction("get_byte", lua_sj_get_byte)
			.addFunction("get_word", lua_sj_get_word)
			.addFunction("get_device", GetDeviceName)		// no error/warning, can be called directly
			.addFunction("get_module_namespace", lua_sj_get_module)
			.addFunction("set_page", lua_sj_set_page)
			.addFunction("set_slot", lua_sj_set_slot)
			// MMU API will be not added, it is too dynamic, and _pc("MMU ...") works
			.addFunction("file_exists", FileExists)
		.endNamespace()
		.beginNamespace("zx")
			.addFunction("trdimage_create_i", lua_zx_trdimage_create)
			.addFunction("trdimage_add_file_i", lua_zx_trdimage_add_file)
			.addFunction("save_snapshot_sna", lua_zx_save_snapshot_sna)
		.endNamespace();

		TextFilePos binding_script_pos(binding_script_name, binding_script_line);
		if (luaL_loadbuffer(LUA, lua_impl_init_bindings_script.c_str(), lua_impl_init_bindings_script.size(), lua_impl_get_script_name(binding_script_pos))
			|| lua_pcall(LUA, 0, LUA_MULTRET, 0)) {
			lua_impl_showLoadError(FATAL);				// unreachable (I hope) // manual testing: damage binding script
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

	assert(!sourcePosStack.empty());
	TextFilePos luaStartPos = sourcePosStack.back();	// position of LUA directive (not ENDLUA)
	if (execute) {
		buff = new char[luaBufferSize];
		bp = buff;
	}
	ListFile();

	while (1) {
		if (!ReadLine(false)) {
			Error("[LUA] Unexpected end of lua script");
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
			memcpy(bp, line, lineLen);
			bp += lineLen;
			*bp++ = '\n';
		}
		if (isEndLua) {		// eat also any trailing eol-type of comment
			skipEmitMessagePos = sourcePosStack.back();
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
		extraErrorWarningPrefix = lua_err_prefix;
		*bp = 0;
		DidEmitByte();			// reset the flag before running lua script
		if (luaL_loadbuffer(LUA, buff, bp-buff, lua_impl_get_script_name(luaStartPos)) || lua_pcall(LUA, 0, LUA_MULTRET, 0)) {
			lua_impl_showLoadError(errorType);
		}
		extraErrorWarningPrefix = nullptr;
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
		extraErrorWarningPrefix = lua_err_prefix;
		fileNameFull = ArchiveFilename(fullpath);	// get const pointer into archive
		if (luaL_dofile(LUA, fileNameFull)) {
			lua_impl_showLoadError(EARLY);
		}
		extraErrorWarningPrefix = nullptr;
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
