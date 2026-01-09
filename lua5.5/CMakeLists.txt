##############################################################
#
# CMakeLists.txt - created by Cizo2000 <cizo2000@gmail.com>
# modified from lua5.4 to lua5.5 by Ped7g
#
##############################################################

cmake_minimum_required(VERSION 3.18.0)
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules ${CMAKE_MODULE_PATH})

project(lua5.5)

set(LUA_SOURCES
	lapi.c
	lauxlib.c
	lbaselib.c
	lcode.c
	lcorolib.c
	lctype.c
	ldblib.c
	ldebug.c
	ldo.c
	ldump.c
	lfunc.c
	lgc.c
	linit.c
	liolib.c
	llex.c
	lmathlib.c
	lmem.c
	loadlib.c
	lobject.c
	lopcodes.c
	loslib.c
	lparser.c
	lstate.c
	lstring.c
	lstrlib.c
	ltable.c
	ltablib.c
	ltm.c
	lundump.c
	lutf8lib.c
	lvm.c
	lzio.c
)

# compile bundled Lua as C++ instead of C
set_source_files_properties(${LUA_SOURCES} PROPERTIES LANGUAGE CXX )

if( ${CMAKE_SYSTEM_NAME} MATCHES "Linux")
		add_definitions(-DLUA_USE_LINUX)
	elseif(CYGWIN)
		add_definitions(-DLUA_USE_LINUX)
	elseif(WIN32)
endif()

#Ped7g -pedantic removed, there's too many warnings with GCC and Lua5.4 (taken over also for 5.5 without checking)
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -Wall -Wno-pedantic")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -Wall -Wno-pedantic")

add_library(lua5.5 STATIC ${LUA_SOURCES})
target_include_directories(lua5.5 PUBLIC include)

