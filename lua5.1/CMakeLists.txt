##############################################################
#
# CMakeLists.txt - created by Cizo2000 <cizo2000@gmail.com>
#
##############################################################

cmake_minimum_required(VERSION 3.1.0)
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules ${CMAKE_MODULE_PATH})

project(lua5.1)

set(LUA_SOURCES 
	lapi.c
	lauxlib.c
	lbaselib.c
	lcode.c
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
	lvm.c
	lzio.c
)

if( ${CMAKE_SYSTEM_NAME} MATCHES "Linux")
		add_definitions(-DLUA_USE_LINUX)
	elseif(CYGWIN)
		add_definitions(-DLUA_USE_LINUX)
	elseif(WIN32)
		add_definitions(-DLUA_USE_WINDOWS)
endif()

set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -Wall -Wabi -pedantic")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -Wall -Wabi -pedantic")

add_library(lua5.1 ${LUA_SOURCES})
target_include_directories(lua5.1 PUBLIC include)
