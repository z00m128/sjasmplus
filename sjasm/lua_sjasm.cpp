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

// extern "C" { //FIXME remove or update
// #include "lua_lpack.h"
// }

lua_State *LUA = nullptr;		// lgtm[cpp/short-global-name]
TextFilePos LuaStartPos;
// LUA and LuaStartPos are also used by io_err.cpp - keep it in sync in case of some changes

static void LuaFatalError(lua_State *L) {
	Error((char *)lua_tostring(L, -1), NULL, FATAL);
}

// skips file+line_number info (but will adjust global LuaStartPos data for Error output)
static void SplitLuaErrorMessage(const char*& LuaError)
{
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

static void _lua_showLoadError(const EStatus type) {
	const char *msgp = lua_tostring(LUA, -1);
	SplitLuaErrorMessage(msgp);
	Error(msgp, nullptr, type);
	lua_pop(LUA, 1);
}

static bool LuaSetPage(aint n) {
	return dirPageImpl("sj.set_page", n);
}

static bool LuaSetSlot(aint n) {
	if (!DeviceID) {
		Warning("sj.set_slot: only allowed in real device emulation mode (See DEVICE)");
		return false;
	}
	if (!Device->SetSlot(n)) {
		char buf[LINEMAX];
		SPRINTF1(buf, LINEMAX, "sj.set_slot: Slot number must be in range 0..%u", Device->SlotsCount - 1);
		Error(buf, NULL, IF_FIRST);
		return false;
	}
	return true;
}

static void initLUA() {
	assert(nullptr == LUA);

	// initialise Lua (regular Lua, without sjasmplus bindings/extensions)
	LUA = luaL_newstate();
	lua_atpanic(LUA, (lua_CFunction)LuaFatalError);	//FIXME verify if this works
	luaL_openlibs(LUA);	//FIXME verify if this works
	//FIXME luaopen_pack(LUA);

	// initialise sjasmplus bindings/extensions
	luabridge::getGlobalNamespace(LUA)
		.addFunction("_c", LuaCalculate)
		.addFunction("_pl", LuaParseLine)
		.addFunction("_pc", LuaParseCode)
		.beginNamespace("sj")
			.addProperty("current_address", &CurAddress, false)	// read-only
			.addProperty("warning_count", &WarningCount, false)	// read-only
			.addProperty("error_count", &ErrorCount, false)	// read-only
			.addFunction("get_define",
				(std::function<const char*(const char*)>)[](const char*n) { return DefineTable.Get(n); })
			.addFunction("insert_define",
				(std::function<bool(const char*,const char*)>)[](const char*n,const char*v) { return DefineTable.Replace(n, v); })
			.addFunction("get_label", LuaGetLabel)
			//FIXME verify the official API only
			.addFunction("insert_label",
				(std::function<bool(const char*,int,bool,bool)>)[](const char*n,int a,bool undefined,bool defl) {
					unsigned traits = (undefined ? LABEL_IS_UNDEFINED : 0) | (defl ? LABEL_IS_DEFL : 0);
					return LabelTable.Insert(n, a, traits);
				}
			)
			.addFunction("shellexec", LuaShellExec)
			.addFunction("exit", ExitASM)
			.addFunction("calc", LuaCalculate)
			.addFunction("parse_line", LuaParseLine)
			.addFunction("parse_code", LuaParseCode)
			.addFunction("add_byte", EmitByte)
			.addFunction("add_word", EmitWord)
			.addFunction("get_byte", MemGetByte)
			.addFunction("get_word", MemGetWord)
			.addFunction("get_device", GetDeviceName)
			.addFunction("set_device", SetDevice)
			.addFunction("set_page", LuaSetPage)
			.addFunction("set_slot", LuaSetSlot)
			.addFunction("error", (std::function<void(const char*)>)[](const char*m) { Error(m, nullptr, ALL); })
			.addFunction("warning", (std::function<void(const char*)>)[](const char*m) { Warning(m, nullptr, W_ALL); })
			.addFunction("file_exists", FileExists)
		.endNamespace()
		.beginNamespace("zx")
			.addFunction("trdimage_create",
				(std::function<void(const char*)>)[](const char*n) {
					char label[9] = {"        "};
					TRD_SaveEmpty(n,label);
				}
			)
			.addFunction("trdimage_add_file",
				(std::function<void(const char*,const char*,int,int,int,bool)>)
					[](const char*trd,const char*file,int start,int length,int autostart,bool replace) {
					TRD_AddFile(trd,file,start,length,autostart,replace,false);
				}
			)
			.addFunction("save_snapshot_sna", SaveSNA_ZX)	//FIXME fix docs with return int or bool, fix also trd stuff?
		.endNamespace();

		//FIXME set_device change API to have second argument ramtop
		//TODO add MMU API?
}

void dirENDLUA() {
	Error("[ENDLUA] End of lua script without script");
}

void dirLUA() {
	// lazy init of Lua scripting upon first hit of LUA directive
	if (nullptr == LUA) initLUA();
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
			_lua_showLoadError(errorType);
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
	if (nullptr == LUA) initLUA();
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
			_lua_showLoadError(EARLY);
		}
		LuaStartPos = TextFilePos();
	}
	free(fullpath);
}

#endif //USE_LUA

////////////////////////////////////////////////////////////////////////////////////////////
// close LUA engine and release everything related
void sj_lua_close() {
	#ifdef USE_LUA
		// if Lua was used and initialised, release everything
		if (LUA) lua_close(LUA);
	#endif //USE_LUA

	// do nothing when Lua is disabled
}

//eof lua_sjasm.cpp
