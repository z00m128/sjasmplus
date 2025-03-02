		DEVICE ZXSPECTRUM48

		ORG 32768

		; three ways to detect length of a file using LUA

		; 1. direct LUA (this works)
	LUA PASS3
		local f = io.open("lua_colons_inside_macro.asm", "rb")
		local file_len = f:seek("end")
		f.close(f)
		_pl("fsize = " .. file_len)
	ENDLUA
		ASSERT(1121 == fsize)

		; 2. LUA inside of macro (this does not work)
	MACRO LUA_FileLength1
	LUA PASS3
		local f = io.open("lua_colons_inside_macro.asm", "rb")
		local file_len = f:seek("end")
		f.close(f)
		_pl("fsize = " .. file_len)
	ENDLUA
	ENDM
		LUA_FileLength1
		ASSERT(1121 == fsize)
		; following error message was generated before fix:
		; lua_colons_inside_macro.asm(21): error: [LUA] attempt to call a nil value (global 'seek')
		; lua_colons_inside_macro.asm(25): ^ emitted from here

		; 3. a temporary work around for the above problem (it works)
	MACRO LUA_FileLength2
	LUA PASS3
		local f = io.open("lua_colons_inside_macro.asm", "rb")
		local file_len = f.seek(f, "end")	--; explicit call to the class method avoids using colon
		f.close(f)
		_pl("fsize = " .. file_len)
	ENDLUA
	ENDM
		LUA_FileLength2
		ASSERT(1121 == fsize)
