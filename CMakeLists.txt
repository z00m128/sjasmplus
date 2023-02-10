##############################################################
#
# CMakeLists.txt - created by Cizo2000 <cizo2000@gmail.com>
#
##############################################################

cmake_minimum_required(VERSION 3.18.0)
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules ${CMAKE_MODULE_PATH})

project(sjasmplus)
set(MY_LUA_INCLUDE_DIR "lua5.4")
set(MY_LUA_LIBRARY "lua5.4")
set(LUABRIDGE_DIR "LuaBridge/Source")
set(UNIT_TESTS_DIR "cpp-src-tests")
set(UNITTESTPP_DIR "unittest-cpp")

set(SOURCES
	sjasm/devices.cpp
	sjasm/directives.cpp
	sjasm/io_cpc.cpp
	sjasm/io_err.cpp
	sjasm/io_nex.cpp
	sjasm/io_snapshots.cpp
	sjasm/io_tape.cpp
	sjasm/io_trd.cpp
	sjasm/io_tzx.cpp
	sjasm/lua_sjasm.cpp
	sjasm/parser.cpp
	sjasm/reader.cpp
	sjasm/relocate.cpp
	sjasm/sjasm.cpp
	sjasm/sjio.cpp
	sjasm/support.cpp
	sjasm/tables.cpp
	sjasm/z80.cpp
	crc32c/crc32c.cpp
)

add_definitions(-DMAX_PATH=PATH_MAX)
add_definitions(-DCMAKE)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS ON)

set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -Wall -pedantic")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -Wall -pedantic")

set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -s")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -s")

option(ENABLE_LUA "Enable LUA scripting support" ON)
option(SYSTEM_LUA "Use system LUA package" OFF)
option(ADD_UNIT_TESTS "Add unit tests into binary" OFF)

if(ADD_UNIT_TESTS)
	add_definitions(-DADD_UNIT_TESTS)
	include_directories(${UNITTESTPP_DIR})
	aux_source_directory(${UNITTESTPP_DIR}/UnitTest++/ UT_SRCS)
	aux_source_directory(${UNITTESTPP_DIR}/UnitTest++/Posix/ UT_SRCS)
	aux_source_directory(${UNIT_TESTS_DIR} UT_SRCS)
	set(SOURCES
		${SOURCES}
		${UT_SRCS}
	)
endif(ADD_UNIT_TESTS)

if(ENABLE_LUA)
	add_subdirectory(${LUABRIDGE_DIR} EXCLUDE_FROM_ALL)

	message(STATUS "Looking for Lua 5.4")

	if(SYSTEM_LUA)
		find_package(Lua "5.4" REQUIRED)
	endif(SYSTEM_LUA)

	if(LUA_FOUND)
		message(STATUS "Looking for Lua 5.4 - found: ${LUA_LIBRARIES}")
		include_directories(${LUA_INCLUDE_DIR})
	else(LUA_FOUND)
		message(STATUS "Looking for Lua 5.4 - using local")
		set(LUA_LIBRARY ${MY_LUA_LIBRARY})
		set(LUA_INCLUDE_DIR ${MY_LUA_INCLUDE_DIR})
		add_subdirectory(${LUA_INCLUDE_DIR})
		include_directories(${LUA_INCLUDE_DIR})
	endif(LUA_FOUND)

	add_definitions(-DUSE_LUA)

	if( ${CMAKE_SYSTEM_NAME} MATCHES "Linux")
		add_definitions(-DLUA_USE_LINUX)
	elseif(CYGWIN)
		add_definitions(-DLUA_USE_LINUX)
	elseif(WIN32)
	endif()
endif(ENABLE_LUA)

include_directories(sjasm)
include_directories(crc32c)

if(WIN32)
	set(RESOURCES sjasmwin32/sjasmplus.rc)
endif()

add_executable(${PROJECT_NAME} ${SOURCES} ${RESOURCES})

if(ENABLE_LUA)
	target_link_libraries(
		${PROJECT_NAME}
		${LUA_LIBRARY}
		LuaBridge
	)
	if(NOT WIN32)
		find_package(LibDL)
		if(LIBDL_FOUND)
		target_link_libraries(
			${PROJECT_NAME}
			${LIBDL_LIBRARIES}
		)
		endif(LIBDL_FOUND)
	endif()
endif(ENABLE_LUA)

install(TARGETS ${PROJECT_NAME}
	RUNTIME DESTINATION bin)

find_program(BASH_PROGRAM bash)

if(BASH_PROGRAM)
	add_custom_target(tests COMMAND "EXE=${CMAKE_BINARY_DIR}/${PROJECT_NAME}" ${BASH_PROGRAM} "${CMAKE_SOURCE_DIR}/ContinuousIntegration/test_folder_tests.sh"
		WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
		DEPENDS ${PROJECT_NAME})

	add_custom_target(examples COMMAND "EXE=${CMAKE_BINARY_DIR}/${PROJECT_NAME}" ${BASH_PROGRAM} "${CMAKE_SOURCE_DIR}/ContinuousIntegration/test_folder_examples.sh"
		WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
		DEPENDS ${PROJECT_NAME})
endif()
